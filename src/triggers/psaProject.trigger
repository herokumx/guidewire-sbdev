/**************************************************************************************
// Name          : psaProject Trigger
// Date          : March 4, 2015
// Description   : psaProject Trigger
// Author        : CLD Partners
// Revisions     : 2015-03-04  Schwartz  Initial version
***************************************************************************************/
trigger psaProject on pse__Proj__c (before insert, after insert, before update, after update) {
    psaTriggerHandlerFactory.createHandler(pse__Proj__c.sObjectType);
}