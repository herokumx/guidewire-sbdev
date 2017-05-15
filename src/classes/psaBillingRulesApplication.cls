/****************************************************************************************
Name            : psaBillingRulesApplication
Author          : CLD Partners
Created Date    : March 1, 2015
Description     : Contains methods to apply billing rules for project billing
                    (billing event generation).  Each Billing Rule, in general, has self-
                    contained logic
Revisions       : 3/1/15 - Initial version (prototype)
                : 4/21/15 - Start of actual implementation
                : 6/25/15 - Added Currency Code to Misc. Adjust. creation
                : 8/20/15 - Added custom Apex Logging functionality to most methods
                : 9/23/15 - Added Try/Catch logic to handle custom Apex Logging now that
                    the Billing Rules Application has been de-coupled from the Billing Event
                    Generation logic (because it was moved to a batchable class)
                : 9/29/15 - Added parameter to Over the daily cap call to handle another process
                    passing in a set of approved timecard ids
******************************************************************************************/
global class psaBillingRulesApplication {
    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaBillingRulesApplication';
    private static Integer apexLogMethodSequenceMaster = 0;

    List<pse__Miscellaneous_Adjustment__c> miscAdjsToInsert = new List<pse__Miscellaneous_Adjustment__c>();
    List<pse__Billing_Event_Item__c> billingEventItemsToInsert = new List<pse__Billing_Event_Item__c>();
    public Map<Id, pse__Proj__c> projectMasterMap;
    public Map<Id, pse__Billing_Event__c> billingEventMasterMap;
    Map<Id, pse__Miscellaneous_Adjustment__c> holdbackReleaseMiscAdjMasterMap;
    List<pse__Billing_Event__c> billingEventsToUpdate = new List<pse__Billing_Event__c>();
    Set<Id> accountDiscountIds = new Set<Id>();
    List<AccountDiscountAmount> accountDiscountAmounts = new List<AccountDiscountAmount>();
    TimecardSummaryByKeyAndBillingLevel timecardSummaryController = new TimecardSummaryByKeyAndBillingLevel();
    Date startDate;
    Date endDate;

    //Initialze a list of Misc. Adjs. which will contain Holdback Release records that need to be updated
    //miscAdjsToUpdate is used in BR 11 and BR 13
    List<pse__Miscellaneous_Adjustment__c> miscAdjsToUpdate = new List<pse__Miscellaneous_Adjustment__c>();
    //Initialze a list of Misc. Adjs. which will contain min. billable hours adjs. that no longer apply
    //miscAdjsToDelete is used in BR 9
    List<pse__Miscellaneous_Adjustment__c> miscAdjsToDelete = new List<pse__Miscellaneous_Adjustment__c>();
    Map<Id, Decimal> billingEventMinimumHoursAmountsMap = new Map<Id, Decimal>();

    //String constants
    //Over the daily cap Milestone name
    public final String OVER_CAP_MILESTONE_NAME = 'Excess (Non-billable) Time over Daily Cap';

    //Billing Rule type values (must match picklist values in Miscellaneous Adjustment - Billing Rule Type)
    public final String BILLING_TYPE_TIME_AND_MATERIALS = 'Services - Time and Materials';
    public final String BILLING_TYPE_SERVICES_FIXED_FEE = 'Services - Fixed Fee';
    public final String BILLING_TYPE_MINIMUM_HOURS = 'Services Charge - Minimum Hours';
    public final String BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT = 'Services Credit - Cap Flat Amount';
    public final String BILLING_TYPE_HOLDBACK = 'Services Credit - Holdback';
    public final String BILLING_TYPE_HOLDBACK_RELEASE = 'Services Charge - Holdback Release';
    public final String BILLING_TYPE_PROJECT_DISCOUNT = 'Services Credit - Project Discount';
    public final String BILLING_TYPE_CUSTOMER_DISCOUNT = 'Services Credit - Customer Discount';
    public final String BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES = 'Expense Charge - Percent of Services';
    public final String BILLING_TYPE_EXPENSE_FLAT_AMOUNT = 'Expense Charge - Flat Amount';
    public final String BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES = 'Expense Credit - Cap Percent of Services';
    public final String BILLING_TYPE_EXPENSE_CAP_FLAT_AMOUNT = 'Expense Credit - Cap Flat Amount';
    public final String BILLING_TYPE_EXPENSE_LTA = 'Expense Charge - Domestic LTA';
    public final String BILLING_TYPE_EXPENSE_AS_INCURRED = 'Expenses - As Incurred';
    public final String BILLING_TYPE_EXPENSE_FIXED_AMOUNT = 'Expenses - Fixed Amount';

    /**************************************************************************************
    // Name         : launchBillingRulesBeforeStart
    // Description  : Entry point for the process that runs methods in the BeforeStart method
    //                  of psaBillingEventGeneration
    // Author       : CLD Partners
    // Revisions    : 2015-07-12  Klassen  Initial version
    //              :
    ***************************************************************************************/
    public void launchBillingRulesBeforeStart(Set<Id> projectIds, Date timePeriodStartDate,
            Date timePeriodEndDate) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'launchBillingRulesBeforeStart';

        Try {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Starting launchBillingRulesBeforeStart', null, null);

            startDate = timePeriodStartDate;
            endDate = timePeriodEndDate;

            //Populate a map of Holdback Release Misc. Adjs. for the specified set of Projects
            holdbackReleaseMiscAdjMasterMap=getHoldbackReleaseMiscAdjByProjectMap(projectIds);
            System.Debug('Holdback Release Master Map:'+holdbackReleaseMiscAdjMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'holdbackReleaseMiscAdjMasterMap', String.valueOf(holdbackReleaseMiscAdjMasterMap), (List<SObject>)holdbackReleaseMiscAdjMasterMap.values());

            //Populate a map of all Billing Events for the specified Projects which will be used to get specific billing event values
            billingEventMasterMap=fillBillingEventsMasterMap(projectIds);
            System.Debug('Billing Event Master Map:' + billingEventMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'billingEventMasterMap', String.valueOf(billingEventMasterMap), (List<SObject>)billingEventMasterMap.values());

            //Create a misc. adjustment for project where the min hours billing rule applies, but no timecards exist
            createMinimumHoursMiscAdjustmentIfNoTimecards(projectIds, timePeriodStartDate,
                timePeriodEndDate);

            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Finishing launchBillingRulesBeforeStart', null, null);
        } catch (Exception ex) {
          psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingRulesApplication.launchBillingRulesBeforeStart-Line Number:' + ex.getLineNumber(), 'MESSAGE=' + ex.getMessage() + '   STACKTRACE=' + ex.getStackTraceString(), null);
          psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Rules Application Error');
        }

        //Insert the list of PSA Apex Log records
        Try {
            psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
            psaApexLog.insertApexLogRecords();
        } Catch (Exception ex) {
            System.debug('Error trying to insert the Apex Log Records in psaBillingRulesApplication.launchBillingRulesBeforeStart: ' + ex.getMessage());
          psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Rules Application Error');
        }
  }

    /**************************************************************************************
    // Name         : launchBillingRules
    // Description  : Entry point for the process that applies billing rules to all un-released
    //                  billing events for a specified set of projects
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  Initial version
    //              :
    ***************************************************************************************/
    public void launchBillingRules(Set<Id> projectIds, Date timePeriodStartDate, Date timePeriodEndDate) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'launchBillingRules';

        Try {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Starting launchBillingRules', null, null);

            startDate = timePeriodStartDate;
            endDate = timePeriodEndDate;

            //Populate a map of Holdback Release Misc. Adjs. for the specified set of Projects
            holdbackReleaseMiscAdjMasterMap=getHoldbackReleaseMiscAdjByProjectMap(projectIds);
            System.Debug('Holdback Release Master Map:'+holdbackReleaseMiscAdjMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'holdbackReleaseMiscAdjMasterMap', String.valueOf(holdbackReleaseMiscAdjMasterMap), (List<SObject>)holdbackReleaseMiscAdjMasterMap.values());

            //Process Timecard Daily Caps.  This may leave billing event items with incorrect amounts,
            // but any soql (and aggregate) queries or amount rollups will use the source object amount, and the
            // FF Recalc api call at the end of billing event generation will update the billing event item
            // amounts.
            if (endDate != null) {
                //Add apex log record
                psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Processing Over Daily Cap Timecard logic', null, null);
                psaTimecardDailyCap.processOverDailyCapTimecards(projectIds, endDate, null);
            }

            //Populate a map of all projects, will use this to get specific billing rules values
            projectMasterMap=fillProjectsMasterMap(projectIds);
            System.Debug('Project Master Map:' + projectMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'projectMasterMap', String.valueOf(projectMasterMap), (List<SObject>)projectMasterMap.values());

            //Populate a map of all Billing Events for the specified Projects which will be used to get specific billing event values
            billingEventMasterMap=fillBillingEventsMasterMap(projectIds);
            System.Debug('Billing Event Master Map:' + billingEventMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'billingEventMasterMap', String.valueOf(billingEventMasterMap), (List<SObject>)billingEventMasterMap.values());

            //Start by removing all billing rules for unreleased billing events for the specified set of project ids
            clearBillingRules(projectIds);

            //Populate a map of Holdback Release Misc. Adjs. for the specified set of Projects
            holdbackReleaseMiscAdjMasterMap=getHoldbackReleaseMiscAdjByProjectMap(projectIds);
            System.Debug('Holdback Release Master Map:'+holdbackReleaseMiscAdjMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'holdbackReleaseMiscAdjMasterMap-refill', String.valueOf(holdbackReleaseMiscAdjMasterMap), (List<SObject>)holdbackReleaseMiscAdjMasterMap.values());

            //Populate a map of all projects, will use this to get specific billing rules values
            projectMasterMap=fillProjectsMasterMap(projectIds);
            System.Debug('Project Master Map:' + projectMasterMap);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'projectMasterMap-refill', String.valueOf(projectMasterMap), (List<SObject>)projectMasterMap.values());

            //added 9/25/15 by cklassen to ensure the time period is accurately reflected on the billing event
            // The billing event batch related record may not match the time period that the billing event was created in
            Id timePeriodId = (
                    [Select Id
                        From pse__Time_Period__c
                        Where pse__Start_Date__c = :timePeriodStartDate
                        And pse__End_Date__c = :timePeriodEndDate
                        Limit 1
                    ]).Id;
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Time Period Id: ' + timePeriodId, null, null);
            //Update the time period lookup field on the billing events --used by various functions when applying billing rules
            List<pse__Billing_Event__c> billingEventsTimePeriodUpdate = billingEventMasterMap.values();
            for (pse__Billing_Event__c beUpdated : billingEventsTimePeriodUpdate) {
                beUpdated.PSA_Time_Period__c = timePeriodId;
            }
            update billingEventsTimePeriodUpdate;
            //Re-Populate a map of all Billing Events for the specified Projects which will be used to get specific billing event values
            billingEventMasterMap=fillBillingEventsMasterMap(projectIds);
            System.Debug('Billing Event Master Map:' + billingEventMasterMap);

            //Now that the billing rule misc. adjs. for the current set of project billing events have been removed, apply billing rules
            applyBillingRules();

            //added 9/16/15 by cklassen to help automate the billing event regeneration process
            //Update a field on the billing events indicating when the custom billing logic has been completed
            List<pse__Billing_Event__c> billingEventsUpdated = billingEventMasterMap.values();
            pse__Billing_Event__c beWithMiscAdj;
            Map<Id, pse__Billing_Event__c> beWithMiscAdjMap = getBillingEventsWithManualMiscellaneousAdjustments();
            for (pse__Billing_Event__c beUpdated : billingEventsUpdated) {
                beUpdated.PSA_Billing_Rules_Applied_Date__c = DateTime.now();
                beUpdated.PSA_Billing_Event_Recalc_Date__c = null;
                beUpdated.PSA_Billing_Event_Docs_Started_Date__c = null;
                beUpdated.PSA_Billing_Event_Docs_Attached_Date__c = null;

                beWithMiscAdj = beWithMiscAdjMap.get(beUpdated.Id);
                if (beWithMiscAdj != null) {
                    beUpdated.PSA_Has_Miscellaneous_Adjustments__c = true;
                }
            }
            update billingEventsUpdated;

            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Finishing launchBillingRules', null, null);
        } catch (Exception ex) {
          psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingRulesApplication.launchBillingRules-Line Number:' + ex.getLineNumber(), 'MESSAGE=' + ex.getMessage() + '   STACKTRACE=' + ex.getStackTraceString(), null);
          psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Rules Application Error');
        }

        //Insert the list of PSA Apex Log records
        Try {
            psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
            psaApexLog.insertApexLogRecords();
        } Catch (Exception ex) {
            System.debug('Error trying to insert the Apex Log Records in psaBillingRulesApplication.launchBillingRules: ' + ex.getMessage());
          psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Rules Application Error');
        }
    }

    /**************************************************************************************
    // Name        : getBillingEventsWithManualMiscellaneousAdjustments
    // Description : Update the Has Miscellaneous Adjustments field if any billing event items
    //                  qualify (are manually created, not created by billing rule logic)
    // Author       : CLD Partners
    // Revisions    : 2015-10-16  Klassen  Initial version
    ***************************************************************************************/
    private Map<Id, pse__Billing_Event__c> getBillingEventsWithManualMiscellaneousAdjustments() {
        return new Map<Id, pse__Billing_Event__c>(
            [Select Id, Name
                From pse__Billing_Event__c
                Where Id In (
                    Select pse__Billing_Event__c
                        From pse__Billing_Event_Item__c
                        Where pse__Billing_Event__c = :billingEventMasterMap.keySet()
                        And pse__Miscellaneous_Adjustment__c != null
                        And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                )
            ]);
    }

    /**************************************************************************************
    // Name         : launchBillingRules
    // Description  : Each time a billing event is created or updated, including when new billing event
    //                  items are added, billing rule logic must be run to add miscellaneous adjustments
    //                  if applicable.  Multiple billing rules can apply and must be applied in a
    //                  particular order.
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  Initial version (prototype)
    //              : 2015-04-21  Klassen  Initial Implementation
    ***************************************************************************************/
    public Boolean applyBillingRules() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRules';

        Boolean successFlag = true; //assume success

        //BR 14: Domestic LTA
        applyBillingRule_DomesticLTA();

        //BR 9: Minimum Billed Hours
        applyBillingRule_MinimumBillableHours();

        //BR 10: Apply Billing Rule: Services Cap - Flat Amount
        applyBillingRule_ServicesCappedAsFlatAmount();

        //BR 11: Apply Billing Rule: Holdback
        applyBillingRule_Holdback();

        //BR 13: Apply Billing Rule: Account Discount
        applyBillingRule_AccountDiscount();

        //BR 5: Apply Billing Rule: Expenses Flat % if applicable
        applyBillingRule_ExpensesFlatPercent();

        //BR 6: Apply Billing Rule: Expenses Flat Amount if applicable
        applyBillingRule_ExpensesFlatAmount();

        //BR 7: Apply Billing Rule: Expense Cap Percent of Services
        applyBillingRule_ExpensesCappedAsPercent();

        //BR 8: Apply Billing Rule: Expense Cap Flat
        applyBillingRule_ExpensesCapFlatAmount();


        //BEGIN DML
        //Insert any new Misc. Adjs. and create new corresponding Billing Event Items
        if (miscAdjsToInsert.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Misc. Adjs. To Insert:' + miscAdjsToInsert.size(), String.valueOf(miscAdjsToInsert), null);

            //Insert the new Misc. Adjs.
            insert miscAdjsToInsert;

            //Create new Billing Event Items for each new Misc. Adj. except ones not marked as created by Billing Rule
            // This includes Holdback Release misc. adjs.
            for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjsToInsert) {
                pse__Billing_Event__c billingEvent = billingEventMasterMap.get(miscAdj.PSA_BR_Billing_Event__c);
                //Exclude Misc. Adjs. not marked as having been created by Billing Rules (Holdback Release Misc. Adjs)
                if (miscAdj.PSA_Created_By_Billing_Rule__c == true && miscAdj.PSA_Billing_Rule_Type__c != BILLING_TYPE_HOLDBACK_RELEASE) {
                    pse__Billing_Event_Item__c bei = createBillingEventItem(billingEvent, miscAdj);
                    billingEventItemsToInsert.add(bei);
                }
            }
        }

        //If there are any new billing event items (corresponding to Misc. Adjs. created by Billing Rules), insert them
        if (billingEventItemsToInsert.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BE Items To Insert:' + billingEventItemsToInsert.size(), String.valueOf(billingEventItemsToInsert), null);
            insert billingEventItemsToInsert;
        }

        //Update the pse__Billing_Event_Item__c on the Misc. Adj. (can't do this until after inserting the related BEI)
        if (miscAdjsToInsert.size() > 0) {
            updateMiscellaneousAdjustmentBillingEventItemIds(projectMasterMap.keySet());
        }

        //Update any Misc. Adjs to Update
        if (miscAdjsToUpdate.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Misc. Adjs. To Update:' + miscAdjsToUpdate.size(), String.valueOf(miscAdjsToUpdate), (List<SObject>)miscAdjsToUpdate);
            update miscAdjsToUpdate;
        }

        //Update the pse__Billing_Event__c list if applicable (BR 13 may add to this list)
        if (billingEventsToUpdate.size() > 0) {
            System.debug('Billing Events To Update: ' + billingEventsToUpdate);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BEs To Update:' + billingEventsToUpdate.size(), String.valueOf(billingEventsToUpdate), (List<SObject>)billingEventsToUpdate);
            update billingEventsToUpdate;
        }
        //END DML

        //Refresh the Invoice Summary Lines for each billing event we just processed
        psaInvoiceSummaryLineRefresh.refreshInvoiceSummaryLines(projectMasterMap.keySet());

        //Refresh the Billing Event and PSA Project Balance objects with Summary/Balances
        psaRefreshProjectBillingBalances.refreshBillingBalances(billingEventMasterMap.keySet(),
                projectMasterMap.keySet(), accountDiscountIds);

        return successFlag;
    }

    /***********************************************************************************************************
    // GW Billing Rule #9: Services Minimum Billable
    // Description: If the total number of hours in the billing event does not add up to the minimum monthly hours,
    //                  create a Misc. Adj. to make up the difference.  The amount of the Misc. Adj. will be the
    //                  unbilled number of hours multiplied by the "default" bill rate.
    //  Inputs:
    //      1. Total of timecard splits eligible for Billing (from Billing Event Item lines)
    //      2. "Standard" bill rate for all assignments for this project
    //      3. Number of minimum hours to be billed monthly
    //  Steps:
    //      1. Populate a Map of the total number of hours worked grouped by billing event
    //      2. Loop through each Billing Event checking if less hours were worked than the min. monthly
    //          hours set on the project
    //         1. Get total timecard hours for this billing event (if no results, exit method)
    //         2. Get Standard ("Default") Bill Rate for Project
    //         3. Check if the min. hours to be billed monthly exceeds the actual billed hours.
    //         4. If the minimum hours is greater than the actual billed hours, create a positive misc
    //          adj for the difference
    //
    //  Misc. Adjustment Billing Rule Type: 'Services Charge - Minimum Hours'
    ***********************************************************************************************************/
    public void applyBillingRule_MinimumBillableHours() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_MinimumBillableHours';

        System.debug('BR 9: running applyBillingRule_MinimumBillableHours');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Initialize a set of billing event ids to apply this billing rule to
        Set<Id> billingEventIds = new Set<Id>();
        List<Id> minHoursBillingEventItemsToDelete = new List<Id>();

        //Get a list of unreleased Billing Events with the Min Hours Billing Applies set
        AggregateResult[] arTotalHours = getTimecardsAggregateResults(projectMasterMap.keySet(), 'PSA_BR_Minimum_Billed_Hours_Applies__c');
        System.debug('BR 9: Total Hours List: ' + arTotalHours);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Total Hours List', String.valueOf(arTotalHours), null);

        //*** ADDED BY CKLASSEN 7/10 TO INCLUDE PROJECTS WITH NO TIMECARDS FOR THE PERIOD
        //Add projects that have no timecards to the timecardSummaryList
        List<pse__Proj__c> projectsNoTimecards = getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards(projectMasterMap.keySet(), startDate, endDate, true);
        System.debug('BR9: projectsNoTimecards: ' + projectsNoTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'projectsNoTimecards', String.valueOf(projectsNoTimecards), (List<SObject>)projectsNoTimecards);

        //Map<Id, Decimal> totalHoursMap = new Map<Id, Decimal>();
        if ((arTotalHours != null && arTotalHours.size() > 0) || (projectsNoTimecards != null && projectsNoTimecards.size() > 0)) {
            //Define variables to be used for calculating the misc. adj. for each billing event
            pse__Proj__c project;
            pse__Billing_Event__c billingEvent;
            Decimal totalHoursWorked;
            Decimal unWorkedHours;
            Decimal projectBillRateAmount;
            Decimal miscAdjAmount;
            Date miscAdjDate;
            pse__Miscellaneous_Adjustment__c miscAdj;

            Map<Id, pse__Miscellaneous_Adjustment__c> miscAdjMinHoursMap =
                    buildMiscAdjustmentForMinimumHoursIfNoTimecardsMap(projectMasterMap.keySet());
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'miscAdjMinHoursMap', String.valueOf(projectMasterMap.values()), null);

            //Aggregate the timecard total hours at the billing event level
            List<TimecardSummaryByKeyAndBillingLevel> timecardSummaryList =
                    timecardSummaryController.buildMap(arTotalHours, 'BillingEventId', false).values();
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'timecardSummaryList', String.valueOf(timecardSummaryList), null);

            //*** ADDED BY CKLASSEN 7/10 TO INCLUDE PROJECTS WITH NO TIMECARDS FOR THE PERIOD
            pse__Billing_Event__c billingEventNoTimecard;
            TimecardSummaryByKeyAndBillingLevel timecardSummaryNoTimecard;
            if (projectsNoTimecards != null && projectsNoTimecards.size() > 0) {
                System.debug('No Timecards has Projects: ' + projectsNoTimecards);
                for (pse__Proj__c projectNoTimecard : projectsNoTimecards) {
                    System.debug('No Timecards project loop: ' + projectNoTimecard);
                    //Find the appropriate billing event and then create a new timecard summary record
                    billingEventNoTimecard = getBillingEventForProject(projectNoTimecard, endDate);
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: billingEventNoTimecard', String.valueOf(billingEventNoTimecard), null);

                    if (billingEventNoTimecard != null) {
                        timecardSummaryNoTimecard = new TimecardSummaryByKeyAndBillingLevel();
                        timecardSummaryNoTimecard.ProjectId = projectNoTimecard.Id;
                        timecardSummaryNoTimecard.BillingEventId = billingEventNoTimecard.Id;
                        timecardSummaryNoTimecard.TotalAmount = 0.0;
                        timecardSummaryNoTimecard.TotalHoursWorked = 0.0;
                        timecardSummaryNoTimecard.TotalDaysWorked = 0.0;
                        timecardSummaryList.add(timecardSummaryNoTimecard);
                        System.debug('No Timecards summary: ' + timecardSummaryNoTimecard);
                    }
                }
            }

            System.debug('BR9: timecard summary list: ' + timecardSummaryList);
            //Loop through each billing event and add a credit for the difference in minimum billable hours vs actual hours billed
            for (TimecardSummaryByKeyAndBillingLevel timecardSummary : timecardSummaryList) {
                System.debug('BR9: timecard summary: ' + timecardSummary);
                miscAdj = new pse__Miscellaneous_Adjustment__c();

                //Get the project and billing event from the master maps
                project = projectMasterMap.get(timecardSummary.ProjectId);
                billingEvent = billingEventMasterMap.get(timecardSummary.BillingEventId);
                System.debug('BR 9: Billing Event Name: ' + billingEvent.Name);

                //Get the total hours for the specified billing event
                totalHoursWorked = timecardSummary.TotalHoursWorked;
                System.debug('BR 9: Total Hours Worked: ' + totalHoursWorked);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Total Hours Worked', String.valueOf(totalHoursWorked), null);

                //If total hours worked is negative, set the hours worked to zero (don't want to over-charge
                // the min. monthly hours total)
                if (totalHoursWorked < 0) {
                    totalHoursWorked = 0;
                }

                //If the min. billable hours is greater than the actual bill hours, create a misc. adj. credit for the difference
                if (project.PSA_BR_Minimum_Billed_Hours_Monthly__c > totalHoursWorked) {
                    //Get the difference in Hours which will be multiplied by the bill rate
                    unWorkedHours = project.PSA_BR_Minimum_Billed_Hours_Monthly__c - totalHoursWorked;
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Un-worked Hours', String.valueOf(unWorkedHours), null);

                    //Get the bill rate from the project's billing rules
                    projectBillRateAmount = project.PSA_BR_Minimum_Hours_Bill_Rate__c;
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Project Bill Rate', String.valueOf(project.PSA_BR_Minimum_Hours_Bill_Rate__c), null);

                    //Set the miscAdjAmount
                    miscAdjAmount = unWorkedHours * projectBillRateAmount;
                    System.debug('BR 9: miscAdj Amount: ' + miscAdjAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: miscAdj Amount', String.valueOf(miscAdjAmount), null);

                    //Set the miscAdjDate (same logic as setting the invoice date when releasing a billing event)
                    miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                    //Search for the misc in the min. hours misc. adj. map.  If not found create a new one, otherwise update it
                    miscAdj = miscAdjMinHoursMap.get(billingEvent.Id);
                    System.debug('miscAdjMinHoursMap:' + miscAdjMinHoursMap);
                    System.debug('miscAdj:' + miscAdj);
                    if (miscAdj == null) {
                        //Create the misc. adj.
                        miscAdj = createMiscellaneousAdjustment(BILLING_TYPE_MINIMUM_HOURS, miscAdjAmount, miscAdjDate, project.Id,
                                    billingEvent.Name, billingEvent.Id, true, BILLING_TYPE_MINIMUM_HOURS, null, null, null, billingEvent.CurrencyISOCode);
                        //miscAdjsToInsert.add(miscAdj);
                        System.debug('BR 9: Misc. Adj. to Insert: ' + miscAdj);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Misc. Adj. to Insert', String.valueOf(miscAdj), null);
                    } else {
                        System.debug('Updating existing misc adj: ' + miscAdj);
                        if (miscAdj.pse__Amount__c != miscAdjAmount) {
                            miscAdj.pse__Amount__c = miscAdjAmount;
                            miscAdjsToUpdate.add(miscAdj);
                            System.debug('BR 9: Misc. Adj. to Update: ' + miscAdj);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Misc. Adj. to Update', String.valueOf(miscAdj), null);
                        }
                    }
                } else {
                    miscAdj = miscAdjMinHoursMap.get(billingEvent.Id);
                    if (miscAdj != null) {
                        minHoursBillingEventItemsToDelete.add(miscAdj.pse__Billing_Event_Item__c);
                        //miscAdjsToDelete.add(miscAdj);
                        System.debug('BR 9: Misc. Adj. to Delete: ' + miscAdj);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 9: Misc. Adj. to Delete', String.valueOf(miscAdj), null);
                    }
                }
            }
        }

        //Perform all DML statements
        if (miscAdjsToInsert.size() > 0) {
            System.debug('BR 9: miscAdjsToInsert:' + miscAdjsToInsert);
            insert miscAdjsToInsert;

            //Create new Billing Event Items for each new Misc. Adj. except ones not marked as created by Billing Rule
            // This includes Holdback Release misc. adjs.
            for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjsToInsert) {
                pse__Billing_Event__c billingEvent = billingEventMasterMap.get(miscAdj.PSA_BR_Billing_Event__c);
                //Exclude Misc. Adjs. not marked as having been created by Billing Rules (Holdback Release Misc. Adjs)
                if (miscAdj.PSA_Created_By_Billing_Rule__c == true && miscAdj.PSA_Billing_Rule_Type__c != BILLING_TYPE_HOLDBACK_RELEASE) {
                    pse__Billing_Event_Item__c bei = createBillingEventItem(billingEvent, miscAdj);
                    billingEventItemsToInsert.add(bei);
                }
            }
            if (billingEventItemsToInsert.size() > 0) {
                insert billingEventItemsToInsert;
                billingEventItemsToInsert = new List<pse__Billing_Event_Item__c>();
                updateMiscellaneousAdjustmentBillingEventItemIds(projectMasterMap.keySet());
            }

            miscAdjsToInsert = new List<pse__Miscellaneous_Adjustment__c>();
        }
        if (miscAdjsToUpdate.size() > 0) {
            System.debug('BR 9: MiscAdjsToUpdate: ' + miscAdjsToUpdate);
            update miscAdjsToUpdate;
            miscAdjsToUpdate = new List<pse__Miscellaneous_Adjustment__c>();
        }
        if (minHoursBillingEventItemsToDelete.size() > 0) {
            System.debug('MinHours Billing Event ITems To Delete: ' + minHoursBillingEventItemsToDelete);
            Database.delete(minHoursBillingEventItemsToDelete);
        }

        //Populate billingEventMinimumHoursAmountsMap
        billingEventMinimumHoursAmountsMap = getBillingEventMiscAdjAmountMap(BILLING_TYPE_MINIMUM_HOURS);
        System.debug('BR 9: Min Hours Amounts Map: ' + billingEventMinimumHoursAmountsMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Min Hours Amounts Map', String.valueOf(billingEventMinimumHoursAmountsMap), null);

    }

    /***********************************************************************************************************
    // GW Billing Rule #10: Services Cap - Flat Amount
    //  Inputs:
    //      1. Total of timecard splits eligible for Billing (from Billing Event Item lines)
    //      2. Total Services-related misc. adjustments
    //      3. Cap Amount (from the Project)
    //  Steps:
    //      1. Populate a map of total timecard amount for unreleased billing events where BR 10 applies
    //      2. Populate a map of "ad-hoc" (not created by billing rule application) un-released Misc. Adjustments
    //          related to Services for each billing Event.  The billing rule types include:
    //              'Services Charge - Minimum Hours'
    //              'Services - Time and Materials'
    //              'Services Credit - Cap Flat Amount'
    //      3. Loop through billing event to determine if a BR 10 misc. adj. needs to be created
    //          1. Retrieve any timecard total for the billing event (from the map populated in step 1)
    //          2. Retrieve any ad-hoc misc. adj. total for the billing event (from the map populated in step 2)
    //          3. Retrieve any current credits for this billing event (from BR #9)
    //          4. Retrieve any prior billings (from the project) -- used for "True-up" calculations
    //          5. Retrieve any prior services credits (from the project)  -- used for "True-up" calculations
    //          6. Sum the total services billings (current and prior) - from 3.1, 3.2, 3.3, and 3.4
    //          7. Retrieve the capped amount from the project
    //          8. If the total services billings exceed the cap, a create a misc. adj. credit for the difference
    //
    //  Misc. Adjustment Billing Rule Type: 'Services Credit - Cap Flat Amount'
    ***********************************************************************************************************/
    public void applyBillingRule_ServicesCappedAsFlatAmount() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_ServicesCappedAsFlatAmount';

        System.debug('BR 10: running applyBillingRule_ServicesCappedAsFlatAmount');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Initialize a set of billing event ids to apply this billing rule to
        Set<Id> billingEventIds = new Set<Id>();
        Map<String, TimecardSummaryByKeyAndBillingLevel> timecardSummaryMap;

        //Un-released timecards summarized for each billing event
        AggregateResult[] unReleasedTimecards = getTimecardsAggregateResults(projectMasterMap.keySet(),
                'PSA_BR_Services_Cap_Flat_Applies__c');
        System.debug('BR 10: Un-released Timecards:' + unReleasedTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Un-released Timecards', String.valueOf(unReleasedTimecards), null);

        if (unReleasedTimecards != null && unReleasedTimecards.size() > 0) {
            //Aggregate the timecard total hours at the billing event level
            timecardSummaryMap = timecardSummaryController.buildMap(unReleasedTimecards, 'BillingEventId', false);
            for (TimecardSummaryByKeyAndBillingLevel ts : timecardSummaryMap.values()) {
                billingEventIds.add(ts.BillingEventId);
            }
        }

        //Un-released Misc. Adjustments related to Services for each billing Event
        AggregateResult[] unReleasedMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Services_Cap_Flat_Applies__c = true
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_MINIMUM_HOURS, :BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT)
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 10: Un-released ad-hoc Misc. Adjs.:' + unReleasedMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Un-released ad-hoc Misc. Adjs.', String.valueOf(unReleasedMiscAdjs), null);

        Map<Id, Decimal> unReleasedMiscAdjsMap = new Map<Id, Decimal>();
        if (unReleasedMiscAdjs != null && unReleasedMiscAdjs.size() > 0) {
            for (AggregateResult ar : unReleasedMiscAdjs) {
                unReleasedMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Include billing event Ids from BR9
        Set<Id> billingEventMinHoursMapIds = billingEventMinimumHoursAmountsMap.keySet();
        for (Id billingEventId : billingEventMinHoursMapIds) {
            billingEventIds.add(billingEventId);
        }

        //Define variables to be used for calculating the misc. adj. for each billing event
        pse__Billing_Event__c billingEvent;
        pse__Proj__c project;
        TimecardSummaryByKeyAndBillingLevel timecardSummary;
        Decimal priorServicesBillings;
        Decimal currentMinHoursCharges;
        Decimal currentManualMiscellaneousAdjustments;
        Decimal currentServicesBillings;
        Decimal priorServicesCredits;
        Decimal totalServicesBillings;
        Decimal capFlatAmount;
        Decimal miscAdjAmount;
        Date miscAdjDate;
        pse__Miscellaneous_Adjustment__c miscAdj;

        //Loop through each billing event
        for (Id billingEventId : billingEventIds) {
            //Get the current billing event and project
            billingEvent = billingEventMasterMap.get(billingEventId);
            project = projectMasterMap.get(billingEvent.pse__Project__c);
            if (project.PSA_BR_Services_Cap_Flat_Applies__c == true) {
                System.debug('BR 10: Billing Event: ' + billingEvent.Name);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Billing Event', String.valueOf(billingEvent), null);

                //Retrieve the services billed in this billing event
    //            currentServicesBillings = unReleasedTimecardsMap.get(billingEvent.Id) != null ? unReleasedTimecardsMap.get(billingEvent.Id) : 0.0;
                if (timecardSummaryMap == null) {
                    timecardSummary = null;
                } else {
                    timecardSummary = timecardSummaryMap.get(billingEvent.Id);
                }
                currentServicesBillings = timecardSummary != null ? timecardSummary.TotalAmount : 0.0;
                System.debug('BR 10: Current timecard billings:' + currentServicesBillings);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Current timecard billings', String.valueOf(currentServicesBillings), null);

                //Retrieve any Manually-created "Services" Miscellanous Adjustments for this billing event
                currentManualMiscellaneousAdjustments = unReleasedMiscAdjsMap.get(billingEvent.Id) != null ? unReleasedMiscAdjsMap.get(billingEvent.Id) : 0.0;
                System.debug('BR 10: Current ad hoc manual adj amt:' + currentManualMiscellaneousAdjustments);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Current ad hoc manual adj amt', String.valueOf(currentManualMiscellaneousAdjustments), null);

                //Retrieve any new current credits for this billing event (from BR #9)
    //            currentMinHoursCharges = getCurrentCreditAmountForBillingEvent(miscAdjsToInsert, project.Id, billingEvent.Id);
                //*** updated by cklassen 7/11/15 to handle min. hours misc. adjustsments for projects with no timecards
                currentMinHoursCharges = billingEventMinimumHoursAmountsMap.get(billingEvent.Id) != null ? billingEventMinimumHoursAmountsMap.get(billingEvent.Id) : 0.0;
                System.debug('BR 10: Current Min. Hours charge amt:' + currentMinHoursCharges);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Current Min. Hours charge amt', String.valueOf(currentMinHoursCharges), null);

                //Get the prior services billings which includes any prior charges for minimum hours (BR #9)
                priorServicesBillings = project.PSA_BR_Services_Total_To_Date__c;
                System.debug('BR 10: Prior Services Billings: ' + priorServicesBillings);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Prior Services Billings', String.valueOf(priorServicesBillings), null);

                //Get the prior services billings which includes any prior credits for minimum hours (BR #9)
                priorServicesCredits = project.PSA_BR_Services_Credit_Applied_To_Date__c;
                System.debug('BR 10: Prior Services Credits: ' + priorServicesCredits);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Prior Services Credits', String.valueOf(priorServicesCredits), null);

                //Sum the total services billings
                totalServicesBillings = priorServicesBillings + currentMinHoursCharges + currentManualMiscellaneousAdjustments + currentServicesBillings + priorServicesCredits;
                System.debug('BR 10: Total Current and Prior Services Billings: ' + totalServicesBillings);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Total Current and Prior Services Billings', String.valueOf(totalServicesBillings), null);

                //Retrieve the capped amount from the project
                capFlatAmount = project.PSA_BR_Services_Cap_Amt__c;
                System.debug('BR 10: Project Cap Flat Amount: ' + capFlatAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Project Cap Flat Amount', String.valueOf(capFlatAmount), null);

                //If the total services billings exceed the cap, a credit will need to be created for the difference
                if (totalServicesBillings > capFlatAmount) {
                    //Set the credit amount to offset the overage
                    miscAdjAmount = capFlatAmount - totalServicesBillings;
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: Misc. Adj. Amount', String.valueOf(miscAdjAmount), null);

                    //Set the miscAdjDate (same logic as setting the invoice date when releasing a billing event)
                    miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                    //Create the misc. adj.
                    miscAdj = createMiscellaneousAdjustment(BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT, miscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                            billingEvent.Id, true, BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT, null, null, null, billingEvent.CurrencyISOCode);
                    //miscAdjsToInsert.add(miscAdj);
                    System.debug('BR 10: MiscAdjToInsert' + miscAdj);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 10: MiscAdjToInsert', String.valueOf(miscAdj), null);
                }
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #11: Holdback
    //  Inputs:
    //      1. Total of timecard splits eligible for Billing (from Billing Event Item lines)
    //      2. Total Services-related misc. adjustments
    //      3. Total Misc. Adjs. from BRs 9 and 10
    //      4. Holdback End Date (from the Project) - if a billing event time period date is after the holdback end date,
    //          the billing event should be ignored by this Billing Rule
    //      5. Holdback Percent (from the Project)
    //  Steps:
    //      1. Populate a map of total timecard amount for unreleased billing events where BR 10 applies
    //      2. Populate a map of "ad-hoc" (not created by billing rule application) un-released Misc. Adjustments
    //          related to Services for each billing Event.  The billing rule types include:
    //              'Services Charge - Minimum Hours'
    //              'Services - Time and Materials'
    //              'Services Credit - Cap Flat Amount'
    //      3. If the holdback end date is in the future, loop through billing event to determine if a BR 11 misc. adj. needs to be created.  Also may need to
    //          create a Holdback Release misc. adj. if one does not exist for the project
    //          1. Check if the project's Holdback End Date is in the future.  If not, skip this billing event
    //          2. Retrieve any timecard total for the billing event (from the map populated in step 1)
    //          3. Retrieve any ad-hoc misc. adj. total for the billing event (from the map populated in step 2)
    //          4. Retrieve any current credits for this billing event (from BR #9)
    //          5. Retrieve any prior billings (from the project) -- used for "True-up" calculations
    //          6. Retrieve any holdback amounts from the project
    //          7. Sum all current and prior services amounts (3.2, 3.3, 3.4, 3.5, and 3.6)
    //          8. Calculate the total holdback amount including prior billings
    //          9. Calculate the "true-up" amount which will be the difference of the total holdback amount minus
    //              the holdback amount applied to date
    //          10. If the true-up amount != 0, create a holdback misc. adjustment and create/update the project
    //              holdback release misc. adj
    //              1. Create the Holdback misc. adj.
    //              2. Create/Upate the Holdback Release misc. adj.
    //                  1. Look for a holdback release in the miscAdjsToUpdate list (created by an earlier billing
    //                      event in this same billing application rules application process)
    //                  2. If not found in the previous step, check the Holdback Release Misc. Adj. Master Map
    //                      which was populated when the Billing Event Application process started
    //                  3. If not found in the previous step, create a new Holdback Release Misc. Adj. for the project
    //
    //  Misc. Adjustment Billing Rule Type: 'Services Credit - Holdback'
    //  Misc. Adjustment Billing Rule Type (conditional): 'Services Charge - Holdback Release'
    ***********************************************************************************************************/
    public void applyBillingRule_Holdback() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_Holdback';

        System.debug('BR 11: running applyBillingRule_Holdback');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Initialize a set of billing event ids to apply this billing rule to
        Set<Id> billingEventIds = new Set<Id>();
        Map<String, TimecardSummaryByKeyAndBillingLevel> timecardSummaryMap;

        //Populate a map of un-released timecards summarized for each billing event
        AggregateResult[] unReleasedTimecards = getTimecardsAggregateResults(projectMasterMap.keySet(), 'PSA_BR_Holdback_Applies__c');
        System.debug('BR 11: Un-released Timecards List:' + unReleasedTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Un-released Timecards List', String.valueOf(unReleasedTimecards), null);

        if (unReleasedTimecards != null && unReleasedTimecards.size() > 0) {
            //Aggregate the timecard total hours at the billing event level
            timecardSummaryMap = timecardSummaryController.buildMap(unReleasedTimecards, 'BillingEventId', false);
            for (TimecardSummaryByKeyAndBillingLevel ts : timecardSummaryMap.values()) {
                billingEventIds.add(ts.BillingEventId);
            }
        }

        //Populate a map of un-released Misc. Adjustments related to Services for each billing Event
        AggregateResult[] unReleasedMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(pse__Miscellaneous_Adjustment__r.PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Holdback_Applies__c = true
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_MINIMUM_HOURS, :BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT)
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 11: Un-released ad-hoc Misc. Adjs.:' + unReleasedMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Un-released ad-hoc Misc. Adjs.', String.valueOf(unReleasedMiscAdjs), null);

        Map<Id, Decimal> unReleasedMiscAdjsMap = new Map<Id, Decimal>();
        if (unReleasedMiscAdjs != null && unReleasedMiscAdjs.size() > 0) {
            for (AggregateResult ar : unReleasedMiscAdjs) {
                unReleasedMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Include billing event Ids from BR9
        Set<Id> billingEventMinHoursMapIds = billingEventMinimumHoursAmountsMap.keySet();
        for (Id billingEventId : billingEventMinHoursMapIds) {
            billingEventIds.add(billingEventId);
            System.debug('BR 11 billing event min hours map: ' + billingEventMinimumHoursAmountsMap);
        }

        //Define variables to be used for calculating the misc. adj. for each billing event
        pse__Billing_Event__c billingEvent;
        pse__Proj__c project;
        TimecardSummaryByKeyAndBillingLevel timecardSummary;
        Decimal priorServicesBillings;
        Decimal currentBRChargesAndCredits;
        Decimal currentManualMiscellaneousAdjustments;
        Decimal currentServicesBillings;
        Decimal priorServicesCredits;
        Decimal totalServicesBillings;
        Decimal holdbackAppliedToDate;
        Decimal totalHoldbackAmount;
        Decimal trueUpHoldbackAmount;
        Date miscAdjDate;
        pse__Miscellaneous_Adjustment__c holdbackRelease;
        pse__Miscellaneous_Adjustment__c miscAdj;
        pse__Miscellaneous_Adjustment__c newHoldbackReleaseMiscAdj;

        for (Id billingEventId : billingEventIds) {
            //Get the current billing event and project
            billingEvent = billingEventMasterMap.get(billingEventId);
            project = projectMasterMap.get(billingEvent.pse__Project__c);
            if (project.PSA_BR_Holdback_Applies__c == true) {
                System.debug('BR 11: Billing Event Name: ' + billingEvent.Name);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Billing Event', String.valueOf(billingEvent), null);

                //BEGIN Only process the BR for this billing event if the holdback end date is current or in the future relative to the holdback end date
                if (project.PSA_BR_Holdback_End_Date__c == null ||
                        project.PSA_BR_Holdback_End_Date__c >= billingEvent.PSA_Time_Period__r.pse__End_Date__c) {
                    //Retrieve the services billed in this billing event
    //                currentServicesBillings = unReleasedTimecardsMap.get(billingEvent.Id) != null ? unReleasedTimecardsMap.get(billingEvent.Id) : 0.0;
                    if (timecardSummaryMap == null) {
                        timecardSummary = null;
                    } else {
                        timecardSummary = timecardSummaryMap.get(billingEvent.Id);
                    }
                    currentServicesBillings = timecardSummary != null ? timecardSummary.TotalAmount : 0.0;
                    System.debug('BR 11: current timecard billings:'+currentServicesBillings);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: current timecard billings', String.valueOf(currentServicesBillings), null);

                    //Retrieve any Manually-created (ad-hoc) Miscellanous Adjustments for this billing event
                    currentManualMiscellaneousAdjustments = unReleasedMiscAdjsMap.get(billingEvent.Id) != null ? unReleasedMiscAdjsMap.get(billingEvent.Id) : 0.0;
                    System.debug('BR 11: ad-hoc misc adj amt:'+currentManualMiscellaneousAdjustments);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: ad-hoc misc adj amt', String.valueOf(currentManualMiscellaneousAdjustments), null);

                    //Retrieve any current charges for this billing event (from BR #9)
                    //*** updated by cklassen 7/11/15 to handle min. hours misc. adjustsments for projects with no timecards
                    currentBRChargesAndCredits = billingEventMinimumHoursAmountsMap.get(billingEvent.Id) != null ? billingEventMinimumHoursAmountsMap.get(billingEvent.Id) : 0.0;
                    System.debug('BR 11: Current credit amt (BR 9):'+currentBRChargesAndCredits);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Current credit amt (BR 9)', String.valueOf(currentBRChargesAndCredits), null);

                    //Retrieve any current charges/credits for this billing event (from BR #10)
                    currentBRChargesAndCredits += getCurrentCreditAmountForBillingEvent(miscAdjsToInsert, project.Id, billingEvent.Id);
                    System.debug('BR 11: Current credit amt (BR 9 and 10):'+currentBRChargesAndCredits);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Current credit amt (BR 9 and 10)', String.valueOf(currentBRChargesAndCredits), null);

                    //Get the prior services billings which includes any prior services adjustments (manual and from BRs)
                    priorServicesBillings = project.PSA_BR_Services_Total_To_Date__c;
                    System.debug('BR 11: Prior Services Billings: ' + priorServicesBillings);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Prior Services Billings', String.valueOf(priorServicesBillings), null);

                    //Get the prior services billings which includes any prior charges for minimum hours (BR #9)
                    priorServicesCredits = project.PSA_BR_Services_Credit_Applied_To_Date__c;
                    System.debug('BR 11: Prior Services Credits: ' + priorServicesCredits);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Prior Services Credits', String.valueOf(priorServicesCredits), null);

                    //Holdback amount applied to date: PSA_BR_Holdback_Applied_To_Date__c -- will be used as part of the "true-up" logic
                    holdbackAppliedToDate = project.PSA_BR_Holdback_Applied_To_Date__c;
                    System.debug('BR 11: Holdback To Date: ' + holdbackAppliedToDate);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Holdback To Date', String.valueOf(holdbackAppliedToDate), null);

                    //Calculate the Total Services billings including past services aounts, current credits, current non-BR misc. adjs and current services billings
                    totalServicesBillings = priorServicesBillings + currentBRChargesAndCredits + currentManualMiscellaneousAdjustments + currentServicesBillings + priorServicesCredits;
                    System.debug('BR 11-Total Services Billings: ' + totalServicesBillings);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Total Services Billings', String.valueOf(totalServicesBillings), null);

                    //Calculate the total hold back amount (will allow us to create a "true-up" amount relative the project from inception)
                    totalHoldbackAmount = (totalServicesBillings * (project.PSA_BR_Holdback_Pct__c * .01)) * -1;
                    System.debug('BR 11: Total Holdback Amount: ' + totalHoldbackAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Total Holdback Amount', String.valueOf(totalHoldbackAmount), null);

                    //Calculate the "true-up" holdback amount
                    trueUpHoldbackAmount = totalHoldbackAmount - holdbackAppliedToDate;
                    System.debug('BR 11: True-up Holdback Amount: ' + trueUpHoldbackAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: True-up Holdback Amount', String.valueOf(trueUpHoldbackAmount), null);

                    //If the true-up holdback amount is not equal to zero, create a holdback misc. adj. either update an existing holdback misc. adj.
                    // or create a new one if none exists
                    if (trueUpHoldbackAmount != 0) {
                        //Set the miscAdjDate (same logic as setting the invoice date when releasing a billing event)
                        miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                        //Create the misc. adj.
                        miscAdj = createMiscellaneousAdjustment(BILLING_TYPE_HOLDBACK, trueUpHoldbackAmount, miscAdjDate, project.Id, billingEvent.Name,
                                billingEvent.Id, true, BILLING_TYPE_HOLDBACK, null, null, null, billingEvent.CurrencyISOCode);
                        //miscAdjsToInsert.add(miscAdj);
                        System.debug('BR 11: holdback MiscAdjToInsert'+miscAdj);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: holdback MiscAdjToInsert', String.valueOf(miscAdj), null);

                        //Create or Update a Holdback Release Misc. Adj.
                        //First check the list of Misc. Adjs. to see if it has already been added
                        holdbackRelease = getHoldBackReleaseMiscAdjForProject(miscAdjsToUpdate, project.Id);
                        if (holdbackRelease != null) {
                            holdbackRelease.pse__Amount__c += (trueUpHoldbackAmount * -1);
                            System.debug('BR 11: Found holdback release in miscAdjsToUpdate: ' + holdbackRelease);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: Found holdback release in miscAdjsToUpdate', String.valueOf(holdbackRelease), null);
                        } else {
                            //If there wasn't a holdbackRelease in the current list of Misc. Adjs. to Update, look for one
                            // in the holdback Release Master map
                            holdbackRelease = holdbackReleaseMiscAdjMasterMap.get(project.Id);
                            if (holdbackRelease != null) {
                                //update the misc. adj.
                                holdbackRelease.pse__Amount__c += (trueUpHoldbackAmount * -1);
                                miscAdjsToUpdate.add(holdbackRelease);
                                System.debug('BR 11: holdback release to update-miscAdjsToUpdate: ' + holdbackRelease);
                                //Add apex log record
                                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: holdback release to update-miscAdjsToUpdate', String.valueOf(holdbackRelease), null);
                            } else {
                                //create a new misc. adj. - attempt to use the project end date, but if it's null use today's date
                                miscAdjDate = project.pse__End_Date__c != null ? project.pse__End_Date__c : Date.today();
                                newHoldbackReleaseMiscAdj = createMiscellaneousAdjustment(BILLING_TYPE_HOLDBACK_RELEASE, (trueUpHoldbackAmount * -1), miscAdjDate, project.Id, null,
                                        null, true, BILLING_TYPE_HOLDBACK_RELEASE, null, null, null, billingEvent.CurrencyISOCode);
                                //miscAdjsToInsert.add(newHoldbackReleaseMiscAdj);
                                System.debug('BR 11: holdback release to insert-MiscAdjToInsert: ' + newHoldbackReleaseMiscAdj);
                                //Add apex log record
                                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 11: holdback release to insert-MiscAdjToInsert', String.valueOf(newHoldbackReleaseMiscAdj), null);
                            }
                        }
                    }
                } //END If the holdback end date is prior to the current billing period end date, skip this billing event
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #13: Account Discount Part Two
    public void applyBillingRule_AccountDiscountTwo() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_AccountDiscount';

        System.debug('BR 13: running applyBillingRule_AccountDiscount');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
        Set<Id> projectIds = new Set<Id>();
        Set<Id> accountDiscountIds = new Set<Id>();

        //This will hold a list of discounts we need to apply at each project account discount level
        Map<Id, Decimal> projectDiscountToAmount = new Map<Id, Decimal>();
        Decimal totalExcludedTime = 0.0;

        AccountDiscountAmount accountDiscountController = new AccountDiscountAmount();
        System.debug('Master map : '+billingEventMasterMap.keySet());
        Map<Id, pse__Billing_Event__c> accountDiscountBillingEventsMap = new Map<Id, pse__Billing_Event__c>(
            [Select Id,
                    Name,
                    pse__Project__c,
                    CurrencyISOCode,
                    pse__Billing_Event_Batch__c,
                    PSA_Time_Period__r.pse__Type__c,
                    PSA_Time_Period__r.pse__Start_Date__c,
                    PSA_Time_Period__r.pse__End_Date__c,
                    pse__Project__r.PSA_BR_Account_Discount__c,
                    PSA_Account_Discount_Services_Total__c
                From pse__Billing_Event__c
                Where Id in :billingEventMasterMap.keySet()
                
                And pse__Project__r.PSA_BR_Account_Discount_Applies__c = true
            ]);
        System.debug('Billing events map: '+accountDiscountBillingEventsMap);
        ////// And pse__Is_Released__c = false
        for(pse__Billing_Event__c be : accountDiscountBillingEventsMap.values()){
            projectIds.add(be.pse__Project__c);
        }

        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: accountDiscountBillingEventsMap', String.valueOf(accountDiscountBillingEventsMap), null);
        Date today = Date.today();
        List<PSA_Project_Account_Credit__c> credits = [Select Id, Assignment__c, Project__c,
            assignment__r.pse__Resource__r.name,
            PSA_Account_Credit__c,
            PSA_Account_Credit__r.PSA_Account__c,
            PSA_Account_Credit__r.PSA_Discount_Active__c,
            PSA_Account_Credit__r.PSA_Discount_Amount_Applied__c,
            PSA_Account_Credit__R.PSA_Discount_Amount_Remaining__c,
            PSA_Account_Credit__r.PSA_Discount_Billing_Levels__c,
            PSA_Account_Credit__r.PSA_Discount_Cap__c,
            PSA_Account_Credit__r.PSA_Discount_Eligible_Billings_To_Date__c,
            PSA_Account_Credit__r.PSA_Discount_End_Date__c,
            PSA_Account_Credit__r.PSA_Discount_Percent__c,
            PSA_Account_Credit__r.PSA_Discount_Type__c
            from PSA_Project_Account_Credit__c
            where Project__c in :projectIds AND PSA_Account_Credit__r.PSA_Discount_Active__c = true
            AND PSA_Account_Credit__r.PSA_DIscount_End_Date__c >= :today];

         System.Debug('BR 13: Found Project Discounts:' + credits);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Found Project Discounts', String.valueOf(credits), null);
       


        Map<Id, List<PSA_Project_Account_Credit__c>> projectToAccountCredits = new Map<Id, List<PSA_Project_Account_Credit__c>>();
        Map<Id, List<String>> projectToBillingLevels = new Map<Id, List<String>>();

        //The key for this map is going to be Assignment | Billing Level
        //This means that if one Account Credit applies to multiple billing levels, there could be multiple keys mapped to the same
        // Account Credit
        Map<String, List<PSA_Account_Discount__c>> keyToPAC = new Map<String, List<PSA_Account_Discount__c>>();

        for(PSA_Project_Account_Credit__c pac : credits){
            PSA_Account_Discount__c ac = pac.PSA_Account_Credit__r;
            String assignment = pac.Assignment__c == null ? '' : ''+pac.Assignment__c;


            List<PSA_Project_Account_Credit__c> projectCredits = projectToAccountCredits.get(pac.Project__c);
            List<String> projectLevels = projectToBillingLevels.get(pac.Project__c);
            String[] selectedLevels = pac.PSA_Account_Credit__r.PSA_Discount_Billing_Levels__c.split(';');

            accountDiscountIds.add(pac.PSA_Account_Credit__c);
            for(String s : selectedLevels){
                String thisKey = assignment+'|'+s;
                List<PSA_Account_Discount__c> discs = keyToPAC.get(thisKey);
                if(discs == null){
                    discs = new List<PSA_Account_Discount__c>();
                }
                discs.add(ac);
                keyToPAC.put(thisKey, discs);
            }

            if(projectCredits == null){
                projectCredits = new List<PSA_Project_Account_Credit__c>();
            }
            if(projectLevels == null){
                projectLevels = new List<String>();
            }
            projectCredits.add(pac);
            projectToAccountCredits.put(pac.Project__c, projectCredits);
            projectLevels.addAll(selectedLevels);
            projectToBillingLevels.put(pac.Project__c, projectLevels);

        }


        Map<Id, pse__Billing_Event_Item__c> allTimecards = new Map<Id, pse__Billing_Event_Item__c>([Select pse__Timecard_Split__r.pse__Resource__c,
                    pse__Billing_Event__c,
                    pse__Project__c,
                    pse__Project__r.pse__Account__c,
                    pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c,
                    pse__Timecard_Split__r.pse__Total_Hours__c,
                    pse__Timecard_Split__r.pse__Assignment__c,
                    pse__Timecard_Split__r.pse__Total_Days_Worked__c,
                    pse__Timecard_Split__r.pse__Project__c,
                    pse__Timecard_Split__r.PSA_Total_Billable_Number__c
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Timecard_Split__c != null
                And pse__Timecard_Split__r.pse__Timecard_Header__r.pse__Milestone__r.Name != :OVER_CAP_MILESTONE_NAME
                And pse__Project__r.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c != null
                Order by pse__Billing_Event__c]);

         System.debug('BR 13: Current Timecards (BE Items):' + allTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Timecards (BE Items)', String.valueOf(allTimecards), null);

        //Split out the current timecard results between billing levels that are included in the discount calculaion
        // and ones that are excluded from the discount calculations
        List<pse__Billing_Event_Item__c> includedCurrentTimecards = new List<pse__Billing_Event_Item__c>();
        List<pse__Billing_Event_Item__c> excludedCurrentTimecards = new List<pse__Billing_Event_Item__c>();
        for (pse__Billing_Event_Item__c result : allTimecards.values()) {
            String key = '';
            if(result.pse__Timecard_Split__r.pse__Assignment__c != null){

            }
            List<String> billingLevels = projectToBillingLevels.get(result.pse__Project__c);
            Set<String> setLevels = new Set<String>();
            for(String s : billingLevels){
                setLevels.add(s);
            }
            //project = projectMasterMap.get((Id)result.get('ProjectId'));
            //billingEvent = billingEventMasterMap.get((Id)result.get('BillingEventId'));
            if (setLevels.contains(result.pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c)) {
                includedCurrentTimecards.add(result);
            } else {
                excludedCurrentTimecards.add(result);
                totalExcludedTime += result.pse__Timecard_Split__r.PSA_Total_Billable_Number__c;
            }
        }
        System.Debug('BR 13: Included current timecards:' + includedCurrentTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Included current timecards', String.valueOf(includedCurrentTimecards), null);
        System.Debug('BR 13: Excluded current timecards:' + excludedCurrentTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Excluded current timecards', String.valueOf(excludedCurrentTimecards), null);

        Map<Id, Decimal> projToExcludedTotal = new Map<Id, Decimal>();
        for(pse__Billing_Event_Item__c excl : excludedCurrentTimecards){
            Decimal curTotal = projToExcludedTotal.get(excl.pse__Timecard_Split__r.pse__Project__c) != null ? projToExcludedTotal.get(excl.pse__Timecard_Split__r.pse__Project__c) : 0.0;
            curTotal += excl.pse__Timecard_Split__r.PSA_Total_Billable_Number__c;
            projToExcludedTotal.put(excl.pse__Timecard_Split__r.pse__Project__c, curTotal);
        }

        Map<Id, PSA_Account_Discount__c> accountDiscountMap = new Map<Id, PSA_Account_Discount__c>(
            [Select Id, PSA_Discount_Amount_Applied__c, PSA_Discount_Eligible_Billings_To_Date__c
                From PSA_Account_Discount__c
                Where PSA_Discount_Active__c = true
            ]);
        System.Debug('BR 13: Account Discount Map:' + accountDiscountMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Account Discount Map', String.valueOf(accountDiscountMap), (List<SObject>)accountDiscountMap.values());

        //Populate a map of un-released ad-hoc Misc. Adjustments related to Services for each billing Event
        List<pse__Billing_Event_Item__c> unReleasedMiscAdjsList = [Select pse__Billing_Event__c, pse__Miscellaneous_adjustment__r.PSA_Amount_Number__c, pse__Miscellaneous_ADjustment__r.Billing_Level__c
                                                        from pse__Billing_Event_Item__c
                                                        Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                                                        And pse__Miscellaneous_Adjustment__c != null
                                                        And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                                                        And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                                                            (:BILLING_TYPE_MINIMUM_HOURS, :BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT)];
        Map<Id, List<pse__Billing_Event_Item__c>> beToUnreleased = new Map<Id, List<pse__Billing_event_Item__c>>();
        for(pse__Billing_EVent_Item__c unadj : unReleasedMiscAdjsList){
            List<pse__Billing_Event_Item__c> items = beToUnreleased.get(unadj.pse__Billing_Event__c);
            if(items == null){
                items = new List<pse__Billing_Event_Item__c>();
            }
            items.add(unadj);
            beToUnreleased.put(unadj.pse__Billing_Event__c, items);
        }

        List<pse__Billing_Event_Item__c> minBillHoursList = [Select pse__Billing_Event__c, pse__Miscellaneous_Adjustment__r.PSA_Amount_Number__c,pse__Miscellaneous_Adjustment__r.Billing_Level__c
                from pse__Billing_Event_Item__c
                where pse__Billing_Event__c = :billingEventMasterMap.keySet()
                and pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c = :BILLING_TYPE_MINIMUM_HOURS
                and pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = true];
        Map<Id, List<pse__Billing_Event_ITem__c>> minimumHoursMap = new Map<Id, List<pse__Billing_Event_Item__c>>();
        for(pse__Billing_Event_ITem__c bei : minBillHoursList){
            List<pse__Billing_Event_Item__c> items = minimumHoursMap.get(bei.pse__Billing_event__c);
            if(items == null){
                items = new List<pse__Billing_event_Item__c>();
            }
            items.add(bei);
            minimumHoursMap.put(bei.pse__Billing_Event__c, items);
        }

        AggregateResult[] unReleasedMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_MINIMUM_HOURS, :BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT)
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 13: Un-released Misc. Adjs. List:' + unReleasedMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Un-released Misc. Adjs. List', String.valueOf(unReleasedMiscAdjs), (List<SObject>)unReleasedMiscAdjs);

        Map<Id, Decimal> unReleasedMiscAdjsMap = new Map<Id, Decimal>();
        if (unReleasedMiscAdjs != null && unReleasedMiscAdjs.size() > 0) {
            for (AggregateResult ar : unReleasedMiscAdjs) {
                unReleasedMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
            }
        }

        //Populate a map of un-released Holdback Release Billing Event Items related to Services for each billing Event
        Map<Id, pse__Billing_Event_Item__c> holdbackReleaseBillEventItemMap = new Map<Id, pse__Billing_Event_Item__c>();
        List<pse__Billing_Event_Item__c> holdbackReleaseBillEventItems =
            [Select pse__Billing_Event__c, pse__Amount__c, pse__Miscellaneous_Adjustment__r.PSA_BR_Eligible_Discount_Amount__c,
                    pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, pse__Billing_Event__r.CurrencyISOCode
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = true
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c = :BILLING_TYPE_HOLDBACK_RELEASE
            ];
        if (holdbackReleaseBillEventItems != null && holdbackReleaseBillEventItems.size() > 0) {
            for (pse__Billing_Event_Item__c bei : holdbackReleaseBillEventItems) {
                holdbackReleaseBillEventItemMap.put(bei.pse__Billing_Event__c, bei);
            }
        }
        System.debug('BR 13: Unreleased Holdback Release BE Item Map: ' + holdbackReleaseBillEventItemMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Unreleased Holdback Release BE Item Map', String.valueOf(holdbackReleaseBillEventItemMap), null);



        //Create variables used to process all of the inputs and billing rule values
        // More variables are used than are really needed, but "extras" have been included
        // for the sake of being able to follow the logic in the code more easily
        TimecardSummaryByKeyAndBillingLevel priorTimecardSummary;
        TimecardSummaryByKeyAndBillingLevel currentTimecardAmountIncluded;
        PSA_Account_Discount__c accountDiscount;
        Decimal currentTimecardSummaryAmount;
        Decimal priorEligibleBillings;
        Decimal currentMinHoursCharge;
        Decimal currentServicesCapFlatCredit;
        Decimal nonBillingRuleMiscAdjustments;

        //Holdback and Holdback Release variables
        Decimal currentHoldbackCredit;
        Decimal currentHoldbackReleaseCharge;
        pse__Miscellaneous_Adjustment__c holdbackReleaseMiscAdj;
        pse__Miscellaneous_Adjustment__c holdbackMiscAdj;
        pse__Billing_Event_Item__c holdbackReleaseBillEventItem;
        TimecardSummaryByKeyAndBillingLevel currentHoldbackExcluded;
        Decimal currentHoldbackExcludeAmount;

        Decimal totalCurrentServicesAmount;
        Decimal discountPercent;
        Decimal discountCap = 0.0;
        Decimal totalDiscountAmount = 0.0;
        Decimal priorDiscountAppliedAmount;
        Decimal currentDiscountEligibleBillingsAmount;
        Decimal currentDiscountAmount;

        pse__Miscellaneous_Adjustment__c miscAdj;
        Decimal miscAdjAmount;
        Date miscAdjDate;

        //Loop through the list of applicable billing events
        for (pse__Billing_Event__c billingEvent : accountDiscountBillingEventsMap.values()) {
            System.debug('BR 13: Billing Event Name: ' + billingEvent.Name);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Billing Event', String.valueOf(billingEvent), null);

            pse__Proj__c project = projectMasterMap.get(billingEvent.pse__Project__c);
            //Build a set of Account Discount Ids which will be used to refresh the Account Discount "to-date" balances
            Decimal totalToDiscount = 0.0;
            Decimal excludedFromDiscount = 0.0;
            Map<Id, Decimal> creditToAmountMap = new Map<Id, Decimal>();

            for(pse__Billing_Event_Item__c bei : allTimecards.values()){
                String assign = bei.pse__Timecard_Split__r.pse__Assignment__c == null ? '' : '' + bei.pse__Timecard_Split__r.pse__Assignment__c;
                String thisKey = assign +'|'+ bei.pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c;
                List<PSA_Account_Discount__c> applied = keyToPAC.get(thisKey);
                boolean listFound = true;
                if(applied == null){
                    thisKey = ''+'|'+ bei.pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c;
                    applied = keyToPAC.get(thisKey);
                    if(applied == null){
                        listFound = false;
                    }
                }

                System.debug('BR 13: Found a list of applicable discounts: ' + applied);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Found a list of applicable discounts', String.valueOf(applied), null);

                PSA_Account_Discount__c discToApply = null;
                boolean discFound = false;
                if(listFound){
                    for(PSA_Account_Discount__c pad : applied){
                        if(pad.PSA_Discount_End_Date__c == null || pad.PSA_Discount_End_Date__c >= billingEvent.PSA_Time_Period__r.pse__End_Date__c){
                            discFound = true;
                            disctoApply = pad;

                            System.debug('BR 13: Found a discount: ' + pad);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Found a discount: ', String.valueOf(pad), null);
                            break;
                        }
                    }
                }

                if(!discFound){
                    excludedFromDiscount += (bei.pse__Amount__c != null ? bei.pse__Amount__c : 0);
                }

                if(discFound){
                    totalToDiscount += (bei.pse__Amount__c != null ? bei.pse__Amount__c : 0);
                    //We found a discount to apply to this billing event item. It is the object stored in DiscToApply
                    //Determine how to discount the timecard
                    //Application logic to the timecard
                    priorEligibleBillings = discToApply.PSA_Discount_Eligible_Billings_To_Date__c;
                    discountPercent = discToApply.PSA_Discount_Percent__c * 0.01;
                    Decimal discountRemaining = discToApply.PSA_Discount_Amount_Remaining__c;
                    System.debug('BR 13: discount applied: '+discToApply.PSA_Discount_Amount_Applied__c);
                    System.debug('BR 13: Prior Eligible Billings: ' + priorEligibleBillings);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Prior Eligible Billings', String.valueOf(priorEligibleBillings), null);

                    System.debug('BR 13: Discount Percent: ' + discountPercent);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Discount Percent: ', String.valueOf(discountPercent), null);    

                    //check the cap: PSA_BR_Account_Discount_Cap__c.  If it's null, set it to zero
                    discountCap = disctoApply.PSA_Discount_Cap__c != null ? disctoApply.PSA_Discount_Cap__c : 0;
                    System.debug('BR 13: Discount Cap:' + discountCap);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Discount Cap', String.valueOf(discountCap), null);

                    Decimal currentCustomerCreditAmount = accountDiscountController.getCurrentAccountDiscountAmount(accountDiscountAmounts,
                        discToApply.id);
                    System.debug('BR 13: Current customer discount credit amt:' + currentCustomerCreditAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current customer discount credit amt', String.valueOf(currentCustomerCreditAmount), null);

                    Decimal remainingDiscount = 0.0;
                    if (discountCap > 0) {
                        remainingDiscount = discountCap + currentCustomerCreditAmount - discToApply.PSA_Discount_Amount_Applied__c;
                    }
                    System.debug('BR 13: Remaining Discount: ' + remainingDiscount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Remaining Discount', String.valueOf(remainingDiscount), null);

                    Decimal thisAmount = bei.pse__Timecard_Split__r.PSA_Total_Billable_Number__c;
                    Decimal thisDiscountAmount = (thisAmount + priorEligibleBillings) * discountPercent;
                    System.debug('BR 13: Amount Applied from this timecard: ' + thisDiscountAmount+' BL: '+bei.pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Amount applied from timecard', String.valueOf(thisDiscountAmount), null);
                    System.debug('BR 13: Prior Billings: '+priorEligibleBillings);


                    //Get the previously applied discount amount
                    priorDiscountAppliedAmount = discToApply.PSA_Discount_Amount_Applied__c;
                    System.debug('BR 13: Previously Applied Discount Amount: ' + discToApply.PSA_Discount_Amount_Applied__c);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Previously Applied Discount Amount', String.valueOf(discToApply.PSA_Discount_Amount_Applied__c), null);

                    //Derive the "adjusted" discount amount.  This is the amount that will be used if there is no discount cap,
                    // but the "final" discount amount may be different if the discount cap will be exceeded based on the adjusted amount
                    //Decimal adjustedDiscountAmount = thisDiscountAmount + currentCustomerCreditAmount + priorDiscountAppliedAmount;
                    Decimal adjustedDiscountAmount = thisDiscountAmount + currentCustomerCreditAmount;
                    System.debug('BR 13: Adjusted Discount Amount: ' + adjustedDiscountAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Adjusted Discount Amount', String.valueOf(adjustedDiscountAmount), null);


                    //If there is any discount available (possibly not if there is a discount cap), determine what the final
                    // discount amount should be ("currentDiscountAmount").  This is what will be used to create the Misc. Adj.
                    //First need to initialize the current discount amount to zero and then set it to a different value if applicable
                    currentDiscountAmount = 0.00;
                    if (remainingDiscount != 0.0) {
                        if (adjustedDiscountAmount > remainingDiscount) {
                            currentDiscountAmount = remainingDiscount;
                            System.debug('BR 13: Current Discount Amount (total exceeded cap): ' + currentDiscountAmount);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total exceeded cap)', String.valueOf(currentDiscountAmount), null);
                        } else {
                            currentDiscountAmount = adjustedDiscountAmount;
                            System.debug('BR 13: Current Discount Amount (total did not exceed cap): ' + currentDiscountAmount);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total did not exceed cap)', String.valueOf(currentDiscountAmount), null);
                        }
                    } else if (discountCap == 0.0) {
                        //No cap so just set the current discount amount to the initial discount amount
                        currentDiscountAmount = adjustedDiscountAmount;
                        System.debug('BR 13: Current Discount Amount: ' + currentDiscountAmount);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount', String.valueOf(currentDiscountAmount), null);
                    }
                    Decimal previousDiscount = projectDiscountToAmount.get(discToApply.ID) != null ? projectDiscountToAmount.get(discToApply.ID) : 0.0;
                    previousDiscount += currentDiscountAmount;
                    projectDiscountToAmount.put(disctoApply.ID, previousDiscount);

                    discToApply.PSA_Discount_Amount_Applied__c = discToApply.PSA_Discount_Amount_Applied__c + currentDiscountAmount;
                    totalDiscountAmount += currentDiscountAmount;
                   // currentDiscountAmount = (currentDiscountAmount * -1);
                }
            }

            //Retrieve necessary misc adjustments. Check the billing levels against created credits. 
            //If they match, add the amounts to the included amounts, update the proejctDiscountToAmount map to include new values
            List<pse__Billing_event_Item__c> beToUnreleasedItems = beToUnreleased.get(billingEvent.id);
            List<pse__Billing_event_Item__c> minBilHoursItems = minimumHoursMap.get(billingEvent.id);
            beToUnreleasedItems.addAll(minBilHoursItems);
            for(pse__Billing_Event_Item__c bei : beToUnreleasedItems){
                String key = ''+'|'+ bei.pse__Miscellaneous_Adjustment__r.Billing_Level__c;
                List<PSA_Account_Discount__c> applied = keyToPAC.get(key);

                PSA_Account_Discount__c discToApply = null;
                boolean discFound = false;
                if(applied != null && applied.size() > 0){
                    for(PSA_Account_Discount__c pad : applied){
                        if(pad.PSA_Discount_End_Date__c == null || pad.PSA_Discount_End_Date__c >= billingEvent.PSA_Time_Period__r.pse__End_Date__c){
                            discFound = true;
                            disctoApply = pad;

                            System.debug('BR 13: Found a discount for  misc adjustments: ' + pad);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Found a discount for misc adjustments : ', String.valueOf(pad), null);
                            break;
                        }
                    }
                }

                if(!discFound){
                    excludedFromDiscount += (bei.pse__Amount__c != null ? bei.pse__Amount__c : 0);
                }

                if(discFound){
                    totalToDiscount += (bei.pse__Amount__c != null ? bei.pse__Amount__c : 0);
                    //Repeat the steps from the timecard section
                    priorEligibleBillings = discToApply.PSA_Discount_Eligible_Billings_To_Date__c;
                    discountPercent = discToApply.PSA_Discount_Percent__c * 0.01;
                    Decimal discountRemaining = discToApply.PSA_Discount_Amount_Remaining__c;
                    discountCap = disctoApply.PSA_Discount_Cap__c != null ? disctoApply.PSA_Discount_Cap__c : 0;
                    Decimal currentCustomerCreditAmount = accountDiscountController.getCurrentAccountDiscountAmount(accountDiscountAmounts,discToApply.id);
                    Decimal remainingDiscount = 0.0;
                    if (discountCap > 0) {
                        remainingDiscount = discountCap + currentCustomerCreditAmount - discToApply.PSA_Discount_Amount_Applied__c;
                    }
                    Decimal thisAmount = bei.pse__Miscellaneous_Adjustment__r.PSA_Amount_Number__c;
                    Decimal thisDiscountAmount = (thisAmount + priorEligibleBillings) * discountPercent;
                    //Get the previously applied discount amount
                    priorDiscountAppliedAmount = discToApply.PSA_Discount_Amount_Applied__c;
                    Decimal adjustedDiscountAmount = thisDiscountAmount + currentCustomerCreditAmount;
                    currentDiscountAmount = 0.00;
                    if (remainingDiscount != 0.0) {
                        if (adjustedDiscountAmount > remainingDiscount) {
                            currentDiscountAmount = remainingDiscount;
                            System.debug('BR 13: Current Discount Amount (total exceeded cap): ' + currentDiscountAmount);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total exceeded cap)', String.valueOf(currentDiscountAmount), null);
                        } else {
                            currentDiscountAmount = adjustedDiscountAmount;
                            System.debug('BR 13: Current Discount Amount (total did not exceed cap): ' + currentDiscountAmount);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total did not exceed cap)', String.valueOf(currentDiscountAmount), null);
                        }
                    } else if (discountCap == 0.0) {
                        //No cap so just set the current discount amount to the initial discount amount
                        currentDiscountAmount = adjustedDiscountAmount;
                        System.debug('BR 13: Current Discount Amount: ' + currentDiscountAmount);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount', String.valueOf(currentDiscountAmount), null);
                    }
                    Decimal previousDiscount = projectDiscountToAmount.get(discToApply.ID) != null ? projectDiscountToAmount.get(discToApply.ID) : 0.0;
                    previousDiscount += currentDiscountAmount;
                    projectDiscountToAmount.put(disctoApply.ID, previousDiscount);

                    discToApply.PSA_Discount_Amount_Applied__c = discToApply.PSA_Discount_Amount_Applied__c + currentDiscountAmount;
                    totalDiscountAmount += currentDiscountAmount;

                }

            }

            
            System.debug('BR 13: Non Billing Rule Misc. Adjs.: ' + nonBillingRuleMiscAdjustments);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Non Billing Rule Misc. Adjs.', String.valueOf(nonBillingRuleMiscAdjustments), null);


            for(Id projDiscount : projectDiscountToAmount.keySet()){
                Decimal amt = projectDiscountToAmount.get(projDiscount);
                if(amt != null && amt != 0){
                    //Set the misc adj amount
                    miscAdjAmount = amt;

                    //Set the miscAdjDate (same logic as setting the invoice date when releasing a billing event)
                    miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                    //create misc adj;
                    miscAdj = createMiscellaneousAdjustment(BILLING_TYPE_CUSTOMER_DISCOUNT, miscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                            billingEvent.Id, true, BILLING_TYPE_CUSTOMER_DISCOUNT, null, null, null, billingEvent.CurrencyISOCode);
                    //miscAdjsToInsert.add(miscAdj);
                }
            }


            System.debug('BR 13: Excluded Time Total: ' + projToExcludedTotal.get(project.id));
            //Apply holdback or cap discounts, update discount fields, true up the discounts
            holdbackMiscAdj = getMiscAdjForBillingEventAndBillingRuleType(miscAdjsToInsert, billingEvent.Id, BILLING_TYPE_HOLDBACK);
            if (holdbackMiscAdj != null) {
                currentHoldbackCredit = holdbackMiscAdj.pse__Amount__c;
                System.debug('BR 13: Starting current Holdback Credit: ' + currentHoldbackCredit);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Starting current Holdback Credit', String.valueOf(currentHoldbackCredit), null);

                //Retrieve the amount of timecards for excluded billing levels
                Decimal excludedAmount = projToExcludedTotal.get(project.id) != null ? projToExcludedTotal.get(project.id) : 0.0;
                //currentHoldbackExcluded = projToExcludedTotal.get(project.id) != null ? projToExcludedTotal.get(project.id) : 0.0;
                System.debug('BR 13: Current Holdback Excluded: ' + excludedAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Holdback Excluded', String.valueOf(currentHoldbackExcluded), null);

                currentHoldbackExcludeAmount = excludedAmount;
                currentHoldbackCredit += currentHoldbackExcludeAmount * (project.PSA_BR_Holdback_Pct__c * 0.01);
                holdbackMiscAdj.PSA_BR_Eligible_Discount_Amount__c = currentHoldbackCredit;
            } else {
                currentHoldbackCredit = 0.0;
                currentHoldbackExcludeAmount = 0.0;
            }
            System.debug('BR 13: Final current Holdback Credit: ' + currentHoldbackCredit);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Final current Holdback Credit', String.valueOf(currentHoldbackCredit), null);

        }

        
        System.debug('The final map: '+projectDiscountToAmount);

    }
    */

    /***********************************************************************************************************
    // GW Billing Rule #13: Account Discount
    //  Inputs:
    //      1. Total Hours worked of timecard splits eligible for Billing (from Billing Event Item lines)
    //      2. Various PSA Account Discount fields, including applicable billing levels, cap, end date, and percent
    //      3. Map with Account Id and a list of all past Services at the billing level
    //  Steps:
    //      1. Get the list of eligible billing events (where Account Discount Applies)
    //      2. Get total Timecard Split billing items grouped by Billing Event and Billing Level
    //      3. Use the related Account Discount Billing levels to separate the timecard splits into an "included"
    //          and an "excluded" summary amount.  The excluded amount will NOT be included in the current services
    //          amount, and it will also be used to potentially reduce any holdback amounts that included amounts
    //          from the "excluded" timecards.
    //      4. Get all related Account Discount records (populate a map)
    //      5. Populate a map of "ad-hoc" (not created by billing rule application) un-released Misc. Adjustments
    //          related to Services for each billing Event.  The billing rule types include:
    //              'Services Charge - Minimum Hours'
    //              'Services - Time and Materials'
    //              'Services Credit - Cap Flat Amount'
    //      6. Populate a map of un-released Holdback Release Billing Event Items for each billing Event
    //      7. Loop through all applicable Billing Events and perform the following tasks:
    //          1. Retrieve the related project
    //          2. Verify the related account discount end date is not in the past.  If so, skip this billing event
    //          3. Retrieve the current timecard amount for included timecards (from the map populated in step 3)
    //          4. Retrieve the prior eligible billings amount (from the map populated in step 4)
    //          5. Retrieve any "ad-hoc" or non-billing rule created misc adjustments for this billing event (from the map
    //              populated in step 5)
    //          6. Retrieve any current misc. adjustments for current billing event including BR 9 (Min. Monthly Hours)
    //          7. Retrieve any current misc. adjustments for current billing event including BR 10 (Services Cap Flat Amount)
    //          8. Retrieve any current misc. adjustments for current billing event including BR 11 (Holdback)
    //              a. Retrieve a holdback for the current billing event
    //              b. If a holdback exists, back out any amount that was based on excluded timecard amounts (from the map
    //                  populated in step 3)
    //          9. Retrieve a Holdback Release for the current billing event if one exists
    //              a. Retrieve the Holdback Release Misc. Adj
    //              b. If a holdback release exists, back out any amount that was based on excluded timecard amounts (from
    //                  the map populated in step 3)
    //          10. Sum up all "services" inputs (steps 3, 5, 6, 7, 8, and 9)
    //          11. Retrieve any current "Customer Discount" credits for this Account (discounts for individual projects for the
    //               same account will be added on a first come-first served basis)
    //          12.
    //            7. Get the total current Services billings by summing up the results from 4, 5, 6, 7.4, 7.5, 7.6a, and 7.6b
    //            8. Get the Project's prior expense billings ("PSA_BR_Expense_Total_To_Date__c")
    //            9. Get the Project's prior services billings ("PSA_BR_Services_Total_To_Date__c")
    //            10. Get the Project's prior discount applied amount ("PSA_BR_Discount_Applied_To_Date__c")
    //            11. Get the total current and prior expense billings
    //            12. Get the total current and prior services billings, including any prior discount applied amount
    //            13. Get any current expense credits for other billing events for the same project
    //            14. Get the Amount of expense credits applied to date on the related project ("PSA_BR_Expense_Credits_Applied_To_Date__c")
    //            15. Get the total expense credits (current and prior)
    //            16. Get the Expense Pct Cap from the related project ("PSA_BR_Expense_Cap_Pct__c")
    //            17. Set the total cap amount for the project based on the Expense Cap Pct (divided by 100) multiplied
    //                by the total current and prior services billings.
    //            18. Get an adjusted cap amount
    //            19. If the total current and prior expense billings exceed the total cap, subtract


    //      5. Create a Misc. Adjustument for the result of step 4
    //  Misc. Adjustment Billing Rule Type: 'Services Credit - Customer Discount'
    //  Revisions:
    //          2016-01-06  Klassen  Fixed bug that was causing cap to be exceeded on future billing runs after
    //                                  the cap was reached in a prior billing event
    ***********************************************************************************************************/
    public void applyBillingRule_AccountDiscount() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_AccountDiscount';

        System.debug('BR 13: running applyBillingRule_AccountDiscount');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Define variabled used later in the method
        pse__Proj__c project;
        AccountDiscountAmount accountDiscountController = new AccountDiscountAmount();

        //Retrieve list of billing events that may have billing event items that will be included in the inputs
        // for Account Discounts
        Map<Id, pse__Billing_Event__c> accountDiscountBillingEventsMap = new Map<Id, pse__Billing_Event__c>(
            [Select Id,
                    Name,
                    pse__Project__c,
                    CurrencyISOCode,
                    pse__Billing_Event_Batch__c,
                    PSA_Time_Period__r.pse__Type__c,
                    PSA_Time_Period__r.pse__Start_Date__c,
                    PSA_Time_Period__r.pse__End_Date__c,
                    pse__Project__r.PSA_BR_Account_Discount__c,
                    PSA_Account_Discount_Services_Total__c
                From pse__Billing_Event__c
                Where Id = :billingEventMasterMap.keySet()
                And pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Account_Discount_Applies__c = true
                And pse__Project__r.PSA_BR_Account_Discount__r.PSA_Discount_Active__c = true
            ]);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: accountDiscountBillingEventsMap', String.valueOf(accountDiscountBillingEventsMap), null);

        //Sum up all timecard hours, days, and amounts by billing level
        AggregateResult[] arCurrentTimecards =
            [Select pse__Timecard_Split__r.pse__Resource__c ResourceId,
                    pse__Billing_Event__c BillingEventId,
                    pse__Project__c ProjectId,
                    pse__Project__r.pse__Account__c AccountId,
                    pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c BillingLevel,
                    Sum(pse__Timecard_Split__r.pse__Total_Hours__c) TotalHours,
                    Sum(pse__Timecard_Split__r.pse__Total_Days_Worked__c) TotalDays,
                    Sum(pse__Timecard_Split__r.PSA_Total_Billable_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Timecard_Split__c != null
                And pse__Timecard_Split__r.pse__Timecard_Header__r.pse__Milestone__r.Name != :OVER_CAP_MILESTONE_NAME
                And pse__Project__r.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c != null
                Group by pse__Timecard_Split__r.pse__Resource__c, pse__Billing_Event__c, pse__Project__c,
                    pse__Project__r.pse__Account__c, pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c
                Order by pse__Billing_Event__c
            ];
        //AggregateResult[] arCurrentTimecards = getTimecardsAggregateResults(projectMasterMap.keySet(), 'PSA_BR_Holdback_Applies__c');
        System.debug('BR 13: Current Timecards (BE Items):' + arCurrentTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Timecards (BE Items)', String.valueOf(arCurrentTimecards), null);

        //Split out the current timecard results between billing levels that are included in the discount calculaion
        // and ones that are excluded from the discount calculations
        AggregateResult[] includedCurrentTimecards = new AggregateResult[]{};
        AggregateResult[] excludedCurrentTimecards = new AggregateResult[]{};
        for (AggregateResult result : arCurrentTimecards) {
            project = projectMasterMap.get((Id)result.get('ProjectId'));
            //billingEvent = billingEventMasterMap.get((Id)result.get('BillingEventId'));
            if (project.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c.contains((String)result.get('BillingLevel'))) {
                includedCurrentTimecards.add(result);
            } else {
                excludedCurrentTimecards.add(result);
            }
        }
        System.Debug('BR 13: Included current timecards:' + includedCurrentTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Included current timecards', String.valueOf(includedCurrentTimecards), null);
        System.Debug('BR 13: Excluded current timecards:' + excludedCurrentTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Excluded current timecards', String.valueOf(excludedCurrentTimecards), null);

        //Build a map of summarized timecard amounts that will be included in the Account Discount inputs.
        Map<String, TimecardSummaryByKeyAndBillingLevel> includedCurrentTimecardSummaryMap =
            new Map<String, TimecardSummaryByKeyAndBillingLevel>();
        if (includedCurrentTimecards != null && includedCurrentTimecards.size() > 0) {
            includedCurrentTimecardSummaryMap = timecardSummaryController.buildMap(includedCurrentTimecards, 'BillingEventId', false);
        }

        //Build a map of summarized timecard amounts that will be excluded from the Account Discount inputs.
        // This may be used to exclude some timecard totals from the total Holdback credit, if there is one
        Map<String, TimecardSummaryByKeyAndBillingLevel> excludedCurrentTimecardSummaryMap =
            new Map<String, TimecardSummaryByKeyAndBillingLevel>();
        if (excludedCurrentTimecards != null && excludedCurrentTimecards.size() > 0) {
            excludedCurrentTimecardSummaryMap = timecardSummaryController.buildMap(excludedCurrentTimecards, 'BillingEventId', false);
        }

        //Populate a map of prior account discount amounts and eligible billings to date which will be used as part
        // of the "true-up" calculation
        Map<Id, PSA_Account_Discount__c> accountDiscountMap = new Map<Id, PSA_Account_Discount__c>(
            [Select Id, PSA_Discount_Amount_Applied__c, PSA_Discount_Eligible_Billings_To_Date__c
                From PSA_Account_Discount__c
                Where PSA_Discount_Active__c = true
            ]);
        System.Debug('BR 13: Account Discount Map:' + accountDiscountMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Account Discount Map', String.valueOf(accountDiscountMap), (List<SObject>)accountDiscountMap.values());

        //Populate a map of un-released ad-hoc Misc. Adjustments related to Services for each billing Event
        AggregateResult[] unReleasedMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_MINIMUM_HOURS, :BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT)
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 13: Un-released Misc. Adjs. List:' + unReleasedMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Un-released Misc. Adjs. List', String.valueOf(unReleasedMiscAdjs), (List<SObject>)unReleasedMiscAdjs);

        Map<Id, Decimal> unReleasedMiscAdjsMap = new Map<Id, Decimal>();
        if (unReleasedMiscAdjs != null && unReleasedMiscAdjs.size() > 0) {
            for (AggregateResult ar : unReleasedMiscAdjs) {
                unReleasedMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
            }
        }

        //Populate a map of un-released Holdback Release Billing Event Items related to Services for each billing Event
        Map<Id, pse__Billing_Event_Item__c> holdbackReleaseBillEventItemMap = new Map<Id, pse__Billing_Event_Item__c>();
        List<pse__Billing_Event_Item__c> holdbackReleaseBillEventItems =
            [Select pse__Billing_Event__c, pse__Amount__c, pse__Miscellaneous_Adjustment__r.PSA_BR_Eligible_Discount_Amount__c,
                    pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, pse__Billing_Event__r.CurrencyISOCode
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c = :accountDiscountBillingEventsMap.keySet()
                And pse__Miscellaneous_Adjustment__c != null
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = true
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c = :BILLING_TYPE_HOLDBACK_RELEASE
            ];
        if (holdbackReleaseBillEventItems != null && holdbackReleaseBillEventItems.size() > 0) {
            for (pse__Billing_Event_Item__c bei : holdbackReleaseBillEventItems) {
                holdbackReleaseBillEventItemMap.put(bei.pse__Billing_Event__c, bei);
            }
        }
        System.debug('BR 13: Unreleased Holdback Release BE Item Map: ' + holdbackReleaseBillEventItemMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Unreleased Holdback Release BE Item Map', String.valueOf(holdbackReleaseBillEventItemMap), null);

        //Create variables used to process all of the inputs and billing rule values
        // More variables are used than are really needed, but "extras" have been included
        // for the sake of being able to follow the logic in the code more easily
        TimecardSummaryByKeyAndBillingLevel priorTimecardSummary;
        TimecardSummaryByKeyAndBillingLevel currentTimecardAmountIncluded;
        PSA_Account_Discount__c accountDiscount;
        Decimal currentTimecardSummaryAmount;
        Decimal priorEligibleBillings;
        Decimal currentMinHoursCharge;
        Decimal currentServicesCapFlatCredit;
        Decimal nonBillingRuleMiscAdjustments;

        //Holdback and Holdback Release variables
        Decimal currentHoldbackCredit;
        Decimal currentHoldbackReleaseCharge;
        pse__Miscellaneous_Adjustment__c holdbackReleaseMiscAdj;
        pse__Miscellaneous_Adjustment__c holdbackMiscAdj;
        pse__Billing_Event_Item__c holdbackReleaseBillEventItem;
        TimecardSummaryByKeyAndBillingLevel currentHoldbackExcluded;
        Decimal currentHoldbackExcludeAmount;

        Decimal totalCurrentServicesAmount;
        Decimal discountPercent;
        Decimal discountCap;
        Decimal totalDiscountAmount;
        Decimal priorDiscountAppliedAmount;
        Decimal currentDiscountEligibleBillingsAmount;
        Decimal currentDiscountAmount;

        pse__Miscellaneous_Adjustment__c miscAdj;
        Decimal miscAdjAmount;
        Date miscAdjDate;

        //Loop through the list of applicable billing events
        for (pse__Billing_Event__c billingEvent : accountDiscountBillingEventsMap.values()) {
            System.debug('BR 13: Billing Event Name: ' + billingEvent.Name);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Billing Event', String.valueOf(billingEvent), null);

            project = projectMasterMap.get(billingEvent.pse__Project__c);
            //Build a set of Account Discount Ids which will be used to refresh the Account Discount "to-date" balances
            accountDiscountIds.add(project.PSA_BR_Account_Discount__c); //Used to refresh Account Discount "To-Date" summary fields

            System.debug('BR 13: Account Discount End Date: ' + project.PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Account Discount End Date', String.valueOf(project.PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c), null);

            //Only process the BR for this billing event if the discount end date is current or in the future relative to the billing period end date
            if (project.PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c == null ||
                    project.PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c >= billingEvent.PSA_Time_Period__r.pse__End_Date__c) {

                //Populate a variable with the current timecard billings
                //currentTimecardSummaryAmount = timecardSummary.TotalAmount;
                currentTimecardAmountIncluded = includedCurrentTimecardSummaryMap.get(billingEvent.Id);
                if (currentTimecardAmountIncluded != null) {
                    currentTimecardSummaryAmount = currentTimecardAmountIncluded.TotalAmount;
                } else {
                    currentTimecardSummaryAmount = 0.0;
                }
                System.debug('BR 13: Current Timecard Amount: ' + currentTimecardSummaryAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Timecard Amount', String.valueOf(currentTimecardSummaryAmount), null);

                //Retrieve any prior timecard billings and populate a variable with the prior timecard billings
                accountDiscount = accountDiscountMap.get(project.PSA_BR_Account_Discount__c);
                priorEligibleBillings = accountDiscount.PSA_Discount_Eligible_Billings_To_Date__c;
                System.debug('BR 13: Prior Eligible Billings: ' + priorEligibleBillings);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Prior Eligible Billings', String.valueOf(priorEligibleBillings), null);

                //Retrieve any "ad-hoc" or non-billing rule created misc adjustments for this billing event
                nonBillingRuleMiscAdjustments = unReleasedMiscAdjsMap.get(billingEvent.Id) != null ? unReleasedMiscAdjsMap.get(billingEvent.Id) : 0.0;
                System.debug('BR 13: Non Billing Rule Misc. Adjs.: ' + nonBillingRuleMiscAdjustments);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Non Billing Rule Misc. Adjs.', String.valueOf(nonBillingRuleMiscAdjustments), null);

                //Retrieve any current misc. adjustments for current billing event including BR 9
                //currentMinHoursCharge = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                //                        BILLING_TYPE_MINIMUM_HOURS);
                //*** updated by cklassen 7/11/15 to handle min. hours misc. adjustsments for projects with no timecards
                currentMinHoursCharge = billingEventMinimumHoursAmountsMap.get(billingEvent.Id) != null ? billingEventMinimumHoursAmountsMap.get(billingEvent.Id) : 0.0;
                System.debug('BR 13: Min. Hours Misc. Adj.: ' + currentMinHoursCharge);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Min. Hours Misc. Adj.', String.valueOf(currentMinHoursCharge), null);

                //Retrieve any current misc. adjustments for current billing event including BR 10
                currentServicesCapFlatCredit = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT);
                System.debug('BR 13: Services Cap Flat Credit: ' + currentServicesCapFlatCredit);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Services Cap Flat Credit', String.valueOf(currentServicesCapFlatCredit), null);

                //Retrieve any holdback amount adjusted to only include applicable billing levels
                //First, get a Holdback Credit amount for the current billing event.
                holdbackMiscAdj = getMiscAdjForBillingEventAndBillingRuleType(miscAdjsToInsert, billingEvent.Id, BILLING_TYPE_HOLDBACK);
                if (holdbackMiscAdj != null) {
                    currentHoldbackCredit = holdbackMiscAdj.pse__Amount__c;
                    System.debug('BR 13: Starting current Holdback Credit: ' + currentHoldbackCredit);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Starting current Holdback Credit', String.valueOf(currentHoldbackCredit), null);

                    //Retrieve the amount of timecards for excluded billing levels
                    currentHoldbackExcluded = excludedCurrentTimecardSummaryMap.get(billingEvent.Id);
                    System.debug('BR 13: Current Holdback Excluded: ' + currentHoldbackExcluded);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Holdback Excluded', String.valueOf(currentHoldbackExcluded), null);

                    currentHoldbackExcludeAmount = currentHoldbackExcluded != null ? currentHoldbackExcluded.TotalAmount : 0.0;
                    currentHoldbackCredit += currentHoldbackExcludeAmount * (project.PSA_BR_Holdback_Pct__c * 0.01);
                    holdbackMiscAdj.PSA_BR_Eligible_Discount_Amount__c = currentHoldbackCredit;
                } else {
                    currentHoldbackCredit = 0.0;
                    currentHoldbackExcludeAmount = 0.0;
                }
                System.debug('BR 13: Final current Holdback Credit: ' + currentHoldbackCredit);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Final current Holdback Credit', String.valueOf(currentHoldbackCredit), null);

                //If there is a holdback credit, update the disc. elig. billings to date value of the related holdback release misc. adj.
                currentHoldbackReleaseCharge = 0;
                Boolean addToMiscAdjsToUpdateList = false;
                if (currentHoldbackCredit != 0) {
                    //Find the holdback release  misc. adj. -- check the miscAdjsToUpdate, then miscAdjsToInsert, then map
                    holdbackReleaseMiscAdj = getHoldBackReleaseMiscAdjForProject(miscAdjsToUpdate, Project.Id);
                    if (holdbackReleaseMiscAdj == null) {
                        holdbackReleaseMiscAdj = getHoldBackReleaseMiscAdjForProject(miscAdjsToInsert, Project.Id);
                        if (holdbackReleaseMiscAdj == null) {
                            holdbackReleaseMiscAdj = holdbackReleaseMiscAdjMasterMap.get(Project.Id);
                            addToMiscAdjsToUpdateList = true;
                        }
                    }
                    if (holdbackReleaseMiscAdj == null) {
                        System.debug('BR 13: Error - Unable to find the Holdback Release Misc. Adj.');
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Error - Unable to find the Holdback Release Misc. Adj.', null, null);
                    } else {
                        System.debug('BR 13: Initial Holdback Release Eligible Discount Amount: ' + holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c);
                        holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c -= currentHoldbackCredit;
                        System.debug('BR 13: Updated Holdback Release Eligible Discount Amount: ' + holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Updated Holdback Release Eligible Discount Amount', String.valueOf(holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c), null);

                        //Check if the holdback release misc. adj. is included in the current billing event.  If so, set
                        // the currentHoldbackReleaseCharge variable
                        holdbackReleaseBillEventItem = holdbackReleaseBillEventItemMap.get(billingEvent.Id);
                        if (holdbackReleaseBillEventItem != null) {
                            //Set the initial holdback release charge amount
                            currentHoldbackReleaseCharge = holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c;
                            System.debug('BR 13: Current Holdback Release Eligible Discount Amount: ' + currentHoldbackReleaseCharge);
                            //Add apex log record
                            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Holdback Release Eligible Discount Amount', String.valueOf(currentHoldbackReleaseCharge), null);
                        }

                        if (addToMiscAdjsToUpdateList == true) {
                            miscAdjsToUpdate.add(holdbackReleaseMiscAdj);
                        }
                    }
                }

                //Sum up all "services" inputs
                totalCurrentServicesAmount = currentTimecardSummaryAmount + nonBillingRuleMiscAdjustments + currentMinHoursCharge +
                                                currentServicesCapFlatCredit + currentHoldbackCredit + currentHoldbackReleaseCharge;
                System.debug('BR 13: Total Current Services Amount: ' + totalCurrentServicesAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Total Current Services Amount', String.valueOf(totalCurrentServicesAmount), null);

                //Retrieve any current "Customer Discount" credits for this Account (discounts for individual projects for the
                // same account will be added on a first come-first served basis)
                Decimal currentCustomerCreditAmount = accountDiscountController.getCurrentAccountDiscountAmount(accountDiscountAmounts,
                        project.PSA_BR_Account_Discount__c);
                System.debug('BR 13: Current customer discount credit amt:' + currentCustomerCreditAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current customer discount credit amt', String.valueOf(currentCustomerCreditAmount), null);

                //Populate the discountPercent variable
                discountPercent = project.PSA_BR_Account_Discount__r.PSA_Discount_Percent__c * 0.01;
                System.debug('BR 13: Discount Percent:' + discountPercent);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Discount Percent', String.valueOf(discountPercent), null);

                //check the cap: PSA_BR_Account_Discount_Cap__c.  If it's null, set it to zero
                discountCap = project.PSA_BR_Account_Discount__r.PSA_Discount_Cap__c != null ? project.PSA_BR_Account_Discount__r.PSA_Discount_Cap__c : 0;
                System.debug('BR 13: Discount Cap:' + discountCap);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Discount Cap', String.valueOf(discountCap), null);

                //Get the discount eligible billings from previous un-released events for the related Account Discount
                currentDiscountEligibleBillingsAmount = accountDiscountController.getCurrentAccountDiscountEligibleBillingsAmount(
                                                            accountDiscountAmounts, project.PSA_BR_Account_Discount__c);
                System.debug('BR 13: Other Discount Eligible Billings:' + currentDiscountEligibleBillingsAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Other Discount Eligible Billings', String.valueOf(currentDiscountEligibleBillingsAmount), null);

                //Get the total account discount amount for current and prior billing events
                totalDiscountAmount = (totalCurrentServicesAmount + priorEligibleBillings + currentDiscountEligibleBillingsAmount) * discountPercent;
                System.debug('BR 13: Total Discount Amount (current services+prior billings+current disc. elig. amount * disc. pct): ' + totalDiscountAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Total Discount Amount (current services+prior billings+current disc. elig. amount * disc. pct)', String.valueOf(totalDiscountAmount), null);

                //Get the previously applied discount amount
                priorDiscountAppliedAmount = project.PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c;
                System.debug('BR 13: Previously Applied Discount Amount: ' + project.PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Previously Applied Discount Amount', String.valueOf(project.PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c), null);

                //Derive the "adjusted" discount amount.  This is the amount that will be used if there is no discount cap,
                // but the "final" discount amount may be different if the discount cap will be exceeded based on the adjusted amount
                Decimal adjustedDiscountAmount = totalDiscountAmount + currentCustomerCreditAmount + priorDiscountAppliedAmount;
                System.debug('BR 13: Adjusted Discount Amount: ' + adjustedDiscountAmount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Adjusted Discount Amount', String.valueOf(adjustedDiscountAmount), null);

                //If there's a discount cap, populate the amount of discount remaining under the cap.  This takes into account
                // and "current" discount amount set by other biilling events using the same account discount
                Decimal remainingDiscount = 0.0;
                if (discountCap > 0) {
                    remainingDiscount = discountCap + currentCustomerCreditAmount + project.PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c;
                }
                System.debug('BR 13: Remaining Discount: ' + remainingDiscount);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Remaining Discount', String.valueOf(remainingDiscount), null);

                //If there is any discount available (possibly not if there is a discount cap), determine what the final
                // discount amount should be ("currentDiscountAmount").  This is what will be used to create the Misc. Adj.
                //First need to initialize the current discount amount to zero and then set it to a different value if applicable
                currentDiscountAmount = 0.00;
                if (remainingDiscount != 0.0) {
                    if (adjustedDiscountAmount > remainingDiscount) {
                        currentDiscountAmount = remainingDiscount;
                        System.debug('BR 13: Current Discount Amount (total exceeded cap): ' + currentDiscountAmount);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total exceeded cap)', String.valueOf(currentDiscountAmount), null);
                    } else {
                        currentDiscountAmount = adjustedDiscountAmount;
                        System.debug('BR 13: Current Discount Amount (total did not exceed cap): ' + currentDiscountAmount);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount (total did not exceed cap)', String.valueOf(currentDiscountAmount), null);
                    }
                } else if (discountCap == 0.0) {
                    //No cap so just set the current discount amount to the initial discount amount
                    currentDiscountAmount = adjustedDiscountAmount;
                    System.debug('BR 13: Current Discount Amount: ' + currentDiscountAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Discount Amount', String.valueOf(currentDiscountAmount), null);
                }
                currentDiscountAmount = (currentDiscountAmount * -1);

                //If the current Discount Amount != 0, do the following:
                // 1. add the current discount amount to a list for potential use by other unreleased billing events
                //      for the same account discount record
                // 2. Add a Customer Discount Misc. Adjustment
                // 3. Add the discount amount to the PSA_Account_Discount_Services_Total__c field on the billing event for
                //      future rollup logic
                if (currentDiscountAmount != 0) {
                    //Add the current amount to a list of Account Discount Amounts
                    accountDiscountAmounts.add(accountDiscountController.addNewAmount(accountDiscountAmounts,
                            project.PSA_BR_Account_Discount__c, currentDiscountAmount, totalCurrentServicesAmount));
                    System.debug('BR 13: Current Account Discount Amounts List: ' + accountDiscountAmounts);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 13: Current Account Discount Amounts List', String.valueOf(accountDiscountAmounts), null);

                    //Set the misc adj amount
                    miscAdjAmount = currentDiscountAmount;

                    //Set the miscAdjDate (same logic as setting the invoice date when releasing a billing event)
                    miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                    //create misc adj;
                    miscAdj = createMiscellaneousAdjustment(BILLING_TYPE_CUSTOMER_DISCOUNT, miscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                            billingEvent.Id, true, BILLING_TYPE_CUSTOMER_DISCOUNT, null, null, null, billingEvent.CurrencyISOCode);
                    //miscAdjsToInsert.add(miscAdj);
                }

                //Update the "Account Discount Services To Date" field on the billing event since it is needed
                // to roll-up to the Project and Account Discount record.  Add the updated billing event to the
                // billingEventsToUpdate list
                billingEvent.PSA_Account_Discount_Services_Total__c = totalCurrentServicesAmount;
                billingEventsToUpdate.add(billingEvent);
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #5: Expenses as Percent of Services
    //  Inputs:
    //      1. Total of timecard splits eligible for Billing (from Billing Event Item lines)
    //      2. Total Credits from BR #9 (Min. Hours)
    //      3. Pct of Services to use for the misc. adj. amount calculation
    //  Steps:
    //      1. Populate a map of total timecard amount for unreleased billing events where BR 5 applies
    //      2. Loop through billing events to determine if a BR 5 misc. adj. needs to be created.
    //          1. Filter the timecard aggregate result list and exclude any amounts for billing levels
    //              that have not been included in the Manage Billing Rules page for this billing rule
    //          2. If any timecards remain, create misc. adjustments for them
    //              1. Retrieve the timecard total amount for the billing event
    //              2. Retrieve a misc. adj. for min. monthly hours if one exists
    //              3. Get the expense percent of services from the project
    //              4. Multiply the expense percent of services by the sum of 2.2.1 and 2.2.2
    //              5. Create the Billing Rule 5 Misc. Adj.
    //
    //  Misc. Adjustment Billing Rule Type: 'Expense Charge - Percent of Services'
    ***********************************************************************************************************/
    public void applyBillingRule_ExpensesFlatPercent() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_ExpensesFlatPercent';

        System.debug('BR 5: running applyBillingRule_ExpensesFlatPercent');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Sum up all timecard hours, days, and amounts by billing level
        AggregateResult[] timecards =
            [Select pse__Timecard_Split__r.pse__Resource__c ResourceId,
                    pse__Billing_Event__c BillingEventId,
                    pse__Project__c ProjectId,
                    pse__Project__r.pse__Account__c AccountId,
                    pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c BillingLevel,
                    Sum(pse__Timecard_Split__r.pse__Total_Hours__c) TotalHours,
                    Sum(pse__Timecard_Split__r.pse__Total_Days_Worked__c) TotalDays,
                    Sum(pse__Timecard_Split__r.PSA_Total_Billable_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Timecard_Split__c != null
                And pse__Timecard_Split__r.pse__Timecard_Header__r.pse__Milestone__r.Name != :OVER_CAP_MILESTONE_NAME
                And pse__Project__r.PSA_BR_Expenses_Billing_Type__c = 'Percent of Services'
                And pse__Project__r.PSA_BR_Billing_Levels_for_Expense_Pct__c != null
                Group by pse__Timecard_Split__r.pse__Resource__c, pse__Billing_Event__c, pse__Project__c,
                    pse__Project__r.pse__Account__c, pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c
                Order by pse__Billing_Event__c
            ];
        System.debug('BR 5: timecards: ' + timecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: timecards', String.valueOf(timecards), null);

        if (timecards.size() > 0) {
            pse__Proj__c project;
            pse__Billing_Event__c billingEvent;

            //First filter the timecards, then roll them up by Billing Event - only include hours worked for assignments
            // with a billing level specified on the project (Billing: Billing Levels for Expense Pct)
            AggregateResult[] filteredTimecards = new AggregateResult[]{};
            for (AggregateResult timecard : timecards) {
                project = projectMasterMap.get((Id)timecard.get('ProjectId'));
                billingEvent = billingEventMasterMap.get((Id)timecard.get('BillingEventId'));
                if (project.PSA_BR_Billing_Levels_for_Expense_Pct__c != null &&
                        project.PSA_BR_Billing_Levels_for_Expense_Pct__c.contains((String)timecard.get('BillingLevel'))) {
                    filteredTimecards.add(timecard);
                }
            }
            System.Debug('BR 5: Filtered Timecards: ' + filteredTimecards);
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Filtered timecards', String.valueOf(filteredTimecards), null);

            //For the filtered results which now only include Billing Levels specified on the Project, create a BR Misc. Adj.
            if (filteredTimecards.size() > 0) {
                List<TimecardSummaryByKeyAndBillingLevel> timecardSummaryList =
                        timecardSummaryController.buildMap(filteredTimecards, 'BillingEventId', false).values();
                for (TimecardSummaryByKeyAndBillingLevel timecardSummary : timecardSummaryList) {
                    project = projectMasterMap.get(timecardSummary.ProjectId);
                    billingEvent = billingEventMasterMap.get(timecardSummary.BillingEventId);
                    System.debug('BR 5: Billing Event Name: ' + billingEvent.Name);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Billing Event', String.valueOf(billingEvent), null);

                    //Retrieve the timecards total for this billing event
                    Decimal timecardAmount = timecardSummary.TotalAmount;
                    System.debug('BR 5: Timecard Amount: ' + timecardAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Timecard Amount', String.valueOf(timecardAmount), null);

                    //Retrieve any current credits from BR 9 - Min. Hours Monthly for this billing event
                    //Decimal currentMinHoursAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id,
                    //    billingEvent.Id, BILLING_TYPE_MINIMUM_HOURS);
                    //*** updated by cklassen 7/11/15 to handle min. hours misc. adjustsments for projects with no timecards
                    Decimal currentMinHoursAmount = billingEventMinimumHoursAmountsMap.get(billingEvent.Id) != null ? billingEventMinimumHoursAmountsMap.get(billingEvent.Id) : 0.0;
                    System.debug('BR 5: Current credit amt (min hours only): ' + currentMinHoursAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Current credit amt (min hours only)', String.valueOf(currentMinHoursAmount), null);

                    //Get the expense percent of services from the project
                    Decimal expensePercentOfServices = (project.PSA_BR_Expense_Pct_of_Services__c * .01);
                    System.debug('BR 5: Project Expense Pct of Services: ' + expensePercentOfServices);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Project Expense Pct of Services', String.valueOf(expensePercentOfServices), null);

                    //create misc adj;
                    Decimal miscAdjAmount = expensePercentOfServices * (timecardAmount + currentMinHoursAmount);
                    System.debug('BR 5: Misc. Adj. Amt: ' + miscAdjAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Misc. Adj. Amt', String.valueOf(miscAdjAmount), null);

                    Date miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);
                    pse__Miscellaneous_Adjustment__c miscAdj =
                        createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES, miscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                            billingEvent.Id, true, BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES, null, null, null, billingEvent.CurrencyISOCode);
                    //miscAdjsToInsert.add(miscAdj);
                    System.debug('BR 5: Misc. Adj. Added: ' + miscAdj);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 5: Misc. Adj. Added', String.valueOf(miscAdj), null);
                }
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #6: Expenses as Flat Amount (based on Days Worked)
    //  Inputs:
    //      1. Total Days worked using Time Date records (from Billing Event Item/TC Split lines)
    //      2. Expense Amount per day (from the related project)
    //  Steps:
    //      1. Populate a map of total timecard amount for unreleased billing events where BR 6 applies
    //      2. Loop through billing events to determine if a BR 6 misc. adj. needs to be created.
    //          1. Filter the timecard aggregate result list and exclude any amounts for billing levels
    //              that have not been included in the Manage Billing Rules page for this billing rule
    //          2. If any timecards remain, create misc. adjustments for each individual resource
    //              1. Retrieve the total days worked for the billing event/resource
    //              2. Get the expense amount per day from the related project (PSA_BR_Expense_Amt_Per_Day__c)
    //              3. Multiply the total days worked by the expense amount per day
    //              4. Create the Billing Rule 6 Misc. Adj(s).
    //
    //  Misc. Adjustment Billing Rule Type: 'Expense Charge - Flat Amount'
    //  Revisions: 2015-10-23  Klassen  Changed from using total days worked on Timecard Splits to total number
    //              of dates worked based on Time Date records
    ***********************************************************************************************************/
    public void applyBillingRule_ExpensesFlatAmount() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_ExpensesFlatAmount';

        System.debug('BR 6: running applyBillingRule_ExpensesFlatAmount');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //*** Replaces original aggregate query that pull total hours worked from all timecards.  This aggregate query
        //      is based on time date records associated with the billing event timecard splits. This is necessary because a resource
        //      may enter more than one timecard per day, but only one day worked should be charged to the project
        AggregateResult[] arTimecardsByDay =
            [Select pse__Timecard__r.pse__Project__r.pse__Account__c AccountId,
                    pse__Timecard__r.pse__Project__c ProjectId,
                    PSA_Timecard_Split__r.pse__Billing_Event_Item__r.pse__Billing_Event__c BillingEventId,
                    pse__Timecard__r.pse__Resource__c ResourceId,
                    pse__Timecard__r.PSA_Billing_Level__c BillingLevel,
                    pse__Date__c TCDate,
                    sum(pse__Hours__c) TotalHours,
                    sum(pse__Hours__c) TotalAmount
                from pse__time_date__c
                where psa_timecard_split__c in (
                    select pse__timecard_split__c
                                From pse__Billing_Event_Item__c
                                Where pse__Billing_Event__c =:billingEventMasterMap.keySet()
                                And pse__Timecard_Split__c != null
                                And pse__Project__r.PSA_BR_Expenses_Billing_Type__c = 'Flat Amount per Day'
                                And pse__Project__r.PSA_BR_Billing_Levels_for_Expense_Amt__c != null
                )
                group by pse__Timecard__r.pse__Project__r.pse__Account__c, pse__Timecard__r.pse__Project__c,
                    PSA_Timecard_Split__r.pse__Billing_Event_Item__r.pse__Billing_Event__c,
                    pse__Timecard__r.pse__Resource__c, pse__Timecard__r.PSA_Billing_Level__c, pse__Date__c
                having sum(pse__Hours__c) > 0
                order by pse__Timecard__r.pse__Project__r.pse__Account__c, pse__Timecard__r.pse__Project__c,
                    PSA_Timecard_Split__r.pse__Billing_Event_Item__r.pse__Billing_Event__c,
                    pse__Timecard__r.pse__Resource__c
            ];
        System.debug('BR 6: Timecards By Day: ' + arTimecardsByDay);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: timecards by day', String.valueOf(arTimecardsByDay), null);

        if (arTimecardsByDay.size() > 0) {
            pse__Proj__c project;
            pse__Billing_Event__c billingEvent;

            //First filter the results, then roll them up by Billing Event - only include days worked for assignments
            // with a billing level specified on the project (Billing: Billing Levels for Expense Amt)
            AggregateResult[] arFilteredTimecards = new AggregateResult[]{};
            for (AggregateResult result : arTimecardsByDay) {
                project = projectMasterMap.get((Id)result.get('ProjectId'));
                //billingEvent = billingEventMasterMap.get((Id)result.get('BillingEventId'));
                if (project.PSA_BR_Billing_Levels_for_Expense_Amt__c != null &&
                        project.PSA_BR_Billing_Levels_for_Expense_Amt__c.contains((String)result.get('BillingLevel'))) {
                    arFilteredTimecards.add(result);
                }
            }
            System.debug('BR 6: Filtered Timecards: ' + arFilteredTimecards);
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Filtered Timecards', String.valueOf(arFilteredTimecards), null);

            //For the filtered results which now only include Billing Levels specified on the Project, create a BR Misc. Adj.
            if (arFilteredTimecards.size() > 0) {
                Decimal totalDaysWorked;
                Decimal expenseAmountPerDay;
                Decimal miscAdjAmount;
                Id resourceId;
                Date miscAdjDate;

                List<TimecardSummaryByKeyAndBillingLevel> timecardSummaryList =
                        timecardSummaryController.buildMap(arFilteredTimecards, 'BillingEventAndResourceId', true).values();
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Timecard Summary List', String.valueOf(timecardSummaryList), null);

                for (TimecardSummaryByKeyAndBillingLevel timecardSummary : timecardSummaryList) {
                    project = projectMasterMap.get(timecardSummary.ProjectId);
                    billingEvent = billingEventMasterMap.get(timecardSummary.BillingEventId);

                    //Retrieve the Resource Name from the Timecard Summary class records
                    resourceId = timecardSummary.ResourceId;
                    System.debug('BR 6: Resource Id: ' + resourceId);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Resource Id', String.valueOf(resourceId), null);

                    //Retrieve the total days worked from the Timecard Summary class records
                    totalDaysWorked = timecardSummary.TotalDaysWorked;
                    System.debug('BR 6: Total Days Worked: ' + totalDaysWorked);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Total Days Worked', String.valueOf(totalDaysWorked), null);

                    //Retrieve the expense amount per day from the related project
                    expenseAmountPerDay = project.PSA_BR_Expense_Amt_Per_Day__c;
                    System.debug('BR 6: Project Exp. Amt Per Day: ' + project.PSA_BR_Expense_Amt_Per_Day__c);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Project Exp. Amt Per Day', String.valueOf(project.PSA_BR_Expense_Amt_Per_Day__c), null);

                    //Set the misc. adj. amount - daily rate multipled by the days worked
                    miscAdjAmount = expenseAmountPerDay * totalDaysWorked;
                    System.debug('BR 6: Misc. Adj. Amount: ' + miscAdjAmount);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Misc. Adj. Amount', String.valueOf(miscAdjAmount), null);

                    //Create a misc. adj. if the amount != zero
                    if (miscAdjAmount != 0) {
                        //Set the misc. adj. date to the invoice date
                        miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);

                        //create misc adj;
                        pse__Miscellaneous_Adjustment__c miscAdj =
                            createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_FLAT_AMOUNT, miscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                                billingEvent.Id, true, BILLING_TYPE_EXPENSE_FLAT_AMOUNT, expenseAmountPerDay, totalDaysWorked, resourceId, billingEvent.CurrencyISOCode);
                        //miscAdjsToInsert.add(miscAdj);
                        System.debug('BR 6: Misc. Adj.: ' + miscAdj);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 6: Misc. Adj', String.valueOf(miscAdj), null);
                    }
                }
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #7: Expense Cap - Pct of Services
    //  Inputs:
    //     1. All "current" expenses and expense-related milestones and misc. adjs.
    //     2. Prior expenses to date
    //     3. All current timecards and services-related milestones and misc. adjs.
    //     4. Prior services to date, including discount applied amounts
    //     5. Billing Rule settings such as pct cap
    //  Steps:
    //      1. Get total Expense billing items grouped by Billing Event
    //      2. Get total Expense-related Milestones grouped by Billing Event
    //      3. Get total non-billing rule ("ad hoc") Miscellaneous Adjustments related to Expenses
    //          This includes the following Billing Rule Types:
    //              'Expense Charge - Percent of Services'
    //              'Expense Charge - Flat Amount'
    //              'Expenses - Fixed Amount'
    //              'Expenses - As Incurred'
    //              'Expense Credit - Cap Percent of Services'
    //              'Expense Credit - Cap Flat Amount'
    //      4. Get total Timecard Split billing items grouped by Billing Event
    //      5. NOT APPLICABLE Get total Services-related Milestones grouped by Billing Event
    //      6. Get total non-billing rule ("ad hoc") Miscellaneous Adjustments related to Services.
    //          This includes the following Billing Rule Types:
    //              'Services - Time and Materials'
    //              'Services Charge - Minimum Hours'
    //              'Services Credit - Cap Flat Amount'
    //              'Services Credit - Project Discount'
    //              'Services Credit - Customer Discount'
    //      7. Loop through all applicable Billing Events and perform the following tasks:
    //          1. Retrieve the total expenses incurred amount from the map populated in step 1
    //          2. Retrieve the total expense milestones from the map populated in step 2
    //          3. Retrieve the total ad-hoc misc. adjustment amount from the map populated in step 3
    //          4. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 5:
    //              "Expense Pct of Services"
    //          5. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 6:
    //              "Expense Flat Amount"
    //          6. Get the total current Expenses billings by summing up the results from 7.1, 7.2, 7.3, 7.4, and 7.5
    //          7. Retrieve the total timecards amount from the map populated in step 4
    //          8. NOT APPLICABLE Retrieve the total milestones amount from the map populated in step 5
    //          9. Retrieve the total ad-hoc misc. adjustment amount from the map populated in step 6
    //          10. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 9:
    //                "Services Charge - Minimum Hours"
    //          11. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 10:
    //                "Services Credit - Cap Flat Amount"
    //          12. Retrieve the total amount for any Misc. Adjs. for the current project from Billing Rule 12:
    //                "Services Credit - Project Discount"
    //          13. Retrieve the total amount for any Misc. Adjs. for the current account from Billing Rule 13:
    //                "Services Credit - Customer Discount"
    //          14. Get the total current Services billings by summing up the results from 7.7, 7.8, 7.9, 7.10, 7.11, 7.12, 7.13
    //          15. Get the Project's prior expense billings ("PSA_BR_Expense_Total_To_Date__c")
    //          16. Get the Project's prior services billings ("PSA_BR_Services_Total_To_Date__c")
    //          17. Get the Project's prior discount applied amount ("PSA_BR_Discount_Applied_To_Date__c")
    //          18. Get the total current and prior expense billings
    //          19. Get the total current and prior services billings, including any prior discount applied amount
    //          20. Get any current expense credits for other billing events for the same project
    //          21. Get the Amount of expense credits applied to date on the related project ("PSA_BR_Expense_Credits_Applied_To_Date__c")
    //          22. Get the total expense credits (current and prior)
    //          23. Get the Expense Pct Cap from the related project ("PSA_BR_Expense_Cap_Pct__c")
    //          24. Set the total cap amount for the project based on the Expense Cap Pct (divided by 100) multiplied
    //                by the total current and prior services billings.
    //          25. Get an adjusted cap amount
    //          26. If the total expenses > adjusted cap amount, create a misc. adj. credit for the difference
    //
    //  Misc. Adjustment Billing Rule Type: 'Expense Credit - Cap Percent of Services'
    ***********************************************************************************************************/
    public void applyBillingRule_ExpensesCappedAsPercent() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_ExpensesCappedAsPercent';

        System.debug('BR 7: running applyBillingRule_ExpensesCappedAsPercent');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Initialize a set of billing event ids to apply this billing rule to
        Set<Id> billingEventIds = new Set<Id>();
        Map<String, TimecardSummaryByKeyAndBillingLevel> timecardSummaryMap;

        //Populate a map of un-released expenses ("as incurred")
        AggregateResult[] arExpenseItems =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Expense__c != null
                And pse__Project__r.PSA_BR_Expense_Cap_Pct_Applies__c = true
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 7: Expense Items List: ' + arExpenseItems);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Expense Items List', String.valueOf(arExpenseItems), null);

        Map<Id, Decimal> expenseItemsMap = new Map<Id, Decimal>();
        if (arExpenseItems != null && arExpenseItems.size() > 0) {
            for (AggregateResult ar : arExpenseItems) {
                expenseItemsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Populate a map of un-released Milestones ("Billable Expenses - Fixed")
        AggregateResult[] arExpenseMilestones =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Milestone__c != null
                And pse__Milestone__r.PSA_Milestone_Type__c = 'Billable Expenses - Fixed'
                And pse__Project__r.PSA_BR_Expense_Cap_Pct_Applies__c = true
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 7: Expense Milestones List: ' + arExpenseMilestones);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Expense Milestones List', String.valueOf(arExpenseMilestones), null);

        Map<Id, Decimal> expenseMilestonesMap = new Map<Id, Decimal>();
        if (arExpenseMilestones != null && arExpenseMilestones.size() > 0) {
            for (AggregateResult ar : arExpenseMilestones) {
                expenseMilestonesMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Populate a map of un-released Misc. Adjs. related to Expenses (manually entered)
        AggregateResult[] arExpenseNonBillingMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Expense_Cap_Pct_Applies__c = true
                And pse__Miscellaneous_Adjustment__c != null
                and pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                and pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES, :BILLING_TYPE_EXPENSE_FLAT_AMOUNT, :BILLING_TYPE_EXPENSE_FIXED_AMOUNT,
                        :BILLING_TYPE_EXPENSE_AS_INCURRED, :BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES, :BILLING_TYPE_EXPENSE_CAP_FLAT_AMOUNT
                    )
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 7: Expense Non-Billing Rule Misc. Adj. List: ' + arExpenseNonBillingMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Expense Non-Billing Rule Misc. Adj. List', String.valueOf(arExpenseNonBillingMiscAdjs), null);

        Map<Id, Decimal> expenseNonBillingMiscAdjsMap = new Map<Id, Decimal>();
        if (arExpenseNonBillingMiscAdjs != null && arExpenseNonBillingMiscAdjs.size() > 0) {
            for (AggregateResult ar : arExpenseNonBillingMiscAdjs) {
                expenseNonBillingMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Populate a map of un-released timecards summarized for each billing event
        AggregateResult[] arTimecards = getTimecardsAggregateResults(projectMasterMap.keySet(), 'PSA_BR_Expense_Cap_Pct_Applies__c');
        System.debug('BR 7: Services - Timecards List: ' + arTimecards);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Services - Timecards List', String.valueOf(arTimecards), null);

        Map<Id, Decimal> servicesTimecardsMap = new Map<Id, Decimal>();
        if (arTimecards != null && arTimecards.size() > 0) {
            timecardSummaryMap = timecardSummaryController.buildMap(arTimecards, 'BillingEventId', false);
            for (TimecardSummaryByKeyAndBillingLevel ts : timecardSummaryMap.values()) {
                billingEventIds.add(ts.BillingEventId);
            }
        }

        /* Excluded b/c not in Design doc... doesn't appear this would apply but will leave if this
            changes in the future
        //Populate a map of un-released Milestones ("Billable Services - Fixed")
        AggregateResult[] arServicesMilestones =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Milestone__c != null
                And pse__Milestone__r.PSA_Milestone_Type__c = 'Billable Services - Fixed'
                And pse__Project__r.PSA_BR_Expense_Cap_Pct_Applies__c = true
                Group by pse__Billing_Event__c
            ];
        System.debug('Expense Milestones List:'+arServicesMilestones);
        Map<Id, Decimal> servicesMilestonesMap = new Map<Id, Decimal>();
        if (arServicesMilestones != null && arServicesMilestones.size() > 0) {
            for (AggregateResult ar : arServicesMilestones) {
                servicesMilestonesMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }
        */

        //Populate a map of un-released Misc. Adjs. related to Services (manually entered)
        AggregateResult[] arServicesNonBillingMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Expense_Cap_Pct_Applies__c = true
                And pse__Miscellaneous_Adjustment__c != null
                and pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                and pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_TIME_AND_MATERIALS, :BILLING_TYPE_MINIMUM_HOURS,
                        :BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT, :BILLING_TYPE_PROJECT_DISCOUNT, :BILLING_TYPE_CUSTOMER_DISCOUNT
                    )
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 7: Services Non-Billing Misc. Adj. List: ' + arServicesNonBillingMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Services Non-Billing Misc. Adj. List', String.valueOf(arServicesNonBillingMiscAdjs), null);

        Map<Id, Decimal> servicesNonBillingMiscAdjsMap = new Map<Id, Decimal>();
        if (arServicesNonBillingMiscAdjs != null && arServicesNonBillingMiscAdjs.size() > 0) {
            for (AggregateResult ar : arServicesNonBillingMiscAdjs) {
                servicesNonBillingMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Define variables used for the various roll-up calculations
        pse__Billing_Event__c billingEvent;
        pse__Proj__c project;
        TimecardSummaryByKeyAndBillingLevel timecardSummary;
        //Current expenses
        Decimal currentExpenseItemsAmount;
        Decimal currentExpenseMilestonesAmount;
        Decimal currentExpenseNonBillingMiscAdjsAmount;
        Decimal currentExpensePctOfServicesAmount;
        Decimal currentExpenseFlatAmount;
        Decimal totalCurrentExpenseAmount;
        //Current Services
        Decimal currentServicesItemsAmount;
        //Decimal currentServicesMilestones;
        Decimal currentServicesNonBillingMiscAdjsAmount;
        Decimal currentServicesMinHoursAmount;
        Decimal currentServicesFlatCapAmount;
        Decimal currentProjectDiscountAmount;
        Decimal currentAccountDiscountAmount;
        Decimal totalCurrentServicesAmount;
        //Prior billed Expenses and Services and prior credits for Expenses and Services
        Decimal priorExpenseBillingsAmount;
        Decimal priorServicesBillingsAmount;
        Decimal priorDiscountApplied;
        Decimal priorExpenseCreditsAmount;
        Decimal currentExpenseCreditsAmount;
        Decimal totalExpenseCreditsAmount;
        //Project criteria
        Decimal expenseCapPercent;

        Decimal totalCurrentAndPriorExpensesAmount;
        Decimal totalCurrentAndPriorServicesAmount;
        Decimal totalCapAmount;
        Decimal adjustedCapAmount;
        Decimal totalExpenseMiscAdjAmount;

        //Loop through each billing event rolling up current and prior expenses and services and applying a misc. adj. credit if needed
        for (Id billingEventId : billingEventIds) {
            //Get the current billing event and project records
            billingEvent = billingEventMasterMap.get(billingEventId);
            project = projectMasterMap.get(billingEvent.pse__Project__c);
            System.debug('BR 7: Billing Event Name: ' + billingEvent.Name);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Billing Event', String.valueOf(billingEvent), null);

            //Retrieve the expense items billed in this billing event ("as incurred")
            currentExpenseItemsAmount = expenseItemsMap.get(billingEvent.Id) != null ? expenseItemsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Current expense items: ' + currentExpenseItemsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current expense items', String.valueOf(currentExpenseItemsAmount), null);

            //Retrieve the summarized expense milestones for this billing event
            currentExpenseMilestonesAmount = expenseMilestonesMap.get(billingEvent.Id) != null ?
                                                expenseMilestonesMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Current expense milestones: ' + currentExpenseMilestonesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current expense milestones', String.valueOf(currentExpenseMilestonesAmount), null);

            //Retrieve the summarized expense non-billing Misc. Adjs. for this billing event
            currentExpenseNonBillingMiscAdjsAmount = expenseNonBillingMiscAdjsMap.get(billingEvent.Id) != null ?
                                                expenseNonBillingMiscAdjsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Current expense non billing Misc. Adjs.: ' + currentExpenseNonBillingMiscAdjsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current expense non billing Misc. Adjs.', String.valueOf(currentExpenseNonBillingMiscAdjsAmount), null);

            //Current Misc. Adj. for Expense Pct of Services
            currentExpensePctOfServicesAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                    BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES);
            System.debug('BR 7: Misc. Adj: Expense Pct of Services: ' + currentExpensePctOfServicesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Misc. Adj: Expense Pct of Services', String.valueOf(currentExpensePctOfServicesAmount), null);

            //Current Misc. Adj. for Expense Flat Amount
            currentExpenseFlatAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                    BILLING_TYPE_EXPENSE_FLAT_AMOUNT);
            System.debug('BR 7: Misc. Adj: Expense Charge - Flat Amount: ' + currentExpenseFlatAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Misc. Adj: Expense Charge - Flat Amount', String.valueOf(currentExpenseFlatAmount), null);

            //Set the total current expenses amount
            totalCurrentExpenseAmount = currentExpenseItemsAmount + currentExpenseMilestonesAmount + currentExpenseNonBillingMiscAdjsAmount +
                                            currentExpensePctOfServicesAmount + currentExpenseFlatAmount;
            System.debug('BR 7: Total current Expenses Amount: ' + totalCurrentExpenseAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total current Expenses Amount', String.valueOf(totalCurrentExpenseAmount), null);

            //Retrieve the timecards billed in this billing event
//            currentServicesItemsAmount = servicesTimecardsMap.get(billingEvent.Id) != null ? servicesTimecardsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Billing Event Id: ' + billingEvent.Id);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Billing Event', String.valueOf(billingEvent), null);
            System.debug('BR 7: tc summary map: ' + timecardSummaryMap);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: tc summary map', String.valueOf(timecardSummaryMap), null);

            //*** added by cklassen to fix a bug if no timecards exist (meaning the timecardSummaryMap is null)
            if (timecardSummaryMap != null) {
                timecardSummary = timecardSummaryMap.get(billingEvent.Id);
            } else {
                timecardSummary = null;
            }
            currentServicesItemsAmount = timecardSummary != null ? timecardSummary.TotalAmount : 0.0;
            System.debug('BR 7: Current timecards: ' + currentServicesItemsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current timecards', String.valueOf(currentServicesItemsAmount), null);

            //Retrieve the summarized services non-billing rule Misc. Adjs. for this billing event
            currentServicesNonBillingMiscAdjsAmount = servicesNonBillingMiscAdjsMap.get(billingEvent.Id) != null ?
                                                        servicesNonBillingMiscAdjsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Current services non billing Misc. Adjs.: ' + currentServicesNonBillingMiscAdjsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current services non billing Misc. Adjs.', String.valueOf(currentServicesNonBillingMiscAdjsAmount), null);

            //Current Misc. Adj. for Min. Hours Amount
            //currentServicesMinHoursAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
            //                                    BILLING_TYPE_MINIMUM_HOURS);
            //*** updated by cklassen 7/11/15 to handle min. hours misc. adjustsments for projects with no timecards
            currentServicesMinHoursAmount = billingEventMinimumHoursAmountsMap.get(billingEvent.Id) != null ? billingEventMinimumHoursAmountsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 7: Current BR 9 Misc. Adj: Services Charge - Minimum Hours: ' + currentServicesMinHoursAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current BR 9 Misc. Adj: Services Charge - Minimum Hours', String.valueOf(currentServicesMinHoursAmount), null);

            //Current Misc. Adj. for Services Cap Flat Amount
            currentServicesFlatCapAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                BILLING_TYPE_SERVICES_CAP_FLAT_AMOUNT);
            System.debug('BR 7: Current BR 10 Misc. Adj: Services Credit - Cap Flat Amount: ' + currentServicesFlatCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current BR 10 Misc. Adj: Services Credit - Cap Flat Amount', String.valueOf(currentServicesFlatCapAmount), null);

            //Current Misc. Adj(s). for Project Discounts (include other un-released billing events for the same project)
            // *** No project discounts will be included in the initial implementation, but leaving this for future enhancements
            currentProjectDiscountAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                BILLING_TYPE_PROJECT_DISCOUNT);
            System.debug('BR 7: Current BR 12 Misc. Adj (project-level): Services Credit - Project Discount: ' + currentProjectDiscountAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current BR 12 Misc. Adj (project-level): Services Credit - Project Discount', String.valueOf(currentProjectDiscountAmount), null);

            //Current Misc. Adj(s). for Account-level Discounts (include other un-released billing events for the same account)
            currentAccountDiscountAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id,
                                                BILLING_TYPE_CUSTOMER_DISCOUNT);
            System.debug('BR 7: Current BR 13 Misc. Adj: Services Credit - Customer Discount: ' + currentAccountDiscountAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current BR 13 Misc. Adj: Services Credit - Customer Discount', String.valueOf(currentAccountDiscountAmount), null);

            //Set the total current services amount
            totalCurrentServicesAmount = currentServicesItemsAmount + currentServicesNonBillingMiscAdjsAmount + currentServicesMinHoursAmount +
                                            currentServicesFlatCapAmount + currentProjectDiscountAmount + currentAccountDiscountAmount;
            System.debug('BR 7: Total current Services Amount: ' + totalCurrentServicesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total current Services Amount', String.valueOf(totalCurrentServicesAmount), null);

            //Retrieve the prior expense amount billed
            priorExpenseBillingsAmount = project.PSA_BR_Expense_Total_To_Date__c;
            System.debug('BR 7: Prior expense billings: ' + priorExpenseBillingsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Prior expense billings', String.valueOf(priorExpenseBillingsAmount), null);

            //Retrieve the prior services amount billed
            priorServicesBillingsAmount = project.PSA_BR_Services_Total_To_Date__c;
            System.debug('BR 7: Prior services billings: ' + priorServicesBillingsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Prior services billings', String.valueOf(priorServicesBillingsAmount), null);

            //Get the prior amount of discount applied to the project
            priorDiscountApplied = project.PSA_BR_Discount_Applied_To_Date__c;
            System.debug('BR 7: Prior discount applied to the project: ' + priorDiscountApplied);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Prior discount applied to the project', String.valueOf(priorDiscountApplied), null);

            //Set the total current and prior expenses amount
            totalCurrentAndPriorExpensesAmount = totalCurrentExpenseAmount + priorExpenseBillingsAmount;
            System.debug('BR 7: Total current and prior expense billings: ' + totalCurrentAndPriorExpensesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total current and prior expense billings', String.valueOf(totalCurrentAndPriorExpensesAmount), null);

            //Set the total current and prior services amount, including the prior discount applied amount
            totalCurrentAndPriorServicesAmount = totalCurrentServicesAmount + priorServicesBillingsAmount + priorDiscountApplied;
            System.debug('BR 7: Total current and prior services billings, including prior disc. applied amt: ' + totalCurrentAndPriorServicesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total current and prior services billings, including prior disc. applied amt', String.valueOf(totalCurrentAndPriorServicesAmount), null);

            //Get "current" expense credit amounts from other billing events for the same project
            currentExpenseCreditsAmount = getCurrentCreditAmountForProjectAndBillingRuleType(miscAdjsToInsert, project.Id,
                                            BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES);
            System.debug('BR 7: Current expenses credits (other billing events for same project): ' + currentExpenseCreditsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Current expenses credits (other billing events for same project)', String.valueOf(currentExpenseCreditsAmount), null);

            //Retrieve the prior expenses credits applied to date
            priorExpenseCreditsAmount = project.PSA_BR_Expense_Credits_Applied_To_Date__c;
            System.debug('BR 7: Prior expenses credits: ' + priorExpenseCreditsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Prior expenses credits', String.valueOf(priorExpenseCreditsAmount), null);

            //Set the total expense credits amount - current billing events from same project and prior billing events
            totalExpenseCreditsAmount = currentExpenseCreditsAmount + priorExpenseCreditsAmount;
            System.debug('BR 7: Total (current and prior) expenses credits: ' + totalExpenseCreditsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total (current and prior) expenses credits', String.valueOf(totalExpenseCreditsAmount), null);

            //Retrieve the expense cap percent from the project
            expenseCapPercent = project.PSA_BR_Expense_Cap_Pct__c;
            System.debug('BR 7: Expense cap pct: ' + expenseCapPercent);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Expense cap pct', String.valueOf(expenseCapPercent), null);

            //Set the total cap amount
            totalCapAmount = ((expenseCapPercent * 0.01) * totalCurrentAndPriorServicesAmount);
            System.debug('BR 7: Total cap amount: ' + totalCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Total cap amount', String.valueOf(totalCapAmount), null);

            //Set the adjusted cap amount
            adjustedCapAmount = totalCapAmount - totalExpenseCreditsAmount;
            System.debug('BR 7: Adjusted cap amount: ' + adjustedCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Adjusted cap amount', String.valueOf(adjustedCapAmount), null);

            //If the total expenses > adjusted cap amount, create a misc. adj. credit for the difference
            if (totalCurrentAndPriorExpensesAmount > adjustedCapAmount) {
                totalExpenseMiscAdjAmount = adjustedCapAmount - totalCurrentAndPriorExpensesAmount ;
            } else {
                totalExpenseMiscAdjAmount = 0;
            }
            System.debug('BR 7: Final misc adj amount: ' + totalExpenseMiscAdjAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: Final misc adj amount', String.valueOf(totalExpenseMiscAdjAmount), null);

            //If the expense credit != 0, create a new misc. adj.
            if (totalExpenseMiscAdjAmount != 0) {
                //Need to create an expense credit for cap pct of services misc. adj.
                Date miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);
                pse__Miscellaneous_Adjustment__c miscAdj =
                    createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES, totalExpenseMiscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                        billingEvent.Id, true, BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES, null, null, null, billingEvent.CurrencyISOCode);
                //miscAdjsToInsert.add(miscAdj);
                System.debug('BR 7: MiscAdjToInsert: ' + miscAdj);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 7: MiscAdjToInsert', String.valueOf(miscAdj), null);
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #8: Expense Cap Flat Amount
    //  Inputs:
    //     1. All "current" expenses and expense-related milestones and misc. adjs.
    //     2. Prior expenses to date
    //     3. Billing Rule settings, including the expense cap amount
    //  Steps:
    //      1. Get total Expense billing items grouped by Billing Event
    //      2. Get total Expense-related Milestones grouped by Billing Event
    //      3. Get total non-billing rule ("ad hoc") Miscellaneous Adjustments related to Expenses
    //          This includes the following Billing Rule Types:
    //              'Expense Charge - Percent of Services'
    //              'Expense Charge - Flat Amount'
    //              'Expenses - Fixed Amount'
    //              'Expenses - As Incurred'
    //              'Expense Credit - Cap Percent of Services'
    //              'Expense Credit - Cap Flat Amount'
    //      4. Loop through all applicable Billing Events and perform the following tasks:
    //          1. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 5:
    //              "Expense Pct of Services"
    //          2. Retrieve the total amount for any Misc. Adjs. for the current billing event from Billing Rule 6:
    //              "Expense Flat Amount"
    //
    //  Misc. Adjustment Billing Rule Type: 'Expense Credit - Cap Flat Amount'
    ***********************************************************************************************************/
    public void applyBillingRule_ExpensesCapFlatAmount() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_ExpensesCapFlatAmount';

        System.debug('BR 8: running applyBillingRule_ExpensesCapFlatAmount');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        //Initialize a set of billing event ids to apply this billing rule to
        Set<Id> billingEventIds = new Set<Id>();

        //Populate a map of un-released expenses ("as incurred")
        AggregateResult[] arExpenseItems =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Expense__c != null
                And pse__Project__r.PSA_BR_Expense_Cap_Flat_Applies__c = true
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 8: Expense Items List: ' + arExpenseItems);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Expense Items List', String.valueOf(arExpenseItems), null);

        Map<Id, Decimal> expenseItemsMap = new Map<Id, Decimal>();
        if (arExpenseItems != null && arExpenseItems.size() > 0) {
            for (AggregateResult ar : arExpenseItems) {
                expenseItemsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Populate a map of un-released Milestones ("Billable Expenses - Fixed")
        AggregateResult[] arExpenseMilestones =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Milestone__c != null
                And pse__Milestone__r.PSA_Milestone_Type__c = 'Billable Expenses - Fixed'
                And pse__Project__r.PSA_BR_Expense_Cap_Flat_Applies__c = true
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 8: Expense Milestones List: ' + arExpenseMilestones);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Expense Milestones List', String.valueOf(arExpenseMilestones), null);

        Map<Id, Decimal> expenseMilestonesMap = new Map<Id, Decimal>();
        if (arExpenseMilestones != null && arExpenseMilestones.size() > 0) {
            for (AggregateResult ar : arExpenseMilestones) {
                expenseMilestonesMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Populate a map of un-released Misc. Adjs. related to Expenses (manually entered)
        AggregateResult[] arExpenseNonBillingMiscAdjs =
            [Select pse__Billing_Event__c BillingEventId,
                    Sum(PSA_Amount_Number__c) TotalAmount
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Project__r.PSA_BR_Expense_Cap_Flat_Applies__c = true
                And pse__Miscellaneous_Adjustment__c != null
                and pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = false
                and pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c IN
                    (:BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES, :BILLING_TYPE_EXPENSE_FLAT_AMOUNT, :BILLING_TYPE_EXPENSE_FIXED_AMOUNT,
                        :BILLING_TYPE_EXPENSE_AS_INCURRED, :BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES, :BILLING_TYPE_EXPENSE_CAP_FLAT_AMOUNT
                    )
                Group by pse__Billing_Event__c
            ];
        System.debug('BR 8: Expense Non-Billing Rule Misc. Adj. List: ' + arExpenseNonBillingMiscAdjs);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Expense Non-Billing Rule Misc. Adj. List', String.valueOf(arExpenseNonBillingMiscAdjs), null);

        Map<Id, Decimal> expenseNonBillingMiscAdjsMap = new Map<Id, Decimal>();
        if (arExpenseNonBillingMiscAdjs != null && arExpenseNonBillingMiscAdjs.size() > 0) {
            for (AggregateResult ar : arExpenseNonBillingMiscAdjs) {
                expenseNonBillingMiscAdjsMap.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
                billingEventIds.add((Id)ar.get('BillingEventId'));
            }
        }

        //Define variables used for the various roll-up calculations
        pse__Billing_Event__c billingEvent;
        pse__Proj__c project;
        //Current expenses
        Decimal currentExpenseItemsAmount;
        Decimal currentExpenseMilestonesAmount;
        Decimal currentExpenseNonBillingMiscAdjsAmount;
        Decimal currentExpensePctOfServicesAmount;
        Decimal currentExpenseFlatAmount;
        Decimal currentExpensePctOfServicesCapAmount;
        Decimal totalCurrentExpenseAmount;
        //Prior billed Expenses and prior credits for Expenses
        Decimal priorExpenseBillingsAmount;
        Decimal priorExpenseCreditsAmount;
        //Project criteria
        Decimal expenseCapAmount;

        Decimal totalCurrentAndPriorExpensesAmount;
        Decimal adjustedCapAmount;
        Decimal totalExpenseMiscAdjAmount;

        for (Id billingEventId : billingEventIds) {
            //Get the current billing event and project
            billingEvent = billingEventMasterMap.get(billingEventId);
            project = projectMasterMap.get(billingEvent.pse__Project__c);
            System.debug('BR 8: Billing Event Name: ' + billingEvent.Name);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Billing Event', String.valueOf(billingEvent), null);

            //Retrieve the expense items billed in this billing event ("as incurred")
            currentExpenseItemsAmount = expenseItemsMap.get(billingEvent.Id) != null ? expenseItemsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 8: Current expense items: ' + currentExpenseItemsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Current expense items', String.valueOf(currentExpenseItemsAmount), null);

            //Retrieve the summarized expense milestones for this billing event
            currentExpenseMilestonesAmount = expenseMilestonesMap.get(billingEvent.Id) != null ? expenseMilestonesMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 8: Current expense milestones: ' + currentExpenseMilestonesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Current expense milestones', String.valueOf(currentExpenseMilestonesAmount), null);

            //Retrieve the summarized expense non-billing Misc. Adjs. for this billing event
            currentExpenseNonBillingMiscAdjsAmount = expenseNonBillingMiscAdjsMap.get(billingEvent.Id) != null ? expenseNonBillingMiscAdjsMap.get(billingEvent.Id) : 0.0;
            System.debug('BR 8: Current expense non billing Misc. Adjs.: ' + currentExpenseNonBillingMiscAdjsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Current expense non billing Misc. Adjs.', String.valueOf(currentExpenseNonBillingMiscAdjsAmount), null);

            //Current Misc. Adj. for Expense Pct of Services
            currentExpensePctOfServicesAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id, BILLING_TYPE_EXPENSE_PERCENT_OF_SERVICES);
            System.debug('BR 8: Current BR 5 Misc. Adj: Expense Pct of Services: ' + currentExpensePctOfServicesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Current BR 5 Misc. Adj: Expense Pct of Services', String.valueOf(currentExpensePctOfServicesAmount), null);

            //Current Misc. Adj. for Expense Flat Amount
            currentExpenseFlatAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id, BILLING_TYPE_EXPENSE_FLAT_AMOUNT);
            System.debug('BR 8: Current BR 6 Misc. Adj: Expense Charge - Flat Amount: ' + currentExpenseFlatAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Current BR 6 Misc. Adj: Expense Charge - Flat Amount', String.valueOf(currentExpenseFlatAmount), null);

            //Current Misc. Adj. for Expense Cap as Pct of Services Amount
            currentExpensePctOfServicesCapAmount = getCurrentCreditAmountForBillingRuleType(miscAdjsToInsert, project.Id, billingEvent.Id, BILLING_TYPE_EXPENSE_CAP_PERCENT_OF_SERVICES);
            System.debug('BR 8: Current BR 7 Misc. Adj: Expense Credit - Cap Percent of Services: ' + currentExpensePctOfServicesCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Misc. Adj: Expense Credit - Cap Percent of Services', String.valueOf(currentExpensePctOfServicesCapAmount), null);

            //Set the total current expenses amount
            totalCurrentExpenseAmount = currentExpenseItemsAmount + currentExpenseMilestonesAmount + currentExpenseNonBillingMiscAdjsAmount +
                                            currentExpensePctOfServicesAmount + currentExpenseFlatAmount + currentExpensePctOfServicesCapAmount;
            System.debug('BR 8: Total current Expenses Amount: ' + totalCurrentExpenseAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Total current Expenses Amount', String.valueOf(totalCurrentExpenseAmount), null);

            //Retrieve the prior expense amount billed
            priorExpenseBillingsAmount = project.PSA_BR_Expense_Total_To_Date__c;
            System.debug('BR 8: Prior expense billings: ' + priorExpenseBillingsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Prior expense billings', String.valueOf(priorExpenseBillingsAmount), null);

            //Set the total current and prior expenses amount
            totalCurrentAndPriorExpensesAmount = totalCurrentExpenseAmount + priorExpenseBillingsAmount;
            System.debug('BR 8: Total current and prior expense billings: ' + totalCurrentAndPriorExpensesAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Total current and prior expense billings', String.valueOf(totalCurrentAndPriorExpensesAmount), null);

            //Retrieve the prior expenses credits applied to date
            priorExpenseCreditsAmount = project.PSA_BR_Expense_Credits_Applied_To_Date__c;
            System.debug('BR 8: Prior expenses credits: ' + priorExpenseCreditsAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Prior expenses credits', String.valueOf(priorExpenseCreditsAmount), null);

            //Retrieve the expense cap amount from the project
            expenseCapAmount = project.PSA_BR_Expense_Cap_Amt__c;
            System.debug('BR 8: Expense cap amount: ' + expenseCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Expense cap amount', String.valueOf(expenseCapAmount), null);

            //Set the adjusted cap amount
            adjustedCapAmount = expenseCapAmount - priorExpenseCreditsAmount;
            System.debug('BR 8: Adjusted cap amount: ' + adjustedCapAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Adjusted cap amount', String.valueOf(adjustedCapAmount), null);

            //If the total expenses > adjusted cap amount, create a misc. adj. credit for the difference
            if (totalCurrentAndPriorExpensesAmount > adjustedCapAmount) {
                totalExpenseMiscAdjAmount = adjustedCapAmount - totalCurrentAndPriorExpensesAmount;
            } else {
                totalExpenseMiscAdjAmount = 0;
            }
            System.debug('BR 8: Final misc adj amount: ' + totalExpenseMiscAdjAmount);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: Final misc adj amount', String.valueOf(totalExpenseMiscAdjAmount), null);

            //If the expense credit != 0, create a new misc. adj.
            if (totalExpenseMiscAdjAmount != 0) {
                //Need to create an expense credit for cap pct of services misc. adj.
                Date miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);
                pse__Miscellaneous_Adjustment__c miscAdj =
                    createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_CAP_FLAT_AMOUNT, totalExpenseMiscAdjAmount, miscAdjDate, project.Id, billingEvent.Name,
                        billingEvent.Id, true, BILLING_TYPE_EXPENSE_CAP_FLAT_AMOUNT, null, null, null, billingEvent.CurrencyISOCode);
                //miscAdjsToInsert.add(miscAdj);
                System.debug('BR 8: MiscAdjToInsert: ' + miscAdj);
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 8: MiscAdjToInsert', String.valueOf(miscAdj), null);
            }
        }
    }

    /***********************************************************************************************************
    // GW Billing Rule #14: Domestic LTA
    //  Inputs:
    //      1. All expenses by assignment for lta-eligible resources
    //  Steps:
    //      1. Get the list of possible expenses (assignment is marked as lta eligible and lta billable)
    //      2. Roll-up all expenses by assignment and resource where the lta start date is prior to the expense date
    //      3. For all non-zero rolled up expense amounts, create a misc. adj.
    //
    //  Misc. Adjustment Billing Rule Type: 'Expense Charge - Domestic LTA'
    ***********************************************************************************************************/
    public void applyBillingRule_DomesticLTA() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'applyBillingRule_DomesticLTA';

        System.debug('BR 14: running applyBillingRule_DomesticLTA');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        /*** Start of new logic to handle LTA Calculations for Projects that don't have an
        //    Expenses Billing Type of "As Incurred"
        ***/
        //check to see if a related project's expenses billing type is not "As Incurred"
        //  (flat amt per day, pct of services, fixed), and there is an existing billing event
        pse__Billing_Event__c currentBE;
        for (pse__Billing_Event__c be : billingEventMasterMap.values()){
            if (be.pse__Project__r.PSA_BR_Expenses_Billing_Type__c != 'As Incurred' &&
                    be.PSA_Time_Period__r.pse__End_Date__c == endDate &&
                    be.PSA_Time_Period__r.pse__Start_Date__c == startDate){
                currentBE = be;
                break;
            }
        }

        //If an eligible BE was found, retrieve a filtered list of expenses for all LTA-Eligible Assignments
        if (currentBE != null){
            List<pse__Expense__c> expensesToUpdate = new List<pse__Expense__c>();

            //Populate a filter to prevent the LTA calculations from going back further than a certain date (presumably when the
            // updated functionality is deployed)
            Date earliestLTADate = Date.newInstance(2000, 1, 1);
            PSA_Billing__c defaultBilling = PSA_Billing__c.getValues('default');
            if (defaultBilling != null && defaultBilling.PSA_Earliest_LTA_Date__c != null) {
                earliestLTADate = defaultBilling.PSA_Earliest_LTA_Date__c;
            }
            //System.debug('Earliest LTA Date: ' + earliestLTADate);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - Earliest LTA Date: ', String.valueOf(earliestLTADate), null);

            List<pse__Expense__c> ltaExpenses =
                [Select pse__Resource__c, pse__Project__c, pse__Assignment__r.Name, pse__Amount__c, pse__Project__r.CurrencyIsoCode,
                        pse__Expense_Date__c, pse__Assignment__r.PSA_LTA_Start_Date__c, CurrencyISOCode, PSA_LTA_Billing_Event__c
                    From pse__Expense__c
                    Where pse__Project__c = :projectMasterMap.keySet()
                    And pse__Assignment__r.PSA_LTA_Eligible__c = true
                    And pse__Assignment__r.PSA_LTA_Billable__c = true
                    And pse__Expense_Date__c >= :earliestLTADate
                    And pse__Expense_Date__c <= :endDate
                    And pse__Status__c = 'Approved'
                    And pse__Project__r.PSA_BR_Expenses_Billing_Type__c != 'As Incurred'
                    And (PSA_LTA_Billing_Event__c = null Or PSA_LTA_Billing_Event__c = :currentBe.Id)
                    Order By  pse__Project__c, pse__Resource__c, pse__Assignment__r.Name, pse__Expense_Date__c
                ];

            //Start code to handle currency conversions
            Map<Date, Map<String, Decimal>> allRates = new Map<Date, Map<String, Decimal>>();

            Set<String> currencyCodesSet = new Set<String>();
            Set<Date> currencyDateSet = new Set<Date>();
            //get currency for conversion
            if (!ltaExpenses.isEmpty()){
                for (pse__Expense__c e : ltaExpenses){
                    if (e.pse__Project__r.CurrencyIsoCode != e.CurrencyIsoCode){
                        currencyCodesSet.add(e.CurrencyISOCode);
                        currencyCodesSet.add(e.pse__Project__r.CurrencyISOCode);
                        currencyDateSet.add(e.pse__Expense_Date__c);
                    }
                }
            }
            allRates = appirio_core.MultiCurrencyUtil.getConversionRatesByDate(currencyCodesSet, currencyDateSet);
            //End code to handle currency conversions

            String previousKey;
            Decimal total = 0.0;
            Id projectId;
            String description = 'LTA for ';
            Boolean hasRecords= false;

            if (!ltaExpenses.isEmpty()){
                for (pse__Expense__c e : ltaExpenses){
                    hasRecords = true;
                    String currentKey = String.valueOf(e.pse__Project__c) + String.valueOf(e.pse__Resource__c) + e.pse__Assignment__r.Name;
                    if (previousKey != null && currentKey != previousKey) {

                        pse__Proj__c project = projectMasterMap.get(projectId);
                        Decimal ltaPercent = 0.66;

                        Decimal miscAdjAmount = total * ltaPercent;
                        Date miscAdjDate = getInvoiceDate(endDate);

                        pse__Miscellaneous_Adjustment__c miscAdj =
                            createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_LTA, miscAdjAmount, miscAdjDate,
                                project.Id, currentBE.Name, currentBE.Id, true, description, null, null, null, project.CurrencyISOCode);
                        System.debug('BR 14: MiscAdjToInsert (Not Last LTA): ' + miscAdj);
                        //Add apex log record
                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: MiscAdjToInsertFlat', String.valueOf(miscAdj), null);

                        //Reset the Total and key
                        previousKey = currentKey;
                        total = 0.0;
                    }
                    if (previousKey == null || currentKey == previousKey) {
                            Decimal convertedAmount = e.pse__Amount__c;
                            projectId = e.pse__Project__c;
                            description = 'LTA for ' + e.pse__Assignment__r.Name;

                            //If the LTA Start Date <= the Expense Date, add the expense amount to the total (in the Project currency)
                            if (e.pse__Expense_Date__c >= e.pse__Assignment__r.PSA_LTA_Start_Date__c) {
                                //If the expense currency code is different than the project currency code, perform a conversion
                                if (e.pse__Project__r.CurrencyIsoCode != e.CurrencyIsoCode){
                                 //Get conversion rate
                                    Double toCurrencyRate = 0.0;
                                    Double fromCurrencyRate = 0.0;
                                    Date currencyDateIn = e.pse__Expense_Date__c;
                                    String toCurrencyIn = e.pse__Project__r.CurrencyISOCode;
                                    String fromCurrencyIn = e.CurrencyISOCode;
                                    Decimal conversionRate = 0.0;

                                    if (allRates != null && allRates.get(currencyDateIn) != null && allRates.get(currencyDateIn).get(toCurrencyIn) != null)
                                    {
                                        toCurrencyRate = allRates.get(currencyDateIn).get(toCurrencyIn);
                                        //System.debug('***** toCurrencyRate: ' + toCurrencyRate);
                                        //Add apex log record
                                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - To Currency Rate (Project)', String.valueOf(toCurrencyRate + '(' + toCurrencyIn + ' )'), null);
                                    }
                                    if (allRates != null && allRates.get(currencyDateIn) != null && allRates.get(currencyDateIn).get(fromCurrencyIn) != null)
                                    {
                                        fromCurrencyRate = allRates.get(currencyDateIn).get(fromCurrencyIn);
                                        //System.debug('***** fromCurrencyRate: ' + fromCurrencyRate);
                                        //Add apex log record
                                        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - From Currency Rate (Expense)', String.valueOf(fromCurrencyRate + '(' + fromCurrencyIn + ' )'), null);
                                    }

                                    //Only set if from CurrencyRate > 0
                                    //System.debug('***** from CurrencyRate: ' + fromCurrencyRate);
                                    if (fromCurrencyRate <> 0)
                                    {
                                        conversionRate = toCurrencyRate/(1/fromCurrencyRate);
                                    }

                                    //Return the converted Amount
                                    //System.debug('******* original amount: ' + e.pse__Amount__c);
                                    convertedAmount = (e.pse__Amount__c * conversionRate).setScale(2);
                                    //System.debug('**** convertedAmount: ' + convertedAmount);
                                    //Add apex log record
                                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - Original Expense Amount', String.valueOf(e.pse__Amount__c), null);
                                    //Add apex log record
                                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - Converted Expense Amount', String.valueOf(convertedAmount), null);
                                }
                                //System.debug('******Expense Date: ' + e.pse__Expense_Date__c + ' LTA Start: ' + e.pse__Assignment__r.PSA_LTA_Start_Date__c);

                                total += convertedAmount;

                                //If the expense LTA Billing Event value is null, set it and add the expense to the list of expenses to be updated
                                if (e.PSA_LTA_Billing_Event__c == null) {
                                    e.PSA_LTA_Billing_Event__c = currentBE.Id;
                                    expensesToUpdate.add(e);
                                }
                                //System.debug('******** Total: ' + total);
                                //Add apex log record
                                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: LTA - Running Total: ', String.valueOf(total), null);
                            }
                    }

                    previousKey = currentKey;
                }

                //Add the last Misc. Adj.
                if (hasRecords){
                    pse__Proj__c project = projectMasterMap.get(projectId);
                    Decimal ltaPercent = 0.66;

                    Decimal miscAdjAmount = total * ltaPercent;
                    Date miscAdjDate = getInvoiceDate(endDate);
                    pse__Miscellaneous_Adjustment__c miscAdj =
                        createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_LTA, miscAdjAmount, miscAdjDate,
                            project.Id, currentBE.Name, currentBE.Id, true, description, null, null, null, project.CurrencyISOCode);
                    System.debug('BR 14: MiscAdjToInsert (Last LTA): ' + miscAdj);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: MiscAdjToInsertFlat', String.valueOf(miscAdj), null);
                }

            }

            //Perform DML update for Expenses if applicable
            if (expensesToUpdate.size() > 0) {
                update expensesToUpdate;
            }
        }
        /*** End of new logic to handle LTA Calculations for Projects that don't have an
        //    Expenses Billing Type of "As Incurred"
        ***/

        List<pse__Billing_Event_Item__c> beiExpenses =
            [Select Id, Name, pse__Expense__r.pse__Assignment__c, pse__Expense__r.pse__Resource__c,
                    pse__Expense__r.pse__Expense_Date__c, pse__Billing_Event__c,
                    pse__Expense__r.pse__Resource__r.Name, pse__Expense__r.pse__Assignment__r.PSA_LTA_Start_Date__c,
                    pse__Expense__r.pse__Assignment__r.Name, pse__Expense__r.pse__Billing_Amount__c
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectMasterMap.keySet()
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Expense__c != null
                And pse__Expense__r.pse__Assignment__r.PSA_LTA_Eligible__c = true
                And pse__Expense__r.pse__Assignment__r.PSA_LTA_Billable__c = true
                Order By  pse__Expense__r.pse__Resource__c, pse__Expense__r.pse__Assignment__c
            ];
        System.debug('BR 14: All Possible Expenses List: ' + beiExpenses);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: All Possible Expenses List', String.valueOf(beiExpenses), null);

        //Loop through each expense and roll them up by resource and assignment
        if (beiExpenses != null && beiExpenses.size() > 0) {
            ExpenseSummaryByResourceAndAssignment expenseSummaryController = new ExpenseSummaryByResourceAndAssignment();
            Map<String, ExpenseSummaryByResourceAndAssignment> expenseSummaryMap = expenseSummaryController.buildMap(beiExpenses);
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: Expense Summary Map', String.valueOf(expenseSummaryMap), null);

            String miscAdjDescription;
            Decimal miscAdjAmount;
            Decimal ltaPercent = 0.66;
            pse__Billing_Event__c billingEvent;
            pse__Proj__c project;

            for (ExpenseSummaryByResourceAndAssignment expenseSummary : expenseSummaryMap.values()) {
                //If the amount is > 0, create a misc. adj.
                if (expenseSummary.TotalAmount > 0) {
                    //Need to create an expense credit for cap pct of services misc. adj.
                    billingEvent = billingEventMasterMap.get(expenseSummary.BillingEventId);
                    project = projectMasterMap.get(billingEvent.pse__Project__c);
                    miscAdjDescription = 'LTA for ' + expenseSummary.AssignmentName;
                    miscAdjAmount = expenseSummary.TotalAmount * ltaPercent;
                    Date miscAdjDate = getInvoiceDate(billingEvent.PSA_Time_Period__r.pse__End_Date__c);
                    pse__Miscellaneous_Adjustment__c miscAdj =
                        createMiscellaneousAdjustment(BILLING_TYPE_EXPENSE_LTA, miscAdjAmount, miscAdjDate,
                            project.Id, billingEvent.Name, billingEvent.Id, true, miscAdjDescription, null, null, null, billingEvent.CurrencyISOCode);
                    //miscAdjsToInsert.add(miscAdj);
                    System.debug('BR 14: MiscAdjToInsert: ' + miscAdj);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BR 14: MiscAdjToInsert', String.valueOf(miscAdj), null);
                }
            }
        }
    }

    /**************************************************************************************
    // Name         : getBillingEventForProject
    // Description  : Used by BR #9 to get a "default" bill rate.  If the total number of hours
    //                  in the billing event does not add up to the minimum monthly hours, add
    //                  a Misc. Adj. to make up the difference.  The amount of the Misc. Adj.
    //                  will be the unbilled number of hours multiplied by the "default" bill rate.
    // Author       : CLD Partners
    // Revisions    : 2015-07-10  Klassen  (Initial Version)
    //              :
    ***************************************************************************************/
    public pse__Billing_Event__c getBillingEventForProject(pse__Proj__c project, Date timePeriodEndDate) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getBillingEventForProject';

        //System.debug('entering getBillingEventForProject');
        List<pse__Billing_Event__c> billingEvents = billingEventMasterMap.values();
        //System.debug('getBillingEventForProject project: ' + project);
        //System.debug('getBillingEventForProject end date: ' + timePeriodEndDate);
        //System.debug('getBillingEventForProject - billing events: ' + billingEvents);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Time Period End Date', String.valueOf(timePeriodEndDate), null);

        for (pse__Billing_Event__c billingEvent : billingEvents) {
            if (billingEvent.pse__Project__c == project.Id &&
                    billingEvent.PSA_Time_Period__r.pse__End_Date__c == timePeriodEndDate) {
                //Add apex log record
                psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BE for specified End Date', String.valueOf(billingEvent), null);

                return billingEvent;
            }
        }
        //Should not reach this condition since this means we couldn't find a billing event
        return null;
    }

    /*** The following method is no longer needed since the Min Hours bill rate now is set
            directly on the project
    ***/
    /**************************************************************************************
    // Name         : getProjectStandardBillRate
    // Description  : Used by BR #9 to get a "default" bill rate.  If the total number of hours
    //                  in the billing event does not add up to the minimum monthly hours, add
    //                  a Misc. Adj. to make up the difference.  The amount of the Misc. Adj.
    //                  will be the unbilled number of hours multiplied by the "default" bill rate.
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              : 2015-07-20  Klassen  (Pull Rates from Assignments, not previous timecards)
    //              : 2016-04-24  Klassen  Method no longer used, so commented out
    ***************************************************************************************/
    /*** CK 4/24/16 -- The following method is no longer needed since the Min Hours bill rate now
             is set directly on the project
    public Map<Id, Decimal> getProjectStandardBillRate(Set<Id> projectIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getProjectStandardBillRate';

        Map<Id, Decimal> projectBillRateMap = new Map<Id, Decimal>();
        List<pse__Assignment__c> assignmentBillRates =
            [Select pse__Project__c, pse__Bill_Rate__c
                From pse__Assignment__c
                Where pse__Project__c = :projectIds
                And pse__Bill_Rate__c > 0
            ];
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Assignment Bill Rate List', String.valueOf(assignmentBillRates), null);

        for (pse__Assignment__c assignment : assignmentBillRates) {
            if (!projectBillRateMap.containsKey(assignment.pse__Project__c)) {
                projectBillRateMap.put(assignment.pse__Project__c, assignment.pse__Bill_Rate__c);
            }
        }
        System.debug('Project bill rate map:'+projectBillRateMap);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project bill rate map', String.valueOf(projectBillRateMap), null);

        return projectBillRateMap;
    }
    ***/

    /**************************************************************************************
    // Name         : getCurrentCreditAmountForBillingRuleType
    // Description  : Lookup any misc. adjs. for a specific (un-released) billing event that
    //                  match a specified Billing Rule Type.
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    private Decimal getCurrentCreditAmountForBillingRuleType(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id projectId, Id billingEventId,
            String billingRuleType) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getCurrentCreditAmountForBillingRuleType';

        Decimal currentCreditAmount = 0.0;
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
            if (miscAdj.pse__Project__c == projectId &&
                    miscAdj.PSA_BR_Billing_Event__c == billingEventId &&
                    miscAdj.PSA_Billing_Rule_Type__c == billingRuleType) {
                currentCreditAmount += miscAdj.pse__Amount__c;
            }
        }
        return currentCreditAmount;
    }

    /**************************************************************************************
    // Name         : getCurrentCreditAmountForBillingEvent
    // Description  : Lookup all misc. adjs. for a specific (un-released) billing event that
    //                  match a specified Billing Event.
    //                  Used in BR #11, BR #5
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    private Decimal getCurrentCreditAmountForBillingEvent(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id projectId,
            Id billingEventId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getCurrentCreditAmountForBillingEvent';

        Decimal currentCreditAmount = 0.0;
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
            if (miscAdj.pse__Project__c == projectId &&
                    miscAdj.PSA_BR_Billing_Event__c == billingEventId) {
                currentCreditAmount += miscAdj.pse__Amount__c;
            }
        }
        return currentCreditAmount;
    }

    /**************************************************************************************
    // Name         : getCurrentCreditAmountForProject
    // Description  : Lookup all misc. adjs. for all (un-released) billing events that
    //                  match a specified Project.
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    private Decimal getCurrentCreditAmountForProject(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id projectId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getCurrentCreditAmountForProject';

        Decimal currentCreditAmount = 0.0;
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
            if (miscAdj.pse__Project__c == projectId) {
                currentCreditAmount += miscAdj.pse__Amount__c;
            }
        }
        return currentCreditAmount;
    }

    /**************************************************************************************
    // Name         : getCurrentCreditAmountForProjectAndBillingRuleType
    // Description  : Lookup all misc. adjs. for all (un-released) billing events that
    //                  match a specified Project AND billing rule type.
    // Author       : CLD Partners
    // Revisions    : 2015-05-06  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    private Decimal getCurrentCreditAmountForProjectAndBillingRuleType(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id projectId, String billingRuleType) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getCurrentCreditAmountForProjectAndBillingRuleType';

        Decimal currentCreditAmount = 0.0;
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
            if (miscAdj.pse__Project__c == projectId && miscAdj.PSA_Billing_Rule_Type__c == billingRuleType) {
                currentCreditAmount += miscAdj.pse__Amount__c;
            }
        }
        return currentCreditAmount;
    }

    /**************************************************************************************
    // Name         : getCurrentCreditAmountForAccountAndBillingRuleType
    // Description  : Lookup all misc. adjs. for all (un-released) billing events that
    //                  match a specified Account AND billing rule type.
    // Author       : CLD Partners
    // Revisions    : 2015-05-06  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    private Decimal getCurrentCreditAmountForAccountAndBillingRuleType(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id accountId, String billingRuleType) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getCurrentCreditAmountForAccountAndBillingRuleType';

        Decimal currentCreditAmount = 0.0;
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
            if (miscAdj.pse__Project__r.pse__Account__c == accountId && miscAdj.PSA_Billing_Rule_Type__c == billingRuleType) {
                currentCreditAmount += miscAdj.pse__Amount__c;
            }
        }
        return currentCreditAmount;
    }

    /**************************************************************************************
    // Name         : getBillingEventMiscAdjAmountMap
    // Description  : Use an aggregateresults query to sum up all "saved" Misc. Adj. Amounts
    //                  that match a the Billing Events master list and a specific billing rule type.
    // Author       : CLD Partners
    // Revisions    : 2015-07-11  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    public Map<Id, Decimal> getBillingEventMiscAdjAmountMap(String billingRuleType) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getBillingEventMiscAdjAmountMap';

        Map<Id, Decimal> returnMapValue = new Map<Id, Decimal>();
        AggregateResult[] arTotalMinHourAmounts =
            [Select pse__Billing_Event__c BillingEventId, SUM(pse__Miscellaneous_Adjustment__r.PSA_Amount_Number__c) TotalAmount
                from pse__Billing_Event_Item__c
                where pse__Billing_Event__c = :billingEventMasterMap.keySet()
                and pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c = :billingRuleType
                and pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = true
                group by pse__Billing_Event__c
                order by pse__Billing_Event__c
            ];
        if (arTotalMinHourAmounts != null && arTotalMinHourAmounts.size() > 0) {
            for (AggregateResult ar : arTotalMinHourAmounts) {
                returnMapValue.put((Id)ar.get('BillingEventId'), (Decimal)ar.get('TotalAmount'));
            }
        }

        return returnMapValue;
    }

    /**************************************************************************************
    // Name         : getHoldBackMiscAdjForBillingEvent
    // Description  : Lookup a Holdback misc. adjs. for a specific Billing Event
    // Author       : CLD Partners
    // Revisions    : 2015-05-08  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    public pse__Miscellaneous_Adjustment__c getMiscAdjForBillingEventAndBillingRuleType(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id billingEventId, String billingRuleType) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getMiscAdjForBillingEventAndBillingRuleType';

        //System.debug('getMiscAdjForBillingEventAndBillingRuleType miscAdjList: ' + miscAdjList);
        if (miscAdjList != null && miscAdjList.size() > 0) {
            for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
                if (miscAdj.PSA_BR_Billing_Event__c == billingEventId && miscAdj.PSA_Billing_Rule_Type__c == billingRuleType) {
                    //System.debug('getMiscAdjForBillingEventAndBillingRuleType Found for: ' + billingRuleType + ': misc adj: ' + miscAdj);
                    return miscAdj;
                }
            }
        }
        return null;
    }

    /**************************************************************************************
    // Name         : getHoldBackReleaseMiscAdjForProject
    // Description  : Lookup a Holdback Release misc. adjs. for all (un-released) billing events that
    //                  match a specified Project.
    // Author       : CLD Partners
    // Revisions    : 2015-05-06  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    public pse__Miscellaneous_Adjustment__c getHoldBackReleaseMiscAdjForProject(
            List<pse__Miscellaneous_Adjustment__c> miscAdjList, Id projectId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getHoldBackReleaseMiscAdjForProject';

        //pse__Miscellaneous_Adjustment__c holdbackReleaseMiscAdj;

        System.debug('getHoldBackReleaseMiscAdjForProject miscAdjList: ' + miscAdjList);
        if (miscAdjList != null && miscAdjList.size() > 0) {
            for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjList) {
                if (miscAdj.pse__Project__c == projectId &&
                        miscAdj.PSA_Billing_Rule_Type__c == BILLING_TYPE_HOLDBACK_RELEASE) {
                    System.debug('getHoldBackReleaseMiscAdjForProject Found Holdback Release misc adj: ' + miscAdj);
                    return miscAdj;
                }
            }
        }
        return null;
    }

    /**************************************************************************************
    // Name         : clearBillingRules
    // Description  : Each time a billing event is updated, including when new billing event
    //                  items are added, the miscellaneous adjustments that were created by
    //                  the applyBillingRules process will either need to be deleted or
    //                  in some situations updated.  If a "billing rule" misc. adj. was manually
    //                  created, we don't want to automatically remove it.  In addition, any
    //                  PSA Project Balance records for affected billing Events will need to be
    //                  deleted.
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              : 2015-04-27  Klassen  (Initial Implementation)
    ***************************************************************************************/
    public Boolean clearBillingRules(Set<Id> projectIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'clearBillingRules';

        System.debug('Running clearBillingRules');
        //Add apex log record
        psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);

        Set<Id> billingEventIds = new Set<Id>(); //Used to delete related PSA Project Balance records
        Boolean successFlag = true; //assume success
        List<pse__Billing_Event_Item__c> beItems =
            [Select Id, pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, pse__Billing_Event__c,
                    pse__Project__c, pse__Amount__c, pse__Miscellaneous_Adjustment__r.PSA_BR_Eligible_Discount_Amount__c
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectIds
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Miscellaneous_Adjustment__r.PSA_Created_By_Billing_Rule__c = true
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c != :BILLING_TYPE_HOLDBACK_RELEASE
                And pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c != :BILLING_TYPE_MINIMUM_HOURS
            ];
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event with Items to Clear', String.valueOf(beItems), null);

        List<Id> billingEventItemsToDelete = new List<Id>();
        //List<pse__Miscellaneous_Adjustment__c> miscAdjsToUpdate = new List<pse__Miscellaneous_Adjustment__c>();
        pse__Miscellaneous_Adjustment__c holdbackReleaseMiscAdj;
        pse__Miscellaneous_Adjustment__c billingMiscAdj;

        for (pse__Billing_Event_Item__c bei : beItems) {
            System.debug('Running clearBillingRules for Billing Event:'+bei);
            billingEventIds.add(bei.pse__Billing_Event__c);
            billingEventItemsToDelete.add(bei.Id);
        }

        //Add any billing events with a min. hours misc. adjustment for no timecards
        pse__Billing_Event__c billingEventNoTimecard;
        List<pse__Proj__c> minHoursProjectsWithNoTimecards = getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards(
                projectMasterMap.keySet(), startDate, endDate, true);
        if (minHoursProjectsWithNoTimecards != null && minHoursProjectsWithNoTimecards.size() > 0) {
            for (pse__Proj__c minHoursProject : minHoursProjectsWithNoTimecards) {
                //Find the appropriate billing event and then add the billing event id to the set
                billingEventNoTimecard = getBillingEventForProject(minHoursProject, endDate);
                if (billingEventNoTimecard != null) {
                    billingEventIds.add(billingEventNoTimecard.Id);
                    //Add apex log record
                    psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event With No Timecards', String.valueOf(billingEventNoTimecard), null);
                }
            }
        }

        //Code exists in psaBillingEventItemTriggerHandler to delete the related Billing Rule Misc. Adjs
        // after the BEI is deleted
        if (billingEventItemsToDelete.size() > 0) {
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'About to delete BE Items', String.valueOf(billingEventItemsToDelete), null);
            Database.delete(billingEventItemsToDelete);
        }

        //Delete PSA Project Balance records for affected billing events
        if (billingEventIds.size() > 0) {
            System.debug('About to delete all PSA Project Balances for Billing Events: ' + billingEventIds);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'About to delete all PSA Project Balances for Billing Events', String.valueOf(billingEventIds), null);
            delete [Select Id From PSA_Project_Balance__c Where PSA_Billing_Event__c In :billingEventIds];
        }

        //Reset the Account Discount Eligible Billings summary field on the billing events and PSA Account Discount records
        Set<Id> accountDiscountIds = new Set<Id>();
        List<pse__Billing_Event__c> billingEventsToUpdate =
            [Select Id, PSA_Account_Discount_Services_Total__c, pse__Project__r.PSA_BR_Account_Discount__c
                From pse__Billing_Event__c
                Where Id = :billingEventIds
            ];
        for (pse__Billing_Event__c billingEvent : billingEventsToUpdate) {
            billingEvent.PSA_Account_Discount_Services_Total__c = 0.0;
            if (billingEvent.pse__Project__r.PSA_BR_Account_Discount__c != null) {
                accountDiscountIds.add(billingEvent.pse__Project__r.PSA_BR_Account_Discount__c);
            }
        }
        System.debug('Billing Events To Update: ' + billingEventsToUpdate);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Events To Update (for Account Discount BR)', String.valueOf(billingEventsToUpdate), null);
        update billingEventsToUpdate;

        //Reset the variable since it will be updated with the current BE amount and BEI count
        // at the end of the Billing Rules Application
        billingEventsToUpdate = new List<pse__Billing_Event__c>();

        if (accountDiscountIds.size() > 0) {
            System.debug('Account Discount Ids to be updated: ' + accountDiscountIds);
            //Add apex log record
            psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Account Discount Ids to be updated (via Refresh Billing Balances)', String.valueOf(accountDiscountIds), null);
            psaRefreshProjectBillingBalances.updateAccountDiscountBalances(accountDiscountIds);
        }

        //Database.rollback(sp);

        return successFlag;
    }

    /**************************************************************************************
    // Name         : fillProjectsMasterMap
    // Description  : Populate a Map of all related Projects for Billing Events to be
    //                  processed
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              : 2015-04-15  Klassen  (Initial Implementation)
    ***************************************************************************************/
    private Map<Id, pse__Proj__c> fillProjectsMasterMap(Set<Id> projectIds) {

        return new Map<Id, pse__Proj__c>(
            [Select Id,
                    Name,
                    pse__End_Date__c,
                    pse__Billing_Type__c,
                    CurrencyISOCode,
                    PSA_BR_Expenses_Billing_Type__c,
                    PSA_BR_Expense_Pct_of_Services__c,
                    PSA_BR_Billing_Levels_for_Expense_Pct__c,
                    PSA_BR_Expense_Amt_Per_Day__c,
                    PSA_BR_Billing_Levels_for_Expense_Amt__c,
                    PSA_BR_Expense_Cap_Pct_Applies__c,
                    PSA_BR_Expense_Cap_Pct__c,
                    PSA_BR_Expense_Cap_Flat_Applies__c,
                    PSA_BR_Expense_Cap_Amt__c,
                    PSA_BR_Minimum_Billed_Hours_Applies__c,
                    PSA_BR_Minimum_Billed_Hours_Monthly__c,
                    PSA_BR_Services_Cap_Flat_Applies__c,
                    PSA_BR_Services_Cap_Amt__c,
                    PSA_BR_Holdback_Applies__c,
                    PSA_BR_Holdback_Pct__c,
                    PSA_BR_Holdback_End_Date__c,
                    PSA_BR_Project_Discount_Applies__c,
                    PSA_BR_Project_Discount_Pct__c,
                    PSA_BR_Project_Discount_End_Date__c,
                    PSA_BR_Project_Discount_Cap__c,
                    PSA_BR_Project_Discount_Type__c,
                    PSA_BR_Project_Discount_Billing_Levels__c,
                    PSA_BR_Account_Discount_Applies__c,
                    PSA_BR_Account_Discount__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Percent__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Cap__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Type__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Active__c,
                    PSA_BR_Account_Discount__r.PSA_Discount_Eligible_Billings_To_Date__c,
                    pse__Account__c,
                    PSA_BR_Holdback_Applied_To_Date__c,
                    PSA_BR_Holdback_Release_Applied_ToDate__c,
                    PSA_BR_Expense_Total_To_Date__c,
                    PSA_BR_Expense_Credits_Applied_To_Date__c,
                    PSA_BR_Discount_Applied_To_Date__c,
                    PSA_BR_Services_Total_To_Date__c,
                    PSA_BR_Services_Credit_Applied_To_Date__c,
                    PSA_BR_Minimum_Hours_Bill_Rate__c,
                    PSA_BR_Minimum_Hours_Bill_Amount__c, 
                    PSA_BR_Minimum_Hours_Billing_Level__c 
                from pse__Proj__c
                Where Id =:projectIds
                And PSA_BR_Billing_Rules_Status__c = 'Accepted'
            ]);
    }

    /**************************************************************************************
    // Name         : fillBillingEventsMasterMap
    // Description  : Populate a Map of all Billing Events to be processed
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    private Map<Id, pse__Billing_Event__c> fillBillingEventsMasterMap(Set<Id> projectIds) {
        return new Map<Id, pse__Billing_Event__c>(
            [Select Id,
                    Name,
                    pse__Project__c,
                    CurrencyISOCode,
                    pse__Billing_Event_Batch__c,
                    PSA_Time_Period__r.pse__Type__c,
                    PSA_Time_Period__r.pse__Start_Date__c,
                    PSA_Time_Period__r.pse__End_Date__c,
                    PSA_Account_Discount_Services_Total__c,
                    PSA_Billing_Rules_Applied_Date__c,
                    PSA_Billing_Event_Recalc_Date__c,
                    PSA_Billing_Event_Docs_Started_Date__c,
                    PSA_Billing_Event_Docs_Attached_Date__c,
                    PSA_Has_Miscellaneous_Adjustments__c,
                    pse__Project__r.PSA_BR_Expenses_Billing_Type__c
                From pse__Billing_Event__c
                Where pse__Project__c =:projectIds
                And pse__Is_Released__c = false
            ]);
    }

    /**************************************************************************************
    // Name         : getHoldbackReleaseMiscAdjByProjectMap
    // Description  : Populate a Map of all "Holdback Release" Misc. Adj. for a specified
    //                  set of Projects
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              : 2015-04-27  Klassen  (Actual implementation)
    ***************************************************************************************/
    public Map<Id, pse__Miscellaneous_Adjustment__c> getHoldbackReleaseMiscAdjByProjectMap(Set<Id> projectIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getHoldbackReleaseMiscAdjByProjectMap';

        Map<Id, pse__Miscellaneous_Adjustment__c> holdbackReleaseMiscAdjByProjectMap = new Map<Id, pse__Miscellaneous_Adjustment__c>();
        List<pse__Miscellaneous_Adjustment__c> miscAdjs =
            [Select Id, Name, pse__Project__c, pse__Amount__c, PSA_Billing_Rule_Type__c,
                    PSA_BR_Eligible_Discount_Amount__c
                From pse__Miscellaneous_Adjustment__c
                Where pse__Project__c = :projectIds
                And PSA_Billing_Rule_Type__c = :BILLING_TYPE_HOLDBACK_RELEASE
                And PSA_Created_By_Billing_Rule__c = true
                And pse__Billed__c = false
            ];
                //And pse__Approved__c = false
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Holdback Misc. Adjs.', String.valueOf(miscAdjs), null);

        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjs) {
            holdbackReleaseMiscAdjByProjectMap.put(miscAdj.pse__Project__c, miscAdj);
        }

        return holdbackReleaseMiscAdjByProjectMap;
    }

    /**************************************************************************************
    // Name         : getTimecardsAggregateResults
    // Description  : Populate an array of AggregateResults with summarized timecard amounts,
    //                  total hours, and total days worked.  Used by BRs 9,
    // Author       : CLD Partners
    // Revisions    : 2015-05-13  Klassen  (Implementation)
    //              :
    ***************************************************************************************/
    public AggregateResult[] getTimecardsAggregateResults(Set<Id> projectIds,
            String billingRuleField) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getTimecardsAggregateResults';

        String selectClause = 'Select pse__Timecard_Split__r.pse__Resource__c ResourceId, ' +
                    'pse__Billing_Event__c BillingEventId, ' +
                    'pse__Project__c ProjectId, ' +
                    'pse__Project__r.pse__Account__c AccountId, ' +
                    'Sum(pse__Timecard_Split__r.pse__Total_Hours__c) TotalHours, ' +
                    'Sum(pse__Timecard_Split__r.pse__Total_Days_Worked__c) TotalDays, ' +
                    'Sum(pse__Timecard_Split__r.PSA_Total_Billable_Number__c) TotalAmount ';
        String fromClause = 'From pse__Billing_Event_Item__c ';
        String groupByClause = 'Group by pse__Timecard_Split__r.pse__Resource__c, ' +
                                'pse__Billing_Event__c, pse__Project__c, pse__Project__r.pse__Account__c ';
        String orderByClause = 'Order by pse__Billing_Event__c ';
        String whereClause = 'Where pse__Project__c In :projectIds ' +
                    'And pse__Billing_Event__r.pse__Is_Released__c = false ' +
                    'And pse__Timecard_Split__c != null ' +
                    'And pse__Timecard_Split__r.pse__Timecard_Header__r.pse__Milestone__r.Name != :OVER_CAP_MILESTONE_NAME ';
        whereClause += 'And pse__Project__r.' + billingRuleField + ' = true ';

        String soqlQuery = selectClause + fromClause + whereClause + groupByClause + orderByClause;
        System.debug('BR getTimecardsAggregateResults soql: ' + soqlQuery);
        //Add apex log record
        psaApexLog.createApexLog(3, apexLogSource, apexLogMethod, apexLogMethodSequence, 'getTimecardsAggregateResults soql for BR Type Field: ' + billingRuleField, soqlQuery, null);

        AggregateResult[] arTimecardSummary = (AggregateResult[])Database.query(soqlQuery);
        return arTimecardSummary;
    }

    /**************************************************************************************
    // Name         : getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards
    // Description  : Used to create a miscellaneous adjustment for projects with the
    //              :  Minimum Billable Hours Monthly applies but have no timecards and no
    //              :  min. hours misc. adjustment.  This will cause a Billing Event to be
    //              :  created for this project, and the Min. Hours billing rule code will
    //              :  get run to create the misc. adjustment for this project.
    // Author       : CLD Partners
    // Revisions    : 2015-07-10  Klassen  (Initial Version)
    //              : 2016-01-04  Klassen  Fix bug that caused a dup. Id error when updating
    //                  the min. hours misc. adjustment (DE852) -- include timecards from
    //                  prior periods
    ***************************************************************************************/
    public List<pse__Proj__c> getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards(Set<Id> projectIds,
            Date timePeriodStartDate, Date timePeriodEndDate, Boolean excludeBillingEventCriteria) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards';

        List<pse__Proj__c> projects;

        if (excludeBillingEventCriteria == true) {
            projects =
                [select Id, Name, CurrencyISOCode, pse__Exclude_From_Billing__c
                    from pse__Proj__c
                    where Id In :projectIds
                    and PSA_BR_minimum_billed_hours_applies__c = true
                    and Id Not In (
                        select pse__Project__c
                            from pse__Billing_Event_Item__c
                            where pse__Project__c = :projectIds
                            and pse__Billing_Event__r.PSA_Time_Period__r.pse__End_Date__c = :timePeriodEndDate
                            and pse__Timecard_Split__c != null
                    )
                ];
        }  else {
            projects =
                [select Id, Name, CurrencyISOCode, pse__Exclude_From_Billing__c
                    from pse__Proj__c
                    where Id In :projectIds
                    and PSA_BR_minimum_billed_hours_applies__c = true
                    and Id Not In (
                        select pse__Project__c
                            from pse__Billing_Event__c
                            where PSA_Time_Period__r.pse__End_Date__c = :timePeriodEndDate
                    )
                    and Id Not In (
                        select pse__Project__c
                            from pse__Timecard__c
                            where pse__End_Date__c <= :timePeriodEndDate
                            and pse__Approved__c = true
                            and pse__Total_Hours__c != 0
                            and pse__Billing_Event_Item__c = null
                            and pse__Billable__c = true
                    )
                ];
//Removed as part of DE852 since we need to consider any past billable timecards, not just billable timecards for the current billing period
//                            and pse__Start_Date__c >= :timePeriodStartDate
        }

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Projects - Min. Hours List', String.valueOf(projects), null);

        return projects;
    }

    /**************************************************************************************
    // Name         : createMinimumHoursMiscAdjustmentIfNoTimecards
    // Description  : Used to create a miscellaneous adjustment for projects with the
    //              :  Minimum Billable Hours Monthly applies but have no timecards and no
    //              :  min. hours misc. adjustment.  This will cause a Billing Event to be
    //              :  created for this project, and the Min. Hours billing rule code will
    //              :  get run to create the misc. adjustment for this project.
    // Author       : CLD Partners
    // Revisions    : 2015-07-09  Klassen  (Initial Version)
    //              :
    ***************************************************************************************/
    public void createMinimumHoursMiscAdjustmentIfNoTimecards(Set<Id> projectIds,
            Date timePeriodStartDate, Date timePeriodEndDate) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'createMinimumHoursMiscAdjustmentIfNoTimecards';

        List<pse__Proj__c> projects = getProjectsForMinimumHoursMiscAdjustmentIfNoTimecards(
                projectIds, timePeriodStartDate, timePeriodEndDate, false);
        if (projects != null && projects.size() > 0) {
            System.debug('Projects to create a misc. adj.: ' + projects);
            for (pse__Proj__c project : projects) {
                if (project.pse__Exclude_From_Billing__c == false) {
                    createMiscellaneousAdjustment(BILLING_TYPE_MINIMUM_HOURS, 1.00, timePeriodEndDate, project.Id,
                                            '', null, true, BILLING_TYPE_MINIMUM_HOURS, null, null, null, project.CurrencyISOCode);
                }
            }
            System.debug('Misc Adj: ' + miscAdjsToInsert);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Projects - Min. Hours - New Misc Adj.', String.valueOf(miscAdjsToInsert), null);

            insert miscAdjsToInsert;
        }
    }

    /**************************************************************************************
    // Name         : buildMiscAdjustmentForMinimumHoursIfNoTimecardsMap
    // Description  : Build a map of all possible misc adjs for minimum billable hours that
    //                  wasn't created by the standard BR9 billing rules logic, i.e. misc
    //                  adjs that were for projects with no timecards in the period
    // Author       : CLD Partners
    // Revisions    : 2015-07-10  Klassen  (Initial Version)
    //              :
    ***************************************************************************************/
    public Map<Id, pse__Miscellaneous_Adjustment__c> buildMiscAdjustmentForMinimumHoursIfNoTimecardsMap(Set<Id> projectIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'buildMiscAdjustmentForMinimumHoursIfNoTimecardsMap';

        Map<Id, pse__Miscellaneous_Adjustment__c> miscAdjMinHoursMap = new Map<Id, pse__Miscellaneous_Adjustment__c>();

        List<pse__Miscellaneous_Adjustment__c> miscAdjs =
            [Select Id, Name, pse__Billing_Event_Item__r.pse__Billing_Event__c, pse__Amount__c, PSA_Billing_Rule_Type__c,
                    pse__Billing_Event_Item__c
                From pse__Miscellaneous_Adjustment__c
                Where pse__Project__c = :projectIds
                And PSA_Billing_Rule_Type__c = :BILLING_TYPE_MINIMUM_HOURS
                And PSA_Created_By_Billing_Rule__c = true
                And pse__Billed__c = false
            ];
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjs) {
            miscAdjMinHoursMap.put(miscAdj.pse__Billing_Event_Item__r.pse__Billing_Event__c, miscAdj);
        }
        System.debug('Misc Adj Min Hours Map: ' + miscAdjMinHoursMap);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Min. Hours - Misc Adj Map', String.valueOf(miscAdjMinHoursMap), null);

        return miscAdjMinHoursMap;
    }

    /**************************************************************************************
    // Name         : createBillingEventItem
    // Description  : Used to create new Billing Event Items
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    public pse__Billing_Event_Item__c createBillingEventItem(pse__Billing_Event__c be, pse__Miscellaneous_Adjustment__c miscAdj) {
        pse__Billing_Event_Item__c bei = new pse__Billing_Event_Item__c();
        bei.pse__Billing_Event__c = be.Id;
        bei.pse__Project__c = be.pse__Project__c;
        bei.pse__Amount__c = miscAdj.pse__Amount__c;
        bei.pse__Unit_Price__c = miscAdj.pse__Amount__c;
        bei.pse__Quantity__c = 1;
        bei.pse__Date__c = Date.today();
        bei.pse__Category__c = 'Miscellaneous Adjustment';
        bei.pse__Object_Id__c = miscAdj.Id;
        bei.pse__Miscellaneous_Adjustment__c = miscAdj.Id;
        bei.pse__Description__c = miscAdj.pse__Description__c;
        bei.pse__Billing_Event_Batch__c = be.pse__Billing_Event_Batch__c;
        bei.CurrencyISOCode = be.CurrencyISOCode;
        return bei;
    }

    /**************************************************************************************
    // Name         : createMiscellaneousAdjustment
    // Description  : Used to create new Misc. Adjustments that will be related to new
    //                  Billing Event Items
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    public pse__Miscellaneous_Adjustment__c createMiscellaneousAdjustment(String billingRuleType,
            Decimal amount, Date effectiveDate, Id projectId, String beName, Id beId,
            Boolean createdByBillingrule, String description, Decimal dailyRate,
            Decimal totalDaysWorked, Id resourceId, String currencyCode) {
        String miscAdjName;
        pse__Miscellaneous_Adjustment__c miscAdj;

        if (amount != 0.0) {
            if (beName == null) {
                miscAdjName= 'Billing: ' + billingRuleType;
            } else {
                miscAdjName= 'Billing: ' + beName + ' : ' + billingRuleType;
            }
            miscAdj =  new pse__Miscellaneous_Adjustment__c(Name=miscAdjName);
            miscAdj.pse__Project__c = projectId;
            miscAdj.pse__Amount__c = amount;
            miscAdj.PSA_Billing_Rule_Type__c = billingRuleType;
            miscAdj.pse__Effective_Date__c = effectiveDate;
            miscAdj.pse__Transaction_Category__c = 'Ready-to-Bill Revenue';
            miscAdj.PSA_Created_By_Billing_Rule__c = createdByBillingrule;
            if (billingRuleType != BILLING_TYPE_HOLDBACK_RELEASE) {
                miscAdj.pse__Status__c = 'Approved';
                miscAdj.pse__Approved__c = true;
            }
            miscAdj.PSA_BR_Billing_Event__c = beId;
            miscAdj.pse__Description__c = description;
            miscAdj.PSA_BR_Eligible_Discount_Amount__c = 0;
            miscAdj.PSA_Daily_Rate__c = dailyRate;
            miscAdj.PSA_Total_Days_Worked__c = totalDaysWorked;
            miscAdj.PSA_Resource__c = resourceId;
            miscAdj.CurrencyISOCode = currencyCode;

            miscAdjsToInsert.add(miscAdj);
        }

        return miscAdj;
    }

    /**************************************************************************************
    // Name         : getInvoiceDate
    // Description  : Used to set the Effective Date for new Misc. Adjustments
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    public Date getInvoiceDate(Date timePeriodEndDate) {
        Date invoiceDate = Date.today();
        if (Date.today() > timePeriodEndDate) {
            invoiceDate = timePeriodEndDate;
        }
        return invoiceDate;
    }

    /**************************************************************************************
    // Name         : updateMiscellaneousAdjustmentBillingEventItemIds
    // Description  : Retrieves the Billing Event Item Id for newly created Billing Event
    //                  Items and updates newly inserted Miscellaneous Adjustments
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              :
    ***************************************************************************************/
    public void updateMiscellaneousAdjustmentBillingEventItemIds(Set<Id> projectIds) {
        Map<Id, Id> billingEventItemMap = new Map<Id, Id>();
        List<pse__Billing_Event_Item__c> beItems =
            [select Id, pse__Miscellaneous_Adjustment__c
                from pse__Billing_Event_Item__c
                where pse__Project__c = :projectIds
            ];
        for (pse__Billing_Event_Item__c beItem : beItems) {
            billingEventItemMap.put(beItem.pse__Miscellaneous_Adjustment__c, beItem.Id);
        }
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjsToInsert) {
            miscAdj.pse__Billing_Event_Item__c = billingEventItemMap.get(miscAdj.Id);
        }
        update miscAdjsToInsert;
    }


    /**************************************************************************************
    // Name         : CLASS: ExpenseSummaryByResourceAndAssignment
    // Description  : Summarizes expenses by Resource and Assignment. Used by LTA Billing Rule
    // Author       : CLD Partners
    // Revisions    : 2015-05-14  Klassen  (Initial Version)
    //              :
    ***************************************************************************************/
    class ExpenseSummaryByResourceAndAssignment {
        String KeyValue {get; set; }
        Id BillingEventId {get; set; }
        Decimal TotalAmount {get; set; }
        String AssignmentName {get; set; }

        /**************************************************************************************
        // Name         : buildMap
        // Description  : Create a map of expense amounts summarized by billing event,
        //                  resource, and assignment
        // Author       : CLD Partners
        // Revisions    : 2015-05-14  Klassen  (Initial Version)
        //              :
        ***************************************************************************************/
        Map<String, ExpenseSummaryByResourceAndAssignment> buildMap(
                List<pse__Billing_Event_Item__c> beiExpenses) {
            //Initialize the return value
            Map<String, ExpenseSummaryByResourceAndAssignment> expenseMap =
                    new Map<String, ExpenseSummaryByResourceAndAssignment>();
            List<ExpenseSummaryByResourceAndAssignment> expenses =
                    new List<ExpenseSummaryByResourceAndAssignment>(); //rollupTimecards(results);
            ExpenseSummaryByResourceAndAssignment expense = new ExpenseSummaryByResourceAndAssignment();

            //build the list which will be used to populate the map
            String previousKey;
            String currentKey;
            Boolean hasRecords = false;
            for (pse__Billing_Event_Item__c bei : beiExpenses) {
                //System.debug('ExpenseSummaryByResourceAndAssignment Rollup:' + bei);
                hasRecords = true;
                currentKey = bei.pse__Billing_Event__c + ':' +
                                bei.pse__Expense__r.pse__Resource__c + ':' +
                                bei.pse__Expense__r.pse__Assignment__c;
                //System.debug('ExpenseSummaryByResourceAndAssignment Rollup-Current Key:' + currentKey);

                if (previousKey != null && currentKey != previousKey) {
                    expenses.add(expense);
                }
                if (previousKey == null || currentKey != previousKey) {
                    expense = new ExpenseSummaryByResourceAndAssignment();
                    expense.KeyValue = currentKey;
                    expense.BillingEventId = bei.pse__Billing_Event__c;
                    expense.AssignmentName = bei.pse__Expense__r.pse__Assignment__r.Name;
                    expense.TotalAmount = 0.0;
                }
                if (bei.pse__Expense__r.pse__Expense_Date__c >= bei.pse__Expense__r.pse__Assignment__r.PSA_LTA_Start_Date__c) {
                    expense.TotalAmount += bei.pse__Expense__r.pse__Billing_Amount__c;
                }
                previousKey = currentKey;
            }

            //add the last record if any were found
            if (hasRecords==true) {
                expenses.add(expense);
            }

            //Now build the map
            for (ExpenseSummaryByResourceAndAssignment expenseItem : expenses) {
                expenseMap.put(expenseItem.KeyValue, expenseItem);
            }
            return expenseMap;
        }


    }
    /**************************************************************************************
    // Name         : CLASS: TimecardSummaryByKeyAndBillingLevel
    // Description  : Summarizes timecard hours, amounts, and days worked based on an array
    //                  of aggregate results.  Used by Billing Rules that are valid for a
    //                  subset of billing levels (BR 5, 6, 12, 13)
    // Author       : CLD Partners
    // Revisions    : 2015-03-01  Klassen  (Prototype)
    //              : 2015-04-28  Klassen  (Implementation)
    ***************************************************************************************/
    class TimecardSummaryByKeyAndBillingLevel {
        Id BillingEventId {get; set; }
        Id ProjectId {get; set; }
        Id AccountId {get; set; }
        Id ResourceId {get; set; }
        Decimal TotalAmount {get; set; }
        Decimal TotalHoursWorked {get; set; }
        Decimal TotalDaysWorked {get; set; }

        /**************************************************************************************
        // Name         : buildMap
        // Description  : Create a map of timecard hours/amounts/days summarized by billing event
        // Author       : CLD Partners
        // Revisions    : 2015-03-01  Klassen  (Prototype)
        //              : 2015-04-28  Klassen  (Implementation)
        //              : 2015-10-23  Klassen  Add logic to sum up days worked 1 result at a time
        ***************************************************************************************/
        Map<String, TimecardSummaryByKeyAndBillingLevel> buildMap(
                AggregateResult[] results, String keyName, Boolean daysWorkedExcluded) {
            //Initialize the return value
            Map<String, TimecardSummaryByKeyAndBillingLevel> timecardMap =
                    new Map<String, TimecardSummaryByKeyAndBillingLevel>();
            List<TimecardSummaryByKeyAndBillingLevel> timecards =
                    new List<TimecardSummaryByKeyAndBillingLevel>(); //rollupTimecards(results);
            TimecardSummaryByKeyAndBillingLevel timecard;

            //build the list which will be used to populate the map
            String previousKey;
            String currentKey;
            Boolean hasRecords = false;
            for (AggregateResult result : results) {
                //System.debug('TimecardSummaryByKeyAndBillingLevel Rollup:' + result);
                hasRecords = true;
                if (keyName == 'BillingEventAndResourceId') {
                    currentKey = (String)result.get('BillingEventId') + ':' + (String)result.get('ResourceId');
                } else {
                    currentKey = (String)result.get(keyName);
                }
                //System.debug('TimecardSummaryByKeyAndBillingLevel Rollup-Current Key:' + currentKey);

                if (previousKey == null) {
                    timecard = initTimecardWithBillingLevel(result);
                } else if (currentKey != previousKey) {
                    timecards.add(timecard);
                    timecard = initTimecardWithBillingLevel(result);
                }
                //timecard.ResourceCount += 1;
                timecard.TotalAmount += (Decimal)result.get('TotalAmount');
                timecard.TotalHoursWorked += (Decimal)result.get('TotalHours');
                if (daysWorkedExcluded == true) {
                    timecard.TotalDaysWorked += 1;
                } else {
                    timecard.TotalDaysWorked += (Decimal)result.get('TotalDays');
                }
                previousKey = currentKey;
            }

            //add the last record if any were found
            if (hasRecords==true) {
                timecards.add(timecard);
            }

            //Now build the map
            for (TimecardSummaryByKeyAndBillingLevel timecardItem : timecards) {
                if (keyName == 'BillingEventId') {
                    timecardMap.put(timecardItem.BillingEventId, timecardItem);
                } else if (keyName == 'BillingEventAndResourceId') {
                    timecardMap.put(timecardItem.BillingEventId + ':' + timecardItem.ResourceId, timecardItem);
                } else if (keyName == 'ProjectId') {
                    timecardMap.put(timecardItem.ProjectId, timecardItem);
                } else if (keyName == 'AccountId') {
                    timecardMap.put(timecardItem.AccountId, timecardItem);
                } else {
                    System.debug('Unknown Map Key: ' + keyName);
                }
            }
            return timecardMap;
        }

        /**************************************************************************************
        // Name         : initTimecardWithBillingLevel
        // Description  : Initialize a new "record" of timecard hours/amounts/days summarized by
        //                  billing event
        // Author       : CLD Partners
        // Revisions    : 2015-03-01  Klassen  (Prototype)
        //              :
        ***************************************************************************************/
        TimecardSummaryByKeyAndBillingLevel initTimecardWithBillingLevel(AggregateResult result) {
            TimecardSummaryByKeyAndBillingLevel timecardWithBillingLevel =
                new TimecardSummaryByKeyAndBillingLevel();
            timecardWithBillingLevel.ProjectId = (Id)result.get('ProjectId');
            timecardWithBillingLevel.BillingEventId = (Id)result.get('BillingEventId');
            timecardWithBillingLevel.AccountId = (Id)result.get('AccountId');
            timecardWithBillingLevel.ResourceId = (Id)result.get('ResourceId');
            timecardWithBillingLevel.TotalAmount = 0.0;
            timecardWithBillingLevel.TotalHoursWorked = 0.0;
            timecardWithBillingLevel.TotalDaysWorked = 0.0;
            return timecardWithBillingLevel;
        }
    }

    /**************************************************************************************
    // Name         : CLASS: DiscountAmounts
    // Description  : Contains Account Discount Values Needed for BR 13
    // Author       : CLD Partners
    // Revisions    : 2015-04-29  Klassen  (Initial Implementation)
    //              :
    ***************************************************************************************/
    class AccountDiscountAmount {
        Id AccountDiscountId {get; set; }
        Decimal CurrentDiscountTotal {get; set; }
        Decimal CurrentEligibleDiscountBillings {get; set; }

        /**************************************************************************************
        // Name         : addNewAmount
        // Description  : Update an existing instance or create a new one if none exists
        // Author       : CLD Partners
        // Revisions    : 2015-04-29  Klassen  (Initial Implementation)
        //              :
        ***************************************************************************************/
        AccountDiscountAmount addNewAmount(List<AccountDiscountAmount> accountDiscountAmounts,
                Id accountDiscountId, Decimal discountAmount, Decimal discountEligibleBillings) {
            AccountDiscountAmount currentAccountDiscountAmount;

            if (accountDiscountAmounts != null) {
                //Loop through the list, looking for the current account discount id
                // if found, update the value.  if not found, create a new instance of the class
                for (AccountDiscountAmount accountDiscountAmount : accountDiscountAmounts) {
                    if (accountDiscountAmount.AccountDiscountId == accountDiscountId) {
                        currentAccountDiscountAmount = accountDiscountAmount;
                        break;
                    }
                }
            }
            if (currentAccountDiscountAmount != null) {
                currentAccountDiscountAmount.CurrentDiscountTotal += discountAmount;
                currentAccountDiscountAmount.CurrentEligibleDiscountBillings += discountEligibleBillings;
            } else {
                currentAccountDiscountAmount = new AccountDiscountAmount();
                currentAccountDiscountAmount.AccountDiscountId = accountDiscountId;
                currentAccountDiscountAmount.CurrentDiscountTotal = discountAmount;
                currentAccountDiscountAmount.CurrentEligibleDiscountBillings = discountEligibleBillings;
            }

            return currentAccountDiscountAmount;
        }

        /**************************************************************************************
        // Name         : getCurrentAccountDiscountAmount
        // Description  : Retrieve the existing account discount amount
        // Author       : CLD Partners
        // Revisions    : 2015-04-29  Klassen  (Initial Implementation)
        //              :
        ***************************************************************************************/
        Decimal getCurrentAccountDiscountAmount(List<AccountDiscountAmount> accountDiscountAmounts,
                Id accountDiscountId) {
            Decimal currentAccountDiscountAmount = 0.0;

            if (accountDiscountAmounts != null) {
                //Loop through the list, looking for the current account discount id
                // if found, set the return value.
                for (AccountDiscountAmount accountDiscountAmount : accountDiscountAmounts) {
                    if (accountDiscountAmount.AccountDiscountId == accountDiscountId) {
                        currentAccountDiscountAmount = accountDiscountAmount.CurrentDiscountTotal;
                        break;
                    }
                }
            }

            return currentAccountDiscountAmount;
        }

        /**************************************************************************************
        // Name         : getCurrentAccountDiscountEligibleBillingsAmount
        // Description  : Retrieve the existing account discount amount
        // Author       : CLD Partners
        // Revisions    : 2015-05-07  Klassen  (Initial Implementation)
        //              :
        ***************************************************************************************/
        Decimal getCurrentAccountDiscountEligibleBillingsAmount(List<AccountDiscountAmount> accountDiscountAmounts,
                Id accountDiscountId) {
            Decimal currentAccountDiscountAmount = 0.0;

            if (accountDiscountAmounts != null) {
                //Loop through the list, looking for the current account discount id
                // if found, set the return value.
                for (AccountDiscountAmount accountDiscountAmount : accountDiscountAmounts) {
                    if (accountDiscountAmount.AccountDiscountId == accountDiscountId) {
                        currentAccountDiscountAmount = accountDiscountAmount.CurrentEligibleDiscountBillings;
                        break;
                    }
                }
            }

            return currentAccountDiscountAmount;
        }
    }
}