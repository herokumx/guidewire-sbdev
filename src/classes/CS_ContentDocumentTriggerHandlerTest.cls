/*
*****************************************************************************************************************************
Class Name - CS_ContentDocumentTriggerHandlerTest
Class Type -  Trigger Handler Test Ckass 
Test Class-
Purpose- 

*****************************************************************************************************************************

Name        Email              Date             Notes 
Suchitra                                        Initial Creation

*****************************************************************************************************************************
*/

@isTest 

private class CS_ContentDocumentTriggerHandlerTest{
static List<GW_Common_Settings__c> commonSettings;
static testMethod void testContentDocumentTriggerHandler() {

//Create a case 
//Upadte the case with the file upload as a customer support user. 

    CS_Profile_Id__c csProfile = new CS_Profile_Id__c();
    csProfile.CS_Customer_Profile_18__c = GWUtilities.getProfileId('GW Customer Community');
    csProfile.CS_Partner_Profile_18__c = GWUtilities.getProfileId('GW Partner Community');
    
    Map<String,String> mapOfRecordType;

    insert csProfile;
    
    //create test account
    Account acc = CS_TestDataUtility.createCustomerAccount();
    
     System.Debug('acc+++ ' + acc );

    //create parent asset
    List<Asset> parentAsset = CS_TestDataUtility.createParentAssetRecord(acc,true);

    //create product
    Product2 prd = CS_TestDataUtility.createProductRecord();

    //create child asset
    Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');

    //create contact
    Contact con = CS_TestDataUtility.createContact(acc, 'Customer Support');
    
     User u = CS_TestDataUtility.createCustomerCommunityTestUser(con);
     String acntName = acc.Name + ' Customer Support';
     /*UserRole role = [Select Id, PortalType,name, PortalAccountId From UserRole where PortalType =:'CustomerPortal' and Name =: acntName limit 1];
     u.UserRoleId = role.Id;
     update u;
    
    */
    CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createAcp(parentAsset[0],con,'Customer Support', true);

    //create customer community test user
   
    
    System.Debug('User.Role.Name' + u.UserRole.Name);
    System.Debug('User.Role.Id' + u.UserRoleId);
    //create case
    
    
    //create case comment
    
    GW_Common_Settings__c gwSettings = new GW_Common_Settings__c(name= 'EnableContentVersionTrigger', Boolean_Value__c = false);
    insert gwSettings;  
    
   
        Case caseRec = CS_TestDataUtility.createCaseCS(acc, childAsset, con);
               
        mapOfRecordType = GWUtilities.getRecordTypeId('Case');
        caseRec.RecordTypeId =  mapOfRecordType.get('CS_Customer_Support');
        System.Debug('mapOfRecordType' + mapOfRecordType.get('CS_Customer_Support'));
        caseRec.ContactId = con.Id;
         
        update caseRec;
             //ContentDocumentLink cdl = CS_TestDataUtility.createUploadDocument(caseRec);
         
        
        ContentVersion contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        ContentDocumentLink cdl2 = CS_TestDataUtility.createUploadDocument(caseRec);
    

    }
  }