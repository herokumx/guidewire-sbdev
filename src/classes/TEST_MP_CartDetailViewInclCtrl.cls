@isTest
public class TEST_MP_CartDetailViewInclCtrl {
	@testSetup static void setup() {
    	 //create test user to create data
        Profile pAdmin = [select Id from profile where Name = 'System Administrator'];
        Profile pComm = [select Id from profile where Name = 'Customer Community User'];
        UserRole rAdmin = [select Id from userrole where Name = 'CEO'];
        User admin = TEST_MP_TestDataSetup.createAdminUser(1, pAdmin.Id, rAdmin.Id);
        system.runAs(admin){
            ccrz__E_AccountGroup__c ag = TEST_MP_TestDataSetup.createAccountGroup(); insert ag;
            Account acct = TEST_MP_TestDataSetup.createAccount('Account', ag.Id); insert acct;
            Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
            ccrz__E_Product__c product = TEST_MP_TestDataSetup.createProduct('Product Name', 'prod1'); insert product;
            User communityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pComm.Id); insert communityUser;
        }
    }
    static testMethod void testMP_CartDetailViewInclCtrl() {
    	User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        system.runAs(u){
            Test.startTest();
            	ccrz__E_Cart__c cart = TEST_MP_TestDataSetup.createCart(u.Id, u.Contact.Account.Id, u.ContactId); insert cart;
            	ccrz__E_CartItem__c cartItem = TEST_MP_TestDataSetup.createCartItem(cart.Id, product.Id); insert cartItem;
            	Test.setCurrentPageReference(new PageReference('Page.ccrz__Cart'));
            	System.currentPageReference().getParameters().put('cartID', cart.ccrz__EncryptedId__c);
            	MP_CartDetailViewInclCtrl ctrl = new MP_CartDetailViewInclCtrl();
            Test.stopTest();
        }
    }
}