@isTest
private class psaBillingStageTriggerHandlerTest {
	
	@isTest static void test_method_one() {

		PSA_Billing_Stage__c bs = new PSA_Billing_Stage__c();
		bs.PSA_GW_Integration_Id__c = '15235';
		insert bs;
	}
	
	@isTest static void test_method_two() {
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

		pse__Proj__c testProject = psaTestUtils.createTestProject('Test', testR, testP, testG, 'Draft', null);
		testProject.pse__project_Type__c = 'Internal';
		testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.pse__Exclude_From_Billing__c = true;
        testProject.pse__Closed_for_Time_Entry__c = true;
        testProject.pse__Closed_for_Expense_Entry__c = true;
        testProject.PSA_Closed_For_Revenue__c = true;
        update testProject;
       //	testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
       	//update testProject;
    	
    	List<pse__Billing_Event__c> events = new List<pse__Billing_Event__c>();
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 100;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        events.add(event);

        pse__Billing_Event__c event2 = psaTestUtils.createTestBillingEvent(testProject.id, 'Draft', Date.today(), 'USD', 40, false);
        pse__Billing_event__c event3 = psaTestUtils.createTestBillingEvent(testProject.id, 'Draft', Date.today(), 'USD', 89, false);
        events.add(event2);
        events.add(event3);
        insert events;



        List<PSA_Billing_Stage__c> stages = new List<PSA_Billing_Stage__c>();
        PSA_Billing_Stage__c bs = new PSA_Billing_Stage__c();
		bs.PSA_GW_Integration_Id__c = '15235';
		bs.PSA_Billing_Event__c = event.id;
		bs.PSA_Integration_Status__c = 'Wrong';
		stages.add(bs);

		PSA_Billing_Stage__c bs2 = new PSA_Billing_Stage__c();
		bs2.PSA_GW_Integration_Id__c = '15235';
		bs2.PSA_Billing_Event__c = event2.id;
		bs2.PSA_Integration_Status__c = 'Processing Invoice';
		bs2.PSA_Invoice_Date__c = Date.today();
		bs2.PSA_Invoice_Number__c = '1234567';
		stages.add(bs2);

		PSA_Billing_Stage__c bs3 = new PSA_Billing_Stage__c();
		bs3.PSA_GW_Integration_Id__c = '15235';
		bs3.PSA_Billing_Event__c = event3.id;
		bs3.PSA_Integration_Status__c = 'Complete';
		stages.add(bs3);
		insert stages;

	}
	
}