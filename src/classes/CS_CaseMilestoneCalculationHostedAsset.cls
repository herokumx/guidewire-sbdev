/*
******************************************************************************************************************************
Controller Class Name- CS_CaseMilestoneCalculationHostedAsset
Object - Case 
Purpose- Controller for Case Email VF
*****************************************************************************************************************************

Name            Email              Date         Notes 
Mani G                                     Initial Creation,Calcualtes Milestone mins based on Entitlement's Business Hours

Assumption: Business Start Date and End Date is hard coded to be 8 AM to 6 PM for each time zone. And Case's Entitlement Business Hours
            is expected to have set as 24x7.
Mani G                           09/29/2016   Modifed the Calculation Start Date from Case Created Date to System Date& Time 
Mani G                           10/19/2016   fixed for INC0063512 - Mielstones Completing on Friday were not calculating correctly
*****************************************************************************************************************************
*/


global class CS_CaseMilestoneCalculationHostedAsset implements Support.MilestoneTriggerTimeCalculator
{
    Boolean set8AM = false;
    string defaultTimezone = 'GMT';
    Integer holidays = 0;
    Integer weekends = 0;
    Integer weekdays = 0;
    Integer startTimeHours = 0;
    Integer startTimeMinutes = 0;
    
    Integer endTimeHours = 0;
    Integer endTimeMinutes = 0;
    //string exceptionEmail;
    //string defaultExceptionEmail;
    
    // Method to be implemented to calculate milestone mins
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId)
    {
        return customMilestoneCalculation(caseId, milestoneTypeId, false);
    }
    
    public Integer customMilestoneCalculation(String caseId, String milestoneTypeId, Boolean logEvents)
    {
        system.debug('############### Milestone Type is:  ' + milestoneTypeId);
        Case c;
        MilestoneType mt;
        try
        {
            // query case details and milestone details
            c = [Select CaseNumber, Entitlement.BusinessHoursId, Entitlement.SlaProcess.Name,
                                Entitlement.BusinessHours.TimeZoneSidKey, CreatedDate, Severity__c from Case 
                                where Id = :caseId];
            mt = [Select Name from MilestoneType where Id = :milestoneTypeId];
            
            Support_Business_Hours__c bizHrs = [SELECT Business_Hours_End_mm__c,Business_Hours_End__c,Business_Hours_Start_mm__c,Business_Hours_Start__c,Type_of_support__c FROM Support_Business_Hours__c where Type_of_support__c = 'Hosted Asset' ];
            
            startTimeHours = bizHrs.Business_Hours_Start__c.intValue();
            startTimeMinutes = bizHrs.Business_Hours_Start_mm__c.intValue();
            endTimeHours = bizHrs.Business_Hours_End__c.intValue();
            endTimeMinutes = bizHrs.Business_Hours_End_mm__c.intValue();
            
            system.debug('Business Hours are : ' + startTimeHours + ':' + startTimeMinutes + '  TO ' + endTimeHours + ':' + endTimeMinutes );
            
            system.debug('############### c.Entitlement.BusinessHours.TimeZoneSidKey  ' + c.Entitlement.BusinessHours.TimeZoneSidKey);
            
            // get time zone
            string timezone = (c.Entitlement.BusinessHours.TimeZoneSidKey != null 
                                    ? c.Entitlement.BusinessHours.TimeZoneSidKey 
                                        : defaultTimezone);
            if(logEvents)
                logEvent('Case Timezone: ' + timezone);
            
            // calculate local start date (local to entitlement's business hours time zone
            //DateTime lStartDate = convertToTimeZone(c.CreatedDate, timezone);
            DateTime lStartDate = convertToTimeZone(System.now(), timezone);
            system.debug('########## RP : Customer Case Created Time: ' + lStartDate);
            if(logEvents)
                logEvent('Customer Case Created Time: ' + lStartDate);
            
            // calculate next business start date
            DateTime businessStartDate = getBusinessStartDate(lStartDate, c.Entitlement.BusinessHoursId, 
                                                                timezone);
                                                                
            system.debug('############### businessStartDate  ' + businessStartDate + '   Does Lstart date change ? : ' + lStartDate);
            if(logEvents)
                logEvent('Milestone Calculation Start Date: ' + businessStartDate);
            
            // Get duration for the Case severity and milestone name
            Integer duration = getDuration(c.Entitlement.SlaProcess.Name, 
                                            mt.Name, c.Severity__c);
            system.debug('Milestone Duration for ' + c.Severity__c + ': ' + duration + ' days');
            
            if(logEvents){
                logEvent('Milestone Duration for ' + c.Severity__c + ': ' + duration + ' days');
                //logEvent('------------------------------------------');
            }
            
            // calcualte business end date
            DateTime businessEndDate = getBusinessEndDate(businessStartDate, duration, c.Entitlement.BusinessHoursId, 
                                                                timezone, logEvents);
            if(logEvents){
                logEvent('No of Weekdays: ' + Weekdays);
                logEvent('No of Weekends: ' + Weekends);
                logEvent('No of Holidays: ' + Holidays);
                logEvent('Target Date in ' + timezone + ': ' + businessEndDate);
                //logEvent('-----------------------------------------');
            }
            
            if(holidays > 0)
            {
                Integer h = holidays - (holidays * 2);
                businessEndDate = businessEndDate.addDays(h);
            }
            // calculate milestone mins (Commented code is what is in the class for std support milestone
            Integer milestoneMins = getMilestoneMins(lStartDate, businessEndDate);
            system.debug('******** lStartDate   ' + lStartDate + '    ********** businessStartDate ' + businessStartDate + ' ************ businessEndDate ' + businessEndDate);
            // Integer milestoneMins = getMilestoneMins(lStartDate, businessStartDate) + getMilestoneMins(businessStartDate, businessEndDate);
            if(logEvents)
                logEvent('Milestone Mins: ' + milestoneMins);
            
            return milestoneMins;
        }
        catch(Exception e)
        {
            system.debug('Exception occurred: ' + e.getMessage());
            CS_ExceptionHandler.createErrorRecord('Custom Milestone Mins Calculation Error. Line Number: ' + e.getLineNumber() + '. Error Message: ' + e.getMessage(), caseId);
            // on exception, return default mins
            return (getDefaultDuration() * 10 * 60); 
        }
    }
    
    // subtracts business end date from local start date to get milestone mins
    private Integer getMilestoneMins(DateTime bStartDate, DateTime bEndDate)
    {
        Long actualInterval = bEndDate.getTime() - bStartDate.getTime();
        return (Integer)(actualInterval/(1000 * 60));
    }
    
    // get duration from CS_Milestone_Business_Hours__c custom settings
    private Integer getDuration(String entitlementProcessName, string milestoneName, string severity)
    {
        List<CS_Milestone_Business_Hours__c> cmList = CS_Milestone_Business_Hours__c.getall().values();



        Integer bizDays = 1;

        for(CS_Milestone_Business_Hours__c cm : cmList){

            if(cm.CS_Entitlement_Process_Name__c == entitlementProcessName && cm.CS_Milestone_Name__c == milestoneName && cm.CS_Severity__c == severity)
            bizDays = (Integer)cm.CS_Business_Days__c;
        }

        return bizDays;
    }
    
    // query default duration if any error occured
    private Integer getDefaultDuration()
    {
        // CS_Milestone_Business_Hours__c cm = [Select CS_Business_Days__c from CS_Milestone_Business_Hours__c
                                                        // where CS_Entitlement_Process_Name__c = 'Default'];
        List<CS_Milestone_Business_Hours__c> cmList = CS_Milestone_Business_Hours__c.getall().values();



        Integer bizDays = 1;

        for(CS_Milestone_Business_Hours__c cm : cmList){

            if(cm.CS_Entitlement_Process_Name__c == 'Default')
            bizDays = (Integer)cm.CS_Business_Days__c;
        }

        //defaultExceptionEmail = cm.CS_Exception_Email__c;
        return bizDays;
    }
    
    // Calculate next business start date
    // - if created within business hours, return the same
    // - if created in weekend or holiday or outside business hours (But in the evening through 12AM), return the next business start date time
    private DateTime getBusinessStartDate(DateTime lStartDate, Id businessHoursId, string timezoneKey)
    {
        Integer i = 0;
        
        // This loop expects Business Hours always to be 24x7. Otherwise, this loop would end up in CPU Time Limit
        while(i >= 0)
        {
            lStartDate = lStartDate.addDays(i);
            system.debug('#### RP Holiday' + isHoliday(lStartDate, businessHoursId)+ ':  RP Weekend   ' + isWeekend(lStartDate, timezoneKey) + ' ||  StartDate' + lStartDate);
            if(!isHoliday(lStartDate, businessHoursId)
              && !isWeekend(lStartDate, timezoneKey))
            {
                if(!set8AM)
                {
                    system.debug('########### Hour GMT : ' + lStartDate.hourGmt());
                    if(lStartDate.hourGmt() >= startTimeHours && (lStartDate.hourGmt() < endTimeHours || (lStartDate.hourGmt() == endTimeHours && lStartDate.minuteGmt() == endTimeMinutes))){
                        lStartDate = DateTime.newInstanceGmt(lStartDate.yearGmt(), lStartDate.monthGmt(), lStartDate.DayGmt() + 1, 
                                                            startTimeHours, startTimeMinutes, 0);
                        set8AM = true;
                        break;
                    }
                    else if(lStartDate.hourGmt() < startTimeHours)
                    {
                        lStartDate = DateTime.newInstanceGmt(lStartDate.yearGmt(), lStartDate.monthGmt(), lStartDate.DayGmt(), 
                                                            startTimeHours, startTimeMinutes, 0);
                        set8AM = true;
                        break;
                    }
                    else if(lStartDate.hourGmt() >= endTimeHours)
                    {
                        lStartDate = DateTime.newInstanceGmt(lStartDate.yearGmt(), lStartDate.monthGmt(), lStartDate.DayGmt() + 1, 
                                                            startTimeHours, startTimeMinutes, 0);
                        set8AM = true;
                        break;
                    }
                }
                else
                {
                    lStartDate = DateTime.newInstanceGmt(lStartDate.yearGmt(), lStartDate.monthGmt(), lStartDate.DayGmt(), 
                                                            startTimeHours, startTimeMinutes, 0);
                    break;
                }
            }
            else
            {
                i = 1;
                set8AM = true;
            }
        }
        
        return lStartDate;
    }
    
    // Calculates the end date time by skipping any weekends or holidays
    private DateTime getBusinessEndDate(DateTime lStartDate, Integer duration, Id businessHoursId, string timezoneKey, boolean logEvents)
    {
        Integer i = 1;
        DateTime lEndDate;
        DateTime tempDate = lStartDate;
        while(i <= duration)
        {
            if(i == duration)
            {
                if(set8AM)
                {
                    // tempDate = tempDate.addHours(9);
                    tempDate = DateTime.newInstanceGmt(tempDate.yearGmt(), tempDate.monthGmt(), tempDate.DayGmt(), 
                                                            endTimeHours, endTimeMinutes, 0);
                }
                else
                {
                    tempDate = tempDate.addDays(1);
                    tempDate = DateTime.newInstanceGmt(tempDate.yearGmt(), tempDate.monthGmt(), tempDate.DayGmt(), 
                                                            endTimeHours, endTimeMinutes, 0);
                }
            }
            else
            {
                tempDate = tempDate.addDays(1);
                tempDate = DateTime.newInstanceGmt(tempDate.yearGmt(), tempDate.monthGmt(), tempDate.DayGmt(), 
                                                            endTimeHours, endTimeMinutes, 0);
                
            }
            
            if(!isHoliday(tempDate, businessHoursId)
              && 
              !isWeekend(tempDate, timezoneKey))
            {
                /*if(logEvents)
                {
                    logEvent(tempDate + ' is a weekday');
                }*/
                weekdays++;
                lEndDate = tempDate;
                i++;
            }
            else
            {
                tempDate = tempDate.addDays(1);
                i = 1;
                /*if(logEvents)
                {
                    logEvent(tempDate + ' is either a weekend or holiday');
                }*/
            }
        }
        system.debug('########### lEndDate : ' + lEndDate);
        return lEndDate;
    }
    
    // return if a date is weekend with respect to the specific time zone
    private boolean isWeekend(DateTime lStartDate, string timezoneKey)
    {
        boolean isWeekend = false;
        set<String> weekendDays = new set<String>{'Saturday', 'Sunday'};
        //INC0063512
        if(weekendDays.contains(lStartDate.formatGMT('EEEE')))
        {
            weekends++;
            return true;
        }
        else
            return false;
    }
    
    // return if a date is holiday with respect to the specific time zone
    private boolean isHoliday(DateTime lStartDate, Id businessHoursId)
    {
        if(!BusinessHours.isWithin(businessHoursId, lStartDate))
        {
            holidays++;
            return true;
        }
        else
        {
            return false;
        }
        
    }
    
    // convert created date to local time for the specific timezone key
    public DateTime convertToTimeZone(DateTime sd, string timezoneKey)
    {    
        string localSD = sd.format('MM/dd/yyyy HH:mm:ss', timeZoneKey);
        List<string> strList = localSD.split(' ');
        List<string> lDate = strList[0].split('/');
        List<string> lTime = strList[1].split(':');
        DateTime converted = DateTime.newInstanceGmt(Integer.valueOf(lDate[2]), 
                                        Integer.valueOf(lDate[0]), 
                                        Integer.valueOf(lDate[1]), 
                                        Integer.valueOf(lTime[0]), 
                                        Integer.valueOf(lTime[1]), 
                                        Integer.valueOf(lTime[2]));
                                        
        system.debug('################# Debug convertedTimeZone date : ' + converted);
        return DateTime.newInstanceGmt(Integer.valueOf(lDate[2]), 
                                        Integer.valueOf(lDate[0]), 
                                        Integer.valueOf(lDate[1]), 
                                        Integer.valueOf(lTime[0]), 
                                        Integer.valueOf(lTime[1]), 
                                        Integer.valueOf(lTime[2]));
    }
    
    private void logEvent(string msg)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg));
    }
}