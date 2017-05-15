/*********************************************************************************************** x
Name            : psaCardTransactionLoader
Author          : CLD
Created Date    : Oct 2015
Revision History:

Usage           : Class to load card transaction staging objects into card transactions
                :
***********************************************************************************************/
public without sharing class psaCardTransactionLoader
{
    // generates card transaction objects from card transaction staging objects
    // - psaCardTransactionLoader.process(...)
    public static void process(PSA_Card_Transaction_Stage__c[] cardStagingTransactions)
    {
        try
        {
            if (cardStagingTransactions != null && cardStagingTransactions.size() > 0)
            {
                // for collecting the employeeIds associated with the staging card transactions
                Set<String> employeeIds = new Set<String>();

                // for collecting the country codes
                Set<String> merchantCountries = new Set<String>();

                // for collecting the state codes
                Set<String> merchantStates = new Set<String>();

                for (PSA_Card_Transaction_Stage__c ctStage : cardStagingTransactions)
                {
                    if (ctStage.PSA_EmployeeId__c != null)
                    {
                        employeeIds.add(ctStage.PSA_EmployeeId__c);
                    }

                    if (ctStage.PSA_Merchant_Country_Code__c != null)
                    {
                        merchantCountries.add(ctStage.PSA_Merchant_Country_Code__c);
                    }

                    if (ctStage.PSA_Merchant_State_Province__c != null)
                    {
                        merchantStates.add(ctStage.PSA_Merchant_State_Province__c);
                    }
                }

                // ****
                Map<String, User> employeeIdUsers                          = loadUsersByEmployeeId(employeeIds);
                Map<String, Contact> employeeIdResources                   = loadResourcesByEmployeeId(employeeIds);
                Map<String, pw_cc__CountryObject__c> merchantCountryCodes  = loadMerchantCountryCodes(merchantCountries);
                Map<String, pw_cc__State__c> merchantStateCodes            = loadMerchantStateCodes(merchantCountries, merchantStates);

                // generate our card transactions
                PSA_Card_Transaction__c[] cardTransactionsToCreate =  createCardTransFromStaging(cardStagingTransactions,
                                                                                                 employeeIdUsers,
                                                                                                 employeeIdResources,
                                                                                                 merchantCountryCodes,
                                                                                                 merchantStateCodes);


                if (cardTransactionsToCreate != null && cardTransactionsToCreate.size() > 0)
                {
                    insert cardTransactionsToCreate;

                    logInfo('Card Transactions Success created: ' + cardTransactionsToCreate.size() );
                }
            }
        }
        catch(Exception e)
        {
            logError('ERROR:' + e.getMessage());
        }
    }

    // lookup the 'operations-review-queue' queueid associated to the psa card transaction
    private static String fetchOperationsQueueOwnerId{get{
        if (fetchOperationsQueueOwnerId == null)
        {
            QueueSobject[] gz = [
                select Id, QueueId, Queue.DeveloperName, SobjectType
                  from QueueSobject
                 where Queue.DeveloperName = 'Operations_Review_Queue'
                   and SobjectType = 'PSA_Card_Transaction__c'  ];

            fetchOperationsQueueOwnerId = (gz != null && gz.size() > 0 && gz[0].QueueId != null) ? gz[0].QueueId : null;
        }
        return fetchOperationsQueueOwnerId;
        } private set;}

    //private static String fetchOperationsQueueOwnerId()
    //{
    //    QueueSobject[] gz = [
    //        select Id, QueueId, Queue.DeveloperName, SobjectType
    //          from QueueSobject
    //         where Queue.DeveloperName = 'Operations_Review_Queue'
    //           and SobjectType = 'PSA_Card_Transaction__c'  ];

    //    return (gz != null && gz.size() > 0 && gz[0].QueueId != null) ? gz[0].QueueId : null;
    //}

    //
    // generate the card transaction objects from staging objects
    //
    private static PSA_Card_Transaction__c[] createCardTransFromStaging(
                                                   PSA_Card_Transaction_Stage__c[]cardStagingTransactions,
                                                   Map<String, User> employeeIdUsers,
                                                   Map<String, Contact> employeeIdResources,
                                                   Map<String, pw_cc__CountryObject__c> merchantCountryCodes,
                                                   Map<String, pw_cc__State__c> merchantStateCodes)
    {
        // collect the transactions to create
        PSA_Card_Transaction__c[] cardTransactionsToCreate = new PSA_Card_Transaction__c[]{};
        if (cardStagingTransactions != null && cardStagingTransactions.size() > 0)
        {
            for (PSA_Card_Transaction_Stage__c ctStage : cardStagingTransactions)
            {
                Contact resource = employeeIdResources.get(ctStage.PSA_EmployeeId__c);
                User user = employeeIdUsers.get(ctStage.PSA_EmployeeId__c);


                PSA_Card_Transaction__c cardTrans = new PSA_Card_Transaction__c();

                cardTrans.psa_card_transaction_stage__c = ctStage.id; // associate it with the staged object
                cardTrans.currencyIsoCode = ctStage.currencyIsoCode;

                cardTransactionsToCreate.add(cardTrans);

                if (user != null)
                {
                    cardTrans.OwnerId = user.id;
                    cardTrans.PSA_Salesforce_User__c = user.id;
                }

                if (resource != null)
                {
                    cardTrans.PSA_Resource__c = resource.id;
                    cardTrans.PSA_Resource_Inactive__c = (resource.pse__Is_Resource_Active__c == false);

                    if (user == null && resource.pse__Salesforce_User__c != null)
                    {
                        cardTrans.OwnerId = resource.pse__Salesforce_User__c;
                        cardTrans.PSA_Salesforce_User__c = resource.pse__Salesforce_User__c;
                    }
                }

                cardTrans.PSA_Amount_in_Original_Currency__c = ctStage.PSA_Amount_in_Original_Currency__c;
                cardTrans.PSA_Amount_in_Billing_Currency__c  = ctStage.PSA_Amount_in_Billing_Currency__c;
                cardTrans.PSA_EmployeeId__c                  = ctStage.PSA_EmployeeId__c;
                cardTrans.PSA_Expense_Type__c                = '';
                cardTrans.PSA_FX__c                          = ctStage.PSA_Billing_Conversion_Rate__c;
                cardTrans.PSA_Merchant_Country_Code__c       = ctStage.PSA_Merchant_Country_Code__c;
                cardTrans.PSA_Merchant_Name__c               = ctStage.PSA_Merchant_Name__c;
                cardTrans.PSA_Merchant_Postal_Code__c        = ctStage.PSA_Merchant_Postal_Code__c;
                cardTrans.PSA_Merchant_State_Province__c     = ctStage.PSA_Merchant_State_Province__c;
                cardTrans.PSA_Posting_Date__c                = ctStage.PSA_Posting_Date__c;
                cardTrans.PSA_Processor_Transaction_Id__c    = ctStage.PSA_ProcessorTransactionId__c;
                cardTrans.PSA_Status__c                      = 'Unassigned';
                cardTrans.PSA_Transaction_Date__c            = ctStage.PSA_Transaction_Date__c;

                // lookup and set the incurred country and state codes, based on the merchant values
                pw_cc__CountryObject__c ccCountry = merchantCountryCodes.get(ctStage.PSA_Merchant_Country_Code__c);
                if (ccCountry != null && ccCountry.id != null)
                {
                    cardTrans.PSA_Incurred_Country__c = ccCountry.id;
                }

                // lookup state...using country...
                if (ctStage.PSA_Merchant_Country_Code__c != null && (ctStage.PSA_Merchant_Country_Code__c =='USA' || ctStage.PSA_Merchant_Country_Code__c =='CAN') &&
                    ctStage.PSA_Merchant_State_Province__c != null &&
                    ctStage.PSA_Merchant_State_Province__c <> 'UNK')
                {
                    String countryStateKey = ctStage.PSA_Merchant_Country_Code__c + '-' + ctStage.PSA_Merchant_State_Province__c;
                    pw_cc__State__c ccState = merchantStateCodes.get(countryStateKey);
                    if (ccState != null && ccState.id != null)
                    {
                        cardTrans.PSA_Incurred_State_Province__c = ccState.id;
                    }
                }

                // ----- evaluate if operations review is needed and set accordingly....
                verifyIfOperationsReviewRequired(cardTrans, resource);


            }
        }

        return cardTransactionsToCreate;
    }

    // ----- evaluate if operations review is needed and set accordingly....
    /*
    Specifies a reason code (set automatically) for when a transaction needs ops review.  Values include:
    -   NUSR (No Salesforce User Found)
    -   NCNT (No Contact Found)
    -   NRSC (Contact.pse__Is_Resource__c = False)
    -   ACTV (Contact.pse__Is_Resource_Active__c = False)
    -   TERM (Contact.PSA_Resource_Review_Status__c = Termination)
    -   TRNS (Contact.PSA_Resource_Review_Status__c = ‘Transfer Out’)
    -   LCTN (No matching country or state objects were found and so the Incurred Country and/or Incurred State / Province could not be set)
    */
    private static void verifyIfOperationsReviewRequired(PSA_Card_Transaction__c cardTrans, Contact resource)
    {
        if (cardTrans.PSA_Salesforce_User__c == null)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'NUSR';
        }
        else if (cardTrans.PSA_Resource__c == null)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'NCNT';
        }
        else if (resource != null && resource.pse__Is_Resource__c == false)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'NRSC';
        }
        else if (resource != null && resource.pse__Is_Resource_Active__c == false)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'ACTV';
        }

        // PSA_Resource_Review_Status__c (is a multi-picklist) check to see if it contains termination
        else if (resource != null && resource.PSA_Resource_Review_Status__c != null
                                  && resource.PSA_Resource_Review_Status__c.indexOf('Termination') > -1)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'TERM';
        }
        // PSA_Resource_Review_Status__c (is a multi-picklist) check to see if it contains transfer out
        else if (resource != null && resource.PSA_Resource_Review_Status__c != null
                                  && resource.PSA_Resource_Review_Status__c.indexOf('Transfer Out') > -1)
        {
            cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'TRNS';
        }
        else if (cardTrans.PSA_Incurred_Country__c == null)
        {
          //  cardTrans.PSA_Operations_Review__c = true;
            cardTrans.PSA_Operations_Review_Reason__c = 'LCTN';
        }
        else if (cardTrans.PSA_Incurred_State_Province__c == null)
        {
            // skip UNK verification check
            if (cardTrans.PSA_Merchant_State_Province__c == null || cardTrans.PSA_Merchant_State_Province__c <> 'UNK')
            {
             //   cardTrans.PSA_Operations_Review__c = true;
                cardTrans.PSA_Operations_Review_Reason__c = 'LCTN';
            }
         }

        // set to the operations review queue....
        if (cardTrans.PSA_Operations_Review__c == true)
        {
            // lookup the 'operations-review-queue' queueid associated to the psa card transaction
            String operationsReviewQueueOwnerId = fetchOperationsQueueOwnerId;
            if (operationsReviewQueueOwnerId != null)
            {
                cardTrans.OwnerId = operationsReviewQueueOwnerId;
            }
        }
    }

    // ------------------------------------------------------------------------
    // * load resources by employee ids
    // * returns map of worker id to resource based on the specified employee/worker ids
    private static Map<String, Contact> loadResourcesByEmployeeId(Set<String> employeeIds)
    {
        Map<String, Contact> rtn = new Map<String, Contact>();
        if (employeeIds != null && employeeIds.size() > 0)
        {
            for (Contact resource : [ SELECT Id,
                                             PSA_Worker_Id__c,
                                             pse__Is_Resource__c,
                                             pse__Is_Resource_Active__c,
                                             pse__Salesforce_User__c,
                                             PSA_Resource_Review_Status__c
                                        FROM Contact
                                       WHERE PSA_Worker_Id__c in :employeeIds ])
            {
                rtn.put(resource.PSA_Worker_Id__c, resource);
            }
        }
        return rtn;
    }

    // ------------------------------------------------------------------------
    // * load users by employee ids
    // * returns map of worker id to user based on the specified employee/worker ids
    private static Map<String, User> loadUsersByEmployeeId(Set<String> employeeIds)
    {
        Map<String, User> rtn = new Map<String, User>();
        if (employeeIds != null && employeeIds.size() > 0)
        {
            for (User user : [ SELECT Id,
                                      PSA_Worker_Id__c
                                 FROM User
                                WHERE PSA_Worker_Id__c in :employeeIds ])
            {
                rtn.put(user.PSA_Worker_Id__c, user);
            }
        }
        return rtn;
    }


    //// ------------------------------------------------------------------------
    //// * load expense type mapping
    //// * returns a map of PSA_Card_Expense_Category_Code__c to PSA_Expense_Type
    //private static Map<String, PSA_Card_Expense_Type_Map__c> loadExpenseTypeMapping(Set<String> expenseCategoryCodes)
    //{
    //    Map<String, PSA_Card_Expense_Type_Map__c> rtn = new Map<String, PSA_Card_Expense_Type_Map__c>();
    //    if (expenseCategoryCodes != null && expenseCategoryCodes.size() > 0)
    //    {
    //        for(PSA_Card_Expense_Type_Map__c cardExpTypeMap : [
    //                     select Id,
    //                            PSA_Card_Expense_Category_Code__c,
    //                            PSA_Expense_Type__c
    //                       from PSA_Card_Expense_Type_Map__c
    //                      where PSA_Card_Expense_Category_Code__c in :expenseCategoryCodes])
    //        {
    //            rtn.put(cardExpTypeMap.PSA_Card_Expense_Category_Code__c, cardExpTypeMap);
    //        }

    //    }
    //    return rtn;
    //}

    // ------------------------------------------------------------------------
    // * load country codes
    // * returns a map of merchant country code to (pw_cc__Country_Country.ISO 3166-3
    private static Map<String, pw_cc__CountryObject__c> loadMerchantCountryCodes(Set<String> merchantCountryCodes)
    {
        Map<String, pw_cc__CountryObject__c> rtn = new Map<String, pw_cc__CountryObject__c>();
        if (merchantCountryCodes != null && merchantCountryCodes.size() > 0)
        {
            for (pw_cc__CountryObject__c ccCountry : [
                select Id,
                       pw_cc__IsoCode_3__c
                  from pw_cc__CountryObject__c
                 where pw_cc__IsoCode_3__c in :merchantCountryCodes])
            {
                rtn.put(ccCountry.pw_cc__IsoCode_3__c, ccCountry);
            }

        }
        return rtn;
    }


    // ------------------------------------------------------------------------
    // * load state codes
    // * returns a map of merchant country + state code to State.ISO Code object
    // * Note key will be country isocode + '-' + state iso code
    private static Map<String, pw_cc__State__c> loadMerchantStateCodes(Set<String> merchantCountryCodes, Set<String> merchantStateCodes)
    {
        Map<String, pw_cc__State__c> rtn = new Map<String, pw_cc__State__c>();
        if (merchantStateCodes != null && merchantStateCodes.size() > 0)
        {

            for(pw_cc__State__c ccState : [select Id,
                                                  pw_cc__IsoCode__c,
                                                  pw_cc__Country__c,
                                                  pw_cc__Country__r.pw_cc__IsoCode_3__c
                                             from pw_cc__State__c
                                            where pw_cc__IsoCode__c in :merchantStateCodes
                                              and pw_cc__Country__r.pw_cc__IsoCode_3__c in :merchantCountryCodes])
            {
                String key = ccState.pw_cc__Country__r.pw_cc__IsoCode_3__c + '-' + ccState.pw_cc__IsoCode__c;
                rtn.put(key, ccState);
                //rtn.put(ccState.pw_cc__IsoCode__c, ccState);
            }

        }
        return rtn;
    }

    // --- convenient logging....

    private static boolean logError(String logMessage)
    {
        return logDetails(null, logMessage, psaIntegrationUtils.LOG_TYPE_ERROR);
    }

    private static boolean logInfo(String logMessage)
    {
        return logDetails(null, logMessage, psaIntegrationUtils.LOG_TYPE_INFORMATION);
    }

    private static boolean logDetails(String refId, String logMessage, String logType)
    {
        logMessage = logMessage != null && logMessage.length() > 255 ? logMessage.substring(0, 254) : logMessage;
        return psaIntegrationUtils.writeLogEntry(
                refId,
                'Card Transactions',
                'Card Transactions',
                logType,
                logMessage,
                null,
                null,
                null);
    }

