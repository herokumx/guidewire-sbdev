@isTest
public class TestCS_CaseTriggerHandler {
  static User usr;
    static Account customerAcc;
    static Account partnerAcc;
    static Product2 prod;
    static ContentVersion contentVersion;
    static ContentDocumentLink cdl;
    static CS_Release__c release;
    static List<GW_Common_Settings__c> commonSettings;
    static CS_ByPass__c byPass;
    static Contact customerContact;
    static Contact customerContact1;
    static Contact partnerContact;
   
    
    private static void setupTestData() {
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        partnerAcc = CS_TestDataUtility.createPartnerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        customerContact1 = CS_TestDataUtility.createContact(customerAcc, 'General Customer');
        partnerContact = CS_TestDataUtility.createContact(partnerAcc, 'Partner');
        usr = CS_TestDataUtility.createTestUser();
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        cdl = CS_TestDataUtility.createContentDocumentLink(cv.ContentDocumentId, release.Id);
        CS_TestDataUtility.createACPactivateUser();
    //byPass = CS_TestDataUtility.createByPass(usr);
       
    }

    Static testmethod Void testCustomerCaseCreation1(){

        setupTestData();
        
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            Test.startTest();
            
            // insert bypass custom setting to disable validation rule
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.CS_Batch_Context__c = true;
            byPassValidation.SetupOwnerId = currentUsr.Id;
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
             // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets
            for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
                if (i < parentAssetsCustomer.size() - 1) {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect', customerContact);
                } else {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation', customerContact);
                }
            }
            
            //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
            //    // create acp
            //    CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
            //}
            
