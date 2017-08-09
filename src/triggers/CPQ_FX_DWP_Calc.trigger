trigger CPQ_FX_DWP_Calc on SBQQ__Quote__c (before insert, after insert, after update, before update) {
  // Read the value of the custom setting to Bypass Trigger, and exit the Trigger if the customsetting value is set to True
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  if(bypass.CS_Disable_Trigger__c) {return;}

  //This is tricky, because when the SBQQ creates the Quote, it actually creates it, rolls it back and creates a new one in the same transaction.
  //This has to be a before trigger and also before update and we will determine in the handler more of what to do.
  if(Trigger.isBefore && Trigger.isInsert) {
    System.debug('***CPQ_FX_DWP_Calc trigger isBefore && isInsert');
    CPQ_FX_DWP_Calc_Helper.OnBeforeInsert(Trigger.new, Trigger.newMap);
  }

  if(Trigger.isBefore && Trigger.isUpdate) {
    System.debug('***CPQ_FX_DWP_Calc trigger isBefore && isInsert');
    CPQ_FX_DWP_Calc_Helper.OnBeforeUpdate(Trigger.new, Trigger.newMap);
  }

  /* Debugging
     system.debug('isInsert: ' + Trigger.isInsert + ' isUpdate: ' + Trigger.isUpdate);
     system.debug('isBefore: ' + Trigger.isBefore + ' isAfter: ' + Trigger.isAfter);
     for(SBQQ__Quote__c newQuote : Trigger.new) {
      system.debug('1 ' + newQuote);
      system.debug('2 ' + newQuote.CPQ_Quote_Currency_to_USD_Conversion__c);
      system.debug('3 ' + newQuote.CPQ_USD_to_Quote_Currency_Conversion__c);
     }
     //handler.OnBeforeInsert(Trigger.new, Trigger.newMap);
   */
}