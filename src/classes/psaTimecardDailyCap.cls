/****************************************************************************************
Name            : psaTimecardDailyCap
Author          : CLD Partners 
Created Date    : May 11, 2015
Description     : Contains methods to apply Daily Caps to Timecard Hours when Billing 
                    Event Generation is run.
Revisions       : 5/11/15 - Initial version 
                : 6/24/15 - Bug fix to handle multiple TCs for the same day
                : 7/26/15 - Major revision to handle daily caps for negative timecards
                :   which need to be tracked separately from daily caps for positive timecards
                : 8/20/15 - Added custom Apex Logging functionality to some methods
                : 9/28/15 - Fixed bug that failed to calculate offsetting positive and negative
                :   timecard hours
                : 11/23/15 - Klassen Temporarily add TC Ops Edit to approving user's permission
                :   control
******************************************************************************************/
public without sharing class psaTimecardDailyCap {
    public psaTimecardDailyCap() {}

    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaTimecardDailyCap';
    private static Integer apexLogMethodSequenceMaster = 0;

    //static List<pse__Timecard__c> timecardSplitsToUpdate = new List<pse__Timecard__c>();
    static List<pse__Timecard_Header__c> timecardsToAdd = new List<pse__Timecard_Header__c>();
    static List<pse__Timecard_Header__c> timecardsToUpdate = new List<pse__Timecard_Header__c>();
    static String overCapMilestoneName = 'Excess (Non-billable) Time over Daily Cap';
    static String excludedBillableOvertimeMilestoneName = 'Billable Over Professional Day Cap';
    static Map<Id, Id> overCapMilestonMap = new Map<Id, Id>();

    static Map<Id, pse__Timecard_Header__c> timecardHeaderMap;
    static Map<String, pse__Timecard_Header__c> timecardHeaderKeyMap;
    static List<pse__Timecard__c> billableTimecardSplits;
    static List<pse__Timecard__c> overTheCapTimecardSplits;

    /**************************************************************************************
    // Name         : processOverDailyCapTimecards
    // Description  : Each time a billing event is created or updated, split out any time over
    //                  a daily cap hourly total into a non-billable timecard
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 2015-07-26  Klassen  Revise to allow separate Excess Over the Daily
    //                  cap timecards for positive and negative hours
                    : 2015-09-28  Klassen  Fixed bug with Positive and Negative correcting
                        entries not cancelling each other out
                    : 2015-09-29  Klassen  Update to allow the logic to be run when timecards
                        are approved
    ***************************************************************************************/
    public static void processOverDailyCapTimecards(Set<Id> projectIds, Date periodEndDate, 
            Set<Id> approvedTimecardIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'processOverDailyCapTimecards';

        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Populate a map of projects
        Map<Id, pse__Proj__c> projectMap = new Map<Id, pse__Proj__c>(
            [Select Id, Name, PSA_Daily_Cap__c, pse__End_Date__c, CurrencyISOCode 
                From pse__Proj__c
                Where Id =:projectIds
                And PSA_Daily_Cap__c != null 
            ]);

        String mapKey;
        Set<Id> timecardIds = new Set<Id>();
        Date earliestDate = Date.today();

        //Create "over the cap" milestone for all projects missing it (based on the name "Excess (Non-billable) Time over Daily Cap")
        createMissingMilestones(projectMap.keySet(), projectMap.values(), overCapMilestoneName);
        List<pse__Milestone__c> overCapMilestones = 
            [Select Id, pse__Project__c 
                From pse__Milestone__c 
                Where pse__Project__c = :projectMap.keySet()
                And Name = :overCapMilestoneName
            ];
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'overCapMilestones List', String.valueOf(overCapMilestones), (List<SObject>)overCapMilestones);
        for (pse__Milestone__c overCapMilestone : overCapMilestones) {
            overCapMilestonMap.put(overCapMilestone.pse__Project__c, overCapMilestone.Id);
        }

        //Master list of billable Timecard Splits
        billableTimecardSplits = getBillableTCSplitsList(projectIds, periodEndDate, approvedTimecardIds);
        if (billableTimecardSplits == null || billableTimecardSplits.size() == 0) {
            //No valid billable timecard splits were found, so exiting the method
            System.debug('No valid billable timecard splits were found, so exiting the method');
            return;
        }
        System.debug('Daily Cap: Billable Timecard Splits Size/List: ' + billableTimecardSplits.size() + '/' + billableTimecardSplits);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billable Timecard Splits List: ' + billableTimecardSplits.size(), String.valueOf(billableTimecardSplits), (List<SObject>)billableTimecardSplits);

        //Populate a set of timecard ids and update the "earliestDate" as needed
        if (billableTimecardSplits != null && billableTimecardSplits.size() > 0) {
            for (pse__Timecard__c tc : billableTimecardSplits) {
                timecardIds.add(tc.pse__Timecard_Header__c);
                if (tc.pse__Timecard_Header__r.pse__Start_Date__c < earliestDate) {
                    earliestDate = tc.pse__Timecard_Header__r.pse__Start_Date__c;
                }
            }
        }
        System.debug('Earliest Date: ' + earliestDate);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Earliest Date: ' + earliestDate, null, null);

        //Master list of over the cap Timecard Splits
        overTheCapTimecardSplits = 
            [Select Id, pse__Billing_Event_Item__c, 
                    pse__Project__c, 
                    pse__Assignment__c, 
                    pse__Resource__c, 
                    pse__Start_Date__c,                     
                    pse__Monday_Hours__c, 
                    pse__Tuesday_Hours__c, 
                    pse__Wednesday_Hours__c, 
                    pse__Thursday_Hours__c, 
                    pse__Friday_Hours__c, 
                    pse__Saturday_Hours__c, 
                    pse__Sunday_Hours__c, 
                    pse__Timecard_Header__c, 
                    pse__Total_Hours__c, 
                    pse__Timecard_Header__r.pse__Start_Date__c, 
                    CurrencyISOCode
                From pse__Timecard__c
                Where pse__Project__c = :projectIds 
                And pse__Project__r.PSA_Daily_Cap__c != null 
                And pse__End_Date__c <= :periodEndDate 
                And pse__Timecard_Header__r.pse__Start_Date__c >= :earliestDate 
                And pse__Timecard_Header__r.pse__Milestone__r.Name = :overCapMilestoneName 
            ];
//                And pse__Billing_Event_Item__r.pse__Billing_Event__r.pse__Is_Released__c = false

        System.debug('Daily Cap: Over the Cap Timecard Splits List: ' + overTheCapTimecardSplits);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Over the Cap Timecard Splits List', String.valueOf(overTheCapTimecardSplits), null);

        //Add to the set of Timecard Ids which will be used to populate a Timecard Header map
        if (overTheCapTimecardSplits != null && overTheCapTimecardSplits.size() > 0) {
            for (pse__Timecard__c tc : overTheCapTimecardSplits) {
                timecardIds.add(tc.pse__Timecard_Header__c);
            }
        }

        //Populate a master map of timecard headers by Id
        timecardHeaderMap = new Map<Id, pse__Timecard_Header__c>(
            [Select Id, Name, 
                    pse__Project__c, 
                    pse__Assignment__c, 
                    pse__Resource__c, 
                    pse__Start_Date__c,                     
                    pse__Monday_Hours__c, 
                    pse__Tuesday_Hours__c, 
                    pse__Wednesday_Hours__c, 
                    pse__Thursday_Hours__c, 
                    pse__Friday_Hours__c, 
                    pse__Saturday_Hours__c, 
                    pse__Sunday_Hours__c, 
                    pse__Milestone__r.Name, 
                    PSA_Over_Cap_Timecard__c 
                From pse__Timecard_Header__c
                Where Id = :timecardIds             
            ]);
        //Populate a master map of timecard headers by unique "key"
        timecardHeaderKeyMap = new Map<String, pse__Timecard_Header__c>();
        if (timecardHeaderMap != null && timecardHeaderMap.size() > 0) {
            for (pse__Timecard_Header__c tcHeader : timecardHeaderMap.values()) {
                //mapKey = tcHeader.Id;
                mapKey = tcHeader.pse__Project__c + ':' + 
                            tcHeader.pse__Assignment__c + ':' + 
                            tcHeader.pse__Resource__c + ':' + 
                            String.valueOf(tcHeader.pse__Start_Date__c) + ':' + 
                            tcHeader.pse__Milestone__r.Name;
                timecardHeaderKeyMap.put(mapKey, tcHeader);
                System.debug('adding timecard header key map record: ' + mapKey + ' - ' + tcHeader);
            }
        }

        if (billableTimecardSplits != null && billableTimecardSplits.size() > 0) {
            Decimal hours;
            pse__Proj__c project;
            Decimal dailyCap;
            String dayOfWeek;

            //First loop through each billable TC split and split out any time which exceeds the daily cap
            for (pse__Timecard__c tc : billableTimecardSplits) {
                project = projectMap.get(tc.pse__Project__c);
                System.debug('Daily Cap: Project Name: ' + project.Name);
                dailyCap = project.PSA_Daily_Cap__c;
                System.debug('Daily Cap: Daily Cap Hours on Project: ' + dailyCap);

                //Set the mapKey in case hours need to be adjusted
                //mapKey = tc.pse__Timecard_Header__c;
                mapKey = tc.pse__Project__c + ':' + 
                            tc.pse__Assignment__c + ':' + 
                            tc.pse__Resource__c + ':' + 
                            String.valueOf(tc.pse__Timecard_Header__r.pse__Start_Date__c);
                System.debug('billableTimecardSplits MapKey: ' + mapKey);

                //Check for hours over the daily cap for each day of the week
                dayOfWeek = 'Monday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Monday_Hours__c, tc.pse__Timecard_Header__c);              
                
                dayOfWeek = 'Tuesday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Tuesday_Hours__c, tc.pse__Timecard_Header__c);              

                dayOfWeek = 'Wednesday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Wednesday_Hours__c, tc.pse__Timecard_Header__c);              

                dayOfWeek = 'Thursday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Thursday_Hours__c, tc.pse__Timecard_Header__c);              

                dayOfWeek = 'Friday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Friday_Hours__c, tc.pse__Timecard_Header__c);              

                dayOfWeek = 'Saturday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Saturday_Hours__c, tc.pse__Timecard_Header__c);              

                dayOfWeek = 'Sunday';
                processEachDay(dayOfWeek, mapKey, dailyCap, true, project, tc.pse__Sunday_Hours__c, tc.pse__Timecard_Header__c);
            }
            //DML statements
            processDMLLogic();


            //Second, loop through each arTimecardHours record and split out time over the cap if applicable
            // This handles the condition if 2 timecards both of which are under the daily cap have a combined
            // total of more than the daily cap

            //Reset the list of billable Timecard Splits since they may have been modified
            billableTimecardSplits = getBillableTCSplitsList(projectIds, periodEndDate, approvedTimecardIds);
            System.debug('Daily Cap: 2nd Billable Timecard Splits Size/List: ' + billableTimecardSplits.size() + '/' + billableTimecardSplits);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, '2nd Billable Timecard Splits List: ' + billableTimecardSplits.size(), String.valueOf(billableTimecardSplits), (List<SObject>)billableTimecardSplits);

            //Re-Populate a master map of timecard headers by Id
            timecardHeaderMap = new Map<Id, pse__Timecard_Header__c>(
                [Select Id, Name, 
                        pse__Project__c, 
                        pse__Assignment__c, 
                        pse__Resource__c, 
                        pse__Start_Date__c,                     
                        pse__Monday_Hours__c, 
                        pse__Tuesday_Hours__c, 
                        pse__Wednesday_Hours__c, 
                        pse__Thursday_Hours__c, 
                        pse__Friday_Hours__c, 
                        pse__Saturday_Hours__c, 
                        pse__Sunday_Hours__c, 
                        pse__Milestone__r.Name, 
                        PSA_Over_Cap_Timecard__c 
                    From pse__Timecard_Header__c
                    Where Id = :timecardIds             
                ]);
            //Re-Populate a master map of timecard headers by unique "key"
            timecardHeaderKeyMap = new Map<String, pse__Timecard_Header__c>();
            if (timecardHeaderMap != null && timecardHeaderMap.size() > 0) {
                for (pse__Timecard_Header__c tcHeader : timecardHeaderMap.values()) {
                    mapKey = tcHeader.pse__Project__c + ':' + 
                                tcHeader.pse__Assignment__c + ':' + 
                                tcHeader.pse__Resource__c + ':' + 
                                String.valueOf(tcHeader.pse__Start_Date__c) + ':' + 
                                tcHeader.pse__Milestone__r.Name;
                    timecardHeaderKeyMap.put(mapKey, tcHeader);
                    System.debug('2nd time adding timecard headermap record: ' + mapKey + ' - ' + tcHeader);
                }
            }

            //Get summary of timecard hours by project, assignment, resource, and start date
            AggregateResult[] arTimecardHours = 
                [Select pse__Project__c ProjectId, 
                        pse__Assignment__c AssignmentId, 
                        pse__Resource__c ResourceId, 
                        pse__Timecard_Header__r.pse__Start_Date__c StartDate, 
                        Sum(pse__Monday_Hours__c) MondayHours, 
                        Sum(pse__Tuesday_Hours__c) TuesdayHours, 
                        Sum(pse__Wednesday_Hours__c) WednesdayHours, 
                        Sum(pse__Thursday_Hours__c) ThursdayHours, 
                        Sum(pse__Friday_Hours__c) FridayHours, 
                        Sum(pse__Saturday_Hours__c) SaturdayHours, 
                        Sum(pse__Sunday_Hours__c) SundayHours 
                    From pse__Timecard__c
                    Where pse__Project__c = :projectIds
                    And pse__Project__r.PSA_Daily_Cap__c != null 
                    And pse__End_Date__c <= :periodEndDate 
                    And pse__Timecard_Header__r.pse__Start_Date__c >= :earliestDate 
                    And pse__Billable__c = true
                    And pse__Timecard_Header__r.pse__Bill_Rate__c > 0
                    And pse__Timecard_Header__r.pse__Approved__c = true
                    And pse__Milestone__r.name != :excludedBillableOvertimeMilestoneName
                    Group by pse__Project__c, pse__Assignment__c, pse__Resource__c, pse__Timecard_Header__r.pse__Start_Date__c
                    Order by pse__Project__c, pse__Assignment__c,  pse__Resource__c, pse__Timecard_Header__r.pse__Start_Date__c
                ];
//                    And (pse__Billable__c = true Or pse__Timecard_Header__r.pse__Milestone__r.Name = :overCapMilestoneName) 
//                  And pse__Timecard_Header__r.pse__Milestone__r.Name != :overCapMilestoneName 
//            system.debug('Period End Date: ' + periodEndDate);
//            System.debug('Earliest Date: ' + earliestDate);
            System.debug('Daily Cap: Total Hours Summary: ' + arTimecardHours);

            for (AggregateResult ar : arTimecardHours) {
                project = projectMap.get((Id)ar.get('ProjectId'));
                System.debug('Daily Cap: Project Name: ' + project.Name);
                dailyCap = project.PSA_Daily_Cap__c;
                System.debug('Daily Cap: Daily Cap Hours on Project: ' + dailyCap);

                //Set the mapKey in case hours need to be adjusted
                mapKey = project.Id + ':' + (Id)ar.get('AssignmentId') + ':' + 
                    (Id)ar.get('ResourceId') + ':' + String.valueOf((Date)ar.get('StartDate'));
                System.debug('arTimecardHours MapKey: ' + mapKey);

                //Check for hours over the daily cap for each day of the week
                dayOfWeek = 'Monday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('MondayHours'), null);              
                
                dayOfWeek = 'Tuesday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('TuesdayHours'), null);              

                dayOfWeek = 'Wednesday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('WednesdayHours'), null);              

                dayOfWeek = 'Thursday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('ThursdayHours'), null);              

                dayOfWeek = 'Friday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('FridayHours'), null);              

                dayOfWeek = 'Saturday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('SaturdayHours'), null);              

                dayOfWeek = 'Sunday';
                processEachDay(dayOfWeek, mapKey, dailyCap, false, project, (Decimal)ar.get('SundayHours'), null);
            }
        }

        //DML statements
        processDMLLogic();
    }

    /**************************************************************************************
    // Name         : processEachDay
    // Description  : Execute the timecard cap logic for a given day of the week
    // Author       : CLD Partners
    // Revisions    : 2015-07-24  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static void processEachDay(String dayOfWeek, String mapKey, Decimal dailyCap, Boolean singleSplitRecord, 
            pse__Proj__c project, Decimal hours, Id tcHeaderId) {
        if ( (hours > 0 && hours > dailyCap) || (hours < 0 && hours < (dailyCap * -1) ) ) {
            System.debug('Daily Cap: Hours for ' + dayOfWeek + ': ' + hours);
            if (hours < 0) {
                processOverCapTimecardsByDay(dayOfWeek, mapKey, hours, dailyCap * -1, 
                    project.Id, false, singleSplitRecord, tcHeaderId);
            } else {
                processOverCapTimecardsByDay(dayOfWeek, mapKey, hours, dailyCap, 
                    project.Id, true, singleSplitRecord, tcHeaderId);
            }
        }
    }

    /**************************************************************************************
    // Name         : processOverCapTimecardsByDay
    // Description  : Update billable timecard headers (and splits), reducing the total hours
    //                  billed on a given day to the daily cap.  Also, create/update over the  
    //                  daily cap timecardheader (and split) records.
    //                The reduction in hours for each TC Split that contributes to the overage
    //                  is based on the pct of total hours that TC Split contributes to the 
    //                  overage.  Below is a breakdown of how that works:
    //                BMH = Billable Milestone Hours (TC Split)
    //                TBMH = Total of all BMH (TC Splits)
    //                DC = Daily Cap (Set on the Project)
    //                OMH = Overage Milestone Hours (Total Hours for Billable TC Splits for that day minus the Daily Cap)
    //                BMHAP = Billable Milestone Hours After Processing (Adjusted hours on a individual TC Split)
    //                OMH = (TBMH - DC)
    //                BMHAP = BMH-((BMH/TBMH)*OMH)
    //
    // Author       : CLD Partners
    // Revisions    : 2015-05-12  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static void processOverCapTimecardsByDay(String dayOfWeek, String mapKey,  
            Decimal totalHours, Decimal dailyCap, Id projectId, 
            Boolean positiveHours, Boolean singleSplitRecord, Id tcHeaderId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'processOverCapTimecardsByDay';

        List<pse__Timecard__c> tcSplitsToProcess;
        pse__Timecard_Header__c billableTCHeader;
        pse__Timecard_Header__c overCapTimecardHeader;
        Id overCapMilestoneId;
        Boolean foundBillableTCHeader;
        Decimal currentHours;
        Decimal adjustedHours;
        Decimal overCapHours = totalHours - dailyCap;
        Decimal remainingCapHours = 0.0;    //Used to set adjusted hours on last TC Split to avoid rounding issues
        Integer tcSplitCount;
        Integer counter = 0;
        //Variables needed to create the overage TC. Using the first TC Split for this
        Id resourceId;
        Id assignmentId;
        Id projectPhaseId;
        Id projectLocationId;
        Id billingEventId;
        String currencyCode;
        Date startDate;
        Date endDate;

        //get a list of be items that match
        String keyValue = mapKey;
        if (singleSplitRecord == true) {
            keyValue = tcHeaderId;
        }
        System.debug('processOverCapTimecardsByDay KeyValue: ' + keyValue);
        tcSplitsToProcess = getTimecardSplits(keyValue, billableTimecardSplits, singleSplitRecord, dayOfWeek);
        tcSplitCount = tcSplitsToProcess.size();
        System.debug('Split Count: ' + tcSplitCount);
        System.debug('Daily Cap: tcSplitsToProcess: ' + tcSplitsToProcess);
        if (tcSplitsToProcess.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Daily Cap: tcSplitsToProcess (Count): ' + tcSplitCount, String.valueOf(tcSplitsToProcess), null);

            for (pse__Timecard__c tcSplitToProcess : tcSplitsToProcess) {
                currentHours = getHoursForDayOfWeek(dayOfWeek, tcSplitToProcess); //tcSplitToProcess.pse__Tuesday_Hours__c;
                counter+=1;

                //Set the variables need to create a new Over the Cap Timecard.  Using the first billable TC Split values
                if (counter == 1) {
                    resourceId = tcSplitToProcess.pse__Resource__c;
                    assignmentId = tcSplitToProcess.pse__Assignment__c;
                    projectPhaseId = tcSplitToProcess.pse__Timecard_Header__r.pse__Project_Phase_Object__c;
                    projectLocationId = tcSplitToProcess.pse__Timecard_Header__r.pse__Primary_Project_Location__c;
                    billingEventId = tcSplitToProcess.pse__Billing_Event_Item__r.pse__Billing_Event__c;
                    currencyCode = tcSplitToProcess.pse__Timecard_Header__r.CurrencyISOCode;
                    startDate = tcSplitToProcess.pse__Timecard_Header__r.pse__Start_Date__c;
                    endDate = tcSplitToProcess.pse__Timecard_Header__r.pse__End_Date__c;
                }
        
                //For each TC Split, reduce the hours on the billable timecard
                // The amount to reduce is based on the pct of the TC Split versus the sum of all billable TC Splits for that day
                // (See Method description for implementation details)

                //Set adjusted hours on last TC Split to the remaining over the cap hours to avoid rounding issues
                if (counter == tcSplitCount) {
                    adjustedHours = currentHours - (overCapHours - remainingCapHours);
                } else {
                    adjustedHours = currentHours - ((currentHours / totalHours) * overCapHours);
                }
                remainingCapHours += ((currentHours / totalHours) * overCapHours);
                System.debug('Current Hours: ' + currentHours);
                System.debug('Adjusted Hours: ' + adjustedHours);
                System.debug('Remaining Cap Hours: ' + remainingCapHours);

                //Check for the billableTCHeader in the List of Timecards to Update.  If not found, check the timecardHeaderMap
                foundBillableTCHeader = false;
                billableTCHeader = getTimecardFromList(tcSplitToProcess.pse__Timecard_Header__c, timecardsToUpdate, null, true, null);
                System.debug('Daily Cap: billableTCHeader after searching timecardsToUpdate: ' + billableTCHeader);
                if (billableTCHeader == null) {
                    billableTCHeader = timecardHeaderMap.get(tcSplitToProcess.pse__Timecard_Header__c);
                } else {
                    foundBillableTCHeader = true;
                }
                billableTCHeader = setHoursForDayOfWeek(dayOfWeek, billableTCHeader, adjustedHours, true); //billableTCHeader.pse__Tuesday_Hours__c = dailyCap;
                if (!foundBillableTCHeader) {
                    timecardsToUpdate.add(billableTCHeader);
                }
                System.debug('Daily Cap: billable tc header to update: ' + billableTCHeader);
            }

            //Now that the billable TC Splits have been adjusted, create or update an Over the Cap Timecard
            //First look for an existing over the cap Timecard Header in both the timecardsToUpdate and timecardsToAdd Lists.  
            // If one exists, add the adjusted hours.  If none exists, create a new one
            //1. Check the timecardsToUpdate list
            System.debug('Done with Billable TCs. Now looking for Over Daily Cap timecard');

            //System.debug('Map Key:' + mapKey + ', Positive Hours:' + positiveHours + ' , TCs to Update List:' + timecardsToUpdate);
//            overCapTimecardHeader = getTimecardFromList(mapKey, timecardsToUpdate, overCapMilestoneName, false, positiveHours);
            overCapTimecardHeader = getTimecardFromList(mapKey, timecardsToUpdate, overCapMilestoneName, false, null);          
            if (overCapTimecardHeader != null) {
                overCapTimecardHeader = setHoursForDayOfWeek(dayOfWeek, overCapTimecardHeader, overCapHours, false);
                System.debug('Daily Cap: Found over the cap tc in tc headers to update: ' + overCapTimecardHeader);
            } else {
                //2. Check the timecardsToAdd list
                //System.debug('Daily Cap: Checking timecardsToAdd List: ' + timecardsToAdd);
                //System.debug('OverCap Milestone Map:' + overCapMilestonMap);
                overCapTimecardHeader = getTimecardFromList(mapKey, timecardsToAdd, null, false, null);
                if (overCapTimecardHeader != null) {
                    overCapTimecardHeader = setHoursForDayOfWeek(dayOfWeek, overCapTimecardHeader, overCapHours, false);
                    System.debug('Daily Cap: Found the Over the cap TC Header in the timecardsToAdd: ' + overCapTimecardHeader);
                } else {
                    //3. Check the timecard map.  If not found, create a new timecard
                    mapKey += ':' + overCapMilestoneName;
                    System.debug('checking timecard map using key: ' + mapKey);
                    overCapTimecardHeader = timecardHeaderKeyMap.get(mapKey);
                    if (overCapTimecardHeader == null) {
                        System.debug('Daily Cap: Need to create new TC Header');
                        overCapMilestoneId = overCapMilestonMap.get(projectId);
                        //Create a new Timecard
                        timecardsToAdd.add(
                            CreateTimecardHeader(
                                projectId, 
                                resourceId, 
                                assignmentId, 
                                dayOfWeek, 
                                overCapHours, 
                                0.0, 
                                overCapMilestoneId, 
                                projectPhaseId, 
                                projectLocationId, 
                                billingEventId, 
                                currencyCode, 
                                startDate, 
                                endDate, 
                                false
                            )
                        );
                    } else {
                        System.debug('Daily Cap: Found over the cap tc in the tc header key map: ' + overCapTimecardHeader);
                        overCapTimecardHeader = setHoursForDayOfWeek(dayOfWeek, overCapTimecardHeader, overCapHours, false);
                        timecardsToUpdate.add(overCapTimecardHeader);
                    }
                }
            }
        }
    }

    /**************************************************************************************
    // Name         : getHoursForDayOfWeek
    // Description  : Get the billable timecard hours for a specific day
    // Author       : CLD Partners
    // Revisions    : 2015-05-12  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static Decimal getHoursForDayOfWeek(String dayOfWeek, 
            pse__Timecard__c tcSplit) {
        Decimal hours = 0.0;

        if (dayOfWeek == 'Monday') {
            hours = tcSplit.pse__Monday_Hours__c;
        } else if (dayOfWeek == 'Tuesday') {
            hours = tcSplit.pse__Tuesday_Hours__c;
        } else if (dayOfWeek == 'Wednesday') {
            hours = tcSplit.pse__Wednesday_Hours__c;
        } else if (dayOfWeek == 'Thursday') {
            hours = tcSplit.pse__Thursday_Hours__c;
        } else if (dayOfWeek == 'Friday') {
            hours = tcSplit.pse__Friday_Hours__c;
        } else if (dayOfWeek == 'Saturday') {
            hours = tcSplit.pse__Saturday_Hours__c;
        } else if (dayOfWeek == 'Sunday') {
            hours = tcSplit.pse__Sunday_Hours__c;
        }

        return hours;
    }

    /**************************************************************************************
    // Name         : setHoursForDayOfWeek
    // Description  : Update the billable timecard hours for a specific day.  Billable 
    //                  timecards will have their hours set to the daily cap, while
    //                  over the cap timecards will have their hours added on to
    // Author       : CLD Partners
    // Revisions    : 2015-05-12  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static pse__Timecard_Header__c setHoursForDayOfWeek(String dayOfWeek, 
            pse__Timecard_Header__c tcHeader, Decimal hours, boolean replaceHours) {

        if (replaceHours == true) {
            if (dayOfWeek == 'Monday') {
                tcHeader.pse__Monday_Hours__c = hours;
            } else if (dayOfWeek == 'Tuesday') {
                tcHeader.pse__Tuesday_Hours__c = hours;
            } else if (dayOfWeek == 'Wednesday') {
                tcHeader.pse__Wednesday_Hours__c = hours;
            } else if (dayOfWeek == 'Thursday') {
                tcHeader.pse__Thursday_Hours__c = hours;
            } else if (dayOfWeek == 'Friday') {
                tcHeader.pse__Friday_Hours__c = hours;
            } else if (dayOfWeek == 'Saturday') {
                tcHeader.pse__Saturday_Hours__c = hours;
            } else if (dayOfWeek == 'Sunday') {
                tcHeader.pse__Sunday_Hours__c = hours;
            }
        } else {
            if (dayOfWeek == 'Monday') {
                tcHeader.pse__Monday_Hours__c += hours;
            } else if (dayOfWeek == 'Tuesday') {
                tcHeader.pse__Tuesday_Hours__c += hours;
            } else if (dayOfWeek == 'Wednesday') {
                tcHeader.pse__Wednesday_Hours__c += hours;
            } else if (dayOfWeek == 'Thursday') {
                tcHeader.pse__Thursday_Hours__c += hours;
            } else if (dayOfWeek == 'Friday') {
                tcHeader.pse__Friday_Hours__c += hours;
            } else if (dayOfWeek == 'Saturday') {
                tcHeader.pse__Saturday_Hours__c += hours;
            } else if (dayOfWeek == 'Sunday') {
                tcHeader.pse__Sunday_Hours__c += hours;
            }
        }

        return tcHeader;
    }  

    /**************************************************************************************
    // Name         : processDMLLogic
    // Description  : Insert/Update timecard headers.  Insert new billing event items as
    //                  needed.
    // Author       : CLD Partners
    // Revisions    : 2015-05-12  Klassen  Initial Implementation
    //              : 2015-07-26  Klassen  Removed Billing Event Item creation, because GW
    //                  doesn't need any information from Excess Over the Daily Cap timecards
    //                  referenced with any billing information
    //              : 2015-11-23  Klassen  Add logic to temporarily add TC Ops Edit permission
    //                  control in case Excess Over the Daily Cap timecard(s) need to be added
    ***************************************************************************************/
    private static void processDMLLogic() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'processDMLLogic';

        //added by cklassen 11/22/15 to temporarily assign the Timecard Ops Edit permission 
        //  control if the user doesn't already have this
        pse__Permission_Control__c pcTemp = addPermissionControl(UserInfo.getUserId());
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'PC with Updated TC Ops Edit permission (null if none updated)', String.valueOf(pcTemp), null);

        //Insert timecard headers (and splits).  Also, create billing event items for newly inserted timecard headers, and update
        // the billing event item lookup field on the newly inserted timecard headers (will need to do a dml update on the timecards.)
        if (timecardsToAdd.size() > 0) {
            insert timecardsToAdd;
            System.debug('Daily Cap: timecardsToAdd: ' + timecardsToAdd);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'DML timecards To add', String.valueOf(timecardsToAdd), null);
            timecardsToAdd = new List<pse__Timecard_Header__c>();            
        }

        //Update timecard headers
        if (timecardsToUpdate.size() > 0) {
            System.debug('Daily Cap: final TC Headers to Update: ' + timecardsToUpdate);

            update timecardsToUpdate;
            timecardsToUpdate = new List<pse__Timecard_Header__c>();
        }

        //Remove the TC Ops Edit permission control if it was added in code above        
        if (pcTemp != null) {
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Removing TC Ops Edit permission control', String.valueOf(pcTemp), null);
            removePermissionControl(pcTemp);
        }
    }

    /**************************************************************************************
    // Name         : addPermissionControl
    // Description  : Check if the user has permission to edit an approved timecard.  If not
    //                  temporarily add this permission control setting for the user
    // Author       : CLD Partners
    // Revisions    : 2015-11-22  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static pse__Permission_Control__c addPermissionControl (Id userId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'addPermissionControl';

        Boolean timecardOpsEditFound = false;
        pse__Permission_Control__c updatedPermissionControl;
        List<pse__Permission_Control__c> permissionControls = 
            [Select Id, Name, pse__Timecard_Ops_Edit__c
                From pse__Permission_Control__c
                Where pse__User__c =: userId
            ];
        System.debug('Current Users PC records: ' + permissionControls);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Current Users PC records', String.valueOf(permissionControls), null);
        if (permissionControls != null && permissionControls.size() > 0) {
            for (pse__Permission_Control__c permissionControl : permissionControls) {
                updatedPermissionControl = permissionControl;
                if (permissionControl.pse__Timecard_Ops_Edit__c == true) {
                    timecardOpsEditFound = true;
                } 
            }

            //If no PC was found that had an TC Ops Edit permission, update the 
            // most recently found PC
            if (timecardOpsEditFound == false) {
                System.debug('Updating Permission Control: ' + updatedPermissionControl);                
                updatedPermissionControl.pse__Timecard_Ops_Edit__c = true;
                update updatedPermissionControl;                
            } else {
                updatedPermissionControl = null;
            }
        }

        return updatedPermissionControl;
    }

    /**************************************************************************************
    // Name         : removePermissionControl
    // Description  : Remove the permission to edit an approved timecard. 
    // Author       : CLD Partners
    // Revisions    : 2015-11-22  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static void removePermissionControl (pse__Permission_Control__c pc) {
        System.debug('Removing Permission Control: ' + pc);
        pc.pse__Timecard_Ops_Edit__c = false;
        update pc;
    }

    /**************************************************************************************
    // Name         : createTimecardHeader
    // Description  : Create a timecard header for a new over the cap timecard. The bill rate
    //                  default from the over cap milestone ($0.00 bill rate)
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static pse__Timecard_Header__c createTimecardHeader (Id projId,  Id resourceId, 
            Id assignmentId, String dayOfWeek, Decimal hours, Decimal billRate, 
            Id milestoneId, Id phaseId, Id projectLocationId, Id billingEventId, 
            String currencyCode, Date startDate, Date endDate, Boolean billable) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'createTimecardHeader';

        pse__Timecard_Header__c psaTimecard = new pse__Timecard_Header__c();
        psaTimecard.pse__Resource__c = resourceId;
        psaTimecard.pse__Project__c = projId;
        psaTimecard.pse__Assignment__c = assignmentId;
        psaTimecard.pse__Bill_Rate__c = billRate;
        psaTimecard.pse__Bill_Rate_Defaulted_from_Milestone__c = true;
        psaTimecard.pse__Milestone__c = milestoneId;
        psaTimecard.pse__Project_Phase_Object__c = phaseId;
        psaTimecard.pse__Primary_Project_Location__c = projectLocationId;
        psaTimecard.pse__Status__c = 'Approved'; //Saved
        psaTimecard.pse__Submitted__c = true;
        psaTimecard.pse__Approved__c = true;
        psaTimecard.PSA_Approved_Date__c = Date.today();
        psaTimecard.PSA_Submitted_Date__c = Date.today();
        psaTimecard.PSA_Over_Cap_Billing_Event__c = billingEventId;
        psaTimecard.CurrencyISOCode = currencyCode;
        psaTimecard.pse__Start_Date__c = startDate;
        psaTimecard.pse__End_Date__c = endDate;
        psaTimecard.pse__Billable__c = billable;

        psaTimecard.pse__Monday_Hours__c = 0.0;
        psaTimecard.pse__Tuesday_Hours__c = 0.0;
        psaTimecard.pse__Wednesday_Hours__c = 0.0;
        psaTimecard.pse__Thursday_Hours__c = 0.0;
        psaTimecard.pse__Friday_Hours__c = 0.0;
        psaTimecard.pse__Saturday_Hours__c = 0.0;
        psaTimecard.pse__Sunday_Hours__c = 0.0;

        if (dayOfWeek == 'Monday') {
            psaTimecard.pse__Monday_Hours__c = hours;
        }else if (dayOfWeek == 'Tuesday') {
            psaTimecard.pse__Tuesday_Hours__c = hours;
        }else if (dayOfWeek == 'Wednesday') {
            psaTimecard.pse__Wednesday_Hours__c = hours;
        }else if (dayOfWeek == 'Thursday') {
            psaTimecard.pse__Thursday_Hours__c = hours;
        }else if (dayOfWeek == 'Friday') {
            psaTimecard.pse__Friday_Hours__c = hours;
        }else if (dayOfWeek == 'Saturday') {
            psaTimecard.pse__Saturday_Hours__c = hours;
        } else if (dayOfWeek == 'Sunday') {
            psaTimecard.pse__Sunday_Hours__c = hours;
        }
        return psaTimecard;
    }

    /**************************************************************************************
    // Name         : getTimecardFromList
    // Description  : Look for an over the cap timecard header from the a timecard header  
    //                  list variable
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 2015-07-26  Klassen  Added logic to handle multiple timecards for one
    //                  project for the Excess over the daily cap milestone (one positive 
    //                  and one for negative hours)
    //              : 2015-09-28  Klassen  No longer splitting the over daily cap timecards
    //                  into separate positive and negative hours timecards
    ***************************************************************************************/
    private static pse__Timecard_Header__c getTimecardFromList(String keyValue, 
            List<pse__Timecard_Header__c> timecardHeaders, String milestoneName, 
            Boolean searchById, Boolean positiveHours) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getTimecardFromList';

        System.debug('Daily Cap: Begin getTimecardFromList: keyValue and Milestone Name: ' + keyValue + ' (' + milestoneName + ')');

        String tcHeaderKey;
        for(pse__Timecard_Header__c tcHeader : timecardHeaders) {
            if (!searchById) { 
                tcHeaderKey = tcHeader.pse__Project__c + ':' + 
                            tcHeader.pse__Assignment__c + ':' + 
                            tcHeader.pse__Resource__c + ':' + 
                            String.valueOf(tcHeader.pse__Start_Date__c).Replace(' 00:00:00', '');
            } else {
                tcHeaderKey = tcHeader.Id;
            }

            //System.debug('TC Header Milestone Name: ' + tcHeader.pse__Milestone__r.Name);

            //System.debug('Daily Cap: getTimecardFromList tcHeaderKey and milestone name: ' + tcHeaderKey + ' (' + tcHeader.pse__Milestone__r.Name + ')');
            if (tcHeaderKey == keyValue && (milestoneName == null || tcHeader.pse__Milestone__r.Name == milestoneName)) {
                System.debug('Daily Cap: getTimecardFromList: Found TC Header: ' + tcHeader + ' (' + tcHeaderKey + ')');
                return tcHeader;
            }
        }
        
        System.debug('getTimecardFromList no timecard header found');
        return null;
    }

    /**************************************************************************************
    // Name         : getTimecardSplits
    // Description  : Get a list of billable or over the cap timecards splits that may need 
    //                  to be adjusted.  If any over the cap timecard splits are found, there
    //                  should may be one or two values (one for positve adjustments and one
    //                  for negative adjustments).  
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 2015-10-13  Klassen  Exclude any TC Splits for zero hours for a specific day
    ***************************************************************************************/
    private static List<pse__Timecard__c> getTimecardSplits(String keyValue, 
            List<pse__Timecard__c> timecardSplits, Boolean singleSplitRecord, 
            String dayOfWeek) {
        List<pse__Timecard__c> matchingTimecardSplits = new List<pse__Timecard__c>();

        String tcSplitKey;
        for(pse__Timecard__c tcSplit : timecardSplits) {
            if (singleSplitRecord == true) {
                tcSplitKey = tcSplit.pse__Timecard_Header__c;
            } else {
                tcSplitKey = tcSplit.pse__Project__c + ':' + 
                                tcSplit.pse__Assignment__c + ':' + 
                                tcSplit.pse__Resource__c + ':' + 
                                String.valueOf(tcSplit.pse__Timecard_Header__r.pse__Start_Date__c);
            }

            if (tcSplitKey == keyValue) {
                //System.debug('Found TC Split record: ' + tcSplit + ' (' + tcSplitKey + ')');
                if (getHoursForDayOfWeek(dayOfWeek, tcSplit) != 0) {
                    matchingTimecardSplits.add(tcSplit);
                } else {
                    System.debug('Excluding TC Split b/c zero hours for: ' + dayOfWeek);
                }
            }
        }
        
        return matchingTimecardSplits;
    }

    /**************************************************************************************
    // Name         : createMilestone
    // Description  : Create the "over the cap" milestone for a project
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private static void createMissingMilestones(Set<Id> projectIds, List<pse__Proj__c> projects, 
            String overCapMilestoneNameInput) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'createMissingMilestones';

        List<pse__Milestone__c> milestonesToAdd = new List<pse__Milestone__c>();

        Map<Id, Id> existingOverCapMilestonMap = new Map<Id, Id>();
        List<pse__Milestone__c> overCapMilestones = 
            [Select Id, pse__Project__c 
                From pse__Milestone__c 
                Where pse__Project__c = :projectIds
                And Name = :overCapMilestoneNameInput
            ];
        if (overCapMilestones != null && overCapMilestones.size() > 0) {
            for (pse__Milestone__c overCapMilestone : overCapMilestones) {
                existingOverCapMilestonMap.put(overCapMilestone.pse__Project__c, overCapMilestone.Id);
            }
        }
        
        Id foundMilestoneId;
        for (pse__Proj__c project : projects) {
            foundMilestoneId = existingOverCapMilestonMap.get(project.Id);
            if (foundMilestoneId == null) {
                milestonesToAdd.add(
                    createMilestone(overCapMilestoneNameInput, project.Id, false, false, 
                        project.pse__End_Date__c, project.CurrencyISOCode)
                );
            }
        }

        if (milestonesToAdd.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Milestones To add', String.valueOf(milestonesToAdd), null);

            insert milestonesToAdd;
        }
    }

    /**************************************************************************************
    // Name         : createMilestone
    // Description  : Create the "over the cap" milestone for a project (if it doesn't 
    //                  already exist)
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 2015-07-26  Klassen  Added Utilization Type = "Time Credited"
    ***************************************************************************************/
    private static pse__Milestone__c createMilestone(String milestoneName, Id projectId, 
            boolean cfte, boolean cfee, Date targetDate, String currencyCode) {
        pse__Milestone__c milestone = new pse__Milestone__c(Name=milestoneName);
        milestone.pse__Project__c = projectId;
        milestone.pse__Closed_for_Expense_Entry__c = cfee;
        milestone.pse__Closed_for_Time_Entry__c = cfte;
        milestone.pse__Target_Date__c = targetDate;
        milestone.pse__Description__c = 'Created by automation';
        milestone.pse__Status__c = 'Planned';
        milestone.PSA_Milestone_Type__c = 'Non-Billable';
        milestone.pse__Default_Bill_Rate__c = 0.0;
        milestone.pse__Apply_Default_Bill_Rate_to_Timecard__c = true;
        milestone.CurrencyISOCode = currencyCode;
        milestone.PSA_Utilization_Type__c = 'Time Credited';

        return milestone;
    }

    /**************************************************************************************
    // Name         : getBillableTCSplitsList
    // Description  : Get the list of billable TC Splits 
    //                  
    // Author       : CLD Partners
    // Revisions    : 2015-09-04  Klassen  Initial Implementation
    //              : 2015-09-29  Klassen  Include filter for specific timecards
    ***************************************************************************************/
    private static List<pse__Timecard__c> getBillableTCSplitsList(Set<Id> projIds, 
            Date endDate, Set<Id> approvedTimecardIds) {
        //Master list of billable Timecard Splits
        List<pse__Timecard__c> billableTCSplits;
        System.debug('End Date: ' + endDate);

        //If approvedTimecardIds is not null, filter the list to just those timecards, else
        //  get all the timecard splits for the project prior to the end date
        if (approvedTimecardIds != null) {
            //1. Populate a set of Timecard "keys" which will be used to get the list of all
            // relevant billable timecards that should have the over the daily cap logic 
            // performed on them
            List<pse__Timecard__c> coreBillableTCSplits = 
                [Select Id, pse__Timecard_Header__r.PSA_Timecard_Daily_Cap_Key__c
                    From pse__Timecard__c
                    Where pse__Project__c = :projIds 
                    And pse__Project__r.PSA_Daily_Cap__c != null 
                    And pse__Billing_Event_Item__r.pse__Billing_Event__r.pse__Is_Released__c = false
                    And pse__End_Date__c <= :endDate 
                    And pse__Billable__c = true 
                    And pse__Timecard_Header__r.pse__Bill_Rate__c > 0
                    And pse__Milestone__r.name != :excludedBillableOvertimeMilestoneName
                    And pse__Timecard_Header__c =: approvedTimecardIds
                ];
            System.debug('core billable tc splits: ' + coreBillableTCSplits);

            //2. Populate a set of assignment Ids which will be used to filter a list of all possible
            //      billable timecard splits
            Set<String> timecardKeys = new Set<String>();
            if (coreBillableTCSplits != null && coreBillableTCSplits.size() > 0) {
                System.debug('Number of Valid Approved Timecard Splits: ' + coreBillableTCSplits.size());

                for (pse__Timecard__c tcSplit : coreBillableTCSplits) {
                    timecardKeys.add(tcSplit.pse__Timecard_Header__r.PSA_Timecard_Daily_Cap_Key__c);
                }

                //3. Now get the list of all relevant timecard splits
                billableTCSplits = 
                    [Select Id, pse__Billing_Event_Item__c, 
                            pse__Billing_Event_Item__r.pse__Billing_Event__c, 
                            pse__Project__c, 
                            pse__Assignment__c, 
                            pse__Resource__c, 
                            pse__Start_Date__c,                     
                            pse__Monday_Hours__c, 
                            pse__Tuesday_Hours__c, 
                            pse__Wednesday_Hours__c, 
                            pse__Thursday_Hours__c, 
                            pse__Friday_Hours__c, 
                            pse__Saturday_Hours__c, 
                            pse__Sunday_Hours__c, 
                            pse__Timecard_Header__r.pse__Project_Phase_Object__c, 
                            pse__Timecard_Header__r.pse__Primary_Project_Location__c, 
                            pse__Timecard_Header__c, 
                            pse__Timecard_Header__r.CurrencyISOCode, 
                            pse__Timecard_Header__r.pse__Start_Date__c, 
                            pse__Timecard_Header__r.pse__End_Date__c 
                        From pse__Timecard__c
                        Where pse__Timecard_Header__r.PSA_Timecard_Daily_Cap_Key__c =: timecardKeys
                        And pse__Billable__c = true 
                        And pse__Timecard_Header__r.pse__Bill_Rate__c > 0
                        And pse__Milestone__r.name != :excludedBillableOvertimeMilestoneName
                        And pse__Billing_Event_Item__r.pse__Billing_Event__r.pse__Is_Released__c = false
                    ];
            }
        } else {
            billableTCSplits = 
                [Select Id, pse__Billing_Event_Item__c, 
                        pse__Billing_Event_Item__r.pse__Billing_Event__c, 
                        pse__Project__c, 
                        pse__Assignment__c, 
                        pse__Resource__c, 
                        pse__Start_Date__c,                     
                        pse__Monday_Hours__c, 
                        pse__Tuesday_Hours__c, 
                        pse__Wednesday_Hours__c, 
                        pse__Thursday_Hours__c, 
                        pse__Friday_Hours__c, 
                        pse__Saturday_Hours__c, 
                        pse__Sunday_Hours__c, 
                        pse__Timecard_Header__r.pse__Project_Phase_Object__c, 
                        pse__Timecard_Header__r.pse__Primary_Project_Location__c, 
                        pse__Timecard_Header__c, 
                        pse__Timecard_Header__r.CurrencyISOCode, 
                        pse__Timecard_Header__r.pse__Start_Date__c, 
                        pse__Timecard_Header__r.pse__End_Date__c 
                    From pse__Timecard__c
                    Where pse__Project__c = :projIds 
                    And pse__Project__r.PSA_Daily_Cap__c != null 
                    And pse__Billing_Event_Item__r.pse__Billing_Event__r.pse__Is_Released__c = false
                    And pse__End_Date__c <= :endDate 
                    And pse__Billable__c = true 
                    And pse__Timecard_Header__r.pse__Bill_Rate__c > 0
                    And pse__Timecard_Header__r.pse__Approved__c = true
                    And pse__Milestone__r.name != :excludedBillableOvertimeMilestoneName
                ];
        }
        return billableTCSplits;
    }

    /**************************************************************************************
    // Name         : createBillingEventItem
    // Description  : Used to create new Billing Event Items for new over the cap timecards
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  Initial Implementation
    //              : 2015-09-04  Klassen  No incuding overage timecards in billing so don't
    //                  need this method
    ***************************************************************************************/
    /*
    private static pse__Billing_Event_Item__c createBillingEventItem(Id billingEventId, Id projectId,  
            pse__Timecard__c tcSplit, Id billingEventBatchId, String currencyCode) {
        pse__Billing_Event_Item__c bei = new pse__Billing_Event_Item__c();
        bei.pse__Billing_Event__c = billingEventId;
        bei.pse__Project__c = projectId;
        bei.pse__Amount__c = 0.0;
        bei.pse__Unit_Price__c = 0.0;
        bei.pse__Quantity__c = 1;
        bei.pse__Date__c = Date.today();
        bei.pse__Category__c = 'Timecard';
        bei.pse__Object_Id__c = tcSplit.Id;
        bei.pse__Timecard_Split__c = tcSplit.Id;
        bei.pse__Description__c = 'Created by Automation';
        bei.pse__Billing_Event_Batch__c = billingEventBatchId;
        bei.CurrencyISOCode = currencyCode;
        return bei;
    }
    */

    /**************************************************************************************
    // Name         : updateTimecardSplitsBillingEventItemIds
    // Description  : Retrieves the Billing Event Item Id for newly created Billing Event 
    //                  Items and updates newly inserted Timecard Splits
    // Author       : CLD Partners
    // Revisions    : 2015-05-11  Klassen  (Initial Implementation)
    //              : 2015-09-04  Klassen  No incuding overage timecards in billing so don't
    //                  need this method
    ***************************************************************************************/
    /*
    private static void updateTimecardSplitsBillingEventItemIds(List<pse__Timecard__c> tcSplits, 
            List<pse__Billing_Event_Item__c> beItems) {
        Map<Id, Id> billingEventItemMap = new Map<Id, Id>();
        for (pse__Billing_Event_Item__c beItem : beItems) {
            billingEventItemMap.put(beItem.pse__Timecard_Split__c, beItem.Id);
        }
        for (pse__Timecard__c tcSplit : tcSplits) {
            tcSplit.pse__Billing_Event_Item__c = billingEventItemMap.get(tcSplit.Id);
        }
        update tcSplits;
    }
    */
}