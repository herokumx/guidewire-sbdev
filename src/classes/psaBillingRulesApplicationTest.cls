@isTest(seeAllData=false)
private class psaBillingRulesApplicationTest {
	static User resourceUser;
	static User managerUser;
	static Contact resourceContact;
	static Contact managerContact;
	static pse__Region__c testR;
	static pse__Practice__c testP;
	static pse__Grp__c testG;
	static Account testAccount;
	static PSA_Entity__c entity;
	static PSA_Department__c department;
	static pse__Proj__c project;
	static pse__Time_Period__c timePeriod;
	static pse__Billing_Event_Batch__c testBEB;
	static pse__Milestone__c overCapMilestone;
	static pse__Milestone__c implementationMilestone;
	static pse__Project_Phase__c projectPhase;
	static pse__Assignment__c testAssignment;
	static pse__Timecard_Header__c tcHeader;
	static pse__Expense_Report__c expenseRptHeader;
	static pse__Expense__c expense;
	static pse__Billing_Event__c billingEvent;
	static pse__Billing_Event_Item__c billingEventItem1;
	static PSA_Account_Discount__c accountDiscount;

	@isTest static void MinimumHoursTest() {
		System.debug('Starting MinimumHoursTest');
		/*
		 1. Create Users 
		 2. Create Contacts
		 3. Create RPG and Account	 
		 4. Create Project (don't require assignments, Exclude From Billing=false, Billing Rules Accepted=true, Min. Hours Applies = true and Min. Hours = 20)
		 5. Create Expense?
		 6. Create Timecard
		 7. Create Time Period (to match Timecard Date)
		 8. Create Billing Event Batch (account matches Project Account, Time Period matches test Time Period)
		 7. Create Billing Event (related BEB = test Billing Event Batch)
		 8. Create Billing Event Item for Timecard
		 9. Update Timecard with Billing Event Item?
		 10. Call Billing Rules Application code
		*/

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_BR_Minimum_Billed_Hours_Applies__c = true;
        project.PSA_BR_Minimum_Billed_Hours_Monthly__c = 10;
        project.PSA_BR_Minimum_Hours_Bill_Rate__c = 20;
        
        project.PSA_BR_Services_Cap_Flat_Applies__c = true;
		project.PSA_BR_Services_Cap_Amt__c = 100;
		
		project.PSA_BR_Holdback_Applies__c = true;
		project.PSA_BR_Holdback_Pct__c = 0.10;
		project.PSA_BR_Holdback_End_Date__c = Date.newInstance(2015, 2, 28);
		
		project.PSA_BR_Account_Discount_Applies__c = true; 
		project.PSA_BR_Account_Discount__c = accountDiscount.Id;

		project.PSA_BR_Expense_Cap_Pct_Applies__c = true;
		project.PSA_BR_Expense_Cap_Pct__c = 1;

		project.PSA_BR_Expense_Cap_Flat_Applies__c = true;
		project.PSA_BR_Expense_Cap_Amt__c = 1.00;

        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

		//Create timecard and billing event item (update timecard with BEI)
		Date tcDate = Date.newInstance(2015, 1, 9);
		Date tcStartDate = tcDate.toStartOfWeek();
		tcHeader = createTimecardHeader(project.Id, resourceContact.Id, testAssignment.Id, tcDate, 8, projectPhase, implementationMilestone.Id);
		
		expenseRptHeader = psaTestUtils.createTestExpenseReport('test', project.Id, resourceContact.Id, true);
		expense = psaTestUtils.createTestExpenseOnReportWithAssignment(expenseRptHeader.Id, project.Id, resourceContact.Id, 10.00, 'Meals - Self - Lunch', 
				tcDate, testAssignment.Id, true);
		expense.pse__Billable__c = true;
		expense.pse__Status__c = 'Approved';
		expense.pse__Submitted__c = true;
		expense.pse__Approved__c = true;
		expense.pse__Include_In_Financials__c = true;
		update expense;

		List<pse__Billing_Event__c> billingEvents = [select Id from pse__Billing_Event__c];
		System.debug('BE Size before billing: ' + billingEvents.size());
		pse.APIBillingService.BillingContextGenerate bcg = new pse.APIBillingService.BillingContextGenerate();
		bcg.projectID = project.Id;
		bcg.regionID = testR.Id;
		bcg.groupID = null;
		bcg.practiceID = null;
		bcg.includePriorPeriods = false;
		bcg.useFlexiblePeriods = false;
		//bcg.cutoff = Date.newInstance(2015, 1, 31);
		bcg.timePeriodID = timeperiod.Id;
		
		system.debug('****** THE VALUE OF bcg right before calling = '+ bcg);
		pse.APICommonsService.BatchStatus bs = pse.APIBillingService.generate(bcg);
		system.assertEquals(bs.status,'Batched');
		system.assert(bs.jobId != null);

		Test.stopTest();

    	//Add or Update PSA Project Balance records
    	//get the newly created BE id
    	Id beId = ([select Id from pse__Billing_Event__c where pse__Project__c = :project.Id]).Id;
    	Set<Id> beIds = new Set<Id>{beId};
    	Set<Id> projectIds = new Set<Id>{project.Id};
    	psaRefreshProjectBillingBalances.refreshBillingBalances(beIds, projectIds, null);

		billingEvents = [select Id from pse__Billing_Event__c];
		System.debug('BE Size after billing: ' + billingEvents.size());
		System.debug('BE: ' + billingEvents[0]);		
	}

