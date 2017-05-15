/**************************************************************************************
// Name          : psaTimeOffStage Trigger
// Date          : April 10, 2015
// Description   : psaTimeOffStage Trigger
// Author        : CLD Partners
// Revisions     : 2015-04-10  Klassen  Initial version
***************************************************************************************/
trigger psaTimeOffStage on PSA_Time_Off_Stage__c (after insert, after update) {
	psaTriggerHandlerFactory.createHandler(PSA_Time_Off_Stage__c.sObjectType);
}