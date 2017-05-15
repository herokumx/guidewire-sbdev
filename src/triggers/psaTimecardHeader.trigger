/**************************************************************************************
// Name          : psaTimecardHeader Trigger
// Date          : March 4, 2015
// Description   : psaTimecardHeader Trigger
// Author        : CLD Partners
// Revisions     : 2015-03-04  Klassen  Initial version
***************************************************************************************/
trigger psaTimecardHeader on pse__Timecard_Header__c (before insert, after insert, before update, after update) {

	psaTriggerHandlerFactory.createHandler(pse__Timecard_Header__c.sObjectType);

}