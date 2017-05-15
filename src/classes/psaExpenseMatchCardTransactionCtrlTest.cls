/*************************************************************************
Name:           psaExpenseMatchCardTransactionCtrlTest
Author:         CLD
Created Date:   7/19/2016
Description:    Tests related to psaExpenseMatchCardTransactionController
*************************************************************************/
@isTest(seeAllData=false)
private class psaExpenseMatchCardTransactionCtrlTest
{
    static User testUser;
    static pse__Expense_Report__c testExpenseReport;
    static psa_card_transaction__c[] testCardTransactions;
    static pse__Assignment__c testAssignment;
    static pse__Proj__c testProject;
    static Contact c;

    static {
        setupTestData();
    }


    @isTest static void itInitializesMatchingScreen()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...

        // mock up an expense
        pse__Expense__c testExpense =  psaTestUtils.createTestExpense(testExpenseReport.pse__Project__c, testExpenseReport.pse__Resource__c, 1.23, 'String type', false);
        testExpense.pse__Expense_Report__c = testExpenseReport.id;
        insert testExpense;


        // ctors
        psaExpenseMatchCardTransactionController subject = getSubject(testExpenseReport);
        system.assert(subject != null);

        // verify it errs out
        Map<String, Object> errr = psaExpenseMatchCardTransactionController.initializeExpenseReportCardTransactions(null);
        system.assert(errr != null);

        // ensure we can initialize expense reports and card transactions
        Map<String, Object> rslt = psaExpenseMatchCardTransactionController.initializeExpenseReportCardTransactions(testExpenseReport.id);
        system.assert(rslt != null);

        // grab resource id to cover card transactions....

        String resourceId = c.id;

        Date before = Date.today().addDays(-5);
        Date later = Date.today().addDays(5);

        String filterStartDate = before.year() + '-10-10';
        String filterEndDate = later.year() + '-11-11';

        Map<String, String> payload = new Map<String, String>();
        payload.put('filterStartDate', filterStartDate);
        payload.put('filterEndDate', filterEndDate);

        Map<String, Object> rslt2 = psaExpenseMatchCardTransactionController.lookupCardTransactions(resourceId, JSON.serialize(payload));
        system.assert(rslt2 != null);



