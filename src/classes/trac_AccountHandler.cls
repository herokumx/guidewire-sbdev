/**
 * @description Generate auto number for the Participant_id__c field
 *              Automatically submit record for approval
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */

public with sharing class trac_AccountHandler {

    public static Id PROS_RT = Schema.SObjectType.Account.RecordTypeInfosByName.get('Prospect').RecordTypeId;
    public static Id PART_RT = Schema.SObjectType.Account.RecordTypeInfosByName.get('Partner').RecordTypeId;
    public static Id VEND_RT = Schema.SObjectType.Account.RecordTypeInfosByName.get('Vendor').RecordTypeId;
    public static Id CUST_RT = Schema.SObjectType.Account.RecordTypeInfosByName.get('Customer').RecordTypeId;
    public static Boolean disableTrigger = false;

    //Automatically submit the account for approval when status is changed to 'Resubmit Required'
    public static void autoSubmitApproval(Account[] acc){
        if(!disableTrigger){
            for (Account a :acc) {
                if(a.Participant_id__c != null 
                    && a.Approval_Status__c == 'Resubmit Required' 
                    && ( a.RecordTypeId == PROS_RT || a.RecordTypeId == PART_RT || a.RecordTypeId == VEND_RT || a.RecordTypeId == CUST_RT) 
                    && a.Requested_Approval__c !=NULL ){
                    try{
                        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                        req1.setComments('Submitting request for approval.');
                        req1.setObjectId(a.id);
                        Approval.ProcessResult result = Approval.process(req1);
                        System.debug('Approval Process Result:' + result);
                        disableTrigger = true;
                    }catch(Exception e){
                        throw new CustomException('***ERROR: Matching approval process not found.***');
                    }
                }
            }
        }
    }

    public static void validateAccountContactDeletion(List<SObject> oldObjList, String sObjType){
       
       List<Account_Contact__c>  acrList = new List<Account_Contact__c>();
       List<Account> accLst = new List<Account>();
       if(sObjType =='Contact'){
         acrList = [select Id,Account__c,Contact__c  from Account_Contact__c where Contact__c  in: oldObjList and RecordStatus__c = 'Active'];
       }else if(sObjType =='Account'){
         acrList = [select Id,Account__c,Contact__c,Account__r.RecordTypeId  from Account_Contact__c where Account__c in: oldObjList and RecordStatus__c = 'Active'];
         Acclst = [select id,name, Participant_id__c from account where id IN: oldObjList];         
       }
     
       for(SObject  sobj : oldObjList)
       {
          if(acrList.size()>0){
             for(Account_Contact__c acrVar : acrList){
                 if(sObjType =='Contact'){
                     if(acrVar.Contact__c == sobj.Id){
                          sobj.addError('Contact can not be deleted as it has associated Bill To/Ship To.');
                     }
                 } else if(sObjType =='Account'){
                     if(acrVar.Account__c == sobj.Id && acrVar.Account__r.RecordTypeId  == Schema.SObjectType.Account.RecordTypeInfosByName.get('Site').RecordTypeId){
                          sobj.addError('Account can not be deleted as it has associated Bill To/Ship To.');
                     }   
                 }
             }
          } 
          
          // Added to check Participant id - Hari
          
          for(Account acc : Acclst)
          {
            if(acc.id == sobj.id && acc.Participant_id__c != Null)
            {
              sobj.addError('Account can not be deleted as it has Participant Id');
            }
          } 
       }
    }

    public class CustomException extends Exception {}
}