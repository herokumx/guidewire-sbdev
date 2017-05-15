@IsTest
public class TEST_MP_ReviewsCtrl {

    public static ccrz__E_Product__c product1;
    public static ccrz__E_Product__c product2;

    private static void setupCallContext() {
        /*ccrz__E_AccountGroup__c ag = TEST_MP_TestDataSetup.createAccountGroup(); insert ag;
        Id acctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acct = TEST_MP_TestDataSetup.createAccount('Account', ag.Id); 
        acct.RecordTypeId = acctRecordTypeId;
        insert acct;
        Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
        Contact cont2 = TEST_MP_TestDataSetup.createContact(acct.Id, 'Johnny', 'Doe'); insert cont2;
        User custCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pCommCust.Id); insert custCommunityUser;
        User partCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont2, 2, pCommPart.Id); insert partCommunityUser;
        ccrz.cc_CallContext.currAccountId = acct.Id;
        ccrz.cc_CallContext.currUserId = custCommunityUser.Id;
        ccrz.cc_CallContext.storefront = 'MarketPlace';*/
    }

    @TestSetup static void setupTests() {
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
            acct2.Tier__c ='Select';
            insert acct2;
            Account acct3 = TEST_MP_TestDataSetup.createAccount('Account3', ag.Id); 
            acct3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            acct3.Alliance_Type__c = 'PartnerConnect - Solution';
            acct3.Tier__c ='Select';
            insert acct3;
            Contact cont = TEST_MP_TestDataSetup.createContact(acct.Id, 'John', 'Doe'); insert cont;
            Contact cont2 = TEST_MP_TestDataSetup.createContact(acct2.Id, 'Johnny', 'Doe'); insert cont2;
            Contact cont3 = TEST_MP_TestDataSetup.createContact(acct3.Id, 'Johnny2', 'Doe'); insert cont3;
            User custCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont, 1, pCommCust.Id); insert custCommunityUser;
            User partCommunityUser = TEST_MP_TestDataSetup.createCommunityUser(cont2, 2, pCommPart.Id); insert partCommunityUser;
            User partCommunityUser2 = TEST_MP_TestDataSetup.createCommunityUser(cont3, 2, pCommPart.Id); insert partCommunityUser2;
            ccrz__E_Menu__c menu = TEST_MP_TestDataSetup.createMenu('Go to Community', 'Marketplace'); insert menu;
            ccrz__E_MenuItem__c menuItem1 = TEST_MP_TestDataSetup.createMenuItem(menu.Id, 'Partner', 'www.google.com'); insert menuItem1;
            ccrz__E_MenuItem__c menuItem2 = TEST_MP_TestDataSetup.createMenuItem(menu.Id, 'Customer', 'www.guidewire.com'); insert menuItem2;
            
            ccrz.cc_CallContext.currAccountId = acct.Id;
            ccrz.cc_CallContext.currUserId = custCommunityUser.Id;
            ccrz.cc_CallContext.storefront = 'MarketPlace';
            
            //setupCallContext();
            List<ccrz__E_Review__c> reviews = new List<ccrz__E_Review__c>();
    
            product1 = new ccrz__E_Product__c(ccrz__SKU__C='testSKU1',  Name='test product 1', ccrz__ProductStatus__c='Released');
            insert product1;
    
            product2 = new ccrz__E_Product__c(ccrz__SKU__C='testSKU2',  Name='test product 2',ccrz__ProductStatus__c='Released');
            insert product2;
    
            String subject = 'test subject';
            String reviewText = 'test review text';
            String rating = '5';
    
            //TEST_MP_TestDataSetup.createAccountUser(TEST_MP_TestDataSetup.PROFILE_CUSTOMER_COMMUNITY);
    
            // create 5 reviews for target product with 'New' status
            Integer i;
            for (i=0; i < 5; i++) {
                ccrz__E_Review__c review = new ccrz__E_Review__c();
                review.ccrz__Product__c = product1.Id;
                review.ccrz__Status__c = 'New';
                review.ccrz__Subject__c = subject + String.valueOf(i);
                review.ccrz__UserReview__c = reviewText + String.valueOf(i);
                review.ccrz__User__c = ccrz.cc_CallContext.currUserId;
                review.ccrz__RatingCode__c = rating;
                reviews.add(review);
            }
    
            // create 2 reviews for target product with 'Accepted' status
            for (i=5; i < 7; i++) {
                ccrz__E_Review__c review = new ccrz__E_Review__c();
                review.ccrz__Product__c = product1.Id;
                review.ccrz__Status__c = 'Accepted';
                review.ccrz__Subject__c = subject + String.valueOf(i);
                review.ccrz__UserReview__c = reviewText + String.valueOf(i);
                review.ccrz__User__c = ccrz.cc_CallContext.currUserId;
                review.ccrz__RatingCode__c = rating;
                reviews.add(review);
            }
    
            // create 3 reviews for another product with 'New' status
            for (i=7; i < 10; i++) {
                ccrz__E_Review__c review = new ccrz__E_Review__c();
                review.ccrz__Product__c = product2.Id;
                review.ccrz__Status__c = 'New';
                review.ccrz__Subject__c = subject + String.valueOf(i);
                review.ccrz__UserReview__c = reviewText + String.valueOf(i);
                review.ccrz__User__c = ccrz.cc_CallContext.currUserId;
                review.ccrz__RatingCode__c = rating;
                reviews.add(review);
            }
    
