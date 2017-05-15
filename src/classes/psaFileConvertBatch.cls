/**************************************************************************************
// Name          : psaFileConvertBatch
// Date          : March 17, 2016
// Description   : Used to process a large number of non-image expense attachments in batches 
//                  
// Author        : CLD Partners
// Revisions     : 2016-03-17  Klassen  Initial version
//               : 
***************************************************************************************/
global class psaFileConvertBatch implements Database.Batchable<sObject>, 
   Database.AllowsCallouts, Database.Stateful {

    String query;
    Set<Id> attachmentIds;
    Decimal batchNumber;
    Boolean sendEmail;
    String sourceDocType;
    String sourceObjectId;


    //method to get a list of records to process
    global psaFileConvertBatch(Set<Id> attachmentIdsIn, Decimal batchNumberIn, 
            Boolean sendEmailIn, String sourceDocTypeIn, String sourceObjectIdIn) {
        attachmentIds = attachmentIdsIn;
        batchNumber = batchNumberIn;
        sendEmail = sendEmailIn;
        sourceDocType = sourceDocTypeIn;
        sourceObjectId = sourceObjectIdIn;

        query = 'Select Id, ParentId ' + 
            'From Attachment ' + 
            'Where Id = :attachmentIds ';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> batchIds = new Set<Id>();
        for (SObject obj : scope) {
            Attachment a = (Attachment)obj;
            batchIds.add(a.Id);
        }

        psaFileConvert.initiateConversion(batchIds, sourceObjectId, sourceDocType, batchNumber);
    }

    global void finish(Database.BatchableContext BC) {
        //If there were no errors, continue the combined expense receipt process.  Otherwise, update the source
        // object's status and don't continue the process
        AsyncApexJob a = 
            [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedById, CreatedBy.Email
                FROM AsyncApexJob 
                WHERE Id = :BC.getJobId()];
        if (a.NumberOfErrors == 0) {
            System.debug('psaFileConvertBatch -- About to schedule job to check file conversion status');
            //Schedule the job to run that will create a combined receipts attachment once any files are done being converted
            psaFileConvert.scheduleJobByBatchNumber(batchNumber, sourceObjectId, sourceDocType, 1);
        } else {
            //Set the Combine Receipt Progress value
            psaCombineExpenseReceipts.updateCombineReceiptProgress('Error', sourceObjectId, sourceDocType, false, true);

            //Send an email notification
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String emailBody = 'The batch Apex job processed ' + a.TotalJobItems + ' batches ' + 
                                'with '+ a.NumberOfErrors + ' failures. (UserId=' + a.CreatedById + 
                                ', User Email: ' + a.CreatedBy.Email + ', Source Object Type=' + sourceDocType + 
                                ', Source Object Id=' + sourceObjectId + ')';
            String notifyEmailList = getEmailNotifyList();
            String[] toAddresses = notifyEmailList.split(',');
            if (notifyEmailList != '') {
                mail.setToAddresses(toAddresses);
                String subjectText = 'psaFileConvertBatch Status: ' + a.Status; 
                mail.setSubject(subjectText);
                mail.setPlainTextBody(emailBody);
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