@isTest
private class psaExpenseStageTriggerHandlerTest {
	
	@isTest static void test_empty() {
		PSA_Expense_Stage__c es = new PSA_Expense_Stage__c();
		es.PSA_GW_Integration_Id__c = '12345';
		insert es;
	}
	
	@isTest static void test_normal_op() {
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

		pse__Proj__c testProject = psaTestUtils.createTestProject('Test project', testR, testP, testG, 'Draft', null);
		testProject.pse__Closed_for_Expense_Entry__c = false;
		update testProject;

		Test.startTest();

		insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
		pse__Expense_Report__c report = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, false);
		report.PSA_Reimbursement_Status__c = 'Fake value';
		insert report;

		PSA_Expense_Stage__c es = new PSA_Expense_Stage__c();
		es.PSA_GW_Integration_Id__c = '12345';
		es.PSA_Expense_Report__c = report.id;
		insert es;

		report.PSA_Reimbursement_Status__c = 'Processing Reimbursement';
		update report;

		/*List<pse__Expense__c> expenses = new List<pse__Expense__c>();
		pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
		pse__Expense__c expense2 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Ground - Parking/Tolls', false);
		pse__Expense__c expense3 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Laundry & Dry Cleaning', false);
		pse__Expense__c expense4 = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Relocation Expenses', false);
		expense.pse__Expense_Report__c = report.id;
		expense2.pse__Expense_report__c = report.id;
		expense3.pse__Expense_Report__c = report.id;
		expense4.pse__Expense_Report__c = report.id;
		expenses.add(expense);
		expenses.add(expense2);
		expenses.add(expense3);
		expenses.add(expense4);
		try{
			insert expenses;
		} catch(Exception e){
			System.debug('*** EXCEPTION'+e.getMessage());
		}*/
	}
	
}