        test.stopTest();
    }

    @isTest static void itMatchesExpenseAndCards()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...

        // mock up an expense
        pse__Expense__c testExpense =  psaTestUtils.createTestExpense(testExpenseReport.pse__Project__c, testExpenseReport.pse__Resource__c, 1.23, 'String type', false);
        testExpense.pse__Expense_Report__c = testExpenseReport.id;

        // mock up another expense with a card transaction.......
        pse__Expense__c testExpense2 =  psaTestUtils.createTestExpense(testExpenseReport.pse__Project__c, testExpenseReport.pse__Resource__c, 1.23, 'String type', false);
        testExpense2.psa_card_transaction__c = testCardTransactions[0].id;

        testExpense2.pse__Expense_Report__c = testExpenseReport.id;

        insert new pse__Expense__c[]{testExpense, testExpense2};


        // ctors
        psaExpenseMatchCardTransactionController subject = getSubject();
        system.assert(subject != null);


        Map<String, String> entry = new Map<String, String>();
        entry.put('expenseId', testExpense.id);
        entry.put('cardTransactionId', testCardTransactions[0].id);

        List<Object> payload = new List<Object>();
        payload.add(entry);

    //@RemoteAction public static Map<String, Object> matchExpenseCardTransactions(String expenseReportId,
    //                                                                             String jsonExpCardMatchFields,
    //                                                                             String jsonExpIdMatchToRemove)


        Map<String, Object> rslt =  psaExpenseMatchCardTransactionController.matchExpenseCardTransactions(
                testExpenseReport.id,
                JSON.serialize(payload),
                JSON.serialize(new String[]{testExpense2.id}));

        system.assert(rslt != null);


        test.stopTest();

    }


    // ------------------------------------------------------------------------
    // # Matches expense items to card transactions
    // # jsonFilterFields : JSON serialized list of expense ids to card transactions ids to match
    //      - (example from Javascript:)
    //          var filterFields = [{
    //              { expenseId: 'abc123', cardTransactionId: '123abc' },
    //              { expenseId: 'def456', cardTransactionId: '456def' }
    //           ];

    // Map<String, Object> rslt =  psaExpenseMatchCardTransactionController.matchExpenseCardTransactions(expRptId, JSON.serialize(new list<object>()));
    // ------------------------------------------------------------------------
    // cover our remote action expense lookup
    //@isTest static void itLooksupExpenses()
    //{
    //    test.startTest();

    //    Datetime fromDT = Datetime.now();
    //    fromDT.addDays(-10);
    //    fromDT.format('yyyy-MM-dd');

    //    Datetime toDT = Datetime.now();
    //    toDT.addDays(10);
    //    toDT.format('yyyy-MM-dd');


    //    Map<String, Object> payload = new Map<String, Object>();
    //    payload.put('resourceId', c.id);
    //    payload.put('status', 'Any');
    //    payload.put('fromExpDate', fromDT.format('yyyy-MM-dd'));
    //    payload.put('toExpDate', toDT.format('yyyy-MM-dd'));


    //    Map<String, Object> rslt = psaExpenseAddCardTransactionsController.lookupExpenses(JSON.serialize(payload));
    //    system.assert(rslt != null);

    //    test.stopTest();
    //}

    // --------------------------------------------------------------------------
    // Convenient methods for constructing test subjects
    // --------------------------------------------------------------------------
    private static psaExpenseMatchCardTransactionController getSubject() {
        return getSubject(null);
    }

    private static psaExpenseMatchCardTransactionController getSubject(pse__Expense_Report__c er) {
        test.setCurrentPage(Page.psaExpenseMatchCardTransactions);
        psaExpenseMatchCardTransactionController ctr = null;
        if (er != null)
        {
            ApexPages.currentPage().getParameters().put('id', er.id);
            ApexPages.StandardController stdController = new ApexPages.StandardController(er);
            ctr = new psaExpenseMatchCardTransactionController(stdController);
        }
        else
        {
            ctr = new psaExpenseMatchCardTransactionController();
        }
        return ctr;
    }

    // --------------------------------------------------------------------------
    // Mock / Stub Test Data
    // --------------------------------------------------------------------------

    private static void setupTestData()
    {
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager
        //User testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        c = psaTestUtils.createTestResource(testUser, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);

        testUser.ManagerId = u2.id;

        testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, testUser);
        testProject.PSA_Milestone_Required__c = false;
        testProject.pse__Project_type__c = 'Internal';
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.pse__Allow_Expenses_Without_Assignment__c = true;
        update testProject;

        pse__Permission_Control__c[] permissions = new pse__Permission_Control__c[]{};
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Staffing__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= testR.id, pse__Staffing__c=true, pse__Cascading_Permission__c = true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Resource__c = c.id, pse__Expense_Entry__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Resource__c = c.id, pse__Staffing__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Region__c= testR.id, pse__Staffing__c=true, pse__Cascading_Permission__c = true));

        insert permissions;

        ////////////

        pw_cc__CountryObject__c pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = 'USA',
            pw_cc__IsoCode_2__c = 'US'
        );
        insert pcc;

        pw_cc__State__c pcs = new pw_cc__State__c(
            pw_cc__Country__c = pcc.id,
            pw_cc__IsoCode__c = 'VA');
        insert pcs;


        testExpenseReport = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, false);

        // insert a psa card transactions......
        psa_card_transaction__c ct1 = new psa_card_transaction__c();
        ct1.PSA_Salesforce_User__c = testUser.id;
        ct1.PSA_Resource__c = c.id;
        ct1.PSA_Resource_Inactive__c = false;
        ct1.PSA_Amount_in_Original_Currency__c = 100.00;
        ct1.PSA_Expense_Type__c = 'Hotel';
        ct1.PSA_Transaction_Date__c = Date.today();
        ct1.PSA_Incurred_Country__c = pcc.id;
        //ct1.PSA_Incurred_State_Province__c = pcs.id;


        psa_card_transaction__c ct2 = new psa_card_transaction__c();
        ct2.PSA_Salesforce_User__c = testUser.id;
        ct2.PSA_Resource__c = c.id;
        ct2.PSA_Resource_Inactive__c = false;
        ct2.PSA_Amount_in_Original_Currency__c = 100.00;
        ct2.PSA_Expense_Type__c = 'Hotel';
        ct2.PSA_Transaction_Date__c = Date.today();
        ct2.PSA_Incurred_Country__c = pcc.id;
        //ct2.PSA_Incurred_State_Province__c = pcs.id;


        psa_card_transaction__c ct3 = new psa_card_transaction__c();
        ct3.PSA_Salesforce_User__c = testUser.id;
        ct3.PSA_Resource__c = c.id;
        ct3.PSA_Resource_Inactive__c = false;
        ct3.PSA_Amount_in_Original_Currency__c = 100.00;
        ct3.PSA_Expense_Type__c = 'Hotel';
        ct3.PSA_Transaction_Date__c = Date.today();
        ct3.PSA_Incurred_Country__c = pcc.id;
        //ct3.PSA_Incurred_State_Province__c = pcs.id;

        testCardTransactions = new psa_card_transaction__c[]{ct1, ct2, ct3};
        insert testCardTransactions;

    }


    // todo...test it!
}