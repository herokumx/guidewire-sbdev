/**************************************************************************************
// Name          : psaBillingStage Trigger
// Date          : April 10, 2015
// Description   : psaBillingStage Trigger
// Author        : CLD Partners
// Revisions     : 2015-04-10  Klassen  Initial version
***************************************************************************************/
trigger psaBillingStage on PSA_Billing_Stage__c (after insert, after update) {
	psaTriggerHandlerFactory.createHandler(PSA_Billing_Stage__c.sObjectType);
}