/**************************************************************************************
// Name          : psaAttachmentTriggerHandler
// Date          : June 2015
// Description   : Handles all inserts/updates/deletes called by the psaBillingEventItem trigger
// Author        : CLD Partners
// Revisions     : 2015-09-17  Klassen  Modified to update the Billing Event.Billing Event Docs Attached Date
//               :  when the Billing Event Attachments have been added to by Conga
//               : 
***************************************************************************************/
public with sharing class psaAttachmentTriggerHandler implements psaITriggerHandler{
    
    Map<Id, pse__Expense__c> expenseMap;
    Map<Id, pse__Billing_Event__c> eventMap;
    Map<ID, Integer> attachCountPerExpense;
    //List<pse__Billing_Event__c> toUpdate = new List<pse__Billing_Event__c>();
    Map<Id, pse__Billing_Event__c> toUpdate = new Map<Id, pse__Billing_Event__c>();

    public psaAttachmentTriggerHandler(){}

    /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){

        //Retrieve the map of associated expenses
        if(Trigger.isInsert){
            System.debug('It is an insert trigger');

            Set<Id> parentIds = new Set<Id>();
            Map<ID, Integer> attachCountPerExpense = new Map<ID, Integer>();
            for (SObject so : Trigger.new) {
                Attachment a = (Attachment)so;
                parentIds.add(a.parentId);
                System.debug('Added : '+a.parentId + 'to the set');
            }

            if(parentIds.size() > 0){
                expenseMap = new Map<Id, pse__Expense__c>([SELECT ID,PSA_Receipt_Attached__c from pse__Expense__c where ID in :parentIds]);
                eventMap = new Map<Id, pse__Billing_Event__c>([SELECT ID,PSA_Invoice_Detail_Document__c,PSA_Invoice_Detail_CSV_Document__c from pse__Billing_Event__c where ID in :parentIds]);
            }
        }

        if(Trigger.isDelete){
            System.debug('It is a delete trigger');
            Set<Id> expenseIds = new Set<Id>();
            attachCountPerExpense = new Map<ID, Integer>();
            for (SObject so : Trigger.old) {
                Attachment a = (Attachment)so;
                expenseIds.add(a.parentId);
            }

            List<Attachment> allAttachmentsOnExpenses = [Select Id,ParentId from Attachment where ParentId in :expenseIds];
            for(Attachment attach : allAttachmentsOnExpenses){
                Integer count = attachCountPerExpense.get(attach.parentId);
                if(count == null){
                    count = 0;
                }
                count++;
                attachCountPerExpense.put(attach.parentId, count);
            }

            System.debug('countperexpense: '+attachCountPerExpense);
            if(expenseIds.size() > 0){
                expenseMap = new Map<Id, pse__Expense__c>([SELECT ID,PSA_Receipt_Attached__c from pse__Expense__c where ID in :expenseIds]);
            }
        }
    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter(){
        //Retrieve the map of associated expenses
        if(Trigger.isInsert){
            System.debug('It is an insert trigger');

            Set<Id> parentIds = new Set<Id>();
            Map<ID, Integer> attachCountPerExpense = new Map<ID, Integer>();
            for (SObject so : Trigger.new) {
                Attachment a = (Attachment)so;
                parentIds.add(a.parentId);
                System.debug('Added : '+a.parentId + 'to the set');
            }

            if(parentIds.size() > 0){
                expenseMap = new Map<Id, pse__Expense__c>([SELECT ID,PSA_Receipt_Attached__c from pse__Expense__c where ID in :parentIds]);
                eventMap = new Map<Id, pse__Billing_Event__c>([SELECT ID,PSA_Invoice_Detail_Document__c,PSA_Invoice_Detail_CSV_Document__c from pse__Billing_Event__c where ID in :parentIds]);
            }
        }
    }
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        Attachment a = (Attachment)so;
        pse__Expense__c expense = expenseMap.get(a.parentId);
        pse__Billing_Event__c event = eventMap.get(a.parentId);
        if(expense != null){
            System.debug('Checking receipt attached');
            checkReceiptAttached(expense);
        }
    }
     
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
    public void beforeDelete(SObject so){
        System.debug('This is before a delete');
        System.debug('The map is: '+attachCountPerExpense);
        Attachment a = (Attachment)so;
        pse__Expense__c expense = expenseMap.get(a.parentId);
        if(expense != null){
            deleteAttachment(a);
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
        Attachment a = (Attachment)so;
        pse__Billing_Event__c event = eventMap.get(a.parentId);
        if(event != null){
            System.debug('Updating Invoice Detail URL');
            updateInvoiceURL(a, event);
        }
    }
 
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
    public void andFinally(){
        System.debug('And finally: '+toUpdate);
        if(toUpdate != null && toUpdate.values().size() > 0){
            System.debug('Updating billing events!');
            update toUpdate.values();
        }
    }

    private void checkReceiptAttached(pse__Expense__c expense){
        System.debug('Attached the receipt!');
        expense.PSA_Receipt_Attached__c = true;
        update expense;
    }

    private void updateInvoiceURL(Attachment a, pse__Billing_Event__c event){
        System.debug('Inserting a URL');
        String name = a.name;

        //added by cklassen 9/16/15 to enhance the Billing Event Re-generation process
        if(name.contains('Invoice Preview')){
            pse__Billing_Event__c toChange = toUpdate.get(event.id);
            if(toChange == null){
                event.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                toUpdate.put(event.id, event);
            }
            else{
                toChange.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                toUpdate.put(toChange.id, toChange);
            }
        }

        if(name.contains('Detail')){
            System.debug('It contained detail');

            string SFDCUrl = URL.getSalesforceBaseUrl().toExternalForm();
            SFDCUrl += '/servlet/servlet.FileDownload?file=' + a.id;
            if(name.contains('.pdf')){
                pse__Billing_Event__c toChange = toUpdate.get(event.id);
                if(toChange == null){
                    event.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                    event.PSA_Invoice_Detail_Document__c = SFDCUrl;
                    toUpdate.put(event.id, event);
                }
                else{
                    toChange.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                    toChange.PSA_Invoice_Detail_Document__c = SFDCUrl;
                    toUpdate.put(toChange.id, toChange);
                }
            }
            if(name.contains('.xlsx')){
                pse__Billing_Event__c toChange = toUpdate.get(event.id);
                if(toChange == null){
                    event.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                    event.PSA_Invoice_Detail_CSV_Document__c = SFDCUrl;
                    toUpdate.put(event.id, event);
                }
                else{
                    toChange.PSA_Billing_Event_Docs_Attached_Date__c = DateTime.now();
                    toChange.PSA_Invoice_Detail_CSV_Document__c = SFDCUrl;
                    toUpdate.put(toChange.id, toChange);
                }
            }
        }

    }

    private void deleteAttachment(Attachment a){
        System.debug('Variables: '+a+' '+attachCountPerExpense);
        Integer count = attachCountPerExpense.get(a.parentId);
        System.debug('Count before decrement'+count);
        count--;
        System.debug('Count after decerement: '+count);
        if(count == 0){
            System.debug('Count was zero!');
            pse__Expense__c expense = expenseMap.get(a.parentId);
            expense.PSA_Receipt_Attached__c = false;
            update expense;
        }
        attachCountPerExpense.put(a.parentId, count);
    }
}