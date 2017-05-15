@isTest(seeAllData=true)
public class TestPresalesMetricsController2{

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
        
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o.Id, 
                                                  Status__c = 'Confirmed', 
                                                  Confirmed_Start_Date__c = Date.today().addDays(-4),
                                                  Confirmed_End_Date__c = Date.today().addDays(-2) );
        insert event;
        
        
        Event_Possible_Date__c pDate = new Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Sales_Event__c = event.Id,
                                              Start_Date__c = Date.today().addDays(-3),
                                              Event_Hours__c = 5,
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert pDate ;
        Event_Possible_Date__c pDate2 = new Event_Possible_Date__c (Name = 'Possible date test 2',
                                              Status__c = 'Selected',
                                              Sales_Event__c = event.Id,
                                              Start_Date__c = Date.today().addDays(-5),
                                              Event_Hours__c = 5,
                                              End_Date__c = Date.today().addDays(-4)
                                              );
        
        insert pDate2 ;
        
         Customer_Commitment__c commitment = new Customer_Commitment__c(Name = 'Customer Commitment Test 1',
                                                                       Sales_Event__c = event.Id,
                                                                       Who__c = UserInfo.getUserId(),
                                                                       Coverage_Area__c = 'ClaimCenter,Technical'
                                                                      );
                                                                      
        insert commitment;        
        
        Preparation__c prep = new Preparation__c(Name = 'Prep test 1',
                                              Sales_Event__c = event.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(-8),
                                              End__c = Date.today().addDays(-4)
                                              );
        
        insert prep;      
        
        Sales_Event__c eventRFP = new Sales_Event__c(Opportunity__c = o.Id, 
                                                  Status__c = 'Confirmed', 
                                                  Name = 'Test Event',
                                                  Event_Type__c = 'RFI / RFP',
                                                  RFx_Internal_Due__c = Date.today().addDays(4),
                                                  RFx_External_Due__c = Date.today().addDays(6) );
        insert eventRFP;
        
         Customer_Commitment__c commitmentRFP = new Customer_Commitment__c(Name = 'Customer Commitment Test 1',
                                                                       Sales_Event__c = eventRFP.Id,
                                                                       Who__c = UserInfo.getUserId(),
                                                                       Coverage_Area__c = 'ClaimCenter,Technical'
                                                                      );
                                                                      
        insert commitmentRFP;        
        

        Preparation__c prepRFP = new Preparation__c(Name = 'Prep test 1',
                                              Sales_Event__c = eventRFP.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(-8),
                                              End__c = Date.today().addDays(-4)
                                              );
        
        insert prepRFP;      
        
        
        
        ResourceRequest__c req = new ResourceRequest__c(Opportunity__c = o.Id,
                                                        Name = 'Request Test 1',
                                                        Status__c = 'Open', 
                                                        Event_Hours__c = 5,
                                                        Presentation_Type__c = 'Demonstration',
                                                        Location__c = 'Austin, TX',
                                                        Description__c = 'Request Test 1 Description'
                                                        );
        insert req;
                
        //now add a possible date to the request
        Resource_Role__c role = new Resource_Role__c(  Status__c='Required',
                                                       Resource_Request__c = req.Id,
                                                       Role__c = 'ClaimCenter'
                                                      );                                             
                                                      
        insert role;


        //add a few possible dates
        Possible_Date__c pDate3 = new Possible_Date__c(Name='Possible Date Test 1',
                                                       Start_Date__c = Date.today().addDays(6),
                                                       End_Date__c = Date.today().addDays(8),
                                                       Event_Hours__c = 5,
                                                       Resource_Request__c = req.Id
                                                      );
        insert pDate3;        

        Possible_Date__c pDate4 = new Possible_Date__c(Name='Possible Date Test 2',
                                                       Start_Date__c = Date.today().addDays(7),
                                                       End_Date__c = Date.today().addDays(9),
                                                       Event_Hours__c = 5,
                                                       Resource_Request__c = req.Id
                                                      );
        insert pDate4;
                        
        // TEST RFP Request  
        ResourceRequest__c reqRFP = new ResourceRequest__c(Opportunity__c = o.Id,
                                                        Name = 'Request Test 2',
                                                        Status__c = 'Open', 
                                                        Event_Hours__c = 5,
                                                        Presentation_Type__c = 'RFI / RFP',
                                                        Location__c = 'Austin, TX',
                                                        Description__c = 'Request Test 1 Description',
                                                        RFx_Internal_Due__c = Date.today().addDays(15)
                                                        );
        insert reqRFP;
        
        Resource_Role__c roleRFP = new Resource_Role__c(  Status__c='Required',
                                                       Resource_Request__c = reqRFP.Id,
                                                       Role__c = 'ClaimCenter'
                                                      );                                             
                                                      
        insert roleRFP;
        Possible_Date__c pDateRFP = new Possible_Date__c(Name='Possible Date Test 1',
                                                       Start_Date__c = Date.today().addDays(6),
                                                       End_Date__c = Date.today().addDays(8),
                                                       Event_Hours__c = 5,
                                                       Resource_Request__c = reqRFP.Id
                                                      );
        insert pDateRFP;        
        
        // TEST a project or two
        
        Project__c proj = new Project__c(Name='Test Project',
                                      Status__c='Active',
                                      Description__c='Description');
        
        insert proj;        
        
        Project_Event__c projEvent = new Project_Event__c(Name='Test Project',
                                              Status__c='Tentative',
                                              Project__c = proj.Id);
        
        insert projEvent;
        
        Project_Event__c projEvent2 = new Project_Event__c(Name='Test Project 2',
                                              Status__c='Confirmed',
                                              Confirmed_Start_Date__c =  Date.today().addDays(5),
                                              Confirmed_End_Date__c =  Date.today().addDays(7),
                                              Project__c = proj.Id);
        
        insert projEvent2;
        
        Project_Event_Possible_Date__c ppDate = new Project_Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Project_Event__c = projEvent.Id,
                                              Event_Hours__c = 5,
                                              Start_Date__c = Date.today().addDays(-3),
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert ppDate ;
        
         Project_Participant__c participant = new Project_Participant__c(Name = 'Customer Commitment Test 1',
                                                                       Project_Event__c = projEvent.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert participant ;      

         Project_Participant__c participant2 = new Project_Participant__c(Name = 'Customer Commitment Test 1',
                                                                       Project_Event__c = projEvent2.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert participant2 ;      

        
         Project_Date_Range__c partDateRange = new Project_Date_Range__c(Start__c = Date.today().addDays(3), 
                                                                         End__c = Date.today().addDays(4),
                                                                         Note__c = 'note',
                                                                         Project_Participant__c = participant.Id);
                                                                         
       insert partDateRange;
        
        Project_Preparation__c pprep = new Project_Preparation__c(Name = 'Prep test 1',
                                              Project_Event__c = projEvent.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(3),
                                              End__c = Date.today().addDays(4),
                                              Hours__c = 4
                                              
                                              );
        
        insert pprep;        
        
        Project_Preparation__c pprep2 = new Project_Preparation__c(Name = 'Prep test 1',
                                              Project_Event__c = projEvent2.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(3),
                                              End__c = Date.today().addDays(4),
                                              Hours__c = 4
                                              
                                              );
        
        insert pprep2;        
        
        Sales_Support_Request__c ssreq = new Sales_Support_Request__c(Opportunity__c = o.Id,
                                                        Status__c = 'Not Started', 
                                                        Type__c = 'Dossier',
                                Target_Completion_Date__c = Date.today().addDays(4)
                                );
        
        insert ssreq;
          
        
        //static getStaffingXML String region, String startDateAsText)
          PresalesMetricsController2 theExistingController = new PresalesMetricsController2();
   }
    
}