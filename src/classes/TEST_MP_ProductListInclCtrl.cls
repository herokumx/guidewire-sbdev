@isTest
public class TEST_MP_ProductListInclCtrl {
	@testSetup static void setup() {
    	 //create test user to create data
        Profile pAdmin = [select Id from profile where Name = 'System Administrator'];
        Profile pComm = [select Id from profile where Name = 'Customer Community User'];
        UserRole rAdmin = [select Id from userrole where Name = 'CEO'];
        User admin = TEST_MP_TestDataSetup.createAdminUser(1, pAdmin.Id, rAdmin.Id);
        system.runAs(admin){
            ccrz__E_AccountGroup__c ag = TEST_MP_TestDataSetup.createAccountGroup(); insert ag;
            ccrz__E_AccountGroup__c ag2 = TEST_MP_TestDataSetup.createAccountGroup(); 
            ag2.Name = 'Anonymous';
        	ag2.ccrz__AccountGroupID__c = 'Anonymous';
            insert ag2;
            Account acct = TEST_MP_TestDataSetup.createAccount('Account', ag.Id); insert acct;
            Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
            ccrz__E_Product__c product = TEST_MP_TestDataSetup.createProduct('Product Name', 'prod1'); insert product;
            ccrz__E_Category__c category = TEST_MP_TestDataSetup.createCategory('categoryId','Category'); insert category;
            ccrz__E_ProductCategory__c prodCategory = TEST_MP_TestDataSetup.createProductCategory(category.Id, product.Id); insert prodCategory;
            ccrz__E_PriceList__c priceList = TEST_MP_TestDataSetup.createPricelist('Account Group Pricelist'); insert priceList;
            ccrz__E_PriceList__c priceList2 = TEST_MP_TestDataSetup.createPricelist('Anonymous'); insert priceList2;
            ccrz__E_AccountGroupPriceList__c agPricelist = TEST_MP_TestDataSetup.createAccGrpPricelist(priceList.Id, ag.Id); insert agPricelist;
            ccrz__E_AccountGroupPriceList__c agPricelist2 = TEST_MP_TestDataSetup.createAccGrpPricelist(priceList2.Id, ag2.Id); insert agPricelist2;
            ccrz__E_PriceListItem__c priceListItem = TEST_MP_TestDataSetup.createPriceListItem(priceList.Id, product.Id); insert priceListItem;
            ccrz__E_PriceListItem__c priceListItem2 = TEST_MP_TestDataSetup.createPriceListItem(priceList2.Id, product.Id); insert priceListItem2;
            User communityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pComm.Id); insert communityUser;
        }
    }
    static testMethod void testMP_ProductListInclCtrl() {
    	User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        ccrz__E_Category__c category = [select Id from ccrz__E_Category__c where Name = 'Category'];
        system.runAs(u){
            Test.startTest();
            	Test.setCurrentPageReference(new PageReference('Page.ccrz__Products')); 
				System.currentPageReference().getParameters().put('category', category.Id);
            	MP_ProductListInclCtrl ctrl = new MP_ProductListInclCtrl();
            Test.stopTest();
        }
    }
    static testMethod void testMP_ProductListInclCtrl2() {
    	User u = [select id, Contact.Account.Id, ContactId from User where UserType = 'Guest' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        ccrz__E_Category__c category = [select Id from ccrz__E_Category__c where Name = 'Category'];
        system.runAs(u){
            Test.startTest();
            	Test.setCurrentPageReference(new PageReference('Page.ccrz__Products')); 
				System.currentPageReference().getParameters().put('category', category.Id);
            	MP_ProductListInclCtrl ctrl = new MP_ProductListInclCtrl();
            Test.stopTest();
        }
    }
}