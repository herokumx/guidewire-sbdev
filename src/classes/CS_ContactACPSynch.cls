/*
******************************************************************************************************************************
Controller Class Name- DE1027 CS_ContactACPSynch
Object - 
Purpose- Whenver the Contact record type has been changed to Customer. Look for Assets which does not have the ACP and create
ACP
From the update list, get the map of contacts for which the record type has changed 
Query the Assets for the contact
-- Make a set of Assets. 
Map the Asset and Contacts 
Query the ACPs for the Assets. 
Loop through the Assets for which there is no ACP's and create the ACPs' Condition CS_No_Customer_Contact__c excluded Cognos Assets 
This logic executes only for contacts for Partner and Customer type accounts. 
     
*****************************************************************************************************************************

Name     Email              Date         Notes 
Suchitra spurushotham       11/3/2016    Initial Creation for DE1027

*****************************************************************************************************************************
*/
public class CS_ContactACPSynch {

public static void run (Map<Id,Contact> contactOldMap, Map<Id,Contact> contactNewMap) {
        
        Set<Id> setContacts = new Set<Id>();
        Set<Id> setAccounts = new Set<Id>();
        List<Contact> lstContact = new List<Contact>();
        List<CS_Asset_Contact_Permissions__c> lstAssetContactPermission = new List<CS_Asset_Contact_Permissions__c>();
        Map<String,CS_Asset_Contact_Permissions__c> mapExistingAcps = new Map<String,CS_Asset_Contact_Permissions__c>(); 
        Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Contact');
  
        for (Contact contactRec:contactNewMap.Values()) {
            
            Contact contactRecOld =  contactOldMap.get(contactRec.ID);
          
            if (mapOfRecordType.get(contactRec.RecordTypeId) != mapOfRecordType.get(contactRecOld.RecordTypeId) )
            {
                if (mapOfRecordType.get(contactRec.RecordTypeId) == 'Support')
                {
                    setContacts.add(contactRec.Id);
                    setAccounts.add(contactRec.AccountId);
                    lstContact.add(contactRec);
                }
            }        
        }
        if (setContacts.size() > 0 )
        {
        
         List<CS_Asset_Contact_Permissions__c> lstAssetContactPermissions = new List<CS_Asset_Contact_Permissions__c>([Select ID, CS_ACP_Unique_Key__c,CS_Asset__c,CS_Contact__c from CS_Asset_Contact_Permissions__c Where CS_Contact__c IN:setContacts]);
           
          for (CS_Asset_Contact_Permissions__c loopExistingASP:lstAssetContactPermissions){
              mapExistingAcps.put(String.Valueof(loopExistingASP.CS_Contact__c)+ String.Valueof(loopExistingASP.CS_Asset__c) ,loopExistingASP);
          }
    
          List<Asset> lstAsset =new List<Asset>([Select Id, CS_Is_Active__c,AccountId from Asset where CS_Record_Type_Name__c = 'Parent Asset' AND AccountId in:setAccounts AND CS_No_Customer_Contact__c=:False]);
          Map<ID, Account> mapAccountsforTypeCheck = new Map<Id,Account>([Select ID, RecordType.Name from Account Where Id in:setAccounts]);
  
          for (Contact contactR:lstContact){
                 Account acnt = new Account();
                 acnt = mapAccountsforTypeCheck.get(contactR.AccountId);
                 String acntRecordTypName = acnt.RecordType.Name;
              if (acntRecordTypName.ToUpperCase() == 'CUSTOMER' || acntRecordTypName.ToUpperCase() == 'PARTNER'){
              for (Asset assetRec:lstAsset){
                 if (contactR.AccountId == assetRec.AccountID && mapExistingAcps.get(String.ValueOf(contactR.Id) + String.ValueOf(assetRec.Id))==NULL ){
                     CS_Asset_Contact_Permissions__c newacpRecord = new CS_Asset_Contact_Permissions__c();
                     newacpRecord.CS_Access_Type__c ='General Customer';
                     newacpRecord.CS_Asset__c = assetRec.Id;
                     newacpRecord.CS_Contact__c = contactR.Id;
                     newacpRecord.Name = contactR.FirstName + ' ' + contactR.LastName;
                     if (contactR.User__c != null && contactR.User__c != ''){
                     newacpRecord.CS_IsActive__c = true;
                     }else {
                      newacpRecord.CS_IsActive__c = false;
                     }
                     lstAssetContactPermission.add(newacpRecord);
                 }
              }
              }
          }
        }
        try {
        if (lstAssetContactPermission.size()>0){
            insert lstAssetContactPermission;
            
        }
        }catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Upserting Case Team Member list newCaseTeamMemberList'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }
    }         
 
}