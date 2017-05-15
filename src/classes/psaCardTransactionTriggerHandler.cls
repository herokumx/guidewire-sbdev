/**************************************************************************************
// Name         : psaCardTransactionTriggerHandler
// Date         : August 2016
// Author       : CLD Partners
// Description  : psaCardTransactionTriggerHandler;
//                -- when previously entered is unchecked, we remove associated expense and revert status back to 'unassigned'
//
***************************************************************************************/
public with sharing class psaCardTransactionTriggerHandler  implements psaITriggerHandler
{
    /**************************************************************************************
    // constructor
    ***************************************************************************************/
    public psaCardTransactionTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){}

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


// --- collect the card transactions to unassign:
// ---
    public Set<Id> transactionIdsToUnassign = new Set<Id>();

    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so)
    {
        PSA_Card_Transaction__c oldTrans = (PSA_Card_Transaction__c) oldSo;
        PSA_Card_Transaction__c newTrans = (PSA_Card_Transaction__c) so;

        // collect the transactions which were previoulsy entered, but this update will uncheck previously entered
        if (oldTrans.PSA_Previously_Entered__c == true && newTrans.PSA_Previously_Entered__c != true)
        {
            // unassign....
            newTrans.PSA_Status__c = 'Unassigned';
            transactionIdsToUnassign.add(newTrans.id);
        }
    }

    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so){}

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
    ***************************************************************************************/
    public void andFinally()
    {
        if (transactionIdsToUnassign != null && transactionIdsToUnassign.size() > 0)
        {
            // lookup expenses to to unassociate
            pse__Expense__c[] associatedExpenses = [
                select Id, PSA_Card_Transaction__c,GW_Card_Reimbursement_Amount__c,PSA_GW_Card__c
                from pse__Expense__c
                where PSA_Card_Transaction__c in :transactionIdsToUnassign
            ];

            if (associatedExpenses != null && associatedExpenses.size() > 0)
            {
                for (pse__Expense__c exp : associatedExpenses)
                {
                    exp.PSA_Card_Transaction__c = null;
                    exp.GW_Card_Reimbursement_Amount__c = null;
                    exp.PSA_GW_Card__c = false;
                }

                update associatedExpenses;
            }

        }
    }

}