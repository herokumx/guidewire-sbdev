@isTest(seeAllData=true) 
private class psaIntacctIntegrationTest {
    static User resourceUser;
    static User managerUser;
    static Contact resourceContact;
    static Contact managerContact;
    static pse__Region__c testR;
    static pse__Practice__c testP;
    static pse__Grp__c testG;
    static Account testAccount;
    static PSA_Entity__c entity;
    static pse__Proj__c project;
    static pse__Time_Period__c timePeriod;
    static pse__Billing_Event_Batch__c testBEB;
    static pse__Assignment__c testAssignment;
    static pse__Expense_Report__c expenseRptHeader;
    static pse__Expense__c expense;
    static pse__Billing_Event__c billingEvent;

    @isTest static void BillingEventUpdateTest() {
        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        testBEB = new pse__Billing_Event_Batch__c();
        testBEB.pse__Account__c = testAccount.Id;
        testBEB.pse__Region__c = testR.Id;
        testBEB.pse__Time_Period__c = timePeriod.Id;
        insert testBEB;

        Double billingEventAmount = 0.0;
        billingEvent = createTestBillingEvent(project.Id, 'Draft', Date.Today(), project.CurrencyIsoCode, billingEventAmount, testBEB.Id, true);
        billingEvent.PSA_Integration_Status__c = 'Eligible for Invoicing';

        PSA_Billing_Stage__c bs = new PSA_Billing_Stage__c();
        bs.PSA_Billing_Event__c = billingEvent.Id;
        bs.PSA_GW_Integration_Id__c = '12345';
        bs.PSA_Integration_Status__c = 'Complete';
        bs.PSA_Invoice_Date__c = Date.newInstance(2015, 1, 31);
        bs.PSA_Invoice_Number__c = '123';
        insert bs;

        Test.stopTest();
    }
    
    @isTest static void BillingEventUpdateNoInvoiceNumberTest() {
        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        testBEB = new pse__Billing_Event_Batch__c();
        testBEB.pse__Account__c = testAccount.Id;
        testBEB.pse__Region__c = testR.Id;
        testBEB.pse__Time_Period__c = timePeriod.Id;
        insert testBEB;

        Double billingEventAmount = 0.0;
        billingEvent = createTestBillingEvent(project.Id, 'Draft', Date.Today(), project.CurrencyIsoCode, billingEventAmount, testBEB.Id, true);
        billingEvent.PSA_Integration_Status__c = 'Eligible for Invoicing';

        PSA_Billing_Stage__c bs = new PSA_Billing_Stage__c();
        bs.PSA_Billing_Event__c = billingEvent.Id;
        bs.PSA_GW_Integration_Id__c = '12345';
        bs.PSA_Integration_Status__c = 'Complete';
        bs.PSA_Invoice_Date__c = Date.newInstance(2015, 1, 31);
        bs.PSA_Invoice_Number__c = null;
        insert bs;

        Test.stopTest();
    }
    
    @isTest static void BillingEventUpdateNoBillingEventIdTest() {
        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        testBEB = new pse__Billing_Event_Batch__c();
        testBEB.pse__Account__c = testAccount.Id;
        testBEB.pse__Region__c = testR.Id;
        testBEB.pse__Time_Period__c = timePeriod.Id;
        insert testBEB;

        Double billingEventAmount = 0.0;
        billingEvent = createTestBillingEvent(project.Id, 'Draft', Date.Today(), project.CurrencyIsoCode, billingEventAmount, testBEB.Id, true);
        billingEvent.PSA_Integration_Status__c = 'Eligible for Invoicing';

        PSA_Billing_Stage__c bs = new PSA_Billing_Stage__c();
        //bs.PSA_Billing_Event__c = billingEvent.Id;
        bs.PSA_GW_Integration_Id__c = '12345';
        bs.PSA_Integration_Status__c = 'Complete';
        bs.PSA_Invoice_Date__c = Date.newInstance(2015, 1, 31);
        bs.PSA_Invoice_Number__c = null;
        insert bs;

        Test.stopTest();
    }
    
