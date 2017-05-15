/**************************************************************************************
// Name          : psaCardTransaction Trigger
// Date          : Aug 2016
// Author        : CLD Partners
// Description   : psaCardTransaction Trigger
***************************************************************************************/
trigger psaCardTransaction on PSA_Card_Transaction__c (before update) {
    psaTriggerHandlerFactory.createHandler(PSA_Card_Transaction__c.sObjectType);
}