	@isTest static void ExpensePercentOfServicesTest() {
		System.debug('Starting ExpensePercentOfServicesTest');

		//Create users, contacts, rpg, account, and project
		setupTestData();
		//System.debug(LoggingLevel.WARN, 'SOQL Queries after setupTestData(): ' + Limits.getQueries());

        //set billing rules
        project.PSA_BR_Minimum_Billed_Hours_Applies__c = true;
        project.PSA_BR_Minimum_Billed_Hours_Monthly__c = 20;
        project.PSA_BR_Minimum_Hours_Bill_Rate__c = 200;
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
		project.PSA_BR_Expenses_Billing_Type__c = 'Percent of Services';
		project.PSA_BR_Billing_Levels_for_Expense_Pct__c = '100; 105; 110; 120; 130; 140';
		project.PSA_BR_Expense_Pct_of_Services__c = 10.0;
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;
		//System.debug(LoggingLevel.WARN, 'SOQL Queries after update project: ' + Limits.getQueries());

		//Create approved expenses that will be used to test the LTA calculation for non-billable expenses on Projects with Expenses Billing Type != "As Incurred"
		expenseRptHeader = psaTestUtils.createTestExpenseReport('test', project.Id, resourceContact.Id, true);
		//System.debug(LoggingLevel.WARN, 'SOQL Queries after expenseRptHeader(): ' + Limits.getQueries());

	    //Update the Assignment to allow for inclusion in LTA Calculations
		testAssignment.PSA_LTA_Eligible__c = true;
		testAssignment.PSA_LTA_Start_Date__c = Date.newInstance(2015, 1, 1);
		testAssignment.PSA_LTA_Billable__c = true;
		update testAssignment;
		//System.debug(LoggingLevel.WARN, 'SOQL Queries after update testAssignment(): ' + Limits.getQueries());

		Date tcDate = Date.newInstance(2015, 1, 9);

		expense = psaTestUtils.createTestExpenseOnReportWithAssignment(expenseRptHeader.Id, project.Id, resourceContact.Id, 10.00, 'Meals - Self - Lunch', 
				tcDate, testAssignment.Id, true);
		expense.pse__Billable__c = false;
		expense.pse__Status__c = 'Approved';
		expense.pse__Submitted__c = true;
		expense.pse__Approved__c = true;
		expense.pse__Include_In_Financials__c = true;
		update expense;
		System.debug(LoggingLevel.WARN, 'SOQL Queries after update new expense(): ' + Limits.getQueries());


		Test.startTest();

		//Create timecard and billing event item (update timecard with BEI)
		Date tcStartDate = tcDate.toStartOfWeek();
		tcHeader = createTimecardHeader(project.Id, resourceContact.Id, testAssignment.Id, tcDate, 8, projectPhase, implementationMilestone.Id);
		//System.debug(LoggingLevel.WARN, 'SOQL Queries after createTimecardHeader(): ' + Limits.getQueries());
		
		pse__Expense__c expense2 = psaTestUtils.createTestExpenseOnReportWithAssignment(expenseRptHeader.Id, project.Id, resourceContact.Id, 10.00, 'Meals - Self - Lunch', 
				tcDate, testAssignment.Id, true);
		expense2.pse__Billable__c = true;
		expense2.pse__Status__c = 'Approved';
		expense2.pse__Submitted__c = true;
		expense2.pse__Approved__c = true;
		expense2.pse__Include_In_Financials__c = true;
		expense2.CurrencyIsoCode = 'EUR';
		update expense2;
		System.debug(LoggingLevel.WARN, 'SOQL Queries after update 2ND new expense(): ' + Limits.getQueries());
        
        List<pse__Billing_Event__c> billingEvents = [select Id from pse__Billing_Event__c];
		System.debug('BE Size before billing: ' + billingEvents.size());
		pse.APIBillingService.BillingContextGenerate bcg = new pse.APIBillingService.BillingContextGenerate();
		bcg.projectID = project.Id;
		bcg.regionID = testR.Id;
		bcg.groupID = null;
		bcg.practiceID = null;
		bcg.includePriorPeriods = false;
		bcg.useFlexiblePeriods = false;
		//bcg.cutoff = Date.newInstance(2015, 1, 31);
		bcg.timePeriodID = timeperiod.Id;
		
		system.debug('****** THE VALUE OF bcg right before calling = '+ bcg);
		pse.APICommonsService.BatchStatus bs = pse.APIBillingService.generate(bcg);
		system.assertEquals(bs.status,'Batched');
		system.assert(bs.jobId != null);
		System.debug(LoggingLevel.WARN, 'SOQL Queries after billing event generate: ' + Limits.getQueries());

		Test.stopTest();

		billingEvents = [select Id, Name, pse__Summary_Amount__c from pse__Billing_Event__c];
		System.debug('BE Size after billing: ' + billingEvents.size());
		System.debug('BE: ' + billingEvents[0]);
		List<pse__Billing_Event_Item__c> beItems = [Select Id, Name, pse__Amount__c, pse__Date__c, pse__Category__c From pse__Billing_Event_Item__c Where pse__Billing_Event__c = :billingEvents[0].Id];
		System.debug('BE Items: ' + beItems);

		System.debug(LoggingLevel.WARN, 'SOQL Queries after all code: ' + Limits.getQueries());
	}
	
