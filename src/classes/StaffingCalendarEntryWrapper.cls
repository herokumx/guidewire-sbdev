global class StaffingCalendarEntryWrapper implements Comparable {

    public Sales_Event__c event;
    public Project_Event__c projectEvent;
    public ResourceRequest__c request;
    public Sales_Support_Request__c supportRequest;
    public Date compareDate;
    
    // Constructor for sales events
    public StaffingCalendarEntryWrapper (Sales_Event__c inputEvent) {
        event = inputEvent;
        //need to find the right date to compare
        if(inputEvent.event_type__c == 'RFI / RFP')
        {
            //System.Debug('Looking at event that is RFP.  Internal date: ' + inputEvent.RFx_internal_due__c);
            //use the internal due date
            compareDate = inputEvent.RFx_internal_due__c;
        }
        else  //use confirmed date, otherwise first 
        {
            //System.Debug('Looking at event that is not RFP.'  );
            if(inputEvent.Status__c == 'Confirmed' || inputEvent.Status__c == 'Completed' )
            {
                //System.Debug('Looking at event that is non-rfp confirmed.  date: ' + inputEvent.Confirmed_Start_Date__c.date());
                compareDate = inputEvent.Confirmed_Start_Date__c;
                                
            }
            else
            {
                for(Event_Possible_Date__c pDate: inputEvent.Possible_Dates__r)
                {
                    if(compareDate == null || (pDate.Start_Date__c != null && compareDate > pDate.Start_Date__c))
                        compareDate = pDate.Start_Date__c;
                }
                //System.Debug('Looking at event that is non-rfp with possibles ('+inputEvent.Possible_Dates__r.size()+').  date: ' + compareDate );
            }
        }
    }

    // Constructor for project events
    public StaffingCalendarEntryWrapper (Project_Event__c inputEvent) {
        projectEvent = inputEvent;
        //need to find the right date to compare
            //System.Debug('Looking at event that is not RFP.'  );
            if(inputEvent.Status__c == 'Confirmed' || inputEvent.Status__c == 'Completed' )
            {
                //System.Debug('Looking at event that is non-rfp confirmed.  date: ' + inputEvent.Confirmed_Start_Date__c.date());
                compareDate = inputEvent.Confirmed_Start_Date__c;
                                
            }
            else
            {
                for(Project_Event_Possible_Date__c pDate: inputEvent.Possible_Dates__r)
                {
                    if(compareDate == null || (pDate.Start_Date__c != null && compareDate > pDate.Start_Date__c))
                        compareDate = pDate.Start_Date__c;
                }
                //System.Debug('Looking at event that is non-rfp with possibles ('+inputEvent.Possible_Dates__r.size()+').  date: ' + compareDate );
            }
    }
    
    // Constructor for resource request
    public StaffingCalendarEntryWrapper (ResourceRequest__c inputRequest) {
        request = inputRequest;
        //let's determing the relevant date
        if(inputRequest.event_type__c == 'RFI / RFP')
        {
            //System.Debug('Looking at resource request that is RFP.  Internal date: ' + inputRequest.RFx_internal_due__c);
            //use the internal due date
            compareDate = inputRequest.RFx_internal_due__c;
        }
        else  //use confirmed date, otherwise first 
        {
            //System.Debug('Looking at resource request that is not RFP.  Total possible dates: ' + inputRequest.Possible_Dates__r.size());
            for(Possible_Date__c pDate: inputRequest.Possible_Dates__r)
            {
                //System.Debug('Looking at resource request possible date : ' + pDate.Id);
                if(pDate.Status__c == 'Possible' || pDate.Status__c == 'Selected')
                {
                    //System.Debug('Looking at resource request possible date of: ' + pDate.Start_Date__c.date());
                    if(compareDate == null || (pDate.Start_Date__c != null && compareDate > pDate.Start_Date__c))
                        compareDate = pDate.Start_Date__c;
                    
                }
                if(pDate.Status__c == 'Selected') break;
            }
        }        
    }
    
    public StaffingCalendarEntryWrapper (Sales_Support_Request__c inputSRequest) {
       supportRequest = inputSRequest;
       //let's determine the relevant date
       if(inputSRequest.Actual_Completion_Date__c != null) compareDate = inputSRequest.Actual_Completion_Date__c;
       else if(inputSRequest.Target_Completion_Date__c != null) compareDate = inputSRequest.Target_Completion_Date__c;
       else if(inputSRequest.Requested_Completion_Date__c != null) compareDate = inputSRequest.Requested_Completion_Date__c;
       else compareDate = inputSRequest.Create_Date__c.addMonths(1);
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        StaffingCalendarEntryWrapper compareToWrapper = (StaffingCalendarEntryWrapper)compareTo;
        
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        
        if (compareDate > compareToWrapper.compareDate) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (compareDate  < compareToWrapper.compareDate) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}