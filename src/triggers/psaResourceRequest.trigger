/**************************************************************************************
// Name          : psaResourceRequest Trigger
// Date          : February 6, 2015
// Description   : psaResourceRequest Trigger
// Author        : CLD Partners
// Revisions     : 2015-02-06  Mayfield  Initial version
//				 : 2015-02-25  Schwartz  Implement trigger factory framework
//				 : 2015-06-21  Klassen   Add after delete so RR EVA records get deleted
***************************************************************************************/
trigger psaResourceRequest on pse__Resource_Request__c (before insert, after insert, before update, after update, before delete) {
	psaTriggerHandlerFactory.createHandler(pse__Resource_Request__c.sObjectType);
}