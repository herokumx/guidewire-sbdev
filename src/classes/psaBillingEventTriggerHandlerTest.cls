@isTest
private class psaBillingEventTriggerHandlerTest {
    
    @isTest static void testBENoReceipts() {
        //** load test data files from static resources
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
        User u = psaTestUtils.createTestUser('tuserCLD', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        
        PSA_Account_Discount__c discount = new PSA_Account_Discount__c();
        discount.psa_Account__c = a.id;
        discount.PSA_Discount_Active__c = true;
        discount.PSA_Discount_Billing_Levels__c = '100';
        discount.PSA_Discount_Cap__c = 500;
        discount.psa_Discount_End_Date__c = (Date.today() + 100).addMonths(1).toStartofMonth().addDays(-1);
        discount.PSA_Discount_Type__c = 'Refund from POC';
        insert discount;

        Test.startTest();
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u);
        testProject.PSA_BR_Account_Discount__c = discount.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
       //   testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        //update testProject;
        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 100;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        insert event;

        pse__Billing_Event_Item__c first = new pse__Billing_Event_Item__c();
        first.pse__Amount__c = 100;
        first.pse__Billing_Event__c = event.id;
        first.pse__Date__c = Date.today();
        first.pse__Expense__c = expense.id;
        first.pse__Category__c = 'Expense';
        first.pse__Project__c = testProject.id;
        first.pse__Object_Id__c = expense.id;
        insert first;

        //Create an invoice summary line to test the copy functionality of psaBillingHistory
        PSA_Invoice_Summary_Line__c isl = new PSA_Invoice_Summary_Line__c();
        isl.PSA_Billing_Event__c = event.Id;
        isl.PSA_Summary_Line_Type__c = 'test';
        isl.PSA_Description__c = 'test';
        isl.PSA_Amount__c = 100.0;
        insert isl;
        
        event.PSA_Current_Billing_Amount__c = 200;
        update event;

        delete first;
        //Don't need to delete the be event since deleting all lines on the BE causes it to be deleted also
        //delete event;

        test.stopTest();

    }
    
    @isTest static void testBERelease() {
        //** load test data files from static resources
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
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c=testR.id, pse__Expense_Entry__c=true, pse__Billing__c=true, pse__Invoicing__c=true);

        PSA_Account_Discount__c discount = new PSA_Account_Discount__c();
        discount.psa_Account__c = a.id;
        discount.PSA_Discount_Active__c = true;
        discount.PSA_Discount_Billing_Levels__c = '100';
        discount.PSA_Discount_Cap__c = 500;
        discount.psa_Discount_End_Date__c = (Date.today() + 100).addMonths(1).toStartofMonth().addDays(-1);
        discount.PSA_Discount_Type__c = 'Refund from POC';
        insert discount;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u);
        testProject.PSA_BR_Account_Discount__c = discount.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        update testProject;
        Test.startTest();
        //update testProject;

//          pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);

        Date miscAdjDate = Date.today();
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
        insert miscAdj;

        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 500;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        insert event;

        pse__Billing_Event_Item__c first = new pse__Billing_Event_Item__c();
        first.pse__Amount__c = 500;
        first.pse__Quantity__c = 1;
        first.pse__Unit_Price__c = 500;
        first.pse__Rounded_Amount__c = 500;
        first.pse__Billing_Event__c = event.id;
        first.pse__Date__c = miscAdjDate;
        first.pse__Miscellaneous_Adjustment__c = miscAdj.Id;
        first.pse__Category__c = 'Miscellaneous Adjustment';
        first.pse__Object_Id__c = miscAdj.Id;
        first.pse__Description__c = 'Services Credit - Holdback';
        //first.pse__Expense__c = expense.id;
        //first.pse__Category__c = 'Expense';
        first.pse__Project__c = testProject.id;
        first.pse__Object_Id__c = miscAdj.id;
        insert first;
        //expense.pse__Billing_Event_Item__c = first.id;
        //expense.pse__Expense_Date__c = Date.today();
        //update expense;
        miscAdj.pse__Billing_Event_Item__c = first.Id;
        update miscAdj;

        event.PSA_Current_Billing_Amount__c = 200;
//        event.PSA_CIM_Reviewed__c = true;
//        event.pse__Status__c = 'Released';
//        event.pse__Is_Released__c = true;
        update event;

        //manually add invoice summary line
//        PSA_Invoice_Summary_Line__c isl = new PSA_Invoice_Summary_Line__c();
//        isl.PSA_Billing_Event__c = event.Id;
//        isl.PSA_Amount__c = 500;
//        isl.PSA_Description__c = 'test';
//        isl.PSA_Summary_Line_Type__c = 'Consulting Services';
//        insert isl;

//        event.pse__Status__c = 'Draft';
//        update event;

        delete first;


        test.stopTest();
