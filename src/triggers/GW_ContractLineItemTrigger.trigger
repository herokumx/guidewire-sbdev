/*
 ******************************************************************************************************************************
   Trigger Name - GW_ContractLineItemTrigger
   Object - ContractLineItem
   Event - after insert
   Test Class-
   Purpose- Trigger on  object ContractLineItem
   - Update Serial Numbers for Rating Management,ReInsurance,SAP Production,BFO
   -
   Custom Setting-CS_ByPass__c

 *****************************************************************************************************************************

   Name     Email              Date         Notes
   Mani G   manig@slalom.com    07/28/2016   Initial Creation

 *****************************************************************************************************************************
 */
trigger GW_ContractLineItemTrigger on ContractLineItem (after insert) {
  // Read the value of the custom setting to Bypass Trigger
  CS_ByPass__c bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  // Exit the Trigger if the customsetting value is set to True
  if(bypass.CS_Disable_Trigger__c) {return;}
  CS_TriggerFactory.createHandler(ContractLineItem.sObjectType);

}
