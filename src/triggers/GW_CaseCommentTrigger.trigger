/*
******************************************************************************************************************************
Trigger Name - GW_CaseCommentTrigger
Object - CaseComment
Event - before insert,after insert,before update,after update
Test Class-
Purpose- Trigger on  object CaseComment
    - Copy Public Post and Private Post to Case Fields and  Send Email 
Custom Setting-CS_ByPass__c

*****************************************************************************************************************************

Name     Email              Date         Notes 
Vipin                       08/29/2016   Initial Creation

*****************************************************************************************************************************
*/
trigger GW_CaseCommentTrigger on CaseComment (before insert,after insert,before update,after update) {
     CS_ByPass__c  bypass = CS_ByPass__c.getInstance(UserInfo.getUserId());
    // Exit the Trigger if the customsetting value is set to True 
    
    if(bypass.CS_Disable_Trigger__c){return;}     
    CS_TriggerFactory.createHandler(CaseComment.sObjectType);
}