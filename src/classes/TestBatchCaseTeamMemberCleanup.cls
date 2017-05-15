@isTest
public class TestBatchCaseTeamMemberCleanup {
    static testMethod void testBatchCaseTeamMemberCleanup() {
        Account customerAcc = CS_TestDataUtility.createCustomerAccount();
        Contact customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        Product2 prod = CS_TestDataUtility.createProductRecord();
        User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact); 
        
        User testUser = CS_TestDataUtility.createTestUser();
        // insert parent asset for customer account
        Asset parentAssetsCustomer = CS_TestDataUtility.createParentAsset(customerAcc, true);
        
        CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer, 'Implementation');
        
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
        //c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        Account partnerAcc = CS_TestDataUtility.createPartnerAccount();
        Contact partnerContact =  CS_TestDataUtility.createContact(partnerAcc, 'Partner');
        User partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(partnerContact);
        
         // query case team role       
        CaseTeamRole ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Support' and AccessLevel = 'Edit' limit 1];
        
        CaseTeamMember ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, partnerCommunityTestUser.Id, ctr.Id);
        
        Test.startTest();
        BatchCaseTeamMemberCleanup cleanup = new BatchCaseTeamMemberCleanup();
        Database.executeBatch(cleanup, 1);
        Test.stopTest();
    }
}