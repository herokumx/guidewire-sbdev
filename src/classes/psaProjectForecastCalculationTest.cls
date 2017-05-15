@isTest(seeAllData=false) 
private class psaProjectForecastCalculationTest {
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
	static pse__Resource_Request__c testResourceRequest;
	static pse__Timecard_Header__c tcHeader;
	static pse__Expense_Report__c expenseRptHeader;
	static pse__Expense__c expense;
	static pse__Billing_Event__c billingEvent;
	static pse__Billing_Event_Item__c billingEventItem1;
	static PSA_Account_Discount__c accountDiscount;
	static pse__Budget__c testBudget;

	@isTest static void BasicForecastTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_BR_Minimum_Billed_Hours_Applies__c = true;
		project.PSA_BR_Minimum_Hours_Bill_Rate__c = 100;
        project.PSA_BR_Minimum_Billed_Hours_Monthly__c = 20;
        
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

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

		Test.stopTest();

	}
	
	@isTest static void ExpensePctOfServicesTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
		project.PSA_BR_Expenses_Billing_Type__c = 'Percent of Services';
		project.PSA_BR_Billing_Levels_for_Expense_Pct__c = '100; 105; 110; 120; 130; 140';
		project.PSA_BR_Expense_Pct_of_Services__c = 10.0;
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

		Test.stopTest();
	}	

	@isTest static void ExpenseFlatAmountTest() {
		psaTestUtils.disablePsaTriggers();

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

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

		Test.stopTest();
	}	

	@isTest static void RatableTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_BR_Minimum_Billed_Hours_Applies__c = true;
		project.PSA_BR_Minimum_Hours_Bill_Rate__c = 100;
        project.PSA_BR_Minimum_Billed_Hours_Monthly__c = 20;
        
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

		project.PSA_Revenue_Forecast_Model__c = 'Ratable';
		project.PSA_Revenue_Ratable_Period_Counts__c = '12';
		//project.PSA_Revenue_Deferral_Duration__c = ;

        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

		Test.stopTest();
	}

    @isTest static void AsDeliveredNoDeferralTest() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_Revenue_Forecast_Model__c = 'As Delivered - No Deferral';
        //project.PSA_Revenue_Deferral_End_Date__c = Date.addDays(120);
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

        Test.stopTest();
    }

    @isTest static void AsDeliveredHoldbackTest() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.PSA_BR_Holdback_Applies__c = true;
        project.PSA_BR_Holdback_Pct__c = 0.10;
        project.PSA_BR_Holdback_End_Date__c = Date.today().addDays(365);
        
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_Revenue_Forecast_Model__c = 'As Delivered - Holdback';
        //project.PSA_Revenue_Deferral_End_Date__c = Date.addDays(120);
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

        Test.stopTest();
    }

    @isTest static void percentCompleteTest() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        //project.PSA_BR_Holdback_Applies__c = true;
        //project.PSA_BR_Holdback_Pct__c = 0.10;
        //project.PSA_BR_Holdback_End_Date__c = Date.today().addDays(365);
        
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_Revenue_Forecast_Model__c = 'Percent Complete';
        //project.PSA_Revenue_Deferral_End_Date__c = Date.addDays(120);
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

        Test.stopTest();
    }

    @isTest static void AsDeliveredFixedDeferralEndDateTest() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral End Date';
        project.PSA_Revenue_Deferral_End_Date__c = Date.today().addDays(120);
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

        Test.stopTest();
    }

    @isTest static void AsDeliveredSubjecttoRefund() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_Revenue_Forecast_Model__c = 'As Delivered - Subject to Refund';
        project.PSA_Revenue_Refund_Percent__c = 10;
        project.PSA_Revenue_Refund_Expiration_Date__c = Date.newInstance(2025, 1, 1);
        project.PSA_Revenue_Deferral_End_Date__c = Date.today().addDays(120);
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        List<Id> projectIds = new List<Id>();
        projectIds.add(project.Id);

        psaProjectForecastCalculation.calculateBillingForecast(projectIds);
        psaProjectForecastCalculation.calculateRevenueForecast(projectIds);

        Test.stopTest();
    }

    @isTest static void refreshBillingAndReveneueForecasts() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_BR_Expenses_Billing_Type__c = 'Percent of Services';
        project.PSA_BR_Billing_Levels_for_Expense_Pct__c = '100; 105; 110; 120; 130; 140';
        project.PSA_BR_Expense_Pct_of_Services__c = 10.0;
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        psaProjectForecastCalculation.refreshBillingForecast(project.Id);
        psaProjectForecastCalculation.refreshRevenueForecast(project.Id);
        psaProjectForecastCalculation.refreshBillingAndRevenueForecast(project.Id);

        Test.stopTest();
    }   

    @isTest static void scheduleBillingAndReveneueForecasts() {
        psaTestUtils.disablePsaTriggers();

        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //set billing rules
        project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Exclude_From_Billing__c = false;
        project.PSA_BR_Expenses_Billing_Type__c = 'Percent of Services';
        project.PSA_BR_Billing_Levels_for_Expense_Pct__c = '100; 105; 110; 120; 130; 140';
        project.PSA_BR_Expense_Pct_of_Services__c = 10.0;
        project.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        update project;

        Datetime sysTime = System.now().addSeconds( 10 );
        String cronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        system.schedule('PSA Project Forecast Refresh - 1 time' + sysTime, cronExpression, new psaProjectForecastSchedulable() );

        Test.stopTest();
    }   

	private static void setupTestData() {
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
        resourceUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        resourceContact = psaTestUtils.createTestResource(resourceUser, testR, testP, testG);
        resourceContact.PSA_Fully_Loaded_Cost_Rate__c = 123;
        resourceContact.PSA_Resource_Entity__c = entity.id;
        resourceContact.MailingCity = 'Ellicott City';
        resourceContact.MailingState = 'MD';
        resourceContact.MailingPostalCode = '21042';
        resourceContact.MailingCountry = 'USA';
        update resourceContact;

        managerUser = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        managerContact = psaTestUtils.createTestResource(managerUser, testR, testP, testG);
        
        resourceUser.ManagerId = managerUser.id;
        update resourceUser;

        //Grant all permission controls to the current user
        psaTestUtils.grantAllPermissionControls(UserInfo.getUserId(), testR.Id);

        //Create the project and assignment and assure that locations were created
        project = createTestProjectInProgress('Time Off', testAccount, testR, testP, testG, null, resourceContact, resourceUser, 
        			'Draft', true);
        System.debug('Project: ' + project);

        //Create a budget with an expense amount
        createTestBudget(project.Id, 50000);
        
        //Date startDate = Date.today(2017, 1, 1);
        //Date endDate = Date.newInstance(2015, 1, 31);
        //Double seasonalityFactor = 0.90;
        //timePeriod = psaTestUtils.createTestTimePeriod('Test Period', seasonalityFactor, startDate, endDate, 'Month', true);
        List<pse__Time_Period__c> tps = [select Id from pse__Time_Period__c];
        System.debug('TP Size before:' + tps.size());
        createTestTimePeriods();
        tps.clear();
        tps = [select Id from pse__Time_Period__c];
        System.debug('TP Size after:' + tps.size());

        //Create Assignment 
        testAssignment = createTestAssignment(project, resourceContact, 'Project Manager', Date.newInstance(2015, 1, 1), Date.newInstance(2018, 1, 31), 100.00);
		//Create Resource Request
		testResourceRequest = psaTestUtils.createTestResourceRequest('test', testR.Id, Date.newInstance(2015, 1, 1), Date.newInstance(2018, 1, 31), project.Id, 
				'Business Architect', '100', 1000, true);
		
        //Create the needed records for Rev Rec (native PSA)
        //createTestRevRecTemplate();

        //Create the PSA Forecast custom setting with default values
        psaTestUtils.createPSAForecastCustomSetting();

	} 
