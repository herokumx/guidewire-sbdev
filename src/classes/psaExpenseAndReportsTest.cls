@isTest
private class psaExpenseAndReportsTest {
    
    @isTest static void testSimpleDelete() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;

        Test.startTest();

        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Expense_Report__c report = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, true);

        testProject.PSA_Director__c = c2.id;
        update testProject;
        pse__Expense_Report__c reportDir = psaTestUtils.createTestExpenseReport('Test Expense Report Director', testProject.id, c.id, true);
		pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
        expense.pse__Expense_Report__c = reportDir.id;

        delete reportDir;
        Test.stopTest();
    }
    
    @isTest static void testSimpleReportSubmit() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;

        Test.startTest();

        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Expense_Report__c report = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, true);

        testProject.PSA_Director__c = c2.id;
        update testProject;
        pse__Expense_Report__c reportDir = psaTestUtils.createTestExpenseReport('Test Expense Report Director', testProject.id, c.id, true);
		pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
        expense.pse__Expense_Report__c = reportDir.id;
        
        
        pw_cc__CountryObject__c co = new pw_cc__CountryObject__c();
        co.Name = 'Mexico';
        co.pw_cc__IsoCode_2__c = 'MX';
        co.pw_cc__IsoCode_3__c = 'MEX';
        insert co;
        expense.PSA_Incurred_Country__c = co.id;
        insert expense;

        reportDir.pse__Status__c = 'Submitted';
        
        update reportDir;
        Test.stopTest();
    }
    
    @isTest static void testSimpleReport() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;

        Test.startTest();

        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Expense_Report__c report = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, true);

        testProject.PSA_Director__c = c2.id;
        update testProject;
        pse__Expense_Report__c reportDir = psaTestUtils.createTestExpenseReport('Test Expense Report Director', testProject.id, c.id, true);


        testProject.PSA_CIM__c = c2.id;
        update testProject;

        pse__Expense_Report__c report2 = psaTestUtils.createTestExpenseReport('Test Expense Report 2', testProject.id, c.id, true);

        testProject.pse__Project_Manager__c = c2.id;
        update testProject;

        pse__Expense_Report__c report3 = psaTestUtils.createTestExpenseReport('Test Expense Report 3', testProject.id, c.id, true); 

        testProject.PSA_Expense_Approval_Method__c = 'Resource Manager';
        update testProject;
        pse__Expense_Report__c report4 = psaTestUtils.createTestExpenseReport('Test Expense Report 4', testProject.id, c.id, true); 
        Test.stopTest();
    }
    
    @isTest static void testExpensesWithPolicies() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        PSA_Expense_Policy__c amountReview = psaTestUtils.createTestPolicy('Test Amount', testProject.id, null, 'Lodging - Hotel', 'Amount Review Threshold', 100, false);
        PSA_Expense_Policy__c receiptReq = psaTestUtils.createTestPolicy('Test Receipt', testProject.id, null, 'Ground - Parking/Tolls', 'Receipt Required', 30 , false);
        PSA_Expense_Policy__c singleLimit = psaTestUtils.createTestPolicy('Test Bill Limit', null, a.id, 'Lodging - Laundry & Dry Cleaning', 'Single Billing Limit', 25, false);
        PSA_Expense_Policy__c noteReq = psaTestUtils.createTestPolicy('Test Note', null, a.id, 'Lodging - Relocation Expenses', 'Note Required', 25, false);
        List<PSA_Expense_Policy__c> policies = new List<PSA_Expense_Policy__c>();
        policies.add(amountReview);
        policies.add(receiptReq);
        policies.add(singleLimit);
        policies.add(noteReq);

        Test.startTest();
        insert policies;

        List<pse__Expense__c> expenses = new List<pse__Expense__c>();
        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
        pse__Expense__c expense2 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Ground - Parking/Tolls', false);
        pse__Expense__c expense3 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Laundry & Dry Cleaning', false);
        pse__Expense__c expense4 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Relocation Expenses', false);
        expenses.add(expense);
        expenses.add(expense2);
        expenses.add(expense3);
        expenses.add(expense4);
        try{
            insert expenses;
        } catch(Exception e){
            System.debug('*** EXCEPTION'+e.getMessage());
        }
        Test.stopTest();
    }

    @isTest static void testExpenseWithVATs() {
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;

        pw_cc__CountryObject__c testUSA = new pw_cc__CountryObject__c();
        testUSA.Name = 'USA';
        testUSA.pw_cc__IsoCode_2__c = 'US';
        testUSA.pw_cc__IsoCode_3__c = 'USA';
        insert testUSA;

        pw_cc__CountryObject__c testCAN = new pw_cc__CountryObject__c();
        testCAN.Name = 'Canada';
        testCAN.pw_cc__IsoCode_3__c = 'CAN';
        testCAN.pw_cc__IsoCode_2__c = 'CA';
        insert testCAN;

        pw_cc__CountryObject__c testMEX = new pw_cc__CountryObject__c();
        testMEX.Name = 'Mexico';
        testMEX.pw_cc__IsoCode_3__c = 'MEX';
        testMEX.pw_cc__IsoCode_2__c = 'MX';
        insert testMEX;


        pw_cc__State__c testState = new pw_cc__State__c();
        testState.Name = 'CanadaState';
        testState.pw_cc__Country__c = testCAN.id;
        testState.pw_cc__IsoCode__c = 'CSC';
        insert testState;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        c.PSA_Home_Country__c = testCAN.id;
        c.PSA_Home_State__c = testState.id;
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        c2.PSA_Home_Country__c = testUSA.id;
        
        u.ManagerId = u2.id;

      //  Test.startTest();
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c2.id, pse__Expense_Entry__c=true);
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
        
        Test.startTest();

        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
        expense.PSA_Incurred_Country__c = testUSA.id;
        insert expense;

        PSA_Expense_VAT__c testVat = new PSA_Expense_VAT__c();
        testVat.PSA_Expense_Type__c = 'Lodging - Hotel';
        testVat.PSA_Incurred_Country__c = testUSA.id;
        testVat.PSA_Is_Reclaimable__c = true;
        testVat.psa_Tax_Rate__c = .45;
        testVat.psa_Tax_type__c = 'VAT 1';
        insert testVat;

        

        PSA_Expense_VAT__c testVat2 = new PSA_Expense_VAT__c();
        testVat2.PSA_Expense_Type__c = 'Lodging - Hotel';
        testVat2.PSA_Incurred_Country__c = testCAN.id;
        testVat2.PSA_Incurred_State_Province__c = testState.id;
        testVat2.PSA_Is_Reclaimable__c = true;
        testVat2.psa_Tax_Rate__c = .45;
        testVat2.psa_Tax_type__c = 'VAT 1';
        insert testVat2;

        List<pse__Expense__c> expenses = new List<pse__Expense__c>();
        pse__Expense__c expense2 = psaTestUtils.createTestExpense(testProject.id, c.id, 400, 'Lodging - Hotel', false);
        expense2.PSA_Incurred_Country__c = testUSA.id;
        insert expense2;

        pse__Expense__c expense3 = psaTestUtils.createTestExpense(testProject.id, c.id, 400, 'Lodging - Hotel', false);
        expense3.PSA_Incurred_Country__c = testCAN.id;
        expense3.PSA_Incurred_State_Province__c = testState.id;
        expense3.PSA_Receipt_Type__c = 'Tax Receipt';
        insert expense3;

        pse__Expense__c expense4 = psaTestUtils.createTestExpense(testProject.id, c.id, 400, 'Lodging - Hotel', false);
        expense4.PSA_Incurred_Country__c = testMEX.id;
        insert expense4;

        pse__Expense__c expense5 = psaTestUtils.createTestExpense(testProject.id, c2.id, 400, 'Lodging - Hotel', false);
        expense5.PSA_Incurred_Country__c = testUSA.id;
        expense5.PSA_Receipt_Type__c = 'Tax Receipt';
        insert expense5;

        Test.stopTest();


    }

    @isTest static void testExpenseWithGLACode() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;

        
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
        Test.startTest();
        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);
        expense.pse__type__c = 'Lodging - Relocation Expenses';
        update expense;

        pse__Proj__c testProject2 = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject2.pse__Project_Type__c = 'Internal';
        testProject2.pse__Closed_for_Expense_Entry__c = false;
        update testProject2;

        PSA_Expense_Type_GLA__c testGLA = new PSA_Expense_Type_GLA__c();
        testGLA.name = 'Test GLA';
        testGLA.PSA_Expense_Type__c = 'Lodging - Hotel';
        testGLA.PSA_GLA_Code__c = '55667';
        insert testGLA;
        pse__Expense__c expense2 = psaTestUtils.createTestExpense(testProject2.id, c.id, 500, 'Lodging - Hotel', true);
        Test.stopTest();
    }
}