@isTest(seeAllData=false) 
private class psaBillingHistoryTest {
	static pse__Billing_Event__c billingEvent1;
	static pse__Billing_Event__c billingEvent2;
	static pse__Billing_Event__c billingEvent3;
	static pse__Time_Period__c timePeriod;
	static pse__Proj__c testProject;

	@isTest static void Test1() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

		List<pse__Billing_Event__c> billingEvents = 
			[Select CurrencyISOCode, PSA_Account_Discount_Services_Total__c, pse__Is_Approved__c, PSA_Billing_Detail_Template__c, 
					PSA_Bill_To_Contact__c, PSA_CIM_Reviewed__c, PSA_CIM_User__c, PSA_Comments__c, pse__Billing_Contact__c, 
					PSA_Current_Billing_Amount__c, PSA_Current_Billing_Event_Item_Count__c, pse__Date__c, PSA_Discount_Applied__c, 
					PSA_Expense_Credits_Applied__c, PSA_Expense_Total__c, PSA_Holdback_Applied__c, PSA_Holdback_Release_Applied__c, 
					PSA_Integration_Status__c, pse__Invoiced__c, pse__Invoice_Date__c, pse__Invoice_Number__c, Name, PSA_PM_Reviewed__c, 
					PSA_PO_Number__c, pse__Project__c, PSA_Billing_Stage__c, pse__Is_Released__c, PSA_Send_CIM_Notification__c, 
					PSA_Services_Credits_Applied__c, PSA_Ship_To_Contact__c, PSA_Special_Invoice_Instructions__c, pse__Status__c, 
					pse__Summary_Amount__c, PSA_T_M_Services_Total__c, PSA_Time_Period__c, PSA_Prior_Billing_Event__c
				From pse__Billing_Event__c
				Where Id = :billingEvent1.Id
			];
		psaBillingHistory.copyBillingEvent(billingEvents);

		Test.stopTest();

	}

	/*
	@isTest static void TestError() {
		psaTestUtils.disablePsaTriggers();

		//Create users, contacts, rpg, account, and project
		setupTestData();

		Test.startTest();

		List<pse__Billing_Event__c> billingEvents = 
			[Select CurrencyISOCode, PSA_Account_Discount_Services_Total__c, pse__Is_Approved__c, PSA_Billing_Detail_Template__c, 
					PSA_Bill_To_Contact__c, PSA_CIM_Reviewed__c, PSA_CIM_User__c, PSA_Comments__c, pse__Billing_Contact__c, 
					PSA_Current_Billing_Amount__c, PSA_Current_Billing_Event_Item_Count__c, pse__Date__c, PSA_Discount_Applied__c, 
					PSA_Expense_Credits_Applied__c, PSA_Expense_Total__c, PSA_Holdback_Applied__c, PSA_Holdback_Release_Applied__c, 
					PSA_Integration_Status__c, pse__Invoiced__c, pse__Invoice_Date__c, pse__Invoice_Number__c, Name, PSA_PM_Reviewed__c, 
					PSA_PO_Number__c, pse__Project__c, PSA_Billing_Stage__c, pse__Is_Released__c, PSA_Send_CIM_Notification__c, 
					PSA_Services_Credits_Applied__c, PSA_Ship_To_Contact__c, PSA_Special_Invoice_Instructions__c, pse__Status__c, 
					pse__Summary_Amount__c, PSA_T_M_Services_Total__c, PSA_Time_Period__c
				From pse__Billing_Event__c
				Where Id = :billingEvent1.Id
			];
		psaBillingHistory.copyBillingEvent(billingEvents);

		Test.stopTest();

	}
	*/
	
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
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Closed_For_Revenue__c = true;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        testProject.pse__Project_Manager__c = c.Id;
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

        pse__Miscellaneous_Adjustment__c miscAdj = new pse__Miscellaneous_Adjustment__c();
        miscAdj.pse__Project__c = testProject.id;
        miscAdj.pse__Amount__c = 100;
        miscAdj.PSA_Billing_Rule_Type__c = 'Services Charge - Minimum Hours';
        miscAdj.pse__Effective_Date__c = Date.today();
        miscAdj.pse__Transaction_Category__c = 'Ready-to-Bill Revenue';
        miscAdj.PSA_Created_By_Billing_Rule__c = false;
        insert miscAdj;
        /*
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
		*/
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
        //first.pse__Expense__c = expense.id;
        first.pse__Miscellaneous_Adjustment__c = miscAdj.Id;
        first.pse__Category__c = 'Miscellaneous Adjustment';
        first.pse__Project__c = testProject.id;
        first.pse__Object_Id__c = miscAdj.id;
        insert first;

//        expense.pse__Billing_Event_Item__c = first.id;
//        update expense;

        PSA_Invoice_Summary_Line__c isl = new PSA_Invoice_Summary_Line__c();
        isl.PSA_Amount__c = 100;
        isl.PSA_Summary_Line_Type__c = 'Test';
        isl.PSA_Description__c = 'Test';
        isl.PSA_Billing_Event__c = billingEvent1.Id;
        insert isl;

	}
}