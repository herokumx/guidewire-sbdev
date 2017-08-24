trigger CPQ_Order_BillingSchedule on Order (before insert, before update, after insert, after update) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  CPQ_Order_BillingSchedule_Helper handler = new CPQ_Order_BillingSchedule_Helper(Trigger.isExecuting, Trigger.size);

  if(Trigger.isUpdate && Trigger.isBefore) {
    handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
  }

  if(Trigger.isInsert && Trigger.isAfter) {
    if (CPQ_Order_BillingSchedule_Helper.runOnce() ) {
      handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }
  }

  if(Trigger.isUpdate && Trigger.isAfter) {
    if (CPQ_Order_BillingSchedule_Helper.runOnce() ) {
      handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
  }
}