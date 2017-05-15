@isTest(seeAllData=true)
private class TestStaffingCalendarEntryWrapper {

    static testMethod void validateWrapper() {
        //create an opportunity
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
        
        
        //create a request
        ResourceRequest__c req = new ResourceRequest__c(Opportunity__c = o.Id, Event_Type__c = 'Demonstration', Event_Hours__c = 5);
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
                                                       Resource_Request__c = req.Id,
                                                       Status__c = 'Possible'
                                                      );
                                                      
        insert pDate;        
        
        
        
        ResourceRequest__c req2 = new ResourceRequest__c(Opportunity__c = o.Id, Event_Type__c = 'RFI / RFP', RFx_Internal_Due__c = Date.today().addDays(13), Event_Hours__c = 5);
        insert req2;
        
        post = new FeedItem();
            post.ParentId = req2.Id; 
            post.Body = 'This request has been opened.';
            insert post;
        
        req2.FeedAnnouncementID__c = post.Id;
        upsert req2;
                
        
        //create an event
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o.Id);
        insert event;
        
        Event_Possible_Date__c pDate3 = new Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Sales_Event__c = event.Id,
                                              Start_Date__c = Date.today().addDays(-6),
                                              End_Date__c = Date.today().addDays(-5),
                                              Event_Hours__c = 5,
                                              Status__c = 'Selected'
                                              );
        
        insert pDate3 ;        

        Sales_Event__c event2 = new Sales_Event__c(Opportunity__c = o.Id, Status__c='Completed', Confirmed_Start_Date__c = Date.today().addDays(-40),Confirmed_End_Date__c = Date.today().addDays(-39) );
        insert event2;
        
        //let's add a project
        Project__c proj = new Project__c(Name='Test Project',
                                      Status__c='Active',
                                      Description__c='Description');
        
        insert proj;        
        
        Project_Event__c projEvent = new Project_Event__c(Name='Test Project',
                                              Status__c='Confirmed',
                                              Confirmed_Start_Date__c = Date.today().addDays(160),
                                              Confirmed_End_Date__c = Date.today().addDays(161),                                              
                                              Project__c = proj.Id);
        
        insert projEvent;
        
        //add each to a wrappers, add to list, and sort
        List<StaffingCalendarEntryWrapper> items = new List<StaffingCalendarEntryWrapper>();
        items.add(new StaffingCalendarEntryWrapper([SELECT ID,  Status__c, Confirmed_Start_Date__c, Confirmed_End_Date__c, (SELECT Start_Date__c , Status__c FROM Possible_Dates__r) FROM Project_Event__c where Id = :projEvent.Id LIMIT 1]));
        items.add(new StaffingCalendarEntryWrapper([SELECT ID, Event_Type__c, RFx_Internal_Due__c, (SELECT Start_Date__c , Status__c FROM Possible_Dates__r) FROM ResourceRequest__c where Id = :req.Id LIMIT 1]));
        items.add(new StaffingCalendarEntryWrapper([SELECT ID, Event_Type__c, RFx_Internal_Due__c, (SELECT Start_Date__c , Status__c FROM Possible_Dates__r) FROM ResourceRequest__c where Id = :req2.Id LIMIT 1]));
        items.add(new StaffingCalendarEntryWrapper([SELECT ID,  Status__c, Event_Type__c, RFx_Internal_Due__c, Confirmed_Start_Date__c, Confirmed_End_Date__c, (SELECT Start_Date__c , Status__c FROM Possible_Dates__r) FROM Sales_Event__c where Id = :event.Id LIMIT 1]));
        items.add(new StaffingCalendarEntryWrapper([SELECT ID,  Status__c, Event_Type__c, RFx_Internal_Due__c, Confirmed_Start_Date__c, Confirmed_End_Date__c, (SELECT Start_Date__c , Status__c FROM Possible_Dates__r) FROM Sales_Event__c where Id = :event2.Id LIMIT 1]));
        
        items.sort();
        
        System.assertEquals(items.get(0).event.Id, event2.Id);
        System.assertEquals(items.get(1).event.Id, event.Id);
        System.assertEquals(items.get(2).request.Id, req.Id);
        System.assertEquals(items.get(3).request.Id, req2.Id);
        System.assertEquals(items.get(4).projectEvent.Id, projEvent.Id);
        
        
        
       
    }
}