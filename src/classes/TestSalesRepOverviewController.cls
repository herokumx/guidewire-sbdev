@isTest(seeAllData=true)
private class TestSalesRepOverviewController {

    static testMethod void validateController() {
        Opportunity o = new Opportunity(SWOT_Strengths__c='S Value',
                                        SWOT_Weaknesses__c='W Value',
                                        SWOT_Opportunities__c = 'O Value',
                                        SWOT_Threats__c = 'T Value',
                                        SWOT_Strategy_SO__c = 'SO Value',
                                        SWOT_Strategy_ST__c = 'ST Value',
                                        SWOT_Strategy_WO__c = 'WO Value',
                                        SWOT_Strategy_WT__c = 'WT Value',
                                        Name = 'Test SWOT Opportunity',
                                        StageName = 'Qualified',
                                        CloseDate = Date.today(),
                                        Premium_In_Scope__c = 1000,
                                        Amount=100   );
    
        insert o;
        
        
        //create an event for the current user
        
        // create aa request with the current user
        ResourceRequest__c req = new ResourceRequest__c(Opportunity__c = o.Id, Event_Hours__c = 5);
        insert req;
        
        
        
        
        
        FeedItem post = new FeedItem();
            post.ParentId = req.Id; 
            post.Body = 'This request has been opened.';
            insert post;
        
        req.FeedAnnouncementID__c = post.Id;
        upsert req;
        
        //now add a possible date to the requ
        Possible_Date__c pDate = new Possible_Date__c(Name='Possible Date Test 1',
                                                       Start_Date__c = Date.today().addDays(-3),
                                                       End_Date__c = Date.today().addDays(-2),
                                                       Event_Hours__c = 5,
                                                       Status__c = 'Possible',
                                                       Resource_Request__c = req.Id
                                                      );
        insert pDate;                                              
		        
        Resource_Role__c role = new Resource_Role__c(  Status__c='Required',
                                                       Resource_Request__c = req.Id
                                                      );                                             
                                                      
        insert role;
        
            
Opportunity o2 = new Opportunity(SWOT_Strengths__c='S Value',
                                        SWOT_Weaknesses__c='W Value',
                                        SWOT_Opportunities__c = 'O Value',
                                        SWOT_Threats__c = 'T Value',
                                        SWOT_Strategy_SO__c = 'SO Value',
                                        SWOT_Strategy_ST__c = 'ST Value',
                                        SWOT_Strategy_WO__c = 'WO Value',
                                        SWOT_Strategy_WT__c = 'WT Value',
                                        Name = 'Test SWOT Opportunity',
                                        StageName = 'Qualified',
                                        CloseDate = Date.today(),
                                        Premium_In_Scope__c = 1000,
                                        Amount=100   );
        insert o2;
        
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o2.Id, Status__c = 'Tentative');
        insert event;
        
        Event_Possible_Date__c pDate2 = new Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Sales_Event__c = event.Id,
                                              Event_Hours__c = 5,
                                              Start_Date__c = Date.today().addDays(-3),
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert pDate2 ;
        
         Customer_Commitment__c commitment = new Customer_Commitment__c(Name = 'Customer Commitment Test 1',
                                                                       Sales_Event__c = event.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert commitment;        
        
        Preparation__c prep = new Preparation__c(Name = 'Prep test 1',
                                              Sales_Event__c = event.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today(),
                                              End__c = Date.today(),
                                              Hours__c = 4
                                              );
        
        insert prep;        

        // Now let's test        
        
        
        SalesRepOverviewController theController = new SalesRepOverviewController();
        theController.viewForUser.Who__c = UserInfo.getUserId();
        theController.reloadPage();
        theController.getFilteredOpportunityList();
        theController.getPageBlockTitle();
       
    }
}