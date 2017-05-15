/**************************************************************************************
// Name          : psaBillingRulesApplicationBatch
// Date          : September 16, 2015
// Description   : Used to process a large number of projects/billing event records in batches 
//                  
// Author        : CLD Partners
// Revisions     : 2015-09-15  Klassen  Initial version
//               : 
***************************************************************************************/
global class psaBillingRulesApplicationBatch implements Database.Batchable<sObject> {

	String query;
	Set<Id> projectIds;
	Date startDate;
	Date endDate;
    Boolean sendEmail;
    
    //method to get a list of records to process
    global psaBillingRulesApplicationBatch(Set<Id> projectIdsIn, Date startDateIn, Date endDateIn, Boolean sendEmailIn) {
        projectIds = projectIdsIn;
        startDate = startDateIn;
        endDate = endDateIn;
        sendEmail = sendEmailIn;

        query = 'Select Id ' + 
            'From pse__Proj__c ' + 
            'Where Id = :projectIds ';      
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	Set<Id> batchProjectIds = new Set<Id>();
    	for (SObject obj : scope) {
    		batchProjectIds.add(obj.Id);
    	}

        psaBillingRulesApplication bra = new psaBillingRulesApplication();
        bra.launchBillingRules(batchProjectIds, startDate, endDate);
    }

    global void finish(Database.BatchableContext BC) {
    	System.debug('psaBillingRulesApplicationBatch.finish: about to call the BE recalc method');
        //Now that the billing rules application batch is finished, call the Recalc billing api method
        psaBillingEventRecalc.recalcBillingEvents(projectIds);

        String emailList;
        PSA_Billing__c psaBilling = PSA_Billing__c.getValues('default');
        if (psaBilling != null) {
          if (psaBilling.PSA_Billing_Rules_Batch_Done_Email_List__c != null) {
            emailList = psaBilling.PSA_Billing_Rules_Batch_Done_Email_List__c;
          }
        }
        if (emailList != null && emailList != '') {    
            AsyncApexJob a = 
                [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                    FROM AsyncApexJob 
                    WHERE Id = :BC.getJobId()];
            // Send an email to the PSA Billing custom setting email list of job completion. 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //String[] toAddresses = new String[] {a.CreatedBy.Email};
            String[] toAddresses = emailList.split(',');       
            mail.setToAddresses(toAddresses);
            String subjectText = 'psaBillingRulesApplicationBatch Status: ' + a.Status; 
            mail.setSubject(subjectText);
            mail.setPlainTextBody
            ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
            if (a.NumberOfErrors > 0 || sendEmail) 
            {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }       
        }
    }
    
}