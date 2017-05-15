public with sharing class PresalesMetricsController2 {

    public String reloadPage { get; set; }


    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public String startQuarter {get;set;}
    public String startYear {get;set;}
    public String startMonth {get;set;}
    public Integer quarterCount {get;set;}

    public String eventTypeFilter {get;set;}
    public String regionFilter {get;set;}

    public Integer travelHoursPerTrip {get;set;}

    
    public Date Now {get { return Date.today();}}
    public String ThisYear {get { return String.valueOf(Date.today().year());} }
    
    public List<String> quarterlyLabels {get; set;} 
    public List<Map<String,String>> theMaps  { get;set;}
    
    public Map<String, QuarterlyMetrics> quarterlyMetricsMap { get;set;}

    public PresalesMetricsController2 ()
    {
        travelHoursPerTrip = 12;
    
        quarterCount = 6;
        startDate = getStartOfQuarterDate(Date.today().addMonths(0-quarterCount*3) );
        
        startQuarter = String.valueOf(getQuarterAsInteger(startDate));
        startYear = String.valueOf(getFYear(startDate));
        System.Debug('^^^^^^ startYear: ' + startYear);
        startMonth = String.valueOf(startDate.month());
        System.Debug('^^^^^^ startMonth: ' + startMonth);
        
        eventTypeFilter='Presales';
        regionFilter= UserRegionHelper.getCurrentUserDefaultRegion();
        

        endDate = startDate.addMonths((quarterCount * 3) + 1);  //add an extra month so we can do less than below
        
        quarterlyLabels = new List<String> ();
        theMaps = new List<Map<String,String>>();        
        quarterlyMetricsMap = new Map<String, QuarterlyMetrics>(); 
        
        //if perf becomes an issue, let's turn this off
        reloadPage();              
    }

    public Date getStartOfQuarterDate(Date inputDate)
    {
        Integer theMonth = inputDate.month();
        Integer offset = 0;
        if(theMonth == 9 || theMonth == 12 || theMonth == 3 || theMonth == 6) offset = -1;
        else  if(theMonth == 10 || theMonth == 1 || theMonth == 4 || theMonth == 7) offset = -2;
        
        return inputDate.addMonths(offset).toStartOfMonth();                    
    }
    
    public Integer getQuarterAsInteger(Date inputDate)
    {
        Integer theMonth = inputDate.month();
        if(theMonth == 8 || theMonth == 9 || theMonth == 10) return 1;
        else if(theMonth == 11 || theMonth == 12 || theMonth == 1) return 2;
        else if(theMonth == 2 || theMonth == 3 || theMonth == 4) return 3;
        else return 4;
    }

    public String getFYear(Date inputDate)
    {
        Integer year = inputDate.year();
        if(inputDate.month() > 7) year += 1;
    
//        return String.valueOf(year).substring(2,4);
        return String.valueOf(year);
    }
    
    public Date getStartDateOfQuarterString(String q, String y)
    {
        Integer year = Integer.valueOf(y)-1;
        if(q == '3' || q == '4') year++;
        Integer month = 8;
        if(q == '2') month = 11;
        if(q == '3') month = 2;
        if(q == '4') month = 5;
    
        return Date.newInstance(year,month,1 );
    }
    
    private Integer getRoleCount(String roleString)
    {
        Integer usesPC = 0;
        Integer usesCC = 0;
        Integer usesBC = 0;
        Integer usesDM = 0;
        Integer usesMP = 0;
        Integer usesLive = 0;
        Integer usesTech = 0;

        if(roleString.contains('PolicyCenter') || 
           roleString.contains('ISO Templates') ||
           roleString.contains('Reinsurance') ||
           roleString.contains('Client Data Management') ||
           roleString.contains('Rating') )
        {
            usesPC = 1;
        }
        if(roleString.contains('ClaimCenter'))
        {
            usesCC = 1;
        }
        if(roleString.contains('BillingCenter'))
        {
            usesBC = 1;
        }
        if(roleString.contains('Data Management'))
        {
            usesDM = 1;
        }
        if(roleString.contains('Digital Portals'))
        {
            usesMP = 1;
        }
        if(roleString.contains('Live'))
        {
            usesLive = 1;
        }
        if(roleString.contains('Technical'))
        {
            usesTech = 1;
        }
        
        return usesPC + usesCC + usesBC + usesDM + usesMP + usesLive + usesTech;

    }

    private Decimal distributeToProductBuckets(Decimal hours, String roleString, QuarterlyMetrics thisQuartersMetrics, String fullRoleString, Integer productCountOnEvent, Decimal proration)
    {    
        if(roleString == null || roleString.length() == 0) return 0;
        //figure out how many products the person is covering
        Integer usesPC = 0;
        Integer usesCC = 0;
        Integer usesBC = 0;
        Integer usesDM = 0;
        Integer usesMP = 0;
        Integer usesLive = 0;
        Integer usesTech = 0;
        
        
                
        if(roleString.contains('PolicyCenter') || 
           roleString.contains('ISO Templates') ||
           roleString.contains('Reinsurance') ||
           roleString.contains('Client Data Management') ||
           roleString.contains('Rating') )
        {
            usesPC = 1;
        }
        if(roleString.contains('ClaimCenter'))
        {
            usesCC = 1;
        }
        if(roleString.contains('BillingCenter'))
        {
            usesBC = 1;
        }
        if(roleString.contains('Data Management'))
        {
            usesDM = 1;
        }
        if(roleString.contains('Digital Portals'))
        {
            usesMP = 1;
        }
        if(roleString.contains('Live'))
        {
            usesLive = 1;
        }
        if(roleString.contains('Technical'))
        {
            usesTech = 1;
        }
        
        Integer count = usesPC + usesCC + usesBC + usesDM + usesMP + usesLive + usesTech;

        //ignore:  Observation, Shadow,, Lead
        if(count == 0)
        {
            //if we are here, we need  to            
              //Split:   Suite?  Standard Reporting?  Value Consulting? Strategy?
              
            //need to distribute against all applicable products
            if(fullRoleString.contains('PolicyCenter') || 
               fullRoleString.contains('ISO Templates') ||
               fullRoleString.contains('Reinsurance') ||
               fullRoleString.contains('Client Data Management') ||
               fullRoleString.contains('Rating') )
            {
                usesPC = 1;
            }
            if(fullRoleString.contains('ClaimCenter'))
            {
                usesCC = 1;
            }
            if(fullRoleString.contains('BillingCenter'))
            {
                usesBC = 1;
            }
            if(fullRoleString.contains('Data Management'))
            {
                usesDM = 1;
            }
            if(fullRoleString.contains('Digital Portals'))
            {
                usesMP = 1;
            }
            if(fullRoleString.contains('Live'))
            {
                usesLive = 1;
            }
            if(fullRoleString.contains('Technical'))
            {
                usesTech = 1;
            }
            
            count = productCountOnEvent;
            
        }


        //now, let's add to the appropriate buckets
        if(usesPC == 1)
        {
            thisQuartersMetrics.totalPCHours += hours/count*proration;
        }
        if(usesCC == 1)
        {
            thisQuartersMetrics.totalCCHours += hours/count*proration;
        }
        if(usesBC == 1)
        {
            thisQuartersMetrics.totalBCHours += hours/count*proration;
        }
        if(usesDM == 1)
        {
            thisQuartersMetrics.totalDMHours += hours/count*proration;
        }
        if(usesMP == 1)
        {
            thisQuartersMetrics.totalMPHours += hours/count*proration;
        }
        if(usesLive == 1)
        {
            thisQuartersMetrics.totalLiveHours += hours/count*proration;
        }
        if(usesTech == 1)
        {
            thisQuartersMetrics.totalTechHours += hours/count*proration;
        }            
        
        
        if(count > 0) return hours * proration;
        return 0;
        //  
    }                


    public void reloadPage()
    {
        startDate = getStartDateOfQuarterString(startQuarter, startYear);

        quarterlyLabels = new List<String> ();
        theMaps = new List<Map<String,String>>();        
        quarterlyMetricsMap = new Map<String, QuarterlyMetrics>();

        endDate = startDate.addMonths((quarterCount * 3) + 1);  //add an extra month so we can do less than below


        //create and add the header
        quarterlyLabels.add('');


        Map<String,String> categoryLabelMap = new Map<String,String>();
        categoryLabelMap.put('', 'Hours by Category');
        categoryLabelMap.put(' Perc', '');

        Map<String,String> customerFacingMap = new Map<String,String>();
        customerFacingMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Customer Facing');
        customerFacingMap.put(' Perc', '');

        Map<String,String> prepMap = new Map<String,String>();
        prepMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Preparation');
        prepMap.put(' Perc', '');

        Map<String,String> rfpMap = new Map<String,String>();
        rfpMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;RFI/RFP');
        rfpMap.put(' Perc', '');

        Map<String,String> travelMap = new Map<String,String>();
        travelMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Est. Travel');
        travelMap.put(' Perc', '');


        Map<String,String> spacerMap = new Map<String,String>();
        spacerMap.put('', '');
        spacerMap.put(' Perc', '');


        Map<String,String> productLabelMap = new Map<String,String>();
        productLabelMap.put('', 'Hours by Product');
        productLabelMap.put(' Perc', '');


        Map<String,String> pcMap = new Map<String,String>();
        pcMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;PolicyCenter');
        pcMap.put(' Perc', '');

        Map<String,String> ccMap = new Map<String,String>();
        ccMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;ClaimCenter');
        ccMap.put(' Perc', '');

        Map<String,String> bcMap = new Map<String,String>();
        bcMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;BillingCenter');
        bcMap.put(' Perc', '');

        Map<String,String> dmMap = new Map<String,String>();
        dmMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Data Management');
        dmMap.put(' Perc', '');

        Map<String,String> mpMap = new Map<String,String>();
        mpMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Digital Portals');
        mpMap.put(' Perc', '');

        Map<String,String> liveMap = new Map<String,String>();
        liveMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Live');
        liveMap.put(' Perc', '');
        
        Map<String,String> techMap = new Map<String,String>();
        techMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Technical');
        techMap.put(' Perc', '');


        Map<String,String> eventsLabelMap = new Map<String,String>();
        eventsLabelMap.put('', 'Event Hours (and Counts) by Type');
        eventsLabelMap.put(' Perc', '');




        Map<String,String> eventCallMap = new Map<String,String>();
        eventCallMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Call');
        eventCallMap.put(' Perc', '');
        eventCallMap.put(' Hours', '');
        
        Map<String,String> eventDemoMap = new Map<String,String>();
        eventDemoMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Demonstration');
        eventDemoMap.put(' Perc', '');
        eventDemoMap.put(' Hours', '');
        
        Map<String,String> eventDiscoveryMap = new Map<String,String>();
        eventDiscoveryMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Discovery');
        eventDiscoveryMap.put(' Perc', '');
        eventDiscoveryMap.put(' Hours', '');
        
        Map<String,String> eventInstallMap = new Map<String,String>();
        eventInstallMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Installation');
        eventInstallMap.put(' Perc', '');
        eventInstallMap.put(' Hours', '');
        
        Map<String,String> eventPostSaleMap = new Map<String,String>();
        eventPostSaleMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Post Sale Work');
        eventPostSaleMap.put(' Perc', '');
        eventPostSaleMap.put(' Hours', '');
        
        Map<String,String> eventPOCMap = new Map<String,String>();
        eventPOCMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Proof Of Concept');
        eventPOCMap.put(' Perc', '');
        eventPOCMap.put(' Hours', '');
        
        Map<String,String> eventRFxMap = new Map<String,String>();
        eventRFxMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;RFI/RFP');
        eventRFxMap.put(' Perc', '');
        eventRFxMap.put(' Hours', '');
        
        Map<String,String> eventTestDriveMap = new Map<String,String>();
        eventTestDriveMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;Test Drive');
        eventTestDriveMap.put(' Perc', '');
        eventTestDriveMap.put(' Hours', '');
        
        Map<String,String> eventVCAssessmentMap = new Map<String,String>();
        eventVCAssessmentMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;VC Assessment');
        eventVCAssessmentMap.put(' Perc', '');
        eventVCAssessmentMap.put(' Hours', '');
        
        Map<String,String> eventVCBusCaseMap = new Map<String,String>();
        eventVCBusCaseMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;VC Business Case');
        eventVCBusCaseMap.put(' Perc', '');
        eventVCBusCaseMap.put(' Hours', '');
        
        Map<String,String> eventVCAlignmentMap = new Map<String,String>();
        eventVCAlignmentMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;VC Alignment');
        eventVCAlignmentMap.put(' Perc', '');
        eventVCAlignmentMap.put(' Hours', '');
        
        Map<String,String> eventVCPoVMap = new Map<String,String>();
        eventVCPoVMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;VC Proof of Value');
        eventVCPoVMap.put(' Perc', '');
        eventVCPoVMap.put(' Hours', '');
        
        Map<String,String> eventVCConsultationMap = new Map<String,String>();
        eventVCConsultationMap.put('', '&nbsp;&nbsp;&nbsp;&nbsp;VC Consultation');
        eventVCConsultationMap.put(' Perc', '');
        eventVCConsultationMap.put(' Hours', '');
        
        


        //HERE IS WHERE WE CALCULATE THE INFORMATION
        List<Sales_Event__c> theEvents;
        if(regionFilter == 'Global')
        {
        
            theEvents = [SELECT Id, Confirmed_Start_Date__c,Confirmed_End_Date__c, Name, Presentation_Type__c , Event_Type__c,Event_Hours__c, Status__c,RFx_Internal_Due__c,
                                                     Opportunity__r.Name, Opportunity__r.Id,Opportunity__r.Amount,Opportunity__r.Region__c,
                                                     (SELECT Who__c, Coverage_Area__c,Event_Hours__c  FROM Customer_Commitments__r),
                                                     (SELECT Id, Start__c, End__c, Who__r.Name, Hours__c, Note__c FROM Preparations__r  )
                                              FROM Sales_Event__c
                                              WHERE 
                                                (Event_Type__c = 'RFI / RFP' 
                                                  AND RFx_Internal_Due__c >= :startDate
                                                  AND RFx_Internal_Due__c < :endDate)
                                                OR
                                                (Status__c in ('Confirmed','Completed')
                                                AND Confirmed_Start_Date__c >= :startDate 
                                                AND Confirmed_Start_Date__c < :endDate)];
        }
        else
        {
            theEvents = [SELECT Id, Confirmed_Start_Date__c, Confirmed_End_Date__c, Name, Presentation_Type__c , Event_Type__c,Event_Hours__c, Status__c,RFx_Internal_Due__c ,
                                                     Opportunity__r.Name, Opportunity__r.Id,Opportunity__r.Amount,Opportunity__r.Region__c,
                                                     (SELECT Who__c, Coverage_Area__c, Event_Hours__c  FROM Customer_Commitments__r),
                                                     (SELECT Id, Start__c, End__c, Who__r.Name, Hours__c, Note__c FROM Preparations__r  )
                                              FROM Sales_Event__c
                                              WHERE 
                                                Opportunity__r.Region__c = :regionFilter AND
                                                (
                                                    (Event_Type__c = 'RFI / RFP' 
                                                      AND RFx_Internal_Due__c >= :startDate
                                                      AND RFx_Internal_Due__c < :endDate)
                                                    OR
                                                    (Status__c in ('Confirmed','Completed')
                                                    AND Confirmed_Start_Date__c >= :startDate 
                                                    AND Confirmed_Start_Date__c < :endDate)
                                                 )];
            
        }            
        //let's parse the results
        for(Sales_Event__c thisEvent: theEvents)
        {
        
            Date refStartDate = thisEvent.RFx_Internal_Due__c;
            Date refEndDate = thisEvent.RFx_Internal_Due__c;
            if(thisEvent.Event_Type__c != 'RFI / RFP') 
            {
              refStartDate = thisEvent.Confirmed_Start_Date__c;
              if(thisEvent.Confirmed_End_Date__c != null) refEndDate = thisEvent.Confirmed_End_Date__c;
              else refEndDate = thisEvent.Confirmed_Start_Date__c;
            }
        
            Date theEventStart = getStartOfQuarterDate(refStartDate);
            Date theEventEnd = getStartOfQuarterDate(refEndDate);
            
            String quarterKey = 'Q' + getQuarterAsInteger(theEventStart) + ' ' + getFYear(theEventStart);
            String quarterKeyNext = 'Q' + getQuarterAsInteger(theEventEnd) + ' ' + getFYear(theEventEnd);
            
            //TODO:  need to deal with proration factor
            Decimal proration = 1;
            if(quarterKey != quarterKeyNext)
            {
                //count days between refStartDate and theEventEnd and
                //        days between theEventEnd and refEndDate
                //the figure out proration for first quarter and last quarter
                
                Integer firstDays = refStartDate.daysBetween(theEventEnd);
                Integer secondDays = theEventEnd.daysBetween(refEndDate);
                            
                proration = firstDays/(firstDays+secondDays);
            }
            
            
            //check the map to see if there is already a metric object for this date
            QuarterlyMetrics thisQuartersMetrics =  quarterlyMetricsMap.get(quarterKey);
            //if not, create a new one
            if(thisQuartersMetrics == null) thisQuartersMetrics = new QuarterlyMetrics(theEventStart);

            QuarterlyMetrics nextQuartersMetrics =  quarterlyMetricsMap.get(quarterKeyNext);
            if(nextQuartersMetrics == null) nextQuartersMetrics = new QuarterlyMetrics(theEventEnd);
        
            //update the metrics for this month with this event
            thisQuartersMetrics.opportunities.add(thisEvent.Opportunity__r.Id);
            
            //MATT TODO:  Add ARR HERE
            if(thisEvent.Opportunity__r.Amount != null)
                thisQuartersMetrics.totalARR += thisEvent.Opportunity__r.Amount;
            
            thisQuartersMetrics.incrementEventCountByType(thisEvent.Event_Type__c);

            if(thisEvent.Event_Type__c == 'RFI / RFP')
            {
                thisQuartersMetrics.rfps.add(thisEvent.Id);
                                                
//                         Integer productsForPerson
                 Map<Id, String> userToRoleMap = new Map<Id, String>();

                 String fullRoleString = '';
                 for(Customer_Commitment__c theCommit : thisEvent.Customer_Commitments__r)
                 {                     
                     fullRoleString += theCommit.Coverage_Area__c;
                     //build a map for person name to product
                     String existingRole = userToRoleMap.get(theCommit.Who__c);
                     if(existingRole == null)  // not an entry already for this person
                     {
                         userToRoleMap.put(theCommit.Who__c, theCommit.Coverage_Area__c);
                     }
                     else //need to merge with previous line
                     {
                         userToRoleMap.put(theCommit.Who__c, theCommit.Coverage_Area__c +';'+ existingRole);
                     }
                                          
                 }
                 
                     Integer roleCount = getRoleCount(fullRoleString);
                 
                     //walk over preps and use the map from above to distribute the time. 
                    for(Preparation__c thisPrep : thisEvent.Preparations__r)
                    {
                        if(thisPrep.Hours__c != null && thisPrep.Hours__c > 0)
                        {
                            Decimal hoursDistributed = distributeToProductBuckets(thisPrep.Hours__c, userToRoleMap.get(thisPrep.Who__c), thisQuartersMetrics, fullRoleString, roleCount, proration);                  
                            thisQuartersMetrics.totalRFxHours += hoursDistributed;
                            thisQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributed);
                            if(proration != 1)
                            {
                                Decimal hoursDistributedNext = distributeToProductBuckets(thisPrep.Hours__c, userToRoleMap.get(thisPrep.Who__c), nextQuartersMetrics, fullRoleString, roleCount, 1-proration);                  
                                nextQuartersMetrics.totalRFxHours += hoursDistributedNext;                                
                                nextQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributedNext);
                            }
                            

                        }
                    }                
            
            }
            else  //this is not a RFI, so we need to do like above but allocate time for commitments as well.
            {
                thisQuartersMetrics.events.add(thisEvent.Id); 
                Boolean requiresTravel = thisEvent.Presentation_Type__c != 'Remote';
                

                 Map<Id, String> userToRoleMap = new Map<Id, String>();

                 String fullRoleString = '';
                 for(Customer_Commitment__c theCommit : thisEvent.Customer_Commitments__r)
                 {
                     
                     fullRoleString += theCommit.Coverage_Area__c;
                     //build a map for person name to product
                     String existingRole = userToRoleMap.get(theCommit.Who__c);
                     if(existingRole == null)  // not an entry already for this person
                     {
                         userToRoleMap.put(theCommit.Who__c, theCommit.Coverage_Area__c);
                     }
                     else //need to merge with previous line
                     {
                         userToRoleMap.put(theCommit.Who__c, theCommit.Coverage_Area__c +';'+ existingRole);
                     }
                     
                  }

                 Integer roleCount = getRoleCount(fullRoleString);
                  
                  //walk again now that we built the full role string
                 for(Customer_Commitment__c theCommit : thisEvent.Customer_Commitments__r)
                 {
                  
                     //TODO:  here we need to account for hours for the commitment
                     if(theCommit.Event_Hours__c != null)
                     {
                         //allocate these hours
                        Decimal hoursDistributed = distributeToProductBuckets(theCommit.Event_Hours__c, theCommit.Coverage_Area__c, thisQuartersMetrics, fullRoleString, roleCount,proration);                  
                                                                        
                        thisQuartersMetrics.totalCustomerFacingHours += hoursDistributed;
                        thisQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributed);
                        
                        if(proration != 1)
                        {
                            Decimal hoursDistributedNext = distributeToProductBuckets(theCommit.Event_Hours__c, theCommit.Coverage_Area__c, thisQuartersMetrics, fullRoleString, roleCount,proration);                  
                            nextQuartersMetrics.totalCustomerFacingHours += hoursDistributedNext;                                
                            nextQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributedNext);
                        }
                        
                        if(travelHoursPerTrip > 0 && requiresTravel)
                        {
                            if(proration != 1) 
                            {  
                              thisQuartersMetrics.travelEstimated += travelHoursPerTrip/2;
                              nextQuartersMetrics.travelEstimated += travelHoursPerTrip/2;
                            }
                            else
                              thisQuartersMetrics.travelEstimated += travelHoursPerTrip;
                        }
                        
                         
                     }
                     else
                     {
                         //allocate from the event level
                        Decimal hoursDistributed = distributeToProductBuckets(thisEvent.Event_Hours__c, theCommit.Coverage_Area__c, thisQuartersMetrics, fullRoleString, roleCount,proration);                  
                        thisQuartersMetrics.totalCustomerFacingHours += hoursDistributed;
                        thisQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributed);

                        if(proration != 1)
                        {
                            Decimal hoursDistributedNext = distributeToProductBuckets(thisEvent.Event_Hours__c, theCommit.Coverage_Area__c, thisQuartersMetrics, fullRoleString, roleCount,proration);                  
                            nextQuartersMetrics.totalCustomerFacingHours += hoursDistributedNext;                                
                            nextQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributedNext);
                        }
                        
                        if(travelHoursPerTrip > 0 && requiresTravel)
                        {
                            if(proration != 1) 
                            {  
                              thisQuartersMetrics.travelEstimated += travelHoursPerTrip/2;
                              nextQuartersMetrics.travelEstimated += travelHoursPerTrip/2;
                            }
                            else
                              thisQuartersMetrics.travelEstimated += travelHoursPerTrip;
                        }
                        
                         
                     }
                     
                                          
                 }

             
                 //walk over preps and use the map from above to distribute the time. 
                for(Preparation__c thisPrep : thisEvent.Preparations__r)
                {
                    if(thisPrep.Hours__c != null && thisPrep.Hours__c > 0)
                    {
                        Decimal hoursDistributed = distributeToProductBuckets(thisPrep.Hours__c, userToRoleMap.get(thisPrep.Who__c), thisQuartersMetrics, fullRoleString, roleCount,proration);                  
                        thisQuartersMetrics.totalPreparationHours += hoursDistributed;
                        thisQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributed);

                            if(proration != 1)
                            {
                                Decimal hoursDistributedNext = distributeToProductBuckets(thisPrep.Hours__c, userToRoleMap.get(thisPrep.Who__c), nextQuartersMetrics, fullRoleString, roleCount, 1-proration);                  
                                nextQuartersMetrics.totalPreparationHours += hoursDistributedNext;                                
                                nextQuartersMetrics.incrementEventHoursByType(thisEvent.Event_Type__c, hoursDistributedNext);
                            }
                    }
                }                

                
                   
                //add to total event hours  :  legacy
                if(thisEvent.Event_Hours__c != null && thisEvent.Event_Hours__c > 0)
                    thisQuartersMetrics.totalEventHours += thisEvent.Event_Hours__c ;
                    
                //if here, examime the resources being used and the hours
                //TODO2:  add to time by product for prep
                //TODO2:  add to time by product for cust time                  
                    
                //now figure out how many people participated
                Integer ccommitCount = 0;
                for(Customer_Commitment__c thisCommitment : thisEvent.Customer_Commitments__r)
                {
                    if(thisCommitment.Coverage_Area__c != 'Shadow' && thisCommitment.Coverage_Area__c != 'Observation')
                    {
                        thisQuartersMetrics.totalSCCommitments++;  
                        ccommitCount++;                  
                    }
                }
                                
            }
            //add this to the map 
            quarterlyMetricsMap.put(quarterKey, thisQuartersMetrics);
            quarterlyMetricsMap.put(quarterKeyNext, nextQuartersMetrics);
        }
        
        
        
        for(Integer i = 0; i< quarterCount; i++)
        {
            Date theNewDate =  startDate.addMonths(i*3); 
            Integer quarter = getQuarterAsInteger(  theNewDate);  
            String year = getFYear(theNewDate);  
            
            
//            String thisLabel = DateTime.newInstance(theNewDate,Time.newInstance(18, 30, 2, 20)).format('MMM yy');
            String thisLabel = 'Q' + quarter + ' ' + year; //DateTime.newInstance(theNewDate,Time.newInstance(18, 30, 2, 20)).format('MMM yy');
            quarterlyLabels.add(thisLabel);
           
            String thisQuarterKey = 'Q' + quarter + ' ' + year;
           
           
            //get the holder for this month
            QuarterlyMetrics qmetrics = quarterlyMetricsMap.get(thisQuarterKey);
            
            if(qmetrics != null)
            {
                categoryLabelMap.put(thisLabel, '');
                customerFacingMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalCustomerFacingHours)));
                prepMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalPreparationHours)));
                rfpMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalRFxHours)));
                travelMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.travelEstimated)));
                spacerMap.put(thisLabel, '');
                productLabelMap.put(thisLabel, '');
                pcMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalPCHours)));
                ccMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalCCHours)));
                bcMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalBCHours)));
                dmMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalDMHours)));
                mpMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalMPHours)));
                liveMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalLiveHours)));
                techMap.put(thisLabel, String.valueOf(Integer.valueOf(qmetrics.totalTechHours)));

                eventsLabelMap.put(thisLabel, '');
                eventCallMap.put(thisLabel, String.valueOf(qmetrics.eventCountCallHours) + ' (' + String.valueOf(qmetrics.eventCountCall) + ')');    
                eventDemoMap.put(thisLabel, String.valueOf(qmetrics.eventCountDemoHours) + ' (' + String.valueOf(qmetrics.eventCountDemo) + ')');
                eventDiscoveryMap.put(thisLabel, String.valueOf(qmetrics.eventCountDiscoveryHours) + ' (' +  String.valueOf(qmetrics.eventCountDiscovery)+ ')');
                eventInstallMap.put(thisLabel, String.valueOf(qmetrics.eventCountInstallationHours) + ' (' +  String.valueOf(qmetrics.eventCountInstallation)+ ')');
                eventPostSaleMap.put(thisLabel, String.valueOf(qmetrics.eventCountPostSaleWorkHours) + ' (' + String.valueOf(qmetrics.eventCountPostSaleWork) + ')');
                eventPOCMap.put(thisLabel, String.valueOf(qmetrics.eventCountProofOfConceptHours) + ' (' +  String.valueOf(qmetrics.eventCountProofOfConcept)+ ')');
                eventRFxMap.put(thisLabel, String.valueOf(qmetrics.eventCountRFxHours) + ' (' + String.valueOf(qmetrics.eventCountRFx) + ')');
                eventTestDriveMap.put(thisLabel, String.valueOf(qmetrics.eventCountTestDriveHours) + ' (' +  String.valueOf(qmetrics.eventCountTestDrive)+ ')');
                eventVCAssessmentMap.put(thisLabel, String.valueOf(qmetrics.eventCountVCAssessmentHours) + ' (' +  String.valueOf(qmetrics.eventCountVCAssessment)+ ')');
                eventVCBusCaseMap.put(thisLabel, String.valueOf(qmetrics.eventCountVCBusinessCaseHours) + ' (' + String.valueOf(qmetrics.eventCountVCBusinessCase) + ')');
                eventVCAlignmentMap.put(thisLabel, String.valueOf(qmetrics.eventCountVCAlignmentHours) + ' (' +  String.valueOf(qmetrics.eventCountVCAlignment)+ ')');
                eventVCPoVMap.put(thisLabel, String.valueOf(qmetrics.eventCountProofOfValueHours) + ' (' +  String.valueOf(qmetrics.eventCountProofOfValue)+ ')');
                eventVCConsultationMap.put(thisLabel, String.valueOf(qmetrics.eventCountConsultationHours) + ' (' + String.valueOf(qmetrics.eventCountConsultation) + ')');
        
                                    
                //get totals to do the math
                Double totalHours = qmetrics.totalRFxHours + qmetrics.totalPreparationHours + qmetrics.totalCustomerFacingHours + qmetrics.travelEstimated;
                
                Double totalProductHours = qmetrics.totalPCHours + 
                                           qmetrics.totalCCHours + 
                                           qmetrics.totalBCHours + 
                                           qmetrics.totalDMHours + 
                                           qmetrics.totalMPHours + 
                                           qmetrics.totalLiveHours + 
                                           qmetrics.totalTechHours; 
                
                Double totalEvents = qmetrics.eventCountDemo
                                    + qmetrics.eventCountCall
                                    + qmetrics.eventCountDiscovery
                                    + qmetrics.eventCountInstallation
                                    + qmetrics.eventCountPostSaleWork
                                    + qmetrics.eventCountProofOfConcept
                                    + qmetrics.eventCountRFx
                                    + qmetrics.eventCountTestDrive
                                    + qmetrics.eventCountVCAssessment
                                    + qmetrics.eventCountVCBusinessCase
                                    + qmetrics.eventCountVCAlignment
                                    + qmetrics.eventCountProofOfValue
                                    + qmetrics.eventCountConsultation;

                Decimal totalEventsHoursByType = qmetrics.eventCountDemoHours
                                    + qmetrics.eventCountCallHours
                                    + qmetrics.eventCountDiscoveryHours
                                    + qmetrics.eventCountInstallationHours
                                    + qmetrics.eventCountPostSaleWorkHours
                                    + qmetrics.eventCountProofOfConceptHours
                                    + qmetrics.eventCountRFxHours
                                    + qmetrics.eventCountTestDriveHours
                                    + qmetrics.eventCountVCAssessmentHours
                                    + qmetrics.eventCountVCBusinessCaseHours
                                    + qmetrics.eventCountVCAlignmentHours
                                    + qmetrics.eventCountProofOfValueHours
                                    + qmetrics.eventCountConsultationHours;

                
                eventsLabelMap.put(thisLabel, '(' + Decimal.valueOf(totalEvents).setScale(0) + ')');

                categoryLabelMap.put(thisLabel + ' Perc', '');
                customerFacingMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalCustomerFacingHours/ totalHours * 100)).setScale(1) + '%');
                prepMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalPreparationHours/ totalHours * 100)).setScale(1) + '%');
                rfpMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalRFxHours/ totalHours * 100)).setScale(1) + '%');
                travelMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.travelEstimated/ totalHours * 100)).setScale(1) + '%');
                spacerMap.put(thisLabel + ' Perc', '');
                productLabelMap.put(thisLabel + ' Perc', '');
                pcMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalPCHours/ totalProductHours * 100)).setScale(1) + '%');
                ccMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalCCHours/ totalProductHours * 100)).setScale(1) + '%');
                bcMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalBCHours/ totalProductHours * 100)).setScale(1) + '%');
                dmMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalDMHours/ totalProductHours * 100)).setScale(1) + '%');
                mpMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalMPHours/ totalProductHours * 100)).setScale(1) + '%');
                liveMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalLiveHours/ totalProductHours * 100)).setScale(1) + '%');
                techMap.put(thisLabel + ' Perc', Decimal.valueOf((qmetrics.totalTechHours/ totalProductHours * 100)).setScale(1) + '%');

                eventsLabelMap.put(thisLabel + ' Perc', '');                                
                            
                if(totalEventsHoursByType == 0)
                {
                    eventCallMap.put(thisLabel + ' Perc', '');    
                    eventDemoMap.put(thisLabel + ' Perc',  '');
                    eventDiscoveryMap.put(thisLabel + ' Perc',  '');
                    eventInstallMap.put(thisLabel + ' Perc',  '');
                    eventPostSaleMap.put(thisLabel + ' Perc',  '');
                    eventPOCMap.put(thisLabel + ' Perc',  '');
                    eventRFxMap.put(thisLabel + ' Perc',  '');
                    eventTestDriveMap.put(thisLabel + ' Perc',  '');
                    eventVCAssessmentMap.put(thisLabel + ' Perc',  '');
                    eventVCBusCaseMap.put(thisLabel + ' Perc',  '');
                    eventVCAlignmentMap.put(thisLabel + ' Perc',  '');
                    eventVCPoVMap.put(thisLabel + ' Perc',  '');
                    eventVCConsultationMap.put(thisLabel + ' Perc',  '');                    
                }                
                else
                {                
                    eventCallMap.put(thisLabel + ' Perc',  (qmetrics.eventCountCallHours/ totalEventsHoursByType * 100).setScale(1) + '%');    
                    eventDemoMap.put(thisLabel + ' Perc',  (qmetrics.eventCountDemoHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventDiscoveryMap.put(thisLabel + ' Perc',  (qmetrics.eventCountDiscoveryHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventInstallMap.put(thisLabel + ' Perc',  (qmetrics.eventCountInstallationHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventPostSaleMap.put(thisLabel + ' Perc',  (qmetrics.eventCountPostSaleWorkHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventPOCMap.put(thisLabel + ' Perc',  (qmetrics.eventCountProofOfConceptHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventRFxMap.put(thisLabel + ' Perc',  (qmetrics.eventCountRFxHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventTestDriveMap.put(thisLabel + ' Perc',  (qmetrics.eventCountTestDriveHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventVCAssessmentMap.put(thisLabel + ' Perc',  (qmetrics.eventCountVCAssessmentHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventVCBusCaseMap.put(thisLabel + ' Perc',  (qmetrics.eventCountVCBusinessCaseHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventVCAlignmentMap.put(thisLabel + ' Perc',  (qmetrics.eventCountVCAlignmentHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventVCPoVMap.put(thisLabel + ' Perc',  (qmetrics.eventCountProofOfValueHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    eventVCConsultationMap.put(thisLabel + ' Perc',  (qmetrics.eventCountConsultationHours/ totalEventsHoursByType * 100).setScale(1) + '%');
                    
                }


                

            }
            else
            {
                
                categoryLabelMap.put(thisLabel, '');
                customerFacingMap.put(thisLabel, '-');
                prepMap.put(thisLabel, '-');
                rfpMap.put(thisLabel, '-');
                travelMap.put(thisLabel, '-');
                spacerMap.put(thisLabel, '');
                productLabelMap.put(thisLabel, '');
                pcMap.put(thisLabel, '-');
                ccMap.put(thisLabel, '-');
                bcMap.put(thisLabel, '-');
                dmMap.put(thisLabel, '-');
                mpMap.put(thisLabel, '-');
                liveMap.put(thisLabel, '-');
                techMap.put(thisLabel, '-');

                eventsLabelMap.put(thisLabel, '');
                    eventCallMap.put(thisLabel, '');    
                    eventDemoMap.put(thisLabel,  '');
                    eventDiscoveryMap.put(thisLabel,  '');
                    eventInstallMap.put(thisLabel,  '');
                    eventPostSaleMap.put(thisLabel,  '');
                    eventPOCMap.put(thisLabel,  '');
                    eventRFxMap.put(thisLabel,  '');
                    eventTestDriveMap.put(thisLabel,  '');
                    eventVCAssessmentMap.put(thisLabel,  '');
                    eventVCBusCaseMap.put(thisLabel,  '');
                    eventVCAlignmentMap.put(thisLabel,  '');
                    eventVCPoVMap.put(thisLabel,  '');
                    eventVCConsultationMap.put(thisLabel,  '');                    



                categoryLabelMap.put(thisLabel + ' Perc', '');
                customerFacingMap.put(thisLabel + ' Perc', '-');
                prepMap.put(thisLabel + ' Perc', '-');
                rfpMap.put(thisLabel + ' Perc', '-');
                travelMap.put(thisLabel + ' Perc', '-');
                spacerMap.put(thisLabel + ' Perc', '');
                productLabelMap.put(thisLabel + ' Perc', '');
                pcMap.put(thisLabel + ' Perc', '-');
                ccMap.put(thisLabel + ' Perc', '-');
                bcMap.put(thisLabel + ' Perc', '-');
                dmMap.put(thisLabel + ' Perc', '-');
                mpMap.put(thisLabel + ' Perc', '-');
                liveMap.put(thisLabel + ' Perc', '-');
                techMap.put(thisLabel + ' Perc', '-');

                eventsLabelMap.put(thisLabel + ' Perc', '');
                    eventCallMap.put(thisLabel + ' Perc', '');    
                    eventDemoMap.put(thisLabel + ' Perc',  '');
                    eventDiscoveryMap.put(thisLabel + ' Perc',  '');
                    eventInstallMap.put(thisLabel + ' Perc',  '');
                    eventPostSaleMap.put(thisLabel + ' Perc',  '');
                    eventPOCMap.put(thisLabel + ' Perc',  '');
                    eventRFxMap.put(thisLabel + ' Perc',  '');
                    eventTestDriveMap.put(thisLabel + ' Perc',  '');
                    eventVCAssessmentMap.put(thisLabel + ' Perc',  '');
                    eventVCBusCaseMap.put(thisLabel + ' Perc',  '');
                    eventVCAlignmentMap.put(thisLabel + ' Perc',  '');
                    eventVCPoVMap.put(thisLabel + ' Perc',  '');
                    eventVCConsultationMap.put(thisLabel + ' Perc',  '');                    
            }
            
        }

    
        theMaps.add(categoryLabelMap);
        theMaps.add(customerFacingMap);
        theMaps.add(prepMap);
        theMaps.add(rfpMap);
        theMaps.add(travelMap);
        theMaps.add(spacerMap);
        theMaps.add(productLabelMap);
        theMaps.add(pcMap);
        theMaps.add(ccMap);
        theMaps.add(bcMap);
        theMaps.add(dmMap);
        theMaps.add(mpMap);
        theMaps.add(liveMap);
        theMaps.add(techMap);
        theMaps.add(spacerMap);
        theMaps.add(eventsLabelMap);
        theMaps.add(eventPOCMap);
        theMaps.add(eventDemoMap);
        theMaps.add(eventCallMap);
        theMaps.add(eventDiscoveryMap);
        theMaps.add(eventInstallMap);
        theMaps.add(eventPostSaleMap);
        theMaps.add(eventRFxMap);
        theMaps.add(eventTestDriveMap);
        theMaps.add(eventVCAssessmentMap);
        theMaps.add(eventVCBusCaseMap);
        theMaps.add(eventVCAlignmentMap);
        theMaps.add(eventVCPoVMap);
        theMaps.add(eventVCConsultationMap);
        
    }
    

    
    public Class QuarterlyMetrics
    {
        public Date thisQuarterStart;
        public Date thisQuarterEnd;
        public Date thisQuarterLabel;
        
        public Set<Id> opportunities;
        
        public Double totalARR;
        public Double totalEventHours;
        public Double totalSCCommitments;
                
        public Double totalCustomerFacingHours;
        public Double totalPreparationHours;
        public Double totalRFxHours;
        
        
        public Double totalPCHours;
        public Double totalCCHours;
        public Double totalBCHours;
        public Double totalDMHours;
        public Double totalMPHours;
        public Double totalLiveHours;
        public Double totalTechHours;
        
        public Double travelEstimated;

        public Set<Id> events;
        public Set<Id> rfps;
        public Set<Id> vcevents;
        
        public Integer eventCountDemo;
        public Integer eventCountCall;
        public Integer eventCountDiscovery;
        public Integer eventCountInstallation;
        public Integer eventCountPostSaleWork;
        public Integer eventCountProofOfConcept;
        public Integer eventCountRFx;
        public Integer eventCountTestDrive;
        public Integer eventCountVCAssessment;
        public Integer eventCountVCBusinessCase;
        public Integer eventCountVCAlignment;
        public Integer eventCountProofOfValue;
        public Integer eventCountConsultation;
        
        public Decimal eventCountDemoHours;
        public Decimal eventCountCallHours;
        public Decimal eventCountDiscoveryHours;
        public Decimal eventCountInstallationHours;
        public Decimal eventCountPostSaleWorkHours;
        public Decimal eventCountProofOfConceptHours;
        public Decimal eventCountRFxHours;
        public Decimal eventCountTestDriveHours;
        public Decimal eventCountVCAssessmentHours;
        public Decimal eventCountVCBusinessCaseHours;
        public Decimal eventCountVCAlignmentHours;
        public Decimal eventCountProofOfValueHours;
        public Decimal eventCountConsultationHours;
        
        
        public QuarterlyMetrics(Date theMonth)
        {
            thisQuarterStart = theMonth;
            thisQuarterEnd = thisQuarterStart.addMonths(3);
            totalARR = 0;
            totalEventHours = 0;
            totalSCCommitments = 0;
            
            totalCustomerFacingHours = 0;
            totalPreparationHours = 0;
            totalRFxHours = 0;
            
            
            totalPCHours = 0;
            totalCCHours = 0;
            totalBCHours = 0;
            totalDMHours = 0;
            totalMPHours = 0;
            totalLiveHours = 0;
            totalTechHours = 0;
            
            travelEstimated = 0;

            opportunities = new Set<Id>();
            events = new Set<Id>();
            vcevents = new Set<Id>();
            rfps = new Set<Id>();
            
            
            eventCountDemo = 0;
            eventCountCall = 0;
            eventCountDiscovery = 0;
            eventCountInstallation = 0;
            eventCountPostSaleWork = 0;
            eventCountProofOfConcept = 0;
            eventCountRFx = 0;
            eventCountTestDrive = 0;
            eventCountVCAssessment = 0;
            eventCountVCBusinessCase = 0;
            eventCountVCAlignment = 0;
            eventCountProofOfValue = 0;
            eventCountConsultation = 0;

            eventCountDemoHours = 0;
            eventCountCallHours = 0;
            eventCountDiscoveryHours = 0;
            eventCountInstallationHours = 0;
            eventCountPostSaleWorkHours = 0;
            eventCountProofOfConceptHours = 0;
            eventCountRFxHours = 0;
            eventCountTestDriveHours = 0;
            eventCountVCAssessmentHours = 0;
            eventCountVCBusinessCaseHours = 0;
            eventCountVCAlignmentHours = 0;
            eventCountProofOfValueHours = 0;
            eventCountConsultationHours = 0;
                
            
        }

        public String getFormattedARR()
        {
            if(totalARR != null)
            {
                return Decimal.valueOf(totalARR).format();
            }
            else
             return '0';
        }

        
        public String getAvgHoursPerEvent()
        {
            if(events.size() > 0 && totalEventHours > 0)
            {
                Double theVal = totalEventHours/events.size();
                Decimal theDecVal = Decimal.valueOf(theVal);
                theDecVal.setScale(2);
                return theDecVal.format();
            }            
            
            return '0';        
        }
        
        public String getAvgSCsPerEvent()
        {
            if(events.size() > 0 && totalSCCommitments > 0)
            {
                Double theVal = totalSCCommitments/events.size();
                Decimal theDecVal = Decimal.valueOf(theVal);
                theDecVal.setScale(2);
                return theDecVal.format();
            
            }
        
            return '0';
        }
    
    
        public void incrementEventCountByType(String eventType)
        {
            incrementEventCountByType(eventType,0,true);
        }

        public void incrementEventHoursByType(String eventType, Decimal hoursToAdd)
        {
            incrementEventCountByType(eventType, hoursToAdd,false);
        }
    
    
        public void incrementEventCountByType(String eventType, Decimal hoursToAdd, Boolean shouldIncrement)
        {
            if(eventType == 'Demonstration') 
            {  
              if(shouldIncrement) eventCountDemo++;
              eventCountDemoHours += hoursToAdd;
            }
            else if(eventType == 'Call') 
            {  
              if(shouldIncrement) eventCountCall++;
              eventCountCallHours += hoursToAdd;
            }
            else if(eventType == 'Discovery') 
            {  
              if(shouldIncrement) eventCountDiscovery++;
              eventCountDiscoveryHours += hoursToAdd;
            }
            else if(eventType == 'Installation') 
            {  
              if(shouldIncrement) eventCountInstallation++;
              eventCountInstallationHours += hoursToAdd;
            }
            else if(eventType == 'Post Sale Work') 
            {  
              if(shouldIncrement) eventCountPostSaleWork++;
              eventCountPostSaleWorkHours += hoursToAdd;
            }
            else if(eventType == 'Proof of Concept') 
            {  
              if(shouldIncrement) eventCountProofOfConcept++;
              eventCountProofOfConceptHours += hoursToAdd;
            }
            else if(eventType == 'RFI / RFP') 
            {  
              if(shouldIncrement) eventCountRFx++;
              eventCountRFxHours += hoursToAdd;
            }
            else if(eventType == 'Test Drive') 
            {  
              if(shouldIncrement) eventCountTestDrive++;
              eventCountTestDriveHours += hoursToAdd;
            }
            else if(eventType == 'Value Consulting Assessment') 
            {  
              if(shouldIncrement) eventCountVCAssessment++;
              eventCountVCAssessmentHours += hoursToAdd;
            }
            else if(eventType == 'Value Consulting Business Case') 
            {  
              if(shouldIncrement) eventCountVCBusinessCase++;
              eventCountVCBusinessCaseHours += hoursToAdd;
            }
            else if(eventType == 'Value Alignment') 
            {  
              if(shouldIncrement) eventCountVCAlignment++;
              eventCountVCAlignmentHours += hoursToAdd;
            }
            else if(eventType == 'Value Consulting Proof of Value') 
            {  
              if(shouldIncrement) eventCountProofOfValue++;
              eventCountProofOfValueHours += hoursToAdd;
            }
            else if(eventType == 'Value Consultation') 
            {  
              if(shouldIncrement) eventCountConsultation++;
              eventCountConsultationHours += hoursToAdd;
            }
            
        }
    
    }    
}