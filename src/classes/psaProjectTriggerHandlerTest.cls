@isTest
private class psaProjectTriggerHandlerTest {
	
        @isTest static void testPMChange(){
                Test.loadData(appirio_core__Config_Group__c.SObjectType, 'TestDataConfigGroups');
        Test.loadData(appirio_core__Config_Option__c.SObjectType, 'TestDataConfigOptions');
        Test.loadData(appirio_core__Config_Value__c.SObjectType, 'TestDataConfigValues');

        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        User u2 = psaTestUtils.createTestUser('2serCLD2', '2userCLD2@tuser.com', 'u2erCLD2', '2est2', '2userCLD2@tuser.com', '2userCLD2');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c=testR.id, pse__Expense_Entry__c=true, pse__Billing__c=true, pse__Invoicing__c=true);

        PSA_Account_Discount__c discount = new PSA_Account_Discount__c();
        discount.psa_Account__c = a.id;
        discount.PSA_Discount_Active__c = true;
        discount.PSA_Discount_Billing_Levels__c = '100';
        discount.PSA_Discount_Cap__c = 500;
        discount.psa_Discount_End_Date__c = (Date.today() + 100).addMonths(1).toStartofMonth().addDays(-1);
        discount.PSA_Discount_Type__c = 'Refund from POC';
        insert discount;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u, false);
        testProject.PSA_BR_Account_Discount__c = discount.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        insert testProject;
        Test.startTest();
        //update testProject;

