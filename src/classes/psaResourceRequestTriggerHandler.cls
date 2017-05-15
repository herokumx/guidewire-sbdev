/**************************************************************************************
// Name          : psaResourceRequestTriggerHandler
// Date          : March 4, 2015
// Description   : Handles all inserts/updates/deletes called by the psaResourceRequest trigger
// Author        : CLD Partners 
// Revisions     : 2015-03-04  Initial version
//               : 2015-05-14  Spano updated documentation
//               : 2015-07-01  Mayfield Added some checking of RR values to see if  hours needed 
//                              to be recalculated, checking to see if set had values
//                              before executing SOQL in updateResourceRequestEvARecords
//               : 2015-07-30  Klassen Major code update to exclude the holiday hours from the code that
//                              creates/updates Est. Vs. Actuals (EVAs) based on the start/end dates of the
//                              related Resource Request (parent)
//               : 2015-10-27  Klassen Updated code to use the new RR start/end dates rather than the old
//                              start/end dates which were originally taken from a soql query that didn't
//                              have the updated start/end dates yet
//               : 2016-07-13  Hari updated the class to delete Forecast details when a resource request is deleted.
//                             Added this method:  deleteResourceRequestForecastDetailRecords
***************************************************************************************/
public with sharing class psaResourceRequestTriggerHandler implements psaITriggerHandler {

    Map<Id, Map<String, List<psaRateLookup>>> rateBucket = new Map<Id, Map<String, List<psaRateLookup>>>();
    Date rangeStartDate = null;
    Date rangeEndDate  = null;
    Map<Id, pse__Proj__c> projectMap = new Map<Id, pse__Proj__c>();
    List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
    Boolean needRateLookup = false;

    //added by cklassen 7/30 to centralize working hours calculations
    Map<Id, pse__Work_Calendar__c> regionToWorkCalendarMap = new Map<Id, pse__Work_Calendar__c>();  
    Map<Id, Map<Id, pse__HolidayObj__c>> workCalendarToHolidayMap = new Map<Id, Map<Id, pse__HolidayObj__c>>();

    public psaResourceRequestTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore() {

        if(Trigger.isInsert || Trigger.isUpdate) {

            List<String> currencies = new List<String>();
            List<pse__Resource_Request__c> resourceRequestsOnWhichToCalcHours = new List<pse__Resource_Request__c>();
                    
            Set<Id> account_ids = new Set<Id>();
            Set<Id> project_ids = new Set<Id>();
            for(SObject so : Trigger.new) {
                pse__Resource_Request__c req = (pse__Resource_Request__c)so;

                // Rate and Rate Cards Code...
                currencies.add(req.currencyIsoCode);
                if(req.pse__Account__c != null) {
                    account_ids.add(req.pse__AccountId__c);
                }
                if(req.pse__Project__c != null){
                    project_ids.add(req.pse__Project__c);
                }
                
                if(Trigger.isUpdate) {
                    //Get old RR
                    pse__Resource_Request__c reqOld = (pse__Resource_Request__c)Trigger.oldMap.get(req.Id);
                    
                    // Determine if RR Requested Hours needs to be calculated
                    if ((req.pse__Start_Date__c != reqOld.pse__Start_Date__c) || 
                        (req.pse__End_Date__c != reqOld.pse__End_Date__c) || 
                        (req.pse__Percent_Allocated__c != reqOld.pse__Percent_Allocated__c) || 
                        (req.Override_Requested_Hours_Calc__c == false && reqOld.Override_Requested_Hours_Calc__c == true)){
                        resourceRequestsOnWhichToCalcHours.add(req);
                    }

                    // Determine if Rates need to be looked up
                    Boolean isAssigned = (req.pse__Status__c == 'Assigned');
                    Boolean isCanceled = (req.pse__Status__c == 'Canceled');
                    Boolean hasBillLevelChanged = (reqOld.PSA_Billing_Level__c != req.PSA_Billing_Level__c);
                    Boolean hasStartDateChanged = (reqOld.pse__Start_Date__c != req.pse__Start_Date__c);
                    Boolean hasEndDateChanged = (reqOld.pse__End_Date__c != req.pse__End_Date__c);
                    if(!isAssigned && !isCanceled){
                        if(hasBillLevelChanged || hasStartDateChanged || hasEndDateChanged){
                            needRateLookup = true;
                        }
                    }
                }
                
                if(Trigger.isInsert){
                    needRateLookup = true;
                    if(req.Override_Requested_Hours_Calc__c == false) {
                        resourceRequestsOnWhichToCalcHours.add(req);
                    }
                }
            }

            if(needRateLookup == true) {
                rateBucket  = psaRateSetUtils.setRateBucket(account_ids, project_ids, currencies);
                System.debug('The rate bucket is: '+rateBucket);
                projectMap = new Map<Id, pse__Proj__c>([SELECT id, pse__Project_Type__c, psa_Project_Rate_Set__c, psa_Account_Rate_Set__c from pse__Proj__c where id in :project_ids]);
            }
            
            if(resourceRequestsOnWhichToCalcHours != null && resourceRequestsOnWhichToCalcHours.size() > 0) {
                calculateResourceRequestHours(resourceRequestsOnWhichToCalcHours); 
            }
              
        }

        // Before Update: Update Est vs Actuals records.
        // Note: this is done after the calculation of resource request hours call above because those
        // calculated hours are needed for the EvA hours calculation
        if(Trigger.isUpdate) {
            updateResourceRequestEvARecords(Trigger.new, Trigger.oldMap);
        }

        // Before Delete: Delete related Est vs Actuals records
        if(Trigger.isDelete) {
            deleteResourceRequestEvARecords(Trigger.old);
            deleteResourceRequestForecastDetailRecords(Trigger.old);
        }
    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter() {
        // After Insert: Create Est vs Actuals records.
        if(trigger.isInsert) {
            createResourceRequestEvARecords(Trigger.new);
        }

        // After Update: Populate map of resource requests and related assignments for any just assigned
        if(trigger.isUpdate) {
            copyResourceRequestFieldsToAssignment(Trigger.New, Trigger.OldMap);
        }
    }
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so) {

        if(needRateLookup){
            pse__Resource_Request__c resReq = (pse__Resource_Request__c)so;
            pse__Proj__c project = projectMap.get(resReq.pse__Project__c);
            
            if(project != null && project.pse__Project_Type__c == 'Customer Project'){
                ApplyBillCostRates(resReq); 
            }
        }
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so) {

        if(needRateLookup){

            pse__Resource_Request__c resReqOld = (pse__Resource_Request__c)oldSo;
            pse__Resource_Request__c resReq = (pse__Resource_Request__c)so;
            pse__Proj__c project = projectMap.get(resReq.pse__Project__c);

            Boolean isAssigned = (resReq.pse__Status__c == 'Assigned');
            Boolean isCanceled = (resReq.pse__Status__c == 'Canceled');
            Boolean hasBillLevelChanged = (resReqOld.PSA_Billing_Level__c != resReq.PSA_Billing_Level__c);
            Boolean hasStartDateChanged = (resReqOld.pse__Start_Date__c != resReq.pse__Start_Date__c);
            Boolean hasEndDateChanged = (resReqOld.pse__End_Date__c != resReq.pse__End_Date__c);
            Boolean isCustomer = (project.pse__Project_Type__c == 'Customer Project');


            if(isCustomer && !isAssigned && !isCanceled){
                if(hasBillLevelChanged || hasStartDateChanged || hasEndDateChanged){
                    System.debug('Applying bill rates');
                    ClearBillCostRates(resReq);
                    ApplyBillCostRates(resReq);
                }
            }
        }
    }
 
    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so){}
 
    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted 
    //               during an AFTER trigger. Always put field validation in the 'After' 
    //               methods in case another trigger has modified any values. The record 
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){}
 
    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated 
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){}
 
    /**************************************************************************************
    // Name        : afterDelete
    // Description : This method is called iteratively for each record deleted 
    //               during an AFTER trigger.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void afterDelete(SObject so){}
 
    /**************************************************************************************
    // Name        : andFinally
    // Description : This method is called once all records have been processed by the 
    //               trigger. Use this method to accomplish any final operations such as
    //               creation or updates of other records.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void andFinally() {
        
        if(projectsToUpdate != null && projectsToUpdate.size() > 0){
            System.debug('Updating projects to update');
            update projectsToUpdate;
        }

    }

    /**************************************************************************************
    // Name        : clearBillCostRates
    // Description : This method clears the bill and cost rates on a resource request
    // Arguments   : pse__Resource_Request__c resReq - the request that needs to be cleared
    ***************************************************************************************/
    private void ClearBillCostRates(pse__Resource_Request__c resReq) {
        resReq.PSA_Rate_Set__c = null;
        resReq.pse__Suggested_Bill_Rate_Number__c = null;
        resReq.pse__Suggested_Bill_Rate_Currency_Code__c = null;
        resReq.pse__Requested_Bill_Rate__c = null;
        resReq.pse__Average_Cost_Rate_Number__c = null;
        resReq.pse__Average_Cost_Rate_Currency_Code__c = null;
        resReq.pse__Planned_Bill_Rate__c = null;
    }

     /**************************************************************************************
    // Name        : ApplyBillCostRates
    // Description : This method sets a resource request with cost and bill rates
    // Arguments   : pse__Resource_Request__c resReq - the request that needs rates applied
    ***************************************************************************************/
    private void ApplyBillCostRates(pse__Resource_Request__c resReq) {
        Boolean flagForReview = false;
        System.debug('Applying bill cost rates, flag is false');
        String rateType = '';
        if(resReq.PSA_Billing_Level__c != null){
            // first try project...
            Map<String, List<psaRateLookup>> rateMap = rateBucket.get(resReq.pse__Project__c);
            if(rateMap != null){
                System.debug('Project Rate Set Check');
                boolean found = false;
                List<psaRateLookup> rates = rateMap.get(resReq.PSA_Billing_Level__c);
                if(rates != null){
                    for(psaRateLookup rate : rates){
                        System.debug('Checking rate: '+rate);
                        if((rate.Start == null || rate.Start <= resReq.pse__Start_Date__c) &&
                            (rate.EndDate == null || rate.EndDate >= resReq.pse__Start_Date__c)){
                            if(rate.CurrencyIsoCode == resReq.currencyIsoCode){
                                System.debug('Rate used is: '+rate);
                                pse__Proj__c project = projectMap.get(resReq.pse__Project__c);
                                if(project != null && project.psa_Project_Rate_Set__c == null){
                                    project.psa_Project_Rate_Set__c = rate.rateSetId;
                                    projectsToUpdate.add(project);
                                }
                                resReq = assignRate(resReq, rate);
                                found = true;
                            }
                        }
                    }
                }
                if(!found){
                    rateMap = null;
                }

            }
            if(rateMap == null){
                boolean found = false;

                // try Account next
                rateMap = rateBucket.get(resReq.pse__AccountId__c);
                if(rateMap != null){
                    List<psaRateLookup> rates = rateMap.get(resReq.PSA_Billing_Level__c);
                    if(rates != null){
                        for(psaRateLookup rate : rates){
                            System.debug('Checking rate: '+rate);
                            if((rate.Start == null || rate.Start <= resReq.pse__Start_Date__c) &&
                            (rate.EndDate == null || rate.EndDate >= resReq.pse__Start_Date__c)){
                                if(rate.CurrencyIsoCode == resReq.currencyIsoCode){
                                    System.debug('Rate used is: '+rate);
                                    pse__Proj__c project = projectMap.get(resReq.pse__Project__c);
                                    if(project != null && project.psa_Account_Rate_Set__c == null){
                                        project.psa_Account_Rate_Set__c = rate.rateSetId;
                                        projectsToUpdate.add(project);
                                    }
                                    resReq = assignRate(resReq, rate);
                                    found = true;
                                }
                            }
                        }
                    }
                }
                if(!found){
                    rateMap = null;
                }
            }

            if(rateMap == null){
                // default to org bill rates
                boolean found = false;
                rateMap = rateBucket.get(null);
                if(rateMap != null){
                    List<psaRateLookup> rates = rateMap.get(resReq.PSA_Billing_Level__c);
                    if(rates != null){
                        for(psaRateLookup rate : rates){
                            System.debug('Checking rate: '+rate);
                            if((rate.Start == null || rate.Start <= resReq.pse__Start_Date__c) &&
                                (rate.EndDate == null || rate.EndDate >= resReq.pse__Start_Date__c)){
                                if(rate.CurrencyIsoCode == resReq.currencyIsoCode){
                                    resReq = assignRate(resReq, rate);
                                    found = true;
                                }
                            }
                        }
                    }
                }
                if(!found){
                    resReq.Rate_Needs_Review__c = flagForReview;
                }
            }
            //Commented out on 6/11, GW expressed concern that too many resource requests would be flagged for review
            resReq.Rate_Needs_Review__c = flagForReview;
        }   

    }

    private pse__Resource_Request__c assignRate(pse__Resource_Request__c resReq, psaRateLookup rate){
        Double billRate = rate.BillRate;
        resReq.PSA_Rate_Set__c = rate.RateSetId;
        resReq.pse__Suggested_Bill_Rate_Number__c = billRate;
        resReq.pse__Suggested_Bill_Rate_Currency_Code__c = rate.CurrencyIsoCode;
        resReq.pse__Requested_Bill_Rate__c = billRate;
        resReq.pse__Planned_Bill_Rate__c = billRate;
        resReq.pse__Average_Cost_Rate_Number__c = rate.AvgCost;
        resReq.pse__Average_Cost_Rate_Currency_Code__c = rate.CurrencyIsoCode;
        System.debug(resReq);
        return resReq;
    }

     /**************************************************************************************
    // Name        : calculateResourceRequestHours
    // Description : This method calculates the resource request hours inside of a particular schedule
    // Arguments   : pse__Resource_Request__c resReq - the request that needs to have hours calculated
    ***************************************************************************************/
    private void calculateResourceRequestHours(list<pse__Resource_Request__c> resourceRequests) {
        //Build a set of Region Ids which will be used to populate maps of regions, work calendars, and holidays
        Set<Id> regionIDs = new Set<Id>();
        for (pse__Resource_Request__c rr : resourceRequests) {
            regionIDs.add(rr.pse__region__c);
        }

        //Populate Region, Work Calendar, and Holiday maps -- these are used to determine what days/hours should be
        // included as days to be worked by a resource
        fillRegionAndWorkCalendarAndHolidayMap(regionIDs);
    
        //Now that we our maps of region => workCalendar and region => Holidays, we will process the resource requests and calculate
        // hours        
        for (pse__Resource_Request__c rr : resourceRequests) {
            // Only process RR's where the "Overide Requested Hours" checkbox is not checked
            if (rr.Override_Requested_Hours_Calc__c == false) {
                rr.pse__SOW_Hours__c = getTotalWorkingHours(rr.pse__Region__c, rr.pse__Start_Date__c, rr.pse__End_Date__c, rr.pse__Percent_Allocated__c);
            }
        } 
    } 

     /**************************************************************************************
    // Name        : calcRequestedHours
    // Description : This method calculate the Requested Hours based on the Start Date, End Date and Percent Allocated
    // Arguments   : 
    *****************************************************/
    private decimal calcRequestedHours(date stDate, date endDate, decimal pctAllocated, decimal hoursPerDay, decimal holidayHours)
    {
        decimal totalHours = 0.0;
        date testDate = stDate;
  
        for(testDate = stDate; testDate <= endDate; testDate = testDate.addDays(1))
        {
            datetime myDateTime = datetime.newInstanceGmt(testDate, Time.newInstance(0,0,0,0)); // Cast the Date variable into a DateTime
            string dayOfWeek = myDateTime.formatGmt('E');  // Creates 'Mon', 'Tue', etc

            //system.Debug('*** psaResourceRequestBiu_CalcRequestedHours: dayOfWeek for ' + testDate + ' = ' + dayOfWeek);
  
            // Increment total hours if on a weekday
            if(dayOfWeek == 'Mon'){
                totalHours = totalHours + hoursPerDay;
            } else if(dayOfWeek == 'Tue'){
                totalHours = totalHours + hoursPerDay;
            } else if(dayOfWeek == 'Wed'){
                totalHours = totalHours + hoursPerDay;
            } else if(dayOfWeek == 'Thu'){
               totalHours = totalHours + hoursPerDay;
            } else if(dayOfWeek == 'Fri'){
                totalHours = totalHours + hoursPerDay;
            } else if(dayOfWeek == 'Sat'){
                //do nothing
            } else if(dayOfWeek == 'Sun'){
                //do nothing
            }  
  
        }
  
        // Now multiply the total workday hours by Percent Allocated and round to 2 places
        totalHours = ((totalHours - holidayHours) * (pctAllocated / 100)).setScale(2);
        System.debug('*** calcRequestHours.holidayHours: ' + holidayHours);
        return totalHours;
    }

    /**************************************************************************************
    // Name        : createResourceRequestEvARecords
    // Description : Called after insert of Resource Requests.
    //               This method creates related Est vs Actuals records
    //
    ***************************************************************************************/
    private void createResourceRequestEvARecords(List <SObject> resourceRequestObjs)
    {
        Integer actualsToCreate = 0;
        List<pse__Est_Vs_Actuals__c> listOfEvAInsert = new List<pse__Est_Vs_Actuals__c>();
        Map<Id, Map<Date, Decimal>> mapOfRRIdAndWorkDayMap = new Map<Id, Map<Date, Decimal>>();
        Map<Id, Decimal> mapOfRRIdAndHourPerDay = new Map<Id, Decimal>();
        Set<Id> setOfProjectIds = new Set<Id>();
        Map<Id, Id> mapOfProjectIdAndPMId = new Map<Id, Id>();
        Set<Id> regionIds = new Set<Id>();

        //First need to populate a the region/work calendar/holiday maps for all RR regions
        for(SObject so : resourceRequestObjs) {
            pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
                regionIds.add(rr.pse__Region__c);
        }
        fillRegionAndWorkCalendarAndHolidayMap(regionIds);

        for(SObject so : resourceRequestObjs) {
            pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
            if (rr.pse__Status__c == 'Ready to Staff' || rr.pse__Status__c == 'Hold' || rr.pse__Status__c == 'Draft' || rr.pse__Status__c == 'Tentative') {
                Map<Date, Decimal> WorkDayMap = new Map<Date, Decimal>();

                if (rangeStartDate == null || rr.pse__Start_Date__c < rangeStartDate) {
                    rangeStartDate = rr.pse__Start_Date__c;
                }

                if (rangeEndDate == null || rr.pse__End_Date__c > rangeEndDate) {
                    rangeEndDate = rr.pse__End_Date__c;
                }
                
                //begin modified by cklassen 7/22 to centralize how total working days is calculated
                Date startDate = rr.pse__Start_Date__c; 
                while(startDate <= rr.pse__End_Date__c) {
                    String weekday = Datetime.newInstance(startDate, Time.newInstance(0,0,0,0)).format('E');
                    //if(!weekday.equals('Sat') && !weekday.equals('Sun'))
                    //modifed by cklassen 7/30/15 to exclude Holidays (based on the region work calendar)
                    if(!weekday.equals('Sat') && !weekday.equals('Sun') && !dateIsHoliday(rr.pse__Region__c, startDate)) {
                        System.debug('@@@@@ ' + weekday);
                        System.debug('$$$$$ ' + startDate);
                        WorkDayMap.put(startDate, 0);
                    }
                    startDate = startDate.addDays(1);
                }
                Decimal HoursPerDay = rr.pse__SOW_Hours__c/(WorkDayMap.size());

                mapOfRRIdAndWorkDayMap.put(rr.Id, WorkDayMap);
                mapOfRRIdAndHourPerDay.put(rr.Id, HoursPerDay);

                if(rr.pse__Project__c != null) {
                    setOfProjectIds.add(rr.pse__Project__c);
                }
                actualsToCreate++;
            }
        }
        System.debug('##### rangeStartDate ' + rangeStartDate + ', rangeEndDate ' +rangeEndDate);


        if (actualsToCreate > 0) {
            // Fetch records of time periods for the type 'Month' 
            List<pse__Time_Period__c> listOfTimePeriods = 
                    [SELECT Id, Name, pse__Start_Date__c, pse__End_Date__c, pse__Type__c 
                       FROM pse__Time_Period__c 
                      WHERE pse__Type__c = 'Month' 
                        AND pse__End_Date__c >= :rangeStartDate
                        AND pse__Start_Date__c <= :rangeEndDate
                      ORDER BY pse__Start_Date__c];   

            // Populate mapOfProjectIdAndPMId to get project manager of related projects
            for(pse__Proj__c p : [Select Id, pse__Project_Manager__c from pse__Proj__c where Id in :setOfProjectIds]) {
                if(!mapOfProjectIdAndPMId.containsKey(p.pse__Project_Manager__c)) {
                    mapOfProjectIdAndPMId.put(p.Id, p.pse__Project_Manager__c);
                }
            }

            for(SObject so : resourceRequestObjs) {
                pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
                Id projectManagerId = mapOfProjectIdAndPMId.get(rr.pse__Project__c);
                Decimal workingHoursPerDay = mapOfRRIdAndHourPerDay.get(rr.Id);
                Map<Date, Decimal> workDayMap = mapOfRRIdAndWorkDayMap.get(rr.Id);

                // Generate Monthly EvA records   
                Date startOfPsaMonth = rr.pse__Start_Date__c;
                System.debug('##### startOfPsaMonth ' + startOfPsaMonth);
                for(pse__Time_Period__c tp : listOfTimePeriods) {
                    if(startOfPsaMonth <= rr.pse__End_Date__c) {
                        if(tp.pse__Start_Date__c <= startOfPsaMonth && tp.pse__End_Date__c >= startOfPsaMonth) {
                            Date workStartDate = tp.pse__Start_Date__c < rr.pse__Start_Date__c ? rr.pse__Start_Date__c : tp.pse__Start_Date__c;  
                            Date workEndDate =  tp.pse__End_Date__c > rr.pse__End_Date__c ? rr.pse__End_Date__c : tp.pse__End_Date__c;

                            Integer totalWorkingDays = 0;
                            Decimal totalWorkingHours = 0;
                            while(workStartDate <= workEndDate) {
                                system.debug('Work Start Date: ' + workStartDate);
                                if(workDayMap != null && workDayMap.containsKey(workStartDate)) {
                                    system.debug('Found date in map: ' + workStartDate);
                                    totalWorkingDays++;
                                    totalWorkingHours = totalWorkingHours + workingHoursPerDay;
                                }
                                workStartDate = workStartDate.addDays(1);
                            }

                            System.debug('@@@@ tp ' + tp);
                            pse__Est_Vs_Actuals__c objectEvA = new pse__Est_Vs_Actuals__c(
                                    Name='EVA ' + rr.Name + ' ' + tp.pse__Start_Date__c.format() + '-' + tp.pse__End_Date__c.format(),
                                    pse__Project__c=rr.pse__Project__c, pse__Resource__c=rr.pse__Resource__c, PSA_Resource_Request__c=rr.Id,
                                    pse__Start_Date__c=tp.pse__Start_Date__c, pse__End_Date__c=tp.pse__End_Date__c, 
                                    pse__Actual_Hours__c=0, pse__Actual_Days__c=0, pse__Actual_Billable_Amount__c=0,
                                    pse__Estimated_Hours__c=totalWorkingHours, pse__Estimated_Days__c=totalWorkingDays,
                                    pse__Time_Period_Type__c=tp.pse__Type__c, pse__Time_Period__c=tp.Id,
                                    CurrencyIsoCode=rr.CurrencyIsoCode, pse__Project_Manager__c = projectManagerId);
                            if (totalWorkingHours > 0) {
                                listOfEvAInsert.add(objectEvA);
                            }
                        }
                    }
                    startOfPsaMonth = tp.pse__End_Date__c.addDays(1);
                }
            }

            // Insert Monthly EvA records
            if(listOfEvAInsert.size() > 0)
            {
                System.debug('##### ' + listOfEvAInsert.size());
                insert listOfEvAInsert;
            }
        }
    }


    /**************************************************************************************
    // Name        : updateResourceRequestEvARecords
    // Description : Called before update of Resource Requests.
    //               This method updates/deletes related Est vs Actuals records 
    //
    //             : Updated by cklassen 10/28 to fix a bug that was setting EVA days/hours 
    //                  to zero incorrectly (was using the old RR start/end dates)
    ***************************************************************************************/
    private void updateResourceRequestEvARecords(List <SObject> resourceRequestObjs, Map<Id, SObject> oldRRMap)
    {
        Set<Id> setOfRR = new Set<Id>();
        Set<Id> setToDeleteRR = new Set<Id>();
        List<pse__Resource_Request__c> listOfRR = new List<pse__Resource_Request__c>();
        Map<Id, pse__Est_Vs_Actuals__c> mapOfEvAToDelete = new Map<Id, pse__Est_Vs_Actuals__c>();
        List<pse__Est_Vs_Actuals__c> listOfEvAToDelete = new List<pse__Est_Vs_Actuals__c>();
        List<pse__Est_Vs_Actuals__c> listOfEvAInsert = new List<pse__Est_Vs_Actuals__c>();
        Map<Id, Map<Date, Decimal>> mapOfRRIdAndWorkDayMap = new Map<Id, Map<Date, Decimal>>();
        Map<Id, Decimal> mapOfRRIdAndHourPerDay = new Map<Id, Decimal>();
        Set<Id> setOfProjectIds = new Set<Id>();
        Map<Id, Id> mapOfProjectIdAndPMId = new Map<Id, Id>();
        Set<Id> regionIds = new Set<Id>();
        Map<Id, pse__Resource_Request__c> mapOfUpatedRRs = new Map<Id, pse__Resource_Request__c>();

        for(SObject so : resourceRequestObjs) {
            pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
            mapOfUpatedRRs.put(rr.Id, rr);
            System.debug('----STATUS : ' + rr.pse__Status__c + '---');
            pse__Resource_Request__c oldRR = (pse__Resource_Request__c) oldRRMap.get(rr.Id);

            if (rr.pse__Status__c == 'Draft' || rr.pse__Status__c == 'Ready to Staff' || rr.pse__Status__c == 'Hold' || rr.pse__Status__c == 'Tentative') {
                if(rr.pse__SOW_Hours__c != oldRR.pse__SOW_Hours__c || rr.pse__Start_Date__c != oldRR.pse__Start_Date__c ||
                        rr.pse__End_Date__c != oldRR.pse__End_Date__c || rr.pse__Resource__c != oldRR.pse__Resource__c ||
                        rr.pse__Requested_Bill_Rate__c != oldRR.pse__Requested_Bill_Rate__c || rr.pse__Average_Cost_Rate__c != oldRR.pse__Average_Cost_Rate__c ||
                        (rr.PSA_Action_Update_Est_v_Actuals__c == True && oldRR.PSA_Action_Update_Est_v_Actuals__c != True)) {
                    Map<Date, Decimal> WorkDayMap = new Map<Date, Decimal>();
                    setOfRR.add(rr.Id);

                    //Use the same logic used by the calculate requested hours logic which excludes holidays                    
                    regionIds.add(rr.pse__Region__c);
                    fillRegionAndWorkCalendarAndHolidayMap(regionIds);

                    if (rangeStartDate == null || rr.pse__Start_Date__c < rangeStartDate) {
                        rangeStartDate = rr.pse__Start_Date__c;
                    }

                    if (rangeEndDate == null || rr.pse__End_Date__c > rangeEndDate) {
                        rangeEndDate = rr.pse__End_Date__c;
                    }
            
                    Date startDate = rr.pse__Start_Date__c; 
                    while(startDate <= rr.pse__End_Date__c) {
                        String weekday = Datetime.newInstance(startDate, Time.newInstance(0,0,0,0)).format('E');
                        //modifed by cklassen 7/30/15 to exclude Holidays (based on the region work calendar)
                        if(!weekday.equals('Sat') && !weekday.equals('Sun') && !dateIsHoliday(rr.pse__Region__c, startDate)) {
                            System.debug('@@@@@ ' + weekday);
                            System.debug('$$$$$' + startDate);
                            WorkDayMap.put(startDate, 0);
                        }
                        startDate = startDate.addDays(1);
                    }

                    Decimal HoursPerDay = 0;
                    if (WorkDayMap.size() > 0) {
                        HoursPerDay = rr.pse__SOW_Hours__c/(WorkDayMap.size());
                    }

                    System.debug('##### rangeStartDate ' + rangeStartDate + ', rangeEndDate ' +rangeEndDate);

                    mapOfRRIdAndWorkDayMap.put(rr.Id, WorkDayMap);
                    mapOfRRIdAndHourPerDay.put(rr.Id, HoursPerDay);
                }
            }
            else if (rr.pse__Status__c == 'Assigned' || rr.pse__Status__c == 'Cancelled') {
                if(oldRR.pse__Status__c != 'Assigned' && oldRR.pse__Status__c != 'Cancelled') {
                    // With changes to Assigned or Cancelled statuses, we'll delete EvA records...
                    setToDeleteRR.add(rr.Id);
                }
            }
            rr.PSA_Action_Update_Est_v_Actuals__c = false;
        }

        System.debug('##### rangeStartDate ' + rangeStartDate);
        System.debug('##### rangeEndDate ' + rangeEndDate);

        
        // Fetch existing EvA records linked to resource request
        
        //Prevent calling SOQL if setofRR is empty
        if(!setofRR.isEmpty()){
            listOfRR = [SELECT Id, Name, pse__Project__c, pse__Resource__c, pse__SOW_Hours__c, pse__Project__r.pse__Project_Manager__c, pse__Start_Date__c,
                               pse__End_Date__c, CurrencyIsoCode,
                              (SELECT Id, pse__Start_Date__c, pse__End_Date__c, pse__Actual_Hours__c, pse__Actual_Days__c, pse__Time_Period__c, pse__Time_Period_Type__c
                                 FROM Est_Vs_Actuals__r
                                WHERE pse__Time_Period_Type__c = 'Month' 
                                ORDER BY pse__Time_Period_Type__c, pse__Start_Date__c)
                          FROM pse__Resource_Request__c 
                         WHERE Id IN :setOfRR];

            // Fetch records of time periods for the type 'Month' 
            List<pse__Time_Period__c> listOfTimePeriods = [SELECT Id, Name, pse__Start_Date__c, pse__End_Date__c, pse__Type__c 
                                                             FROM pse__Time_Period__c 
                                                            WHERE pse__Type__c = 'Month' 
                                                              AND pse__End_Date__c >= :rangeStartDate
                                                              AND pse__Start_Date__c <= :rangeEndDate
                                                            ORDER BY pse__Start_Date__c];

            for(pse__Resource_Request__c rr : listOfRR)
            {
                //Date startOfPsaWeek = rr.pse__Start_Date__c.toStartOfWeek();
                Decimal workingHoursPerDay = mapOfRRIdAndHourPerDay.get(rr.Id);
                Map<Date, Decimal> workDayMap = mapOfRRIdAndWorkDayMap.get(rr.Id);
                Id projectManagerId = null;
                pse__Resource_Request__c newVersionOfRR = mapOfUpatedRRs.get(rr.Id);

                //Set the starting value to the RR start date
                Date startOfPsaMonth = newVersionOfRR.pse__Start_Date__c;
                System.debug('##### workDayMap: ' + workDayMap);

                if(rr.pse__Project__c != NULL) {
                    projectManagerId = rr.pse__Project__r.pse__Project_Manager__c;
                }
            
                Map<String, pse__Est_Vs_Actuals__c> mapOfStartDateAndEvA = new Map<String, pse__Est_Vs_Actuals__c>();
                for(pse__Est_Vs_Actuals__c evA : rr.Est_Vs_Actuals__r) {
                    mapOfStartDateAndEvA.put(evA.pse__Start_Date__c + '-' + evA.pse__Time_Period_Type__c, evA);
                }

                // Refresh Monthly EvA records
                for(pse__Time_Period__c tp : listOfTimePeriods) {
                    System.debug('##### time period ' + tp);
                    pse__Est_Vs_Actuals__c evA = null;
                    Integer totalWorkingDays = 0;
                    Decimal totalWorkingHours = 0;

                    //Use the end date of the updated RR
                    if(startOfPsaMonth <= newVersionOfRR.pse__End_Date__c) {
                        if(tp.pse__Start_Date__c <= startOfPsaMonth && tp.pse__End_Date__c >= startOfPsaMonth)
                        {
                            evA = mapOfStartDateAndEvA.get(tp.pse__Start_Date__c + '-' + tp.pse__Type__c);

                            Date workStartDate = tp.pse__Start_Date__c < newVersionOfRR.pse__Start_Date__c ? newVersionOfRR.pse__Start_Date__c : tp.pse__Start_Date__c;  
                            Date workEndDate =  tp.pse__End_Date__c > newVersionOfRR.pse__End_Date__c ? newVersionOfRR.pse__End_Date__c : tp.pse__End_Date__c;

                            while(workStartDate <= workEndDate) {
                                if(workDayMap.containsKey(workStartDate)) {
                                    totalWorkingDays++;
                                    totalWorkingHours = totalWorkingHours + workingHoursPerDay;
                                }
                                workStartDate = workStartDate.addDays(1);
                            }
                        }
                    }

                    if(evA == null) {
                        pse__Est_Vs_Actuals__c objectEvA = new pse__Est_Vs_Actuals__c(
                                Name='EVA ' + rr.Name + ' ' + tp.pse__Start_Date__c.format() + '-' + tp.pse__End_Date__c.format(),
                                pse__Project__c=rr.pse__Project__c, pse__Resource__c=rr.pse__Resource__c, PSA_Resource_Request__c=rr.Id,
                                pse__Start_Date__c=tp.pse__Start_Date__c, pse__End_Date__c=tp.pse__End_Date__c,  
                                pse__Actual_Hours__c=0, pse__Actual_Days__c=0, pse__Actual_Billable_Amount__c=0,
                                pse__Estimated_Hours__c=totalWorkingHours, pse__Estimated_Days__c=totalWorkingDays,
                                pse__Time_Period_Type__c=tp.pse__Type__c, pse__Time_Period__c=tp.Id,
                                CurrencyIsoCode=rr.CurrencyIsoCode, pse__Project_Manager__c = projectManagerId);                        
                        if (totalWorkingHours > 0) {
                            listOfEvAInsert.add(objectEvA);
                        }
                    }
                    else {
                        pse__Est_Vs_Actuals__c objectEvA = new pse__Est_Vs_Actuals__c(Id = evA.Id,
                                Name='EVA ' + rr.Name + ' ' + tp.pse__Start_Date__c.format() + '-' + tp.pse__End_Date__c.format(),
                                pse__Project__c=rr.pse__Project__c, pse__Resource__c=rr.pse__Resource__c, PSA_Resource_Request__c=rr.Id,
                                pse__Start_Date__c=tp.pse__Start_Date__c, pse__End_Date__c=tp.pse__End_Date__c, 
                                pse__Actual_Hours__c=0, pse__Actual_Days__c=0, pse__Actual_Billable_Amount__c=0,
                                pse__Estimated_Hours__c=totalWorkingHours, pse__Estimated_Days__c=totalWorkingDays,
                                pse__Time_Period_Type__c=tp.pse__Type__c, pse__Time_Period__c=tp.Id,
                                CurrencyIsoCode=rr.CurrencyIsoCode, pse__Project_Manager__c = projectManagerId);
                        if (totalWorkingHours > 0) {
                            listOfEvAInsert.add(objectEvA);
                        }
                        mapOfStartDateAndEvA.remove(evA.pse__Start_Date__c + '-' + evA.pse__Time_Period_Type__c);
                    }
                    startOfPsaMonth = tp.pse__End_Date__c.addDays(1); 
                }

                if(mapOfStartDateAndEvA.size() > 0) {
                    listOfEvAToDelete.addAll(mapOfStartDateAndEvA.values());    
                }
            }
        }

        if(listOfEvAToDelete.size() > 0) {
            for(pse__Est_Vs_Actuals__c evA: listOfEvAToDelete) {
                mapOfEvAToDelete.put(evA.Id, evA);
            }
        
            System.debug('##### Delete EvA records ' + mapOfEvAToDelete.size());
            delete mapOfEvAToDelete.values();
        }           

        if(listOfEvAInsert.size() > 0) {
            System.debug('##### Insert EvA ' + listOfEvAInsert.size());
            upsert listOfEvAInsert;
        }  

        if (setToDeleteRR.size() > 0) {
            // These are the RR's to delete
            List<pse__Est_Vs_Actuals__c> rrToDelete = [Select Id from pse__Est_Vs_Actuals__c where PSA_Resource_request__c in :setToDeleteRR];
            System.debug('##### Deleting EvA ' + setToDeleteRR.size());
            delete rrToDelete;
        }
    }


    /**************************************************************************************
    // Name        : deleteResourceRequestEvARecords
    // Description : Called before delete of Resource Requests.
    //               This method deletes related Est vs Actuals records
    //
    ***************************************************************************************/
    private void deleteResourceRequestEvARecords(List <SObject> resourceRequestObjs)
    {
        List<Id> setOfRRIds = new List<Id>();
        for(SObject so : resourceRequestObjs)
        {
            pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
            setOfRRIds.add(rr.Id);
        }
        
        List<pse__Est_Vs_Actuals__c> listOfEvARecordsToDelete = new List<pse__Est_Vs_Actuals__c>();
        if(setOfRRIds.size() > 0)
        {
            listOfEvARecordsToDelete = [SELECT Id FROM pse__Est_Vs_Actuals__c WHERE PSA_Resource_Request__c in :setOfRRIds];
        }

        if(listOfEvARecordsToDelete.size() > 0)
        {
            System.debug('##### delete trigger delete EvA ' + listOfEvARecordsToDelete.size());
            delete listOfEvARecordsToDelete;
        }            
    }
    
    
     /**************************************************************************************
    // Name        : deleteResourceRequestForecastDetailRecords
    // Description : Called before delete of Resource Requests.
    //               This method deletes related Forecast Detail (PSA_Project_Forecast_Detail__c) records
    //
    ***************************************************************************************/
     private void deleteResourceRequestForecastDetailRecords(List <SObject> resourceRequestObjs)
     {
         List<PSA_Project_Forecast_Detail__c> ForecastDetailLst = [Select Id,Name,PSA_Item_Key__c,PSA_Project_Forecast__r.Name, PSA_Project_Forecast__r.PSA_Project__r.Name,PSA_For_Month_Ending__c,PSA_Forecast_Source__c from PSA_Project_Forecast_Detail__c where PSA_Item_Key__c  like '%RR-%'];
         Set<String> ResReqNames = new Set<String>();

         Map<String,List<PSA_Project_Forecast_Detail__c>> ForecastDetailMap = new Map<String,List<PSA_Project_Forecast_Detail__c>>();

         for(PSA_Project_Forecast_Detail__c detail: ForecastDetailLst)
         {
           List<String> stringsLst = detail.PSA_Item_Key__c.split('\\|');
           ResReqNames.add(stringsLst[1]);
           if(ForecastDetailMap.containskey(stringsLst[1]))
           { 
              List<PSA_Project_Forecast_Detail__c> list1 =  ForecastDetailMap.get(stringsLst[1]); 
              list1.add(detail); 
              ForecastDetailMap.put(stringsLst[1],list1);
          }
          else
          {
            List<PSA_Project_Forecast_Detail__c> list2 =  new List<PSA_Project_Forecast_Detail__c>(); 
            list2.add(detail); 
            ForecastDetailMap.put(stringsLst[1],list2);
          }
        }
        system.debug('Forecast Details :'+ ForecastDetailMap);

        List<PSA_Project_Forecast_Detail__c> ForecastDetailstoDelete = new List<PSA_Project_Forecast_Detail__c>();
        set<id> ForecastDetailIdstoDelete = new Set<id>();

        for(SObject so : resourceRequestObjs)
        {
           pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
           if(rr.Name != null && ResReqNames.contains(rr.Name))
           {
                List<PSA_Project_Forecast_Detail__c> DeleteLst = ForecastDetailMap.get(rr.Name);
                for(PSA_Project_Forecast_Detail__c ForDetail: DeleteLst)
                {
                  ForecastDetailIdstoDelete.add(ForDetail.Id);
                }
           }
        }
        
        if(ForecastDetailIdstoDelete.size() > 0)
        {
          ForecastDetailstoDelete = [Select Id,Name,PSA_Item_Key__c,PSA_Project_Forecast__r.Name from PSA_Project_Forecast_Detail__c where Id IN :ForecastDetailIdstoDelete];
        }
   
        if(ForecastDetailstoDelete.size() > 0)
        {
            System.debug('##### delete trigger delete Forecast Details ' + ForecastDetailstoDelete.size());
            delete ForecastDetailstoDelete;
        } 
    }  
    

    /**************************************************************************************
    // Name        : copyResourceRequestFieldsToAssignment
    // Description : Called after resource requests are assigned, to copy necessary field values 
    //               to the new assignment
    //               
    //
    ***************************************************************************************/
    private void copyResourceRequestFieldsToAssignment(List <SObject> resourceRequestObjs, Map<Id, SObject> oldRRMap)
    {
        Set<Id> setOfRR = new Set<Id>();
        Map<Id, pse__Resource_Request__c> newAssignmentToRRMap = new Map<Id, pse__Resource_Request__c>();
        List<Id> rrIdsForAssignmentUpdate = new List<Id>();

        for(SObject so : resourceRequestObjs)
        {
            pse__Resource_Request__c rr = (pse__Resource_Request__c) so;
            pse__Resource_Request__c rrPrev = (pse__Resource_Request__c) oldRRMap.get(rr.Id);
            if(rr.pse__Status__c!=null && rr.pse__Status__c=='Assigned' && rrPrev.pse__Status__c==null || rrPrev.pse__Status__c!='Assigned')
            {
                // If the resource request has an assignment now and didn't before, 
                // and if it has fields that don't get automatically carried over to the assignment,
                // include it in the list to have its related assignment updated.
                if(rr.pse__Assignment__c!=null && rrPrev.pse__Assignment__c==null)
                {
                    System.debug('***** Resource request ' + rr.Name + ' is now assigned and will have its assignment updated.');
                    newAssignmentToRRMap.put(rr.pse__Assignment__c, rr);
                    rrIdsForAssignmentUpdate.add(rr.Id);
                }
            }
        }

        // If there are new assignments that need custom values set, call for the assignment update
        if(newAssignmentToRRMap!=null && newAssignmentToRRMap.size() > 0)
        {
            List<pse__Assignment__c> assignmentsToUpdate = new List<pse__Assignment__c>();
            System.debug('***** Ready to update new Assignments.');

            // Get related assignment info
            Set<Id> assignmentIds = newAssignmentToRRMap.keySet();
            List<pse__Assignment__c> relatedAssignments = [
                SELECT Id, 
                    Name, 
                    PSA_Part_Time__c, 
                    PSA_Project_Role__c
                FROM pse__Assignment__c 
                WHERE Id IN :assignmentIds];

            if(relatedAssignments!=null && relatedAssignments.size() > 0)
            {
                for(pse__Assignment__c assignment : relatedAssignments)
                {
                    // Extract the info needed from the resource request and project, and update the assignment with it.
                    pse__Resource_Request__c resourceRequest = newAssignmentToRRMap.get(assignment.Id);
                    if(resourceRequest!=null)
                    {
                        System.debug('***** Checking resource request: ' + resourceRequest.Name + ' for data to update new assignment...');

                        // Get Part-Time (and other values) from the assigned Resource Request and copy them to the new Assignment
                        Boolean partTime = resourceRequest.PSA_Part_Time__c;
                        assignment.PSA_Part_Time__c = partTime;
                        assignment.PSA_Project_Role__c = resourceRequest.PSA_Project_Role__c;
                        assignmentsToUpdate.add(assignment);
                    }
                }
            }

            // Update the assignments with resource request data
            if(assignmentsToUpdate.size() > 0)
            {
                Database.update(assignmentsToUpdate);
            }
        }
    }

    /**************************************************************************************
    // Name        : fillRegionAndWorkCalendarAndHolidayMap
    // Description : This method populates a set of maps based on a list of Resource Request Ids.
    //                  They will be used to calc working hours excluding holidays for a date range
    // Arguments   : Set<Id> regionIDs - Region Ids for which to build the maps
    ***************************************************************************************/
    private void fillRegionAndWorkCalendarAndHolidayMap(Set<Id> regionIDs) {
        //Only populate the maps if they haven't been populated previously
        if (regionToWorkCalendarMap.size() == 0) {
            Set<Id> workCalendarIDs = new Set<Id>();
            Map<Id, pse__HolidayObj__c> regionToHolidaysMap = new Map<Id, pse__HolidayObj__c>();
            Map<Id, pse__HolidayObj__c> holidayMap = new Map<Id, pse__HolidayObj__c>();

            //Get a list of regions based on the Region Ids passed in to the method
            List<pse__region__c> regions = [SELECT Id, Name, pse__Default_Work_Calendar__c
                                                            FROM pse__region__c
                                                            WHERE Id IN : regionIDs
                                                            AND pse__Default_Work_Calendar__c != Null];

            //Populate the list of Work Calendar Ids based on the list of Regions
            for (pse__region__c region : regions) {
                workCalendarIDs.add(region.pse__Default_Work_Calendar__c);
            }
            
            //Get a list of Work Calendars based on the set of Work Calendar Ids just populated
            List<pse__Work_Calendar__c> workCalendars = [SELECT Id, Name, pse__Standard_Hours_Per_Day__c 
                                                            FROM pse__Work_Calendar__c
                                                            WHERE Id IN : workCalendarIDs];
            //Add a map item for each Work Calendar plus a map placeholder for any related holidays
            for(pse__Work_Calendar__c wkCal : workCalendars) {
                workCalendarToHolidayMap.put(wkCal.Id, new Map<Id, pse__HolidayObj__c>());
            }                                           

            //Get a list of holidays for the set of Work Calendar Ids
            List<pse__HolidayObj__c> holidaysList = [SELECT Id, Name, pse__Date__c, pse__Work_Hours__c, pse__Work_Calendar__c
                                                            FROM pse__HolidayObj__c
                                                            WHERE pse__Work_Calendar__c IN : workCalendarIDs];

            if(holidaysList != null && holidaysList.size() > 0) {
                System.debug('*** Holidays found for workcalendar: ' + holidaysList.size());
            }
            else {
                System.debug('*** Holidays found for workcalendar: 0');
            }

            //Loop through each region and work calendar, adding any holidays to the workCalendarToHolidayMap variable
            for (pse__region__c region : regions) {
                for (pse__Work_Calendar__c workCalendar : workCalendars) {
                    if (workCalendar.Id == region.pse__Default_Work_Calendar__c) {
                        regionToWorkCalendarMap.put(region.id, workCalendar);
                        
                        for (pse__HolidayObj__c specificHoliday : holidaysList) {
                            if (specificHoliday.pse__Work_Calendar__c == workCalendar.id) {
                                holidayMap = workCalendarToHolidayMap.get(workCalendar.Id);
                                if(holidayMap == Null) {
                                    holidayMap = new Map<Id, pse__HolidayObj__c>(); 
                                }
                                holidayMap.put(specificHoliday.Id, specificHoliday);
                                workCalendarToHolidayMap.put(workCalendar.Id, holidayMap);
                            } //end of holiday work calendar = current work calendar condition
                        } //end of holiday object loop
                    } //end of work calendar id = region default work calendar condition
                } //end of work calendar loop
            } //end of region loop
        } //end of condition checking to see if the regionToWorkCalendarMap variable has no records
    }

    /**************************************************************************************
    // Name        : getTotalWorkingHours
    // Description : This method calculates the number of working hours based on a 
    //                  work calendar and a date range and excludes any holiday hours
    // Arguments   : Date startDate - the first day of the RR
    //             : Date endDate - the last day of the RR
    //             : pse__Region__c - the region from which to infer the scheduled Holidays
    ***************************************************************************************/
    private Decimal getTotalWorkingHours(Id regionId, Date startDate, Date endDate, Decimal pctAllocated) {
        Decimal totalWorkingHours = 0.0;
        Decimal holidayHours = 0.0;
        Decimal percentAllocated;
        Decimal workingHoursPerDay;

        if (regionToWorkCalendarMap.get(regionId) != null) {
            workingHoursPerDay = regionToWorkCalendarMap.get(regionId).pse__Standard_Hours_Per_Day__c;
        }

        if (workingHoursPerDay == null || workingHoursPerDay == 0) {
            workingHoursPerDay = 8.0; // Default to 8 hours per day if we don't get a value from the work calendar
        }
        
        if (pctAllocated == null || pctAllocated == 0) {
            percentAllocated = 100.0; // Default to 100% if percent allocated isn't set
        }
        else {
            percentAllocated = pctAllocated;    
        }

        //Look up the work calendar for the specified region
        pse__Work_Calendar__c wkCal2 = regionToWorkCalendarMap.get(regionId);
        if(wkCal2 != null){
            Map<Id, pse__HolidayObj__c> holidayMap2 = workCalendarToHolidayMap.get(wkCal2.Id);

            for(Id holidayID : holidayMap2.keySet()) {
                pse__HolidayObj__c h = holidayMap2.get(holidayID);
                if(h.pse__Date__c >= startDate && h.pse__Date__c <= endDate) {
                    System.debug('*** Found holiday: ' + h.Name);
                    holidayHours = holidayHours + (workingHoursPerDay - h.pse__Work_Hours__c);
                    System.debug('*** Holiday hours: ' + holidayHours);
                }
            }
        }
        System.debug('*** Holiday hours after: ' + holidayHours);

        // Calculate the number of requested hours on the Resource Request
        totalWorkingHours = calcRequestedHours(startDate, endDate, percentAllocated, workingHoursPerDay, holidayHours);

        return totalWorkingHours;
    }

    /**************************************************************************************
    // Name        : dateIsHoliday
    // Description : This method calculates the number of working days based on a work calendar
    //                  and excludes any holidays that fall within the date range
    // Arguments   : Date startDate - the first day of the RR
    //             : Date endDate - the last day of the RR
    //             : pse__Region__c - the region from which to infer the scheduled Holidays
    ***************************************************************************************/
    private Boolean dateIsHoliday(Id regionId, Date dateToCheck) {
        Boolean returnValue = false;

        //Look up the work calendar for the specified region
        pse__Work_Calendar__c wkCal2 = regionToWorkCalendarMap.get(regionId);
        if(wkCal2 != null){
            Map<Id, pse__HolidayObj__c> holidayMap2 = workCalendarToHolidayMap.get(wkCal2.Id);

            for(Id holidayID : holidayMap2.keySet()){
                pse__HolidayObj__c h = holidayMap2.get(holidayID);
                if(h.pse__Date__c == dateToCheck){
                    System.debug('*** Found holiday: ' + h.Name);
                    returnValue = true;
                    break;
                }
            }
        }

        return returnValue;
    }
}