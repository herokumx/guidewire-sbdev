/**************************************************************************************
// Name         : psaCardTransactionItemTriggerHandler
// Date         : March 6, 2015
// Author       : CLD Partners
// Description  : psaCardTransactionItemTriggerHandler;
//                -- Contains before delete logic to ensure card transaction items are
//                   not part of an itemized card transaction associated with an
//                   approved expense.
//
***************************************************************************************/
public with sharing class psaCardTransactionItemTriggerHandler  implements psaITriggerHandler
{

// ################ START UPDATE
    Set<Id> cardTransactionItemsWithApprovedExpense = new Set<Id>();

    Set<Id> cardTransactionsWithUnapprovedExpense = new Set<Id>();

    // card transaction item id to expense id
    //Map<Id, Id> cardTransItemIdToExpenseId = new Map<Id, Id>();

    Set<Id> expenseIdsToRemove = new Set<Id>();

Map<id, pse__Expense__c> cardTransItemToExpense = new map<id, pse__Expense__c>();


    /**************************************************************************************
    // constructor
    ***************************************************************************************/
    public psaCardTransactionItemTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore()
    {
        // gather the card transaction items to be deleted
        if (Trigger.isBefore && Trigger.isDelete)
        {
            Set<Id> cardTransactionItemIds = new Set<Id>();
            for (psa_card_transaction_item__c a : (psa_card_transaction_item__c[]) Trigger.old)
            {
                if (a != null && a.PSA_Card_Transaction__c != null)
                {
                    cardTransactionItemIds.add(a.id);
                }
            }

            // Create the collection of psa card transactions associated with approved expenses
            for (pse__Expense__c exp : [
                select id,
                       pse__Approved__c,
                       psa_card_transaction__c,
                       PSA_Card_Transaction_Item__c
                  from pse__Expense__c
                 where PSA_Card_Transaction_Item__c in :cardTransactionItemIds ])
            {
                if (exp.pse__Approved__c == true)
                {
                    cardTransactionItemsWithApprovedExpense.add(exp.PSA_Card_Transaction_Item__c);
                }
                else
                {
                    cardTransItemToExpense.put(exp.PSA_Card_Transaction_Item__c, exp);
                }

                //cardTransItemIdToExpenseId.put(exp.PSA_Card_Transaction_Item__c, exp.id);
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
    public void beforeInsert(SObject so){}

    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){}

    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so)
    {
        // ensure the item to be deleted is not part of an itemized card transaction that
        // includes an approved expense
        psa_card_transaction_item__c cardTransactionItem = (psa_card_transaction_item__c) so;

        if (cardTransactionItem != null &&
            cardTransactionItem.id != null &&
            cardTransactionItemsWithApprovedExpense.contains(cardTransactionItem.id))
        {
            cardTransactionItem.addError('You can not delete an itemized record associated with an approved Expense record.');
        }
        else
        {
            if (cardTransactionItem.PSA_Card_Transaction__c != null)
            {
                cardTransactionsWithUnapprovedExpense.add(cardTransactionItem.PSA_Card_Transaction__c);

            }
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
    public void afterDelete(SObject so)
    {
        psa_card_transaction_item__c cardTransactionItem = (psa_card_transaction_item__c) so;
        if (cardTransactionItem != null && cardTransactionItem.PSA_Card_Transaction__c != null)
        {
            cardTransactionsWithUnapprovedExpense.add(cardTransactionItem.PSA_Card_Transaction__c);
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
        if (Trigger.isBefore && Trigger.isDelete)
        {

            if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactionItems')) {
                System.debug('Skipping psaCardTransactionItemTriggerHandler andFinally() method due to trigger recursion prevention');
                return;
            }
            // handle recursive, skip logic in card transaction loader!
            psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionLoader.unassignCardTransactionItems');
            psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionItemTriggerHandler.unassignCardTransactionItems');

            // logic for handling triggered recurrsion, when deleting from psaCardTransactionLoader...skip this!
            //if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactionItems'))
            //{
            //    System.debug('Skipping psaCardTransactionLoader.unassignCardTransactionItems() method due to trigger recursion prevention');
            //    //return rtn;
            //    return;
            //}
            //else
            //{
                if (cardTransactionsWithUnapprovedExpense != null && cardTransactionsWithUnapprovedExpense.size() > 0)
                {
                    // indicate we are running from this trigger....

                    //system.debug('\n &&&&&&&&&&&&& cardTransItemToExpense > \n ' + cardTransactionsWithUnapprovedExpense);
                    PSA_Card_Transaction__c[] cardTrans = [select id, PSA_Status__c, PSA_Charge_Type__c, PSA_Expense_report__c, PSA_Previously_Entered__c from PSA_Card_Transaction__c where id in :cardTransactionsWithUnapprovedExpense];
                    if (cardTrans != null && cardTrans.size() > 0)
                    {
                        for (PSA_Card_Transaction__c c : cardTrans)
                        {
                            c.PSA_Status__c = 'Unassigned';
                            c.PSA_Charge_Type__c = '';
                            c.PSA_Previously_Entered__c = false;
                        }
                        update cardTrans;

                        // now remove expense report association (vr rule keeps us from doing this at the same time as setting the status)
                        for (PSA_Card_Transaction__c c : cardTrans)
                        {
                            c.PSA_Expense_Report__c = null;
                        }
                        update cardTrans;
                    }
                }

                //system.debug('\n &&&&&&&&&&&&& cardTransItemToExpense > \n ' + cardTransItemToExpense);
                if (cardTransItemToExpense != null && cardTransItemToExpense.size() > 0)
                {
                    pse__Expense__c[] expenses = new pse__Expense__c[]{};
                    for (Id cardTransId : cardTransItemToExpense.keySet())
                    {
                        pse__Expense__c exp = cardTransItemToExpense.get(cardTransId);
                        if (exp != null)
                        {
                             expenses.add(exp);
                        }
                    }

                    if (expenses != null && expenses.size() > 0)
                    {
                        delete expenses;
                    }
                }
            //}


            //if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactions')) {
            //    System.debug('Skipping psaCardTransactionItemTriggerHandler andFinally() method due to trigger recursion prevention');
            //    return;
            //}
            //psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionLoader.unassignCardTransactions');


            //// grab the expense and delete it!
            //Set<Id> expIds = new Set<id>();
            //for (Id ctId : cardTransactionItemsWithUnapprovedExpense)
            //{
            //    if (cardTransItemIdToExpenseId.containsKey(ctId))
            //    {
            //        expIds.add(cardTransItemIdToExpenseId.get(ctId));
            //    }
            //}

            //if (expIds != null && expIds.size() > 0)
            //{
            //    pse__Expense__c[] expenses = [select id, psa_card_transaction_item__c from pse__Expense__c where id in :expIds];
            //    if (expenses != null && expenses.size() > 0)
            //    {
            //        delete expenses;
            //    }
            //}




            // psaCardTransactionLoader.unassignCardTransactionItems(cardTransactionItemsWithUnapprovedExpense);
        }
    }

// ############ END UPDATE...



 //   Set<Id> cardTransactionsWithApprovedExpense = new Set<Id>();
 //   Set<Id> cardTransactionsWithUnapprovedExpense = new Set<Id>();

 //   /**************************************************************************************
 //   // constructor
 //   ***************************************************************************************/
	//public psaCardTransactionItemTriggerHandler() {}

 //  /**************************************************************************************
 //   // Name        : bulkBefore
 //   // Description : This method is called prior to execution of a BEFORE trigger. Use
 //   //               this to cache any data required into maps prior to execution of the
 //   //               trigger.
 //   ***************************************************************************************/
 //   public void bulkBefore()
 //   {
 //       // gather the card transaction items to be deleted
 //       if (Trigger.isBefore && Trigger.isDelete)
 //       {
 //           Set<Id> cardTransactionIds = new Set<Id>();
 //           for (psa_card_transaction_item__c a : (psa_card_transaction_item__c[]) Trigger.old)
 //           {
 //               if (a != null && a.PSA_Card_Transaction__c != null)
 //               {
 //                   cardTransactionIds.add(a.PSA_Card_Transaction__c);
 //               }
 //           }

 //           // Create the collection of psa card transactions associated with approved expenses
 //           for (pse__Expense__c exp : [
 //               select id,
 //                      pse__Approved__c,
 //                      PSA_Card_Transaction__c
 //                 from pse__Expense__c
 //                where PSA_Card_Transaction__c in :cardTransactionIds
 //                  and pse__Approved__c <> false ])
 //           {
 //               cardTransactionsWithApprovedExpense.add(exp.PSA_Card_Transaction__c);
 //           }
 //       }
 //   }

 //   /**************************************************************************************
 //   // Name        : bulkAfter
 //   // Description : This method is called prior to execution of a AFTER trigger. Use
 //   //               this to cache any data required into maps prior to execution of the
 //   //               trigger.
 //   ***************************************************************************************/
 //   public void bulkAfter(){}

 //   /**************************************************************************************
 //   // Name        : beforeInsert
 //   // Description : This method is called iteratively for each record to be inserted
 //   //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and
 //   //               other iterative methods.
 //   ***************************************************************************************/
 //   public void beforeInsert(SObject so){}

 //   /**************************************************************************************
 //   // Name        : beforeUpdate
 //   // Description : This method is called iteratively for each record to be updated
 //   //               during a BEFORE trigger.
 //   ***************************************************************************************/
 //   public void beforeUpdate(SObject oldSo, SObject so){}

 //   /**************************************************************************************
 //   // Name        : beforeDelete
 //   // Description : This method is called iteratively for each record to be deleted
 //   //               during a BEFORE trigger.
 //   ***************************************************************************************/
 //   public void beforeDelete(SObject so)
 //   {
 //       // ensure the item to be deleted is not part of an itemized card transaction that
 //       // includes an approved expense
 //       psa_card_transaction_item__c cardTransactionItem = (psa_card_transaction_item__c) so;

 //       if (cardTransactionItem != null &&
 //           cardTransactionItem.PSA_Card_Transaction__c != null &&
 //           cardTransactionsWithApprovedExpense.contains(cardTransactionItem.PSA_Card_Transaction__c))
 //       {
 //           cardTransactionItem.addError('You can not delete an itemized record associated with an approved Expense record.');
 //       }
 //       else
 //       {
 //           if (cardTransactionItem.PSA_Card_Transaction__c != null)
 //           {
 //               cardTransactionsWithUnapprovedExpense.add(cardTransactionItem.PSA_Card_Transaction__c);
 //           }
 //       }
 //   }

 //   /**************************************************************************************
 //   // Name        : afterInsert
 //   // Description : This method is called iteratively for each record inserted
 //   //               during an AFTER trigger. Always put field validation in the 'After'
 //   //               methods in case another trigger has modified any values. The record
 //   //               is 'read only' by this point.
 //   ***************************************************************************************/
 //   public void afterInsert(SObject so){}

 //   /**************************************************************************************
 //   // Name        : afterUpdate
 //   // Description : This method is called iteratively for each record updated
 //   //               during an AFTER trigger.
 //   ***************************************************************************************/
 //   public void afterUpdate(SObject oldSo, SObject so){}

 //   /**************************************************************************************
 //   // Name        : afterDelete
 //   // Description : This method is called iteratively for each record deleted
 //   //               during an AFTER trigger.
 //   // Arguments   : SObject so - the object that initiated the trigger
 //   ***************************************************************************************/
 //   public void afterDelete(SObject so)
 //   {
 //       psa_card_transaction_item__c cardTransactionItem = (psa_card_transaction_item__c) so;
 //       if (cardTransactionItem != null && cardTransactionItem.PSA_Card_Transaction__c != null)
 //       {
 //           cardTransactionsWithUnapprovedExpense.add(cardTransactionItem.PSA_Card_Transaction__c);
 //       }


 //   }

 //   /**************************************************************************************
 //   // Name        : andFinally
 //   // Description : This method is called once all records have been processed by the
 //   //               trigger. Use this method to accomplish any final operations such as
 //   //               creation or updates of other records.
 //   // Arguments   : SObject so - the object that initiated the trigger
 //   ***************************************************************************************/
 //   public void andFinally()
 //   {
 //       if (Trigger.isAfter && Trigger.isDelete && cardTransactionsWithUnapprovedExpense != null && cardTransactionsWithUnapprovedExpense.size() > 0)
 //       {
 //           //if (psaTriggerMonitor.ExecutedTriggers.contains('psaCardTransactionLoader.unassignCardTransactions')) {
 //           //    System.debug('Skipping psaCardTransactionItemTriggerHandler andFinally() method due to trigger recursion prevention');
 //           //    return;
 //           //}
 //           //psaTriggerMonitor.ExecutedTriggers.add('psaCardTransactionLoader.unassignCardTransactions');


 //           psaCardTransactionLoader.unassignCardTransactions(cardTransactionsWithUnapprovedExpense);
 //       }
 //   }

}