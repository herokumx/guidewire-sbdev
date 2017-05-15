@isTest
private class StorySearchController_TEST {
    
    @isTest static void testSearch() {
    
    //  Insert some accounts
        Integer iSize = 20;
        List<Account>accts = new List<Account>{};
        for(Integer i = 0; i<iSize; i++){
            Accts.add(new Account(Name = 'test', BillingStreet='test', BillingCountry='United States',BillingCity='test',BillingState='California'));
        }
        insert accts;   
    
    //  Insert some cust info & stories 
        List<Customer_Information__c> infos = new List<Customer_Information__c>{};
        List<Customer_Story__c> stories = new List<Customer_Story__c>{};
        for(Account a : accts){         
            infos.add( new Customer_Information__c(Account__c = a.id));
            stories.add( new Customer_Story__c(story_title__c='test'));         
        }
        insert infos;
        insert stories;             
        
    //  Set search results          
        List<Id> fixedSearchResults = new List<Id>{};
        for(Customer_Story__c s : stories)fixedSearchResults.add(s.id);         
        Test.setFixedSearchResults(fixedSearchResults);         
            
    //  Controller
        SearchStoryController d = new SearchStoryController();              
        
    //  Set the default search type & scope     
        d.SelectSearchType();
        d.setDefaultFilters();
        
    //  get filters
        d.getFilters();

    //  Search Stories    
        d.keyword = 'test';
        d.searchType = 'story';
        d.FindResults();

    //  Query Stories    
        d.keyword = null;
        d.searchType = 'story';
        d.doSearch();
                
    //  Query Infos
        d.searchType = 'info';
        d.doSearch();

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
        
    //  get ids for sub searches            
        d.ProductCustomerInfoIDs();
        d.StoryCustomerInfoIDs();
        
    
   }


}