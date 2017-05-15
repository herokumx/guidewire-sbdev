public with sharing class SalesRepOverviewController {

    public Map<Id,Sales_Event__c> salesEventMap {get; set;} 
    public Map<Id,String> tentativeDateMapStarts {get; set;} 
    public Map<Id,String> tentativeDateMapEnds {get; set;} 
    public Map<Id,String> tentativeDateMapDurations {get; set;} 

    public Map<Id,ResourceRequest__c> resourceRequestMap {get; set;} 
    public Map<Id,String> requestDateMapStarts {get; set;} 
    public Map<Id,String> requestDateMapEnds {get; set;} 
    public Map<Id,String> requestDateMapDurations {get; set;} 
    
    

  public Preparation__c viewForUser {get;set;}
  public Boolean showOnlyActiveOpps {get;set;}
  public Boolean showOnlyActiveEvents {get;set;}

  public Boolean showOpenResourceRequests {get;set;}
  public Boolean showOpenSupportRequests {get;set;}

  public SalesRepOverviewController()
  {
      viewForUser = new Preparation__c();
      //temporary
      User currentUser = [SELECT Id, Name from User where Id = :UserInfo.getUserId() LIMIT 1];
      viewForUser.Who__c = currentUser.Id;
      
      showOnlyActiveOpps = false;
      showOnlyActiveEvents = true;
      showOpenResourceRequests = true;
      showOpenSupportRequests = true;
            
      reloadPage();
  }
  
    public void reloadPage()
    {
        if(viewForUser.Who__c != null)
        {
            User userWithName = [Select Id, Name from User where Id = :viewForUser.Who__c LIMIT 1];
            viewForUser.Who__r = userWithName;
        }
        
        salesEventMap = new Map<Id,Sales_Event__c>();
        tentativeDateMapStarts = new Map<Id,String> ();
        tentativeDateMapEnds = new Map<Id,String> ();
        tentativeDateMapDurations = new Map<Id,String> ();
    
        resourceRequestMap = new Map<Id,ResourceRequest__c>();
        requestDateMapStarts = new Map<Id,String> ();
        requestDateMapEnds = new Map<Id,String> ();
        requestDateMapDurations = new Map<Id,String> ();

    }  

  public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
  }


    public String getPageBlockTitle() {
        if(viewForUser != null && viewForUser.Who__c != null)
        {
            return viewForUser.Who__r.Name + '\'s Opportunities and Events';
        }
        return 'Please specify an individual above.';
    }
      
      
    public List<Opportunity> getFilteredOpportunityList() {
        if(viewForUser.Who__c != null)
        {  
            List<String> openOpps = new List<String>{'Lead','Qualified','Evaluating','Red Flag', 'Finalist','Selected','Final Approvals'};    
                
            Opportunity[] listOfOpps = new List<Opportunity>();    
                
            if(showOnlyActiveEvents)
            {
                listOfOpps =  [Select Id, Name, Amount, StageName, CloseDate, Sales_Event_Count__c, Sales_Event_Total_Hours__c,Sales_Event_Total_Cust_Hours__c, Sales_Event_Total_Prep_Hours__c, SWOT_Strengths__c,
                        (SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, 
                                Event_Type__c, List_Of_People__c, LastModifiedDate, Event_Hours__c, Customer_Hours__c, Preparation_Hours__c, Stage__c 
                           from Sales_Events__r
                           WHERE (Status__c != 'Completed' AND Status__c != 'Canceled')
                           ORDER BY Status__c, Confirmed_Start_Date__c DESC ),
                        (SELECT Id, Name, Description__c, RolesAsString__c, Event_Type__c, Status__c, LastModifiedDate
                           from Resource_Requests__r
                           WHERE (Status__c = 'Pending' OR Status__C = 'Open' OR Status__C = 'Fully Staffed')),
                        (SELECT Id,Type__c, Description__c, Status__c, Assigned_To__c, Hours__c, Requested_Completion_Date__c, Target_Completion_Date__c, LastModifiedDate
                           from Sales_Support_Requests__r
                           WHERE (Status__c = 'Not Started' OR Status__C = 'In Progress'))
                           
                                                                        
                        from Opportunity 
                        where OwnerId = :viewForUser.Who__c
                          and StageName in :openOpps
                        Order By CloseDate];        
                
            }    
            else
            {
                 listOfOpps =  [Select Id, Name, Amount, StageName, CloseDate, Sales_Event_Count__c, Sales_Event_Total_Hours__c, Sales_Event_Total_Cust_Hours__c, Sales_Event_Total_Prep_Hours__c, SWOT_Strengths__c,
                        (SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, 
                                Event_Type__c, List_Of_People__c, LastModifiedDate, Event_Hours__c, Customer_Hours__c, Preparation_Hours__c, Stage__c 
                           from Sales_Events__r
                           ORDER BY Status__c, Confirmed_Start_Date__c DESC ),
                        (SELECT Id, Name, Description__c, RolesAsString__c, Event_Type__c, Status__c, LastModifiedDate
                           from Resource_Requests__r
                           WHERE (Status__c = 'Pending' OR Status__C = 'Open' OR Status__C = 'Fully Staffed')),
                        (SELECT Id,Type__c, Description__c, Status__c, Assigned_To__c, Hours__c, Requested_Completion_Date__c, Target_Completion_Date__c, LastModifiedDate
                           from Sales_Support_Requests__r
                           WHERE (Status__c = 'Not Started' OR Status__C = 'In Progress'))
                        from Opportunity 
                        where OwnerId = :viewForUser.Who__c
                          and StageName in :openOpps
                        Order By CloseDate];        
                
            }
                
                            
            //build the event map from the above opps

        List<Opportunity> toReturn = new List<Opportunity>();
        List<Id> relevantEventIDs = new List<Id>();
        List<Id> relevantRequestIDs = new List<Id>();
        
//        if(possibleDates.size() > 0)
//        {
            for(Opportunity opp : listOfOpps)
            {
                //first add to list of opportunities if needed
                if(!showOnlyActiveOpps || opp.Sales_Events__r.size() > 0 || opp.Resource_Requests__r.size() > 0 || opp.Sales_Support_Requests__r.size() > 0)
                {
                    toReturn.add(opp);
                }
            
                for(Sales_Event__c sevent : opp.Sales_Events__r)
                {
                    relevantEventIDs.add(sevent.Id);
                
                }        

                for(ResourceRequest__c rrequest : opp.Resource_Requests__r)
                {
                    relevantRequestIDs.add(rrequest.Id);
                
                }        

            
            }
            
//        }               
        
          //build maps of dates for sales events
            Sales_Event__c[] sevents = 
                        [SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, 
                            Event_Type__c, List_Of_People__c, LastModifiedDate, Event_Hours__c, Customer_Hours__c, Preparation_Hours__c, Stage__c,
                            (SELECT Id, Start_Date__c, End_Date__c, Status__c, Event_Hours__c from Possible_Dates__r
                             WHERE Status__c = 'Possible')
                         from Sales_Event__c
                         WHERE Id in :relevantEventIDs
                         ORDER BY Status__c, Confirmed_Start_Date__c DESC ];
                                
            for(Sales_Event__c thisSEvent : sevents)
            {
                salesEventMap.put(thisSEvent.Id, thisSEvent);
                if(thisSEvent.Status__c == 'Tentative')
                {
                    String currentValStarts = tentativeDateMapStarts.get(thisSEvent.Id);
                    if(currentValStarts == null) 
                    {
                     tentativeDateMapStarts.put(thisSEvent.Id, '');
                     tentativeDateMapEnds.put(thisSEvent.Id, '');
                     tentativeDateMapDurations.put(thisSEvent.Id, '');
                    }
                    
                    for(Event_Possible_Date__c pdate : thisSEvent.Possible_Dates__r)
                    {
                        if(pdate.Status__c == 'Possible')
                        {
                            //add an entry to the three maps
                            
//                            tentativeDateMap.put(pdate.Id,

                                currentValStarts = tentativeDateMapStarts.get(thisSEvent.Id);
                                String currentValEnds = tentativeDateMapEnds.get(thisSEvent.Id);
                                String currentValDurations = tentativeDateMapDurations.get(thisSEvent.Id);
                                if(currentValStarts != null && currentValStarts != '')
                                {
                                    currentValStarts += '<br/>';
                                    currentValEnds += '<br/>';
                                    currentValDurations += '<br/>';
                                }
                                currentValStarts += pdate.Start_Date__c.format();
                                currentValEnds += pdate.End_Date__c.format();
                                currentValDurations += pdate.Event_Hours__c;
                                
                                tentativeDateMapStarts.put(thisSEvent.Id, currentValStarts);
                                tentativeDateMapEnds.put(thisSEvent.Id, currentValEnds);
                                tentativeDateMapDurations.put(thisSEvent.Id, currentValDurations);

                        }
                         //
                    
                    }
                }
            }                     
                  
                  
            //build maps for resource requests     
                          
         ResourceRequest__c[] rrequests = 
                        [SELECT Id, Name, Status__c, RFx_Internal_Due__c, 
                            Event_Type__c,  LastModifiedDate, Event_Hours__c,
                            (SELECT Id, Start_Date__c, End_Date__c, Status__c, Event_Hours__c from Possible_Dates__r
                             WHERE Status__c = 'Possible' or Status__c = 'Selected' or Status__c = 'Preferred' )
                         from ResourceRequest__c
                         WHERE Id in :relevantRequestIDs
                         ORDER BY Status__c];

            for(ResourceRequest__c thisRRequest : rrequests)
            {
                resourceRequestMap.put(thisRRequest.Id, thisRRequest);


                String currentValStarts = requestDateMapStarts.get(thisRRequest.Id);
                if(currentValStarts == null) 
                {
                 requestDateMapStarts.put(thisRRequest.Id, '');
                 requestDateMapEnds.put(thisRRequest.Id, '');
                 requestDateMapDurations.put(thisRRequest.Id, '');
                }
                
                for(Possible_Date__c pdate : thisRRequest.Possible_Dates__r)
                {
                    if(pdate.Status__c == 'Possible' || pdate.Status__c == 'Selected'|| pdate.Status__c == 'Preferred')
                    {
                        //add an entry to the three maps
                        
//                            tentativeDateMap.put(pdate.Id,

                            currentValStarts = requestDateMapStarts.get(thisRRequest.Id);
                            String currentValEnds = requestDateMapEnds.get(thisRRequest.Id);
                            String currentValDurations = requestDateMapDurations.get(thisRRequest.Id);
                            if(currentValStarts != null && currentValStarts != '')
                            {
                                currentValStarts += '<br/>';
                                currentValEnds += '<br/>';
                                currentValDurations += '<br/>';
                            }
                            currentValStarts += pdate.Start_Date__c.format();
                            currentValEnds += pdate.End_Date__c.format();
                            currentValDurations += pdate.Event_Hours__c;
                            
                            requestDateMapStarts.put(thisRRequest.Id, currentValStarts);
                            requestDateMapEnds.put(thisRRequest.Id, currentValEnds);
                            requestDateMapDurations.put(thisRRequest.Id, currentValDurations);

                    }
                     //
                
                }
            }                     

                            
            return toReturn;        
                    
        }
        return null;
    }
      

}