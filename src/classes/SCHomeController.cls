public with sharing class SCHomeController {

  public String regionCode {get;set;}
  public Map<Id,String> roleMap {get;set;}
  public Map<Id,Decimal> prepHoursMap {get;set;}
  public String myEventRange {get;set;}
  public String myRequestRange {get;set;}
  public String fullEventRange {get;set;} 
  public String fullRequestRange {get;set;} 


  
  public Preparation__c viewAsUser {get;set;}
  
    public Map<Id,Sales_Event__c> salesEventMap {get; set;} 
    public Map<Id,String> tentativeDateMapStarts {get; set;} 
    public Map<Id,String> tentativeDateMapEnds {get; set;} 
    public Map<Id,String> tentativeDateMapDurations {get; set;} 

    public Map<Id,ResourceRequest__c> resourceRequestMap {get; set;} 
    public Map<Id,String> requestDateMapStarts {get; set;} 
    public Map<Id,String> requestDateMapEnds {get; set;} 
    public Map<Id,String> requestDateMapDurations {get; set;} 
  
  
  public SCHomeController()
  {
      fullEventRange = 'Next30';
      myEventRange = 'Open';

      fullRequestRange = 'Open';
      myRequestRange = 'Open';

      viewAsUser = new Preparation__c();
      User currentUser = [SELECT Id, Name from User where Id = :UserInfo.getUserId() LIMIT 1];
      viewAsUser.Who__c = currentUser.Id;
      regionCode = UserRegionHelper.getCurrentUserDefaultRegion();
      roleMap = new Map<Id,String>();
      prepHoursMap = new Map<Id,Decimal>();

        salesEventMap = new Map<Id,Sales_Event__c>();
        tentativeDateMapStarts = new Map<Id,String> ();
        tentativeDateMapEnds = new Map<Id,String> ();
        tentativeDateMapDurations = new Map<Id,String> ();
    
        resourceRequestMap = new Map<Id,ResourceRequest__c>();
        requestDateMapStarts = new Map<Id,String> ();
        requestDateMapEnds = new Map<Id,String> ();
        requestDateMapDurations = new Map<Id,String> ();

  }
  
    public void reloadPage()
    {


    }  
  
  public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
  }


  private void buildSalesEventMaps(List<Id> ids)
  {
          //build maps of dates for sales events
            Sales_Event__c[] sevents = 
                        [SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, 
                            Event_Type__c, Presentation_Type__c, List_Of_People__c, LastModifiedDate, Event_Hours__c, Customer_Hours__c, Preparation_Hours__c, Stage__c,
                            (SELECT Id, Start_Date__c, End_Date__c, Status__c, Event_Hours__c from Possible_Dates__r
                             WHERE Status__c = 'Possible')
                         from Sales_Event__c
                         WHERE Id in :ids
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
            
    }
                  
  private void buildResourceRequestMaps(List<Id> ids)
  {
                  
            //build maps for resource requests     
                          
         ResourceRequest__c[] rrequests = 
                        [SELECT Id, Name, Status__c, RFx_Internal_Due__c, 
                            Event_Type__c,  LastModifiedDate, Event_Hours__c,
                            (SELECT Id, Start_Date__c, End_Date__c, Status__c, Event_Hours__c from Possible_Dates__r
                             WHERE Status__c = 'Possible' or Status__c = 'Selected' or Status__c = 'Preferred' )
                         from ResourceRequest__c
                         WHERE Id in :ids
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
                    }
                 }

            }                       
  }
  
  private void addToRoleMap(Id eventID, String role, boolean onlyAddIfEmpty)
  {
      if(roleMap.get(eventID) == null)
          roleMap.put(eventID, role);
      else if(!onlyAddIfEmpty)
      {
          String oldRole = roleMap.get(eventID);
          if(!oldRole.contains(role))
              roleMap.put(eventID, oldRole + ';' + role);
      }
  }
    
  // OPPORTUNITY EVENT METHODS    
  public List<EventAndRoleString> getMySalesEventsList()
  {

       List<Sales_Event__c> theEvents= new List<Sales_Event__c>();
       
      Date dateMin= System.Today().addDays(-30);
      Date dateMax= System.Today().addDays(0);

       if(myEventRange == 'Last30')
       {
          dateMin= System.Today().addDays(-30);
          dateMax= System.Today().addDays(0);           
       }
       else if(myEventRange == 'Last90')
       {
          dateMin= System.Today().addDays(-60);
          dateMax= System.Today().addDays(0);                  
       }
       else if(myEventRange == 'Last365')
       {
          dateMin= System.Today().addDays(-365);
          dateMax= System.Today().addDays(0);                  
       }

       
       if(myEventRange == 'Open')
       {
            theEvents = [SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, Event_Type__c, Event_Hours__c , Opportunity__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Presentation_Type__c, List_Of_People__c, LastModifiedDate, 
                                     (SELECT Id , Who__c, Coverage_Area__c, Description__c  FROM Customer_Commitments__r where Who__c = :viewAsUser.Who__c ),
                                     (SELECT Id , Who__c, Hours__c  FROM Preparations__r where Who__c = :viewAsUser.Who__c )
                                      FROM Sales_Event__c
                                      WHERE (Status__c = 'Tentative' or Status__c = 'Confirmed')
                                      ORDER BY Confirmed_Start_Date__c
                                      ];
       
       }
       else 
       {
            theEvents = [SELECT Id, Name, Status__c, RFx_Internal_Due__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, Event_Type__c, Event_Hours__c, Opportunity__c, Presentation_Type__c, Opportunity__r.Name, Opportunity__r.Owner.Name, List_Of_People__c, LastModifiedDate, 
                                     (SELECT Id , Who__c, Coverage_Area__c, Description__c  FROM Customer_Commitments__r where Who__c = :viewAsUser.Who__c ),
                                     (SELECT Id , Who__c, Hours__c  FROM Preparations__r where Who__c = :viewAsUser.Who__c )
                                      FROM Sales_Event__c
                                      WHERE (Status__c = 'Completed' and Confirmed_Start_Date__c >= :dateMin and COnfirmed_Start_Date__c <= :dateMax)
                                      ORDER BY Confirmed_Start_Date__c DESC
                                      ];
       
       }
            //filter out results that current user is not named on 
          Set<Sales_Event__c > myset = new Set<Sales_Event__c >();
         
           List<Id> theIdsToMap = new List<Id>();
         
              for(Sales_Event__c thisEvent : theEvents)
              {
                  theIdsToMap.add(thisEvent.Id);
                  //walk over full set and only include things where I have a commitment
                  Decimal prepHours = 0;
                  for(Customer_Commitment__c thisCommitment : thisEvent.Customer_Commitments__r)
                  {
                      if(thisCommitment.Who__c == viewAsUser.Who__c)
                      {
//                          for(
                          //add to a set to prevent duplicates
                          //need confirm that I have availability on one of these dates as well
                          myset.add(thisEvent);
                          addToRoleMap(thisEvent.Id, thisCommitment.Coverage_Area__c, false);
                          //break;
                      }
                  }
                  for(Preparation__c thisPrep : thisEvent.Preparations__r)
                  {
                      if(thisPrep.Who__c == viewAsUser.Who__c)
                      {
                          myset.add(thisEvent);                      
                          prepHours += thisPrep.Hours__c;
                          addToRoleMap(thisEvent.Id, 'Prep Only', true);
                          break;
                      }
                  }
                  //store the prep hours for this event
                  prepHoursMap.put(thisEvent.Id, prepHours);
              }

            buildSalesEventMaps(theIdsToMap);

           List<EventAndRoleString> retval = new List<EventAndRoleString>();
           //now, let's sort these events
           List<StaffingCalendarEntryWrapper> sortList = new List<StaffingCalendarEntryWrapper>();
           for(Sales_Event__c thisEvent : myset)
           {
             sortList.add(new StaffingCalendarEntryWrapper(thisEvent));
           }
           sortList.sort();
           
           for(StaffingCalendarEntryWrapper thisWrapper : sortList)
           {
               String roleStr = roleMap.get(thisWrapper.event.Id);
               EventAndRoleString thisERS = new EventAndRoleString();
               thisERS.event = thisWrapper.event;
               thisERS.role = roleStr ;
               Decimal hoursFromMap = prepHoursMap.get(thisWrapper.event.Id);
               if(hoursFromMap == null) hoursFromMap = 0;
               thisERS.prep = hoursFromMap ;
               retval.add(thisERS);
           }
           
//           retval.addAll(myset);
                        
       
       return retval;
  }

  public List<Sales_Event__c> getTeamSalesEventsList()
  {
      Date dateMin= System.Today();
      Date dateMax= System.Today().addDays(30);
      String statusFilter = 'Confirmed';
      
      if(fullEventRange == 'Next30')
      {
          dateMin= System.Today();
          dateMax= System.Today().addDays(30);
          statusFilter = 'Confirmed';                
      }
      else if(fullEventRange == 'Next60')
      {
          dateMin= System.Today();
          dateMax= System.Today().addDays(60);
          statusFilter = 'Confirmed';                
      }
      else if(fullEventRange == 'Next90')
      {
          dateMin= System.Today();
          dateMax= System.Today().addDays(90);
          statusFilter = 'Confirmed';                
      }
      else if(fullEventRange == 'Last30')
      {
          dateMin= System.Today().addDays(-30);
          dateMax= System.Today();
          statusFilter = 'Completed';                
      }
      else if(fullEventRange == 'Last60')
      {
          dateMin= System.Today().addDays(-60);
          dateMax= System.Today();
          statusFilter = 'Completed';                
      }
      else if(fullEventRange == 'Last90')
      {
          dateMin= System.Today().addDays(-90);
          dateMax= System.Today();
          statusFilter = 'Completed';                
      }
      else if(fullEventRange == 'Last365')
      {
          dateMin= System.Today().addDays(-365);
          dateMax= System.Today();
          statusFilter = 'Completed';                
      }

       List<Sales_Event__c> theEvents= [SELECT Id, Name, Status__c, RFx_Internal_Due__c, Confirmed_Start_Date__c, Confirmed_End_Date__c, Event_Type__c, Presentation_Type__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Owner.Name , Opportunity__r.Region__c, List_Of_People__c, LastModifiedDate
                                      FROM Sales_Event__c s
                                      WHERE (Status__c = :statusFilter AND Confirmed_Start_Date__c >= :dateMin AND Confirmed_Start_Date__c <= :dateMax  ) AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                                      ORDER BY Confirmed_Start_Date__c
                                      ];

           List<Sales_Event__c> retval = new List<Sales_Event__c>();
           
           List<Id> theIdsToMap = new List<Id>();
         
           
           
           //now, let's sort these events
           List<StaffingCalendarEntryWrapper> sortList = new List<StaffingCalendarEntryWrapper>();
           for(Sales_Event__c thisEvent : theEvents)
           {
                  theIdsToMap.add(thisEvent.Id);
             sortList.add(new StaffingCalendarEntryWrapper(thisEvent));
           }
           sortList.sort();
           
           for(StaffingCalendarEntryWrapper thisWrapper : sortList)
           {
               retval.add(thisWrapper.event);
           }


            buildSalesEventMaps(theIdsToMap);

      return retval;
  }
  
  // PROJECTS
  public List<Project__c> getMyActiveProjectsList()
  {
      List<Project_Event__c> theProjectEvents= [SELECT Id, Name, Status__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, Project__c, Project__r.Id, Project__r.Name, Project__r.Status__c, LastModifiedDate, 
                                     (SELECT Id , Who__c, Description__c  FROM Project_Participants__r where Who__c = :viewAsUser.Who__c ),
                                     (SELECT Id , Who__c, Hours__c  FROM Preparations__r where Who__c = :viewAsUser.Who__c )
                                      FROM Project_Event__c
                                      WHERE Project__r.Status__c = 'Active'
                                      ORDER BY Confirmed_Start_Date__c
                                      ];
                                      
     theProjectEvents = filterToMyEvents(theProjectEvents);
                                      
     List<Id> projIds  = new List<Id>();
     for(Project_Event__c thisProjectEvent : theProjectEvents)
     {
         projIDs.add(thisProjectEvent.Project__r.Id);
     }
    
    List<Project__c> theProjects = [SELECT Id, Name, Status__c, Description__c , LastModifiedDate
                                    FROM Project__c
                                    WHERE Id in :projIDs ];
                                    
                                    
    return theProjects;

  }
  
  public List<Project_Event__c> filterToMyEvents(List<Project_Event__c> fullList)
  {
                 //filter out results that current user is not named on 
          Set<Project_Event__c > myset = new Set<Project_Event__c >();
         
              for(Project_Event__c thisEvent : fullList)
              {
                  //walk over full set and only include things where I have a commitment
                  Decimal prepHours = 0;
                  for(Project_Participant__c thisCommitment : thisEvent.Project_Participants__r)
                  {
                      if(thisCommitment.Who__c == viewAsUser.Who__c)
                      {
//                          for(
                          //add to a set to prevent duplicates
                          //need confirm that I have availability on one of these dates as well
                          myset.add(thisEvent);
                          //break;
                      }
                  }
                  for(Project_Preparation__c thisPrep : thisEvent.Preparations__r)
                  {
                      if(thisPrep.Who__c == viewAsUser.Who__c)
                      {
                          myset.add(thisEvent);                      
                          prepHours += thisPrep.Hours__c;
                          break;
                      }
                  }
                  //store the prep hours for this event
                  prepHoursMap.put(thisEvent.Id, prepHours);
              }

           //now, let's sort these events
           List<StaffingCalendarEntryWrapper> sortList = new List<StaffingCalendarEntryWrapper>();
           for(Project_Event__c thisEvent : myset)
           {
             sortList.add(new StaffingCalendarEntryWrapper(thisEvent));
           }
           sortList.sort();

     
     return new List<Project_Event__c>(myset);
  
  }

  public List<ProjectEventAndPrep> getMyActiveProjectEventsList()
  {
                                 
      List<Project_Event__c> theProjectEvents= [SELECT Id, Name, Status__c,Confirmed_Start_Date__c, Confirmed_End_Date__c, Project__c, Project__r.Name, LastModifiedDate, 
                                     (SELECT Id , Who__c, Description__c  FROM Project_Participants__r where Who__c = :viewAsUser.Who__c ),
                                     (SELECT Id , Who__c, Hours__c  FROM Preparations__r where Who__c = :viewAsUser.Who__c )
                                      FROM Project_Event__c
                                      WHERE (Status__c = 'Tentative' or Status__c = 'Confirmed')
                                      ORDER BY Confirmed_Start_Date__c
                                      ];


            //filter out the value that the user is not on
            
            List<Project_Event__c> sortedList =  filterToMyEvents(theProjectEvents);
           
           
           List<ProjectEventAndPrep> retval = new List<ProjectEventAndPrep>();

           for(Project_Event__c thisProjectEvent : sortedList)
           {
               ProjectEventAndPrep thisERS = new ProjectEventAndPrep();
               thisERS.event = thisProjectEvent ;
               Decimal hoursFromMap = prepHoursMap.get(thisProjectEvent.Id);
               if(hoursFromMap == null) hoursFromMap = 0;
               thisERS.prep = hoursFromMap ;
               retval.add(thisERS);
           }
           
//           retval.addAll(myset);
                        
       
       return retval;                                 
  }

  // PERSONAL EVENTS METHODS
  public List<Personal_Event__c> getMyOpenPersonalEventsList()
  {
  
    List<Personal_Event__c> retval = [SELECT Id, Name, Start__c, End__c, Event_Type__c, Status__c, Note__c , LastModifiedDate
                                      FROM Personal_Event__c 
                                      WHERE User__c = :viewAsUser.Who__c and (Status__c = 'Tentative' or Status__c = 'Confirmed') 
                                      ORDER BY Start__c LIMIT 50 
                                      ];   
    return retval;
  }

  public List<Personal_Event__c> getMyRecentPersonalEventsList()
  {
  
    Date dateLimit = System.Today().addDays(-60);
    List<Personal_Event__c> retval = [SELECT Id, Name, Start__c, End__c, Event_Type__c, Status__c, Note__c , LastModifiedDate
                                      FROM Personal_Event__c 
                                      WHERE User__c = :viewAsUser.Who__c and (Status__c = 'Completed' and Start__c > :dateLimit  ) 
                                      ORDER BY Start__c DESC LIMIT 50 
                                      ];   
    return retval;
  }

  // Support Request Methods
  public List<Sales_Support_Request__c> getOpenSupportRequestsList()
  {
         List<Sales_Support_Request__c> allOpenRequests = [SELECT Id, Name, Description__c, Opportunity__c, Account__c, Campaign__c, Opportunity__r.Name, Account__r.Name, Campaign__r.Name,  Opportunity__r.Region__c, Type__c, Status__c, Assigned_To__c, Requested_Completion_Date__c, Target_Completion_Date__c, LastModifiedDate 
                   FROM Sales_Support_Request__c
                   WHERE (Status__c = 'Not Started' or Status__c = 'In Progress')  //AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                   ORDER BY Requested_Completion_Date__c, Status__c ];      
  
          return allOpenRequests;
  }


  public List<Sales_Support_Request__c> getMyOpenSupportRequestsList()
  {
         List<Sales_Support_Request__c> allOpenRequests = [SELECT Id, Name, Description__c, Opportunity__c, Account__c, Campaign__c, Opportunity__r.Name, Account__r.Name, Campaign__r.Name,  Opportunity__r.Region__c, Type__c, Status__c, Assigned_To__c, Target_Completion_Date__c,  LastModifiedDate,
                                                             (SELECT Who__c from Preparations__r)
                   FROM Sales_Support_Request__c
                   WHERE (Status__c = 'Not Started' or Status__c = 'In Progress')  
                   ORDER BY Status__c, LastModifiedDate desc ];      
  
          Set< Sales_Support_Request__c > myset = new Set< Sales_Support_Request__c >();
         
         
              for(Sales_Support_Request__c thisRequest : allOpenRequests )
              {
                  //walk over full set and only include things where I have a prep or am assigned
                  
                  if(thisRequest.Assigned_To__c == viewAsUser.Who__c)
                  {
                              myset.add(thisRequest);
                  }
                  else
                  {
                      for(Support_Request_Preparation__c thisPrep : thisRequest.Preparations__r)
                      {
                          if(thisPrep.Who__c == viewAsUser.Who__c)
                          {
                              //add to a set to prevent duplicates
                              myset.add(thisRequest);
                              break;
                          }
                      }
                  }
              }
          
           List< Sales_Support_Request__c > retval = new List< Sales_Support_Request__c >();
            retval.addAll(myset);
          
          return retval;
  }



  // Resource Request Methods

  public List<ResourceRequest__c> getTeamSalesRequestsList()
  {
          List<ResourceRequest__c> theList = new List<ResourceRequest__c>();
            
            if(fullRequestRange == 'Open')
            {
               theList = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Event_Type__c, Status__c, LastModifiedDate FROM ResourceRequest__c
                   WHERE (Status__c = 'Open' or Status__c = 'Fully Staffed')  AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                   ORDER BY LastModifiedDate desc ];      
            }       
            else if(fullRequestRange == 'Past7Days')
            {
               Date greaterThanDate = System.Today().addDays(-7);
            
               theList = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name,  Event_Type__c, Status__c,  LastModifiedDate FROM ResourceRequest__c
                    WHERE ((Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) AND LastModifiedDate >= :greaterThanDate )
                    ORDER BY LastModifiedDate desc ];             
            }
            else if(fullRequestRange == 'Past30Days')
            {
               Date greaterThanDate = System.Today().addDays(-30);
            
               theList = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name,  Event_Type__c, Status__c,  LastModifiedDate FROM ResourceRequest__c
                    WHERE ((Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) AND LastModifiedDate >= :greaterThanDate )
                    ORDER BY LastModifiedDate desc ];             
            }
            else if(fullRequestRange == 'CompletedLast30')
            {
               Date greaterThanDate = System.Today().addDays(-30);
            
               theList = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name,  Event_Type__c, Status__c,  LastModifiedDate FROM ResourceRequest__c
                    WHERE ((Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) AND (Status__c = 'Complete' OR Status__c = 'Completed') AND LastModifiedDate >= :greaterThanDate )
                    ORDER BY LastModifiedDate desc ];             
            }


         List<Id> theIdsToMap = new List<Id>();
         for(ResourceRequest__c thisRequest : theList)
         {
                  theIdsToMap.add(thisRequest.Id);
         
         }
         buildResourceRequestMaps(theIdsToMap);
         
  
          return theList;
  }

  public List<ResourceRequest__c> getPendingSalesRequestsList()
  {
      List<ResourceRequest__c> theList 
         = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Event_Type__c, Status__c, LastModifiedDate FROM ResourceRequest__c
                   WHERE (Status__c = 'Pending' or Status__c = '') AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                   ORDER BY LastModifiedDate desc ];    

         List<Id> theIdsToMap = new List<Id>();
         for(ResourceRequest__c thisRequest : theList)
         {
                  theIdsToMap.add(thisRequest.Id);
         
         }
         buildResourceRequestMaps(theIdsToMap);
                   
                   
      return theList;  
  }


  public List<ResourceRequest__c> getMySalesRequestsList()
  {
          List<ResourceRequest__c> allRequests  = new List<ResourceRequest__c>();
          
          if(myRequestRange == 'Open')
          {
             allRequests = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Event_Type__c, Status__c , LastModifiedDate ,
                     (SELECT Id , User__c, Status__c  FROM Resource_Assignments__r where User__c = :viewAsUser.Who__c )
                    FROM ResourceRequest__c 
                    WHERE Status__c = 'Open' or Status__c = 'Fully Staffed' or Status__c = 'Pending' or Status__c = ''
                    ORDER BY LastModifiedDate desc LIMIT 50 ];   
          }          
          else if(myRequestRange == 'Last30')
          {
             Date greaterThanDate = System.Today().addDays(-30);

             allRequests = [SELECT Id, Name, Description__c, RolesAsString__c, Opportunity__r.Name, Opportunity__r.Owner.Name, Event_Type__c, Status__c , LastModifiedDate ,
                     (SELECT Id , User__c, Status__c  FROM Resource_Assignments__r where User__c = :viewAsUser.Who__c )
                    FROM ResourceRequest__c 
                    WHERE LastModifiedDate >= : greaterThanDate
                    ORDER BY LastModifiedDate desc ];   
          }          


          Set<ResourceRequest__c > myset = new Set<ResourceRequest__c >();
         
         List<Id> theIdsToMap = new List<Id>();
         
         
              for(ResourceRequest__c thisRR : allRequests )
              {
                  //walk over full set and only include things where I have a role of 
                  
                  for(Resource_Assignment__c thisRA : thisRR.Resource_Assignments__r)
                  {
                      if(thisRA.User__c == viewAsUser.Who__c && (thisRA.Status__c == 'Selected' || thisRA.Status__c == 'Pending' ))
                      {
                          theIdsToMap.add(thisRR.Id);
//                          for(
                          //add to a set to prevent duplicates
                          //need confirm that I have availability on one of these dates as well
                          myset.add(thisRR);
                      }
                  }
              }


         buildResourceRequestMaps(theIdsToMap);
          
           List<ResourceRequest__c> retval = new List<ResourceRequest__c>();
            retval.addAll(myset);
          
          return retval;
  }
  
    public class EventAndRoleString{
        public Sales_Event__c event  {get; set;}   
        public String role  {get; set;}   
        public Decimal prep {get; set;}   
        public String getPrepFontColor() 
        {
        
            if(event.Event_Hours__c == null || prep == null) return 'Black';
            if(prep == 0) return 'Red';
            if(event.Event_Hours__c > prep) return 'Red';
            if(event.Event_Hours__c * 1.5 > prep) return 'Orange';
            return 'Black';
        }
    }
  
    public class ProjectEventAndPrep{
        public Project_Event__c event  {get; set;}   
        public Decimal prep {get; set;}   
    }
  
}