	@isTest static void ExpenseFlatAmountPerDayTest() {
		System.debug('Starting ExpenseFlatAmountPerDayTest');
		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
		project.PSA_BR_Expenses_Billing_Type__c = 'Flat Amount per Day';
		project.PSA_BR_Billing_Levels_for_Expense_Amt__c = '100; 105; 110; 120; 130; 140';
		project.PSA_BR_Expense_Amt_Per_Day__c = 100.00;
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

		//Create timecard and billing event item (update timecard with BEI)
		Date tcDate = Date.newInstance(2015, 1, 9);
		Date tcStartDate = tcDate.toStartOfWeek();
		tcHeader = createTimecardHeader(project.Id, resourceContact.Id, testAssignment.Id, tcDate, 8, projectPhase, implementationMilestone.Id);
		
		List<pse__Billing_Event__c> billingEvents = [select Id from pse__Billing_Event__c];
		System.debug('BE Size before billing: ' + billingEvents.size());
		pse.APIBillingService.BillingContextGenerate bcg = new pse.APIBillingService.BillingContextGenerate();
		bcg.projectID = project.Id;
		bcg.regionID = testR.Id;
		bcg.groupID = null;
		bcg.practiceID = null;
		bcg.includePriorPeriods = false;
		bcg.useFlexiblePeriods = false;
		//bcg.cutoff = Date.newInstance(2015, 1, 31);
		bcg.timePeriodID = timeperiod.Id;
		
		system.debug('****** THE VALUE OF bcg right before calling = '+ bcg);
		pse.APICommonsService.BatchStatus bs = pse.APIBillingService.generate(bcg);
		system.assertEquals(bs.status,'Batched');
		system.assert(bs.jobId != null);

		Test.stopTest();

		billingEvents = [select Id from pse__Billing_Event__c];
		System.debug('BE Size after billing: ' + billingEvents.size());
	}