// items....need to then delete expenses, then update card transactions.....
//


    // Called when an 'unapproved' itemized expense record is deleted!
    // --- (from expense trigger handler!!)
    // - updates the card transaction item id status to be 'Unassigned',
    //   to allow the itemized transaction to appear in the users card transaction
    //    listing
    public static Boolean unassignCardTransactionItems(Set<Id> cardTransactionItemIds)
    {
        Boolean rtn = true;

        // logic for handling triggered recurrsion
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactionItems')) {
            System.debug('Skipping psaCardTransactionLoader.unassignCardTransactionItems() method due to trigger recursion prevention');
            return rtn;
        }
        psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionLoader.unassignCardTransactionItems');

        // ignore calls when executed from card transaction item trigger
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionItemTriggerHandler.unassignCardTransactionItems')) {
            System.debug('Skipping psaCardTransactionItemTriggerHandler.unassignCardTransactionItems() method due to trigger recursion prevention');
            return rtn;
        }


        try
        {
            if (cardTransactionItemIds != null && cardTransactionItemIds.size() > 0)
            {

                PSA_Card_Transaction__c[] cardTransToUp = new PSA_Card_Transaction__c[]{};

                Set<Id> cardTransIds = new Set<id>();

                PSA_Card_Transaction_Item__c[] cardTransItems = new PSA_Card_Transaction_Item__c[]{};

                for (PSA_Card_Transaction_Item__c psacti : [
                    select id,
                            PSA_Card_Transaction__c
                    from PSA_Card_Transaction_Item__c
                    where id in :cardTransactionItemIds ])
                {
                    cardTransIds.add(psacti.PSA_Card_Transaction__c);

                    cardTransItems.add(psacti);
                }

                if (cardTransIds != null && cardTransIds.size() > 0)
                {
                    PSA_Card_Transaction__c[] transToUnassign = [
                        select id, PSA_Status__c, PSA_Charge_Type__c, PSA_Previously_Entered__c
                        from PSA_Card_Transaction__c
                        where id in :cardTransIds
                    ];
                    if (transToUnassign != null && transToUnassign.size() > 0)
                    {
                        for (PSA_Card_Transaction__c cardTrans : transToUnassign)
                        {
                            cardTrans.PSA_Status__c = 'Unassigned';
                            cardTrans.PSA_Charge_Type__c = '';
                            cardTrans.PSA_Previously_Entered__c = false;

                        }
                        update transToUnassign;

                        // now remove expense report association (vr rule keeps us from doing this at the same time as setting the status)
                        for (PSA_Card_Transaction__c c : transToUnassign)
                        {
                            c.PSA_Expense_Report__c = null;
                        }
                        update transToUnassign;
                    }
                }


                //// Now...need to handle case when part of an itemized card transaciton expense is deleted
                //// remove un-approved expenses, which may still be associated
                //// with the reverted transaction
                pse__Expense__c[] associatedExpenses = [select id,
                                                               PSA_Card_Transaction_Item__c,
                                                               pse__Approved__c
                                                          from pse__Expense__c
                                                         where PSA_Card_Transaction_Item__c in :cardTransactionItemIds
                                                           and pse__Approved__c = false];



// ERROR psaCardTransactionLoader.unassignCardTransactionItems:
// Delete failed. First exception on row 0 with id a6d290000000I2MAAU;
// first error: SELF_REFERENCE_FROM_TRIGGER, Object (id = a6d290000000I2M)
// is currently in trigger psaCardTransactionItem, there

                if (cardTransItems != null && cardTransItems.size() > 0)
                {
                    //for (PSA_Card_Transaction_Item__c cardItem : transItems)
                    //{
                    //    cardItem.PSA_Status__c = 'Unassigned'; // set status to 'unassigned'
                    //    cardItem.PSA_Expense_Report__c = null; // clear report!
                    //}

                    delete cardTransItems;
                }

                //// attempt to remove expenses....if any!!!!
                if (associatedExpenses != null && associatedExpenses.size() > 0)
                {
                    delete associatedExpenses;
                }


            }
        }
        catch(Exception e)
        {
            logError('ERROR psaCardTransactionLoader.unassignCardTransactionItems: ' + e.getMessage());
            rtn = false;
        }

        return rtn;
    }

    // remove assocaited expense, which will trigger card transaction and item reversion
    public static Boolean handleExpenseReportDelete(Set<Id> deletedExpReportIds)
    {
        Boolean rtn = true;

        try
        {
            if (deletedExpReportIds != null && deletedExpReportIds.size() > 0)
            {
                Set<Id> cardTransItemIdsRetrieved = new Set<Id>();
                pse__Expense__c[] delRptExpenses = [
                        select id, pse__Expense_Report__c, PSA_Card_Transaction_Item__c, PSA_Card_Transaction__c
                        from pse__Expense__c
                        where pse__Expense_Report__c in :deletedExpReportIds];

                // remove assocaited expense, which will trigger card transaction and item reversion
                if (delRptExpenses != null && delRptExpenses.size() > 0)
                {
                    for(pse__Expense__c e : delRptExpenses) {
                        if (e.PSA_Card_Transaction_Item__c != null) {
                            cardTransItemIdsRetrieved.add(e.PSA_Card_Transaction_Item__c);
                        }
                    }
                    delete delRptExpenses;
                }

                // now need to lookup transaction items, currently not associated with an expense, but to the expense report...
                PSA_Card_Transaction_Item__c[] transItems = [
                    select id, PSA_Expense_Report__c
                    from PSA_Card_Transaction_Item__c
                    where PSA_Expense_Report__c in :deletedExpReportIds
                    and id not in :cardTransItemIdsRetrieved];

                if (transItems != null && transItems.size() > 0)
                {
                    delete transItems;
                }
            }

        }
        catch(Exception e)
        {
            logError('ERROR psaCardTransactionLoader.unassigniCardTransactions: ' + e.getMessage());
            rtn = false;
        }


        return rtn;
    }



    // called when an 'unapproved' expense, associated with a psa card transaction, is deleted
    // or a card transaction item, (for a transaction with associated un-approved expenses only)
    //
    public static Boolean unassignCardTransactions(Set<Id> cardTransactionIds)
    {
        Boolean rtn = true;

        // logic for handling triggered recurrsion
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactions')) {
            System.debug('Skipping psaCardTransactionLoader.unassignCardTransactions() method due to trigger recursion prevention');
            return rtn;
        }
        psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionLoader.unassignCardTransactions');

        try
        {
            if (cardTransactionIds != null && cardTransactionIds.size() > 0)
            {
                Set<Id> removedExpRptIds = new Set<Id>();
                PSA_Card_Transaction__c[] cardTrans = [select id, PSA_Status__c, PSA_Charge_Type__c, PSA_Expense_report__c, PSA_Previously_Entered__c from PSA_Card_Transaction__c where id in :cardTransactionIds];
                if (cardTrans != null && cardTrans.size() > 0)
                {
                    for (PSA_Card_Transaction__c c : cardTrans)
                    {
                        c.PSA_Status__c = 'Unassigned';
                        c.PSA_Charge_Type__c = '';
                        c.PSA_Previously_Entered__c = false;

                        if (c.PSA_Expense_Report__c != null)
                        {
                             removedExpRptIds.add(c.PSA_Expense_Report__c);
                        }
                    }
                    update cardTrans;
/////
//      when expense report is deleted.....
// 1) lookup card trasnaction items....remove 'em
// 2) lookup card transactions (not part of )    ....unassign 'em
                    // Now...need to grab all expenses for the expense report...and remove those!!!!!!
                    // remove un-approved expenses, which may still be associated
                    // with the reverted transaction
                    if (removedExpRptIds != null && removedExpRptIds.size() > 0)
                    {
                            pse__Expense__c[] associatedExpenses = [select id,
                                                                           PSA_Card_Transaction__c,
                                                                           pse__Approved__c
                                                                      from pse__Expense__c
                                                                     where PSA_Card_Transaction__c in :cardTransactionIds
                                                                       and pse__Approved__c = false
                                                                       and pse__Expense_Report__c in :removedExpRptIds];
                            if (associatedExpenses != null && associatedExpenses.size() > 0)
                            {
                                delete associatedExpenses;

                            }


                            // removing any other card transaction items associated to the expense report!
                            PSA_Card_Transaction_Item__c[] transItems = [select id,
                                                                               PSA_Card_Transaction__c
                                                                          from PSA_Card_Transaction_Item__c
                                                                         where PSA_Card_Transaction__c in :cardTransactionIds
                                                                           AND PSA_Expense_Report__c in :removedExpRptIds];

                            if (transItems != null && transItems.size() > 0)
                            {
                                // --- remove any transaction items associated....
                                delete transItems;
                            }


                            // !!!!!
                            // now remove expense report association (vr rule keeps us from doing this at the same time as setting the status)
                            for (PSA_Card_Transaction__c c : cardTrans)
                            {
                                c.PSA_Expense_Report__c = null;
                            }
                            update cardTrans;

                    }

                }
            }
        }
        catch(Exception e)
        {
            logError('ERROR psaCardTransactionLoader.unassigniCardTransactions: ' + e.getMessage());
            rtn = false;
        }

        return rtn;
    }

    // ------------------------------------------------------------------------
    // Called from process builder when user field is changed
    // - looks up and sets resource and owner based on specific user
    // ------------------------------------------------------------------------
    @InvocableMethod(
        label='Sets Owner and Resource based on the Salesforce User'
        description='Sets the PSA Card Transaction owner and resource fields based on the PSA Card Transaction User field')
    public static void syncResourceAndOwnerFromUser(List<PSA_Card_Transaction__c> cardTransactions)
    {
        if (cardTransactions != null && cardTransactions.size() > 0)
        {
            Set <Id> userIds = new Set<Id>();
            Set<Id> cardTransIds = new Set<Id>();

            // collect the card transaction user ids...
            for (PSA_Card_Transaction__c ct : cardTransactions)
            {
                if (ct.PSA_Salesforce_User__c != null)
                {
                    userIds.add(ct.PSA_Salesforce_User__c);
                }
                cardTransIds.add(ct.id);
            }

            // lookup resources from users
            Map<String, Contact> userResourceMap =new Map<String, Contact>();
            if (userIds != null && userIds.size() > 0)
            {
                for (Contact resource :[ select id,
                                                pse__Salesforce_User__c,
                                                pse__Is_Resource__c,
                                                PSA_Worker_Id__c,
                                                pse__Is_Resource_Active__c,
                                                PSA_Resource_Review_Status__c
                                           from Contact
                                          where pse__Salesforce_User__c in :userIds ] )
                {
                    userResourceMap.put(resource.pse__Salesforce_User__c, resource);
                }
            }

            // set resource based on user
            if (userResourceMap != null && cardTransIds != null && cardTransIds.size() > 0)
            {
                PSA_Card_Transaction__c[] cardTransToUpdate = [select id,
                                                                      PSA_Salesforce_User__c,
                                                                      PSA_Resource__c,
                                                                      PSA_EmployeeId__c,
                                                                      OwnerId,
                                                                      PSA_Operations_Review__c,
                                                                      PSA_Operations_Review_Reason__c,
                                                                      PSA_Incurred_Country__c,
                                                                      PSA_Incurred_State_Province__c,
                                                                      PSA_Merchant_State_Province__c
                                                                 from PSA_Card_Transaction__c
                                                                where id in :cardTransIds];

                if (cardTransToUpdate != null && cardTransToUpdate.size() > 0)
                {
                    for (PSA_Card_Transaction__c ct : cardTransToUpdate)
                    {
                        if (ct.PSA_Salesforce_User__c != null)
                        {
                            // attempt to set resource and owner from user, if resource is supplied
                            Contact resource = userResourceMap.get(ct.PSA_Salesforce_User__c);
                            if (resource != null)
                            {
                                ct.OwnerId = ct.PSA_Salesforce_User__c; // set owner to user
                                ct.PSA_Resource__c = resource.id;       // set the resource based on the user
                            }

                            // perform verification that the card transaction no longer needs operations review
                            verifyIfOperationsReviewRequired(ct, resource);
                        }
                        else
                        {
                            ct.PSA_Resource__c = null; // clear the resource
                            verifyIfOperationsReviewRequired(ct, null); // trigger operations review required
                        }
                    }

                    update cardTransToUpdate;
                }
            }

        }
    }
}