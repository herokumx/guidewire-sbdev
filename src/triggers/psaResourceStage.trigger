/**************************************************************************************
// Name          : psaResourceStage Trigger
// Date          : April 8, 2015
// Description   : psaResourceStage Trigger
// Author        : CLD Partners
// Revisions     : 2015-04-08  Klassen  Initial version
***************************************************************************************/
trigger psaResourceStage on PSA_Resource_Stage__c (after insert, after update) {
	psaTriggerHandlerFactory.createHandler(PSA_Resource_Stage__c.sObjectType);
}