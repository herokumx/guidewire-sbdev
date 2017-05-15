@isTest
public class TestCS_RequestTriggerHandler {
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
    static  Case insertedCase;
    
    static void setupTestData() { 
        
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
        
     
    }
    
    static testMethod void testRequstInsert() {
        setupTestData();

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
        insert c;
        
        // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Support' and AccessLevel = 'Edit' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, testUser.Id, ctr.Id);
       
        Test.startTest();
        // insert Request
        CS_Request__c request = new CS_Request__c();
        request.CS_Case__c = c.Id;
        request.Dev_Assignee__c = testUser.Id;
        request.CS_is_Active__c = true;
        insert request;
        Test.stopTest();        
    }
}