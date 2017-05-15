/*********************************************************************************************** x
Name            : psaExpenseMatchCardTransactionController
Author          : CLD
Created Date    : July 2016

Usage           : Controller for the psaExpenseMatchCardTransaction page.
                : Allows for matching card transaction with specific expense report expenses
***********************************************************************************************/
public with sharing class psaExpenseMatchCardTransactionController
{
    // ----------------------------------------------------
    // - constructor
    // ----------------------------------------------------
    public psaExpenseMatchCardTransactionController(){}

    // ----------------------------------------------------
    // - standard controller constructor
    // ----------------------------------------------------
    public psaExpenseMatchCardTransactionController(ApexPages.StandardController stdController){}


    // ----------------------------------------------------
    // # Retrieves expense report, the pending expens report items, and pending card transactions for expense report resource.
    // # expenseReportId - String value of the expense report details to load
    // # returns mapped values for:
    // #                     expense report     - expenseReport with pending expense items ,
    // #                     card transactions  - pending cardTransactions for the resource
    // #
    // # Map<String, Object> rslt =  psaExpenseMatchCardTransactionController.initializeExpenseReportCardTransactions(expRptId);
    // ----------------------------------------------------
    @RemoteAction public static Map<String, Object> initializeExpenseReportCardTransactions(String expenseReportId)
    {
        if (String.isEmpty(expenseReportId))
        {
            return makeError('Please match transactions from an expesne report', 'initializeExpenseReportCardTransactions');
        }

        Map<String, Object> result = new Map<String, Object>();

        try
        {
            // load expense report and expense information

            // lookup exp report
            pse__Expense_Report__c[] ersById = [
                select Id,
                       Name,
                       pse__Billable__c,
                       pse__Resource__c,
                       pse__Resource__r.Name,
                       pse__First_Expense_Date__c,
                       pse__Resource__r.PSA_Home_Country__c,
                       pse__Status__c,
                       pse__Description__c
                  from pse__Expense_Report__c
                 where id = :expenseReportId
            ];

            if (ersById != null && ersById.size() > 0)
            {
               // verify report status is allowed
                Set<String> allowedStatuses = new Set<String>{
                    'Draft',
                    'Rejected'
                };

                // when not allowed, render error mesage
                if (!allowedStatuses.contains(ersById[0].pse__status__c))
                {
                    return makeError('Only Draft or Rejected expense reports can be matched!', 'expenseReportStatus');
                }
            }

            // lookup expenses and attachments
            // expenses (associated to non-previously entered card transactions)
            // and non-itemized expenses
            pse__Expense__c[] expenseLines = [
                select Id,
                        Name,

                        PSA_Card_Transaction__c,

                        PSA_Card_Transaction__r.PSA_Merchant_Name__c,
                        PSA_Card_Transaction__r.PSA_Merchant_State_Province__c,
                        PSA_Card_Transaction__r.PSA_Merchant_Country_Code__c,
                        PSA_Card_Transaction__r.CurrencyIsoCode,
                        PSA_Card_Transaction__r.PSA_Amount_in_Original_Currency__c,
                        PSA_Card_Transaction__r.PSA_Transaction_Date__c,
                        PSA_Card_Transaction__r.PSA_Posting_Date__c,

                        PSA_Card_Transaction__r.PSA_Previously_Entered__c,

                        PSA_Card_Transaction_Item__c,


                        pse__Expense_Report__c,
                        pse__Notes__c,
                        pse__Expense_Report__r.Name,
                        pse__Amount__c,

                        CurrencyIsoCode,
                        pse__Description__c,
                        pse__Expense_Date__c,
                        pse__Resource__c,
                        pse__Type__c,
                        pse__Billable__c,
                        pse__Status__c,
                        PSA_Receipt_Type__c,
                        PSA_Pre_Match_Amount__c,
                        OwnerId,

                        ( SELECT Id,  Name, BodyLength, ParentId FROM Attachments )

                   from pse__Expense__c
                  where pse__Expense_Report__c = :expenseReportId
                    and PSA_Card_Transaction__r.PSA_Previously_Entered__c <> true
                    and PSA_Card_Transaction_Item__c = null
            ];


            if (ersById != null && ersById.size() > 0)
            {
                pse__Expense_Report__c exrpt = ersById[0];
                result.put('expenseReport', exrpt);
                result.put('expenseLines', (expenseLines != null) ? expenseLines : new pse__Expense__c[]{});


                // lookup card transactions for resource associated to expense report
                String resourceId = exrpt.pse__Resource__c;
                Map<String, Object> transPayload = new Map<String, Object>();

                Map<String, Object> transResponse = lookupCardTransactions(exrpt.pse__Resource__c, JSON.serialize(transPayload));
                if (transResponse.containsKey('errorCode'))
                {
                    return transResponse;
                }
                else
                {
                    result.put('cardTransactions', transResponse);
                }

            }
            else
            {
                return makeError('Please match transactions from an expesne report', 'initializeExpenseReportCardTransactions');
            }

        }
        catch(Exception e)
        {
            return makeError(e.getMessage(), 'lookup-card-trans');
        }

        return result;

    }



    // store expense report info / resource in state....
    // then pass to the remote actions from page.....


    // ------------------------------------------------------------------------
    // # Retrieves card transactions for the user based on from/to date range
    // # jsonFilterFields : JSON serialized string of transaction fields to filter:
    // # psaResourceId - required string value for the expense report resource id
    //      - (example from Javascript:)
    //          var filterFields = {
    //                filterStartDate: '2016-01-01',
    //                  filterEndDate: '2017-01-01'
    //          }
    //
    //
    // Map<String, Object> rslt =  lookupCardTransactions.initializeExpenseReportCardTransactions(psaResourceId, JSON.serialize(new Map<String, Object>()));
    // ------------------------------------------------------------------------
    @RemoteAction public static Map<String, Object> lookupCardTransactions(String psaResourceId, String jsonFilterFields)
    {
        Map<String, Object> result = new Map<String, Object>();

        Map<String, Object> incomingJsonFilterFields = null;
        try {
            incomingJsonFilterFields = (Map<String, Object>)JSON.deserializeUntyped(jsonFilterFields);
        } catch (JSONException je) {
            return makeError(je.getMessage(), 'JSON_PARSER_ERROR');
        }
        try
        {
            String filterStartDate = null;
            if (incomingJsonFilterFields.containsKey('filterStartDate')) {
                filterStartDate = String.valueOf(incomingJsonFilterFields.get('filterStartDate'));
            }

            String filterEndDate = null;
            if (incomingJsonFilterFields.containsKey('filterEndDate')) {
                filterEndDate = String.valueOf(incomingJsonFilterFields.get('filterEndDate'));
            }


            // These are the columns were going to retrieve from the PSA_CARD_TRANSACTION
            // using the cusomized WHERE clause based on our filter
            String[] psaCardTransactionColumns = new String[]{
                  'Id',
                  'CurrencyIsoCode',
                  'Name',
                  'OwnerId',
                  'PSA_Amount_in_Original_Currency__c',
                  'PSA_Amount_in_Billing_Currency__c',
                  'PSA_EmployeeId__c',
                  'PSA_Expense_Type__c',
                  'PSA_FX__c',
                  'PSA_Expense_Report__c',
                  'PSA_Merchant_Country_Code__c',
                  'PSA_Merchant_Name__c',
                  'PSA_Merchant_Postal_Code__c',
                  'PSA_Merchant_State_Province__c',
                  'PSA_Posting_Date__c',
                  'PSA_Processor_Transaction_Id__c',
                  'PSA_Salesforce_User__c',
                  'PSA_Status__c',
                  'PSA_Incurred_Country__c',
                  'PSA_Incurred_State_Province__c',
                  'PSA_Charge_Type__c',
                  'PSA_Resource__c',
                  'PSA_Resource_Inactive__c',
                  'PSA_Previously_Entered__c',
                  'PSA_Invalid_Transaction__c',
                  'PSA_Operations_Review__c',
                  'PSA_Operations_Review_Reason__c',
                  'PSA_Operations_Review_Comments__c',
                  'PSA_Discard__c',
                  'PSA_Transaction_Date__c',
                  'PSA_Remaining_Transaction_Amount__c',
                  'PSA_Assigned_Itemized_Amount__c',
                  'PSA_Transaction_Id__c '
            };

            // generate the soql for retrieving card transactions
            String soql = '';
            soql += ' SELECT ' + String.join(psaCardTransactionColumns, ',') + ' ';

            //soql += ',   ( SELECT Id, ';
            //soql += '            Name, ';
            //soql += '            BodyLength, ';
            //soql += '            ParentId ';
            //soql += '       FROM Attachments ) ';

            soql += '   FROM PSA_Card_Transaction__c ';
            soql += '  WHERE PSA_Resource__c = \'' + psaResourceId + '\'';
            soql += '    AND PSA_Status__c <> \'Assigned\' ';
            soql += '    AND PSA_Operations_Review__c <> true ';
            soql += '    AND PSA_Previously_Entered__c <> true ';
            soql += '    AND PSA_Invalid_Transaction__c <> true ';
            soql += '    AND PSA_Discard__c <> true ';

// filter out itemized transactions....
            soql += '    AND PSA_Assigned_Itemized_Amount__c = 0 ';

            soql += '    AND PSA_Discard__c <> true ';
            soql += '    AND PSA_Charge_Type__c <> \'Personal\' ';


            if (String.isNotEmpty(filterStartDate) && filterStartDate.length() == 10)
            {
                soql += ' AND PSA_Transaction_Date__c >= ' + filterStartDate;
            }
            if (String.isNotEmpty(filterEndDate) && filterEndDate.length() == 10)
            {
                soql += ' AND PSA_Transaction_Date__c <= ' + filterEndDate;
            }

            // retrieve card transactions
            PSA_Card_Transaction__c[] userCardTransactions = Database.query(soql);

            result.put('records', userCardTransactions);
            result.put('size', userCardTransactions.size());

            return result;

        }
        catch(Exception e)
        {
            return makeError(e.getMessage(), 'lookup-card-trans');
        }
    }

    // ------------------------------------------------------------------------
    // # Matches expense items to card transactions
    // # jsonExpCardMatchFields : JSON serialized list of expense ids to card transactions ids to match
    //      - (example from Javascript:)
    //          var filterFields = [{
    //              { expenseId: 'abc123', cardTransactionId: '123abc' },
    //              { expenseId: 'def456', cardTransactionId: '456def' }
    //           ];

    // # jsonExpIdMatchToRemove : List of expense ids to remove.....

    // Map<String, Object> rslt =  lookupCardTransactions.matchExpenseCardTransactions(expRptId, JSON.serialize(new list<object>()));
    // ------------------------------------------------------------------------
    @RemoteAction public static Map<String, Object> matchExpenseCardTransactions(String expenseReportId,
                                                                                 String jsonExpCardMatchFields,
                                                                                 String jsonExpIdMatchToRemove)
    {
        Map<String, Object> result = new Map<String, Object>();


        // -----
        // PARSE expense ids for mappings to remove (clear card transaction expense lookup, set card trans status back to unassigned)
        Set<String> expIdsToRemove = new Set<String>();
        try {
            List<Object> expidObjList = (List<Object>) JSON.deserializeUntyped(jsonExpIdMatchToRemove);
            if (expidObjList != null && expidObjList.size() > 0)
            {
                for (Object objItem : expidObjList)
                {
                    String eid = String.valueOf(objItem);
                    expIdsToRemove.add(eid);
                }

                // now need to load expenses and card transactions to 'remove...'

            }
        } catch (JSONException je) {
            return makeError(je.getMessage(), 'JSON_PARSER_ERROR');
        }


        // PARSE New Mappings to create!

        // parsed mapping of expense id to card transaction id to "match"
        Set<String> expenseIds = new Set<String>();
        Set<String> cardTransIds = new Set<String>();

        // maintain mapping of card transaction to expense and expens to card transactions....
        Map<String, String> parsedExpenseIdToCardTrans = new Map<String, String>();
        Map<String, String> parsedCardTransToExpenseId = new Map<String, String>();
        try {
            List<Object> objList = (List<Object>)JSON.deserializeUntyped(jsonExpCardMatchFields);
            if (objList != null && objList.size() > 0)
            {
                for (Object obj : objList)
                {
                    Map<String, Object> objMap = (Map<String, Object>)obj;
                    if (objMap != null && objMap.containsKey('expenseId') && objMap.containsKey('cardTransactionId'))
                    {
                        String expenseId = String.valueOf(objMap.get('expenseId'));
                        String cardTransactionId = String.valueOf(objMap.get('cardTransactionId'));

                        if (String.isNotEmpty(expenseId) && String.isNotEmpty(cardTransactionId))
                        {
                            expenseIds.add(expenseId);
                            cardTransIds.add(cardTransactionId);

                            parsedExpenseIdToCardTrans.put(expenseId, cardTransactionId);

                            parsedCardTransToExpenseId.put(cardTransactionId, expenseId);
                        }
                    }
                }
            }

        } catch (JSONException je) {
            return makeError(je.getMessage(), 'JSON_PARSER_ERROR');
        }

        //
        Savepoint savePoint = Database.setSavepoint();

        try
        {
            // HANDLE REMOVING ANY EXISTING ASSOCIATIONS
            if (expIdsToRemove.size() > 0)
            {
                disassociateExpenseAndCardTrans(expIdsToRemove);
            }

            // Does matching...
            if (parsedExpenseIdToCardTrans != null && parsedExpenseIdToCardTrans.size() > 0 &&
                 expenseIds != null && expenseIds.size() > 0 &&
                 cardTransIds != null && cardTransIds.size() > 0)
            {

                //LOAD NEW ORIGINAL EXPENSE AMOUNT FIELD
                // --- PSA_Pre_Match_Amount__c ??
                // load expenses....
                Map<Id, pse__Expense__c> expenseItems = new Map<Id, pse__Expense__c>(
                    [
                    select id,
                           CurrencyIsoCode,
                           PSA_Card_Transaction__c,
                           psa_card_transaction_item__c,
                           pse__Amount__c,
                           pse__Expense_Date__c,
                           GW_Card_Reimbursement_Amount__c,
                           PSA_GW_Card__c,
                           PSA_Pre_Match_Amount__c
                    from pse__Expense__c
                    where id in :expenseIds]);

                // load card transactions...need to handle partial itemizations..
                Map<Id, PSA_Card_Transaction__c> cardTransactions = new Map<Id, PSA_Card_Transaction__c>();


                for (PSA_Card_Transaction__c ct : [
                        select Id,
                               CurrencyIsoCode,
                               PSA_Assigned_Itemized_Amount__c,
                               PSA_Transaction_Date__c,
                               PSA_Expense_Report__c,
                               PSA_Remaining_Transaction_Amount__c,
                               PSA_Amount_in_Original_Currency__c,
                               PSA_Amount_in_Billing_Currency__c,
                               PSA_Merchant_Name__c,
                               PSA_Merchant_State_Province__c,
                               PSA_Merchant_Country_Code__c,
                               PSA_Status__c
                        from PSA_Card_Transaction__c
                        where id = :cardTransIds
                    ])
                {
                    String expId = parsedCardTransToExpenseId.get(ct.id);

                    ct.PSA_Status__c = 'Assigned';

                    cardTransactions.put(ct.id, ct);
                }

                // create transaction items for partially itemized transactions!!!!

                // match em.....
                Map<Id, pse__Expense__c> expensesToUpdate =new Map<Id, pse__Expense__c>();
                PSA_Card_Transaction__c[] cardTransToUpdate = new PSA_Card_Transaction__c[]{};


                // ------------------------------------------------------------
                // ------------------------------------------------------------
                // !!!!! workaround vr rule forcing us to make 2 updates
                //        - one that updates the amounts
                //        - next update associates our card trans!

                Map<Id, String> expenseIdToCardTransactionId = new Map<Id, String>();

                Map<Id, pse__Expense__c> expenseIdToExpense = new Map<Id, pse__Expense__c>();


                for (String expId : expenseIds)
                {
                    pse__Expense__c expItem = expenseItems.get(expId);
                    if (expItem != null)
                    {
                        String cardTransId = parsedExpenseIdToCardTrans.get(expId);
                        if (cardTransId != null && cardTransactions.containsKey(cardTransId))
                        {
                            PSA_Card_Transaction__c cardTrans = cardTransactions.get(cardTransId);
                            cardTrans.PSA_Status__c = 'Assigned';

                            cardTransToUpdate.add(cardTrans); // collect for update

                            // collect for the 2nd expense item update
                            // for working around vr rule!
                            expenseIdToCardTransactionId.put(expItem.id, cardTransId);
                            // expItem.PSA_Card_Transaction__c = cardTrans.id;

                            // TODO: include more items that are needed to be set on the expense
                            expItem.GW_Card_Reimbursement_Amount__c = cardTrans.PSA_Amount_in_Billing_Currency__c;
                            expItem.PSA_GW_Card__c                  = true; // maybe this is needed???
                            expItem.CurrencyIsoCode                 = cardTrans.CurrencyIsoCode;
                            expItem.PSA_Card_Transaction__c         = null; // clear so we can update amounts...and get around validation rule!
                            expItem.pse__Amount__c                  = cardTrans.PSA_Amount_in_Billing_Currency__c;   // default (not itemized)
                            expItem.pse__Expense_Date__c            = cardTrans.PSA_Transaction_Date__c;
                            expItem.pse__Non_Reimbursible__c        = true; //  force the non-reimbursable checkbox to true if a Credit Card transaction is matched?

                            if (String.isEmpty(expItem.pse__Description__c)) {
                                expItem.pse__Description__c  = psaExpenseMatchCardTransactionController.buildCardTransactionDescription(cardTrans);
                            }

                            // collect for updating...
                            expensesToUpdate.put(expItem.id, expItem);
                        }
                    }
                }

                if (expensesToUpdate != null && expensesToUpdate.size() > 0)
                {
                    update expensesToUpdate.values();

                    // now we need update the expenses again, setting the card transaction!
                    for (pse__Expense__c exp : expensesToUpdate.values())
                    {
                        String cardId = expenseIdToCardTransactionId.get(exp.Id);
                        if (String.isNotEmpty(cardId))
                        {
                            exp.PSA_Card_Transaction__c = cardId;
                        }
                    }

                    update expensesToUpdate.values();

                }
                if (cardTransToUpdate != null && cardTransToUpdate.size() > 0)
                {
                    update cardTransToUpdate;
                }
            }

        }
        catch(Exception e)
        {
            if (savePoint != null)
            {
                Database.rollback(savePoint);
            }

            return makeError(e.getMessage(), 'DML_ERR');
        }


        return initializeExpenseReportCardTransactions(expenseReportId);
    }



    // --
    // - appends the cc description into the expense
    public static String buildCardTransactionDescription( PSA_Card_Transaction__c cardTransaction)
    {
        String rtn = '';
        if (cardTransaction != null)
        {
            //String expDescription = expense.pse__Description__c;
            //expDescription = expDescription == null ? '' : expDescription + '  ';
            if (String.isNotEmpty(cardTransaction.PSA_Merchant_Name__c))
            {
                rtn += cardTransaction.PSA_Merchant_Name__c + ' ';
            }
            if (String.isNotEmpty(cardTransaction.PSA_Merchant_State_Province__c))
            {
                rtn += cardTransaction.PSA_Merchant_State_Province__c  + ', ';
            }
            if (String.isNotEmpty(cardTransaction.PSA_Merchant_Country_Code__c))
            {
                rtn += cardTransaction.PSA_Merchant_Country_Code__c;
            }

            rtn = rtn.length() > 255 ? rtn.substring(0, 250) : rtn;


        }
        return rtn;

    }



    // ******8
    public static void disassociateExpenseAndCardTrans(Set<String> expenseIds)
    {
        if (expenseIds != null && expenseIds.size() > 0)
        {
// TODO... PULLBACK NEW ORIGINAL AMOUNT FIELD then evaluate and use it to revert EXPENSE AMOUNT....

            // load expenses, and gather card transactions to unassign
            Set<Id> cardTransIdsToUnassign = new Set<Id>();
            pse__Expense__c[] expsToDisassociate = new pse__Expense__c[]{};
            for (pse__Expense__c e : [
                select id,
                       PSA_Card_Transaction__c,
                       psa_card_transaction_item__c,
                       pse__Amount__c,
                       pse__Expense_Date__c,
                       GW_Card_Reimbursement_Amount__c,
                       PSA_GW_Card__c,
                       PSA_Pre_Match_Amount__c
                  from pse__Expense__c
                 where id in :expenseIds ])
            {
                cardTransIdsToUnassign.add(e.PSA_Card_Transaction__c);
                expsToDisassociate.add(e);

            }

            // load card transactions
            if (cardTransIdsToUnassign != null && cardTransIdsToUnassign.size() > 0)
            {
                PSA_Card_Transaction__c[] unassignCardTrans = new PSA_Card_Transaction__c[]{};
                for (PSA_Card_Transaction__c pct : [
                    select id, PSA_Status__c
                    from PSA_Card_Transaction__c
                    where id in :cardTransIdsToUnassign])
                {
                    if (pct != null)
                    {
                        pct.PSA_Status__c = 'Unassigned';
                        unassignCardTrans.add(pct);
                    }
                }

                if (expsToDisassociate != null && expsToDisassociate.size() > 0)
                {

                    for (pse__Expense__c exp : expsToDisassociate)
                    {
                        // clear card transaction association
                        exp.PSA_Card_Transaction__c = null;

                        // reset amounts and indicators
                        exp.GW_Card_Reimbursement_Amount__c = null;
                        exp.PSA_GW_Card__c = false;
                        if (exp.PSA_Pre_Match_Amount__c != null) {
                            exp.pse__Amount__c = exp.PSA_Pre_Match_Amount__c;
                            exp.PSA_Pre_Match_Amount__c = null;
                        }
                    }

                    update expsToDisassociate;

                }

                if (unassignCardTrans != null && unassignCardTrans.size() > 0)
                {
                    update unassignCardTrans;
                }
            }
        }
    }

    // convenient method to make an error for returning to the ui!
    private static Map<String, Object> makeError(String errMsg, String errCode)
    {
        //gen.writeStringField('message', String.isNotEmpty(message) ? message : '') ;
        //gen.writeStringField('errorCode', String.isNotEmpty(errorCode) ? errorCode : 'ERR') ;
        return new Map<String, Object>{
            'errorCode' => errCode,
            'message' => errMsg
        };
    }


}