            insert reviews;
        }
        
    }

    static testMethod void testCreate() {
        User u = [select id, Contact.Account.Id, ContactId, Contact.Account.Recordtype.Name from User where Profile.Name = 'Customer Community User' and isActive=true limit 1];
        system.assertEquals('Customer', u.Contact.Account.Recordtype.Name);
        system.runAs(u){
            String sku = 'testSKU1';
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = 'MarketPlace';
            ctx.portalUserId = ccrz.cc_CallContext.currUserId;
            String subject = 'Review subject';
            String reviewText = 'This is a test review';
            String rating = '5';
    
            List<ccrz__E_Review__c> newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            Integer numReviews = newReviews.size();
            System.debug('newReviews.size() ' + newReviews.size());
            System.assertEquals(8, numReviews);
            Test.setCurrentPageReference(new PageReference('Page.ccrz__HomePage')); 
            System.currentPageReference().getParameters().put('sku', 'testSKU1');
            MP_ReviewsCtrl ctrl = new MP_ReviewsCtrl();
            ccrz.cc_RemoteActionResult result = MP_ReviewsCtrl.saveReview(ctx,sku,subject,reviewText,rating);
            System.assert(result.success);
    
            newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            System.assertEquals(numReviews+1, newReviews.size());
        }
    }
    
    static testMethod void testCreate2() {
        User u = [select id, Contact.Account.Id, ContactId, Contact.Account.Recordtype.Name from User where Profile.Name = 'Partner Community User' and isActive=true limit 1];
        system.assertEquals('Partner', u.Contact.Account.Recordtype.Name);
        system.runAs(u){
            String sku = 'testSKU1';
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = 'MarketPlace';
            ctx.portalUserId = ccrz.cc_CallContext.currUserId;
            String subject = 'Review subject';
            String reviewText = 'This is a test review';
            String rating = '5';
    
            List<ccrz__E_Review__c> newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            Integer numReviews = newReviews.size();
            System.debug('newReviews.size() ' + newReviews.size());
            System.assertEquals(8, numReviews);
            
            MP_ReviewsCtrl ctrl = new MP_ReviewsCtrl();
            ccrz.cc_RemoteActionResult result = MP_ReviewsCtrl.saveReview(ctx,sku,subject,reviewText,rating);
            System.assert(result.success);
    
            newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            System.assertEquals(numReviews+1, newReviews.size());
        }
    }
    
    static testMethod void testCreate3() {
        User u = [select id, Contact.Account.Id, ContactId, Contact.Account.Recordtype.Name from User where Profile.Name = 'Partner Community User' and Contact.Account.Alliance_Type__c = 'PartnerConnect - Solution' and isActive=true limit 1];
        system.assertEquals('Partner', u.Contact.Account.Recordtype.Name);
        system.runAs(u){
            String sku = 'testSKU1';
            ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
            ctx.storefront = 'MarketPlace';
            ctx.portalUserId = ccrz.cc_CallContext.currUserId;
            String subject = 'Review subject';
            String reviewText = 'This is a test review';
            String rating = '5';
    
            List<ccrz__E_Review__c> newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            Integer numReviews = newReviews.size();
            System.debug('newReviews.size() ' + newReviews.size());
            System.assertEquals(8, numReviews);
            
            MP_ReviewsCtrl ctrl = new MP_ReviewsCtrl();
            ccrz.cc_RemoteActionResult result = MP_ReviewsCtrl.saveReview(ctx,sku,subject,reviewText,rating);
            System.assert(result.success);
    
            newReviews = [select id from ccrz__E_Review__c where ccrz__Status__c = 'New'];
            System.assertEquals(numReviews+1, newReviews.size());
        }
    }

    static testMethod void testFetch() {
        String sku = 'testSKU1';
        ccrz.cc_RemoteActionContext ctx = new ccrz.cc_RemoteActionContext();
        ctx.storefront = 'MarketPlace';
        ctx.portalUserId = ccrz.cc_CallContext.currUserId;
        List<ccrz__E_Review__c> updateReviews = new List<ccrz__E_Review__c>();
        for(ccrz__E_Review__c r : [select ccrz__Product__c,ccrz__Rating__c,ccrz__RatingCode__c,
                ccrz__ReviewDate__c,ccrz__ReviewId__c,ccrz__Status__c,ccrz__Subject__c,ccrz__User__c,
                ccrz__User__r.FirstName,ccrz__User__r.LastName,ccrz__UserReview__c from ccrz__E_Review__c
        where ccrz__Product__r.ccrz__SKU__c =:sku limit 2]){
            r.ccrz__Status__c = 'Accepted';
            updateReviews.add(r);
        }
        update updateReviews;
        List<ccrz__E_Review__c> reviews = [select ccrz__Product__c,ccrz__Rating__c,ccrz__RatingCode__c,
                ccrz__ReviewDate__c,ccrz__ReviewId__c,ccrz__Status__c,ccrz__Subject__c,ccrz__User__c,
                ccrz__User__r.FirstName,ccrz__User__r.LastName,ccrz__UserReview__c from ccrz__E_Review__c
        where ccrz__Status__c = 'Accepted' and ccrz__Product__r.ccrz__SKU__c =:sku];
        System.debug('reviewszzz ' + reviews);

        ccrz.cc_RemoteActionResult result = MP_ReviewsCtrl.fetchReviews(ctx,sku);
        System.assert(result.success);

        Map<String,Object> retData = (Map<String,Object>)result.data;
        System.assert(retData.containsKey(MP_ReviewsCtrl.REVIEW_LIST));

        List<MP_ReviewsCtrl.cc_bean_review> reviewBeanList = (List<MP_ReviewsCtrl.cc_bean_review>)retData.get(MP_ReviewsCtrl.REVIEW_LIST);
        System.debug('size of list: ' + reviewBeanList.size());
        System.assertEquals(2, reviewBeanList.size());
    }

}