/****************************************************************************************
Name            : psaProjectForecastBatch
Author          : CLD
Created Date    : April 29, 2015
Description     : For scheduled batch execution of project forecast calculations
                : 
******************************************************************************************/
global class psaProjectForecastBatch implements Database.Batchable<sObject>, Database.Stateful
{
	// The main query gets a list of projects eligible for billing forecast calculation.
	//public String billingForecastQuery = 'SELECT Id, Name FROM pse__Proj__c WHERE pse__Is_Active__c = True AND pse__Project_Type__c = \'Customer Project\' AND pse__Is_Billable__c = True AND PSA_Include_In_Billing_Forecast__c = True AND pse__Is_Template__c = False'; 
	public String projectForecastQuery = 'SELECT Id, Name FROM pse__Proj__c WHERE pse__Is_Active__c = True AND pse__Is_Billable__c = True AND PSA_Include_In_Billing_Forecast__c = True AND pse__Is_Template__c = False AND pse__Billing_Type__c != null AND PSA_BR_Expenses_Billing_Type__c != null AND pse__End_Date__c >= LAST_N_MONTHS:12'; 

	/****************************************************************************
	* This method is required for batchable Apex.  
	* It sets up the Exectute() method
	****************************************************************************/
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		System.debug('**** psaProjectForecastBatch.start()');
		return Database.getQueryLocator(projectForecastQuery);
	}

	/****************************************************************************
	* This method is required for batchable Apex and is where we loop through the 
	* results of the query specified in the execte() method 
	*****************************************************************************/
	global void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		Integer recordCount;
		List<Id> projectIdList = new List<Id>();
		for(Sobject s : scope)
		{
			pse__Proj__c proj = (pse__Proj__c) s;
			projectIdList.add(proj.Id);
		}

		psaProjectForecastCalculation.calculateBillingForecast(projectIdList);
		psaProjectForecastCalculation.calculateRevenueForecast(projectIdList);
	}

	/****************************************************************************
	* This method is REQUIRED for batchable Apex. It puts some results in the log
	*
	*****************************************************************************/
	global void finish(Database.BatchableContext BC)
	{
		// Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext. 
		// Query the AsyncApexJob object to retrieve the current job's information. 
		AsyncApexJob a = [
			SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
			  FROM AsyncApexJob 
			 WHERE Id = :BC.getJobId()];

		// log Apex job details
		System.debug('**** psaProjectForecastBatch Finish()  status: ' + a.status + ' Total Jobs: ' + a.TotalJobItems + ' Errors: ' + a.NumberOfErrors);
	}
}