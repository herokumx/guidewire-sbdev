/*
******************************************************************************************************************************
Trigger Name - GW_RequestTrigger
Object - CS_Request__c
Event - before insert,before update,after insert,after update
Test Class-
Purpose- Trigger on  object CS_Request__c
	- one  Active Dev Request Validation
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Mani G   manig@slalom.com 	06/1/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_RequestTrigger on CS_Request__c (before insert,before update,after insert,after update) {

	// Read the value of the custom setting to Bypass Trigger
    CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
   // Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}
    CS_TriggerFactory.createHandler(CS_Request__c.sObjectType);

}