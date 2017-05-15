// psaCardTransactionItem
/**************************************************************************************
// Name          : psaCardTransactionItem Trigger
// Date          : 11/24/2015
// Author        : CLD Partners
// Description   : psaCardTransactionItem Trigger
***************************************************************************************/
trigger psaCardTransactionItem on PSA_Card_Transaction_Item__c (before delete, after delete) {
    psaTriggerHandlerFactory.createHandler(PSA_Card_Transaction_Item__c.sObjectType);
}