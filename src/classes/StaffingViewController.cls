public without sharing class StaffingViewController {

    public Date dateValue { get; set; }
    
    static final Integer SC_VIEW = 0;
    static final Integer REP_VIEW = 1;
    static final Integer VC_VIEW = 2;
    
        
    public Boolean getIsPresalesManager() {
      return (GWUserProfileHelper.isPresalesManager());
    }
    
    
    @RemoteAction
    public static String getStaffingXML(String region, String startDateAsText)
    {
        System.Debug('getStaffingXML called with date: ' + startDateAsText ) ;
        
        return  getTypedXML(region, startDateAsText, SC_VIEW);
    }    
    

    @RemoteAction
    public static String getRepsXML(String region, String startDateAsText)
    {
        System.Debug('getRepsXML called with date: ' + startDateAsText ) ;
        return getTypedXML(region, startDateAsText, REP_VIEW);
    }    

    @RemoteAction
    public static String getVCXML(String region, String startDateAsText)
    {
        System.Debug('getVCXML called with date: ' + startDateAsText ) ;
        return getTypedXML(region, startDateAsText, VC_VIEW);
    }    
    
    public static String getTypedXML(String region, String startDateAsText, Integer xmlType)
    {
        System.Debug('getTypedXML called with date: ' + startDateAsText ) ;
        String rowsXML = '';
        if(xmlType == SC_VIEW)
        {
          rowsXML = getRowsXML('SC - ' + region);        
        }
        else if(xmlType == VC_VIEW)
        {
          rowsXML = getRowsXML('VC - Global');        
        }
        else if(xmlType == REP_VIEW)
        {
          rowsXML = getRowsXML('Sales - AMER');        
        }
        Date actualStartDate = Date.today();
        if(startDateAsText != null)
        {
            string year = startDateAsText.subString(6,10);
            string month = startDateAsText.subString(0,2);
            string day = startDateAsText.subString(3,5);
            if(region == 'EMEA' || region == 'APAC')
            {
                month=startDateAsText.subString(3,5);
                day=startDateAsText.subString(0,2);
            }
            
            string hour = '12';
            string minute = '20';
            string second = '20';
            string stringDate = year + '-' + month +
                   '-' + day + ' ' + hour + ':' + 
                    minute + ':' + second;
            
            actualStartDate  = date.valueOf(stringDate);
            
        }
            
        Datetime cDT = System.now();
        String longDate = cDT.format('yyyy-MM-dd') + 'T'+ cDT.format('HH:mm:ss:SSSZ');
        String retval = '<?xml version="1.0"?><List><UpdateTime>' +longDate + '</UpdateTime>' + rowsXML + 
               getEventsXML(region, Date.valueOf(actualStartDate),xmlType) + 
               '</List>';
        System.Debug(retval);
        return retval;
    }    

  public static String getEventProductString(Sales_Event__c event)
  {
 
      String retval = '';
      Set<String> products = new Set<String>();
      for(Customer_Commitment__c cc: event.Customer_Commitments__r)
      {
          if(cc.Coverage_Area__c != null)
          {
              
              
              String[] areas= cc.Coverage_Area__c.split(';',0);
                if (areas!= null && areas.size() > 0)
                {
                    for(String area : areas)
                    {
                       products.add(area);
                    
                    }
                }
           }
      }
      List<String> prodList = new List<String>(products);
      prodList.sort();
        for(String str :  prodList)
        {
         if(retval != '') retval += ';';
         retval+= str;
        }
        
        // remove last additional comma from string
        //retval= retval.subString(0,retval.length());
        
      return retval;
  
  }

  public static String getRequestProductString(ResourceRequest__c request)
  {
      String retval = '';
      Set<String> products = new Set<String>();
      for(Resource_Role__c role: request.Resource_Roles__r)
      {
          if(role.Status__c != 'No Longer Needed' && role.Role__c != null)
          {
               products.add(role.Role__c);               
           }
      }
      List<String> prodList = new List<String>(products);
      prodList.sort();
        for(String str :  prodList)
        {
         if(retval != '') retval += ',';
         retval+= str;
        }
        
        // remove last additional comma from string
        //retval= retval.subString(0,retval.length());
        
      return retval;
  
  }
  
  public static String getRowsXML(String calendar)
  {
    //for the given calendar, get the list of Calendar_Row__c objects ordered by priority
    List<Calendar_Row__c> theRows = [SELECT Name, Id, Priority__c, Calendar__c, Color__c, Type__c
                                       FROM Calendar_Row__c
                                       WHERE Calendar__C = :calendar
                                       ORDER BY Priority__c];

        
    XmlStreamWriter rowsStream = new XmlStreamWriter();

    for(Calendar_Row__c thisRow : theRows)
    {
      rowsStream.writeStartElement(null,'CalendarRow',null);

      rowsStream.writeStartElement(null,'Label',null);
      rowsStream.writeCharacters(thisRow.Name );
      rowsStream.writeEndElement();

      rowsStream.writeStartElement(null,'Type',null);
      rowsStream.writeCharacters(thisRow.Type__c);
      rowsStream.writeEndElement();

      rowsStream.writeStartElement(null,'Color',null);
      String color = '';
      if(thisRow.Color__c != null) color = thisRow.Color__c;
      rowsStream.writeCharacters(color);
      rowsStream.writeEndElement();

          
      rowsStream.writeEndElement();

    }    

    return rowsStream.getXmlString();

  }


  public static String getEventsXML(String regionCode, Date startDate) 
  {
        return getEventsXML(regionCode,startDate,SC_VIEW);
  }  
    
  public static String getEventsXML(String regionCode, Date startDate, Integer viewType) 
  {
     Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;
     
     startDate= startDate.toStartOfWeek();
     Date endDate = startDate.addDays(84);
  
  
  
        Sales_Event__c[] confirmedEvents =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c, Opportunity__r.Owner.Name, Opportunity__r.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c, RFx_Internal_Due__c,
                                    (SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c  FROM Customer_Commitments__r ),
                                    (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r  WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate   ORDER By Start_Date__c ),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate   ORDER By Start__c )
                                    FROM Sales_Event__c
                                    WHERE
                                      (Status__c = 'Completed' OR Status__c = 'Confirmed') AND
                                     // (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) AND
                                      Event_Type__c <> 'RFI / RFP' AND
                                      Confirmed_End_Date__c <= :endDate AND 
                                      Confirmed_End_Date__c >= :startDate 
                                    ORDER BY Confirmed_Start_Date__c  ];

                                    //for tentative events, first find possible dates that are in the range
                                    
        Event_Possible_Date__c[] possibleDates = [SELECT Sales_Event__r.Id 
                                                       FROM Event_Possible_Date__c
                                                       WHERE Status__c = 'Possible' AND End_Date__c <= :endDate AND End_Date__c >= :startDate ORDER BY Start_Date__c];
                            
        Sales_Event__c[] tentativeEvents = new Sales_Event__c[0] ;                             
        List<Id> possibleEventIDs = new List<Id>();
        if(possibleDates.size() > 0)
        {
            for(Event_Possible_Date__c pd : possibleDates)
            {
                possibleEventIDs.add(pd.Sales_Event__c);
            
            }
            
        }                                                                     

        tentativeEvents =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c,  Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c, RFx_Internal_Due__c,
                                    (SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c FROM Customer_Commitments__r ),
                                    (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r  WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate ORDER By Start_Date__c),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate  ORDER By Start__c )
                                    FROM Sales_Event__c
                                    WHERE 
                                      Id in :possibleEventIDs
                                      //AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                                      AND Status__c = 'Tentative'];


        Sales_Event__c[] RFPevents =  [SELECT Id, Name, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c,  Opportunity__r.Name,Opportunity__r.Owner.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c,
                                              RFx_Received__c, RFx_Internal_Due__c, RFx_External_Due__c, 
                                    (SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c FROM Customer_Commitments__r ),
                                    (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r  WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate  ORDER By Start_Date__c ),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate  ORDER By Start__c )
                                    FROM Sales_Event__c
                                    WHERE 
                                      Event_Type__c = 'RFI / RFP' AND 
                                      //(Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) AND                                   
                                      (
//                                      (RFx_Received__c <= :endDate AND RFx_Received__c >= :startDate) OR
                                      (RFx_Internal_Due__c<= :endDate AND RFx_Internal_Due__c>= :startDate) //OR
//                                      (RFx_External_Due__c<= :endDate AND RFx_External_Due__c>= :startDate)
                                      )
                                    ORDER BY RFx_Received__c, RFx_Internal_Due__c, RFx_External_Due__c  ];

        System.Debug('Found ' + RFPevents.size() + ' RFP Events in range' ) ;
        System.Debug('Found ' + tentativeEvents.size() + ' tentative events in range' ) ;

        
        ///////////////////  now handle the projects
        
        Project_Event__c[] confirmedProjectEvents =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, Status__c, Project__c, Project__r.Name,
                                    (SELECT Id , Who__r.Name, Description__c, Project_Event__c  FROM Project_Participants__r ),
                                    (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r  WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate   ORDER By Start_Date__c ),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate   ORDER By Start__c )
                                    FROM Project_Event__c
                                    WHERE
                                      (Status__c = 'Completed' OR Status__c = 'Confirmed') AND
                                      Confirmed_End_Date__c <= :endDate AND 
                                      Confirmed_End_Date__c >= :startDate 
                                    ORDER BY Confirmed_Start_Date__c  ];

        System.Debug('Found ' + confirmedProjectEvents .size() + ' confirmed project events in range' ) ;        
                                    //for tentative events, first find possible dates that are in the range

                                    
        Project_Event_Possible_Date__c[] possibleProjectDates = [SELECT Project_Event__r.Id 
                                                       FROM Project_Event_Possible_Date__c
                                                       WHERE Status__c = 'Possible' AND End_Date__c <= :endDate AND End_Date__c >= :startDate ORDER BY Start_Date__c];
                                                       
        System.Debug('Found ' + possibleProjectDates.size() + ' tentative project dates in range' ) ;        
                            
        Project_Event__c[] tentativeProjectEvents = new Project_Event__c[0] ;                             
        List<Id> possibleProjectEventIDs = new List<Id>();
        if(possibleProjectDates.size() > 0)
        {
            for(Project_Event_Possible_Date__c pd : possibleProjectDates)
            {
                System.Debug('Adding possible project id: ' + pd.Project_Event__c + ' for date: ' + pd.Id ) ;        
                possibleProjectEventIDs.add(pd.Project_Event__c);
            }
            
        }                                                                     
        System.Debug('Found ' + possibleProjectEventIDs.size() + ' tentative project ids for those dates' ) ;        
        
        tentativeProjectEvents =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, Status__c, Project__c,  Project__r.Name,  
                                    (SELECT Id , Who__r.Name, Description__c, Project_Event__c FROM Project_Participants__r ),
                                    (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r  WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate ORDER By Start_Date__c),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate  ORDER By Start__c )
                                    FROM Project_Event__c
                                    WHERE 
                                      Id in :possibleProjectEventIDs 
                                      //AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null)
                                      AND Status__c = 'Tentative'];

        System.Debug('Found ' + tentativeProjectEvents.size() + ' tentative project events in range' ) ;        
        
        
        ////////////////////  END PROJECTS //////////////////////////////




        //now handle the sales requests
        ResourceRequest__c[] allRequests = new ResourceRequest__c[0];


        
        //first, let's find all the possible dates that are in range
        
        Possible_Date__c[] allPossibleDatesInRange = [SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c, Resource_Request__c
                                                      FROM Possible_Date__c 
                                                      WHERE
                                                        Status__c in ('Possible', 'Selected') AND
                                                         End_Date__c <= :endDate AND 
                                                         End_Date__c >= :startDate];

        // here, we need to get the RFI type sales requests that have a valid internal due date that is in range
        //ResourceRequest__c[] openConfirmedSalesRequests 



         List<Id> neededRequestIds = new List<Id>();
         for(Possible_Date__c thisPD : allPossibleDatesInRange )
         {
             neededRequestIds.add(thisPD.Resource_Request__c);
         }
        
         ResourceRequest__c[] openConfirmedSalesRequests =  [SELECT Id, Name, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c,  Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c,
                                   // (SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c FROM Customer_Commitments__r ),
                                                                    RFx_Received__c, RFx_Internal_Due__c, RFx_External_Due__c, 
                                   (SELECT Id, Start_Date__c, End_Date__c, Note__c, Status__c FROM Possible_Dates__r 
                                    WHERE Status__c <> 'No Longer Available' AND End_Date__c <= :endDate AND End_Date__c >= :startDate
                                    ORDER By Start_Date__c ),
                                   (SELECT Id, Who__r.Name, Coverage_Area__c,Description__c FROM Resource_Holds__r  ),
                                   (SELECT Id, Status__c, Role__c FROM Resource_Roles__r  ),
                                    (SELECT Id, Resource_Role__r.Status__c, Resource_Role__r.Role__c, Status__c, User__r.Name, User__r.Id
                                       FROM Resource_Assignments__r where Status__c in ('Pending', 'Selected'))
                                    FROM ResourceRequest__c
                                    WHERE 
                                        (Id in :neededRequestIds OR 
                                          (Event_Type__c = 'RFI / RFP' AND
                                          RFx_Internal_Due__c <= :endDate AND 
                                          RFx_Internal_Due__c >= :startDate)
                                            
                                        ) AND 
                                      (Status__c = 'Pending' OR Status__c = 'Open' OR Status__c = 'Fully Staffed') 
                                      //AND (Opportunity__r.Region__c = :regionCode OR Opportunity__r.Region__c = null) 
                                      ];

        allRequests.addAll(openConfirmedSalesRequests);
        List<Id> allAssignemntIds = new List<Id>();
        Map<String, Resource_Availability__c> availabilityMap = new Map<String, Resource_Availability__c>();
        
        //need to get the availabilities for all the assignments in these requests
        //(SELECT Id, Availability__c, Possible_Date__r.Start__c,Possible_Date__r.End__c,Possible_Date__r.Status__c,Possible_Date__r.Note__c FROM Resource_Availabilities__r)                                  
            //first, make a list of the IDs for the query
            for(ResourceRequest__c req : allRequests)
            {
                //loop over assignments for this request
                for(Resource_Assignment__c resAssign: req.Resource_Assignments__r )
                {
                    allAssignemntIds .add(resAssign.Id);
                }
            }
            //now use the above list to get all Availabilities
            Resource_Availability__c[] avails = [SELECT Id, Availability__c, Resource_Assignment__r.Id, Possible_Date__r.Id, Possible_Date__r.Start_Date__c,Possible_Date__r.End_Date__c,Possible_Date__r.Status__c,Possible_Date__r.Note__c 
                                                 FROM Resource_Availability__c
                                                 WHERE Resource_Assignment__c in :allAssignemntIds ];
                                                 
            for(Resource_Availability__c thisAvail : avails)
            {
                //List<Resource_Availability__c> currentVal = availabilityMap.get(thisAvail.Resource_Assignment__c.Id + thisAvail.Possible_Date__r.Id );
                //if(currentVal == null) currentVal = new List<Resource_Availability__c>();
                //currentVal.add(thisAvail);
                availabilityMap.put('' + thisAvail.Resource_Assignment__r.Id + thisAvail.Possible_Date__r.Id, thisAvail);
            }
            
            
          System.Debug('Found ' + openConfirmedSalesRequests.size() + ' requests in range' ) ;

         ///////   Now handle sales support requests
         
          Date startDateLessMonth = startDate.addMonths(-1);
          Date endDateLessMonth = endDate.addMonths(-1);
         
          List<Sales_Support_Request__c> allSupportRequests = [SELECT Id, Name, Description__c, Opportunity__c, Account__c, Campaign__c, 
                                                                          Opportunity__r.Name, Account__r.Name, Campaign__r.Name,  Opportunity__r.Region__c, 
                                                                          Opportunity__r.Product_Type__c,
                                                                          Type__c, Status__c, Assigned_To__c, Assigned_To__r.Name,
                                                                          Create_Date__c, Actual_Completion_Date__c,
                                                                          Requested_Completion_Date__c, Target_Completion_Date__c, LastModifiedDate,
                                                                          (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r  WHERE End__c <= :endDate AND End__c >= :startDate   ORDER By Start__c )
 
                                    FROM Sales_Support_Request__c
                                   WHERE Status__c != 'Canceled' AND (
                                     (Requested_Completion_Date__c != null AND Requested_Completion_Date__c>= :startDate AND Requested_Completion_Date__c <= :endDate ) OR
                                     (Target_Completion_Date__c != null AND Target_Completion_Date__c >= :startDate AND Target_Completion_Date__c <= :endDate) OR
                                     (Actual_Completion_Date__c != null AND Actual_Completion_Date__c >= :startDate AND Actual_Completion_Date__c <= :endDate) OR
                                     (Create_Date__c != null AND Create_Date__c >= :startDateLessMonth AND Create_Date__c <= :endDateLessMonth)
//                                     (Requested_Completion_Date__c != null AND Target_Completion_Date__c == null AND Requested_Completion_Date__c>= :startDate AND Requested_Completion_Date__c <= :endDate ) OR
//                                     (Target_Completion_Date__c != null AND Actual_Completion_Date__c == null AND Target_Completion_Date__c >= :startDate AND Target_Completion_Date__c <= :endDate) OR
//                                     (Actual_Completion_Date__c != null AND Actual_Completion_Date__c >= :startDate AND Actual_Completion_Date__c <= :endDate) OR
//                                     (Create_Date__c != null AND Requested_Completion_Date__c == null AND Target_Completion_Date__c == null AND Actual_Completion_Date__c == null AND Create_Date__c >= :startDateLessMonth AND Create_Date__c <= :endDateLessMonth)
                                     )  
                                   ORDER BY Create_Date__c];      
                        
          //at this point, we have all candidates for support requests  (but still need to filter out based on most relevant date
            System.Debug('Number Of Support Requests: ' + allSupportRequests.size());


         ///////////////////////////////////////////////  END GATHERING OF EVENTS //////////////////////////////////////////////
          
            //at this point, we have all the requests and events.  Let's add them to the sorted list
          List<StaffingCalendarEntryWrapper> sortedList = new List<StaffingCalendarEntryWrapper>();
  
        confirmedEvents.addAll(RFPevents);
        confirmedEvents.addAll(tentativeEvents);

        confirmedProjectEvents.addAll(tentativeProjectEvents);        
        
       // List<Id> neededCustomerCommitmentDateRangesIDs = new List<Id>();
       // for(Customer_Commitment__c thisCC : 

        //build a list of the customer commitments we care about
        //query to get them and the date ranges we care about
        //build a map to reference later
        Customer_Commitment__c[] allRelevantCommitments = [SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c,
                                                           (SELECT Start__c, End__C, Note__C from Date_Ranges__r)
                                                           FROM Customer_Commitment__c 
                                                           WHERE Sales_Event__c in :confirmedEvents];        
        
        Map<Id, Customer_Commitment__c> ccMap = new Map<Id, Customer_Commitment__c>();
        for(Customer_Commitment__c thisCC : allRelevantCommitments )
        {
            System.Debug('!!!!!!!!!!!!!!!!!!!!!!   !!!!   Adding commitment with date ranges: ' + thisCC.Date_Ranges__r.size() );
            ccMap.put(thisCC.Id,thisCC);
        }
        

        Project_Participant__c[] allRelevantParticipants = [SELECT Id , Who__r.Name, Description__c, Project_Event__c,
                                                           (SELECT Start__c, End__C, Note__C from Date_Ranges__r)
                                                           FROM Project_Participant__c 
                                                           WHERE Project_Event__c in :confirmedProjectEvents];        
        
        Map<Id, Project_Participant__c> partMap = new Map<Id, Project_Participant__c>();
        for(Project_Participant__c thisPart : allRelevantParticipants )
        {
            System.Debug('!!!!!!!!!!!!!!!!!!!!!!   !!!!   Adding participant with date ranges: ' + thisPart.Date_Ranges__r.size() );
            partMap.put(thisPart.Id,thisPart);
        }
       
        /////////////////////////   now we need to sort them
          //first put them in wrappers
        for(Sales_Event__c event : confirmedEvents )
        {
            sortedList.add(new StaffingCalendarEntryWrapper(event));
        }

        for(ResourceRequest__c req: allRequests)
        {
            sortedList.add(new StaffingCalendarEntryWrapper(req));
        }

        for(Project_Event__c event : confirmedProjectEvents )
        {
            sortedList.add(new StaffingCalendarEntryWrapper(event));
        }
        
        for(Sales_Support_Request__c supportRequest : allSupportRequests)
        {
            StaffingCalendarEntryWrapper scew = new StaffingCalendarEntryWrapper(supportRequest);
            if(scew.compareDate >= startDate && scew.compareDate <= endDate)
                sortedList.add(scew);
        }
        
        sortedList.sort();
  
        XmlStreamWriter holidayStream = new XmlStreamWriter();
        XmlStreamWriter w = new XmlStreamWriter();
        XmlStreamWriter w2 = new XmlStreamWriter();
          w.writeStartElement(null,'EventCount',null);
          w.writeCharacters(String.valueOf(sortedList.size()));
          w.writeEndElement();

