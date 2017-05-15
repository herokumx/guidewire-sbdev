/**************************************************************************************
// Name          : psaFileConvertCheckJobsBatch
// Date          : March 17, 2016
// Description   : Used to process a large number of non-image expense attachments in batches 
//                  
// Author        : CLD Partners
// Revisions     : 2016-03-17  Klassen  Initial version
//               : 
***************************************************************************************/
global class psaFileConvertCheckJobsBatch implements Database.Batchable<sObject>, 
   Database.AllowsCallouts, Database.Stateful {

    String query;
    Decimal batchNumber;
    String sourceObjectType;
    String attachmentParentId;
    Integer attemptCount;
    Boolean sendEmail;
    Boolean batchesFound = false; 

    //method to get a list of records to process
    global psaFileConvertCheckJobsBatch(Decimal batchNumberIn, String attachmentParentIdIn, 
            String sourceObjectTypeIn, Integer attemptCountIn, Boolean sendEmailIn) {
        batchNumber = batchNumberIn;
        attachmentParentId = attachmentParentIdIn;
        sourceObjectType = sourceObjectTypeIn;
        attemptCount = attemptCountIn;
        sendEmail = sendEmailIn;

        query = 'Select Id From PSA_File_Convert__c Where PSA_Batch_Number__c = :batchNumber And PSA_Conversion_Job_Id__c != null And PSA_Conversion_Status__c != \'successful\' And PSA_Conversion_Status__c != \'ignore\' ';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('psaFileConvertCheckJobsBatch query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> batchIds = new Set<Id>();
        for (SObject obj : scope) {
            batchIds.add(obj.Id);
        }
        batchesFound = true;

        System.debug('psaFileConvertCheckJobsBatch batchIds: ' + batchIds);
        psaFileConvert.checkJobs(batchIds);
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            System.debug('psaFileConvertCheckJobsBatch -- About to schedule job to check file conversion status');
            //Schedule the job to run that will create a combined receipts attachment once any files are done being converted
            psaFileConvert.checkJobStatusByBatch(batchNumber, attachmentParentId, sourceObjectType, attemptCount);
        }

        AsyncApexJob a = 
            [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob 
                WHERE Id = :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        String[] toAddresses = new String[] {'cklassen@cldpartners.com'};
        mail.setToAddresses(toAddresses);
        String subjectText = 'psaFileConvertCheckJobsBatch Status: ' + a.Status; 
        mail.setSubject(subjectText);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        if (a.NumberOfErrors > 0 || sendEmail) 
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }       
    }
    
}