//          pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);

        /*Date miscAdjDate = Date.today();
        pse__Miscellaneous_Adjustment__c miscAdj = new pse__Miscellaneous_Adjustment__c();
        miscAdj.pse__Project__c = testProject.Id;
        miscAdj.pse__Amount__c = 500;
        miscAdj.pse__Transaction_Category__c = 'Ready-to-Bill Revenue';
        miscAdj.pse__Effective_Date__c = miscAdjDate;
        miscAdj.PSA_Billing_Rule_Type__c = 'Services - Time and Materials';
        miscAdj.pse__Description__c = 'Services Credit - Holdback';
        miscAdj.pse__Approved__c = true;
        miscAdj.pse__Include_In_Financials__c = true;
        miscAdj.pse__Status__c = 'Approved';
        insert miscAdj;*/

        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 500;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        insert event;
		psaTriggerMonitor.ExecutedTriggers = new Set<String>();
        testProject.pse__Project_Manager__c = c2.id;
        update testProject;

        }
    
    @isTest static void testInsert(){
        Test.loadData(appirio_core__Config_Group__c.SObjectType, 'TestDataConfigGroups');
        Test.loadData(appirio_core__Config_Option__c.SObjectType, 'TestDataConfigOptions');
        Test.loadData(appirio_core__Config_Value__c.SObjectType, 'TestDataConfigValues');

        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        User u2 = psaTestUtils.createTestUser('2serCLD2', '2userCLD2@tuser.com', 'u2erCLD2', '2est2', '2userCLD2@tuser.com', '2userCLD2');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c=testR.id, pse__Expense_Entry__c=true, pse__Billing__c=true, pse__Invoicing__c=true);

        PSA_Account_Discount__c discount = new PSA_Account_Discount__c();
        discount.psa_Account__c = a.id;
        discount.PSA_Discount_Active__c = true;
        discount.PSA_Discount_Billing_Levels__c = '100';
        discount.PSA_Discount_Cap__c = 500;
        discount.psa_Discount_End_Date__c = (Date.today() + 100).addMonths(1).toStartofMonth().addDays(-1);
        discount.PSA_Discount_Type__c = 'Refund from POC';
        insert discount;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u, false);
        testProject.PSA_BR_Account_Discount__c = discount.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        Test.startTest();
        insert testProject;
        Test.stopTest();

        }

    @isTest static void testRemaining(){
        psaTestUtils.initDefaultWorkCalendar();
		//Create RPG
		pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
		pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
		pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

		//Create test account with a location so that locations will be created
		Account a = psaTestUtils.createTestAccount('Test Account', '12345');
		a.Participant_id__c = '1234';
		update a;
		//Create 2 contacts, one to submit and one as the manager
		User u = psaTestUtils.createTestUser('tuserCLD', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD');
		Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
		c.PSA_Billing_Level__c = '120';
		update c;

		pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
		testProject.PSA_Milestone_Required__c = false;
		update testProject;

		PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
		rs.PSA_Project__c = testProject.id;
		rs.PSA_Is_Global__c = false;
		insert rs;

		PSA_Rate__c rate = new PSA_Rate__c();
		rate.psa_Billing_Level__c = '120';
		rate.PSA_Average_Cost_Rate__c = 35;
		rate.PSA_Bill_Rate_Amount__c = 80;
		rate.PSA_Start_Date__c = Date.Today() - 20;
		rate.PSA_End_Date__c = Date.Today() + 200;
		rate.PSA_Bill_Rate_Set__c = rs.id;
		insert rate;
		Test.startTest();
		pse__Assignment__c testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');
        psaTriggerMonitor.ExecutedTriggers = new Set<String>();
        update testProject;
        Test.stopTest();
    }
    
    @isTest static void testRemaining2(){
        psaTestUtils.initDefaultWorkCalendar();
		//Create RPG
		pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
		pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
		pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

		//Create test account with a location so that locations will be created
		Account a = psaTestUtils.createTestAccount('Test Account', '12345');
		a.Participant_id__c = '1234';
		update a;
		//Create 2 contacts, one to submit and one as the manager
		User u = psaTestUtils.createTestUser('tuserCLD', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD');
		Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
		c.PSA_Billing_Level__c = '120';
		update c;

		pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
		testProject.PSA_Milestone_Required__c = false;
		update testProject;

		PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
		rs.PSA_Project__c = testProject.id;
		rs.PSA_Is_Global__c = false;
		insert rs;

		PSA_Rate__c rate = new PSA_Rate__c();
		rate.psa_Billing_Level__c = '120';
		rate.PSA_Average_Cost_Rate__c = 35;
		rate.PSA_Bill_Rate_Amount__c = 80;
		rate.PSA_Start_Date__c = Date.Today() - 20;
		rate.PSA_End_Date__c = Date.Today() + 200;
		rate.PSA_Bill_Rate_Set__c = rs.id;
		insert rate;
		Test.startTest();
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
		pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, true);
        psaTriggerMonitor.ExecutedTriggers = new Set<String>();
        update testProject;
        Test.stopTest();
    }
    
	@isTest static void testAllFinanceErrors() {
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        Account a = psaTestUtils.createTestAccount('Test Account', '12345');

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('tuserCLD', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

        pse__Proj__c testProject = new pse__Proj__c(name='Test Project');
        testProject.pse__Stage__c = 'Draft';
        /*testProject.pse__Region__c = testR.id;
        testProject.pse__Practice__c = testP.id;
        testProject.pse__Group__c = testG.id;
        testProject.pse__Account__c = a.id;*/
                testProject.pse__closed_For_Time_Entry__c = true;
        testProject.pse__Closed_For_Expense_Entry__C = true;
        testProject.pse__Exclude_From_Billing__c = true;
        insert testProject;
        testProject.pse__Stage__c = 'Finance Review';
        testProject.psa_Expense_Approval_Method__c = null;
        testProject.psa_Time_Approval_Method__c = null;
        psaTriggerMonitor.ExecutedTriggers = new Set<String>();
        try{
        	update testProject;
        	} catch(DMLException dl){
        		System.debug('Successfully caught the error: '+dl.getMessage());
        	}
        

	}
	
	@isTest static void testAllProgressErrors() {
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        Account a = psaTestUtils.createTestAccount('Test Account', '12345');

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

        pse__Proj__c testProject = new pse__Proj__c(name='Test Project');
        testProject.pse__Stage__c = 'Draft';
        /*testProject.pse__Region__c = testR.id;
        testProject.pse__Practice__c = testP.id;
        testProject.pse__Group__c = testG.id;
        testProject.pse__Account__c = a.id;*/
        testProject.pse__closed_For_Time_Entry__c = true;
        testProject.pse__Closed_For_Expense_Entry__C = true;
        testProject.pse__Exclude_From_Billing__c = true;
        insert testProject;

        PSA_Implementer__c pmi = new PSA_Implementer__c();
        pmi.PSA_Account__C = a.id;
        pmi.PSA_Project__c = testProject.id;
        pmi.PSA_Primary__c = true;
        insert pmi;

        testProject.pse__Stage__c = 'In Progress';
        testProject.currencyIsoCode = null;
        testProject.PSA_BR_Expenses_Billing_Type__c = null;
        testProject.pse__Project_Type__c = null;
        testProject.pse__Billing_Type__c = null;
        testProject.PSA_Revenue_Forecast_Model__c = null;
        testProject.psa_Expense_Approval_Method__c = null;
        testProject.psa_Time_Approval_Method__c = null;
		psaTriggerMonitor.ExecutedTriggers = new Set<String>();

        try{
        	update testProject;
        	} catch(DMLException dl){
        		System.debug('Successfully caught the error: '+dl.getMessage());
        	}
        
	}


	
}