/*
    private static ffrr__Settings__c createTestRevRecSettingsLevel2() {
        ffrr__Settings__c rrSettingsParent = createTestRevRecSettingsLevel1();

        ffrr__Settings__c rrSettings = new ffrr__Settings__c();
        rrSettings.ffrr__ActiveField__c = 'PSA_Include_in_Forecast__c';
        rrSettings.ffrr__ActiveValue__c = 'TRUE';
        rrSettings.ffrr__BalanceSheetAccount__c = '9999';
        rrSettings.ffrr__CompletedField__c = 'PSA_Include_in_Forecast__c';
        rrSettings.ffrr__CompletedValue__c = 'FALSE';
        rrSettings.ffrr__Currency__c = 'CurrencyIsoCode';
        rrSettings.ffrr__Description__c = 'Name';
        rrSettings.ffrr__EndDate__c = 'PSA_For_Month_Ending__c';
        rrSettings.ffrr__FixedBalanceSheetAccountCode__c = true;
        rrSettings.ffrr__FixedCostCenterCode__c = true;
        rrSettings.ffrr__FixedIncomeStatementAccountCode__c = true;
        rrSettings.ffrr__ForecastTransactionLineRelationship__c = 'PSA_Project_Forecast__c';
        rrSettings.ffrr__IncludeActiveValue__c = 'Include';
        rrSettings.ffrr__IncludeCompletedValue__c = 'Exclude';
        rrSettings.ffrr__IncomeStatementAccount__c = '9999';
        rrSettings.ffrr__Object__c = 'PSA_Project_Forecast__c';
        rrSettings.ffrr__ParentSettings__c = rrSettingsParent.Id;
        rrSettings.ffrr__PrimaryRelationship__c = 'PSA_Project__c';
        rrSettings.ffrr__SettingsLevel__c = 'Level 2';
        rrSettings.ffrr__SettingsType__c = 'Forecast';
        rrSettings.ffrr__StartDate__c = 'PSA_For_Month_Starting__c';
        rrSettings.ffrr__TotalRevenue__c = 'PSA_Forecast_Revenue__c';
        rrSettings.Name = 'Guidewire Project Forecast Settings';

        insert rrSettings;
        return rrSettings;
    }

    private static ffrr__Settings__c createTestRevRecSettingsLevel1() {
        ffrr__Settings__c rrSettings = new ffrr__Settings__c();
        rrSettings.ffrr__ActiveField__c = 'pse__Is_Active__c';
        rrSettings.ffrr__ActiveValue__c = 'TRUE';
        rrSettings.ffrr__BalanceSheetAccount__c = '9999';
        rrSettings.ffrr__CompletedField__c = 'ffrr_exp__IncludeinRevenueRecognition__c';
        rrSettings.ffrr__CompletedValue__c = 'TRUE';
        rrSettings.ffrr__Currency__c = 'CurrencyIsoCode';
        rrSettings.ffrr__Description__c = 'Name';
        rrSettings.ffrr__EndDate__c = 'pse__End_Date__c';
        rrSettings.ffrr__FixedBalanceSheetAccountCode__c = true;
        rrSettings.ffrr__FixedCostCenterCode__c = true;
        rrSettings.ffrr__FixedIncomeStatementAccountCode__c = true;
        rrSettings.ffrr__ForecastTransactionLineRelationship__c = 'ffrr_exp__Project__c';
        rrSettings.ffrr__IncludeActiveValue__c = 'Include';
        rrSettings.ffrr__IncludeCompletedValue__c = 'Include';
        rrSettings.ffrr__IncomeStatementAccount__c = '9999';
        rrSettings.ffrr__Object__c = 'pse__Proj__c';
        rrSettings.ffrr__ParentSettings__c = null;
        //rrSettings.ffrr__PrimaryRelationship__c = 'PSA_Project__c';
        rrSettings.ffrr__SettingsLevel__c = 'Primary';
        rrSettings.ffrr__SettingsType__c = 'Actual;Forecast';
        rrSettings.ffrr__StartDate__c = 'pse__Start_Date__c';
        rrSettings.ffrr__TotalRevenue__c = 'pse__Bookings__c';
        rrSettings.Name = 'Project Settings';
        rrSettings.ffrr__ForecastHeaderPrimaryRelationship__c = 'ffrr_exp__Project__c';
        rrSettings.ffrr__PercentageComplete__c = 'PercentComplete__c';
        rrSettings.ffrr__RecognizedToDateValue__c = 'ffrr_exp__RecognizedToDate__c';
        rrSettings.ffrr__RevenueRecognitionCompleted__c = 'ffrr_exp__RevenueRecognitionCompleted__c';
        rrSettings.ffrr__TransactionLineRelationship__c = 'ffrr_exp__Project__c';

        insert rrSettings;
        return rrSettings;
    }

    private static void createTestRevRecTemplate() {
        ffrr__Settings__c rrSettings = createTestRevRecSettingsLevel2();

        ffrr__Template__c rrTemplate = new ffrr__Template__c();
        rrTemplate.ffrr__CalculationType__c = 'Not Applicable';
        rrTemplate.ffrr__RevenueBasis__c = 'Total Revenue';
        rrTemplate.ffrr__RevenueSource__c = 'PSA_Project_Forecast__c';
        rrTemplate.ffrr__RevRecType__c = 'Deliverable';
        rrTemplate.ffrr__Settings__c = rrSettings.Id;
        rrTemplate.Name = 'Guidewire Project Forecast Template';

        insert rrTemplate;
    }
*/
    private static void createTestTimePeriods() {
        Date startDate;
        Date endDate;
        Integer startYear=2015;
        Integer endYear=2020;
        Integer startMonth;
        String timePeriodName;
        List<pse__Time_Period__c> timePeriodsToInsert = new List<pse__Time_Period__c>();
        for (Integer i=startYear; i<=endYear; i++) {
            for (Integer j=1;j<=12;j++) {
                startDate = Date.newInstance(i, j, 1);
                endDate = startDate.addMonths(1).addDays(-1);
                timePeriodName = 'FY' + String.valueOf(i) + '-M' + String.valueOf(j);
                pse__Time_Period__c tp = psaTestUtils.createTestTimePeriod(timePeriodName, 100, startDate, endDate, 'Month', false);
                timePeriodsToInsert.add(tp);
            }

        }
        insert timePeriodsToInsert;
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
        testProject.pse__Start_Date__c = Date.today();
        testProject.pse__End_Date__c = Date.today() + 365;
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

        insert testProject;
        return testProject;
    }

    public static pse__Budget__c createTestBudget(Id projectId, Decimal amount) {
        pse__Budget__c psaBudget = new pse__Budget__c(pse__Project__c=projectId);
        psaBudget.pse__Amount__c = amount;
        psaBudget.pse__Type__c = 'Customer Purchase Order';
        psaBudget.pse__Effective_Date__c = Date.newInstance(2015, 1, 1);
        psaBudget.pse__Status__c = 'Approved';
        psaBudget.pse__Expense_Amount__c = 10000;

        insert psaBudget;
        return psaBudget;
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