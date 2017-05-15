/**************************************************************************************
// Name          : psaAssignment Trigger
// Date          : March 4, 2015
// Description   : psaAssignment Trigger
// Author        : CLD Partners
// Revisions     : 2015-03-04  Klassen  Initial version
***************************************************************************************/
trigger psaAssignment on pse__Assignment__c (before insert, after insert, before update, after update) {

	psaTriggerHandlerFactory.createHandler(pse__Assignment__c.sObjectType);

}