//        w.writeStartDocument(null,'1.0');
        for(StaffingCalendarEntryWrapper wrapper: sortedList)
        {
            if(wrapper.event != null)
            {
                Sales_Event__c event = wrapper.event;
                if(event.Event_Type__c != 'RFI / RFP')
                {
                    handleEventXML(event, regionCode, w, w2, ccMap, startDate, endDate, viewType);
                }
                else
                {
                    handleRFPEventXML(event, regionCode, w, w2, startDate, endDate, viewType);
                }
            }
            if(wrapper.request != null)
            {
                ResourceRequest__c request = wrapper.request;
                System.Debug('Would have created XML for' +  request.Id);
                if(request.Event_Type__c != 'RFI / RFP')
                {
                    handleRequestXML(request, regionCode, availabilityMap, w, w2, startDate, endDate, viewType);
                }
                else
                {
                    handleRFPRequestXML(request, regionCode, availabilityMap, w, w2, startDate, endDate, viewType);
                }
            
            }
            if(wrapper.projectEvent != null)
            {
                Project_Event__c event = wrapper.projectEvent;
                handleProjectEventXML(event, regionCode, w, w2, partMap, startDate, endDate, viewType);
            }
            
            if(wrapper.supportRequest != null)
            {
                Sales_Support_Request__c srr = wrapper.supportRequest;
                handleSupportRequestXML(srr, regionCode, w, w2, startDate, endDate, viewType);
            }
        

        }
        
        String allString = 'ALL';
        //get list of holidays
        List<Presales_Calendar_Event__c> calendarBlocksInRange = new List<Presales_Calendar_Event__c> ();
        if(regionCode != 'ALL')
        {
            calendarBlocksInRange = 
               [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales_Consulting__c, Value_Consulting__c, Sales__c, Region__c
                FROM Presales_Calendar_Event__c
                WHERE 
                  Region__c INCLUDES (:regionCode) AND
                  End_Date__c >= :startDate AND
                  Start_Date__c <= :endDate AND
                  ((Value_Consulting__c = TRUE AND Value_Consulting__c = :vcView) OR
                   (Sales_Consulting__c = TRUE AND Sales_Consulting__c = :scView) OR
                   (Sales__c = TRUE AND Sales__C = :repView))
                ORDER BY Start_Date__c
               ];
            
        }
        else
        {
            calendarBlocksInRange = 
               [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales_Consulting__c, Value_Consulting__c, Sales__c, Region__c
                FROM Presales_Calendar_Event__c
                WHERE 
                  End_Date__c >= :startDate AND
                  Start_Date__c <= :endDate AND
                  ((Value_Consulting__c = TRUE AND Value_Consulting__c = :vcView) OR
                   (Sales_Consulting__c = TRUE AND Sales_Consulting__c = :scView) OR
                   (Sales__c = TRUE AND Sales__C = :repView))
                ORDER BY Start_Date__c
               ];              
                    
        }        
           
           

        for(Presales_Calendar_Event__c thisEvent : calendarBlocksInRange)
        {
            if(thisEvent.Region__c == null || thisEvent.Region__c == '') continue;
            String[] tmpString = thisEvent.Region__c.split(';'); 
            for(String thisRegion : tmpString)           
            {                       
                  holidayStream.writeStartElement(null,'Block',null);
    
                  holidayStream.writeStartElement(null,'Title',null);
                  String nameFull= thisEvent.Label__c;
                  holidayStream.writeCharacters(nameFull );
                  holidayStream.writeEndElement();
        
                  holidayStream.writeStartElement(null,'TitleShortName',null);
                  String nameShort= nameFull;              
                  Integer shortLength = getEventShortNameMaxLength(thisEvent,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
                  holidayStream.writeCharacters(nameShort);
                  holidayStream.writeEndElement();
    
                  Date dateToUse = thisEvent.Start_Date__c;
                  holidayStream.writeStartElement(null,'StartDateConfirmed',null);
                   DateTime cDT1 = datetime.newInstance(dateToUse.year(), dateToUse.month(),dateToUse.day());
                  String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                  holidayStream.writeCharacters(startDateOut );
                  holidayStream.writeEndElement();
    
                  dateToUse = thisEvent.End_Date__c;
                  holidayStream.writeStartElement(null,'EndDateConfirmed',null);
                  cDT1 = datetime.newInstance(dateToUse.year(), dateToUse.month(),dateToUse.day());
                  startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                  holidayStream.writeCharacters(startDateOut );
                  holidayStream.writeEndElement();

                  holidayStream.writeStartElement(null,'Region',null);
                  holidayStream.writeCharacters(thisRegion );
                  holidayStream.writeEndElement();
    
                      
                  holidayStream.writeEndElement();
                  if(regionCode != 'ALL') break;  //if it is VC, we only want to have one iteration (region will be ignored by the VF page)
             }
              
        }
        
        
        
        //walk through all dates in range and record holidays
//        for(Date thisDate = startdate.addDays(0); thisDate <= endDate; thisDate.addDays(1))
//        {
//            if(thisDate
//        }
        
        string xml0 = holidayStream.getXmlString();
        string xml = w.getXmlString();
        string xml2 = w2.getXmlString();
        w.close();
        w2.close();
        
        String xml3 = getPersonalEventsXML(startDate,endDate);

        return xml0 + xml + xml2  + xml3;
  }   


  public static void handleSupportRequestXML(Sales_Support_Request__c supportRequest, String regionCode,XmlStreamWriter w , XmlStreamWriter w2, Date startDate, Date endDate, Integer viewType )
  {
      System.Debug('handleSupportRequestXML called for ' + supportRequest.Id);
  
      Boolean repView = viewType == REP_VIEW;
      Boolean vcView = viewType == VC_VIEW;
      Boolean scView = viewType == SC_VIEW;
      
  
              w.writeStartElement(null,'Event',null);
              w.writeStartElement(null,'Title',null);
              String nameFull= supportRequest.Opportunity__r.Name;
              if(nameFull == null) nameFull = supportRequest.Account__r.Name;
              if(nameFull == null) nameFull = supportRequest.Campaign__r.Name;
              if(nameFull == null) nameFull = 'No Name';
              w.writeCharacters(nameFull );
              w.writeEndElement();
    
              w.writeStartElement(null,'TitleShortName',null);
              String nameShort= nameFull;              
              Integer shortLength = getEventShortNameMaxLength(supportRequest,nameShort);
              if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
              w.writeCharacters(nameShort);
              w.writeEndElement();
    
              w.writeStartElement(null,'Description',null);
              String description = supportRequest.Type__c;
              w.writeCharacters(description);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventType',null);
              String eventType = supportRequest.Type__c;
              w.writeCharacters(eventType);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventID',null);
              String eventID = supportRequest.Id;
              w.writeCharacters(eventID);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventURL',null);
              String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + supportRequest.Id;
              w.writeCharacters( eventURL );
              w.writeEndElement();
    
              w.writeStartElement(null,'Who',null);
              w.writeCharacters('teamsupportreq');
              w.writeEndElement();
    
              w.writeStartElement(null,'Product',null);
              String products = getVCProductString(null, null, supportRequest, '');
              w.writeCharacters(products);
              w.writeEndElement();
    
    
              //determine date to use for this object.  shortcut, use wrapper
              StaffingCalendarEntryWrapper scew = new StaffingCalendarEntryWrapper(supportRequest);
              Date dateToUse = scew.compareDate;
    
              w.writeStartElement(null,'StartDateConfirmed',null);
               DateTime cDT1 = datetime.newInstance(dateToUse.year(), dateToUse.month(),dateToUse.day());
              String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
              w.writeCharacters(startDateOut );
              w.writeEndElement();
    
              w.writeStartElement(null,'EndDateConfirmed',null);
              cDT1 = datetime.newInstance(dateToUse.year(), dateToUse.month(),dateToUse.day());
              String endDateOut = cDT1.format('yyyy-MM-dd') + 'T07:00:00:000-0500';
              w.writeCharacters(endDateOut);
              w.writeEndElement();
    
              w.writeEndElement();  //close event tag
              
              
              if(!repView)
              {

                  if(supportRequest.Assigned_To__c != null)
                  {
                      System.Debug('SupportRequestDebug: Assigned_To__c is not null');
                      addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, supportRequest.Status__c, eventID, products, eventURL, supportRequest.Assigned_To__r.Name, startDateOut, endDateOut ,null, null, null);
                  }

                  for(Support_Request_Preparation__c prep : supportRequest.Preparations__r)
                  {
                      //add a line for each commitment line for the person
                      Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
                      Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
                      String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
                      String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
                      addNewPrepXMLEvent(w2, nameFull, nameShort, description, supportRequest.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
                  }
              }
  }
  

  public static void handleRequestXML(ResourceRequest__c request, String regionCode, Map<String, Resource_Availability__c> availabilityMap, XmlStreamWriter w , XmlStreamWriter w2, Date startDate, Date endDate, Integer viewType )
  {
          System.Debug('RequestXML called.');

     Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;

          if(request.Name == 'scripted demo') System.Debug('RequestXML called for demo of interest');
          if(request.Status__c == 'Pending' || request.Status__c == 'Open' || request.Status__c == 'Fully Staffed' )
          {
              if(request.Opportunity__r.Region__c != null && request.Opportunity__r.Region__c != regionCode && regionCode != 'ALL') w = new XmlStreamWriter();
              if(vcView) w = new XMLStreamWriter();  //we don't care about this event for the top since it is not a VC event
              System.Debug('Status is Open or Fully Staffed.');
              
              if(request.Possible_Dates__r.size() > 0)
              {
                  System.Debug('And it has at least one possible date');
                  //for each possible date, we need to write them out
                  w.writeStartElement(null,'Event',null);
                  w.writeStartElement(null,'Title',null);
                  String nameFull= request.Opportunity__r.Name;
                  if(nameFull == null) nameFull = 'No Name';
                  w.writeCharacters(nameFull );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'TitleShortName',null);
                  String nameShort= nameFull;
                  
                  Integer shortLength = getEventShortNameMaxLength(request,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
                  w.writeCharacters(nameShort);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Description',null);
                  String description = request.Name;
                  if(request.Presentation_Type__c != null) description  = description + ' (' +request.Presentation_Type__c + ')'; 
                  w.writeCharacters(description);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventType',null);
                  //String eventType = event.Event_Type__c;
                  if(request.Status__c == 'Pending') w.writeCharacters('pendingsalesrequest');
                  else w.writeCharacters('salesrequest');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventID',null);
                  String eventID = request.Id;
                  w.writeCharacters(eventID);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventURL',null);
                  String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + request.Id;
                  w.writeCharacters( eventURL );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Who',null);
                  w.writeCharacters('teamreq');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Product',null);
                  String products = getRequestProductString(request);
                  w.writeCharacters(products);
                  w.writeEndElement();

    
                  for(Possible_Date__c pd3 : request.Possible_Dates__r)
                  {
                      String personalStatus = 'Tentative';
                      String startDateOut;
                      String endDateOut;
                      if(pd3.Status__c == 'Possible')
                      {
                          w.writeStartElement(null,'DateSet',null);
                          
                          w.writeStartElement(null,'StartDate',null);
                          Datetime cDT1 = datetime.newInstance(pd3.Start_Date__c.year(), pd3.Start_Date__c.month(),pd3.Start_Date__c.day());

                          startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                          w.writeCharacters(startDateOut );
                          w.writeEndElement();
    
                          w.writeStartElement(null,'EndDate',null);
                          cDT1 = datetime.newInstance(pd3.End_Date__c.year(), pd3.End_Date__c.month(),pd3.End_Date__c.day());
                          endDateOut = cDT1.format('yyyy-MM-dd') + 'T07:00:00:000-0500';
                          w.writeCharacters(endDateOut);
                          w.writeEndElement();
                                  
                          w.writeEndElement();  //close DateSet tag

                      }
                                                
                      else if(pd3.Status__c == 'Selected')
                      {
                          personalStatus = 'Confirmed';
                          w.writeStartElement(null,'StartDateConfirmed',null);
                          Datetime cDT1 = datetime.newInstance(pd3.Start_Date__c.year(), pd3.Start_Date__c.month(),pd3.Start_Date__c.day());
                          startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                          w.writeCharacters(startDateOut );
                          w.writeEndElement();
                
                          w.writeStartElement(null,'EndDateConfirmed',null);
                          cDT1 = datetime.newInstance(pd3.End_Date__c.year(), pd3.End_Date__c.month(),pd3.End_Date__c.day());
                          endDateOut = cDT1.format('yyyy-MM-dd') + 'T07:00:00:000-0500';
                          w.writeCharacters(endDateOut);
                          w.writeEndElement();
                          
                          //now handle events for the individual commitments
                                  
                      }
                      
                      if(!repView)
                      {
                          if(request.Status__c == 'Pending')
                          {
                              //add a line for each block
                              
                              for(Resource_Hold__c theHold : request.Resource_Holds__r)
                              {
                                  String coverageArea =  theHold.Coverage_Area__c;
                                  if(coverageArea == 'Value Consulting') coverageArea = getVCProductString(null, request, null, products);
                              
                                  addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'pendingsalesrequest', null, personalStatus , eventID, coverageArea, eventURL, theHOld.Who__r.Name, startDateOut, endDateOut , null, pd3, null);                          
                              }

                          }
                          else
                          {
                              Map<Id, Id> seenUsers = new Map<Id, Id>();
                              
                              //need to walk over assignments, aggregate roles for individual, and only create entries based on availabilities (using map)
                              for(Resource_Assignment__c thisAssign : request.Resource_Assignments__r)
                              {
                                if(thisAssign.Resource_Role__r.Status__c == 'No Longer Needed') continue;  //make sure to skip this if the role is not needed
                                String prodString = '';
                                System.Debug('Looking at assignment for ' + thisAssign.User__r.Name);
                                if(thisAssign.Status__c == 'Selected' || thisAssign.Status__c == 'Pending' )  //Matt to check these values
                                {
                                   Resource_Availability__c theAvail = availabilityMap.get('' +thisAssign.Id + pd3.Id);
                                    System.Debug('Found possible assignment on request ' + thisAssign.Id + ' with status of ' + theAvail.Availability__c );
                                   //check status of availability
                                   if(theAvail.Availability__c == 'Available' || 
                                      theAvail.Availability__c == 'Preferred' || 
                                      theAvail.Availability__c == 'Not Specified' ||
                                      theAvail.Availability__c == 'Potential Conflict' ||
                                      theAvail.Availability__c == null || 
                                      theAvail.Availability__c == '' )
                                   {
                                    System.Debug('  Assignment has a good status ' + theAvail.Availability__c );
                                      //see if this person has other products on this request
                                      
                                      //let's see if this assignment is against a valid possible date
                                      if(theAvail.Possible_Date__r.Status__c == 'Possible' || theAvail.Possible_Date__r.Status__c == 'Selected' )
                                      {
                                      
                                          //if we haven't seen this person on this request, then let's figure out what products they are asking to cover
                                          if(seenUsers.get(thisAssign.User__r.Id) == null)
                                          {
                                            System.Debug('  User not seen before ' + thisAssign.User__r.Name );
                                             prodString = thisAssign.Resource_Role__r.Role__c;
                                            //search the other assignments to see if they are listed and build the string
                                            //need to make sure  to only look at assignments with a status of selected or possible
                                            //  TODO:  need to loop here
                                            for(Resource_Assignment__c theOtherAssign : request.Resource_Assignments__r)
                                            {
                                              if(thisAssign != theOtherAssign)
                                              {
        //                                        System.Debug('Looking at ' + thisAssign.User__r.Name + ' (thisAssign.Resource_Role__r.Role__c) + ' +
                                                if(thisAssign.User__r.Name == theOtherAssign.User__r.Name &&
                                                    thisAssign.Resource_Role__r.Role__c != theOtherAssign.Resource_Role__r.Role__c)
                                                {  //if we are here, it is for the same person but is not the same assignment/role
                                                   //check the status and if it is still possible or selected, add it to the roles
                                                   if(theOtherAssign.Status__c == 'Pending' || theOtherAssign.Status__c == 'Selected')
                                                   {
                                                      prodString = prodString + ',' + theOtherAssign.Resource_Role__r.Role__c;
                                                   }
                                                
                                                }
                                              }
                                            }
                                            //add them to the map so we don't process them again
                                            seenUsers.put(thisAssign.User__r.Id,thisAssign.User__r.Id);
        
                                            System.Debug('  Adding new request XML for assignment ' + thisAssign.User__r.Name + ' for ' + prodString );
                                            
                                              String coverageArea =  prodString;
                                              if(coverageArea == 'Value Consulting') coverageArea = getVCProductString(null, request, null, products);
                                                                    
                                            addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'salesrequest', null, personalStatus , eventID, coverageArea, eventURL, thisAssign.User__r.Name, startDateOut, endDateOut , null, pd3, null);
        
            
                                          }
                                          
                                      }
                                   }                            
                                }                            
                                  
                                                    
                              }
                              }
                       }
                       else
                       {
                           if(request.Status__c == 'Pending')
                             addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'pendingsalesrequest', null, personalStatus , eventID, products, eventURL, request.Opportunity__r.Owner.Name, startDateOut, endDateOut , null, pd3, null);
                           else
                             addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'salesrequest', null, personalStatus , eventID, products, eventURL, request.Opportunity__r.Owner.Name, startDateOut, endDateOut , null, pd3, null);
                           
                       }
                  }
        
        
                  w.writeEndElement();  //close event tag
                  
              }
                            
          }
  }
  
  public static void handleRFPRequestXML(ResourceRequest__c request, String regionCode,  Map<String, Resource_Availability__c> availabilityMap, XmlStreamWriter w , XmlStreamWriter w2, Date startDate, Date endDate, Integer viewType )
  {
      System.Debug('handleRFPRequestXML called');

     Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;

      
          if(request.Status__c == 'Pending' || request.Status__c == 'Open' || request.Status__c == 'Fully Staffed' )
          {
              if(request.Opportunity__r.Region__c != null && request.Opportunity__r.Region__c != regionCode && regionCode != 'ALL') w = new XmlStreamWriter();
              if(vcView ) w = new XMLStreamWriter();  //we don't care about this event for the top since it is not a VC event
              System.Debug('RFP Status is Open or Fully Staffed.');
              
             if(request.RFx_Internal_Due__c == null) return;
             if(true)
              {
                  //System.Debug('And it has at least one possible date');
                  //for each possible date, we need to write them out
                  w.writeStartElement(null,'Event',null);
                  w.writeStartElement(null,'Title',null);
                  String nameFull= request.Opportunity__r.Name;
                  if(nameFull == null) nameFull = 'No Name';
                  w.writeCharacters(nameFull );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'TitleShortName',null);
                  String nameShort= nameFull;
                  
                  Integer shortLength = getEventShortNameMaxLength(request,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
                  w.writeCharacters(nameShort);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Description',null);
                  String description = request.Name;
                  if(request.Presentation_Type__c != null) description  = description + ' (' +request.Presentation_Type__c + ')';                   
                  w.writeCharacters(description);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventType',null);
                  //String eventType = event.Event_Type__c;
                  w.writeCharacters('salesrequest');
                  w.writeEndElement();
                  w.writeStartElement(null,'EventSubType',null);
                  w.writeCharacters('RFx');
                  w.writeEndElement();
                
                  w.writeStartElement(null,'EventID',null);
                  String eventID = request.Id;
                  w.writeCharacters(eventID);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventURL',null);
                  String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + request.Id;
                  w.writeCharacters( eventURL );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Who',null);
                  w.writeCharacters('teamreq');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Product',null);
                  String products = getRequestProductString(request);
                  w.writeCharacters(products);
                  w.writeEndElement();


          w.writeStartElement(null,'StartDateConfirmed',null);        
//          Datetime cDT1 = event.RFx_Internal_Due__c;
          String startDateOut = request.RFx_Internal_Due__c.year() + '-' + request.RFx_Internal_Due__c.month() + '-' + request.RFx_Internal_Due__c.day() +  'T12:02:00:000-0500';
          w.writeCharacters(startDateOut );
          w.writeEndElement();

          w.writeStartElement(null,'EndDateConfirmed',null);
//          cDT1 = event.RFx_Internal_Due__c;
          String endDateOut = request.RFx_Internal_Due__c.year() + '-' + request.RFx_Internal_Due__c.month() + '-' + request.RFx_Internal_Due__c.day() +  'T12:02:00:000-0500';
//          String endDateOut = cDT1.format('yyyy-MM-dd') + 'T12:00:00:000-0500';
          w.writeCharacters(endDateOut);
          w.writeEndElement();

        
                  w.writeEndElement();  //close event tag
                  
            if(!repView)
            {      

                  if(request.Status__c == 'Pending')
                  {
                      //add a line for each block
                      
                      for(Resource_Hold__c theHold : request.Resource_Holds__r)
                      {
                          addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'pendingsalesrequest', 'RFx', 'Tentative', eventID, theHold.Coverage_Area__c, eventURL, theHOld.Who__r.Name, startDateOut, endDateOut , null, null, null);                          
                      }

                  }
                  else
                  {

                      Map<Id, Id> seenUsers = new Map<Id, Id>();
                      
                      //need to walk over assignments, aggregate roles for individual, and only create entries based on availabilities (using map)
                      for(Resource_Assignment__c thisAssign : request.Resource_Assignments__r)
                      {
                        if(thisAssign.Resource_Role__r.Status__c == 'No Longer Needed') continue;  //make sure to skip this if the role is not needed
                        String prodString = '';
                        System.Debug('Looking at assignment for ' + thisAssign.User__r.Name);
                        if(thisAssign.Status__c == 'Selected' || thisAssign.Status__c == 'Pending' )  //Matt to check these values
                        {
                           //Resource_Availability__c theAvail = availabilityMap.get('' +thisAssign.Id );
                        //    System.Debug('Found possible assignment on request ' + thisAssign.Id + ' with status of ' + theAvail.Availability__c );
                           //check status of availability
    //                               if(theAvail.Availability__c == 'Available' || 
    //                                  theAvail.Availability__c == 'Preferred' || 
    //                                  theAvail.Availability__c == 'Not Specified' ||
    //                                  theAvail.Availability__c == 'Potential Conflict' ||
    //                                  theAvail.Availability__c == null || 
    //                                  theAvail.Availability__c == '' )
    //                               {
                         //   System.Debug('  Assignment has a good status ' + theAvail.Availability__c );
                              //see if this person has other products on this request
                              
                              //if we haven't seen this person on this request, then let's figure out what products they are asking to cover
                              if(seenUsers.get(thisAssign.User__r.Id) == null)
                              {
                                System.Debug('  User not seen before ' + thisAssign.User__r.Name );
                                 prodString = thisAssign.Resource_Role__r.Role__c;
                                //search the other assignments to see if they are listed and build the string
                                //need to make sure  to only look at assignments with a status of selected or possible
                                //  TODO:  need to loop here
                                for(Resource_Assignment__c theOtherAssign : request.Resource_Assignments__r)
                                {
                                  if(thisAssign != theOtherAssign)
                                  {
    //                                        System.Debug('Looking at ' + thisAssign.User__r.Name + ' (thisAssign.Resource_Role__r.Role__c) + ' +
                                    if(thisAssign.User__r.Name == theOtherAssign.User__r.Name &&
                                        thisAssign.Resource_Role__r.Role__c != theOtherAssign.Resource_Role__r.Role__c)
                                    {  //if we are here, it is for the same person but is not the same assignment/role
                                       //check the status and if it is still possible or selected, add it to the roles
                                       if(theOtherAssign.Status__c == 'Pending' || theOtherAssign.Status__c == 'Selected')
                                       {
                                          prodString = prodString + ',' + theOtherAssign.Resource_Role__r.Role__c;
                                       }
                                    
                                    }
                                  }
                                }
                                //add them to the map so we don't process them again
                                seenUsers.put(thisAssign.User__r.Id,thisAssign.User__r.Id);
    
                                System.Debug('  Adding new request XML for assignment ' + thisAssign.User__r.Name + ' for ' + prodString );
                                addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'salesrequest', 'RFx', 'Tentative', eventID, prodString, eventURL, thisAssign.User__r.Name, startDateOut, endDateOut , null, null, null);
    
                              }
                        //   }                            
                        }                            
                              
                                                
                      }
                   }
               }
               else
               {
                           if(request.Status__c == 'Pending')
                             addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'pendingsalesrequest', 'RFx', 'Tentative', eventID, products, eventURL, request.Opportunity__r.Owner.Name, startDateOut, endDateOut , null, null, null);
                           else
                             addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'salesrequest', 'RFx', 'Tentative' , eventID, products, eventURL, request.Opportunity__r.Owner.Name, startDateOut, endDateOut , null, null, null);
