@isTest
public class TEST_MP_NavCtrl {
	@testSetup static void setup() {
    	 //create test user to create data
        Profile pAdmin = [select Id from profile where Name = 'System Administrator'];
        Profile pCommCust = [select Id from profile where Name = 'Customer Community User'];
        Profile pCommPart = [select Id from profile where Name = 'Partner Community User'];
        UserRole rAdmin = [select Id from userrole where Name = 'CEO'];
        User admin = TEST_MP_TestDataSetup.createAdminUser(1, pAdmin.Id, rAdmin.Id);
        system.runAs(admin){
            ccrz__E_AccountGroup__c ag = TEST_MP_TestDataSetup.createAccountGroup(); insert ag;
            Account acct = TEST_MP_TestDataSetup.createAccount('Account', ag.Id); insert acct;
            Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
            Contact cont2 = TEST_MP_TestDataSetup.createContact(acct.Id, 'Johnny', 'Doe'); insert cont2;
            User custCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pCommCust.Id); insert custCommunityUser;
            User partCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont2, 2, pCommPart.Id); insert partCommunityUser;
            ccrz__E_Menu__c menu = TEST_MP_TestDataSetup.createMenu('Go to Community', 'Marketplace'); insert menu;
            ccrz__E_MenuItem__c menuItem1 = TEST_MP_TestDataSetup.createMenuItem(menu.Id, 'Partner', 'www.google.com'); insert menuItem1;
            ccrz__E_MenuItem__c menuItem2 = TEST_MP_TestDataSetup.createMenuItem(menu.Id, 'Customer', 'www.guidewire.com'); insert menuItem2;
        }
    }
    static testMethod void testMP_NavCtrl() {
    	User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        system.runAs(u){
            Test.startTest();
            	Test.setCurrentPageReference(new PageReference('Page.ccrz__HomePage')); 
            	MP_NavCtrl ctrl = new MP_NavCtrl();
            	ctrl.communityLinkName = 'Customer';
            	system.assertEquals('www.guidewire.com', ctrl.communityUrl);
            Test.stopTest();
        }
    }
    static testMethod void testMP_NavCtrl2() {
    	User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Partner Community User' and isActive=true limit 1];
        system.runAs(u){
            Test.startTest();
            	Test.setCurrentPageReference(new PageReference('Page.ccrz__Products')); 
            	MP_NavCtrl ctrl = new MP_NavCtrl();
            	ctrl.communityLinkName = 'Partner';
            	system.assertEquals('www.google.com', ctrl.communityUrl);
            Test.stopTest();
        }
    }
}