/*
        Integer billingEventHistoryRecordCount = [Select Count() From PSA_Billing_Event_History__c];
        System.assertEquals(billingEventHistoryRecordCount, 1);
        Integer invoiceSummaryLineHistoryRecordCount = [Select Count() From PSA_Invoice_Summary_Line_History__c];
        System.assertEquals(invoiceSummaryLineHistoryRecordCount, 1);
*/
    }

    @isTest static void testBEItem() {
        //** load test data files from static resources
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
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);

        PSA_Account_Discount__c discount = new PSA_Account_Discount__c();
        discount.psa_Account__c = a.id;
        discount.PSA_Discount_Active__c = true;
        discount.PSA_Discount_Billing_Levels__c = '100';
        discount.PSA_Discount_Cap__c = 500;
        discount.psa_Discount_End_Date__c = (Date.today() + 100).addMonths(1).toStartofMonth().addDays(-1);
        discount.PSA_Discount_Type__c = 'Refund from POC';
        insert discount;

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Implementation', a, testR, testP, testG, null, c, u);
        testProject.PSA_BR_Account_Discount__c = discount.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        testProject.PSA_Customer_Requires_Expense_Receipts__c = true;
        update testProject;
        test.startTest();
        //update testProject;
        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);
        pse__Miscellaneous_Adjustment__c adj = new pse__Miscellaneous_Adjustment__c();
        adj.name = 'Test Adj';
        adj.pse__Project__c = testProject.id;
        adj.pse__Effective_Date__c = Date.today();
        adj.pse__Amount__c = 100;
        adj.pse__Transaction_Category__c = 'Other Cost';
        adj.PSA_Billing_Rule_Type__c = 'Services Credit - Holdback';
        adj.PSA_Created_By_Billing_Rule__c = true;
        adj.pse__Billed__c = false;
        adj.PSA_BR_Eligible_Discount_Amount__c = 100;
        insert adj;

        pse__Miscellaneous_Adjustment__c adj2 = new pse__Miscellaneous_Adjustment__c();
        adj2.name = 'Test Adj';
        adj2.pse__Project__c = testProject.id;
        adj2.pse__Effective_Date__c = Date.today();
        adj2.pse__Amount__c = 100;
        adj2.pse__Transaction_Category__c = 'Other Cost';
        adj2.PSA_Billing_Rule_Type__c = 'Services Charge - Holdback Release';
        adj2.PSA_Created_By_Billing_Rule__c = true;
        adj2.pse__Billed__c = false;
        adj2.PSA_BR_Eligible_Discount_Amount__c = 100;
        insert adj2;

        pse__Miscellaneous_Adjustment__c adj3 = new pse__Miscellaneous_Adjustment__c();
        adj3.name = 'Test Adj';
        adj3.pse__Project__c = testProject.id;
        adj3.pse__Effective_Date__c = Date.today();
        adj3.pse__Amount__c = 100;
        adj3.pse__Transaction_Category__c = 'Other Cost';
        adj3.PSA_Billing_Rule_Type__c = 'Services Credit - Holdback';
        adj3.PSA_Created_By_Billing_Rule__c = true;
        adj3.pse__Billed__c = false;
        adj3.PSA_BR_Eligible_Discount_Amount__c = 100;
        insert adj3;

        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 100;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        insert event;


        List<pse__Billing_Event_Item__c> beis = new List<pse__Billing_Event_Item__c>();
        pse__Billing_Event_Item__c first = new pse__Billing_Event_Item__c();
        first.pse__Amount__c = 100;
        first.pse__Billing_Event__c = event.id;
        first.pse__Date__c = Date.today();
        //first.pse__Expense__c = expense.id;
        first.pse__Miscellaneous_Adjustment__c = adj.id;
        first.pse__Category__c = 'Expense';
        first.pse__Project__c = testProject.id;
        first.pse__Object_Id__c = adj.id;
        beis.add(first);

        pse__Billing_Event_Item__c first2 = new pse__Billing_Event_Item__c();
        first2.pse__Amount__c = 100;
        first2.pse__Billing_Event__c = event.id;
        first2.pse__Date__c = Date.today();
        //first.pse__Expense__c = expense.id;
        first2.pse__Miscellaneous_Adjustment__c = adj2.id;
        first2.pse__Category__c = 'Expense';
        first2.pse__Project__c = testProject.id;
        first2.pse__Object_Id__c = adj2.id;
        beis.add(first2);

        pse__Billing_Event_Item__c first3 = new pse__Billing_Event_Item__c();
        first3.pse__Amount__c = 100;
        first3.pse__Billing_Event__c = event.id;
        first3.pse__Date__c = Date.today();
        //first.pse__Expense__c = expense.id;
        first3.pse__Miscellaneous_Adjustment__c = adj3.id;
        first3.pse__Category__c = 'Expense';
        first3.pse__Project__c = testProject.id;
        first3.pse__Object_Id__c = adj3.id;
        beis.add(first3);

        insert beis;

        delete beis;
        Test.stopTest();

    }
}