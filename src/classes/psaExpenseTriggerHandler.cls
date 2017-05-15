/**************************************************************************************
// Name          : psaExpesnseTriggerHandler
// Date          : April 20, 2015
// Description   : Handles all inserts/updates/deletes called by the psaExpense trigger
// Author        : CLD Partners
// Revisions     : 2015-04-20  Spano Initial Revision
//               : 2015-10-23  Mayfield Refactored code that finds matching tax record,
//                             updated billing amount calculation to check to see
//                             if exchange rate has been applied and, if not, apply it
//               : 2015-11-23  Klassen Updated CalculateBillingAmount method to exit
//                    immediately if required values aren't set... will be set later by
//                    native PSA code and the CalculateBillingAmount method will get called again
//               : 2016-2-28 Rohit included daily meals logic.
***************************************************************************************/
public with sharing class psaExpenseTriggerHandler implements psaITriggerHandler{

    PSA_Expense_Policy__c singleBilling;
    PSA_Expense_Policy__c receipt;
    PSA_Expense_Policy__c noteRequired;
    PSA_Expense_Policy__c amountReview;

    Map<Id, pse__Proj__c> projectMap;
    Map<String, String> expenseTypeToGLACode;
    Map<String, List<PSA_Expense_Policy__c>> expensePolicyMap;
    Map<Id, List<PSA_Expense_VAT__c>> countryToVATs;
    Map<Id, Contact> resourceMap;

    //Map<String, PSA_Expense_VAT__c> taxRecordKeyToTaxRecordMap = new Map<String, PSA_Expense_VAT__c>();

   // Map<Id, PSA_Expense_VAT__c> expenseIDtoTaxRecordMap = new Map<Id, PSA_Expense_VAT__c>();
    Map<String, PSA_Expense_VAT__c> expenseIDtoTaxRecordMap = new Map<String, PSA_Expense_VAT__c>();
    Id canadaId;

    // Daily Cap Specific variables.
    Map<Id,Decimal> dailyCapProjectMap = new Map<Id,Decimal>();
    List<Id> projectIdList = new List<Id>();
    Set<Id> expIDList = new Set<Id>();
    Set<Id> resourceIds = new Set<Id>();
    Set<Date> expenseDateSet = new Set<Date>();
    Map<Id,Decimal> expensedailyMealsCapMap =  new Map<Id,Decimal>();
    Set<Id> expReportIdSet = new Set<Id>();
    
    //Project change on Expense report variable for Expenses Ids.
    Set<Id> ProjectExpenseIds = new Set<Id>();
    
    public psaExpenseTriggerHandler(){}

    /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
   public void bulkBefore(){

        //String taxRecordKey = '';
        System.debug('Apex CPU Used (psaExpenseTriggerHandler-bulkBefore): ' + Limits.getCpuTime());

        String expCountry = '';
        String taxCountry = '';
        String expState = '';
        String taxState = '';
        String expType = '';
        String taxExpType = '';

        if(Trigger.isInsert || Trigger.isUpdate){

             expenseTypeToGLACode = new Map<String, String>();
             Set<Id> projectIds = new Set<Id>();
             Set<String> expenseTypes = new Set<String>();
             Set<String> countryCodes = new Set<String>();
            // Set<Id> resourceIds = new Set<Id>();
            // Set<Date> expenseDateSet = new Set<Date>();
             countryToVats = new Map<id, List<PSA_Expense_VAT__c>>();
             resourceMap = new Map<Id, Contact>();


             List<PSA_Expense_Type_GLA__c> glas = new List<PSA_Expense_Type_GLA__c>();

             //Add the project IDs and expense types to search for later
              for (SObject so : Trigger.new) {
                pse__Expense__c expense = (pse__Expense__c)so;
                projectIds.add(expense.pse__Project__c);
                expenseTypes.add(expense.pse__Type__c);
                countryCodes.add(expense.PSA_Incurred_Country__c);
                resourceIds.add(expense.pse__Resource__c);
                expenseDateSet.add(expense.pse__Expense_Date__c);
              }

              //obtain the project map to be used in the trigger
              projectMap = new Map<Id, pse__Proj__c>(
                [SELECT Id, pse__Project_Type__c, PSA_BR_Expenses_Billing_Type__c, pse__Account__c
                     FROM pse__Proj__c
                     WHERE Id In : projectIds
                ]);

              resourceMap = new Map<Id, Contact>(
                [SELECT Id, PSA_Resource_Entity__r.PSA_Country__c, PSA_Resource_Entity__c, PSA_Home_Country__c, PSA_Home_State__c from Contact where Id in :resourceIds]);


              //obtain the Expense Type GLA objects to be used in the trigger
              glas = [SELECT PSA_GLA_Code__c,PSA_Expense_Type__c from PSA_Expense_Type_GLA__c
                        where PSA_Expense_Type__c in :expenseTypes];
              for(PSA_Expense_Type_GLA__c nextType : glas){
                expenseTypeToGLACode.put(nextType.PSA_Expense_Type__c, nextType.PSA_GLA_Code__c);
              }

              List<PSA_Expense_VAT__c> vats = [SELECT ID, PSA_Expense_Type__c, PSA_Incurred_Country__c, PSA_Incurred_State_Province__c,
                                                PSA_Is_Reclaimable__c, PSA_Tax_Rate__c, PSA_Tax_Type__c from PSA_Expense_VAT__c
                                                WHERE PSA_Incurred_Country__c in :countryCodes AND PSA_Expense_Type__c in :expenseTypes AND Psa_tax_rate__c > 0];

              /*
              Now that we have the tax records that apply only to the countryCodes and expenseTypes of the expense passed
              in the trigger.new, let's loop through all expenses again and populate a map of expense ID -> matching tax record
              so that we can use this map later
              */

              for (SObject so : Trigger.new) {
                  pse__Expense__c expense = (pse__Expense__c)so;
                  if (expense.PSA_Incurred_Country__c == null) {
                    expCountry = '';
                  }
                  else {
                    expCountry = expense.PSA_Incurred_Country__c;
                  }

                  if (expense.PSA_Incurred_State_Province__c == null) {
                    expState = '';
                  }
                  else {
                    expState = expense.PSA_Incurred_State_Province__c;
                  }

                   if (expense.pse__Type__c == null) {
                    expType = '';
                  }
                  else {
                    expType = expense.pse__Type__c;
                  }


                  for (PSA_Expense_VAT__c taxRecord : vats)
                  {
                        if (taxRecord.PSA_Incurred_Country__c == null) {
                            taxCountry = '';
                        }
                        else {
                            taxCountry = taxRecord.PSA_Incurred_Country__c;
                        }

                        if (taxRecord.PSA_Incurred_State_Province__c == null) {
                            taxState = '';
                        }
                        else {
                            taxState = taxRecord.PSA_Incurred_State_Province__c;
                        }

                        if (taxRecord.PSA_Expense_Type__c == null) {
                            taxExpType = '';
                        }
                        else {
                            taxExpType = taxRecord.PSA_Expense_Type__c;
                        }
                        system.debug('getExpenseVatKey(expense)' +getExpenseVatKey(expense));
                        if (expCountry == taxCountry && expState == taxState && expType == taxExpType) {
                      //      expenseIDtoTaxRecordMap.put(expense.id, taxRecord);
                             expenseIDtoTaxRecordMap.put(getExpenseVatKey(expense), taxRecord);
                             break;
                        }




                  }

              }
              //End of code that populates expenseID -> Tax Record map


              expensePolicyMap = new Map<String, List<PSA_Expense_Policy__c>>();
              List<PSA_Expense_Policy__c> allMatching = [SELECT PSA_Expense_Type__c, PSA_Policy_Type__c, PSA_Amount_Review_Threshold__c, PSA_Receipt_Required_Threshold__c, CurrencyIsoCode, PSA_Account__c, PSA_Project__c, PSA_Billable_Limit__c
                                                        from PSA_Expense_Policy__c where PSA_Expense_Type__c in :expenseTypes];
              for(PSA_Expense_Policy__c nextPolicy : allMatching){
                    List<PSA_Expense_Policy__c> existing = expensePolicyMap.get(nextPolicy.PSA_Expense_Type__c);
                    if(existing == null){
                        existing = new List<PSA_Expense_Policy__c>();
                    }
                    existing.add(nextPolicy);
                    expensePolicyMap.put(nextPolicy.PSA_Expense_Type__c, existing);
              }



             // New Daily Cap Logic variables
            List<PSA_Cap__c> psaCapList = [Select Id,Project__r.Id,Cap_Amount__c from  PSA_Cap__c where Project__c in: projectIds and Cap_Level__c = 'Daily' and Cap_Type__c = 'Meal'];

            dailyCapProjectMap = new Map<Id,Decimal>();
            for (PSA_Cap__c capObj: psaCapList)
            {
               dailyCapProjectMap.put(capObj.Project__r.Id,capObj.Cap_Amount__c);
            }
            projectIdList = new List<Id>();
            expIDList = new Set<Id>();

            if (Trigger.isUpdate)
            {
                    if (dailyCapProjectMap.size()>0)
                    {
                       projectIdList = PSAMealsDailyCap.getProjectsSpecifExpenses(Trigger.new,dailyCapProjectMap);
                    }

                    // include all expences that are approved and would be considered for Daily Cap logic.

                    for (SObject so : Trigger.new) {
                            pse__Expense__c newExpense = (pse__Expense__c)so;
                            pse__Expense__c oldExpense = new pse__Expense__c();
                            if(Trigger.oldmap != null){
                                oldExpense = (pse__Expense__c)Trigger.oldmap.get(newExpense.ID);
                            }
                            if (newExpense.pse__Invoiced__c != null && !newExpense.pse__Invoiced__c && oldExpense.pse__Status__c != 'Approved' && newExpense.pse__Status__c == 'Approved')
                            {
                               expIDList.add(newExpense.Id);
                               expReportIdSet.add(newExpense.pse__Expense_Report__c);
                            }
                    }
                   if (projectIdList.size()>0 && dailyCapProjectMap.size()>0 && expIDList.size()>0)
                   {
                         expensedailyMealsCapMap = PSAMealsDailyCap.getDailyCapMap(projectIdList,resourceIds,expenseDateSet,dailyCapProjectMap,expIDList);
                   }
            }
           System.debug('projectIdList>>>>' +projectIdList );
           System.debug('dailyCapProjectMap>>>>' +dailyCapProjectMap );
        }
    }

    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/

    public void bulkAfter(){}

    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        pse__Expense__c expense = (pse__Expense__c)so;
        system.debug('\nGMM beforeInsert Expense.pse__Billing_Amount__c = ' + expense.pse__Billing_Amount__c);
        updateGLACode(expense);
        checkExpensePolicies(expense);
        applyTax(expense);
        calculateBillingAmount(expense,null);

    }

     /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        System.debug('Apex CPU Used (psaExpenseTriggerHandler-beforeUpdate): ' + Limits.getCpuTime());

        pse__Expense__c oldExpense = (pse__Expense__c)oldSo;
        pse__Expense__c newExpense = (pse__Expense__c)so;

        system.debug('\nGMM beforeUpdate OldExpense.pse__Billing_Amount__c = ' + oldExpense.pse__Billing_Amount__c + ' \n NewExpense.pse__Billing_Amount__c = ' + + newExpense.pse__Billing_Amount__c);

        //*** Added 4/26/16 by Cklassen to handle LTA Billing Event logic for Projects whose Expense Billing Type != "As Incurred"
        if (oldExpense.pse__Billing_Event_Item__c != null && newExpense.pse__Billing_Event_Item__c == null && oldExpense.PSA_LTA_Billing_Event__c != null) {
          newExpense.PSA_LTA_Billing_Event__c = null;
        }

        // Skip update if Billing Event is Avaiable on Expense
       // if (newExpense.pse__Billing_Event_Item__c == null)
       // {
            //Only update the GLA code if the Type has changed
            if(oldExpense.pse__Type__c != newExpense.pse__Type__c){
                System.debug('psaExpenseTriggerHandler-beforeUpdate-Type has changed:' + oldExpense.pse__Type__c + ':' + newExpense.pse__Type__c);
                updateGLACode(newExpense);
            }

            if((oldExpense.currencyIsoCode != newExpense.currencyIsoCode) ||
                (oldExpense.pse__Type__c != newExpense.pse__Type__c) ||
                (oldExpense.pse__Amount__c != newExpense.pse__Amount__c)) {
                System.debug('psaExpenseTriggerHandler-beforeUpdate-Currency/Type/Amount has changed so checking Expense Policies:' + newExpense);
                checkExpensePolicies(newExpense);
            }



            if(oldExpense.pse__Type__c != newExpense.PSE__Type__c ||
                oldExpense.PSA_Incurred_Country__c != newExpense.PSA_Incurred_Country__c ||
                oldExpense.PSA_Incurred_State_Province__c != newExpense.PSA_Incurred_State_Province__c ||
                oldExpense.PSE__Amount__c != newExpense.pse__Amount__c ||
                (oldExpense.PSA_Receipt_Type__c != newExpense.PSA_Receipt_Type__c))
            {
                System.debug('Have to update the expense VAT:' + newExpense);
                applyTax(newExpense);
            }

          //  }
            if(newExpense.pse__Invoiced__c != null && !newExpense.pse__Invoiced__c){
              System.debug('before update>>>>>>>>>>'+ newExpense.pse__Invoiced__c + newExpense);
               calculateBillingAmount(newExpense,oldExpense);
            }

        // include all expences that are approved and would be considered for Daily Cap logic.
        /*  if (newExpense.pse__Invoiced__c != null && !newExpense.pse__Invoiced__c && oldExpense.pse__Status__c != 'Approved' && newExpense.pse__Status__c == 'Approved')
            {
               expIDList.add(newExpense.Id);
            }*/
             
         //Added by hari : To fix the change of a project on the Expense report which changes Billing Currency on Expense.
            
           if((oldExpense.pse__Billing_Currency__c != newExpense.pse__Billing_Currency__c) && newExpense.pse__Status__c =='Draft' )
            {
                ProjectExpenseIds.add(newExpense.Id);
             }
               
    }

     /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted
    //               during a BEFORE trigger.
    //
    //   - include logic for handling partial delete of an itemized expense
    ***************************************************************************************/
    //public void beforeDelete(SObject so){}
    Set<Id> deletedExpCardTransactionIds = new Set<Id>();

    // when expense is an itemized transaction.....
    Set<Id> deletedExpCardTransactionItemIds = new Set<Id>();

    Set<id> deletedExpIds = new set<id>();
    public void beforeDelete(SObject so)
    {
        // collect the ids that are getting deleted....
        pse__Expense__c delExpense = (pse__Expense__c)so;
        deletedExpIds.add(delExpense.id);


        if (delExpense.PSA_Card_Transaction_Item__c != null)
        {
          // collect card transaction ITEM ids for unapproved delete expenses
          deletedExpCardTransactionItemIds.add(delExpense.PSA_Card_Transaction_Item__c);

        }
        else if (delExpense.PSA_Card_Transaction__c != null)
        {
            // collect card transaction ids for unapproved delete expenses
            deletedExpCardTransactionIds.add(delExpense.PSA_Card_Transaction__c);

        }
    }


    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted
    //               during an AFTER trigger. Always put field validation in the 'After'
    //               methods in case another trigger has modified any values. The record
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){
        pse__Expense__c expense = (pse__Expense__c)so;
        system.debug('\nGMM afterInsert Expense.pse__Billing_Amount__c = ' + expense.pse__Billing_Amount__c);
    }

    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){
        pse__Expense__c newExpense = (pse__Expense__c)so;
        pse__Expense__c oldExpense = (pse__Expense__c)oldso;

        system.debug('\nGMM afterUpdate OldExpense.pse__Billing_Amount__c = ' + oldExpense.pse__Billing_Amount__c + ' \n NewExpense.pse__Billing_Amount__c = ' + + newExpense.pse__Billing_Amount__c);

    }

    /**************************************************************************************
    // Name        : afterDelete
    // Description : This method is called iteratively for each record deleted
    //               during an AFTER trigger.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void afterDelete(SObject so)
    {
        pse__Expense__c delExpense = (pse__Expense__c)so;

        if (delExpense.PSA_Card_Transaction_Item__c != null)
        {
          // collect card transaction ITEM ids for unapproved delete expenses
          deletedExpCardTransactionItemIds.add(delExpense.PSA_Card_Transaction_Item__c);
        }
        else if (delExpense.PSA_Card_Transaction__c != null)
        {
          // collect card transaction ids for unapproved delete expenses
            deletedExpCardTransactionIds.add(delExpense.PSA_Card_Transaction__c);
        }
    }

    /**************************************************************************************
    // Name        : andFinally
    // Description : This method is called once all records have been processed by the
    //               trigger. Use this method to accomplish any final operations such as
    //               creation or updates of other records.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void andFinally()
    {
        // before deleting; make sure all itemized expenses are marked for deleted at once
        if (trigger.isDelete && trigger.isBefore && deletedExpCardTransactionIds != null && deletedExpCardTransactionIds.size() >0)
        {
            checkAllItemizedExpensesAreDeleted();
        }

        // after deleting expense(s) associated with card transactions...mark the card transactions as unassigned
        if (trigger.isDelete && trigger.isAfter)
        {

          // REMOVE THE Card Transaction Items....if (any)
          if (deletedExpCardTransactionItemIds != null && deletedExpCardTransactionItemIds.size() > 0)
          {
            psaCardTransactionLoader.unassignCardTransactionItems(deletedExpCardTransactionItemIds);
          }
          // REMOVE THE Card Transaction
          if (deletedExpCardTransactionIds != null && deletedExpCardTransactionIds.size() >0)
          {
            psaCardTransactionLoader.unassignCardTransactions(deletedExpCardTransactionIds);

          }

        }
            if(expReportIdSet.size()>0){
                PSAMealsDailyCap.updateExpenseReport(expReportIdSet);
            }
            if(ProjectExpenseIds.size()>0)
               {
                  ProjectchangeExpensesUpdate(ProjectExpenseIds);
               }
            
     }
    
    @future
    public static void ProjectchangeExpensesUpdate(Set<Id> PExpenseIds)
    {
        Boolean updateExp = false;
        List<pse__expense__c> ProjectExpenseLst = [select Id,pse__Expense_Report__c, pse__Expense_Report__r.Id,pse__Billing_Amount__c,pse__Non_Billable_Amount__c, 
                                                   pse__Exchange_Rate_Incurred_Currency__c,pse__Exchange_Rate_Billing_Currency__c,pse__Billing_Currency__c from pse__Expense__c
                                                   where Id IN: PExpenseIds];
        for(pse__expense__c exp : ProjectExpenseLst )
        {
            exp.pse__Billing_Amount__c =  Null;
            updateExp = true;
        }
        if(updateExp)
        {
            Database.update(ProjectExpenseLst);
        }
     }


    public void checkAllItemizedExpensesAreDeleted()
    {
        // ??
        if (trigger.isDelete && deletedExpIds != null && deletedExpCardTransactionIds.size() >0)
        {
            // card transaction id to expenses
            Map<Id, pse__Expense__c[]> cardTransExpenseMap = new Map<Id, pse__Expense__c[]>();

            for ( pse__Expense__c e : [
                  select id,
                         PSA_Card_Transaction__c,
                         PSA_Card_Transaction_Item__c,
                         pse__Approved__c
                    from pse__Expense__c
                   where PSA_Card_Transaction__c in :deletedExpCardTransactionIds])
            {
                pse__Expense__c[] exp = cardTransExpenseMap.get(e.PSA_Card_Transaction__c) != null ? cardTransExpenseMap.get(e.PSA_Card_Transaction__c) : new pse__Expense__c[]{};
                exp.add(e);
                cardTransExpenseMap.put(e.PSA_Card_Transaction__c, exp);
            }
            if (cardTransExpenseMap != null && cardTransExpenseMap.size() > 0)
            {
                String errMessage = 'You may not delete a partial itemized expense. Please delete the full transaction and return to the Expense Card Transaction screen to allocate the expense';
                for (SObject so : Trigger.old)
                {
                    pse__Expense__c del = (pse__Expense__c)so;
                    if (del.PSA_Card_Transaction__c != null && cardTransExpenseMap.containsKey(del.PSA_Card_Transaction__c))
                    {
                        pse__Expense__c[] cardtransExp = cardTransExpenseMap.get(del.PSA_Card_Transaction__c);
                        if (cardtransExp != null && cardTransExp.size() > 0)
                        {
                           for (pse__Expense__c exp : cardtransExp)
                           {

                              if (exp.PSA_Card_Transaction_Item__c == null && !deletedExpIds.contains(exp.id))
                              {
                                  del.addError(errMessage);
                              }
                           }
                        }
                    }
                }
            }
        }
    }

    /**************************************************************************************
    // Name        : updateGLACode
    // Description : This method is called when an expense is created. The GLA code will be
                    set to either 51110 (if the project type is Customer Project with Expenses Billing Type
                    'Expenses as Incurred'), 51130 (if the project type is customer project with any other
                    expenses billing type) or looked up via the PSA Expense GLA Code object
    //Arguments: psa__Expense__c expense - the object being updated
    ***************************************************************************************/
    private void updateGLACode(pse__Expense__c expense){

        //Obtain the related project
        pse__proj__c relatedProject = projectMap.get(expense.pse__Project__c);
        if(relatedProject != null){
            //If the related project is a customer project, and
            //the Expenses Billing Type is as Incurred, set the GLA Code to 51130
            if(relatedProject.pse__Project_Type__c == 'Customer Project'){
                if(relatedProject.PSA_BR_Expenses_Billing_Type__c == 'As Incurred'){
                    expense.PSA_Expense_GLA_Code__c = '51110';
                }
                else{
                    //If the project is a customer project, but not 'As Incurred',
                    //the GLA Code is 51130
                    expense.PSA_Expense_GLA_Code__c = '51130';
                }
                return;
            }
        }

        String glaCode = expenseTypeToGLACode.get(expense.pse__Type__c);
        if(glaCode != null){
            expense.PSA_Expense_GLA_Code__c = glaCode;
        }

    }


    /**************************************************************************************
    // Name        : checkExpensePolicies
    // Description : This method is called when an expense is created or updated. Expense policies will be checked
                    for those that match at the Expense Type and Currency. Policies will be applied with the precedence
                        1) Project Level
                        2) Account Level
                        3) Global Level
    // Arguments: pse__Expense__c expense - the expense being modified
    ***************************************************************************************/
    private void checkExpensePolicies(pse__Expense__c expense){

        //These four objects are used to make sure that the precedence is maintained.
        //They are set to non-null values as soon as one is found at any of the levels, so that future levels
        //can't overwrite them
        singleBilling = null;
        receipt = null;
        noteRequired = null;
        amountReview = null;
        String expenseType = expense.pse__Type__c;
        pse__Proj__c project = projectMap.get(expense.pse__Project__c);

        //Retrieve the list of expense policies that exist for this expense type
        List<PSA_Expense_Policy__c> existing = expensePolicyMap.get(expenseType);

        //If there are none, return without any more checking
        if(existing == null){
            System.debug('No expense policies exist for this type');
            return;
        }

        boolean found = false;
        //Check for a project level match
        for(PSA_Expense_Policy__c potential : existing){

            //If a matching Expense Policy for the expense's Expense Type is found, Try to assign it
            //to one of the global variables
            if((expense.pse__Project__c != null && potential.psa_Project__c != null &&
             potential.psa_Project__c == expense.pse__Project__c) &&
                potential.currencyIsoCode == expense.currencyIsoCode){

                System.debug('Found a policy at the project level with type: '+potential.PSA_Policy_Type__c);
                found = true;
                tryToAssignToPolicy(potential);
            }
        }

        // ******* only needs to be checked when the project is defined
        if(!found && project != null)
        {
            //Account matching
            for(PSA_Expense_Policy__c potential : existing){
                //If a matching Account level Expense Policy for the expense's Expense Type is found, Try to assign it
                //to one of the global variables
                if(potential.psa_Account__c != null && project.pse__account__c != null &&
                   potential.psa_Account__c == project.pse__account__c &&
                    potential.currencyIsoCode == expense.currencyIsoCode){

                    System.debug('Found a policy at the account level with type: '+potential.PSA_Policy_Type__c);
                    tryToAssignToPolicy(potential);
                    found = true;
                }
            }
        }

        if(!found){
            //Global matching
            for(PSA_Expense_Policy__c potential : existing){

                //If a matching Global level Expense Policy for the expense's Expense Type is found, Try to assign it
                //to one of the classes global variables
                if(potential.psa_Project__c == null && potential.psa_Account__c == null &&
                    potential.currencyIsoCode == expense.currencyIsoCode){

                    System.debug('Found a policy at the global level with type: '+potential.PSA_Policy_Type__c);
                    tryToAssignToPolicy(potential);
                }
            }
        }

        //Calls the method that applies the Expense Policy if any of the found policies need applying
        if(singleBilling != null){
            updateAmounts(expense, singleBilling);
        }
        if(receipt != null){
            updateAmounts(expense, receipt);
        }
        if(noteRequired != null){
            updateAmounts(expense, noteRequired);
        }
        if(amountReview != null){
            updateAmounts(expense, amountReview);
        }

    }

    /**************************************************************************************
    // Name        : updateAmounts
    // Description : This method is called when an Expense policy has been found and needs to be applied.
                    It determines which type of policy it is, and applies the necessary changes to the
                    expense
    //Arguments: pse__Expense__c expense - the expense being modified
                 PSA_Expense_Policy__c - the Expense Policy being applied
    ***************************************************************************************/
    private void updateAmounts(pse__Expense__c expense, PSA_Expense_Policy__c policy){
        if(policy.PSA_Policy_Type__c == 'Receipt Required'){
            System.debug('Policy reciept required is: '+policy.PSA_Receipt_Required_Threshold__c + 'Amount is: '+expense.pse__Amount__c);
            //Sets the receipt required flag to true if the amount is higher than the receipt threshold
            if(expense.pse__Amount__c > policy.PSA_Receipt_Required_Threshold__c){
                expense.PSA_Receipt_Required__c = true;
                System.debug('Amount is: '+expense.pse__Amount__c + '   policy receipt required threshold is: ' + policy.PSA_Receipt_Required_Threshold__c);
            }
            else{
                expense.PSA_Receipt_Required__c = false;
            }
        }
        else if(policy.PSA_Policy_Type__c == 'Single Billing Limit'){
            //Sets the non-billable amount to the Total Amount - the billable amount found on the expense policy
            Double billLimit = policy.PSA_Billable_Limit__c;
            Double amount = expense.pse__Amount__c;
            if(amount > billLimit){
                expense.pse__Non_Billable_Incurred_Amount__c = amount - billLimit;
            /*  if (expense.System_Cap_Amount__c != null)
                {
                   expense.pse__Non_Billable_Incurred_Amount__c = expense.pse__Non_Billable_Incurred_Amount__c + expense.System_Cap_Amount__c;
                }*/
            }
        }
        else if(policy.PSA_Policy_Type__c == 'Note Required'){
            //Throws an error if no note is found on a note required policy
            if(expense.pse__Notes__c == null || expense.pse__Notes__c == ''){
                expense.addError('A note is required for expenses of type: '+expense.pse__Type__c);
                Throw new psaException('A note is required for expenses of type: '+expense.pse__Type__c);
            }
        }
        else if(policy.PSA_Policy_Type__c == 'Amount Review Threshold'){
            //Sets the review needed flag if the amount of the expense is higher than the threshold on the expense policy
            if(expense.pse__Amount__c > policy.PSA_Amount_Review_Threshold__c){
                expense.PSA_Amount_Review_Needed__c = true;
            }
        }

    }

    /**************************************************************************************
    // Name        : tryToAssignToPolicy
    // Description : Assign the current policy to one of the 4 potentialy policy types
                    This is necessary because we have to check for project, account, and global level policies,
                    but the project level needs to take precedent
    //Arguments: PSA_Expense_Policy__c toAssign - the Expense Policy found
    ***************************************************************************************/

    private void tryToAssignToPolicy(PSA_Expense_Policy__c toAssign){
        System.debug('Existing polices: '+singleBilling+' '+receipt+' '+noteRequired+' '+amountReview);
        if(toAssign.PSA_Policy_Type__c == 'Single Billing Limit'){
            if(singleBilling == null){
                singleBilling = toAssign;
            }
        }
         else if(toAssign.PSA_Policy_Type__c == 'Receipt Required'){
            if(receipt == null){
                receipt = toAssign;
            }
        }
        else if(toAssign.PSA_Policy_Type__c =='Note Required'){
            if(noteRequired == null){
                noteRequired = toAssign;
            }
        }
        else if(toAssign.PSA_Policy_Type__c == 'Amount Review Threshold'){
            if(amountReview == null){
                noteRequired = toAssign;
            }
        }

    }

    /**************************************************************************************
    // Name        : applyTax
    // Description : Assign the correct tax Amount and tax Type to the expense, if one exists.
    //Arguments: PSE__Expense__c expense - the expense on which to assign a VAT
    ***************************************************************************************/
    private void applyTax(Pse__Expense__c expense){

      //  if (expenseIDtoTaxRecordMap.containsKey(expense.id)) {
      if (expenseIDtoTaxRecordMap.containsKey(getExpenseVatKey(expense))) {
          //  expense.pse__Incurred_Tax__c = expense.pse__Amount__c - (expense.pse__Amount__c / (1 + expenseIDtoTaxRecordMap.get(expense.id).PSA_Tax_Rate__c));
            expense.pse__Incurred_Tax__c = expense.pse__Amount__c - (expense.pse__Amount__c / (1 + expenseIDtoTaxRecordMap.get(getExpenseVatKey(expense)).PSA_Tax_Rate__c));
         //   expense.pse__Tax_Type__c = expenseIDtoTaxRecordMap.get(expense.id).PSA_Tax_Type__c;
            expense.pse__Tax_Type__c = expenseIDtoTaxRecordMap.get(getExpenseVatKey(expense)).PSA_Tax_Type__c;

        }
        else {
            expense.pse__Incurred_Tax__c = 0;
            expense.pse__Tax_Type__c = '';
        }

        expense.PSA_Incurred_Tax__c = expense.pse__Incurred_Tax__c;

    }

    /**************************************************************************************
    // Name        : calculateBillingAmount
    // Description : Calculates Billing Amount considering exchange rates and reclaimability
    //Arguments: PSE__Expense__c expense - the expense on which to assign a VAT
    ***************************************************************************************/
    private void calculateBillingAmount(Pse__Expense__c expense,Pse__Expense__c oldExpense) {
        system.debug('\n ******\n calculateBillingAmount expense > ' + expense + '\n ******* \n');
        //Added by cklassen 11/23/15 to prevent a timing error
        if (expense.pse__Exchange_Rate_Billing_Currency__c == null ||
              expense.pse__Exchange_Rate_Incurred_Currency__c == null ||
              expense.pse__Exchange_Rate_Incurred_Currency__c == 0.0) {
          System.debug('Skipping calculateBillingAmount b/c not Exchange Rate Billing Currency or Exchange Rate Incurred Currency: ' + expense);
          return;
        }

        Double fxRate = expense.pse__Exchange_Rate_Billing_Currency__c / expense.pse__Exchange_Rate_Incurred_Currency__c;
        Double billingAmountinIncurredCurrency = 0;
        Double expenseAmountinIncurredCurrency = 0;
        Double incurredTaxinIncurredCurrency = 0;
        Double nonBillableIncurredAmountinIncurredCurrency = 0;


       // expense.PSA_Daily_Meals_Cap__c = 10;
       // expense.pse__Non_Billable_Incurred_Amount__c = expense.PSA_Daily_Meals_Cap__c;

        if (expensedailyMealsCapMap.size() > 0 && expensedailyMealsCapMap.get(expense.id) != null)
        {

          //   expense.PSA_Daily_Meals_Cap__c = 10;
        //   expense.pse__Non_Billable_Incurred_Amount__c = expense.PSA_Daily_Meals_Cap__c;

                expense.PSA_Daily_Meals_Cap__c = expensedailyMealsCapMap.get(expense.id);
                if (expense.pse__Non_Billable_Incurred_Amount__c != null)
                {
                    expense.pse__Non_Billable_Incurred_Amount__c = expense.pse__Non_Billable_Incurred_Amount__c + expense.PSA_Daily_Meals_Cap__c;
                }else{
                    expense.pse__Non_Billable_Incurred_Amount__c = expense.PSA_Daily_Meals_Cap__c;
                }
        }

        // reset cap amount to 0 if non billable amount changed
        /*
        if (expense.pse__Non_Billable_Incurred_Amount__c != null && oldExpense != null && oldExpense.pse__Non_Billable_Incurred_Amount__c != null && oldExpense.pse__Non_Billable_Incurred_Amount__c != expense.pse__Non_Billable_Incurred_Amount__c){
           expense.PSA_Daily_Meals_Cap__c = null;
        }

        // logic to update non-billable amount if Cap changed.
        if (expense.PSA_Daily_Meals_Cap__c != null &&  oldExpense != null && expense.PSA_Daily_Meals_Cap__c != oldExpense.PSA_Daily_Meals_Cap__c)
        {
            if (oldExpense.PSA_Daily_Meals_Cap__c == null)
            {
                if (expense.pse__Non_Billable_Incurred_Amount__c != null)
                {
                    expense.pse__Non_Billable_Incurred_Amount__c = expense.pse__Non_Billable_Incurred_Amount__c + expense.PSA_Daily_Meals_Cap__c;
                }else{
                    expense.pse__Non_Billable_Incurred_Amount__c = expense.PSA_Daily_Meals_Cap__c;
                }
            }else {
              // include the difference in cap to Non billable amount.
               if (expense.pse__Non_Billable_Incurred_Amount__c != null)
                {
                       expense.pse__Non_Billable_Incurred_Amount__c = expense.pse__Non_Billable_Incurred_Amount__c + expense.PSA_Daily_Meals_Cap__c - oldExpense.PSA_Daily_Meals_Cap__c;
                }else{
                    expense.pse__Non_Billable_Incurred_Amount__c = expense.PSA_Daily_Meals_Cap__c - oldExpense.PSA_Daily_Meals_Cap__c;
                }
            }
        }
        */

        if (expense.pse__Amount__c != null) {
            expenseAmountinIncurredCurrency = expense.pse__Amount__c;
        }

        if (expense.pse__Incurred_Tax__c != null) {
            incurredTaxinIncurredCurrency = expense.pse__Incurred_Tax__c;
        }

        if (expense.pse__Non_Billable_Incurred_Amount__c != null) {
            nonBillableIncurredAmountinIncurredCurrency = expense.pse__Non_Billable_Incurred_Amount__c;
        }

      //  if (checkIsReclaimable(expense, expenseIDtoTaxRecordMap.get(expense.id))){
        if (checkIsReclaimable(expense, expenseIDtoTaxRecordMap.get(getExpenseVatKey(expense)))){
            billingAmountinIncurredCurrency = expenseAmountinIncurredCurrency - incurredTaxinIncurredCurrency - nonBillableIncurredAmountinIncurredCurrency;
        }
        else {
            billingAmountinIncurredCurrency = expenseAmountinIncurredCurrency - nonBillableIncurredAmountinIncurredCurrency;
        }

        if (expense.pse__Billing_Amount__c != billingAmountinIncurredCurrency * fxRate) {
            expense.pse__Billing_Amount__c = Decimal.valueOf(billingAmountinIncurredCurrency * fxRate).setScale(2, RoundingMode.HALF_UP);
        }

        if (expense.pse__Billable__c == false) {
            expense.pse__Billing_Amount__c = 0;
        }

    }

     /**************************************************************************************
    // Name        : checkIsReclaimable
    // Description : Checks to see if an expense VAT portion is reclaimable based on three criteria:
                        1) The VAT is marked as reclaimable
                        2) The Expense Receipt Type is marked as Tax Receipt
                        3) The expense incurred country is the same as the resource home country, and if the country is canada,
                        the state/province matches as well.

                    If any of these are not fulfilled, it sets VAT Reclaimable and Incurred Tax non-Billable to false
                    If they are all fulfilled, thoes values are set to true
    //Arguments: PSE__Expense__c expense - the expense on which to assign a VAT
                PSA_Expense_Vat__c vat - the vat applied to this expense
    ***************************************************************************************/
    private Boolean checkIsReclaimable(pse__Expense__c expense, PSA_Expense_Vat__c vat){

        boolean isReclaimable = false;
        //Check is the VAT is reclaimable

        if (vat != null) {
            System.debug(' Vat != null ');
            if(vat.PSA_Is_Reclaimable__c == true){
                System.debug(' Vat Is Reclai,able  ' + vat.PSA_Is_Reclaimable__c);
                //If the VAT is reclaimable, check to see if the receipt type is set to 'Tax Receipt'
                if(expense.PSA_Receipt_Type__c != null && expense.PSA_Receipt_Type__c == 'Tax Receipt'){
                    //If the receipt type is set to 'Tax Receipt', check to see that the resource's home location matches the expense
                    System.debug(' PSA Receipt Type  ' + expense.PSA_Receipt_Type__c);
                    Contact resource = resourceMap.get(expense.pse__Resource__c);
                    System.debug(' Contact resource  ' );
                    if(resource != null && resource.PSA_Resource_Entity__c != null && resource.PSA_Resource_Entity__r.PSA_Country__c != null){
                        System.debug(' Contact resource 2 ' );
                        if(resource.PSA_Resource_Entity__r.PSA_Country__c == expense.PSA_Incurred_Country__c){
                            System.debug(' Resource Entity  ' + resource.PSA_Resource_Entity__r.PSA_Country__c);
                            expense.PSA_VAT_Reclaimable__c = true;
                            expense.pse__Incurred_Tax_Non_Billable__c = true;
                            isReclaimable = true;
                        }
                    }

                }
            }
        }
        if(!isReclaimable){
                System.debug('This expense VAT Tax is not reclaimable');
                expense.PSA_VAT_Reclaimable__c = false;
                expense.pse__Incurred_Tax_Non_Billable__c = false;
        }
        return isReclaimable;
    }

    private String getExpenseVatKey(pse__Expense__c expense){
      String key ='';
      if(expense.PSA_Incurred_State_Province__c != null){
      key = String.valueof(expense.PSA_Incurred_State_Province__c);
      }
      if(expense.PSA_Incurred_Country__c != null){
      key += String.valueof(expense.PSA_Incurred_Country__c);
      }
      if(expense.pse__Type__c != null){
        key += String.valueof(expense.pse__Type__c);
      }
      return key;
    }

    private void updateExpenses(){
            System.debug('projectIdList>>>>' +projectIdList );
            System.debug('dailyCapProjectMap>>>>' +dailyCapProjectMap );
            if (projectIdList.size()>0 && dailyCapProjectMap.size()>0 && expIDList.size()>0)
            {
              System.debug('finally>>>>' );
            // PSAMealsDailyCap.updateExpenses(projectIdList,resourceIds,expenseDateSet,dailyCapProjectMap,expIDList);
            }
    }

}