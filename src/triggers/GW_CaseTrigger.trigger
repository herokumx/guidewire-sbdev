/*
******************************************************************************************************************************
Trigger Name - GW_CaseTrigger
Object - Case
Event - Before insert,Before Update,after insert,after Update
Test Class-
Purpose- Trigger on  object Case
    - Auto Populate Account,Product and Business Hours on case 
    - 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu                     05/13/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_CaseTrigger on Case (Before insert,Before Update,after insert,after Update) {

// Read the value of the custom setting to Bypass Trigger
    CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  // Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}
    CS_TriggerFactory.createHandler(Case.sObjectType);
}