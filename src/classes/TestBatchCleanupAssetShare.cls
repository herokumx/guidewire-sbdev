@isTest
public class TestBatchCleanupAssetShare {
    static testMethod void testBatchCleanupAssetShare() {
        Account customerAcc = CS_TestDataUtility.createCustomerAccount();
        Contact customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        Product2 prod = CS_TestDataUtility.createProductRecord();
        User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact); 
        
        User testUser = CS_TestDataUtility.createTestUser();
        // insert parent asset for customer account
        Asset parentAssetsCustomer = CS_TestDataUtility.createParentAsset(customerAcc, true);
        
        Account partnerAcc = CS_TestDataUtility.createPartnerAccount();
        Contact partnerContact =  CS_TestDataUtility.createContact(partnerAcc, 'Partner');
        User partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(partnerContact);
        
        AssetShare asNeedsToDelete = new AssetShare();
        asNeedstoDelete.AssetAccessLevel = 'Read';
        asNeedstoDelete.AssetId = parentAssetsCustomer.Id;
        asNeedstoDelete.RowCause = 'Manual';
        asNeedstoDelete.UserOrGroupId = partnerCommunityTestUser.Id;
        insert asNeedstoDelete;
        
        Test.startTest();
        BatchCleanupAssetShare cleanup = new BatchCleanupAssetShare();
        Database.executeBatch(cleanup, 1);
        Test.stopTest();
    }
}