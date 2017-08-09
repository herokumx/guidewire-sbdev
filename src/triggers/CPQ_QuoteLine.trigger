trigger CPQ_QuoteLine on SBQQ__QuoteLine__c (before insert,before update,after insert,after update) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  CS_TriggerFactory.createHandler(SBQQ__QuoteLine__c.sObjectType);
}