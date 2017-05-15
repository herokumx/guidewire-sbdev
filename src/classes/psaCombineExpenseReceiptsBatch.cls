/**************************************************************************************
// Name          : psaCombineExpenseReceiptsBatch
// Date          : October 8, 2015
// Description   : Used to process a large number of projects/billing event records in batches 
//                  
// Author        : CLD Partners 
// Revisions     : 2015-10-08  Klassen  Initial version
//               : 2015-12-04  Klassen  Update to use more generic "PSA Combined Expense Receipt"
//                  object
***************************************************************************************/
global class psaCombineExpenseReceiptsBatch implements Database.Batchable<sObject>, 
   Database.AllowsCallouts, Database.Stateful {

    String query;
    List<Id> ids;
    String sessionId;
    Boolean sendEmail;
    String sourceDocType;
    String sourceObjectId;
    Integer currentFileNumber = 0;
    Integer totalFileCount;

    //method to get a list of records to process
    global psaCombineExpenseReceiptsBatch(List<Id> idsIn, String sessionIdIn, 
            Boolean sendEmailIn, String sourceDocTypeIn, String sourceObjectIdIn) {
        ids = idsIn;
        sessionId = sessionIdIn;
        sendEmail = sendEmailIn;
        sourceDocType = sourceDocTypeIn;
        sourceObjectId = sourceObjectIdIn;

        query = 'Select Id ' + 
            'From PSA_Combined_Expense_Receipt__c ' + 
            'Where Id = :ids ';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Get the total number of documents
        totalFileCount = database.countQuery('select count() from PSA_Combined_Expense_Receipt__c Where Id = :ids');
        system.debug('the count is '+ totalFileCount);

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Id> batchIds = new List<Id>();
        for (SObject obj : scope) {
            batchIds.add(obj.Id);
        }

        currentFileNumber++;
        psaPDFGenerationUtil.doWork(batchIds, sourceDocType, sourceObjectId, currentFileNumber, totalFileCount);
    }

    global void finish(Database.BatchableContext BC) {
        AsyncApexJob a = 
            [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedById, CreatedBy.Email
                FROM AsyncApexJob 
                WHERE Id = :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String emailBody = 'The batch Apex job processed ' + a.TotalJobItems + ' batches ' + 
                            'with '+ a.NumberOfErrors + ' failures. (UserId=' + a.CreatedById + 
                            ', User Email: ' + a.CreatedBy.Email + ', Source Object Type=' + sourceDocType + 
                            ', Source Object Id=' + sourceObjectId + ')';
        String notifyEmailList = getEmailNotifyList();
        String[] toAddresses = notifyEmailList.split(',');
        if (notifyEmailList != '') {
            mail.setToAddresses(toAddresses);
            String subjectText = 'psaCombineExpenseReceiptsBatch Status: ' + a.Status; 
            mail.setSubject(subjectText);
            mail.setPlainTextBody(emailBody);
            if (a.NumberOfErrors > 0 || sendEmail) 
            {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }

    private String getEmailNotifyList() {
        String notifyEmailList = '';
        PSA_Combine_Receipts__c psaCombineReceipts = PSA_Combine_Receipts__c.getValues('default');
        if (psaCombineReceipts != null) {
            if (psaCombineReceipts.PSA_Email_Notify_List__c != null) {
                notifyEmailList = psaCombineReceipts.PSA_Email_Notify_List__c;
            }
        }      
        return notifyEmailList;
    }
}