//                           addNewPersonalXMLEvent(w2, nameFull, nameShort, description, 'salesrequest', 'RFx', 'Tentative', eventID, products, eventURL, request.Opportunity__r.Owner.Name, startDateOut, endDateOut , null, null);
                   
               }
             
             }
                            
          }   
          
             
  }

  public static Boolean isVCEvent(Sales_Event__c event)
  {
      if( event.Event_Type__c == 'Value Consulting Assessment' ||
             event.Event_Type__c == 'Value Consulting Business Case' ||
             event.Event_Type__c == 'Value Alignment' ||
             event.Event_Type__c == 'Value Consultation' ||
             event.Event_Type__c == 'Value Consulting Proof of Value') return true;
             
      for(Customer_Commitment__c cc : event.Customer_Commitments__r)
      {
          if(cc.Coverage_Area__c != null && cc.Coverage_Area__c.contains('Value Consulting'))
          {
              return true;
          }
           
      }
      
      return false;
  }


  public static void handleProjectEventXML(Project_Event__c event, String regionCode, XmlStreamWriter w , XmlStreamWriter w2, Map<Id, Project_Participant__c> participantMap, Date startDate, Date endDate, Integer viewType )
  {  
     Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;

  
      //if(event.Opportunity__r.Region__c != null && event.Opportunity__r.Region__c != regionCode && regionCode != 'ALL') w = new XmlStreamWriter();
      //if(vcView  && !isVCEvent(event)) w = new XMLStreamWriter();  //we don't care about this event for the top since it is not a VC event
                  System.Debug('QWERT: handleProjectEventXML enter');

          if(event.Status__c == 'Tentative')
          {
                  System.Debug('QWERT: Status is tentative');

//                  String nameFull= event.Project__r.Name;
                  String nameFull= event.Name;
                  if(nameFull == null) nameFull = 'No Name';

                  String nameShort= nameFull;                  
                  Integer shortLength = getEventShortNameMaxLength(event,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);

                  String eventType = '';
                  String eventID = event.Id;
                  String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id;
                  String products = '';
//                  String description = event.Name;
                  String description = event.Project__r.Name;

              if(event.Possible_Dates__r.size() > 0)
              {
                  System.Debug('QWERT: STarting possible date loop: ' + event.Possible_Dates__r.size());
                  //for each possible date, we need to write them out
                  w.writeStartElement(null,'Event',null);
                  w.writeStartElement(null,'Title',null);
                  w.writeCharacters(nameFull );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'TitleShortName',null);
                  w.writeCharacters(nameShort);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Description',null);

                  w.writeCharacters(description);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventType',null);
                  w.writeCharacters(eventType);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventID',null);
                  w.writeCharacters(eventID);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventURL',null);
                  w.writeCharacters( eventURL );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Who',null);
                  w.writeCharacters('teamproject');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Product',null);
                  w.writeCharacters(products);
                  w.writeEndElement();
    
    
                  //keep track of what we have already output 
    
                  for(Project_Event_Possible_Date__c pd3 : event.Possible_Dates__r)
                  {
                      if(pd3.Status__c == 'Possible')
                      {
                          w.writeStartElement(null,'DateSet',null);
                          
                          w.writeStartElement(null,'StartDate',null);
                          Datetime cDT1 = datetime.newInstance(pd3.Start_Date__c.year(), pd3.Start_Date__c.month(),pd3.Start_Date__c.day());
                          String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                          w.writeCharacters(startDateOut );
                          w.writeEndElement();
    
                          w.writeStartElement(null,'EndDate',null);
                          cDT1 = datetime.newInstance(pd3.End_Date__c.year(), pd3.End_Date__c.month(),pd3.End_Date__c.day());
                          String endDateOut = cDT1.format('yyyy-MM-dd')+ 'T07:00:00:000-0500';
                          w.writeCharacters(endDateOut);
                          w.writeEndElement();
                                  
                          w.writeEndElement();  //close DateSet tag

                    


        

                      }
                  }
        
        
                  w.writeEndElement();  //close event tag
                  

                          if(!repView)
                          {
                          
                          String startDateOut = null;
                          String endDateOut = null;
                              //now handle events for the individual commitments
                              for(Project_Participant__c part: event.Project_Participants__r)
                              {
                                  //add a line for each commitment line for the person if no date ranges
                                  Integer dateRangeCount = 0;
                                  if(participantMap.get(part.Id) != null)
                                  {
                                       dateRangeCount = participantMap.get(part.Id).Date_Ranges__r.size();
                                       System.Debug('((((((((((((((((((((((((     Updated date range count to: ' + dateRangeCount);
                                   
                                  }
                                  else
                                  {
                                      System.Debug('((((((((((((((((((((((((     Did not find commitment in map!');
                                  }
                                  if(dateRangeCount  == 0)
                                  {
                                      System.Debug('QWERTY: Date range count is zero.  Adding personal line for tentative. ');  
                                      addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, '', eventURL, part.Who__r.Name, startDateOut, endDateOut , null, null, event.Possible_Dates__r );                                  
                                  }
                                  else
                                  {
                                      System.Debug('QWERTY: Date range count is ' + dateRangeCount  +'.  Adding personal line for tentative. ');  
                                      Project_Event_Possible_Date__c[] thePossibles = new Project_Event_Possible_Date__c[1];
                                  
                                      
                                      //Integer ind = 0;
                                      for(Project_Date_Range__c thisDR : participantMap.get(part.Id).Date_Ranges__r)
                                      {
                                          //check to see if this is in range  (cend > start and cstart is < end)
                                          if(thisDR.Start__c <= endDate && thisDR.End__C >= startDate)
                                          {
                                              Project_Event_Possible_Date__c epd = new Project_Event_Possible_Date__c();
                                              epd.Status__c = 'Possible';
                                              epd.Start_Date__c = thisDR.Start__c;
                                              epd.End_Date__c = thisDR.End__c;
            
                                              thePossibles[0] = epd;
                                              addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, '', eventURL, part.Who__r.Name,startDateOut, endDateOut,null, null, thePossibles );
                                          }
                                      } 
    
                                  }
                              }                              
                          }
                          else
                          {
                                  //addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, products, eventURL, event.Opportunity__r.Owner.Name, startDateOut, endDateOut , event.Possible_Dates__r, null );                          
                          }
                  
              }
                  if(!repView)
                  {
                  
                      //and handle preps
                      for(Project_Preparation__c prep : event.Preparations__r)
                      {
                          System.Debug('Looking at event prep for ' + prep.Who__r.Name);
                          //add a line for each commitment line for the person
                          Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
                          Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
                          String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
                          String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
                          addNewPrepXMLEvent(w2, nameFull, nameShort, description, event.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
                      }
                  }                  
                            
          }
          else
          {
              w.writeStartElement(null,'Event',null);
              w.writeStartElement(null,'Title',null);
//              String nameFull= event.Project__r.Name;
              String nameFull= event.Name;
              if(nameFull == null) nameFull = 'No Name';
              w.writeCharacters(nameFull );
              w.writeEndElement();
    
              w.writeStartElement(null,'TitleShortName',null);
              String nameShort= nameFull;
              
              Integer shortLength = getEventShortNameMaxLength(event,nameShort);
              if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
              w.writeCharacters(nameShort);
              w.writeEndElement();
    
              w.writeStartElement(null,'Description',null);
              String description = event.Project__r.Name;
//              String description = event.Name;
              w.writeCharacters(description);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventType',null);
              String eventType = '';
              w.writeCharacters(eventType);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventID',null);
              String eventID = event.Id;
              w.writeCharacters(eventID);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventURL',null);
              String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id;
              w.writeCharacters( eventURL );
              w.writeEndElement();
    
              w.writeStartElement(null,'Who',null);
              w.writeCharacters('teamproject');
              w.writeEndElement();
    
              w.writeStartElement(null,'Product',null);
              String products = '';
              w.writeCharacters(products);
              w.writeEndElement();
    
              w.writeStartElement(null,'StartDateConfirmed',null);
               DateTime cDT1 = datetime.newInstance(event.Confirmed_Start_Date__c.year(), event.Confirmed_Start_Date__c.month(),event.Confirmed_Start_Date__c.day());
              String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
              w.writeCharacters(startDateOut );
              w.writeEndElement();
    
              w.writeStartElement(null,'EndDateConfirmed',null);
              cDT1 = datetime.newInstance(event.Confirmed_End_Date__c.year(), event.Confirmed_End_Date__c.month(),event.Confirmed_End_Date__c.day());
              String endDateOut = cDT1.format('yyyy-MM-dd') + 'T07:00:00:000-0500';
              w.writeCharacters(endDateOut);
              w.writeEndElement();
    
              w.writeEndElement();  //close event tag
              
              
              if(!repView)
              {
                  //now handle events for the individual commitments
                  for(Project_Participant__c part: event.Project_Participants__r)
                  {
                  
                      Integer dateRangeCount = 0;
                      if(participantMap.get(part.Id) != null)
                      {
                           dateRangeCount = participantMap.get(part.Id).Date_Ranges__r.size();
                           System.Debug('((((((((((((((((((((((((     Updated date range count to: ' + dateRangeCount);
                       
                      }
                      else
                      {
                          System.Debug('((((((((((((((((((((((((     Did not find commitment in map!');
                      }
                      if(dateRangeCount  == 0)
                      {
                          //add a line for each commitment line for the person
                          addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, '', eventURL, part.Who__r.Name, startDateOut, endDateOut ,null, null, event.Possible_Dates__r);
                      }
                      else
                      {
                          for(  Project_Date_Range__c thisDR : participantMap.get(part.Id).Date_Ranges__r)
                          {
                                          //check to see if this is in range  (cend > start and cstart is < end)
                              if(thisDR.Start__c <= endDate && thisDR.End__C >= startDate)
                              {
                                  Datetime sDT1 = datetime.newInstance(thisDR.Start__c.year(), thisDR.Start__c.month(),thisDR.Start__c.day());
                                  String sdateForRange =  sDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                                  Datetime eDT1 = datetime.newInstance(thisDR.End__c.year(), thisDR.End__c.month(),thisDR.End__c.day());
                                  String edateForRange =  eDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                                  addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, '', eventURL, part.Who__r.Name, sdateForRange, edateForRange, null, null, event.Possible_Dates__r);
                              }                              
                          }
                      }                  
                  
                  }
              }
              else
              {
                    //  addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, products, eventURL, event.Project__r.Owner.Name, startDateOut, endDateOut , null,null, event.Possible_Dates__r);                          
              }
          
              if(!repView)
              {
                  //and handle preps
                  for(Project_Preparation__c prep : event.Preparations__r)
                  {
                      //add a line for each commitment line for the person
                      Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
                      Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
                      String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
                      String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
                      addNewPrepXMLEvent(w2, nameFull, nameShort, description, event.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
                  }
              }              
          }
      
  }


  private static Integer getEventShortNameMaxLength(Sales_Event__c event, String shortName)
  {
      Integer retval = 7;
      Integer shortest = 5000;
      
    if(event.Event_Type__c != 'RFI / RFP')
    {

      
      if(event.Status__c == 'Confirmed' || event.Status__c == 'Completed' )
      {
         if(event.Confirmed_Start_Date__c != null && event.Confirmed_End_Date__c != null)
          retval =  (event.Confirmed_Start_Date__c.daysBetween(event.Confirmed_End_Date__c) + 1) * 7;
         else  //can't determine dates, so err on the side of one day
          retval = 7;
      }
      else if(event.Status__c == 'Tentative')
      {
          if(event.Possible_Dates__r.size() > 0)
          {    
              for(Event_Possible_Date__c pd3 : event.Possible_Dates__r)
              {
                  if(pd3.Status__c == 'Possible')
                  {
                      Integer length = pd3.Start_Date__c.daysBetween(pd3.End_Date__c) + 1;      
                      if(length < shortest) shortest = length;                                                  
                  }

                
              }
              if(shortest < 5000) retval = shortest * 7;
              
          }
      }        
     }
  
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }
  private static Integer getEventShortNameMaxLength(Sales_Support_Request__c event, String shortName)
  {
      //currently only have one day
      Integer retval = 7;
      
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }
  private static Integer getEventShortNameMaxLength(ResourceRequest__c request, String shortName)
  {
      Integer retval = 7;
      
      Integer shortest = 5000;
      
      if(request.Event_Type__c != 'RFI / RFP')
      {
          for(Possible_Date__c pd3 : request.Possible_Dates__r)
          {
              
              if(pd3.Status__c == 'Possible')
              {
              
                  Integer length = pd3.Start_Date__c.daysBetween(pd3.End_Date__c) + 1;      
                  if(length < shortest) shortest = length;                
              }
                                        
              else if(pd3.Status__c == 'Selected')
              {
                  Integer length = pd3.Start_Date__c.daysBetween(pd3.End_Date__c) + 1;                      
                  if(length < shortest) shortest = length;                                                  
              }
          }      
          if(shortest < 5000) retval = shortest * 7;
      }
      
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }
  private static Integer getEventShortNameMaxLength(Personal_Event__c event, String shortName)
  {
      Integer retval = 7;
      
      retval = (event.Start__c.daysBetween(event.End__c) + 1) * 7;      
      
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }

  private static Integer getEventShortNameMaxLength(Presales_Calendar_Event__c event, String shortName)
  {
      Integer retval = 7;
      
      retval = (event.Start_Date__c.daysBetween(event.End_Date__c) + 1) * 7;      
      
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }

  private static Integer getEventShortNameMaxLength(Project_Event__c event, String shortName)
  {
      Integer retval = 7;
      
      Integer shortest = 5000;

      if(event.Status__c == 'Tentative')
      {
          if(event.Possible_Dates__r.size() > 0)
          {
              for(Project_Event_Possible_Date__c pd3 : event.Possible_Dates__r)
              {
                  if(pd3.Status__c == 'Possible')
                  {
                      Integer length = pd3.Start_Date__c.daysBetween(pd3.End_Date__c) + 1;      
                      if(length < shortest) shortest = length;                                                  
                  }
              }

          }

      }      
      else
      {
            Integer length = event.Confirmed_Start_Date__c.daysBetween(event.Confirmed_End_Date__c) + 1;      
            if(length < shortest) shortest = length;                                                  

      }      
      if(shortest < 5000) retval = shortest * 7;

      
      if(shortName.length() < retval) return shortName.length();      
      return retval;
  }

  public static void handleEventXML(Sales_Event__c event, String regionCode, XmlStreamWriter w , XmlStreamWriter w2, Map<Id, Customer_Commitment__c> commitmentMap, Date startDate, Date endDate, Integer viewType )
  {  
  
       Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;

  
      if(event.Opportunity__r.Region__c != null && event.Opportunity__r.Region__c != regionCode && regionCode != 'ALL') w = new XmlStreamWriter();
      if(vcView  && !isVCEvent(event)) w = new XMLStreamWriter();  //we don't care about this event for the top since it is not a VC event

          if(event.Status__c == 'Tentative')
          {
              if(event.Possible_Dates__r.size() > 0)
              {
                  //for each possible date, we need to write them out
                  w.writeStartElement(null,'Event',null);
                  w.writeStartElement(null,'Title',null);
                  String nameFull= event.Opportunity__r.Name;
                  if(nameFull == null) nameFull = event.Opportunity__r.Name;
                  if(nameFull == null) nameFull = 'No Name';
                  w.writeCharacters(nameFull );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'TitleShortName',null);
                  String nameShort= nameFull;
                  
                  Integer shortLength = getEventShortNameMaxLength(event,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
                  w.writeCharacters(nameShort);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Description',null);
                  String description = event.Name;
                  if(event.Presentation_Type__c != null) description  = description + ' (' +event.Presentation_Type__c + ')'; 

                  w.writeCharacters(description);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventType',null);
                  String eventType = event.Event_Type__c;
                  w.writeCharacters(eventType);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventID',null);
                  String eventID = event.Id;
                  w.writeCharacters(eventID);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventURL',null);
                  String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id;
                  w.writeCharacters( eventURL );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Who',null);
                  w.writeCharacters('teamopp');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Product',null);
                  String products = getEventProductString(event);
                  String productsToWrite = products;
                  if(products == 'Value Consulting') productsToWrite = getVCProductString(event, null, null, products);
                  w.writeCharacters(productsToWrite);
                  w.writeEndElement();

    
                  for(Event_Possible_Date__c pd3 : event.Possible_Dates__r)
                  {
                      if(pd3.Status__c == 'Possible')
                      {
                          w.writeStartElement(null,'DateSet',null);
                          
                          w.writeStartElement(null,'StartDate',null);
                          Datetime cDT1 = datetime.newInstance(pd3.Start_Date__c.year(), pd3.Start_Date__c.month(),pd3.Start_Date__c.day());
                          String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                          w.writeCharacters(startDateOut );
                          w.writeEndElement();
    
                          w.writeStartElement(null,'EndDate',null);
                          cDT1 = datetime.newInstance(pd3.End_Date__c.year(), pd3.End_Date__c.month(),pd3.End_Date__c.day());
                          String endDateOut = cDT1.format('yyyy-MM-dd')+ 'T07:00:00:000-0500';
                          w.writeCharacters(endDateOut);
                          w.writeEndElement();
                                  
                          w.writeEndElement();  //close DateSet tag

                          if(repView)
                          {
                                  addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, getVCProductString(event, null, null, products), event.Status__c, eventID, products, eventURL, event.Opportunity__r.Owner.Name, startDateOut, endDateOut , event.Possible_Dates__r, null, null );                          
                          }


                      }
                  }
        
        
                  w.writeEndElement();  //close event tag


                              String startDateOut = null;
                              String endDateOut = null;
                          if(!repView)
                          {
                          
                              //now handle events for the individual commitments
                              for(Customer_Commitment__c custC : event.Customer_Commitments__r)
                              {
                              /*
                                      Customer_Commitment__c[] allRelevantCommitments = [SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c,
                                                           (SELECT Start__c, End__C, Note__C from Date_Ranges__r)
                                                           FROM Customer_Commitment__c 
                                                           WHERE Sales_Event__c in :confirmedEvents];        
                              */
                              
                              
                                  //add a line for each commitment line for the person if no date ranges
                                  Integer dateRangeCount = 0;
                                  if(commitmentMap.get(custC.Id) != null)
                                  {
                                       dateRangeCount = commitmentMap.get(custC.Id).Date_Ranges__r.size();
                                       System.Debug('((((((((((((((((((((((((     Updated date range count to: ' + dateRangeCount);
                                   
                                  }
                                  else
                                  {
                                      System.Debug('((((((((((((((((((((((((     Did not find commitment in map!');
                                  }
                                  
                                  String coverageArea =  custC.Coverage_Area__c;
                                  if(coverageArea == 'Value Consulting') coverageArea = getVCProductString(event, null, null, products);
                          
                                  if(dateRangeCount  == 0)
                                  {
                                      addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, coverageArea, eventURL, custC.Who__r.Name, startDateOut, endDateOut , event.Possible_Dates__r, null , null);                                  
                                  }
                                  else
                                  {
                                      Event_Possible_Date__c[] thePossibles = new Event_Possible_Date__c[1];
                                  
                                      
                                      //Integer ind = 0;
                                      for(Customer_Commitment_Date_Range__c thisDR : commitmentMap.get(custC.Id).Date_Ranges__r)
                                      {
                                          //check to see if this is in range  (cend > start and cstart is < end)
                                          if(thisDR.Start__c <= endDate && thisDR.End__C >= startDate)
                                          {
                                              Event_Possible_Date__c epd = new Event_Possible_Date__c();
                                              epd.Status__c = 'Possible';
                                              epd.Start_Date__c = thisDR.Start__c;
                                              epd.End_Date__c = thisDR.End__c;
            
                                              thePossibles[0] = epd;
                                              addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, null, event.Status__c, eventID, coverageArea, eventURL, custC.Who__r.Name,startDateOut, endDateOut, thePossibles, null, null );
                                          }
                                      } 
    
                                  }
                              }                              
                          }
                  
                  
                  if(!repView)
                  {
                  
                      //and handle preps
                      for(Preparation__c prep : event.Preparations__r)
                      {
                          //add a line for each commitment line for the person
                          Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
                          Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
                          String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
                          String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
                          addNewPrepXMLEvent(w2, nameFull, nameShort, description, event.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
                      }
                  }                  
              }
                            
          }
          else if(event.Confirmed_Start_Date__c != null && event.Confirmed_Start_Date__c != null)
          {          
              w.writeStartElement(null,'Event',null);
              w.writeStartElement(null,'Title',null);
              String nameFull= event.Opportunity__r.Name;
              if(nameFull == null) nameFull = event.Opportunity__r.Name;
              if(nameFull == null) nameFull = 'No Name';
              w.writeCharacters(nameFull );
              w.writeEndElement();
    
              w.writeStartElement(null,'TitleShortName',null);
              String nameShort= nameFull;
              
              Integer shortLength = getEventShortNameMaxLength(event,nameShort);
              if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
              w.writeCharacters(nameShort);
              w.writeEndElement();
    
              w.writeStartElement(null,'Description',null);
              String description = event.Name;
                  if(event.Presentation_Type__c != null) description  = description + ' (' +event.Presentation_Type__c + ')'; 
              w.writeCharacters(description);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventType',null);
              String eventType = event.Event_Type__c;
              w.writeCharacters(eventType);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventID',null);
              String eventID = event.Id;
              w.writeCharacters(eventID);
              w.writeEndElement();
    
              w.writeStartElement(null,'EventURL',null);
              String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id;
              w.writeCharacters( eventURL );
              w.writeEndElement();
    
              w.writeStartElement(null,'Who',null);
              w.writeCharacters('teamopp');
              w.writeEndElement();
    
              w.writeStartElement(null,'Product',null);
              String products = getEventProductString(event);
              String productsToWrite = products;
              if(products == 'Value Consulting') productsToWrite = getVCProductString(event, null, null, products);
              w.writeCharacters(productsToWrite);
              w.writeEndElement();
    
              w.writeStartElement(null,'StartDateConfirmed',null);
               DateTime cDT1 = datetime.newInstance(event.Confirmed_Start_Date__c.year(), event.Confirmed_Start_Date__c.month(),event.Confirmed_Start_Date__c.day());
              String startDateOut = cDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
              w.writeCharacters(startDateOut );
              w.writeEndElement();
    
              w.writeStartElement(null,'EndDateConfirmed',null);
              cDT1 = datetime.newInstance(event.Confirmed_End_Date__c.year(), event.Confirmed_End_Date__c.month(),event.Confirmed_End_Date__c.day());
              String endDateOut = cDT1.format('yyyy-MM-dd') + 'T07:00:00:000-0500';
              w.writeCharacters(endDateOut);
              w.writeEndElement();
    
              w.writeEndElement();  //close event tag
              
              
              if(!repView)
              {
                  //now handle events for the individual commitments
                  for(Customer_Commitment__c custC : event.Customer_Commitments__r)
                  {
                  
                      Integer dateRangeCount = 0;
                      if(commitmentMap.get(custC.Id) != null)
                      {
                           dateRangeCount = commitmentMap.get(custC.Id).Date_Ranges__r.size();
                           System.Debug('((((((((((((((((((((((((     Updated date range count to: ' + dateRangeCount);
                       
                      }
                      else
                      {
                          System.Debug('((((((((((((((((((((((((     Did not find commitment in map!');
                      }
                      
                      
                      String coverageArea =  custC.Coverage_Area__c;
                      if(coverageArea == 'Value Consulting') coverageArea = getVCProductString(event, null, null, products);

                      if(dateRangeCount  == 0)
                      {
                          //add a line for each commitment line for the person
                          addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, getVCProductString(event, null, null, products), event.Status__c, eventID, coverageArea, eventURL, custC.Who__r.Name, startDateOut, endDateOut , event.Possible_Dates__r, null, null );
                      }
                      else
                      {
                          for(Customer_Commitment_Date_Range__c thisDR : commitmentMap.get(custC.Id).Date_Ranges__r)
                          {
                                          //check to see if this is in range  (cend > start and cstart is < end)
                              if(thisDR.Start__c <= endDate && thisDR.End__C >= startDate)
                              {
                                  Datetime sDT1 = datetime.newInstance(thisDR.Start__c.year(), thisDR.Start__c.month(),thisDR.Start__c.day());
                                  String sdateForRange =  sDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                                  Datetime eDT1 = datetime.newInstance(thisDR.End__c.year(), thisDR.End__c.month(),thisDR.End__c.day());
                                  String edateForRange =  eDT1.format('yyyy-MM-dd') + 'T06:00:00:000-0500';
                                  addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, getVCProductString(event, null, null, products), event.Status__c, eventID, coverageArea, eventURL, custC.Who__r.Name, sdateForRange, edateForRange, event.Possible_Dates__r, null, null );
                              }                              
                          }
                      }                  
                  
                  }
              }
              else
              {
                      addNewPersonalXMLEvent(w2, nameFull, nameShort, description, eventType, getVCProductString(event, null, null, products), event.Status__c, eventID, products, eventURL, event.Opportunity__r.Owner.Name, startDateOut, endDateOut , event.Possible_Dates__r, null, null );                          
              }
          
              if(!repView)
              {
                  //and handle preps
                  for(Preparation__c prep : event.Preparations__r)
                  {
                      //add a line for each commitment line for the person
                      Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
                      Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
                      String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
                      String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
                      addNewPrepXMLEvent(w2, nameFull, nameShort, description, event.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
                  }
              }              
          }
      
  }

  private static String getVCProductString(Sales_Event__c event, ResourceRequest__c request,Sales_Support_Request__c supportRequest, String priorString)
  {
      if(event != null && event.Opportunity__r.Product_Type__c != null && event.Opportunity__r.Product_Type__c != '') return event.Opportunity__r.Product_Type__c;
      if(request != null && request.Opportunity__r.Product_Type__c != null && request.Opportunity__r.Product_Type__c != '') return request.Opportunity__r.Product_Type__c;
      if(supportRequest != null && supportRequest.Opportunity__r.Product_Type__c != null && supportRequest.Opportunity__r.Product_Type__c != '') return supportRequest.Opportunity__r.Product_Type__c;
      return priorString;
  }


  public static void handleRFPEventXML(Sales_Event__c event, String regionCode, XmlStreamWriter w , XmlStreamWriter w2, Date startDate, Date endDate, Integer viewType )

