/**************************************************************************************
// Name          : psaResourceStageBatch
// Date          : April 8, 2015
// Description   : Contains methods related to the Workday integration including creating
//					and updating Resources and Users and also PTO requests
// Author        : CLD Partners
// Revisions     : 2015-04-08  Klassen  Initial version
//				 : 
***************************************************************************************/
global class psaResourceStageBatch implements Database.Batchable<sObject> {
	
	String query;
	Boolean sendEmail;
	
	global psaResourceStageBatch(Boolean sendEmailIn) {
		sendEmail = sendEmailIn;
		Id psaRecordTypeId = [Select Id from RecordType Where DeveloperName = 'PSA_Resource'].Id;
		query = 'Select Id, PSA_Worker_Id__c, pse__Salesforce_User__c ' + 
				'  From Contact ' + 
				'  Where RecordTypeId = \'' + psaRecordTypeId + '\' ' + 
				'  And pse__Salesforce_User__c = null ' + 
				'  And PSA_Worker_Id__c != null ';		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		psaWorkdayResourceIntegration.updateSalesforceUser(scope);
	}
	
	global void finish(Database.BatchableContext BC) {
        AsyncApexJob a = 
            [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob 
                WHERE Id = :BC.getJobId()];
        if (sendEmail) {        
            // Send an email to the Apex job's submitter notifying of job completion. 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //String[] toAddresses = new String[] {a.CreatedBy.Email};
            String[] toAddresses = new String[] {'cklassen@cldpartners.com'};       
            mail.setToAddresses(toAddresses);
            String subjectText = 'psaResourceStageBatch Status: ' + a.Status; 
            mail.setSubject(subjectText);
            mail.setPlainTextBody
            ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
            if (a.NumberOfErrors > 0 || sendEmail) 
            {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }       
        }

        //system.abortJob(a.id);			
	}
	
}