            List<Asset> childAssets =  [Select Id, CS_Is_Active__c, ParentId from Asset where CS_Record_Type_Name__c = 'Child Asset'];
            System.debug('===childAssets Test==== ' + childAssets);
           
            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            
            // query acp
            CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c where CS_Access_Type__C = 'Customer Support' limit 1];
            System.debug('=====test acp==== ' + acp);
            
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
            Case c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.CS_Contact_Asset__c = acp.Id; 
            c.Description = 'decription';
            insert c;
 
            Test.stopTest();
        }


    }
    
    static testMethod void testCustomerCaseCreation() {
        setupTestData();
        
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            Test.startTest();
            
            // insert bypass custom setting to disable validation rule
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.CS_Batch_Context__c = true;
            byPassValidation.SetupOwnerId = currentUsr.Id;
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
             // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[0], 'Implementation', customerContact);
            //CS_Asset_Contact_Permissions__c  acp1 = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
            //CS_Asset_Contact_Permissions__c  acp2 = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact1, 'Customer Support (View Only)', true);
            
            List<Asset> childAssets =  [Select Id, CS_Is_Active__c, ParentId from Asset where CS_Record_Type_Name__c = 'Child Asset'];
            System.debug('===childAssets Test==== ' + childAssets);
           
            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            
            // query acp
            CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
      System.debug('=====test acp==== ' + acp);
            
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
            Case c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.CS_Contact_Asset__c = acp.Id; 
            c.Description ='Description..';
            insert c;

            CS_Asset_Contact_Permissions__c  acp1 = [Select Id from CS_Asset_Contact_Permissions__c where CS_Access_Type__c = 'Customer Support' limit 1 ];
    
            CS_Asset_Contact_Permissions__c acp3= [Select id,CS_Access_Type__c from CS_Asset_Contact_Permissions__c where id =:acp1.id limit 1];
            CS_Asset_Contact_Permissions__c  AcpCS2GS= New CS_Asset_Contact_Permissions__c(id=acp3.id,CS_Access_Type__c='Customer Support (View Only)');
            Update AcpCS2GS;




            Test.stopTest();
        }
    }
    
    static testMethod void testCustomerCaseUpdate() {
        setupTestData();
        
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        Test.startTest();
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect', customerContact);
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation', customerContact);
            }
        }
        
        //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
        //    // create acp
        //    CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
        //}
        
                
        // insert bypass custom setting to disable validation rule
        CS_ByPass__c byPassValidation = new CS_ByPass__c();
        byPassValidation.Name = 'CS_Disable_ValidationRule__c';
        byPassValidation.CS_Batch_Context__c = true;
        byPassValidation.SetupOwnerId = currentUsr.Id;
        byPassValidation.CS_Disable_ValidationRule__c = true;
        insert byPassValidation;
       

        System.runAs(currentUsr) {
            
            // query acp
            CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
            System.debug('=====test acp==== ' + acp);

            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
            Case c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.CS_Contact_Asset__c = acp.Id; 
            c.Description = 'test';
            insert c;
         
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            // query case
      Case insertedCase = [Select Id, CaseNumber, Status from Case limit 1];
      insertedCase.Status = 'Closed';
            update insertedCase;
            
        }
        Test.stopTest();
    }
    
    static testMethod void testCustomerCaseUpdateContact() {
        setupTestData();
         Test.startTest();
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect', customerContact);
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation', customerContact);
            }
        }
        
        //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
        //    // create acp
        //    CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
        //}
        
                
        // insert bypass custom setting to disable validation rule
        CS_ByPass__c byPassValidation = new CS_ByPass__c();
        byPassValidation.Name = 'CS_Disable_ValidationRule__c';
        byPassValidation.CS_Batch_Context__c = true;
        byPassValidation.SetupOwnerId = currentUsr.Id;
        byPassValidation.CS_Disable_ValidationRule__c = true;
        insert byPassValidation;
        
        List<Asset> childAssets =  [Select Id, CS_Is_Active__c, ParentId from Asset where CS_Record_Type_Name__c = 'Child Asset'];
        System.debug('===childAssets Test==== ' + childAssets);
        
        Contact otherCustomerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        // query acp
        CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
        System.debug('=====test acp==== ' + acp);
        
        System.runAs(currentUsr) {
           
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
            Case c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.CS_Contact_Asset__c = acp.Id; 
            c.Description = 'description';
            insert c;
         
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            // query case 
      Case insertedCase = [Select Id, CaseNumber, ContactId from Case limit 1];
      insertedCase.ContactId = otherCustomerContact.Id;
            update insertedCase;
            Test.stopTest();
        }
    }
    
    static testMethod void testCustomerCaseCreation2() {
        setupTestData();
         // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
       
        System.runAs(currentUsr) {
        
        
         Test.startTest();
             // insert bypass custom setting to disable validation rule
            /*
            CS_ByPass__c byPassTrigger = new CS_ByPass__c();
            byPassTrigger.Name = 'CS_Disable_Trigger__c';
            byPassTrigger.CS_Disable_Trigger__c = true;
            byPassTrigger.SetupOwnerId = currentUsr.Id;
          insert byPassTrigger;
            */
            // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets
            for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
                if (i < parentAssetsCustomer.size() - 1) {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect', customerContact);
                } else {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation', customerContact);
                }
            }
            
            //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
            //    // create acp
            //    CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
            //}
            // query acp
            //CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
            
            //User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            System.runAs(currentUsr) {
               
                //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
                
                // query acp
              CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
                
                // query case record type
                RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
                Case c = new Case();
                c.AssetId = childAsset.Id;
                c.AccountId = customerAcc.Id;
                c.RecordTypeId = rt.Id;
                c.ContactId = customerContact.Id;
                c.CS_Contact_Asset__c = acp.Id; 
                c.Description = 'Description';
                insert c;
                
            }
            
            Test.stopTest();
        }
    }



     static testMethod void testCustomerCaseCreation_with_ACP() {
        setupTestData();
        
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            Test.startTest();
            
            // insert bypass custom setting to disable validation rule
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.CS_Batch_Context__c = true;
            byPassValidation.SetupOwnerId = currentUsr.Id;
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
             // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets
            for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
                if (i < parentAssetsCustomer.size() - 1) {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect', customerContact);
                } else {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation', customerContact);
                }
            }
            
            //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
                // create acp
              //  CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
            //}
            
            List<Asset> childAssets =  [Select Id, CS_Is_Active__c, ParentId from Asset where CS_Record_Type_Name__c = 'Child Asset'];
            System.debug('===childAssets Test==== ' + childAssets);
           
            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            
            // query acp
            CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Asset__r.ParentId from CS_Asset_Contact_Permissions__c limit 1];
            System.debug('=====test acp==== ' + acp);
            
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
            Case c = new Case();
            //c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.CS_Contact_Asset__c = acp.Id; 
            c.Description = 'this is a description.. ';
            insert c;
 
            Test.stopTest();
        }
    }
}