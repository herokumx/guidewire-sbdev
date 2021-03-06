trigger CPQ_BillingSchedule on CPQ_Billing_Schedule__c (before insert,before update,after insert,after update,before delete) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  CS_TriggerFactory.createHandler(CPQ_Billing_Schedule__c.sObjectType);
}
