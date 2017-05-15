/**************************************************************************************
// Name          : psaExpenseReportTriggerHandler
// Date          : March 4, 2015
// Description   : Handles all inserts/updates/deletes called by the psaExpenseReport trigger
// Author        : CLD Partners
// Revisions     : 2015-04-09  Spano initial version
//               : 2015-06-25  Spano added validation check on expenses where receipts were required when an expense report was submitted
//               : 2015-07-31  Klassen updated to un-set billable field if project expenses billing type != As Incurred
//               : 2015-08-13  Klassen updated to reset the owner from ap queue to resource - needed if ER was rejected
//               : 2015-09-25  Rohit updated to reset the owner from ap queue to resource - needed if ER was approved
//               : 2015-02-22  Rohit added new function setTaxPrep to update new field "Includes Tax Preparation" used in approval process.
//               : 2016-11-30  Hari added new function setGlobalMobility to update new field "Requires Global Mobility Approval" used in Approval Process for Global Mobility Team.
***************************************************************************************/
public without sharing class psaExpenseReportTriggerHandler implements psaITriggerHandler{

    Map<Id, pse__Proj__c> projectMap;
    Map<Id, Contact> resourceMap;
    Map<Id, List<pse__Expense__c>> expenseMap = new Map<Id, List<pse__Expense__c>>();
    public psaExpenseReportTriggerHandler() {}
    Boolean rejectionwithoutComments = false;

     /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
        System.debug('Apex CPU Used (psaExpenseReportTriggerHandler-bulkBefore): ' + Limits.getCpuTime());

        Set<Id> projectIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();

        if(Trigger.isInsert){
            // SOQL to look up project and resource
            Set<Id> reportIds = new Set<Id>();

            for (SObject so : Trigger.new) {
                pse__Expense_Report__c expenseReport = (pse__Expense_Report__c)so;
                resourceIds.add(expenseReport.pse__Resource__c);
                projectIds.add(expenseReport.pse__Project__c);
                reportIds.add(expenseReport.id);
            }
            projectMap = new Map<Id, pse__Proj__c>(
                [SELECT Id, PSA_Expense_Approval_Method__c, PSA_Billing_Legal_Entity__c, pse__Project_Type__c, pse__Project_Manager__r.pse__Salesforce_User__c,
                        PSA_CIM__r.pse__Salesforce_User__c, PSA_Director__r.pse__Salesforce_User__c
                    FROM pse__Proj__c
                    WHERE Id In : projectIds
                ]);
            resourceMap = new Map<Id, Contact>(
                [SELECT Id, pse__Salesforce_User__r.ManagerId, PSA_Resource_Entity__c, Pse__Region__c, PSA_Fully_Loaded_Cost_Rate__c
                    FROM Contact
                    WHERE Id In : resourceIds
                ]);
        }
        if(Trigger.isUpdate){
            Set<Id> reportIds = new Set<Id>();

            for (SObject so : Trigger.new) {
                pse__Expense_Report__c expenseReport = (pse__Expense_Report__c)so;
                resourceIds.add(expenseReport.pse__Resource__c);
                projectIds.add(expenseReport.pse__Project__c);
                reportIds.add(expenseReport.id);
            }
            List<pse__Expense__c> expenses = [Select Id,pse__type__c,PSA_Receipt_Required__c,pse__Expense_Report__c,PSA_Receipt_Attached__c from pse__Expense__c where pse__Expense_Report__c in :reportIds];
            for(pse__Expense__c expense : expenses){
                List<pse__Expense__c> onReport = expenseMap.get(expense.pse__Expense_Report__c);
                if(onReport == null){
                    onReport = new List<pse__Expense__c>();
                }
                onReport.add(expense);
                expenseMap.put(expense.pse__Expense_Report__c, onReport);
            }

            projectMap = new Map<Id, pse__Proj__c>(
                [SELECT Id, PSA_Expense_Approval_Method__c, PSA_Billing_Legal_Entity__c, pse__Project_Type__c, pse__Project_Manager__r.pse__Salesforce_User__c,
                        PSA_CIM__r.pse__Salesforce_User__c, PSA_Director__r.pse__Salesforce_User__c, PSA_BR_Expenses_Billing_Type__c
                    FROM pse__Proj__c
                    WHERE Id In : projectIds
                ]);
            //Needed to get SF user if an expense report was rejected -- need to reset owner to the resource's sf user
            resourceMap = new Map<Id, Contact>(
                [SELECT Id, pse__Salesforce_User__r.ManagerId, PSA_Resource_Entity__c, Pse__Region__c, PSA_Fully_Loaded_Cost_Rate__c,
                        pse__Salesforce_User__c
                    FROM Contact
                    WHERE Id In : resourceIds
                  ]);

             // data for comment required on rejection.
             Map<Id, pse__Expense_Report__c> rejectedReports  = new Map<Id, pse__Expense_Report__c>{};
            for(SObject so: trigger.new)
            {
                pse__Expense_Report__c erep = (pse__Expense_Report__c)so;
                SObject soOld = System.Trigger.oldMap.get(erep.Id);
                pse__Expense_Report__c oldER = (pse__Expense_Report__c)soOld;
                if (oldER.pse__Status__c != 'Rejected'
                    && erep.pse__Status__c == 'Rejected')
                {
                    rejectedReports.put(erep.Id, erep);
                }
            }
             if (!rejectedReports.isEmpty())
              {
                List<Id> processInstanceIds = new List<Id>{};
                for (pse__Expense_Report__c er : [SELECT (SELECT ID  FROM ProcessInstances  ORDER BY CreatedDate DESC LIMIT 1) FROM pse__Expense_Report__c WHERE ID IN :rejectedReports.keySet()])
                    {
                        processInstanceIds.add(er.ProcessInstances[0].Id);
                    }

                 for (ProcessInstance pi : [SELECT TargetObjectId, (SELECT Id, StepStatus, Comments FROM Steps ORDER BY CreatedDate DESC LIMIT 1 ) FROM ProcessInstance WHERE Id IN :processInstanceIds ORDER BY CreatedDate DESC])
                {
                      if ((pi.Steps[0].Comments == null ||
                           pi.Steps[0].Comments.trim().length() == 0))
                      {
                      rejectionwithoutComments = true;
                      }
                }
             }


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
        pse__Expense_Report__c expenseReport = (pse__Expense_Report__c)so;
        setApprover(expenseReport);
        setEntities(expenseReport);
    }


    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        System.debug('Apex CPU Used (psaExpenseReportTriggerHandler-beforeUpdate): ' + Limits.getCpuTime());

        pse__Expense_Report__c newReport = (pse__Expense_Report__c)so;
        pse__Expense_Report__c oldReport = (pse__Expense_Report__c)oldSo;
        if((oldReport.pse__Status__c == 'Draft' || oldReport.pse__Status__c == 'Rejected') && newReport.pse__Status__c == 'Submitted'){
            checkReceipts(newReport);
            setTaxPrep(newReport);
            setGlobalMobility(newReport);
        }

        pse__Proj__c proj = projectMap.get(newReport.pse__Project__c);

        if (proj.PSA_BR_Expenses_Billing_Type__c != 'As Incurred' && newReport.pse__Billable__c == true) {
            newReport.pse__Billable__c = false;
        }

        //added by cklassen 8/13/15 to reset record owner to resource user if the expense report was rejected
        Contact resource = resourceMap.get(newReport.pse__Resource__c);
        //System.debug('Resource: ' + resource);
        System.debug('Old Status: ' + oldReport.pse__Status__c);
        System.debug('New Status: ' + newReport.pse__Status__c);
        if (resource != null && (newReport.pse__Status__c == 'Rejected' || newReport.pse__Status__c == 'Approved' || newReport.pse__Status__c == 'Draft') && (oldReport.pse__Status__c == 'AP Review' || oldReport.pse__Status__c == 'Payroll Review' || oldReport.pse__Status__c =='GM Review')) {
            newReport.OwnerId = resource.pse__Salesforce_User__c;
            System.debug('Owner Reset: ' + newReport.OwnerId);
        }

        if (rejectionwithoutComments)
        {
            newReport.addError('Please provide a rejection reason in Comments while rejecting an Expense Report. Please <a href=\'javascript:history.back()\'>go back</a> and add an Comment.');
        }
    }

    set<id> deletedExpReportIds = new set<id>();

    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so)
    {
        // collect the unapproved expense report ids that are getting deleted....
        pse__Expense_Report__c delReport = (pse__Expense_Report__c)so;
        if (delReport.pse__Approved__c == false)
        {
            deletedExpReportIds.add(delReport.id);
        }
    }

    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted
    //               during an AFTER trigger. Always put field validation in the 'After'
    //               methods in case another trigger has modified any values. The record
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){}

    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){}


    /**************************************************************************************
    // Name        : afterDelete
    // Description : This method is called iteratively for each record deleted
    //               during an AFTER trigger.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void afterDelete(SObject so){}

    /**************************************************************************************
    // Name        : andFinally
    // Description : This method is called once all records have been processed by the
    //               trigger. Use this method to accomplish any final operations such as
    //               creation or updates of other records.
    // Arguments   : SObject so - the object that initiated the trigger
    **********************************************
    *****************************************/
    public void andFinally(){

        if (trigger.isDelete && trigger.isBefore && deletedExpReportIds != null && deletedExpReportIds.size() >0)
        {
            // We need to remove expenses and rollback and / card transaction settings!
            psaCardTransactionLoader.handleExpenseReportDelete(deletedExpReportIds);

        }

        System.debug('Apex CPU Used (psaExpenseReportTriggerHandler-andFinally): ' + Limits.getCpuTime());
    }

    /**************************************************************************************
    // Name        : setApprover
    // Description : This method is called when an Expense Report is saved. If the project
    expense approval method is "Project Manager", this assigns the approver based on the following order:
            1) Project Manager, Unless equal to the Resource submitting the expense
            2) CIM, unless equal to the resource submitting the expense
            3) Director, unless equal to the resource submitting the expense
            4) Resource's manager
        If the project Expense Approval method is "Resource manager", it is assigned directly to the
            resource's manager
    // Arguments   : PSE__Expense_Report__c expenseReport - the expense report that was saved
    ***************************************************************************************/
    private void setApprover(pse__Expense_Report__c expenseReport){
        pse__Proj__c project = projectMap.get(expenseReport.pse__Project__c);
        Contact resource = resourceMap.get(expenseReport.pse__Resource__c);

         if (project.PSA_Expense_Approval_Method__c == 'Project Manager') {
            System.debug('Using project manager approval method');
            if (project.pse__Project_Manager__c != null && project.pse__Project_Manager__c != expenseReport.pse__Resource__c) {
                System.debug('Assigning approver to project manager');
                expenseReport.pse__Approver__c = project.pse__Project_Manager__r.pse__Salesforce_User__c;
            } else if (project.PSA_CIM__c != null && project.psa_cim__c != expenseReport.pse__Resource__c) {
                expenseReport.pse__Approver__c = project.PSA_CIM__r.pse__Salesforce_User__c;
            } else if (project.psa_Director__c != null && project.psa_Director__c != expenseReport.pse__Resource__c) {
                expenseReport.pse__Approver__c = project.PSA_Director__r.pse__Salesforce_User__c;
            } else {
                expenseReport.pse__Approver__c = resource.pse__Salesforce_User__r.ManagerId;
            }
        } else if (project.PSA_Expense_Approval_Method__c == 'Resource Manager') {
            expenseReport.pse__Approver__c = resource.pse__Salesforce_User__r.ManagerId;
        }
    }

    /**************************************************************************************
    // Name        : setEntities
    // Description : This method is intended to copy the entities from the project down to
                      a created expense report
    // Arguments   : pse__Expense_Report__c expenseReport The expense report that needs to have
                      the entities populated
    ***************************************************************************************/
    private void setEntities(pse__Expense_Report__c expenseReport){
        pse__Proj__c project = projectMap.get(expenseReport.pse__Project__c);
        Contact c = resourceMap.get(expenseReport.pse__Resource__c);
        if(project != null && project.PSA_Billing_Legal_Entity__c != null){
            expenseReport.PSA_Project_Billing_Legal_Entity__c = project.PSA_Billing_Legal_Entity__c;
        }
        if(c != null && c.PSA_Resource_Entity__c != null){
            expenseReport.PSA_Resource_Entity__c = c.PSA_Resource_Entity__c;
        }
    }

    private void checkReceipts(pse__Expense_Report__c expenseReport){
        List<pse__Expense__c> expenses = expenseMap.get(expenseReport.id);
        boolean receiptError = false;
        String errorMessage = '';
        if(expenses != null){
            for(pse__Expense__c expense : expenses){
                if(expense.psa_Receipt_Required__c && !expense.PSA_Receipt_Attached__c){
                    errorMessage += 'On expense of type: '+expense.pse__Type__c+' a receipt was required but not attached.' + '\r\n';
                    receiptError = true;
                    System.debug('On expense: '+expense.id+', a receipt was required but not attached');
                }
            }
            if(receiptError){
                expenseReport.addError(errorMessage);
            }
        }
    }

    private void setTaxPrep(pse__Expense_Report__c expenseReport){
        List<pse__Expense__c> expenses = expenseMap.get(expenseReport.id);
        if(expenses != null){
         for(pse__Expense__c expense : expenses){
            if (expense.pse__type__c != null && expense.pse__type__c == 'Tax Prep Cost for Addtl State(s)')
            {
              expenseReport.Includes_Tax_Preparation__c = true;
            }
         }
        }
     }
     
    private void setGlobalMobility(pse__Expense_Report__c expenseReport)
    {
        List<pse__Expense__c> expenses = expenseMap.get(expenseReport.id);
        if(expenses != null)
        {
         for(pse__Expense__c expense : expenses)
         {
            if (expense.pse__type__c != null && (expense.pse__type__c == 'Relocation Exp' || expense.pse__type__c == 'GM - Relocation Expenses') )
            {
              expenseReport.Requires_Global_Mobility_Approval__c = true;
            }
          }
        }
     }
     

}