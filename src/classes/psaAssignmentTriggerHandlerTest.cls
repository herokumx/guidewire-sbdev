@isTest
private class psaAssignmentTriggerHandlerTest {
	
	@isTest static void testAssignmentProjectRateSet() {
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

		pse__Assignment__c testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');
	}
	
	@isTest static void testAssignmentAccountRateSet() {
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
		rs.PSA_Account__c = a.id;
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

		pse__Assignment__c testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');
		// Implement test code
	}

	@isTest static void testAssignmentNoRateSet(){
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
		pse__Assignment__c testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');
	}
	
}