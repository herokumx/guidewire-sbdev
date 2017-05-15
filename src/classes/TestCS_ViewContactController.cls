@isTest
public class TestCS_ViewContactController {
	static User testUser;
    static User customerCommunityTestUser;
    static Account customerAcc;
    static Account partnerAcc;
    static List<Asset> parentAssetsCustomer;
    static List<Asset> parentAssetsPartner;
    static Asset childAsset;
    static Product2 prod;
    static CS_Release__c release;
    static Contact contact;
    
    private static void setupTestCustomerData() {
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
    
    static testMethod void testViewContactControllerWithAll() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        System.debug('currentUsr ' + currentUsr);

        System.runAs(currentUsr) {
			customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
                Test.startTest();
                setupTestCustomerData();
                User currentUser = CS_ViewContactsController.getCurrentUser();
                List<CS_Asset_Contact_Permissions__c> contactList = CS_ViewContactsController.getcontactlist();
                List<String> parentAssets = CS_ViewContactsController.getParentAssets('TestParentAsset');
                List<CS_Asset_Contact_Permissions__c> parentAssetswithId = CS_ViewContactsController.getParentAssetswithId('TestParentAsset');
                List<String> products = CS_ViewContactsController.getProducts();
                List<String> childAssetProducts = CS_ViewContactsController.getChildAssetProducts('All');
                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Asset_Contact_Permissions__c> contactsByAsset = CS_ViewContactsController.getContactsByAsset(cAsset.Id);
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testViewContactControllerWithNotAll() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        System.debug('currentUsr ' + currentUsr);

        System.runAs(currentUsr) {
			customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
                Test.startTest();
                setupTestCustomerData();
                User currentUser = CS_ViewContactsController.getCurrentUser();
                List<CS_Asset_Contact_Permissions__c> contactList = CS_ViewContactsController.getcontactlist();
                List<String> parentAssets = CS_ViewContactsController.getParentAssets('TestParentAsset');
                List<CS_Asset_Contact_Permissions__c> parentAssetswithId = CS_ViewContactsController.getParentAssetswithId('TestParentAsset');
                List<String> products = CS_ViewContactsController.getProducts();
                List<String> childAssetProducts = CS_ViewContactsController.getChildAssetProducts('TestParentAsset');
                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Asset_Contact_Permissions__c> contactsByAsset = CS_ViewContactsController.getContactsByAsset(cAsset.Id);
                Test.stopTest();
            }
        }
    }
}