	private static void setupTestData() {
		//** load test data files from static resources
		Test.loadData(appirio_core__Config_Group__c.SObjectType, 'TestDataConfigGroups');
		Test.loadData(appirio_core__Config_Option__c.SObjectType, 'TestDataConfigOptions');
		Test.loadData(appirio_core__Config_Value__c.SObjectType, 'TestDataConfigValues');
		psaTestUtils.createPSABillingCustomSetting();

        Try {
            psaTestUtils.disablePsaTriggers();
        } Catch (Exception ex) {
            System.debug('Failed to disable PSA_Triggers');
        }
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        testR = psaTestUtils.createTestRegion('Corporate');
        testP = psaTestUtils.createTestPractice('Corporate');
        testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        testAccount = psaTestUtils.createTestAccount('Test Account', '12345');
        testAccount.Participant_id__c = '1234';
        testAccount.BillingStreet = '123 Sesame Street';
        testAccount.BillingCity = 'Sesame City';
        testAccount.BillingState = 'CA';
        testAccount.BillingPostalCode = '90210';
        testAccount.BillingCountry = 'USA';
        update testAccount;

        accountDiscount = psaTestUtils.createTestAccountDiscount(testAccount.Id, 100000.00, Date.newInstance(2015, 2, 28), 0.10, true);

        entity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager
        resourceUser = psaTestUtils.createTestUser('UserCLD1', 'UserCLD1@tuser.com', 'UserCLD1', 'test', 'UserCLD1@tuser.com', 'UserCLD1');
        resourceContact = psaTestUtils.createTestResource(resourceUser, testR, testP, testG);
        resourceContact.PSA_Fully_Loaded_Cost_Rate__c = 123;
        resourceContact.PSA_Resource_Entity__c = entity.id;
        resourceContact.MailingCity = 'Ellicott City';
        resourceContact.MailingState = 'MD';
        resourceContact.MailingPostalCode = '21042';
        resourceContact.MailingCountry = 'USA';
        update resourceContact;

        managerUser = psaTestUtils.createTestUser('UserCLD2', 'UserCLD2@tuser.com', 'UserCLD2', 'test', 'UserCLD2@tuser.com', 'UserCLD2');
        managerContact = psaTestUtils.createTestResource(managerUser, testR, testP, testG);
        
        resourceUser.ManagerId = managerUser.id;
        update resourceUser;

        //Grant all permission controls to the current user
        psaTestUtils.grantAllPermissionControls(UserInfo.getUserId(), testR.Id);

        //Create the project and assignment and assure that locations were created
        project = createTestProjectInProgress('Test Project', testAccount, testR, testP, testG, null, resourceContact, resourceUser, 
        			'Draft', true);
        //update project;
        System.debug('Project: ' + project);
        //project.PSA_Time_Approval_Method__c = 'Project Manager';
        //project.PSA_Milestone_Required__c = false;
        //project.PSA_Billing_Legal_Entity__c = entity.id;
        //project.PSA_Customer_Account__c = account.id;

        System.debug('Project: ' + project);

        Date startDate = Date.newInstance(2015, 1, 1);
        Date endDate = Date.newInstance(2015, 1, 31);
        Double seasonalityFactor = 0.90;
        timePeriod = psaTestUtils.createTestTimePeriod('Test Period', seasonalityFactor, startDate, endDate, 'Month', true);

        projectPhase = new pse__Project_Phase__c();
        projectPhase.name = 'Creation';
        projectPhase.pse__Start_Date__c = Date.newInstance(2015, 1, 1);
        projectPhase.pse__End_Date__c = Date.today()+90;
        projectPhase.pse__Project__c = project.id;
        insert projectPhase;

        overCapMilestone = psaTestUtils.createTestMilestone('Excess (Non-billable) Time over Daily Cap', project, false, false, 80);
        implementationMilestone = psaTestUtils.createTestMilestone('Implementation', project, false, false, 80);
        //pse__Milestone__c notOver2 = psaTestUtils.createTestMilestone('Implementation2', project, false, false, 80);
	
        //Create Assignment which is needed to calc. the min. hours bill rate
        testAssignment = createTestAssignment(project, resourceContact, 'Project Manager', Date.newInstance(2015, 1, 1), Date.newInstance(2015, 3, 31), 100.00);
	
	} 
	
