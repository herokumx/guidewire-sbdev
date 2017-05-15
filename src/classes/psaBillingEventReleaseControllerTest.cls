@isTest(seeAllData=true) 
private class psaBillingEventReleaseControllerTest {
	static pse__Billing_Event__c billingEvent1;
	static pse__Billing_Event__c billingEvent2;
	static pse__Billing_Event__c billingEvent3;
	static pse__Time_Period__c timePeriod;
	static pse__Proj__c testProject;

	@isTest static void psaBillingEventReleaseControllerTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

		PageReference pageRef = Page.psaBillingEventRelease;
        Test.setCurrentPage(pageRef);
		ApexPages.StandardController sc = new ApexPages.standardController(billingEvent1);
    	psaBillingEventReleaseController controller = new psaBillingEventReleaseController(sc);
       	controller.autoRun();

        billingEvent1.PSA_CIM_Reviewed__c = true;
        update billingEvent1;
       	controller.autoRun();

		Test.stopTest();

	}

	private static void setupTestData() {
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('tuserCLD', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
		insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);

        PSA_Entity__c testentity = createTestEntity('Test E', '1234', 'TE', true);
        PSA_Department__c dept = createTestDepartment('Test Department', '1425', true);

		testProject = psaTestUtils.createTestProject('Test', testR, testP, testG, 'Draft', null);
		testProject.pse__project_Type__c = 'Internal';
		testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.pse__Exclude_From_Billing__c = true;
        testProject.pse__Closed_for_Time_Entry__c = true;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Closed_For_Revenue__c = true;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        testProject.pse__Project_Manager__c = c.Id;
        testProject.PSA_Director__c = c.id;
        testProject.PSA_CIM__c = c.id;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.PSA_Department__c = dept.id;

        update testProject;
    	
    	Double seasonalityFactor = 90;
    	timePeriod = psaTestUtils.createTestTimePeriod('test', seasonalityFactor, Date.today(), Date.today().addDays(30), 'Month', true);

    	List<pse__Billing_Event__c> events = new List<pse__Billing_Event__c>();
        billingEvent1 = new pse__Billing_Event__c();
        billingEvent1.pse__Project__c = testProject.id;
        billingEvent1.pse__Status__c = 'Draft';
        billingEvent1.pse__Date__c = Date.today();
        billingEvent1.currencyIsoCode = 'USD';
        billingEvent1.PSA_Current_Billing_Amount__c = 100;
        billingEvent1.PSA_CIM_Reviewed__c = false;
        billingEvent1.PSA_PM_Reviewed__c = true;
        billingEvent1.PSA_Time_Period__c = timePeriod.Id;
        events.add(billingEvent1);

        insert events;

        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);

        List<Attachment> imageAttachmentList = 
            [select Body, ContentType, Description, Id, IsPrivate, Name, ParentId 
                From Attachment
                Where ContentType like '%image%'
                And IsDeleted = false
                Limit 1
            ];
        System.debug('Attach List: ' + imageAttachmentList);
        if (imageAttachmentList != null && imageAttachmentList.size() > 0) {
            Attachment att = imageAttachmentList[0];
            Attachment tempAtt = new Attachment (name=att.name, body=att.body, ContentType=att.ContentType, parentId=expense.Id);
            insert tempAtt;
        }

/*
        List<Attachment> attachs = new List<Attachment>();
        Attachment at1 = new Attachment();
        at1.Name = 'Test Attachment';
        at1.parentId = expense.id;
        at1.body = blob.toPDF('This is a fake pdf');
        //at1.contenttype='image/png';
        Attachment at2 = new Attachment();
        at2.Name = 'Test Attachment 2';
        at2.parentId = expense.id;
        at2.body = blob.toPDF('This is a fake pdf2');
        //at2.contenttype='image/png';
        attachs.add(at1);
        attachs.add(at2);
        insert attachs;
*/

        pse__Billing_Event_Item__c first = new pse__Billing_Event_Item__c();
        first.pse__Amount__c = 100;
        first.pse__Billing_Event__c = billingEvent1.id;
        first.pse__Date__c = Date.today();
        first.pse__Expense__c = expense.id;
        first.pse__Category__c = 'Expense';
        first.pse__Project__c = testProject.id;
        first.pse__Object_Id__c = expense.id;
        insert first;

        expense.pse__Billing_Event_Item__c = first.id;
        update expense;
	}

    /**************************************************************************************************
    * Creates a test Entity
    *
    ***************************************************************************************************/
    public static psa_Entity__c createTestEntity(String name, String code, String shortName, boolean billingEntity){
        PSA_Entity__c entity = new PSA_Entity__c();
        entity.name = name;
        entity.PSA_Entity_Code__c = code;
        entity.PSA_Short_Name__c = shortName;
        entity.PSA_Billing_Entity__c = billingEntity;
        insert entity;
        return entity;
    }

    /**************************************************************************************************
    * Creates a test Department
    *
    ***************************************************************************************************/
    public static PSA_Department__c createTestDepartment(String name, String code, boolean isPSDept){
        PSA_Department__c dept = new PSA_Department__c();
        dept.Name = name;
        dept.PSA_Department_Code__c = code;
        dept.PSA_PS_Department__c = isPSDept;
        insert dept;
        return dept;
    }
}