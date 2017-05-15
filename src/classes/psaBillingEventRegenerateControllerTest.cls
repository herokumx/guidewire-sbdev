@isTest(seeAllData=false) 
private class psaBillingEventRegenerateControllerTest {
	static pse__Billing_Event__c billingEvent1;
	static pse__Billing_Event__c billingEvent2;
	static pse__Billing_Event__c billingEvent3;
	static pse__Time_Period__c timePeriod;
	static pse__Proj__c testProject;

	@isTest static void BillingEventRegenerateControllerTest() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

		PageReference pageRef = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('step', 'clear');
		pageRef.getParameters().put('id', billingEvent1.Id);
		pageRef.getParameters().put('count', '100');
        pageRef.getParameters().put('proj', testProject.Id);
        pageRef.getParameters().put('tp', timePeriod.Id);
    	psaBillingEventRegenerateController controller = new psaBillingEventRegenerateController();
       	controller.startRegenerateProcess();
        controller.reloadPage();

		PageReference pageRef4 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef4);
		pageRef4.getParameters().put('step', 'clear');
		pageRef4.getParameters().put('id', billingEvent1.Id);
		pageRef4.getParameters().put('count', '1');
        pageRef4.getParameters().put('proj', testProject.Id);
        pageRef4.getParameters().put('tp', timePeriod.Id);
    	psaBillingEventRegenerateController controller4 = new psaBillingEventRegenerateController();
       	controller4.startRegenerateProcess();

		PageReference pageRef2 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef2);
		pageRef2.getParameters().put('step', 'clear');
		pageRef2.getParameters().put('id', billingEvent2.Id);
        pageRef2.getParameters().put('proj', testProject.Id);
        pageRef2.getParameters().put('tp', timePeriod.Id);
    	psaBillingEventRegenerateController controller2 = new psaBillingEventRegenerateController();
       	controller2.startRegenerateProcess();

		PageReference pageRef7 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef7);
		pageRef7.getParameters().put('step', 'clear');
		pageRef7.getParameters().put('id', billingEvent1.Id);
		pageRef7.getParameters().put('count', '1');
		pageRef7.getParameters().put('jobid', 'null');
        pageRef7.getParameters().put('proj', testProject.Id);
        pageRef7.getParameters().put('tp', timePeriod.Id);
    	psaBillingEventRegenerateController controller7 = new psaBillingEventRegenerateController();
       	controller7.startRegenerateProcess();

		PageReference pageRef5 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef5);
		pageRef5.getParameters().put('step', 'beg');
		pageRef5.getParameters().put('tp', timePeriod.Id);
		pageRef5.getParameters().put('proj', testProject.Id);
    	psaBillingEventRegenerateController controller5 = new psaBillingEventRegenerateController();
       	controller5.startRegenerateProcess();

		PageReference pageRef6 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef6);
		pageRef6.getParameters().put('step', 'beg');
		pageRef6.getParameters().put('id', billingEvent1.Id);
		pageRef6.getParameters().put('tp', timePeriod.Id);
		pageRef6.getParameters().put('proj', testProject.Id);
		pageRef6.getParameters().put('jobid', 'null');
        pageRef6.getParameters().put('retry', '0');
		pageRef6.getParameters().put('start', String.valueOf(DateTime.now()));
    	psaBillingEventRegenerateController controller6 = new psaBillingEventRegenerateController();
       	controller6.startRegenerateProcess();

		PageReference pageRef8 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef8);
        pageRef8.getParameters().put('tp', timePeriod.Id);
        pageRef8.getParameters().put('proj', testProject.Id);
		pageRef8.getParameters().put('step', 'doc');
        pageRef8.getParameters().put('emailcim', '0');
		pageRef8.getParameters().put('id', billingEvent3.Id);
    	psaBillingEventRegenerateController controller8 = new psaBillingEventRegenerateController();
       	controller8.startRegenerateProcess();

		PageReference pageRef9 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef9);
		pageRef9.getParameters().put('step', 'failed');
		pageRef9.getParameters().put('id', billingEvent1.Id);
    	psaBillingEventRegenerateController controller9 = new psaBillingEventRegenerateController();
       	controller9.startRegenerateProcess();

		PageReference pageRef3 = Page.psaBillingEventRegenerate;
        Test.setCurrentPage(pageRef3);
		pageRef3.getParameters().put('step', 'done');
		pageRef3.getParameters().put('id', billingEvent3.Id);
    	psaBillingEventRegenerateController controller3 = new psaBillingEventRegenerateController();
       	controller3.startRegenerateProcess();

		//Also test the psaBillingEventRecalc class
		Set<Id> projectIds = new Set<Id>();
		projectIds.add(testProject.Id);
		psaBillingEventRecalc.recalcBillingEvents(projectIds);
		Set<Id> billingEventIds = new Set<Id>();
		billingEventIds.add(billingEvent3.Id);
		pse.APIBillingService.BillingContextRecalc bcr = new pse.APIBillingService.BillingContextRecalc();
		bcr.billingEventIds = billingEventIds;
		psaBillingEventRecalc ber = new psaBillingEventRecalc();
		ber.afterFinish(bcr);

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

		testProject = psaTestUtils.createTestProject('Test', testR, testP, testG, 'Draft', null);
		testProject.pse__project_Type__c = 'Internal';
		testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.pse__Exclude_From_Billing__c = true;
        testProject.pse__Closed_for_Time_Entry__c = true;
        testProject.pse__Closed_for_Expense_Entry__c = true;
        testProject.PSA_Closed_For_Revenue__c = true;
        update testProject;
       //	testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
       	//update testProject;
    	
    	Double seasonalityFactor = 90;
    	timePeriod = psaTestUtils.createTestTimePeriod('test', seasonalityFactor, Date.today(), Date.today().addDays(30), 'Month', true);

    	List<pse__Billing_Event__c> events = new List<pse__Billing_Event__c>();
        billingEvent1 = new pse__Billing_Event__c();
        billingEvent1.pse__Project__c = testProject.id;
        billingEvent1.pse__Status__c = 'Draft';
        billingEvent1.pse__Date__c = Date.today();
        billingEvent1.currencyIsoCode = 'USD';
        billingEvent1.PSA_Current_Billing_Amount__c = 100;
        billingEvent1.PSA_CIM_Reviewed__c = true;
        billingEvent1.PSA_PM_Reviewed__c = true;
        billingEvent1.PSA_Time_Period__c = timePeriod.Id;
        events.add(billingEvent1);

        billingEvent2 = psaTestUtils.createTestBillingEvent(testProject.id, 'Released', Date.today(), 'USD', 40, false);
        billingEvent3 = psaTestUtils.createTestBillingEvent(testProject.id, 'Draft', Date.today(), 'USD', 89, false);
        events.add(billingEvent2);
        events.add(billingEvent3);
        insert events;

		psaTestUtils.createPSABillingCustomSetting();
	}
}