trigger CPQ_In_Scope_DWP_Calc on Opportunity (after insert, after update, before insert, before update) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  CPQ_In_Scope_DWP_Calc_Helper handler = new CPQ_In_Scope_DWP_Calc_Helper(Trigger.isExecuting, Trigger.size);

  if(Trigger.isInsert && Trigger.isAfter) {
    // [DC 2017-04-05: Removed Test.isRunningTest() condition to avoid recursion while running test class.]
    //if (CPQ_In_Scope_DWP_Calc_Helper.runOnce() || Test.isRunningTest()){
    if (CPQ_In_Scope_DWP_Calc_Helper.runOnce()) {
      handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }
  }

  if(Trigger.isUpdate && Trigger.isAfter) {
    // [DC 2017-04-05: Removed Test.isRunningTest() condition to avoid recursion while running test class.]
    //if (CPQ_In_Scope_DWP_Calc_Helper.runOnce() || Test.isRunningTest()){
    if (CPQ_In_Scope_DWP_Calc_Helper.runOnce()) {
      handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
  }

  if(Trigger.isInsert && Trigger.isBefore) {
    handler.OnBeforeInsert(Trigger.new, Trigger.newMap);
  }

  if(Trigger.isUpdate && Trigger.isBefore) {
    handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
  }
}
