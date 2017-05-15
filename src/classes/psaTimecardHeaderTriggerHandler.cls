/**************************************************************************************
// Name          : psaTimecardHeaderTriggerHandler
// Date          : March 4, 2015
// Description   : Handles all inserts/updates/deletes called by the psaTimecardHeader trigger
// Author        : CLD Partners
// Revisions     : 2015-04-09  Spano revision added setOverrideCostRegion and setEntities
//               : 2015-05-04  Klassen  Changed to pull resource home location values
//                  from the Contact record rather than the Assignment record
//               : 2015-09-29  Klassen  Added logic to run over daily cap logic for all
//                  approved timecards that are billable and not for the billable overtime
//                  milestone ('Billable Over Professional Day Cap')
//               : 2015-10-16  Klassen  Add validation to prevent time from being entered for
//                  2 different months on the same timecard ("checkTimeEnteredForMultipleMonths")
//               : 2015-11-23  Klassen  Add apex logging code to andFinally method
//               : 2015-12-04  Klassen  Update checkTimeEnteredForMultipleMonths method to 
//                  bypass logic if the timecard is non-billable 
***************************************************************************************/
public with sharing class psaTimecardHeaderTriggerHandler implements psaITriggerHandler {
    Map<Id, pse__Assignment__c> assignmentMap;
    Map<Id, pse__Project_Location__c> projectLocationMap;
    Map<Id, pse__Proj__c> projectMap;
    Map<Id, Contact> resourceMap;
    Set<Id> approvedTimecardIds = new Set<Id>();
    Set<Id> approvedTimecardProjectIds = new Set<Id>();
    Date approvedTimecardLatestEndDate;
    String excludedBillableOvertimeMilestoneName = 'Billable Over Professional Day Cap';

    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaTimecardHeaderTriggerHandler';
    private static Integer apexLogMethodSequenceMaster = 0;

    public psaTimecardHeaderTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
        //Populate the contactMap
        if(Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete){
            // Define Set to hold Resource IDs for each assignment
            Set<Id> assignmentIds = new Set<Id>();
            Set<Id> projectLocationIds = new Set<Id>();
            Set<Id> resourceIds = new Set<Id>();
            Set<Id> projectIds = new Set<Id>();

            // Get list of Assignment Ids associated with each timecard
            for (SObject so : Trigger.new) {
                pse__Timecard_Header__c timecard = (pse__Timecard_Header__c)so;
                assignmentIds.add(timecard.pse__Assignment__c);
                projectLocationIds.add(timecard.pse__Primary_Project_Location__c);
                resourceIds.add(timecard.pse__Resource__c);
                projectIds.add(timecard.pse__Project__c);
            }

            // SOQL to look up Billing Level associated with each timecard's assignment
            assignmentMap = new Map<Id, pse__Assignment__c>(
                [SELECT Id, PSA_Billing_Level__c 
                     FROM pse__Assignment__c  
                     WHERE Id In : assignmentIds
                ]);
            // SOQL to look up project locations
            projectLocationMap = new Map<Id, pse__Project_Location__c>(
                [SELECT Id, Name, PSA_City__c, PSA_State_New__c, PSA_Postal_Code__c, PSA_Country_New__c, PSA_State_Province__c, PSA_Country__c 
                     FROM pse__Project_Location__c  
                     WHERE Id In : projectLocationIds 
                ]);
            // SOQL to look up project
            projectMap = new Map<Id, pse__Proj__c>(
                [SELECT Id, PSA_Time_Approval_Method__c, PSA_Billing_Legal_Entity__c, pse__Project_Type__c, 
                        pse__Project_Manager__r.pse__Salesforce_User__c, 
                        PSA_CIM__r.pse__Salesforce_User__c, PSA_Director__r.pse__Salesforce_User__c 
                     FROM pse__Proj__c  
                     WHERE Id In : projectIds 
                ]);
            // SOQL to look up project locations
            resourceMap = new Map<Id, Contact>(
                [SELECT Id, pse__Salesforce_User__r.ManagerId, PSA_Home_Country__c, PSA_Home_State__c, 
                        PSA_Resource_Entity__c, Pse__Region__c, PSA_Fully_Loaded_Cost_Rate__c, 
                        MailingCity, MailingCountry, MailingState, MailingPostalCode
                     FROM Contact  
                     WHERE Id In : resourceIds 
                ]);
        }
    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter(){}
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        pse__Timecard_Header__c timecard = (pse__Timecard_Header__c)so;

        //Check to see if the timecard has hours for multiple months.  If it does, an error will be thrown
        checkTimeEnteredForMultipleMonths(timecard);

        updateBillRateText(timecard);
        setBillingLevel(timecard);
        setProjectLocationFields(timecard);
        setApproversAndFullyLoadedCostRateFields(timecard);
        setOverrideCostRegion(timecard);
        setEntities(timecard);
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        pse__Timecard_Header__c timecardOld = (pse__Timecard_Header__c)oldSo;
        pse__Timecard_Header__c timecardNew = (pse__Timecard_Header__c)so;

        //Check to see if the timecard has hours for multiple months.  If it does, an error will be thrown
        if (timecardOld.pse__Saturday_Hours__c != timecardNew.pse__Saturday_Hours__c || 
                    timecardOld.pse__Sunday_Hours__c != timecardNew.pse__Sunday_Hours__c ||
                    timecardOld.pse__Monday_Hours__c != timecardNew.pse__Monday_Hours__c ||
                    timecardOld.pse__Tuesday_Hours__c != timecardNew.pse__Tuesday_Hours__c ||
                    timecardOld.pse__Wednesday_Hours__c != timecardNew.pse__Wednesday_Hours__c ||
                    timecardOld.pse__Thursday_Hours__c != timecardNew.pse__Thursday_Hours__c ||
                    timecardOld.pse__Friday_Hours__c != timecardNew.pse__Friday_Hours__c) {
            checkTimeEnteredForMultipleMonths(timecardNew);
        }

        if (timecardOld.pse__Primary_Project_Location__c != timecardNew.pse__Primary_Project_Location__c) {
            setProjectLocationFields(timecardNew);
        }
        if(timecardOld.pse__Bill_Rate__c != timecardNew.pse__Bill_Rate__c){
            updateBillRateText(timecardNew);
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
    public void afterUpdate(SObject oldSo, SObject so){
        //If the timecard is newly approved, add it to the set of timecard ids that will be
        // used to trigger the over the daily cap timecard logic.  Only add it to the set of
        // Ids if it is billable and the milestone is null or the milestone name does not 
        // equal "Billable Over Professional Day Cap" 
        pse__Timecard_Header__c oldTC = (pse__Timecard_Header__c)oldSo;
        pse__Timecard_Header__c newTC = (pse__Timecard_Header__c)so;
        //if (oldTC.pse__Status__c != 'Approved' && newTC.pse__Status__c == 'Approved') {
        if (newTC.pse__Status__c == 'Approved' && newTC.pse__Billed__c == false) {
            if (newTC.pse__Billable__c == true) {
                if (newTC.pse__Milestone__c == null || 
                        (newTC.pse__Milestone__c != null && 
                        newTC.pse__Milestone__r.Name != excludedBillableOvertimeMilestoneName)) {
                    System.debug('Approved TC meets criteria to apply the over the daily cap logic: ' + newTC);
                    approvedTimecardIds.add(newTC.Id);
                    approvedTimecardProjectIds.add(newTC.pse__Project__c);
                    //Update the latest end date if applicable.  Needed filter the list of possible billable
                    // timecards in the daily cap logic
                    if (approvedTimecardLatestEndDate == null || 
                            newTC.pse__End_Date__c > approvedTimecardLatestEndDate) {
                        approvedTimecardLatestEndDate = newTC.pse__End_Date__c;
                        System.debug('Updated latest timecard end date: ' + approvedTimecardLatestEndDate);
                    }
                }
            }
        }
    }
 
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
    // Revisions   : 09/30/15  Klassen   Added trigger recursion prevention which was necessary 
    //                  after adding the timecard over the daily cap logic for approved TCs
    // Revisions   : 11/23/15  Klassen   Added custom apex logging code to capture log info 
    //                  
    ***************************************************************************************/
    public void andFinally(){
        //If there are any approved timecards that are eligible for the over the daily cap logic, 
        // run them through the logic.  Prevent trigger recursion if the logic has already been run
        // through one time.
        if (approvedTimecardIds.size() > 0) {
            //update apexLog variables used for custom apex code logging
            apexLogMethodSequenceMaster += 1;
            Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
            String apexLogMethod = 'andFinally';
            psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

            if (psaTriggerMonitor.ExecutedTriggers.contains('psaTimecardHeaderTriggerHandler-after')) {
                System.debug('Skipping psaTimecardHeaderTriggerHandler-after andFinally() method due to trigger recursion prevention');
                return;
            }
            psaTriggerMonitor.ExecutedTriggers.add('psaTimecardHeaderTriggerHandler-after');
            System.debug('Current SOQL Queries before starting daily cap process: ' + System.Limits.getQueries());
            System.debug('Calling over the daily cap process: ' + approvedTimecardIds);
            psaTimecardDailyCap.processOverDailyCapTimecards(approvedTimecardProjectIds, 
                    approvedTimecardLatestEndDate, approvedTimecardIds);

            //Insert the list of PSA Apex Log records
            Try {
                psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
                psaApexLog.insertApexLogRecords();
            } Catch (Exception ex) {
                System.debug('Error inserting apex log records: ' + ex.getMessage());
            }
        }
    }

    /**************************************************************************************
    // Name        : checkTimeEnteredForMultipleMonths
    // Description : This method checks for time entered on the same timecard for multiple  
    //                  months. This can pose a problem when executing the over the daily cap
    //                  logic.
    // Revisions   : 2015-11-01 Klassen Initial implementation
    //               2015-12-04 Klassen Bypass logic if the timecard is non-billable 
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    ***************************************************************************************/
    private void checkTimeEnteredForMultipleMonths(pse__Timecard_Header__c tc) {
        Integer startMonth = tc.pse__Start_Date__c.month();
        Integer endMonth = tc.pse__End_Date__c.month();
        if (startMonth != endMonth && tc.pse__Billable__c == true) {
            Boolean startMonthHasHours = false;
            Boolean endMonthHasHours = false;
            Date currentDay;
            Decimal currentHours;
            //Loop through each day of the week, checking for hours for each month
            for (Integer i=0;i<=6;i++) {
                currentDay = tc.pse__Start_Date__c + i;
                currentHours = getHoursForDayOfWeek(currentDay, tc);
                if (currentDay.month() == startMonth && currentHours != 0) {
                    startMonthHasHours = true;
                } else if (currentDay.month() == endMonth && currentHours != 0) {
                    endMonthHasHours = true;
                }
            }

            //if total hours for both start date month and end date month != 0, "throw" error
            if (startMonthHasHours == true && endMonthHasHours == true) {
                tc.addError('A single timecard may not have time for 2 different months');
            }
        }

    }

    /**************************************************************************************
    // Name        : getHoursForDayOfWeek
    // Description : This method returns the hours worked for a given day of the week.  It  
    //                  presumes the start day is a Saturday
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    //             : Date currentDate - Date to check the total hours for
    ***************************************************************************************/
    private Decimal getHoursForDayOfWeek(Date currentDate, pse__Timecard_Header__c tc) {
        Datetime currentDateTime = Datetime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
        String dayOfWeek = currentDateTime.format('EEEE');

        if (dayOfWeek == 'Saturday') {
            return tc.pse__Saturday_Hours__c; 
        } else if (dayOfWeek == 'Sunday') {
            return tc.pse__Sunday_Hours__c;
        } else if (dayOfWeek == 'Monday') {
            return tc.pse__Monday_Hours__c;
        } else if (dayOfWeek == 'Tuesday') {
            return tc.pse__Tuesday_Hours__c;
        } else if (dayOfWeek == 'Wednesday') {
            return tc.pse__Wednesday_Hours__c;
        } else if (dayOfWeek == 'Thursday') {
            return tc.pse__Thursday_Hours__c;
        } else if (dayOfWeek == 'Friday') {
            return tc.pse__Friday_Hours__c;
        } else {
            return 0.0;
        }
    }

    /**************************************************************************************
    // Name        : setBillingLevel
    // Description : This method copies the Billing Level from the PSA Assignment to the  
    //               Timecard Header
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    ***************************************************************************************/
    private void setBillingLevel(pse__Timecard_Header__c timecard) {
        pse__Assignment__c assignment = assignmentMap.get(timecard.pse__Assignment__c);
        if (assignment != null && assignment.PSA_Billing_Level__c != null) {
            timecard.PSA_Billing_Level__c = assignment.PSA_Billing_Level__c;
        }
    }

    /**************************************************************************************
    // Name        : updateBillRateText
    // Description : This method updates the PSA_Bill_Rate_Text value with the bill rate,
                      this is used by Conga
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being updated
    ***************************************************************************************/
    private void updateBillRateText(pse__Timecard_Header__c timecard){
        timecard.PSA_Bill_Rate_Text__c = ''+timecard.pse__Bill_Rate__c;
    }

    /**************************************************************************************
    // Name        : setProjectLocationFields
    // Description : This method copies the Project Location fields from the related Project    
    //               Location to the Timecard Header
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    // Revisions   : 2015-05-04  Klassen  Pull Home Location values from the Contact record, 
    //                  not the related Assignment
    ***************************************************************************************/
    private void setProjectLocationFields(pse__Timecard_Header__c timecard) {
        pse__Project_Location__c projectLocation = projectLocationMap.get(timecard.pse__Primary_Project_Location__c);
        Contact resource;

        if (projectLocation != null) {
            //Update to inherit from the Contact
            if (projectLocation.Name != 'Home Location') {
                timecard.PSA_Work_Location_City__c = projectLocation.PSA_City__c;
                timecard.PSA_Work_Location_State__c = projectLocation.PSA_State_Province__c;
                timecard.PSA_Work_Location_Postal_Code__c = projectLocation.PSA_Postal_Code__c;
                timecard.PSA_Work_Location_Country__c = projectLocation.PSA_Country__c;
            } else {
                resource = resourceMap.get(timecard.pse__Resource__c);
                if (resource != null) {
                    timecard.PSA_Work_Location_City__c = resource.MailingCity;
                    timecard.PSA_Work_Location_State__c = resource.MailingState;
                    timecard.PSA_Work_Location_Postal_Code__c = resource.MailingPostalCode;
                    timecard.PSA_Work_Location_Country__c = resource.MailingCountry;
                }
            }
        }
    }

    /**************************************************************************************
    // Name        : setApproversAndFullyLoadedCostRateFields
    // Description : This method copies the Resource Manager and other potential Approver fields 
    //                  from the related Project
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    ***************************************************************************************/
    private void setApproversAndFullyLoadedCostRateFields(pse__Timecard_Header__c newTimecard) {
        pse__Proj__c project = projectMap.get(newTimecard.pse__Project__c);
        Contact resource = resourceMap.get(newTimecard.pse__Resource__c);
        if (project != null && project.PSA_CIM__c != null && project.PSA_CIM__r.pse__Salesforce_User__c != null) {
            //set the cim user on the TC
            newTimecard.PSA_CIM_User__c = project.PSA_CIM__r.pse__Salesforce_User__c;
        }
        if (project != null && project.PSA_Director__c != null && project.PSA_Director__r.pse__Salesforce_User__c != null) {
            //set the Director user on the TC
            newTimecard.PSA_Director_User__c = project.PSA_Director__r.pse__Salesforce_User__c;
        }
        if (project != null && project.pse__Project_Manager__c != null && project.pse__Project_Manager__r.pse__Salesforce_User__c != null) {
            //set the Project Manager user on the TC
            newTimecard.PSA_Project_Manager_User__c = project.pse__Project_Manager__r.pse__Salesforce_User__c;
        }
        if (resource != null && resource.pse__Salesforce_User__r != null && resource.pse__Salesforce_User__r.ManagerId != null) {
            //Set the Resource Manager on the TC
            newTimecard.PSA_Resource_Manager_User__c = resource.pse__Salesforce_User__r.ManagerId;
        }
        System.debug('The project manager is: '+newTimecard.PSA_Project_Manager_User__c);
        System.debug('The project approval type is: '+project.PSA_Time_Approval_Method__c);
        System.debug('The project manager user is: '+project.pse__Project_Manager__r.pse__Salesforce_User__c);
        
        //Set the Approver field based on a bottom up hierarchy of PM, CIM, Director, Resource Manager
        // if resource is pm, use cim as approver, if resource is pm and cim, use director, if resource is pm, cim, and director, use resource mgr
        if (project.PSA_Time_Approval_Method__c == 'Project Manager') {
            System.debug('Using project manager approval method');
            if (project.pse__Project_Manager__c != null && project.pse__Project_Manager__c != newTimecard.pse__Resource__c) {
                System.debug('Assigning approver to project manager');
                newTimecard.pse__Approver__c = newTimecard.PSA_Project_Manager_User__c;
            } else if (project.PSA_CIM__c != null && project.psa_cim__c != newTimecard.pse__Resource__c) {
                newTimecard.pse__Approver__c = newTimecard.PSA_CIM_User__c;
            } else if (project.psa_Director__c != null && project.psa_Director__c != newTimecard.pse__Resource__c) {
                newTimecard.pse__Approver__c = newTimecard.PSA_Director_User__c;
            } else {
                newTimecard.pse__Approver__c = newTimecard.PSA_Resource_Manager_User__c;
            }
        } else if (project.PSA_Time_Approval_Method__c == 'Resource Manager') {
            newTimecard.pse__Approver__c = newTimecard.PSA_Resource_Manager_User__c;          
        }

        //Set the Fully Loaded Cost Rate
        if (resource != null && resource.PSA_Fully_Loaded_Cost_Rate__c != null) {
           newTimecard.PSA_Fully_Loaded_Cost_Rate_Amount__c = resource.PSA_Fully_Loaded_Cost_Rate__c;
        }
    }

    /**************************************************************************************
    // Name        : setOverrideCostRegion
    // Description : This method copies the Resource's Region to the Override Cost Region
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    ***************************************************************************************/
    private void setOverrideCostRegion(pse__Timecard_Header__c newTimecard){
        pse__Proj__c project = projectMap.get(newTimecard.pse__Project__c);
        if(project != null && project.pse__Project_Type__c == 'Internal'){
            Contact resource = resourceMap.get(newTimecard.pse__Resource__c);
            if(resource != null){
                newTimecard.pse__Override_Cost_Region__c = resource.pse__Region__c;
                newTimecard.pse__Audit_Notes__c = 'Internal Project Region Overridden by Resource Region';
                newTimecard.pse__Admin_Global_Edit__c = true;
            }
        }
    }


    /**************************************************************************************
    // Name        : setEntities
    // Description : This method copies Project Billing Legal Entity and the Resource's Entity to the timecard respective values
    // Arguments   : pse__Timecard_Header__c timecard - each record that is being inserted
    ***************************************************************************************/
    private void setEntities(pse__Timecard_Header__c newTimecard){
        pse__Proj__c project = projectMap.get(newTimecard.pse__Project__c);
        Contact c = resourceMap.get(newTimecard.pse__Resource__c);
        if(project != null && project.PSA_Billing_Legal_Entity__c != null){
            newTimecard.PSA_Proj_Billing_Legal_Entity__c = project.PSA_Billing_Legal_Entity__c;
        }
        if(c != null && c.PSA_Resource_Entity__c != null){
            newTimecard.PSA_Resource_Entity__c = c.PSA_Resource_Entity__c;
        }
    }

}