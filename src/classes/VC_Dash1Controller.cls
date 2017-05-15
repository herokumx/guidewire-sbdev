public with sharing class VC_Dash1Controller {

    public String MyRequestRangeAsString;
    public Integer MyRequestRangeAsInteger;
    
    public VC_Dash1Controller()
    {
       setMyRequestRange('2014');
    }

    public String  getMyRequestRange()
    {
        return MyRequestRangeAsString;
    }

    public void setMyRequestRange(String newValue)
    {
       MyRequestRangeAsString = newValue;
       MyRequestRangeAsInteger = Integer.valueOf(MyRequestRangeAsString);
    }

    public void reloadPage()
    {
        

    }  


    public List< EventWrapper > getTheFilteredList() {
        
        
        
        Date startDate = date.newinstance(MyRequestRangeAsInteger-1, 8, 1 );
        Date endDate = date.newinstance(MyRequestRangeAsInteger, 7, 31 );
        
        
        String[] vcEventTypes = new String[]{'Value Consulting Assessment','Value Consulting Business Case','Value Alignment','Value Consulting Proof of Value','Value Consultation'};
        
        List<Sales_event__c> eventList = [SELECT Id, Name, Stage__c,Event_Type__c,Confirmed_End_Date__c, List_Of_People__c, Status__c, 
                                              Opportunity__r.Name, Opportunity__c, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c,
                                                 Opportunity__r.Fiscal_Period__c, Opportunity__r.FISCALYEAR, Opportunity__r.FISCALQUARTER, Opportunity__r.StageName,
                                              Opportunity__r.Account.Name , Opportunity__r.Account.BillingCountry
                                              //, Opportunity__r.OpportunityHistories
                                              //, (SELECT Histories.LastModifiedDate FROM Opportunity__r ORDER By Histories.LastModifiedDate DESC LIMIT 1 )
                                       FROM Sales_Event__c 
                                       //WHERE Opportunity__r.FISCALYEAR = :MyRequestRangeAsInteger AND
                                       WHERE (Confirmed_End_Date__c >= :startDate AND Confirmed_End_Date__c <= :endDate) AND 
                                             (Status__c = 'Completed' or Status__c = 'Confirmed') AND
                                             Event_Type__c in :vcEventTypes
                                       ORDER BY Confirmed_End_Date__c];
                                             
        
        Set<Id> oppIds = new Set<Id>();
        List<EventWrapper> retval = new List<EventWrapper>();
        Map<Id,Set<EventWrapper>> theMap = new Map<Id, Set<EventWrapper>>();
        for(Sales_Event__c thisEvent : eventList)
        {
            EventWrapper theWrapper = new EventWrapper(thisEvent);
            retval.add(theWrapper);
            oppIds.add(thisEvent.Opportunity__c);
            if(theMap.get(thisEvent.Opportunity__c) == null) theMap.put(thisEvent.Opportunity__c, new Set<EventWrapper>());
            theMap.get(thisEvent.Opportunity__c).add(theWrapper);
//            theMap.put(thisEvent.Opportunity__c, theWrapper);
        }
        System.Debug('**** Ids size  ' + oppIds.size());
        
        List<OpportunityHistory> theHistories = [SELECT StageName, OpportunityId, SystemModstamp From OpportunityHistory where OpportunityId in :oppIds];
        System.Debug('**** ' + theHistories.size());
        for(OpportunityHistory thisOne : theHistories)
        {
            Set<EventWrapper> thisSet = theMap.get(thisOne.OpportunityId);
            for(EventWrapper ew : thisSet)
            {
                
//                System.Debug('**** SysModStamp' + thisOne.SystemModstamp);
                if(thisOne.SystemModstamp != null)             
                //Preparation__c holder = new Preparation__c(Start__c = date.newinstance(thisOne.SystemModstamp.year(), thisOne.SystemModstamp.month(), thisOne.SystemModstamp.day() ));
//                holder.Start__c = );
//                    ew.setResultDate(holder.Start__c);
//  MATT
                    ew.setResultDate(date.newinstance(thisOne.SystemModstamp.year(), thisOne.SystemModstamp.month(), thisOne.SystemModstamp.day() ));
//                theMap.put(thisOne.OpportunityId, ew);
            }
        }
                
        
        return retval;
    }
    
    
 
    public class EventWrapper
    {
        Set<Integer> currentFiscalMonths = new Set<Integer> { 1, 2, 3, 4, 5, 6, 7 };
    
        public EventWrapper(Sales_Event__c inputEvent)
        {
            theEvent = inputEvent;
            if(theEvent.Confirmed_End_Date__c != null)
            {              
                EventDate = theEvent.Confirmed_End_Date__c;
                EventYear = getFiscalYear(EventDate);
                EventQuarter = getFiscalQuarter(EventDate);
            }
            
        }
    
        public Sales_Event__c theEvent {get; set;} 
        public Date EventDate {get; set;} 
        public String EventQuarter {get; set;} 
        public String EventYear {get; set;} 
        public Date ResultDateInternal;
        public String getResultDate()
        {
            if(ResultDateInternal == null) return '';
            return ResultDateInternal.format();
        }
        public void setResultDate (Date newDate)
        {
            if(ResultDateInternal == null || newDate > ResultDateInternal)
            {
                ResultDateInternal = newDate;
                ResultYear = getFiscalYear(ResultDateInternal);
                ResultQuarter = getFiscalQuarter(ResultDateInternal);                                
            }
        
        }        
        public String ResultQuarter {get; set;} 
        public String ResultYear {get; set;} 
        
        public String getFiscalYear(Date inputDate)
        {
                String retval = String.valueOf(inputDate.year());
                Integer month = inputDate.month();
                if(!currentFiscalMonths.contains(month))
                {
                    retval = String.valueOf(inputDate.year()+1);
                }
                return retval;
        
        }
        
        public String getFiscalQuarter(Date inputDate)
        {
                Integer month = inputDate.month();
                String retval = 'Q4';
                //now determine quarter
                if(month == 8 || month == 9 || month == 10) retval = 'Q1';                 
                else if(month == 11 || month == 12 || month == 1) retval = 'Q2';                 
                else if(month == 2 || month == 3 || month == 4) retval = 'Q3';         
                
                return retval;                
        }
    
    }
   
}