    private static pse__Timecard_Header__c createTimecardHeader (Id projId,  Id resourceId, Id assignmentId, Date inputDate, Decimal hours, 
    		pse__Project_Phase__c phase, Id milestoneId) {
        
        pse__Timecard_Header__c timecardHeader = psaTestUtils.initTestTimecardHeader(projId, resourceId, assignmentId, inputDate, hours, phase);
        
        timecardHeader.pse__Bill_Rate__c = 100;
        timecardHeader.pse__Billable__c = true;
        timecardHeader.pse__Milestone__c = milestoneId;
        timecardHeader.pse__Submitted__c = true;
        timecardHeader.pse__Approved__c = true;
        timecardHeader.pse__Status__c = 'Approved';
        timecardHeader.pse__Include_In_Financials__c = true;

        insert timecardHeader;
        return timecardHeader;
    }

    private static pse__Billing_Event__c createTestBillingEvent(Id projectId, String status, Date eventDate, String currencyCode, Double amount, 
    		Id billingEventBatchId, boolean toInsert){
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = projectId;
        event.pse__Status__c = status;
        event.pse__Date__c = eventDate;
        event.currencyIsoCode = currencyCode;
        event.PSA_Current_Billing_Amount__c = amount;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        event.pse__Billing_Event_Batch__c = billingEventBatchId;
        if(toInsert){
            insert event;
        }
        return event;
    }

