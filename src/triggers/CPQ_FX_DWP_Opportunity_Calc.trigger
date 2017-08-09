trigger CPQ_FX_DWP_Opportunity_Calc on Opportunity (before update) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  if(Trigger.isBefore) {
    System.debug('***CPQ_FX_DWP_Opportunity_Calc trigger isBefore');
    CPQ_FX_DWP_Calc_Helper.OpportunityUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
  }

}