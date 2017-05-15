@isTest
private class StorySearch_NewTest {
    
    private static testmethod void testSearch() {
    
    //  Insert some accounts
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
        Customer_Story_Account__c ca1 = new Customer_Story_Account__c(customer_story__c = c1.id, account__c = a1.id);
        csa.add( ca1);
        Customer_Story_Account__c ca2 = new Customer_Story_Account__c(customer_story__c = c2.id, account__c = a2.id);
        csa.add( ca2);
        Customer_Story_Account__c ca3 = new Customer_Story_Account__c(customer_story__c = c3.id, account__c = a3.id);
        csa.add( ca3);
        Customer_Story_Account__c ca4 = new Customer_Story_Account__c(customer_story__c = c4.id, account__c = a4.id);
        csa.add( ca4);
        // also link c4 to a1
        Customer_Story_Account__c ca5 = new Customer_Story_Account__c(customer_story__c = c4.id, account__c = a1.id);
        csa.add( ca5);
        insert csa;
        
    //  Set SOSL search results so that we have results coming back - test methods will always return blank for SOSL queries        
        List<Id> fixedSearchResults = new List<Id>{};
        for(Customer_Story_Account__c s : csa)fixedSearchResults.add(s.id);         
        Test.setFixedSearchResults(fixedSearchResults);         
            
    //  Controller
        StorySearch_NewController d = new StorySearch_NewController();              
        
    //  Set the default search type & scope     
        d.SelectSearchType();
    //  get filters
        d.getFilters();

    //  Search Stories    
        d.keyword = 'test1';
        d.searchType = 'story';
        d.doSearch();
        // should have 2 returned in results list - SOSL testing is tricky and can't seem to get back right results
       

    //  Query Stories    
        d.keyword = null;
        d.searchType = 'story';
        // add account filter for region = APAC
        d.getFilters()[0].selectedField = 'Account:Region';
        d.currentFilterId = 0;
        d.SelectFilterType();
        // operators should be Includes only
        system.debug('filter: ' +d.getFilters()[0]);
        system.assertequals(d.getFilters()[0].filterOperators.size(), 2);
        d.getFilters()[0].selectedoperator = 'INCLUDES';
        d.getFilters()[0].selectedPickvals = new list<string>{'APAC'};
        d.doSearch();
        // should have found accounts 1 and 2 linked to stories 1, 2 and 4
        system.assertequals(d.results.size(), 2);
        system.assertequals(d.totalStoryLinks, 3);
        system.assertequals(d.totalStories, 3);
        // first results entry is a1 based on sort by name, should have 2 stories
        system.assertequals(d.results[0].storiesCount ,2);
        
    //  Query Products
        d.searchType = 'info';
        // add filter for products here
        d.SelectSearchType();
        // add product filter for product deal close date = today
        d.getFilters()[0].selectedField = 'Product:Product Deal Close Date';
        d.currentFilterId = 0;
        d.SelectFilterType();
        d.getFilters()[0].selectedoperator = '>=';
        d.getFilters()[0].searchString = '01/01/2010';
        d.doSearch();
        // should have found account 1 with product 1
        system.assertequals(d.results.size(), 1);

    //  add a filter
        d.AddFilter();
        
    //  remove a filter
        d.currentFilterID = 0;
        d.removeFilter();

    //  Select a filter
        d.currentFilter = d.idTOfilter.get(0);
        d.currentFilter.selectedField = d.currentFilter.filterFields[0].getValue();
        d.SelectFilterType();
    
    //  Clear filters so search will work
        d.ClearFilters();
        d.getFilters();
        
    //  search stories      
        d.searchType = 'story';     
        d.doSearch();
    
    //  search infos
        d.searchType = 'info';      
        d.doSearch();

        
    
   }


}