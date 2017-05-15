public with sharing class VC_Dash2Controller {

    public String MyRequestRangeAsString;
    public Integer MyRequestRangeAsInteger;
    
    public VC_Dash2Controller()
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


    public List< RequestWrapper > getTheFilteredList() {
        
        
        
        Date startDate = date.newinstance(MyRequestRangeAsInteger-1, 8, 1 );
        Date endDate = date.newinstance(MyRequestRangeAsInteger, 7, 31 );
        
        
        String[] vcRequestTypes = new String[]{'Dossier','Representative Case','Value Hypothesis','VITO Letter'};

        List<Sales_Support_Request__c> requestList = [SELECT Id, Name, Stage__c,Type__c,Target_Completion_Date__c, Actual_Completion_Date__c, 
                                                           Requested_For__c, Status__c, Hours__c, Create_Date__c, Assigned_To__c, Requested_Completion_Date__c,
                                                           Opportunity__r.Name, Opportunity__c , Opportunity__r.Region__c, Opportunity__r.Product_Type__c, Opportunity__r.Owner.Name, Opportunity__r.StageName,
                                                           Opportunity__r.Account.Name , Opportunity__r.Account.BillingCountry,
                                                           Account__r.Name, Account__c,Account__r.Owner.Name, Account__r.BillingCountry,
                                                           Campaign__r.Name, Campaign__c, Campaign__r.Region__c, Campaign__r.Owner.Name
                                                                                                
                                                   FROM Sales_Support_Request__c 
                                       WHERE ((Actual_Completion_Date__c >= :startDate AND Actual_Completion_Date__c <= :endDate AND Status__c = 'Completed' ) OR
                                              (Target_Completion_Date__c >= :startDate AND Target_Completion_Date__c <= :endDate AND Status__c = 'In Progress' ) OR
                                              (CreatedDate >= :startDate AND CreatedDate <= :endDate AND Target_Completion_Date__c = NULL AND Requested_Completion_Date__c = NULL AND Status__c = 'In Progress') OR
                                              (Requested_Completion_Date__c >= :startDate AND Requested_Completion_Date__c <= :endDate AND Status__c = 'Not Started') OR
                                              (CreatedDate >= :startDate AND CreatedDate <= :endDate AND Requested_Completion_Date__c = NULL AND Status__c = 'Not Started')
                                             ) AND 
                                             Type__c in : vcRequestTypes
                                         ];  //no need to order.  will sort the wrappers
                                             
        
        List<RequestWrapper> retval = new List<RequestWrapper>();               

        Set<Id> oppIds = new Set<Id>();
        Map<Id,Set<RequestWrapper>> theMap = new Map<Id, Set<RequestWrapper>>();


        for(Sales_Support_Request__c thisRequest : requestList)
        {
            RequestWrapper theWrapper = new RequestWrapper(thisRequest);
            retval.add(theWrapper);
            if(thisRequest.Opportunity__c != null)
            {
                oppIds.add(thisRequest.Opportunity__c);
                if(theMap.get(thisRequest.Opportunity__c) == null) theMap.put(thisRequest.Opportunity__c, new Set<RequestWrapper>());
                theMap.get(thisRequest.Opportunity__c).add(theWrapper);        
            }
        }
        System.Debug('**** Ids size  ' + oppIds.size());
        
        List<OpportunityHistory> theHistories = [SELECT StageName, OpportunityId, SystemModstamp From OpportunityHistory where OpportunityId in :oppIds];
        System.Debug('**** ' + theHistories.size());
        for(OpportunityHistory thisOne : theHistories)
        {
            Set< RequestWrapper > thisSet = theMap.get(thisOne.OpportunityId);
            for(RequestWrapper ew : thisSet)
            {                
                if(thisOne.SystemModstamp != null)             
                    ew.setResultDate(date.newinstance(thisOne.SystemModstamp.year(), thisOne.SystemModstamp.month(), thisOne.SystemModstamp.day() ));
            }
        }


        //sort the return results   
        retval.sort();             
        
        return retval;
    }
    
    
    public class RequestWrapper implements Comparable
    {
        Set<Integer> currentFiscalMonths = new Set<Integer> { 1, 2, 3, 4, 5, 6, 7 };

        public Sales_Support_Request__c theRequest {get; set;}
        public String ownerStr {get; set;}
        public String regionStr {get; set;}
        public String countryStr {get; set;}
        public Date requestDate {get; set;}
        public String requestQuarter {get; set;} 
        public String requestYear {get; set;} 

        public Date resultDateInternal;
        public String resultQuarter {get; set;} 
        public String resultYear {get; set;} 

        //calc time to complete
        //list of people?

        public RequestWrapper(Sales_Support_Request__c inputRequest)
        {            
            theRequest = inputRequest;
            countryStr = '';
            regionStr = '';   
            ownerStr = '';


            if(inputRequest.Actual_Completion_Date__c != null)
            {
                requestDate  = inputRequest.Actual_Completion_Date__c;
                requestYear = getFiscalYear(requestDate);
                requestQuarter = getFiscalQuarter(requestDate);        
            }
            else if(inputRequest.Target_Completion_Date__c != null)
            {
                requestDate  = inputRequest.Target_Completion_Date__c;
                requestYear = getFiscalYear(requestDate);
                requestQuarter = getFiscalQuarter(requestDate);        
            }
            else if(inputRequest.Requested_Completion_Date__c != null)
            {
                requestDate  = inputRequest.Requested_Completion_Date__c;
                requestYear = getFiscalYear(requestDate);
                requestQuarter = getFiscalQuarter(requestDate);        
            }

            if(inputRequest.Opportunity__c!= null && inputRequest.Opportunity__r.Region__c != null) regionStr = inputRequest.Opportunity__r.Region__c;
            else if(inputRequest.Campaign__c!= null && inputRequest.Campaign__r.Region__c != null) regionStr = inputRequest.Campaign__r.Region__c;
            
            if(inputRequest.Opportunity__c!= null && inputRequest.Opportunity__r.Account.BillingCountry != null) countryStr = inputRequest.Opportunity__r.Account.BillingCountry;
            else if( inputRequest.Account__c!= null && inputRequest.Account__r.BillingCountry != null) countryStr = inputRequest.Account__r.BillingCountry;
           
           
            if(inputRequest.Opportunity__c!= null) ownerStr = inputRequest.Opportunity__r.Owner.Name;
            else if(inputRequest.Account__c!= null) ownerStr = inputRequest.Account__r.Owner.Name;
            else if(inputRequest.Campaign__c!= null) ownerStr = inputRequest.Campaign__r.Owner.Name;
            
            
        }

        public String getRequestDateAsString()
        {
            if(requestDate == null) return '';
            return requestDate.format();
        }


        public String getResultDate()
        {
            if(resultDateInternal == null) return '';
            return resultDateInternal.format();
        }
        public void setResultDate (Date newDate)
        {
            if(ResultDateInternal == null || newDate > ResultDateInternal)
            {
                resultDateInternal = newDate;
                resultYear = getFiscalYear(ResultDateInternal);
                resultQuarter = getFiscalQuarter(ResultDateInternal);                                
            }
        
        }        


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

    
    // Compare requests based on the relevant date
    public Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        RequestWrapper compareToWrapper = (RequestWrapper)compareTo;
        
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        if(compareToWrapper.requestDate == null) return 1;
        else if(requestDate == null) return -1;
        
        if (requestDate > compareToWrapper.requestDate) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (requestDate  < compareToWrapper.requestDate) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }    
    
    }
 
   
}