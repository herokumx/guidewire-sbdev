/**************************************************************************************
// Name          : psaBillingEvent Trigger
// Date          : March 8, 2015
// Description   : psaBillingEvent Trigger
// Author        : CLD Partners
// Revisions     : 2015-03-08  Klassen  Initial version
***************************************************************************************/
trigger psaBillingEvent on pse__Billing_Event__c (before insert, before update, before delete) {
	psaTriggerHandlerFactory.createHandler(pse__Billing_Event__c.sObjectType);
}