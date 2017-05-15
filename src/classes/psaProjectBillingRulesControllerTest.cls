@isTest(seeAllData=false) 
private class psaProjectBillingRulesControllerTest {
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
	static pse__Assignment__c testAssignment;
	static pse__Schedule__c testAssignmentSchedule;

	@isTest static void ProjectBillingRulesControllerTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

		PageReference pageRef = Page.psaProjectBillingRules;
        Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('saved', 'y');
		ApexPages.StandardController sc = new ApexPages.standardController(project);
    	psaProjectBillingRulesController controller = new psaProjectBillingRulesController(sc);
       	controller.save();
       	controller.saveAndReturn();

		PageReference pageRef2 = Page.psaProjectBillingRules;
        Test.setCurrentPage(pageRef2);
		pageRef2.getParameters().put('exec', 'y');
		//ApexPages.StandardController sc = new ApexPages.standardController(project);
    	psaProjectBillingRulesController controller2 = new psaProjectBillingRulesController(sc);
       	controller2.applyBillingRules();

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

        entity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        resourceUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        resourceContact = psaTestUtils.createTestResource(resourceUser, testR, testP, testG);
        resourceContact.PSA_Fully_Loaded_Cost_Rate__c = 123;
        resourceContact.PSA_Resource_Entity__c = entity.id;
        resourceContact.MailingCity = 'Ellicott City';
        resourceContact.MailingState = 'MD';
        resourceContact.MailingPostalCode = '21042';
        resourceContact.MailingCountry = 'USA';
        resourceContact.PSA_Worker_Id__c = 'resourceuser123';
        update resourceContact;

        managerUser = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        managerContact = psaTestUtils.createTestResource(managerUser, testR, testP, testG);
  		managerUser.PSA_Worker_Id__c = 'managertestuser12345';
  		update managerUser;
  		managerContact.PSA_Worker_Id__c = 'managertestuser12345';
  		update managerContact;
        resourceUser.ManagerId = managerUser.id;
        resourceUser.PSA_Worker_Id__c = 'resourceuser123';
        update resourceUser;

		//create a test billable project
        project = createTestProjectInProgress('Test Project', testAccount, testR, testP, testG, null, resourceContact, resourceUser, 
        			'Draft', true);
        System.debug('Project: ' + project);

        //Grant all permission controls to the current user
        psaTestUtils.grantAllPermissionControls(UserInfo.getUserId(), testR.Id);

        //Create Assignment 
        testAssignment = createTestAssignment(project, resourceContact, 'Project Manager', Date.newInstance(2015, 1, 1), Date.newInstance(2016, 1, 31), 100.00);

        //Create Schedule Exception
//        createTestScheduleException(testAssignmentSchedule.Id, Date.today().addDays(90), Date.today().addDays(97));

	} 

    public static pse__Assignment__c createTestAssignment(pse__Proj__c proj, Contact resource, String resourceRole, Date startDate, Date endDate, Decimal billRate)
    {
        // Create an initial assignment schedule
        testAssignmentSchedule = new pse__Schedule__c();
        testAssignmentSchedule.pse__Start_Date__c = startDate;
        testAssignmentSchedule.pse__End_Date__c = endDate;
        testAssignmentSchedule.pse__Monday_Hours__c = 8;
        testAssignmentSchedule.pse__Tuesday_Hours__c = 8;
        testAssignmentSchedule.pse__Wednesday_Hours__c = 8;
        testAssignmentSchedule.pse__Thursday_Hours__c = 8;
        testAssignmentSchedule.pse__Friday_Hours__c = 8;
        insert testAssignmentSchedule;

        // Get top most Region for the Permission Control
        id regionId = [select id from pse__Region__c where pse__Hierarchy_Depth__c = 0 limit 1].id;
        system.Assert(regionId != null, 'No Regions configured.   Please contact your PSA Admin');

        // Create the assignment and associate it with the project
        pse__Assignment__c assignment = new pse__Assignment__c(Name='Test Assignment');
        assignment.pse__Is_Billable__c = true;
        assignment.pse__Project__c = proj.Id;
        assignment.pse__Resource__c = resource.Id;
        assignment.pse__Schedule__c = testAssignmentSchedule.Id;
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
        testProject.pse__End_Date__c = Date.today() + 90;
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
}