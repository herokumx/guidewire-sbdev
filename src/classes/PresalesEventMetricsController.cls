public without sharing class PresalesEventMetricsController {

    public String reloadPage { get; set; }


    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public String startYear {get;set;}
    public String startMonth {get;set;}
    public Integer monthCount {get;set;}

    public String eventTypeFilter {get;set;}
    public String regionFilter {get;set;}

    
    public Date Now {get { return Date.today();}}
    public String ThisYear {get { return String.valueOf(Date.today().year());} }
    
    public List<String> monthlyLabels {get; set;} 
    public List<Map<String,String>> theMaps  { get;set;}
    
    public Map<Date, MonthlyMetrics> monthlyMetricsMap { get;set;}

    
    public PresalesEventMetricsController ()
    {
        startDate = Date.today().addMonths(-1).toStartOfMonth();
        
        startYear = String.valueOf(startDate.year());
        startMonth = String.valueOf(startDate.month());
        
        eventTypeFilter='Presales';
        regionFilter= UserRegionHelper.getCurrentUserDefaultRegion();
        
        monthCount = 4;

        endDate = startDate.addMonths(monthCount + 1);  //add an extra month so we can do less than below
        
        monthlyLabels = new List<String> ();
        theMaps = new List<Map<String,String>>();        
        monthlyMetricsMap = new Map<Date, MonthlyMetrics>(); 
        
        //if perf becomes an issue, let's turn this off
        reloadPage();              
    }

    public void reloadPage()
    {
        //figure out which month to start with
        startDate = Date.newInstance(Integer.valueOf(startYear),Integer.valueOf(startMonth),1 );

        monthlyLabels = new List<String> ();
        theMaps = new List<Map<String,String>>();        
        monthlyMetricsMap = new Map<Date, MonthlyMetrics>();

        endDate = startDate.addMonths(monthCount + 1);  //add an extra month so we can do less than below


        //create and add the header
        monthlyLabels.add('');

        Map<String,String> oppCountMap = new Map<String,String>();
        oppCountMap.put('', 'Opportunities');

        Map<String,String> oppARRMap = new Map<String,String>();
        oppARRMap.put('', 'ARR');

        Map<String,String> eventCountMap = new Map<String,String>();
        eventCountMap .put('', 'Events');
        
        Map<String,String> scsPerEventCountMap = new Map<String,String>();
        scsPerEventCountMap .put('', '&nbsp;&nbsp;&nbsp;&nbsp;Avg. SCs/Event');
        
        Map<String,String> hoursPerEventCountMap = new Map<String,String>();
        hoursPerEventCountMap .put('', '&nbsp;&nbsp;&nbsp;&nbsp;Avg. Hours/Event');

        Map<String,String> rfpCountMap = new Map<String,String>();
        rfpCountMap .put('', 'RFPs');

        Map<String,String> vcCountMap = new Map<String,String>();
        vcCountMap .put('', 'VC Workshops');

        //HERE IS WHERE WE CALCULATE THE INFORMATION
        List<Sales_Event__c> theEvents;
        if(regionFilter == 'Global')
        {
        
            theEvents = [SELECT Id, Confirmed_Start_Date__c, Name, Event_Type__c,Event_Hours__c, Status__c,
                                                     Opportunity__r.Name, Opportunity__r.Id,Opportunity__r.Amount,Opportunity__r.Region__c,
                                                     (SELECT Who__c, Coverage_Area__c FROM Customer_Commitments__r)
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
            theEvents = [SELECT Id, Confirmed_Start_Date__c, Name, Event_Type__c,Event_Hours__c, Status__c,
                                                     Opportunity__r.Name, Opportunity__r.Id,Opportunity__r.Amount,Opportunity__r.Region__c,
                                                     (SELECT Who__c, Coverage_Area__c FROM Customer_Commitments__r)
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
            if(eventTypeFilter == 'Sales Consulting' && (thisEvent.Event_Type__c == 'Value Consulting Assessment' 
                                                     || thisEvent.Event_Type__c == 'Value Workshop'
                                                     || thisEvent.Event_Type__c == 'Value Workshop Follow Up'
                                                     || thisEvent.Event_Type__c == 'Value Alignment'
                                                     || thisEvent.Event_Type__c == 'Value Tracking'
                                                     || thisEvent.Event_Type__c == 'Value Consultation')
                                                      ) continue;
            if(eventTypeFilter == 'Value Consulting' && !(thisEvent.Event_Type__c == 'Value Consulting Assessment' 
                                                     || thisEvent.Event_Type__c == 'Value Workshop'
                                                     || thisEvent.Event_Type__c == 'Value Workshop Follow Up'
                                                     || thisEvent.Event_Type__c == 'Value Alignment'
                                                     || thisEvent.Event_Type__c == 'Value Tracking'
                                                     || thisEvent.Event_Type__c == 'Value Consultation')
                                                      ) continue;
        
        
            Date theEventStart = thisEvent.Confirmed_Start_Date__c.toStartOfMonth();
            //check the map to see if there is already a metric object for this date
            MonthlyMetrics thisMonthsMetrics =  monthlyMetricsMap.get(theEventStart);
            //if not, create a new one
            if(thisMonthsMetrics == null) thisMonthsMetrics = new MonthlyMetrics(theEventStart);
        
            //update the metrics for this month with this event
            thisMonthsMetrics.opportunities.add(thisEvent.Opportunity__r.Id);
            
            //MATT TODO:  Add ARR HERE
            if(thisEvent.Opportunity__r.Amount != null)
                thisMonthsMetrics.totalARR += thisEvent.Opportunity__r.Amount;
            
            if(thisEvent.Event_Type__c == 'RFI / RFP')
            {
                thisMonthsMetrics.rfps.add(thisEvent.Id);
            }
            else if(thisEvent.Event_Type__c == 'Value Consulting Assessment' 
                                                     || thisEvent.Event_Type__c == 'Value Workshop'
                                                     || thisEvent.Event_Type__c == 'Value Workshop Follow Up'
                                                     || thisEvent.Event_Type__c == 'Value Alignment'
                                                     || thisEvent.Event_Type__c == 'Value Tracking'
                                                     || thisEvent.Event_Type__c == 'Value Consultation')
            {
                thisMonthsMetrics.vcevents.add(thisEvent.Id);            
            }
            else
            {
                thisMonthsMetrics.events.add(thisEvent.Id); 
                
                //if here, examime the resources being used and the hours
                   
                //add to total event hours  
                if(thisEvent.Event_Hours__c != null && thisEvent.Event_Hours__c > 0)
                    thisMonthsMetrics.totalEventHours += thisEvent.Event_Hours__c ;
                    
                //now figure out how many people participated
                
                for(Customer_Commitment__c thisCommitment : thisEvent.Customer_Commitments__r)
                {
                    if(thisCommitment.Coverage_Area__c != 'Shadow' && thisCommitment.Coverage_Area__c != 'Observation')
                    {
                        thisMonthsMetrics.totalSCCommitments++;                    
                    }
                }
                
            }
            //add this to the map 
            monthlyMetricsMap.put(theEventStart, thisMonthsMetrics);
        }
        
        
        
        for(Integer i = 0; i< monthCount; i++)
        {
            Date theNewDate =  startDate.addMonths(i);     
            String thisLabel = DateTime.newInstance(theNewDate,Time.newInstance(18, 30, 2, 20)).format('MMM yy');
            monthlyLabels.add(thisLabel);
            
            //get the holder for this month
            MonthlyMetrics mmetrics = monthlyMetricsMap.get(theNewDate);
            
            if(mmetrics != null)
            {
                oppCountMap.put(thisLabel, String.valueOf(mmetrics.opportunities.size()));
                oppARRMap.put(thisLabel, mmetrics.getFormattedARR());
                eventCountMap.put(thisLabel, String.valueOf(mmetrics.events.size()));
                hoursPerEventCountMap .put(thisLabel, String.valueOf(mmetrics.getAvgHoursPerEvent()) );
                scsPerEventCountMap .put(thisLabel, String.valueOf(mmetrics.getAvgSCsPerEvent()));
                rfpCountMap.put(thisLabel, String.valueOf(mmetrics.rfps.size()));                
                vcCountMap.put(thisLabel, String.valueOf(mmetrics.vcevents.size()));                
            
            }
            else
            {
                oppCountMap.put(thisLabel, '-');
                oppARRMap.put(thisLabel, '-');
                eventCountMap.put(thisLabel, '-');
                hoursPerEventCountMap .put(thisLabel, '-');
                scsPerEventCountMap .put(thisLabel, '-');
                rfpCountMap.put(thisLabel, '-');                
                vcCountMap.put(thisLabel, '-');                
            }
            
            
            
        }


        theMaps.add(oppCountMap);
        theMaps.add(oppARRMap);
        theMaps.add(eventCountMap);
        theMaps.add(hoursPerEventCountMap );
        theMaps.add(scsPerEventCountMap );
        theMaps.add(rfpCountMap);
        theMaps.add(vcCountMap);

    
    }
    
    
    public Class MonthlyMetrics
    {
        public Date thisMonth;
        
        public Set<Id> opportunities;
        
        public Double totalARR;
        public Double totalEventHours;
        public Double totalSCCommitments;
        
        public Set<Id> events;
        public Set<Id> rfps;
        public Set<Id> vcevents;
        
        
        public MonthlyMetrics(Date theMonth)
        {
            thisMonth = theMonth;
            totalARR = 0;
            totalEventHours = 0;
            totalSCCommitments = 0;
            
            opportunities = new Set<Id>();
            events = new Set<Id>();
            vcevents = new Set<Id>();
            rfps = new Set<Id>();
            
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
    
    
    }
    

}