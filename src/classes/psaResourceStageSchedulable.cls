/**************************************************************************************
// Name          : psaResourceStageSchedulable
// Date          : April 8, 2015
// Description   : Contains methods related to the Workday integration including creating
//					and updating Resources and Users and also PTO requests
// Author        : CLD Partners
// Revisions     : 2015-04-08  Klassen  Initial version
//				 : 
***************************************************************************************/
global class psaResourceStageSchedulable implements Schedulable {
    /*
    private static String sched = '0 0 01 * * SAT';  //Every Saturday at 1am 
    private static String scheduledJobName = 'psaResourceStageSchedulable Temp';

    global static String scheduleMe(String scheduleName, String scheduleString) {
        psaResourceStageSchedulable SC = new psaResourceStageSchedulable(); 
        if (scheduleString != '') {
        	sched = scheduleString;
        }
        if (scheduleName != '') {
        	scheduledJobName = scheduleName;
        }
        return System.schedule(scheduledJobName, sched, SC);
    }
	*/
	global void execute(SchedulableContext sc) {
		//psaResourceStageBatch b = new psaResourceStageBatch(true);
		//database.executebatch(b);

		Id psaRecordTypeId = [Select Id from RecordType Where DeveloperName = 'PSA_Resource'].Id;
		List<Contact> contactsToUpdate = 
			[Select Id, PSA_Worker_Id__c, pse__Salesforce_User__c 
				From Contact 
				Where RecordTypeId =:psaRecordTypeId 
				And pse__Salesforce_User__c = null 
				And PSA_Worker_Id__c != null 
			];	

		psaWorkdayResourceIntegration.updateSalesforceUser(contactsToUpdate);

		system.abortJob(sc.getTriggerId());
	}
}