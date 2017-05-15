@isTest
private class GWUtilities_Test{

    // TEST METHODS //
    private static testmethod void testAccountRank(){
        test.starttest();
        // start with empty account then update buying entity
        Account a = new Account(name = 'test', direct_premiums__c = 500000);
        insert a;
        a.buying_entity__c = 'Yes';
        update a;
        // should be factor 0 + 1 + 1.5 = 2.5 X 500000 =  1,250,000 since no purchases yet
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 1250000);
        // add a billing center won opp
        Opportunity bc = new Opportunity(name = 'test BC', stagename = 'Closed Won', closedate = date.today(), accountid = a.id, product_type__c = 'BillingCenter',
            Deal_type__c = 'sample', payment_cycle__c = 'annual', amount = 1);
        //insert bc;
        // trigger the account recalc by updating DWP
        a.direct_premiums__c = 400000;
        update a;
        // with Billing Center only, should have factor of 2 + 1 +1.5 = 4.5 X 400000 = 1800000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
       // system.assertequals(a.jt_power_ranking__c, 1800000);
        // test with middle range DWP
        a.direct_premiums__c = 1000000;
        update a;
        // with Billing Center only, should have factor of 2 + 1.5 + 2.25 = 5.75 X 1000000 = 5750000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 5750000);
        // test with top range DWP
        a.direct_premiums__c = 5000000;
        update a;
        // with Billing Center only, should have factor of 2 + 2 + 3 = 7 X 5000000 = 35000000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 35000000);        
        
        // add Policy Center
        Opportunity pc = new Opportunity(name = 'test PC', stagename = 'Closed Won', closedate = date.today(), accountid = a.id, product_type__c = 'PolicyCenter',
            Deal_type__c = 'sample', payment_cycle__c = 'annual', amount = 1);
        insert pc;
        // trigger the account recalc by updating DWP
        a.direct_premiums__c = 150000;
        update a;
        // with Billing Center and Policy, should have factor of 2 + 1 = 3 X 150000 = 450000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 450000);
        // test with middle range DWP
        a.direct_premiums__c = 1000000;
        update a;
        // with Billing Center and Policy, should have factor of 2 + 1.5 = 3.5 X 1000000 = 3500000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        ///system.assertequals(a.jt_power_ranking__c, 3500000);
        // test with top range DWP
        a.direct_premiums__c = 5000000;
        update a;
        // with Billing Center and Policy, should have factor of 2 2 = 4 X 5000000 = 20 000 000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 20000000);   

