@isTest
public class TestCS_Case_Util {
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    static Entitlement ent;
    static CS_Milestone_Business_Hours__c mbh;
    
    static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
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
             //acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        
        List<Case> caseList = new List<Case>();
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '1-Blocker';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        caseList.add(c);
        insert caseList;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
        
    }
    /*
    static testMethod void testEntMatchbyACP() {
        setupTestData();
        
        Test.startTest();
        
        // query case
        List<Case> cList = [Select Id, CS_Contact_Asset__c from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        // query acp
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id from CS_Asset_Contact_Permissions__c];
        Set<Id> acpIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c a : acpList) {
            acpIds.add(a.Id);
        }
        
        CS_Case_Util.EntMatchbyACP(acpIds, cList);
        Test.stopTest();
    }
    */
    
    static testMethod void testAutoCloseResponseTime_FirstEmail() {
        
        setupTestData();
        
        //query case
        
        Case insertedCase = [Select Id from Case limit 1];
        Test.startTest();
        List<EmailMessage> emList = new List<EmailMessage>();
        EmailMessage em1 = new EmailMessage();
        em1.ParentId = insertedCase.Id;
        em1.ToAddress = 'toAddress@gmail.com';
        em1.Subject = 'TestEmail1';
        em1.TextBody='TestEmail';
        emList.add(em1);
        
       /* EmailMessage em2 = new EmailMessage();
        em2.ToAddress = 'setToAddress@gmail.com';
        em2.Parentid=insertedCase.Id;
        em2.Subject = 'TestEmail2';
        em2.TextBody='TestEmail';
        emList.add(em2);*/
        
        insert emList;
        
        
        
        // query case
        List<Case> cList = [Select Id, CS_Contact_Asset__c from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        // query acp
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id from CS_Asset_Contact_Permissions__c];
        Set<Id> acpIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c a : acpList) {
            acpIds.add(a.Id);
        }
        
        // query emailmessage
        List<EmailMessage> insertedEmList = [Select Id from EmailMessage where ToAddress = 'setToAddress@gmail.com'];
        Set<Id> setToIds = new Set<Id>();
        for (EmailMessage em : insertedEmList) {
            setToIds.add(em.Id);
        }
        
        Map<String, String> setToemailMessage = new Map<String, String>();
        setToemailMessage.put('contactEmail@gmail.com', 'ToAddress@gmail.com');
        
        CS_Case_Util.AutoCloseResponseTime_FirstEmail(caseIds, setToIds, setToemailMessage);
        Test.stopTest();
    }
    
    static testMethod void testAutoCloseResponseTime() {
        
        setupTestData();
        
        //query case
        Test.startTest();
        Case insertedCase = [Select Id from Case limit 1];
          
        List<EmailMessage> emList = new List<EmailMessage>();
        EmailMessage em1 = new EmailMessage();
        em1.ParentId = insertedCase.Id;
        em1.ToAddress = 'toAddress@gmail.com';
        em1.Subject = 'TestEmail1';
        em1.TextBody='TestEmail';
        emList.add(em1);
        
      /*  EmailMessage em2 = new EmailMessage();
        em2.ToAddress = 'setToAddress@gmail.com';
        em2.Parentid=insertedCase.Id;
        em2.Subject = 'TestEmail2';
        em2.TextBody = 'TestEmail1';
        emList.add(em2);*/
        
        insert emList;
        
      
        
        // query case
        List<Case> cList = [Select Id, CS_Contact_Asset__c from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        // query acp
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id from CS_Asset_Contact_Permissions__c];
        Set<Id> acpIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c a : acpList) {
            acpIds.add(a.Id);
        }
        
        // query emailmessage
        List<EmailMessage> insertedEmList = [Select Id from EmailMessage where ToAddress = 'setToAddress@gmail.com'];
        Set<Id> setToIds = new Set<Id>();
        for (EmailMessage em : insertedEmList) {
            setToIds.add(em.Id);
        }
        
        Map<String, String> setToemailMessage = new Map<String, String>();
        setToemailMessage.put('contactEmail@gmail.com', 'ToAddress@gmail.com');
        
        CS_Case_Util.AutoCloseResponseTime(caseIds, setToIds, setToemailMessage);
        Test.stopTest();
    }
    
    static testMethod void testAutoClosePrelimAPTarget() {
        
        setupTestData();
        
        //query case
        
        Case insertedCase = [Select Id from Case limit 1];
        Test.startTest();
        List<EmailMessage> emList = new List<EmailMessage>();
        EmailMessage em1 = new EmailMessage();
        em1.ParentId = insertedCase.Id;
        em1.ToAddress = 'toAddress@gmail.com';
        em1.Subject = 'TestEmail1';
        em1.TextBody='TestEmail';
        emList.add(em1);
        
       /* EmailMessage em2 = new EmailMessage();
        em2.ParentId = insertedCase.Id;
        em2.ToAddress = 'setToAddress@gmail.com';
        em2.Subject = 'TestEmail2';
        em2.TextBody='TestEmail';
        emList.add(em2);*/
        
        insert emList;
        
        
        
        // query case
        List<Case> cList = [Select Id, CS_Contact_Asset__c from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        // query acp
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id from CS_Asset_Contact_Permissions__c];
        Set<Id> acpIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c a : acpList) {
            acpIds.add(a.Id);
        }
        
        // query emailmessage
        List<EmailMessage> insertedEmList = [Select Id from EmailMessage where ToAddress = 'setToAddress@gmail.com'];
        Set<Id> setToIds = new Set<Id>();
        for (EmailMessage em : insertedEmList) {
            setToIds.add(em.Id);
        }
        
        Map<String, String> setToemailMessage = new Map<String, String>();
        setToemailMessage.put('contactEmail@gmail.com', 'ToAddress@gmail.com');
        
        CS_Case_Util.AutoClosePrelimAPTarget(caseIds, setToIds, setToemailMessage);
        Test.stopTest();
    }
    
    static testMethod void testAutoClosePrelimDPTarget() {
        setupTestData();
        Test.startTest();
                
        //query case
        
        Case insertedCase = [Select Id from Case limit 1];
         
        List<EmailMessage> emList = new List<EmailMessage>();
        EmailMessage em1 = new EmailMessage();
        em1.ParentId = insertedCase.Id;
        em1.ToAddress = 'toAddress@gmail.com';
        em1.Subject = 'TestEmail1';
        em1.TextBody='TestEmail';
        emList.add(em1);
        
       /* EmailMessage em2 = new EmailMessage();
        em2.Parentid=insertedCase.Id;
        em2.ToAddress = 'setToAddress@gmail.com';
        em2.Subject = 'TestEmail2';
        em2.TextBody='TestEmail';
        emList.add(em2);*/
        
        insert emList;
        
       
        
        // query case
        List<Case> cList = [Select Id, CS_Contact_Asset__c from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        // query acp
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id from CS_Asset_Contact_Permissions__c];
        Set<Id> acpIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c a : acpList) {
            acpIds.add(a.Id);
        }
        
        // query emailmessage
        List<EmailMessage> insertedEmList = [Select Id from EmailMessage where ToAddress = 'setToAddress@gmail.com'];
        Set<Id> setToIds = new Set<Id>();
        for (EmailMessage em : insertedEmList) {
            setToIds.add(em.Id);
        }
        
        Map<String, String> setToemailMessage = new Map<String, String>();
        setToemailMessage.put('contactEmail@gmail.com', 'ToAddress@gmail.com');
        
        CS_Case_Util.AutoClosePrelimDPTarget(caseIds, setToIds, setToemailMessage);
        Test.stopTest();
    }
    
    static testMethod void testCloseRestorationMS() {
        setupTestData();
        testUser = CS_TestDataUtility.createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            
            List<Case> cList = [Select Id from Case];
            Set<Id> caseIds = new Set<Id>();
            for (Case ca : cList) {
                caseIds.add(ca.Id);
            }

            CS_Case_Util.CloseRestorationMS(caseIds);
            Test.stopTest();
            
        }
    }
}