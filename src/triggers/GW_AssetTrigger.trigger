/*
******************************************************************************************************************************
Trigger Name - GW_AssetTrigger
Object - Asset
Event - before insert,after insert,before update,after update
Test Class-
Purpose- Trigger on  object Asset
	- Creates ACP records  for support contacts on Account  linked to Asset
	- Creates Softwaredownload records for the Licensed Product of all versions 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu     				05/13/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_AssetTrigger on Asset (before insert,after insert,before update,after update) {
   
     CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  	// Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}  
    CS_TriggerFactory.createHandler(Asset.sObjectType);


}