@isTest(seeAllData=false) 
private class psaWorkdayResourceIntegrationTest {
	static User managerUser;
	static Contact managerContact;
	static pse__Region__c testR;
	static pse__Practice__c testP;
	static pse__Grp__c testG;
	static Account testAccount;
	static pse__Timecard_Header__c tcHeader;
	static PSA_Resource_Stage__c testRS;
	static PSA_Department__c testDept;
	static PSA_Entity__c testEntity;
	static PSA_Time_Zone__c testTimeZone;
	static pse__Work_Calendar__c testWorkCalendar;

	@isTest static void ResourceIntegration() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project 
		setupTestData();

		testRS = createTestResourceStage('worker123456test', 'managertestuser12345');

		Test.startTest();

		testRS.PSA_PS_Level__c = null;
		update testRS;

		Test.stopTest();

	}

	private static PSA_Resource_Stage__c createTestResourceStage(String workerId, String managerWorkerId) {
		PSA_Resource_Stage__c rs = new PSA_Resource_Stage__c();
		Date testDate = Date.newInstance(2015, 1, 1);
		String entityCode = ([Select PSA_Entity_Code__c from PSA_Entity__c Order By PSA_Entity_Code__c Limit 1]).PSA_Entity_Code__c;
		String departmentCode = ([Select PSA_Department_Code__c from PSA_Department__c Order By PSA_Department_Code__c Limit 1]).PSA_Department_Code__c;
		String timeZone = ([Select PSA_Workday_Time_Zone__c from PSA_Time_Zone__c Order By PSA_Workday_Time_Zone__c Limit 1]).PSA_Workday_Time_Zone__c;
		String workCalendar = ([Select PSA_WD_Work_Calendar_Name__c from pse__Work_Calendar__c Order by PSA_WD_Work_Calendar_Name__c Limit 1]).PSA_WD_Work_Calendar_Name__c;
		String wdRegion = ([Select PSA_WD_Region_ID__c from pse__Region__c Order By PSA_WD_Region_ID__c Limit 1]).PSA_WD_Region_ID__c;

		rs.PSA_Worker_Id__c = workerId;
		rs.PSA_First_Name__c = 'Test';
		rs.PSA_Last_Name__c = 'Last Name';
		rs.PSA_Email__c = 'test@test123456.com';
		rs.PSA_Legal_First_Name__c = 'Test';
		rs.PSA_Legal_Last_Name__c = 'Last Name';
		rs.PSA_Mobile_Phone__c = '5555555555';
		rs.PSA_Phone__c = '5555555555';
		rs.PSA_City__c = 'Foster City';
		rs.PSA_State_Province__c = 'CA';
		rs.PSA_Postal_Code__c = '77777';
		rs.PSA_Country__c = 'United States';
		rs.PSA_PS_Level__c = '100';
		rs.PSA_Resource_Status__c = 'Active';
		rs.PSA_Time_Zone__c = timeZone;
		rs.PSA_Title__c = 'test title';
		rs.PSA_WD_Region_ID__c = wdRegion;
		rs.PSA_WD_Work_Calendar_Name__c = workCalendar;
		rs.PSA_Worker_Type__c = 'Employee';
		rs.PSA_Manager__c = managerWorkerId;
		rs.PSA_Absence_End_Date__c = testDate;
		rs.PSA_Absence_Start_Date__c = testDate;
		rs.PSA_Department__c = departmentCode;
		rs.PSA_Entity_Id__c = entityCode;
		rs.PSA_Termination_Date__c = testDate;
		rs.PSA_GW_Integration_Id__c = 'test integration id';

		insert rs;
		return rs;
	}

	private static void setupTestData() {
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        testR = psaTestUtils.createTestRegion('Corporate');
        testR.PSA_WD_Region_ID__c = 'AA';
        update testR;

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

        testEntity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        PSA_Department__c dept = new PSA_Department__c();
        dept.Name = 'Test Department';
        dept.PSA_Department_Code__c = '1425';
        dept.PSA_PS_Department__c = true;
        insert dept;

		psaTestUtils.createTestResourcePractice(dept.Id, testEntity.Id, testP.Id);

        PSA_Time_Zone__c timeZone = new PSA_Time_Zone__c();
        timeZone.PSA_Workday_Time_Zone__c = 'test';
        timeZone.PSA_Salesforce_Time_Zone__c = 'sf time zone';
        timeZone.PSA_Active__c = true;
        insert timeZone;

        pse__Work_Calendar__c defaultWorkCalendar = new pse__Work_Calendar__c(Name='Test Work Calendar');
        defaultWorkCalendar.PSA_WD_Work_Calendar_Name__c = 'AA';
        insert defaultWorkCalendar;

        managerUser = psaTestUtils.createTestUser('UserCLD2', 'UserCLD2@tuser.com', 'UserCLD2', 'test', 'UserCLD2@tuser.com', 'UserCLD2');
        managerContact = psaTestUtils.createTestResource(managerUser, testR, testP, testG);
  		managerUser.PSA_Worker_Id__c = 'managertestuser12345';
  		update managerUser;
  		managerContact.PSA_Worker_Id__c = 'managertestuser12345';
  		update managerContact;

        //Grant all permission controls to the current user
        psaTestUtils.grantAllPermissionControls(UserInfo.getUserId(), testR.Id);

        //Create the PSA Integration custom setting record
        psaTestUtils.createPSAIntegrationCustomSetting();
	} 
}