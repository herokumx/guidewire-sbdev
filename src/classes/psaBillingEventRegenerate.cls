/****************************************************************************************
Name            : psaBillingEventRegenerate
Author          : CLD Partners 
Created Date    : September 15, 2015
Description     : Contains methods to apply regenerate a billing event including clearing
				:  the existing one, re-running BEG for the project/time period, generating
				:  the Conga documents and notifying the CIM.
Revisions       : 9/15/15 - Initial version 
                : 
******************************************************************************************/
global with sharing class psaBillingEventRegenerate {
    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaBillingEventRegenerate';
    private static Integer apexLogMethodSequenceMaster = 0;

	public psaBillingEventRegenerate() {}

    /**************************************************************************************
    // Name         : runBillingEventClear
    // Description  : Calls the FF Billing API to delete ("Clear") a billing event based on
    //					the Billing Event Id
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static String runBillingEventClear(Id billingEventId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'runBillingEventClear';

    	String returnValue = '';

		pse.APIBillingService.BillingContextClear bc = new pse.APIBillingService.BillingContextClear();
	    bc.id = billingEventId;
	    bc.objectType = pse.APIBillingService.ObjectTypesClear.event;

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Context', String.valueOf(bc), null);

	    pse.APICommonsService.BatchStatus bs =  pse.APIBillingService.clear(bc);
	    if (bs.errorMessage == null || bs.errorMessage == '') {
	    	System.debug('Batch Status Object: ' + bs);
	    	System.debug(String.valueOf(bs.JobId));
	        //Add apex log record
	        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Batch Status', String.valueOf(bs), null);

	    	//query the apex job queue to see if there really is an apex job for the current user
	    	String jobId;
	    	if (bs.JobId == null) {
	    		//checking for batch job using 'BillingDeleteBatch' and current user
	    		jobId = checkJobStatusByNameAndUser('BillingDeleteBatch', UserInfo.getUserId());
	    	} else {
	    		jobId = 'null';
	    	}

	    	System.debug('SUCCESS' + jobId);
	    	returnValue = 'SUCCESS' + jobId;
	    } else {
	    	returnValue = bs.errorMessage;
	    }
		
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'return value: ' + returnValue, null, null);

		return returnValue;
    }

    /**************************************************************************************
    // Name         : runBillingEventGeneration
    // Description  : Calls the FF Billing API to create a new billing event based on the 
    //					a specific Project Id and Time Period
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static String runBillingEventGeneration(Id projId, Id timePeriodId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'runBillingEventGeneration';

	   	String returnValue = '';

	   	//Get RegionId
	   	Id regionId = ([Select pse__Region__c from pse__Proj__c where Id = :projId]).pse__Region__c;
		pse.APIBillingService.BillingContextGenerate bcg = new pse.APIBillingService.BillingContextGenerate();
		bcg.projectID = projId;
		bcg.regionID = regionId;
		bcg.groupID = null;
		bcg.practiceID = null;
		bcg.includePriorPeriods = true;
		bcg.useFlexiblePeriods = false;
		bcg.timePeriodId = timePeriodId;

		system.debug('****** THE VALUE OF bcg right before calling = '+ bcg);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Context', String.valueOf(bcg), null);

		pse.APICommonsService.BatchStatus bs = pse.APIBillingService.generate(bcg);
	    if (bs.errorMessage == null || bs.errorMessage == '') {
	    	System.debug(String.valueOf(bs.JobId));
	    	System.debug('SUCCESS' + String.valueOf(bs.JobId));
	    	returnValue = 'SUCCESS' + String.valueOf(bs.JobId);
	    } else {
	    	returnValue = bs.errorMessage;
	    }

		system.debug('**** psaBillingEventGeneration batch job: ' + bs.jobId);
		System.debug('Return Value: ' + returnValue);

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'return value: ' + returnValue, null, null);

		return returnValue;
    }

    /**************************************************************************************
    // Name         : checkJobStatusByNameAndUser
    // Description  : Looks for an Apex Job for a specifc apex class and user that is not
    //					completed, failed, or aborted.  This is a work-around since the
    //					Billing API for the Clear method does not return the Apex Job Id
    //					like it should, and this is needed to prevent billing event 
    //					generation from launching prematurely
    // Author       : CLD Partners
    // Revisions    : 2015-09-25  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static String checkJobStatusByNameAndUser(String jobName, Id userId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'checkJobStatusByNameAndUser';

    	String returnValue = 'null';

    	List<AsyncApexJob> aajList = 
    		[SELECT Id, Status  
				FROM AsyncApexJob 
				WHERE ApexClass.Name =: jobName
				AND CreatedById =: userId
				AND Status != 'Completed'
				AND Status != 'Aborted' 
				AND Status != 'Failed'
				ORDER BY CreatedDate Desc
			];
		System.debug('AsyncApexJob List: ' + aajList);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'AsyncApexJob List', String.valueOf(aajList), null);

		if (aajList != null && aajList.size() > 0) {
			AsyncApexJob aaj = aajList[0];
			return aaj.Id;
		}
/*
		System.Debug('Apex job id: '+aaj.Id);
		if (aaj.Status == 'Completed') {
			return 'DONE';
		} else if (aaj.Status == 'Aborted' || aaj.Status == 'Failed') {
			return 'FAILED';
		} else {
			return 'PROCESSING';
		}
*/

    	return returnValue;
    }

	/*****************************************************************************************************************/
	/** This method allows a billing event to get re-generated (deleted and re-created )when called from the billing event detail page                   **/
	/*****************************************************************************************************************/
	/* NOT CURRENTLY USED - WOULD BE USED IF CALLING FROM CUSTOM BUTTON/JAVASCRIPT
	Webservice static string regenerateBillingEvent(string billingEventId)
	{
		string message = '';
		try
		{
			message = psaBillingEventRegenerate.processBillingEventRegeneration(new List<Id>{billingEventId});
			if (message == '') {
				message = 'SUCCESS';
			}
		}
		catch(System.CalloutException e)
		{
			message = e.getMessage();
		}
		return message;
	}
	*/

}