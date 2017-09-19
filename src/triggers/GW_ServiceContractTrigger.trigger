trigger GW_ServiceContractTrigger on ServiceContract (after update) {
  // Read the value of the custom setting to Bypass Trigger
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  // Exit the Trigger if the customsetting value is set to True
  if(bypass.CS_Disable_Trigger__c) {return;}
  CS_TriggerFactory.createHandler(ServiceContract.sObjectType);
}
