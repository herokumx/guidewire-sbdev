@isTest
public class TEST_MP_api_CartExtension extends ccrz.cc_api_CartExtension {
    @testSetup static void setup() {
         //create test user to create data
        Profile pAdmin = [select Id from profile where Name = 'System Administrator'];
        Profile pCommCust = [select Id from profile where Name = 'Customer Community User'];
        Profile pCommPart = [select Id from profile where Name = 'Partner Community User'];
        UserRole rAdmin = [select Id from userrole where Name = 'CEO'];
        User admin = TEST_MP_TestDataSetup.createAdminUser(1, pAdmin.Id, rAdmin.Id);
        system.runAs(admin){
            ccrz__E_AccountGroup__c ag = TEST_MP_TestDataSetup.createAccountGroup(); insert ag;
            Account acct = TEST_MP_TestDataSetup.createAccount('Account1', ag.Id); 
            acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            insert acct;
            Account acct2 = TEST_MP_TestDataSetup.createAccount('Account2', ag.Id); 
            acct2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            acct2.Alliance_Type__c = 'PartnerConnect - Consulting';
            acct2.Tier__c ='Select';
            insert acct2;
            Account acct3 = TEST_MP_TestDataSetup.createAccount('Account3', ag.Id); 
            acct3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            acct3.Alliance_Type__c = 'PartnerConnect - Solution';
            acct3.Tier__c ='Select';
            insert acct3;
            Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
            Contact cont2 = TEST_MP_TestDataSetup.createContact(acct2.Id, 'Johnny', 'Doe'); cont2.MP_Certified__c = true; insert cont2;
            Contact cont3 = TEST_MP_TestDataSetup.createContact(acct3.Id, 'Johnny2', 'Doe'); cont2.MP_Certified__c = true; insert cont3;
            User custCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pCommCust.Id); insert custCommunityUser;
            User partCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont2, 2, pCommPart.Id); insert partCommunityUser;
            User partCommunityUser2 = TEST_MP_TestDataSetup.createCommunityUser(cont3, 2, pCommPart.Id); insert partCommunityUser2; 
            ccrz__E_Product__c product = TEST_MP_TestDataSetup.createProduct('Product Name', 'prod1'); insert product;
            //User communityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pComm.Id); insert communityUser;
        }
    }
    static testMethod void testMP_api_CartExtension_preProcess() {
        User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        system.runAs(u){
            Test.startTest();
                ccrz__E_Cart__c cart = TEST_MP_TestDataSetup.createCart(u.Id, u.Contact.Account.Id, u.ContactId); insert cart;
                ccrz__E_CartItem__c cartItem = TEST_MP_TestDataSetup.createCartItem(cart.Id, product.Id); insert cartItem;
                Test.setCurrentPageReference(new PageReference('Page.ccrz__Cart'));
                System.currentPageReference().getParameters().put('cartID', cart.ccrz__EncryptedId__c);
                MP_api_CartExtension ctrl = new MP_api_CartExtension();
                Map<String,object> inputData = new Map<String,Object>();
                inputData.put(ccrz.cc_api_CartExtension.PARAM_CARTITEMS,new List<ccrz__E_CartItem__c>{cartItem});
                ctrl.preprocess(inputData);
            Test.stopTest();
        }
    }
    static testMethod void testMP_api_CartExtension() {
        User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        system.runAs(u){
            Test.startTest();
                ccrz__E_Cart__c cart = TEST_MP_TestDataSetup.createCart(u.Id, u.Contact.Account.Id, u.ContactId); insert cart;
                ccrz__E_CartItem__c cartItem = TEST_MP_TestDataSetup.createCartItem(cart.Id, product.Id); insert cartItem;
                Test.setCurrentPageReference(new PageReference('Page.ccrz__Cart'));
                System.currentPageReference().getParameters().put('cartID', cart.ccrz__EncryptedId__c);
                MP_api_CartExtension ctrl = new MP_api_CartExtension();
                system.assert(ctrl.allowCheckout(new Map<String,Object>()));
            Test.stopTest();
        }
    }
    static testMethod void testMP_api_CartExtension2() {
        User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Partner Community User' and Contact.Account.Alliance_Type__c = 'PartnerConnect - Consulting' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        system.runAs(u){
            Test.startTest();
                ccrz__E_Cart__c cart = TEST_MP_TestDataSetup.createCart(u.Id, u.Contact.Account.Id, u.ContactId); insert cart;
                ccrz__E_CartItem__c cartItem = TEST_MP_TestDataSetup.createCartItem(cart.Id, product.Id); insert cartItem;
                Test.setCurrentPageReference(new PageReference('Page.ccrz__Cart'));
                System.currentPageReference().getParameters().put('cartID', cart.ccrz__EncryptedId__c);
                MP_api_CartExtension ctrl = new MP_api_CartExtension();
                system.assert(ctrl.allowCheckout(new Map<String,Object>()));
            Test.stopTest();
        }
    }
    static testMethod void testMP_api_CartExtension3() {
        User u = [select id, Contact.Account.Id, ContactId from User where Profile.Name = 'Partner Community User' and Contact.Account.Alliance_Type__c = 'PartnerConnect - Solution' and isActive=true limit 1];
        ccrz__E_Product__c product = [select Id, MP_DownloadURL__c from ccrz__E_Product__c where ccrz__SKU__c = 'prod1'];
        system.runAs(u){
            Test.startTest();
                ccrz__E_Cart__c cart = TEST_MP_TestDataSetup.createCart(u.Id, u.Contact.Account.Id, u.ContactId); insert cart;
                ccrz__E_CartItem__c cartItem = TEST_MP_TestDataSetup.createCartItem(cart.Id, product.Id); insert cartItem;
                Test.setCurrentPageReference(new PageReference('Page.ccrz__Cart'));
                System.currentPageReference().getParameters().put('cartID', cart.ccrz__EncryptedId__c);
                MP_api_CartExtension ctrl = new MP_api_CartExtension();
                system.assert(!ctrl.allowCheckout(new Map<String,Object>()));
            Test.stopTest();
        }
    }
}