    private static pse__Proj__c createTestProjectInProgress(String projectName, Account a, pse__Region__c region, pse__Practice__c practice, pse__Grp__c projGroup, 
    		Opportunity opp, Contact pm, User user, String billingRulesStatus, Boolean excludeFromBilling) {
        pse__Proj__c testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        testProject.pse__Account__c = a.id;
        testProject.PSA_Customer_Account__c = a.id;
        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Start_Date__c = Date.newInstance(2015, 1, 1);
        testProject.pse__End_Date__c = Date.today().addDays(365);
        testProject.PSA_Director_Review_Complete__c = true;
        testProject.PSA_PM_Review_Complete__c = true;
        testProject.PSA_Ops_Review_Complete__c = true;
        testProject.pse__Stage__c = 'In Progress';
        testProject.pse__Project_Manager__c = pm.id;
        testProject.PSA_Director__c = pm.id;
        testProject.PSA_PIA__c = pm.id;
        testProject.PSA_CIM__c = pm.id;
        testProject.psa_VP__c = pm.id;
        testProject.PSA_BR_Billing_Rules_Status__c = billingRulesStatus;
        testProject.PSA_PO_Number__c = '12345';
        testProject.pse__Is_Active__c = true;
        testProject.pse__Is_Billable__c = true;
        //testProject.pse__Allow_Timecards_Without_Assignment__c = true;
        //testProject.pse__Allow_Expenses_Without_Assignment__c = true;
        testProject.pse__Project_Type__c = 'Customer Project';
        testProject.PSA_Forecast_Category__c = 'Committed';
        testProject.PSA_Expense_Approval_Method__c = 'Project Manager';
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Daily_Cap__c = 8;
        testProject.PSA_CDO_Email__c = 'cdo@guidewire.com';
        testProject.PSA_Services_Product__c = 'Implementation';
        testProject.PSA_Product_Line__c = 'BillingCenter';
        testProject.PSA_VSOE_Type__c = 'Not Stand Alone Sale';
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        
        testProject.pse__Billing_Type__c = 'Time and Materials';
        testProject.pse__Include_In_Forecasting__c = True;
        testProject.PSA_Include_in_Billing_Forecast__c  = True;
        testProject.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral Duration';
        testProject.PSA_Revenue_Recognition_Model__c = 'As Delivered';
        testProject.PSA_Rate_Classification__c = 'Level Rate';
        testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.PSA_Applicable_SOW_Fully_Executed__c = true;
        testProject.PSA_Pre_SOW_Status__c = 'Pre-SOW Start Approved';
        testProject.pse__Exclude_From_Billing__c = excludeFromBilling;
        testProject.pse__Closed_for_Time_Entry__c = false;
        testProject.pse__Closed_for_Expense_Entry__c = false;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        Account_Contact__c shipTo = new Account_Contact__c();
        Account_Contact__c billTo = new Account_Contact__c();

        PSA_Department__c dept = new PSA_Department__c();
        dept.Name = 'Test Department';
        dept.PSA_Department_Code__c = '1425';
        dept.PSA_PS_Department__c = true;
        insert dept;

        testProject.PSA_Department__c = dept.id;

        shipTo.Account__c = testProject.PSA_Customer_Account__c;
        billTo.Account__c = testProject.pse__Account__c;
        shipTo.Contact__c = pm.id;
        shipTo.Participant_Account__c = testProject.PSA_Customer_Account__c;
        billTo.Contact__c = pm.id;
        billTo.Participant_Account__c = testProject.pse__Account__c;
        shipto.Type__c = 'Ship To';
        billTo.Type__c = 'Bill To';
        List<Account_Contact__c> acs = new List<Account_Contact__c>();
        acs.add(billTo);
        acs.add(shipTo);

        insert acs;

        testProject.PSA_Bill_To_Contact__c = billTo.id;
        testProject.PSA_Ship_To_Contact__c = shipTo.id;
        testProject.PSA_Billing_Detail_Template__c = 'Daily';
        testProject.PSA_Revenue_Deferral_Duration__c = 2;

        testProject.CurrencyIsoCode = 'USD';
        if(opp != null)
        {
            testProject.pse__Opportunity__c = opp.Id;
        }

        System.debug('Project in Progress: ' + testProject);

        insert testProject;
        return testProject;
    }

    public static pse__Assignment__c createTestAssignment(pse__Proj__c proj, Contact resource, String resourceRole, Date startDate, Date endDate, Decimal billRate)
    {
        // Create an initial assignment schedule, 30 days out
        pse__Schedule__c schedule = new pse__Schedule__c();
        schedule.pse__Start_Date__c = startDate;
        schedule.pse__End_Date__c = endDate;
        schedule.pse__Monday_Hours__c = 8;
        schedule.pse__Tuesday_Hours__c = 8;
        schedule.pse__Wednesday_Hours__c = 8;
        schedule.pse__Thursday_Hours__c = 8;
        schedule.pse__Friday_Hours__c = 8;
        insert schedule;

        // Get top most Region for the Permission Control
        id regionId = [select id from pse__Region__c where pse__Hierarchy_Depth__c = 0 limit 1].id;
        system.Assert(regionId != null, 'No Regions configured.   Please contact your PSA Admin');

        // Create the assignment and associate it with the project
        pse__Assignment__c assignment = new pse__Assignment__c(Name='Test Assignment');
        assignment.pse__Is_Billable__c = true;
        assignment.pse__Project__c = proj.Id;
        assignment.pse__Resource__c = resource.Id;
        assignment.pse__Schedule__c = schedule.Id;
        assignment.pse__Bill_Rate__c = billRate;
        assignment.pse__Role__c = resourceRole;
        assignment.PSA_Override_Bill_Rate__c = true;
        assignment.PSA_Rate_Needs_Review__c = false;
        assignment.pse__Closed_for_Time_Entry__c = false;
        assignment.PSA_Billing_Level__c = '120';
        assignment.PSA_LTA_Eligible__c = true;
        assignment.PSA_LTA_Billable__c = true;
        assignment.PSA_LTA_Start_Date__c =  Date.newInstance(2015, 1, 1);
        upsert assignment;

        return assignment;
    }

}