//  public static String getRFPEventsXML(Date startDate, Date endDate, XmlStreamWriter w2  )
  {  
     Boolean repView = viewType == REP_VIEW;
     Boolean vcView = viewType == VC_VIEW;
     Boolean scView = viewType == SC_VIEW;


      if(event.Opportunity__r.Region__c != null && event.Opportunity__r.Region__c != regionCode && regionCode != 'ALL') w = new XmlStreamWriter();
      if(vcView  && !isVCEvent(event)) w = new XMLStreamWriter();  //we don't care about this event for the top since it is not a VC event

      if(event.RFx_Internal_Due__c != null)
      {
        
          w.writeStartElement(null,'Event',null);
          w.writeStartElement(null,'Title',null);
          String nameFull= event.Opportunity__r.Name;
          if(nameFull == null) nameFull = 'No Name';
          w.writeCharacters(nameFull );
          w.writeEndElement();

          w.writeStartElement(null,'TitleShortName',null);
          String nameShort= nameFull;
          Integer shortLength = getEventShortNameMaxLength(event,nameShort);
          if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);
          w.writeCharacters(nameShort);
          w.writeEndElement();

          w.writeStartElement(null,'Description',null);
          String description = event.Name;
                  if(event.Presentation_Type__c != null) description  = description + ' (' +event.Presentation_Type__c + ')'; 
          w.writeCharacters(description);
          w.writeEndElement();

          w.writeStartElement(null,'EventType',null);
          String eventType = event.Event_Type__c;
          w.writeCharacters(eventType);
          w.writeEndElement();
          w.writeStartElement(null,'EventSubType',null);
          w.writeCharacters('RFx');
          w.writeEndElement();

          w.writeStartElement(null,'EventID',null);
          String eventID = event.Id;
          w.writeCharacters(eventID);
          w.writeEndElement();

          w.writeStartElement(null,'EventURL',null);
          String eventURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id;
          w.writeCharacters( eventURL );
          w.writeEndElement();

          w.writeStartElement(null,'Who',null);
          w.writeCharacters('teamopp');
          w.writeEndElement();

          w.writeStartElement(null,'Product',null);
          String products = getEventProductString(event);
          w.writeCharacters(products);
          w.writeEndElement();

          w.writeStartElement(null,'StartDateConfirmed',null);
          
          Datetime cDT1 = event.RFx_Internal_Due__c;
          System.Debug('RFP Internal date: ' + event.RFx_Internal_Due__c);
//          String startDateOut = cDT1.format('yyyy-MM-DD') +  'T12:02:00:000-0500';
          String startDateOut = event.RFx_Internal_Due__c.year() + '-' + event.RFx_Internal_Due__c.month() + '-' + event.RFx_Internal_Due__c.day() +  'T12:02:00:000-0500';
          w.writeCharacters(startDateOut );
          w.writeEndElement();

          w.writeStartElement(null,'EndDateConfirmed',null);
          cDT1 = event.RFx_Internal_Due__c;
          String endDateOut = event.RFx_Internal_Due__c.year() + '-' + event.RFx_Internal_Due__c.month() + '-' + event.RFx_Internal_Due__c.day() +  'T12:02:00:000-0500';
//          String endDateOut = cDT1.format('yyyy-MM-dd') + 'T12:00:00:000-0500';
          w.writeCharacters(endDateOut);
          w.writeEndElement();

          w.writeEndElement();  //close event tag
          
          //now handle events for the individual commitments
          for(Customer_Commitment__c custC : event.Customer_Commitments__r)
          {
              //add a line for each commitment line for the person
              addNewPersonalXMLEvent(w, nameFull, nameShort, description, eventType, 'RFx', event.Status__c, eventID, custC.Coverage_Area__c, eventURL, custC.Who__r.Name, startDateOut, endDateOut , null, null, null );
          }
          
          //and handle preps
          for(Preparation__c prep : event.Preparations__r)
          {
              //add a line for each commitment line for the person
              Datetime sdt = datetime.newInstance(prep.Start__c.year(), prep.Start__c.month(),prep.Start__c.day());
              Datetime edt = datetime.newInstance(prep.End__c.year(), prep.End__c.month(),prep.End__c.day());
              String startPrep = sdt.format('yyyy-MM-dd') + 'T'+ sdt.format('HH:mm:ss:SSSZ');
              String endPrep = edt.format('yyyy-MM-dd') + 'T'+ edt.format('HH:mm:ss:SSSZ');
              addNewPrepXMLEvent(w2, nameFull, nameShort, description, event.Status__c, eventID, '', eventURL, prep.Who__r.Name, startPrep, endPrep);
          }

      }
  
  }

  public static String getPersonalEventsXML(Date startDate, Date endDate )
  {
        Personal_Event__c[] events =  [SELECT Id, Name, End__c, Start__c, Note__c, Event_Type__c, Status__c, User__r.Name  
                                       FROM Personal_Event__c
                                       WHERE (Start__c <= :endDate and End__c >= :startDate)
                                       ORDER BY Start__c  ];
                                       // WHERE ((End__c <= :endDate AND End__c >= :startDate) OR (Start__c <= :startDate AND End__c >= :endDate))
  
        
        XmlStreamWriter w = new XmlStreamWriter();

        for(Personal_Event__c event:events)
        {
            if(event.Start__c != null && event.End__c != null)
            {
                  w.writeStartElement(null,'Event',null);
                
                  w.writeStartElement(null,'Title',null);
                  String nameFull= event.Name;
                  if(nameFull == null) nameFull = '';
                  w.writeCharacters(nameFull );
                  w.writeEndElement();
        
                  String nameShort= event.Name;
                  Integer shortLength = getEventShortNameMaxLength(event,nameShort);
                  if(nameShort.length() > shortLength) nameShort= nameShort.substring(0, shortLength);

                  w.writeStartElement(null,'TitleShortName',null);
                  w.writeCharacters(nameShort);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Description',null);
                  String note = '';
                  if(event.Note__c != null) note = event.Note__c;
                  w.writeCharacters(note);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventType',null);
                  w.writeCharacters('personal');
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventID',null);
                  w.writeCharacters(event.ID);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EventURL',null);
                  w.writeCharacters(System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + event.Id);
                  w.writeEndElement();
        
                  w.writeStartElement(null,'Who',null);
                  w.writeCharacters(event.User__r.Name);
                  w.writeEndElement();
                  
                  w.writeStartElement(null,'Product',null);
                  String eventTypeStr = event.Event_Type__c;
                  if(eventTypeStr == null) eventTypeStr = '';
                  w.writeCharacters(eventTypeStr);
                  w.writeEndElement();
                  
                  w.writeStartElement(null,'StartDateConfirmed',null);
                  Datetime cDT1 = datetime.newInstance(event.Start__c.year(), event.Start__c.month(),event.Start__c.day());
                  String pstartDateOut = cDT1.format('yyyy-MM-dd') + 'T04:00:00:000-0500';
                  w.writeCharacters(pstartDateOut );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EndDateConfirmed',null);
                  cDT1 = datetime.newInstance(event.End__c.year(), event.End__c.month(),event.End__c.day());
                  pstartDateOut = cDT1.format('yyyy-MM-dd') + 'TT05:00:00:000-0500';
                  w.writeCharacters(pstartDateOut );
                  w.writeEndElement();
                  
                  w.writeEndElement(); //close the event
                    
            }
        
      }
      
        string retval = w.getXmlString();
        w.close();
        return retval;

  }

  public static void addNewPrepXMLEvent(XmlStreamWriter w, String nameFull, String nameShort, String description, String eventStatus, String eventID, String products, String url, String who, String startConf, String endConf ) 
    {
              w.writeStartElement(null,'Event',null);

          w.writeStartElement(null,'Title',null);
          String oppName = nameFull;
          if(oppName == null) oppName = 'No Name';
          w.writeCharacters(oppName );
          w.writeEndElement();

          w.writeStartElement(null,'TitleShortName',null);
          w.writeCharacters(nameShort);
          w.writeEndElement();

          w.writeStartElement(null,'Description',null);
          w.writeCharacters(description);
          w.writeEndElement();

          w.writeStartElement(null,'EventType',null);
          w.writeCharacters('prep');
          w.writeEndElement();

          w.writeStartElement(null,'EventID',null);
          w.writeCharacters(eventID);
          w.writeEndElement();

          w.writeStartElement(null,'EventURL',null);
          w.writeCharacters(url );
          w.writeEndElement();

          w.writeStartElement(null,'Who',null);
          w.writeCharacters(who);
          w.writeEndElement();
          
          w.writeStartElement(null,'Product',null);
          w.writeCharacters(products);
          w.writeEndElement();
          
          w.writeStartElement(null,'StartDateConfirmed',null);
          w.writeCharacters(startConf);
          w.writeEndElement();

          w.writeStartElement(null,'EndDateConfirmed',null);
          w.writeCharacters(endConf);
          w.writeEndElement();
          
          w.writeEndElement(); //close the event

    }
       
  public static void addNewPersonalXMLEvent(XmlStreamWriter w, String nameFull, String nameShort, String description, String eventType, String eventSubType, String eventStatus, String eventID, String products, String url, String who, String startConf, String endConf, Event_Possible_Date__c[] dateList, Possible_Date__c reqDate, Project_Event_Possible_Date__c[] projectDateList  ) 
    {   
        boolean shouldContinue = false;
        if(eventStatus=='Confirmed' || eventStatus == 'Completed') shouldContinue = true;
        if(eventStatus=='Not Started' || eventStatus == 'In Progress') shouldContinue = true;  // support project
        if(eventStatus=='Tentative' && reqDate != null )  shouldContinue = true;
        if(eventSubType == 'RFx') shouldContinue = true;
        if(eventStatus=='Tentative' && dateList != null && dateList.size() > 0 ) 
        {
            boolean foundOneTentativeDate = false;
            for(Event_Possible_Date__c possD : dateList)
            {
                if(possD.Status__c == 'Possible')
                {
                    foundOneTentativeDate = true;
                    break;
                }
            }
            if(foundOneTentativeDate) shouldContinue = true;
            
        }
        if(eventStatus=='Tentative' && projectDateList != null && projectDateList.size() > 0 ) 
        {
            System.Debug('Personal looking at tentative project event with dates');

            boolean foundOneTentativeDate = false;
            for(Project_Event_Possible_Date__c possD : projectDateList)
            {
                if(possD.Status__c == 'Possible')
                {
                    foundOneTentativeDate = true;
                    break;
                }
            }
            if(foundOneTentativeDate) shouldContinue = true;
            
        }
       
        if(shouldContinue)
        { 
              System.Debug('Personal Event Continuing');

          w.writeStartElement(null,'Event',null);

          w.writeStartElement(null,'Title',null);
          String oppName = nameFull;
          if(oppName == null) oppName = 'No Name';
          w.writeCharacters(oppName );
          w.writeEndElement();

          w.writeStartElement(null,'TitleShortName',null);
          w.writeCharacters(nameShort);
          w.writeEndElement();

          w.writeStartElement(null,'Description',null);
          w.writeCharacters(description);
          w.writeEndElement();

          w.writeStartElement(null,'EventType',null);
          w.writeCharacters(eventType);
          w.writeEndElement();

          if(eventSubType != null)
          {
              w.writeStartElement(null,'EventSubType',null);
              w.writeCharacters(eventSubType);
              w.writeEndElement();
          }

          w.writeStartElement(null,'EventID',null);
          w.writeCharacters(eventID);
          w.writeEndElement();

          w.writeStartElement(null,'EventURL',null);
          w.writeCharacters(url );
          w.writeEndElement();

          w.writeStartElement(null,'Who',null);
          w.writeCharacters(who);
          w.writeEndElement();

          w.writeStartElement(null,'Product',null);
          w.writeCharacters(products);
          w.writeEndElement();
          
          if(((eventStatus=='Confirmed' || eventStatus == 'Completed' || eventStatus=='Not Started' || eventStatus == 'In Progress') && startConf != null && endConf!= null) || eventSubType != null)
          {
              w.writeStartElement(null,'StartDateConfirmed',null);
              w.writeCharacters(startConf);
              w.writeEndElement();
    
              w.writeStartElement(null,'EndDateConfirmed',null);
              w.writeCharacters(endConf);
              w.writeEndElement();
          }
          else if (dateList != null)
          {  //iterate over the possible dates
          //<Status>Tentative</Status><StartDate>2014-09-06T08:00:00-07:00</StartDate><EndDate>2014-09-06T08:00:00-07:00</EndDate>
              for(Event_Possible_Date__c pDate : dateList )
              {
                if(pDate.Status__c == 'Possible')
                {
                  
                  w.writeStartElement(null,'DateSet',null);                
                  w.writeStartElement(null,'Status',null);
                  w.writeCharacters('Tentative');
                  w.writeEndElement();

                  w.writeStartElement(null,'StartDate',null);
                  Datetime cDT1 = datetime.newInstance(pDate.Start_Date__c.year(), pDate.Start_Date__c.month(),pDate.Start_Date__c.day());
                  String pstartDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pstartDateOut );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EndDate',null);
                  cDT1 = datetime.newInstance(pDate.End_Date__c.year(), pDate.End_Date__c.month(),pDate.End_Date__c.day());
                  String pendDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pendDateOut );
                  w.writeEndElement();
                  w.writeEndElement(); //DateSet
    
                }                  
              
              }
          
          }
          else if (projectDateList != null)
          {  //iterate over the possible dates
              System.Debug('Iterating over project dates');
              for(Project_Event_Possible_Date__c pDate : projectDateList )
              {
                if(pDate.Status__c == 'Possible')
                {
                  
                  w.writeStartElement(null,'DateSet',null);                
                  w.writeStartElement(null,'Status',null);
                  w.writeCharacters('Tentative');
                  w.writeEndElement();

                  w.writeStartElement(null,'StartDate',null);
                  Datetime cDT1 = datetime.newInstance(pDate.Start_Date__c.year(), pDate.Start_Date__c.month(),pDate.Start_Date__c.day());
                  String pstartDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pstartDateOut );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EndDate',null);
                  cDT1 = datetime.newInstance(pDate.End_Date__c.year(), pDate.End_Date__c.month(),pDate.End_Date__c.day());
                  String pendDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pendDateOut );
                  w.writeEndElement();
                  w.writeEndElement(); //DateSet
    
                }                  
              
              }
          
          }
          else if(reqDate != null)
          {

                  w.writeStartElement(null,'DateSet',null);                
                  w.writeStartElement(null,'Status',null);
                  w.writeCharacters('Tentative');
                  w.writeEndElement();
          
                  w.writeStartElement(null,'StartDate',null);
                  Datetime cDT1 = datetime.newInstance(reqDate.Start_Date__c.year(), reqDate.Start_Date__c.month(),reqDate.Start_Date__c.day());
                  String pstartDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pstartDateOut );
                  w.writeEndElement();
        
                  w.writeStartElement(null,'EndDate',null);
                  cDT1 = datetime.newInstance(reqDate.End_Date__c.year(), reqDate.End_Date__c.month(),reqDate.End_Date__c.day());
                  String pendDateOut = cDT1.format('yyyy-MM-dd') + 'T'+ cDT1.format('HH:mm:ss:SSSZ');
                  w.writeCharacters(pendDateOut );
                  w.writeEndElement();
                  w.writeEndElement(); //DateSet

          }
          w.writeEndElement();  //close event tag
        }
        else
        {
            System.Debug('Did not write personal line as it was determined.');
        }
    }

}