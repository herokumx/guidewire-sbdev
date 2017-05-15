/**
 * @description Generates a 4 digit Auto Number for the Participant_id__c field 
 *              and automatically submit record for approval
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */

trigger trac_Account on Account (before insert, before update, after update,before delete) {

    if( trigger.isBefore && trigger.isInsert) {
        // Set participant IDs for the filtered accounts
        trac_GenerateAutoNumber.setAccountParticipantIds(Trigger.new);
    }
    
    if(Trigger.isBefore && trigger.isUpdate){
        // Set participant IDs for the filtered accounts
        trac_GenerateAutoNumber.setAccountParticipantIds(Trigger.new);
    }
    
    //Automatically submit the account for approval when status is changed to 'Resubmit Required'
    if( trigger.isAfter && trigger.isUpdate){   
        trac_AccountHandler.autoSubmitApproval(Trigger.New);
        trac_ACRIntegrationManager.run(Trigger.oldMap, Trigger.newMap);
    }
    
     if(trigger.isDelete && trigger.isBefore){
        trac_AccountHandler.validateAccountContactDeletion(trigger.old,'Account');
     }

}