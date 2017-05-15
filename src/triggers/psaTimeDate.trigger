trigger psaTimeDate on pse__Time_Date__c (before insert, after insert, before update, after update) {
	psaTriggerHandlerFactory.createHandler(PSE__Time_Date__c.sObjectType);
}