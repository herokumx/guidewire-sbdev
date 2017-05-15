/*
******************************************************************************************************************************
Trigger Name - GW_ReleaseTrigger
Object - CS_Release__c
Event - before insert,after update
Test Class-
Purpose- Trigger on  object CS_Release__c
	- Create softwareDownload Records for the  Asset tied to the  Release Product	
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Mani G   manig@slalom.com 	05/25/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_ReleaseTrigger on CS_Release__c (before insert,after update) {
	 CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
    // Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}  
    CS_TriggerFactory.createHandler(CS_Release__c.sObjectType);

}