/**************************************************************************************
// Name          : psaRate Trigger
// Date          : February 6, 2015
// Description   : psaRate Trigger
// Author        : CLD Partners
// Revisions     : 2015-02-06  Spano Initial Version
***************************************************************************************/

trigger psaRate on PSA_Rate__c (before insert) {
    psaTriggerHandlerFactory.createHandler(PSA_Rate__c.sObjectType);
}