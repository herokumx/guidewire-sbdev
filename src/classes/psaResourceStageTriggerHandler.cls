/**************************************************************************************
// Name          : psaResourceStageTriggerHandler
// Date          : April 8, 2015
// Description   : Handles all inserts/updates/deletes called by the psaResourceStage trigger
//				   Includes creating/updating Resources and Salesforce Users
// Author        : CLD Partners
// Revisions     : 2015-04-08  Klassen  Initial version
//				 : 
***************************************************************************************/
public with sharing class psaResourceStageTriggerHandler implements psaITriggerHandler {
	Set<Id> resourceStageIds = new Set<Id>();

	public psaResourceStageTriggerHandler() {}

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
    public void bulkAfter() {
    	//Populate the Maps
    	if(Trigger.isInsert || Trigger.isUpdate){
    		resourceStageIds = Trigger.newMap.keySet();
    	}
    }
     
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
    public void beforeDelete(SObject so){}
 
    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted 
    //               during an AFTER trigger. Always put field validation in the 'After' 
    //               methods in case another trigger has modified any values. The record 
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){
    	/*
       	PSA_Resource_Stage__c resourceStage = (PSA_Resource_Stage__c)so;
       	if (!verifyResourceExists(resourceStage.PSA_Worker_Id__c)) {
       		createNewResource(resourceStage);      		
       	}
       	if (!verifyUserExists(resourceStage.PSA_Worker_Id__c)) {
       		createNewUser(resourceStage);      		
       	}
       	*/
    }

    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated 
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){
    	/*
       	PSA_Resource_Stage__c newResourceStage = (PSA_Resource_Stage__c)so;
//       	PSA_Resource_Stage__c oldResourceStage = (PSA_Resource_Stage__c)oldSo;

       	PSA_Resource_Stage__c resourceStage = (PSA_Resource_Stage__c)so;
       	if (!verifyResourceExists(resourceStage.PSA_Worker_Id__c)) {
       		createNewResource(resourceStage);      		
       	}
       	if (!verifyUserExists(resourceStage.PSA_Worker_Id__c)) {
       		createNewUser(resourceStage);      		
       	}
		*/
    }
 
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
    public void andFinally() {
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaResourceStageTriggerHandler')) {
        	System.debug('Skipping psaResourceStageTriggerHandler andFinally() method due to trigger recursion prevention');
            return;
    	}
	    psaTriggerMonitor.ExecutedTriggers.add('psaResourceStageTriggerHandler');

    	if (resourceStageIds.size() > 0) {
	    	psaWorkdayResourceIntegration.processPSAResources(resourceStageIds);
	    	psaWorkdayResourceIntegration.processPSAUsers(resourceStageIds);
    	}

    }

}