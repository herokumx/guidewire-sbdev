/*
******************************************************************************************************************************
Trigger Name - GW_EmailMessageTrigger
Object - EmailMessage
Event - after insert
Test Class-
Purpose- Trigger on  object EmailMessage
	- Auto Close Case Milestones based on the Email Subject
	- 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Mani G   manig@slalom.com 	06/02/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_EmailMessageTrigger on EmailMessage (after insert) {

	// Read the value of the custom setting to Bypass Trigger
    CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  	// Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}
    CS_TriggerFactory.createHandler(emailMessage.sObjectType);

}