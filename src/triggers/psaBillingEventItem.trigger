/**************************************************************************************
// Name          : psaBillingEventItem Trigger
// Date          : March 6, 2015
// Description   : psaBillingEventItem Trigger
// Author        : CLD Partners
// Revisions     : 2015-03-06  Klassen  Initial version
***************************************************************************************/
trigger psaBillingEventItem on pse__Billing_Event_Item__c (after delete) {
	psaTriggerHandlerFactory.createHandler(pse__Billing_Event_Item__c.sObjectType);
}