    @isTest static void ExpenseReportUpdateTest() {
        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //Create timecard and billing event item (update timecard with BEI)
        Date tcDate = Date.newInstance(2015, 1, 9);
        
        expenseRptHeader = psaTestUtils.createTestExpenseReport('test', project.Id, resourceContact.Id, true);
        expense = psaTestUtils.createTestExpenseOnReportWithAssignment(expenseRptHeader.Id, project.Id, resourceContact.Id, 10.00, 'Meals - Self - Lunch', 
                tcDate, testAssignment.Id, true);
        expense.pse__Billable__c = true;
        expense.pse__Status__c = 'Approved';
        expense.pse__Submitted__c = true;
        expense.pse__Approved__c = true;
        expense.pse__Include_In_Financials__c = true;
        update expense;

        PSA_Expense_Stage__c es = new PSA_Expense_Stage__c();
        es.PSA_Expense_Report__c = expenseRptHeader.Id;
        es.PSA_GW_Integration_Id__c = '12345';
        es.PSA_Reimbursement_Status__c = 'Reimbursed';
        insert es;

        Test.stopTest();
    }

    @isTest static void ExpenseReportUpdateNoIdTest() {
        //Create users, contacts, rpg, account, and project
        setupTestData();

        Test.startTest();

        //Create timecard and billing event item (update timecard with BEI)
        Date tcDate = Date.newInstance(2015, 1, 9);
        
        expenseRptHeader = psaTestUtils.createTestExpenseReport('test', project.Id, resourceContact.Id, true);
        expense = psaTestUtils.createTestExpenseOnReportWithAssignment(expenseRptHeader.Id, project.Id, resourceContact.Id, 10.00, 'Meals - Self - Lunch', 
                tcDate, testAssignment.Id, true);
        expense.pse__Billable__c = true;
        expense.pse__Status__c = 'Approved';
        expense.pse__Submitted__c = true;
        expense.pse__Approved__c = true;
        expense.pse__Include_In_Financials__c = true;
        update expense;


        PSA_Expense_Stage__c es = new PSA_Expense_Stage__c();
        //es.PSA_Expense_Report__c = expenseRptHeader.Id;
        es.PSA_GW_Integration_Id__c = '12345';
        es.PSA_Reimbursement_Status__c = 'Reimbursed';
        insert es;

        Test.stopTest();
    }

    private static void setupTestData() {
        Try {
            psaTestUtils.disablePsaTriggers();
        } Catch (Exception ex) {
            System.debug('Failed to disable PSA_Triggers');
        }
        //psaTestUtils.disableASMTriggers('false');
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        testR = psaTestUtils.createTestRegion('Corporate');
        testP = psaTestUtils.createTestPractice('Corporate');
        testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        testAccount = psaTestUtils.createTestAccountWithParticipantId('Test Account', '12345', '1234');

        entity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager 
        String userNameBase = 'GWIntacctTUser';
        resourceUser = psaTestUtils.createTestUser('usercld2', userNameBase + '1@guidewire.com', 'usercld2', 'test2', 'tuser123@tuser.com', 'tuser123');
        resourceContact = psaTestUtils.createTestResource(resourceUser, testR, testP, testG);
        resourceContact.PSA_Fully_Loaded_Cost_Rate__c = 123;
        resourceContact.PSA_Resource_Entity__c = entity.id;
        resourceContact.MailingCity = 'Ellicott City';
        resourceContact.MailingState = 'MD';
        resourceContact.MailingPostalCode = '21042';
        resourceContact.MailingCountry = 'USA';
        update resourceContact;

        managerUser = psaTestUtils.createTestUser('usercld3', userNameBase + '2@guidewire.com', 'usercld3', 'test3', 'tuser321@tuser.com', 'tuser321');
        managerContact = psaTestUtils.createTestResource(managerUser, testR, testP, testG);
        
        resourceUser.ManagerId = managerUser.id;
        update resourceUser;

        //Grant all permission controls to the current user
        psaTestUtils.grantAllPermissionControls(UserInfo.getUserId(), testR.Id);

        //Create the project and assignment and assure that locations were created
        project = psaTestUtils.createTestProjectInProgress('Test Project', testAccount, testR, testP, testG, null, resourceContact, 
                resourceUser, true);
        //project.pse__Stage__c = 'Draft';
        //project.pse__Closed_for_Time_Entry__c = false;
        project.pse__Closed_for_Expense_Entry__c = false;
        //project.pse__Exclude_From_Billing__c = false;
        update project;
        System.debug('Project: ' + project);

        Date startDate = Date.newInstance(2015, 1, 1);
        Date endDate = Date.newInstance(2015, 1, 31);
        Double seasonalityFactor = 0.90;
        timePeriod = psaTestUtils.createTestTimePeriod('Test Period', seasonalityFactor, startDate, endDate, 'Month', true);

        //Create Assignment 
        testAssignment = createTestAssignment(project, resourceContact, 'Project Manager', Date.newInstance(2015, 1, 1), Date.newInstance(2016, 1, 31), 100.00);
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