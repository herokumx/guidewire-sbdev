@isTest
public class TestCS_AssetTriggerHandler {
    static User usr;
    static Account customerAcc;
    static Account partnerAcc;
    static Product2 prod;
    static ContentVersion contentVersion;
    static ContentDocumentLink cdl;
    static CS_Release__c release;
    static List<GW_Common_Settings__c> commonSettings;
    static CS_ByPass__c byPass;
    static Contact contact;
    
    private static void setupTestData() {
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        partnerAcc = CS_TestDataUtility.createPartnerAccount();
        contact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        usr = CS_TestDataUtility.createTestUser();
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        cdl = CS_TestDataUtility.createContentDocumentLink(cv.ContentDocumentId, release.Id);
        
    }
    
    static testMethod void testAssetTriggerOnInsert() {
        setupTestData();
        
        System.runAs(usr) {
            Test.startTest();
            
            // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets
            for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
                if (i < parentAssetsCustomer.size() - 1) {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
                } else {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
                }
            }
            
            // insert parent asset for partner account
            List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
            
            // insert child assets
            for (Integer i=0; i < parentAssetsPartner.size(); i++) {
                if (i < parentAssetsPartner.size() - 1) {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Prospect');
                } else {
                    CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Certification');
                }
            }

            Test.stopTest();
        }
    }
    
    static testMethod void testAssetDeactivation() {
        setupTestData();
        Test.startTest();
         // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Asset a : parentAssetsCustomer) {
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, a, 'Implementation');
        }
        /*
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        // insert child assets
        for (Asset a : parentAssetsPartner) {
            CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, a, 'Implementation');
        }
*/
       
        Asset parentAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Parent Asset' and Name = 'TestParentAssetImplementation' limit 1];
        parentAsset.CS_Is_Active__c = false;
        update parentAsset;
        Test.stopTest();
    }
    
    static testMethod void testAssetTriggerWithReleaseOnInsert() {
        setupTestData();
        
        Test.startTest();
         // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets with release record
        for (Asset a : parentAssetsCustomer) {
            CS_TestDataUtility.createChildAssetWithRelease(customerAcc, prod, a, release, 'Prospect');
        }
        
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        // insert child assets with release record
        for (Integer i=0; i < parentAssetsPartner.size(); i++) {
            if (i < parentAssetsPartner.size() -1) {
                CS_TestDataUtility.createChildAssetWithRelease(partnerAcc, prod, parentAssetsPartner[i], release, 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetWithRelease(partnerAcc, prod, parentAssetsPartner[i], release, 'Certification');
            }
        }
        
        Test.stopTest();
    }
    
    static testMethod void testAssetReactivation() {
        setupTestData();
        
        Test.startTest();
         // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, false);
        
        // insert child assets
        for (Asset a : parentAssetsCustomer) {
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, a, 'Implementation');
        }
        
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, false);
        
        // insert child assets
        for (Asset a : parentAssetsPartner) {
            CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, a, 'Implementation');
        }
        Asset parentAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Parent Asset' and Name = 'TestParentAssetImplementation' limit 1];
        parentAsset.CS_Is_Active__c = true;
        update parentAsset;
        Test.stopTest();
    }
    
    static testMethod void testAcpDeactivation() {
        setupTestData();
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        
        /*
         // insert bypass custom setting to disable validation rule
        CS_ByPass__c byPassValidation = new CS_ByPass__c();
        byPassValidation.Name = 'CS_Disable_ValidationRule__c';
        byPassValidation.SetupOwnerId = currentUsr.Id;
        byPassValidation.CS_Disable_ValidationRule__c = true;
        insert byPassValidation;
        */
        
        Test.startTest();
        
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Asset a : parentAssetsCustomer) {
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, a, 'Implementation');
        }

        Asset parentAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' limit 1];
        
        // create case
        //Case c = CS_TestDataUtility.createCase(customerAcc, parentAsset);

        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
        
        List<CS_Asset_Contact_Permissions__c> acpListToUpdate = new List<CS_Asset_Contact_Permissions__c>();
        
        for (CS_Asset_Contact_Permissions__c acp : acpList) {
            if (acp.CS_Access_Type__c == 'Customer Support') {
                acp.CS_Access_Type__c = 'General Customer';
            } else if (acp.CS_Access_Type__c == 'Partner') {
                acp.CS_Access_Type__c = 'General Partner';
            }
            acpListToUpdate.add(acp);
        }
        
        update acpListToUpdate;

        Test.stopTest();
    }
    
    static testMethod void testAcpPartnerDeactivation() {
        setupTestData();
        // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        /*
         // insert bypass custom setting to disable validation rule
        CS_ByPass__c byPassValidation = new CS_ByPass__c();
        byPassValidation.Name = 'CS_Disable_ValidationRule__c';
        byPassValidation.SetupOwnerId = currentUsr.Id;
        byPassValidation.CS_Disable_ValidationRule__c = true;
        insert byPassValidation;
        */
        System.runAs(currentUsr) {
            Test.startTest();
            
            // insert parent asset for partner account
            List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, false);
            
            // insert child assets
            for (Asset a : parentAssetsPartner) {
                CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, a, 'Implementation');
            }
    
            Asset parentAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' limit 1];
            
            // insert bypass custom setting to disable validation rule
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.SetupOwnerId = currentUsr.Id;
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            // create case
            Case c = CS_TestDataUtility.createCase(partnerAcc, parentAsset);
    
            List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
            
            List<CS_Asset_Contact_Permissions__c> acpListToUpdate = new List<CS_Asset_Contact_Permissions__c>();
            
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                acp.CS_Access_Type__c = 'Partner';
                acpListToUpdate.add(acp);
            }
            
            update acpListToUpdate;
    
            Test.stopTest();
        }
    }
    
    static testMethod void testAcpReactivation() {
        setupTestData();
        
        Test.startTest();
        
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
            // create acp
            //CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], contact, 'Customer Support', false);
        }
        
        if (parentAssetsPartner != null && parentAssetsPartner.size() > 0) {
             // create partner acp
             CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsPartner[0], contact, 'Partner', false);
        }
        
        // query just inserted acp
        CS_Asset_Contact_Permissions__c insertedAcp = [Select Id, CS_Access_Type__c, CS_IsActive__c from CS_Asset_Contact_Permissions__c where CS_IsActive__c = false limit 1];
        
        insertedAcp.CS_IsActive__c = true;

        update insertedAcp;     
        
        Test.stopTest();
    }
    
    static testMethod void testFutureMethod() {
        setupTestData();
        byPass = CS_TestDataUtility.createByPass(usr);
        Test.startTest();
        System.runAs(usr) {
             // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert child assets with release record
            for (Asset a : parentAssetsCustomer) {
                CS_TestDataUtility.createChildAssetWithRelease(customerAcc, prod, a, release, 'Prospect');
            }
            
            // insert parent asset for partner account
            List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
            
            // insert child assets with release record
            for (Integer i=0; i < parentAssetsPartner.size(); i++) {
                if (i < parentAssetsPartner.size() -1) {
                    CS_TestDataUtility.createChildAssetWithRelease(partnerAcc, prod, parentAssetsPartner[i], release, 'Prospect');
                } else {
                    CS_TestDataUtility.createChildAssetWithRelease(partnerAcc, prod, parentAssetsPartner[i], release, 'Certification');
                }
            }
        }
        Test.stopTest();
    }
    
    static testMethod void testAcpAccessChange() {
         setupTestData();
        
       Test.startTest();
        
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
         // insert child assets
        for (Asset a : parentAssetsCustomer) {
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, a, 'Implementation');
        }
        
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        
        if (parentAssetsPartner != null && parentAssetsPartner.size() > 0) {
             // create partner acp
            // CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsPartner[0], contact, 'General Partner', true);
        }
       
        List<CS_Asset_Contact_Permissions__c> acpListToUpdate = new List<CS_Asset_Contact_Permissions__c>();
        // query just inserted customer acp
        CS_Asset_Contact_Permissions__c insertedCustomerAcp = [Select Id, CS_Access_Type__c, CS_IsActive__c from CS_Asset_Contact_Permissions__c limit 1];
        insertedCustomerAcp.CS_Access_Type__c = 'Customer Support';
        acpListToUpdate.add(insertedCustomerAcp);
        
        // query just inserted partner acp
       // CS_Asset_Contact_Permissions__c insertedPartnerAcp = [Select Id, CS_Access_Type__c, CS_IsActive__c from CS_Asset_Contact_Permissions__c where CS_Access_Type__c = 'General Partner' limit 1];
        //insertedPartnerAcp.CS_Access_Type__c = 'Partner';
       // acpListToUpdate.add(insertedPartnerAcp);
        
        update acpListToUpdate;
        
        Test.stopTest();
    }
    
    static testMethod void testCaseTeamMember() {
        setupTestData();
        
         // query current test user
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        
        System.runAs(currentUsr) {
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(contact);
            Test.startTest();
            
            // insert parent asset for customer account
            List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
            // insert parent asset for partner account
            List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
            
            // insert child assets partner
            for (Asset a : parentAssetsPartner) {
                CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, a, 'Implementation');
            }
            
            if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
                // create acp
                //CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], contact, 'Customer Support', true);
            }
            
            if (parentAssetsPartner != null && parentAssetsPartner.size() > 0) {
                 // create partner acp
                 CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsPartner[0], contact, 'Partner', true);
            }
            
            Asset parentAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' limit 1];
     
            // insert bypass custom setting to disable validation rule
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.CS_Disable_Trigger__c = true;
            byPassValidation.SetupOwnerId = currentUsr.Id;
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            // create case
            Case c = CS_TestDataUtility.createCase(customerAcc, parentAsset);
            Test.stopTest();
        }
    }
    
      static testMethod void testCustomerCaseCreation() {
        setupTestData();
        
       Test.startTest();
         // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
          
        if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
            // create acp
           // CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], contact, 'General Customer', true);
        }
        /*
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsPartner.size(); i++) {
            if (i < parentAssetsPartner.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Certification');
            }
        }
         */
         
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' limit 1];
          
        // query acp
        CS_Asset_Contact_Permissions__c acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        Case c = new Case();
        c.AssetId = childAsset.Id;
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = contact.Id;
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        Test.stopTest();
    }
}