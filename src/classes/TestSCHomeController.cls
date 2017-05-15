@isTest(seeAllData=true)
private class TestSCHomeController {

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

        
        //create a personal event as well
        Personal_Event__c pevent = new Personal_Event__c(Name = 'Personal Event Test 1',
                                                         Start__c = Date.today().addDays(3),
                                                         End__c = Date.today().addDays(4),
                                                         Status__c = 'Confirmed',
                                                         User__c = UserInfo.getUserId());
        insert pevent;
        
        
        Personal_Event__c pevent2 = new Personal_Event__c(Name = 'Personal Event Test 2',
                                                         Start__c = Date.today().addDays(-4),
                                                         End__c = Date.today().addDays(-3),
                                                         Status__c = 'Completed',
                                                         User__c = UserInfo.getUserId());
        insert pevent2;
        
        
        
        
        
        
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
                                                       Resource_Request__c = req.Id
                                                      );
                                                      
        Resource_Role__c role = new Resource_Role__c(  Status__c='Required',
                                                       Resource_Request__c = req.Id
                                                      );                                             
                                                      
        insert role;
        
        
        //add a project and associated event
        
        Project__c proj = new Project__c(Name='Test Project',
                                      Status__c='Active',
                                      Description__c='Description');
        
        insert proj;        
        
        Project_Event__c projEvent = new Project_Event__c(Name='Test Project',
                                              Status__c='Tentative',
                                              Project__c = proj.Id);
        
        insert projEvent;
                                              
        

        // Now let's test        
        SCHomeController  theController = new SCHomeController();
        
        
        theController.getMySalesEventsList();
        theController.getTeamSalesEventsList();

        theController.getMyOpenPersonalEventsList();
        theController.getMyRecentPersonalEventsList();
        theController.getTeamSalesRequestsList();
        theController.getPendingSalesRequestsList();
        theController.getMySalesRequestsList();

        theController.getMyActiveProjectsList();
        theController.getMyActiveProjectEventsList();
        
		theController.getMyOpenSupportRequestsList();
		theController.getOpenSupportRequestsList(); 
        theController.getIsPresalesManager();
        
    }
}