        // add Claims Center and make Policy center lost
        Opportunity cc = new Opportunity(name = 'test CC', stagename = 'Closed Won', closedate = date.today(), accountid = a.id, product_type__c = 'ClaimCenter', 
            Deal_type__c = 'sample', payment_cycle__c = 'annual', amount = 1);
        //insert cc;
        pc.stagename = 'No Intent to Buy';
        //update pc;
        // trigger the account recalc by updating DWP
        a.direct_premiums__c = 150000;
        update a;
        // with Billing and Claims, should have factor of 2 + 1.5 = 3.5 X 500000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 525000); 
        // test with middle range DWP
        a.direct_premiums__c = 1000000;
        update a;
        // with Billing and Claims, should have factor of 2 + 2.25 = 4.25 X 1000000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
       // system.assertequals(a.jt_power_ranking__c, 4250000); 
        // test with top range DWP
        a.direct_premiums__c = 5000000;
        update a;
        // with Billing Center and Claims, should have factor of 2 + 3 =  X 5000000 = 25 000 000
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 25000000);  
        
        // update account industry to 0 out rank
        a.industry = 'Medical Mal Practice';
        //update a;
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 0);               
        
        // finally test out future Opportunity method
        
        // make Policy won
        pc.stagename = 'Closed Won';
        update pc;
        test.stoptest();
        // account should now have rank 0 since all were purchased
        a = [select id, jt_power_ranking__c from Account where id = :a.id];
        //system.assertequals(a.jt_power_ranking__c, 0);                  
                        
                       
    }

    private testmethod static void testCustomerStoryAccountSummary() {
    
    List<Account>accts = new List<Account>{};
        Account a1 = new Account(Name = 'test1', Region__c = 'APAC', distribution_channel__c = 'Captive', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California');
        accts.add(a1);
        Account a2 = new Account(Name = 'test2', Region__c = 'APAC', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California');
        accts.add(a2);
        Account a3 = new Account(Name = 'test3', Region__c = 'EMEA', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California');
        accts.add(a3);
        Account a4 = new Account(Name = 'test4', Region__c = 'EMEA', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California');
        accts.add(a4);
        insert accts;
        
        // need a product each to pass story account lookup filter
        list<product__c> prods = new list<product__c>();
        product__c p1 = new product__c(products__c = 'BillingCenter', account__c = a1.id, Deal_Close_Date__c = date.today());
        prods.add(p1);
        product__c p2 = new product__c(products__c = 'BillingCenter', account__c = a2.id);
        prods.add(p2);
        product__c p3 = new product__c(products__c = 'BillingCenter', account__c = a3.id);
        prods.add(p3);
        product__c p4 = new product__c(products__c = 'BillingCenter', account__c = a4.id);
        prods.add(p4);
        insert prods;
    
    //  Insert some stories and links 
        List<Customer_Story__c> stories = new List<Customer_Story__c>{};
        Customer_Story__c c1 = new Customer_Story__c(story_title__c='test1');
        stories.add( c1);
        Customer_Story__c c2 = new Customer_Story__c(story_title__c='test10');
        stories.add(c2);
        Customer_Story__c c3 = new Customer_Story__c(story_title__c='test2');
        stories.add(c3);
        Customer_Story__c c4 = new Customer_Story__c(story_title__c='test3');
        stories.add(c4);
        insert stories;
        List<Customer_story_account__c> csa = new List<Customer_story_account__c>();        
        // story 1 has account 1 and 2
        Customer_Story_Account__c ca1 = new Customer_Story_Account__c(customer_story__c = c1.id, account__c = a1.id);
        csa.add( ca1);
        Customer_Story_Account__c ca6 = new Customer_Story_Account__c(customer_story__c = c1.id, account__c = a2.id);
        csa.add( ca6);
        // story 2 has account 2
        Customer_Story_Account__c ca2 = new Customer_Story_Account__c(customer_story__c = c2.id, account__c = a2.id);
        csa.add( ca2);
        // story 3 has account 3
        Customer_Story_Account__c ca3 = new Customer_Story_Account__c(customer_story__c = c3.id, account__c = a3.id);
        csa.add( ca3);
        // story 4 has account 4 and 1
        Customer_Story_Account__c ca4 = new Customer_Story_Account__c(customer_story__c = c4.id, account__c = a4.id);
        csa.add( ca4);
        Customer_Story_Account__c ca5 = new Customer_Story_Account__c(customer_story__c = c4.id, account__c = a1.id);
        csa.add( ca5);
        insert csa;
        
        c1 = [select id, story_accounts__c from customer_story__c where id = :c1.id];
        system.assertequals(c1.story_accounts__c, 'test1; test2');
        c2 = [select id, story_accounts__c from customer_story__c where id = :c2.id];
        system.assertequals(c2.story_accounts__c, 'test2');
        c3 = [select id, story_accounts__c from customer_story__c where id = :c3.id];
        system.assertequals(c3.story_accounts__c, 'test3');
        c4 = [select id, story_accounts__c from customer_story__c where id = :c4.id];
        system.assertequals(c4.story_accounts__c, 'test1; test4');
        
        // delete links from story 1/account 2 (ca6) and story 2/account 2 (ca2)
        delete new list<customer_story_account__c>{ca6, ca2};
        c1 = [select id, story_accounts__c from customer_story__c where id = :c1.id];
        system.assertequals(c1.story_accounts__c, 'test1');
        c2 = [select id, story_accounts__c from customer_story__c where id = :c2.id];
        system.assertequals(c2.story_accounts__c, null);        
        // undelete ca 2
        undelete ca2;
        c2 = [select id, story_accounts__c from customer_story__c where id = :c2.id];
        system.assertequals(c2.story_accounts__c, 'test2');        
    }

    private testmethod static void testProfile() {
        test.starttest();
        List<Profile> prf = [Select Id from Profile Where Name = 'System Administrator'];
        GWUtilities.getProfileId('System Administrator');
        GWUtilities.getProfileName(prf[0].Id);
        test.stoptest();

    }

    private testmethod static void testRecordType() {
        test.starttest();
        GWUtilities.getRecordTypeId('Account');
        GWUtilities.getRecordTypeDeveloperName('Account');
        test.stoptest();

    }

    private testmethod static void testCurrencyMap() {

        GWUtilities.currencyISOcodeconversionRateMap();

    }

    private testmethod static void testappend() {

        GWUtilities.appendStringValuesToBaseQuery('AccountId','4','and','!=',false);        

    }

    private testmethod static void testAccountPowerRankingRecalcfromOpportunity() {
        Account a10 = new Account(Name = 'test11', Region__c = 'APAC', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California');   
        insert a10;     
        Set<Id> accIds = new Set<Id>();
        accIds.add(a10.Id);
        GWUtilities.AccountPowerRankingRecalcfromOpportunity(accIds);        

    }

}