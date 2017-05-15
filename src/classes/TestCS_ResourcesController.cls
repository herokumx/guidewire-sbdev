@isTest
public class TestCS_ResourcesController {
    static User testUser;
    static User customerCommunityTestUser;
    static User partnerCommunityTestUser;
    static Account customerAcc;
    static Account partnerAcc;
    static List<Asset> parentAssetsCustomer;
    static List<Asset> parentAssetsPartner;
    static Asset childAsset;
    static Product2 prod;
    static CS_Release__c release;
    static Contact contact;
    
    private static void setupTestData() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        contact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        // insert child assets for customer assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
    }
    
    static testMethod void testResourcesController() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
			customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
                Test.startTest();
                setupTestData();
                List<String> releaseProducts = CS_ResourcesController.getReleaseProducts();
                List<String> productVersions = CS_ResourcesController.getProductVersions('TestProduct');
                List<String> languages = CS_ResourcesController.getLanguagePickval();
               
                CS_Product_Group__c pg = new CS_Product_Group__c();
                pg.Name = 'PG-1';
                pg.CS_Product_Group_Name__c = 'BillingCenter Group';
                insert pg;
                
                List<String> productGroups = CS_ResourcesController.getProductGroupPickvals();
                List<String> productsByProductGroup = CS_ResourcesController.getProductsByProductGroup('BillingCenter Group');
                
                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                Map<String, String> releaseProductByAsset = CS_ResourcesController.getReleaseProductByAsset(cAsset.Id);
                Test.stopTest();
            }
        } 
    }
}