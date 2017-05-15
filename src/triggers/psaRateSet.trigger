trigger psaRateSet on PSA_Rate_Set__c (before insert, after insert, before update, after update) {
	psaTriggerHandlerFactory.createHandler(PSA_Rate_Set__c.sObjectType);
}