trigger CPQ_OppProduct_Owner_Calc on OpportunityLineItem (before insert, before update,after insert, after update){
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  CPQ_OppProduct_Owner_Calc_Helper handler = new CPQ_OppProduct_Owner_Calc_Helper(Trigger.isExecuting, Trigger.size);

  if(Trigger.isInsert && Trigger.isBefore)
  {
    if (CPQ_OppProduct_Owner_Calc_Helper.runOnce() || Test.isRunningTest())
    {
      handler.OnBeforeInsert(Trigger.new, Trigger.newMap);
    }
  }

  if(Trigger.isUpdate && Trigger.isBefore)
  {
    if (CPQ_OppProduct_Owner_Calc_Helper.runOnce() || Test.isRunningTest())
    {
      handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
  }

  if(Trigger.isInsert && Trigger.isAfter)
  {
    if (CPQ_OppProduct_Owner_Calc_Helper.runOnce() || Test.isRunningTest())
    {
      handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }
  }

  if(Trigger.isUpdate && Trigger.isAfter)
  {
    if (CPQ_OppProduct_Owner_Calc_Helper.runAfter || Test.isRunningTest())
    {
      System.debug('Trigger - After Update - Inside CPQ_In_Scope_DWP_Calc_Helper');
      handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
  }
}