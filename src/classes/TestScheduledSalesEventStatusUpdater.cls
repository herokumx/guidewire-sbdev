@isTest(SeeAllData=true)
private class TestScheduledSalesEventStatusUpdater {
    static testMethod void validateStatusUpdate()
    {
        //create an account and opportunity
        Opportunity o = new Opportunity(Name = 'Test Status Update Opportunity',
                                        StageName = 'Qualified',
                                        CloseDate = Date.today(),
                                        Premium_In_Scope__c = 1000,
                                        region__c = 'APAC',
                                        Amount=100   );
    
        insert o;        
        
        //create an event on it in the past
        Sales_Event__c event1 = new Sales_Event__c(Name = 'Test Status Update Event 1',
                                                  Event_Type__c = 'Demonstration',
                                                  Status__c = 'Confirmed',
                                                  Confirmed_Start_Date__c = Date.today().addDays(-3),
                                                  Confirmed_End_Date__c = Date.today().addDays(-2),
                                                  Opportunity__c = o.Id);

        



        //create an RFP event on it in the past
                                                 
        Sales_Event__c event2 = new Sales_Event__c(Name = 'Test Status Update Event 2',
                                                   Event_Type__c = 'RFI / RFP',
                                                  Status__c = 'Confirmed',
                                                  RFx_External_Due__c = Date.today().addDays(-3),
                                                  Opportunity__c = o.ID);
                                                  
        insert event1;
        insert event2;
        
        //need to add a user
        User aUser = [SELECT Id from User Limit 1];
        
        //add a person so the chatter post will be created
        Preparation__c prep1 = new Preparation__c(Name = 'Test Status Update Event 1 Prep 1',
                                                 Start__c = Date.today().addDays(-3),
                                                 End__c = Date.today().addDays(-2),
                                                 Hours__c = 4,
                                                 Sales_Event__c = event1.Id,
                                                 Who__c = aUser.Id
                                                );
        
        
        Project__c proj = new Project__c(Name='Test Project',
                                      Status__c='Active',
                                      Description__c='Description');
        
        insert proj;        
        
        Project_Event__c projEvent = new Project_Event__c(Name='Test Status Update Project Event 1 Prep 1',
                                              Status__c='Confirmed',
                                              Confirmed_Start_Date__c = Date.today().addDays(-160),
                                              Confirmed_End_Date__c = Date.today().addDays(-151),                                              
                                              Project__c = proj.Id);

        insert projEvent; 
      
        Project_Preparation__c projprep1 = new Project_Preparation__c(Name = 'Test Status Update Project Event 1 Prep 1',
                                                 Start__c = Date.today().addDays(-3),
                                                 End__c = Date.today().addDays(-2),
                                                 Hours__c = 4,
                                                 Project_Event__c = projEvent.Id,
                                                 Who__c = aUser.Id
                                                );
        insert projprep1;
        
        //run the asynchronous update
        Test.startTest();
        ScheduledSalesEventStatusUpdater.execute();
        Test.stopTest();
        
        //check to the status of the event
        
        
        Sales_Event__c event1_latest = [SELECT Status__c from Sales_Event__c where Name = 'Test Status Update Event 1' LIMIT 1];
        Sales_Event__c event2_latest = [SELECT Status__c from Sales_Event__c where Name = 'Test Status Update Event 2' LIMIT 1];
        Project_Event__c projectEvent1_latest = [SELECT Status__c from Project_Event__c where Name = 'Test Status Update Project Event 1 Prep 1' LIMIT 1];
        System.Debug('EVENT1 STATUS: ' + event1_latest.Status__c);
        System.assertEquals(event1_latest.Status__c, 'Completed');
        System.assertEquals(event2_latest.Status__c, 'Completed');
        System.assertEquals(projectEvent1_latest.Status__c, 'Completed');
        
  
    }
    
    
    static  testmethod void scheduletestmethod()
    {
       Test.startTest();
        
        String Cron_Exp='0 0 0 12 7 ? 2030';
        ScheduledSalesEventStatusUpdaterB obj=new ScheduledSalesEventStatusUpdaterB();
        system.schedule('test job', Cron_Exp,obj);
        Test.stopTest();
        
    }



}