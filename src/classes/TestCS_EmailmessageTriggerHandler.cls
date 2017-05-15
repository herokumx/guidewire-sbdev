@isTest
public class TestCS_EmailmessageTriggerHandler {
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static User customerCommunityTestUser;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    static ContentVersion contentVersion;
    static ContentDocumentLink cdl;
    static List<GW_Common_Settings__c> commonSettings;
    static Entitlement ent;
    static CS_Milestone_Business_Hours__c mbh;
    static CaseTeamRole ctr;
    static CaseTeamMember ctm;
    
    static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        testUser = CS_TestDataUtility.createServiceTestUser();
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
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
             acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         }
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours2();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement2(childAsset, customerAcc);
                
    }
    
    static testMethod void testEmailmessageInsertInitialResponse() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        testUser = CS_TestDataUtility.createServiceTestUser();
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
          //   acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours2();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        //query acp
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
      
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement2(childAsset, customerAcc);
        
        Test.startTest();
        // query case
        Case insertedCase = [Select Id from Case limit 1];
        EmailMessage em = new EmailMessage();
        em.TextBody = 'TestEmailMessage';
        em.ParentId = insertedCase.Id;
        em.Subject = 'Initial Response';
        em.ToAddress = 'toAddress@gmail.com';
        em.FromAddress = 'testcustsup3@guidewire.com';
        insert em;
        Test.stopTest();
    }
    
    static testMethod void testEmailmessageInsertPreliminary() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        testUser = CS_TestDataUtility.createServiceTestUser();
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
            // acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours('CM-BH-18', 'Preliminary Action Plan (2S)', 'Non-Standard-Berkley', 1, '2-Critical');
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '2-Critical';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc, 'Non-Standard-Berkley');
        
        Test.startTest();
        // query case
        Case insertedCase = [Select Id from Case limit 1];
        EmailMessage em = new EmailMessage();
        em.TextBody = 'TestEmailMessage';
        em.ParentId = insertedCase.Id;
        em.Subject = ' Preliminary Action Plan';
        em.ToAddress = 'toAddress@gmail.com';
        em.FromAddress = 'testcustsup3@guidewire.com';
        insert em;
        Test.stopTest();
    }
    
    static testMethod void testEmailmessageInsertDetailed() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        testUser = CS_TestDataUtility.createServiceTestUser();
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
           //  acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours('CM-BH-42', 'Detailed Action Plan (2S)', 'Non-Standard-TIG', 1, '2-Critical');
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '2-Critical';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc, 'Non-Standard-TIG');
        Test.startTest();
        // query case
        Case insertedCase = [Select Id from Case limit 1];
        EmailMessage em = new EmailMessage();
        em.TextBody = 'TestEmailMessage';
        em.ParentId = insertedCase.Id;
        em.Subject = ' Detailed Action Plan';
        em.ToAddress = 'toAddress@gmail.com';
        em.FromAddress = 'testcustsup3@guidewire.com';
        insert em;
        em.Subject = ' Detailed Action Plan 2';
        update em;
             
        c.CS_Urgency__c = 'low';
        update c;
        
        EmailMessage em2 = new EmailMessage();
        em2.TextBody  ='TestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTestEmailMessageLongTest';
        em2.ParentId = insertedCase.Id;
        em2.Subject = ' Detailed Action Plan';
        em2.ToAddress = 'toAddress@gmail.com';
        em2.FromAddress = 'testcustsup3@guidewire.com';
        insert em2;
        
        CS_EmailmessageTriggerHandler handler = new CS_EmailmessageTriggerHandler();
        handler.beforeinsert(null);
        handler.beforeUpdate(null,null);
        handler.beforeDelete(null);
        handler.afterupdate(null,null);
        handler.afterDelete(null);
        Test.stopTest();
    }
}