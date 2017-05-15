/*
******************************************************************************************************************************
Trigger Name - GW_ContentDocumentLinkTrigger
Object - ContentDocumentLink
Event - after insert
Test Class-
Purpose- Trigger on  object ContentDocumentLink
    - Auto Share Files uploaded by Community user on their User Profile to the Account they belong to
    - 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Mani G   manig@slalom.com   06/10/2016   Initial Creation

*****************************************************************************************************************************
*/

trigger GW_ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

// Read the value of the custom setting to Bypass Trigger
    CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
  // Exit the Trigger if the customsetting value is set to True 
    if(bypass.CS_Disable_Trigger__c){return;}
    CS_TriggerFactory.createHandler(ContentDocumentLink.sObjectType);

}