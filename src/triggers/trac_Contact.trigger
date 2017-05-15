/**
 * @description Trigger on Contact
 * @author KJ, Traction On Demand
 * @date May 25/2015
*****************************************************************************************************************************

Name     Email              Date         Notes 
Suchitra spurushotham       11/4/2016    Added line 23 for DE1027

*****************************************************************************************************************************
 */

trigger trac_Contact on Contact (before insert, after insert, before update, after update,before delete) {
    if( trigger.isBefore && trigger.isInsert) {
      
    }    
    if(Trigger.isBefore && trigger.isUpdate){
       
    }    
    //Automatically submit the account for approval when status is changed to 'Resubmit Required'
    if( trigger.isAfter && trigger.isUpdate){   
        trac_ACRIntegrationManager.run(Trigger.oldMap, Trigger.newMap);
        CS_ContactACPSynch.run(Trigger.oldMap, Trigger.newMap);
    }
    if(trigger.isDelete && trigger.isBefore){
        trac_AccountHandler.validateAccountContactDeletion(trigger.old,'Contact');
     }

}