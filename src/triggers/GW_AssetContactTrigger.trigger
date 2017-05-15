/*
*****************************************************************************************************************************
Trigger Name - GW_AssetContactTrigger
Object - CS_Asset_Contact_Permissions__c
Event - before insert, after insert, before update, after update, before delete
Test Class-
Purpose- Trigger on  object CS_Asset_Contact_Permissions__c
	- Creates Apex Share to Asset Contacts on Asset Object 
	- Creates Case Team Member for Contacts on All Cases on the asset
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name    	Email              Date         	Notes 
Shan Xu     				   05/13/2016   	Initial Creation

*****************************************************************************************************************************
*/
trigger GW_AssetContactTrigger on CS_Asset_Contact_Permissions__c (before insert, after insert, before update, after update, before delete) {
	// Read the value of the custom setting to Bypass Trigger
    CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  	// Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}
     CS_TriggerFactory.createHandler(CS_Asset_Contact_Permissions__c.sObjectType);
}