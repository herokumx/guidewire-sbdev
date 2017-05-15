/*
******************************************************************************************************************************
Trigger Name - GW_FeedItemTrigger
Object - FeedItem
Event - before insert,after insert,before update,after update
Test Class-
Purpose- Trigger on  object FeedItem
    - Auto Close Case Milestones based on First Public Post
    - Copy Public Post and Private Post to Case Fields and  Send Email 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Mani G   manig@slalom.com   06/02/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_FeedItemTrigger on FeedItem (before insert,after insert,before update,after update,before delete) {
     CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
    // Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}  
    CS_TriggerFactory.createHandler(FeedItem.sObjectType);
}