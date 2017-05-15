@isTest
private class psaMigrationScriptsTest {
	
	@isTest static void test_method_one() {
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

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u, false);
       	testProject.pse__Is_Template__c = true;
       	testProject.PSA_GPS_Project_Id__c = '1234566';
       	insert testProject;

        Test.startTest();
        pse__Proj__c testProject2 = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u, false);
        testProject2.pse__Is_Template__c = true;
        testProject2.PSA_GPS_Project_Id__c = '1234566';
        testProject2.pse__Is_Active__c = false;
        testProject2.pse__Stage__c = 'Draft';
        testProject2.pse__End_Date__c = null;
        insert testProject2;

        
        /*pse__Proj__c testProject3 = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u, false);
        testProject3.pse__Is_Template__c = true;
        testProject3.PSA_GPS_Project_Id__c = '1234566';
        testProject3.pse__Is_Active__c = false;
        testProject3.pse__Stage__c = 'Draft';
        insert testProject3;*/

       	Double d = 40;
        pse__Milestone__c testMilestone = psaTestUtils.createTestMilestone('Test One', testProject, false, false, d);
        pse__Project_Phase__c testPhase = new pse__Project_Phase__c();
        testPhase.currencyisocode = 'USD';
        testPhase.Name = 'Test Phase';
        testPhase.pse__Project__c = testProject.id;
        testPhase.pse__Start_Date__c = Date.today();
        testPhase.pse__End_Date__c = Date.today() + 14;
        insert testPhase;

        pse__Project_Phase__c testPhase2 = new pse__Project_Phase__c();
        testPhase2.currencyisocode = 'USD';
        testPhase2.Name = 'Pilot';
        testPhase2.pse__Project__c = testProject2.id;
        testPhase2.pse__Start_Date__c = Date.today();
        testPhase2.pse__End_Date__c = Date.today() + 14;
        insert testPhase2;

        psaMigrationScripts.addMilestonesAndPhases();
        Test.stopTest();

	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}