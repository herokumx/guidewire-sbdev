/*************************************************************************
Name:           psaExpenseAddCardTransactionsTest
Author:         CLD
Created Date:   10/20/2015
Description:    Tests related to psaExpenseAddCardTransactionsController
*************************************************************************/
@isTest(seeAllData=false)
private class psaExpenseAddCardTransactionsTest
{
    static User testUser;
    static pse__Expense_Report__c testExpenseReport;
    static psa_card_transaction__c[] testCardTransactions;
    static pse__Assignment__c testAssignment;
    static pse__Proj__c testProject;
    static Contact c;

    static {
        setupTestData();
    }

    @isTest static void itHandlesCardTransactionsFromExpenseReport()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...


        Integer preExpCount = [select count() from pse__Expense__c where pse__Expense_Report__c = :testExpenseReport.id];

        psaExpenseAddCardTransactionsController subject = getSubject(testExpenseReport);
        system.assert(subject != null);

        // added for gw change
        subject.getUserExpenseReports();

        system.assert(subject.IsAddFromExpenseReport == true);


        // ensure the controller lists states and provinces
        system.assert(subject.incurredStateProvOptions != null);


        // ensure it filters
        subject.filterStartDate = String.valueOf(Date.today().addDays(-15));
        subject.filterEndDate = String.valueOf(Date.today().addDays(15));
        subject.loadUserCardTransactions();

        system.assert(subject.cardTransactionWrappers != null);
        system.assert(subject.hasCardTransactions == true);
        system.assert(subject.cardTransactionWrappers.size() > 2);

        Id billableCardTransactionId = null;
        Id previouslyEnteredCardTransactionId = null;
        Id personalCardTransactionId = null;

        Set<Id> cardTransIds = new Set<Id>();

        // ensure we can add expenses to the expense report
        // and mark card transactions as previously entered
        // and mark card transactions as personal
        if (subject.cardTransactionWrappers.size() > 0)
        {
            subject.cardTransactionWrappers[0].selected = true;
            subject.cardTransactionWrappers[0].billable = true;
            subject.cardTransactionWrappers[0].previouslyEntered = false;
            subject.cardTransactionWrappers[0].personal = false;
            subject.cardTransactionWrappers[0].cardTransaction.PSA_Expense_Report__c = testExpenseReport.id;

            billableCardTransactionId = subject.cardTransactionWrappers[0].cardTransaction.id;
            cardTransIds.add(billableCardTransactionId);
        }
        if (subject.cardTransactionWrappers.size() > 1)
        {
            subject.cardTransactionWrappers[1].selected = true;
            subject.cardTransactionWrappers[1].previouslyEntered = true;
            subject.cardTransactionWrappers[1].billable = false;
            subject.cardTransactionWrappers[1].personal = false;
            subject.cardTransactionWrappers[1].cardTransaction.PSA_Expense_Report__c = testExpenseReport.id;

            previouslyEnteredCardTransactionId = subject.cardTransactionWrappers[1].cardTransaction.id;
            cardTransIds.add(previouslyEnteredCardTransactionId);

        }
        if (subject.cardTransactionWrappers.size() > 2)
        {
            subject.cardTransactionWrappers[2].selected = true;
            subject.cardTransactionWrappers[2].previouslyEntered = false;
            subject.cardTransactionWrappers[2].billable = false;
            subject.cardTransactionWrappers[2].personal = true;
            subject.cardTransactionWrappers[2].cardTransaction.PSA_Expense_Report__c = testExpenseReport.id;

            personalCardTransactionId = subject.cardTransactionWrappers[2].cardTransaction.id;
            cardTransIds.add(personalCardTransactionId);
        }
//
        // cover add to expense report
        subject.addToExpenseReport();

        // verify the card transactions were updated accordingly
        Map<Id, psa_card_transaction__c> postSettings = new Map<Id, psa_card_transaction__c>([select id,PSA_Status__c,PSA_Charge_Type__c, PSA_Previously_Entered__c from psa_card_transaction__c where id in : cardTransIds ]);
        if (billableCardTransactionId != null)
        {

            system.assert(postSettings.get(billableCardTransactionId).PSA_Charge_Type__c == 'Company');
        }
        if (previouslyEnteredCardTransactionId != null)
        {
            system.assert(postSettings.get(previouslyEnteredCardTransactionId).PSA_Previously_Entered__c == true);
        }
        if (personalCardTransactionId != null)
        {
            system.assert(postSettings.get(personalCardTransactionId).PSA_Charge_Type__c =='Personal');
        }

        // verify expense was created for expense report
        pse__Expense__c[] postUpdate = [select id, pse__Expense_Report__c from pse__Expense__c where pse__Expense_Report__c = :testExpenseReport.id];
        Integer postExpCount = postUpdate.size();

        //Integer postExpCount = [select count() from pse__Expense__c where pse__Expense_Report__c = :testExpenseReport.id];
        system.assert(postExpCount > preExpCount);

        // cover triggering deletes....
        if (postUpdate.size() > 0)
        {
            delete postUpdate[0];
        }
        delete testExpenseReport;

        test.stopTest();
    }


    @isTest static void itHandlesCardTransactionManagement()
    {
        test.startTest();

        // attempt to get around too many soql...
        insert testExpenseReport;
        testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');
        //
        /////

        system.runAs(testUser)
        {
            psaExpenseAddCardTransactionsController subject = getSubject();
            system.assert(subject != null);

            system.assert(subject.notIsAddFromExpenseReport == true);

            // select the rows
            system.assert(subject.cardTransactionWrappers.size() > 2);

            subject.cardTransactionWrappers[0].selected = true;
            subject.cardTransactionWrappers[1].selected = true;
            subject.cardTransactionWrappers[2].selected = true;

            // cover formatted date
            system.assert(subject.cardTransactionWrappers[0].transactionDateFormatted != null); // cover
            // cover calculating
            subject.cardTransactionWrappers[0].calculateGWCardReimburesementAmount(5);
            // cover generating error when no items associated
            subject.addToExpenseReport();
            // cover when none selected
            subject.applySelectedToExpenseReport();


            // ---good

           // set the expense report selector
            subject.userExpenseReportSelector.pse__Expense_Report__c = testExpenseReport.id;

            // apply the expense report to the selected rows
            subject.applySelectedToExpenseReport();

            // cover create new expense report/////
            //       need an assignment stubbed

            subject.createAndShowNewExpenseReport();
            subject.expenseReportAssignmentId = testAssignment.id + ':' + testAssignment.pse__Project__c;


            subject.saveNewExpenseReport(); // will produce error that all fields are required

            subject.createdExpenseReport.name  = 'testing';
            subject.createdExpenseReport.pse__description__c = 'testing';
            subject.saveNewExpenseReport(); // will succeed
            //system.debug(' SHOULD HAVE SUCCEEDED!!!!! \n\n >>>> ');
            system.debug(subject.expReportErrMsg);

            subject.expenseReportAssignmentId =  '<none>:' + testAssignment.pse__Project__c;
            subject.saveNewExpenseReport(); // cover saving as internal project?

            // ensure we can add expenses to the expense report
            // and mark card transactions as previously entered
            // and mark card transactions as personal
            if (subject.cardTransactionWrappers.size() > 0)
            {
                subject.cardTransactionWrappers[0].selected = true;
                subject.cardTransactionWrappers[0].billable = false;
                subject.cardTransactionWrappers[0].previouslyEntered = false;
                subject.cardTransactionWrappers[0].cardTransaction.PSA_Expense_Report__c = testExpenseReport.id;
                subject.cardTransactionWrappers[0].personal = false;
            }
            if (subject.cardTransactionWrappers.size() > 1)
            {
                subject.cardTransactionWrappers[1].selected = true;
                subject.cardTransactionWrappers[1].previouslyEntered = true;
                subject.cardTransactionWrappers[1].billable = false;
                subject.cardTransactionWrappers[1].personal = false;

            }
            if (subject.cardTransactionWrappers.size() > 2)
            {
                subject.cardTransactionWrappers[2].selected = true;
                subject.cardTransactionWrappers[2].previouslyEntered = false;
                subject.cardTransactionWrappers[2].billable = false;
                subject.cardTransactionWrappers[2].personal = true;
            }

            // cover add to expense report
            subject.addToExpenseReport();

            system.assert(subject.hasRecentlySavedExpenses != null);

            test.stopTest();
        }
    }


    //
    @isTest static void itItemizesCardTransactionManagement()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...

        psaExpenseAddCardTransactionsController subject = getSubject(testExpenseReport);
        system.assert(subject != null);


        // cover itemizing and cancelling
        subject.itemizeUserCardTransaction();
        subject.cancelItemizeUserCardTransaction();

        //system.assert(subject.hasPageError == true);

        // with a row selected, verify the itemized screen renders
        subject.transactionIdToItemize = subject.cardTransactionWrappers[0].cardTransaction.id;
        subject.itemizeUserCardTransaction();

        system.assert(subject.hasPageError == false);

        system.assert(subject.hasItemizedCardTransaction == true);
        system.assert(subject.itemizedTransWrapper.itemizedTransactions.size() == 2);

        subject.addItemizedLine(); // assert we can add a line

        system.assert(subject.itemizedTransWrapper.itemizedTransactions.size() == 3);

        // cover when none selected
        subject.deleteSelectedItemizedLines();


        subject.itemizedTransWrapper.itemizedTransactions[subject.itemizedTransWrapper.itemizedTransactions.size() -1].selected = true;
        subject.deleteSelectedItemizedLines();

        system.assert(subject.itemizedTransWrapper.itemizedTransactions.size() == 2);

        // attempt to save with '0' in an item line....should get an error!
        subject.addItemizedToExpenseReport();

        // should get an error about amounts
        system.assert(subject.hasPageError == true);

        subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
        subject.itemizedTransWrapper.itemizedTransactions[1].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
        subject.itemizedTransWrapper.itemizedTransactions[1].billable = false;
        subject.itemizedTransWrapper.itemizedTransactions[1].personal = true; // make this one personal!

        // with amounts updated, should succeed
        subject.addItemizedToExpenseReport();

        // system.debug('\n ***********  pageErrorMessage > ' + subject.pageErrorMessage);

        system.assert(subject.hasPageError == false);
        Id cardTransId = subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.id;

        Set<Id> cardTransItemIds = new Set<Id>();
        for (PSA_Card_Transaction_Item__c pct : [
                select id, psa_card_transaction__c, psa_expense_report__c
                from PSA_Card_Transaction_Item__c
                where psa_expense_report__c = :testExpenseReport.id])
        {
            cardTransItemIds.add(pct.id);
        }

        system.assert(cardTransItemIds != null && cardTransItemIds.size() > 0);
        psaCardTransactionLoader.unassignCardTransactionItems(cardTransItemIds);


        test.stopTest();
    }

    //
    @isTest static void itCoversCardTransactionItemDelete()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...

        psaExpenseAddCardTransactionsController subject = getSubject(testExpenseReport);
        system.assert(subject != null);



        // with a row selected, verify the itemized screen renders
        subject.transactionIdToItemize = subject.cardTransactionWrappers[0].cardTransaction.id;
        subject.itemizeUserCardTransaction();

        system.assert(subject.hasPageError == false);

        system.assert(subject.hasItemizedCardTransaction == true);
        system.assert(subject.itemizedTransWrapper.itemizedTransactions.size() == 2);

        subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
        subject.itemizedTransWrapper.itemizedTransactions[1].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
        subject.itemizedTransWrapper.itemizedTransactions[1].billable = false;
        subject.itemizedTransWrapper.itemizedTransactions[1].personal = true; // make this one personal!

        // with amounts updated, should succeed
        subject.addItemizedToExpenseReport();

        // system.debug('\n ***********  pageErrorMessage > ' + subject.pageErrorMessage);

        system.assert(subject.hasPageError == false);
        Id cardTransId = subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.id;

        PSA_Card_Transaction_Item__c[] pctItems = [
                select id, psa_card_transaction__c, psa_expense_report__c
                from PSA_Card_Transaction_Item__c
                where psa_expense_report__c = :testExpenseReport.id];

        system.assert(pctItems != null && pctItems.size() > 0);
        delete pctItems; // cover trigger handler delete!!!


        test.stopTest();
    }

/*
*/
    //
    @isTest static void itItemizesToMultipleExpenseReports()
    {
        pse__Expense_Report__c testExpenseReport2 = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, false);

        test.startTest();

        insert new pse__Expense_Report__c[]{testExpenseReport, testExpenseReport2}; // attempt to get around too many soql...
        testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist');

        system.runAs(testUser)
        {

            psaExpenseAddCardTransactionsController subject = getSubject();
            system.assert(subject != null);

            // cover itemizing and cancelling

            // select the rows
            system.assert(subject.cardTransactionWrappers.size() > 2);

            // select the first row....
            subject.cardTransactionWrappers[0].selected = true;


            subject.transactionIdToItemize = subject.cardTransactionWrappers[0].cardTransaction.id;
            subject.itemizeUserCardTransaction();

            subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
            subject.itemizedTransWrapper.itemizedTransactions[0].cardTransaction.PSA_Expense_Report__c = testExpenseReport.id;

            subject.itemizedTransWrapper.itemizedTransactions[1].cardTransaction.PSA_Amount_in_Original_Currency__c = 50;
            subject.itemizedTransWrapper.itemizedTransactions[1].cardTransaction.PSA_Expense_Report__c = testExpenseReport2.id;

            // with amounts updated, should succeed
            subject.addItemizedToExpenseReport();

    system.debug('\n ***********  pageErrorMessage > ' + subject.pageErrorMessage);

            system.assert(subject.hasPageError == false);
            Set<Id> cardTransItemIds = new Set<Id>();
            for (PSA_Card_Transaction_Item__c  er : [select id, PSA_Expense_Report__c from PSA_Card_Transaction_Item__c where PSA_Expense_Report__c = :testExpenseReport.id])
            {
                cardTransItemIds.add(er.id);
            }

            system.assert(cardTransItemIds != null && cardTransItemIds.size() > 0);

            psaCardTransactionLoader.unassignCardTransactionItems(cardTransItemIds);
        }

        test.stopTest();


    }


    @isTest static void itMatchesExpenses()
    {
        test.startTest();

        insert testExpenseReport; // attempt to get around too many soql...

        // mock up an expense
        pse__Expense__c testExpense =  psaTestUtils.createTestExpense(testExpenseReport.pse__Project__c, testExpenseReport.pse__Resource__c, 1.23, 'String type', false);
        testExpense.pse__Expense_Report__c = testExpenseReport.id;
        insert testExpense;

        //testExpenseReport.pse__Status__c = 'Submitted';
        //testExpenseReport.pse__Submitted__c = true;
        //update testExpenseReport;

        psaExpenseAddCardTransactionsController subject = getSubject(testExpenseReport);
        system.assert(subject != null);

        subject.cardTransIdToMap = subject.cardTransactionWrappers[0].cardTransaction.id;
        subject.expenseIdToMap = testExpense.id;

        // map transaction and expense....
        subject.mapTransactionToExpense();


        // with prev entered checked
        subject.prevCardTransMap = 'true';
        subject.cardTransIdToMap = subject.cardTransactionWrappers[0].cardTransaction.id;
        subject.expenseIdToMap = testExpense.id;
        subject.mapTransactionToExpense();

        // with missing card
        subject.cardTransIdToMap = '';
        subject.expenseIdToMap = '';
        subject.mapTransactionToExpense();

        // with bogus ids card
        subject.cardTransIdToMap = 'bogusid';
        subject.expenseIdToMap = testExpense.id;
        subject.mapTransactionToExpense();

        // cover add single...
        subject.cardTansIdToAdd = subject.cardTransactionWrappers[1].cardTransaction.id;
        subject.addSingleItemToExpenseReport();

        // with approved!
        //testExpenseReport.pse__Status__c = 'Approved';
        //testExpenseReport.pse__Approved__c = true;
        //update testExpenseReport;

        //subject.prevCardTransMap = 'true';
        //subject.cardTransIdToMap = subject.cardTransactionWrappers[0].cardTransaction.id;
        //subject.expenseIdToMap = testExpense.id;
        //subject.mapTransactionToExpense();


        // cover adding and removing temp permission
        subject.createTempPermission(testExpense);
        subject.removeTempPermission();

        // cover this!
        system.assert(subject.hideCardTransactionTable != null);

        test.stopTest();
    }

    // cover our remote action expense lookup
    @isTest static void itLooksupExpenses()
    {
        test.startTest();

        Datetime fromDT = Datetime.now();
        fromDT.addDays(-10);
        fromDT.format('yyyy-MM-dd');

        Datetime toDT = Datetime.now();
        toDT.addDays(10);
        toDT.format('yyyy-MM-dd');


        Map<String, Object> payload = new Map<String, Object>();
        //payload.put('resourceId', c.id);
        payload.put('status', 'Any');
        payload.put('fromExpDate', fromDT.format('yyyy-MM-dd'));
        payload.put('toExpDate', toDT.format('yyyy-MM-dd'));
        payload.put('userExpenseReportId', testExpenseReport);
        payload.put('expenseReportName', testExpenseReport.Name);
        payload.put('expenseNotes', 'testExpenseReport.Name');
        payload.put('offset', 0);
        payload.put('limit', 10);

        // payload without a resource id...to trigger/cover error
        Map<String, Object> errResourceIdRslt = psaExpenseAddCardTransactionsController.lookupExpenses(JSON.serialize(payload));
        system.assert(errResourceIdRslt != null);

        // add resource id to payload and trigger good
        payload.put('resourceId', c.id);
        Map<String, Object> rslt = psaExpenseAddCardTransactionsController.lookupExpenses(JSON.serialize(payload));
        system.assert(rslt != null);

        // remove this indicator to cover by name and or notes:
        payload.remove('userExpenseReportId');
        payload.put('status', 'Draft');
        Map<String, Object> rsltByNameOrNotes = psaExpenseAddCardTransactionsController.lookupExpenses(JSON.serialize(payload));
        system.assert(rsltByNameOrNotes != null);



        // cover it returns an error when the json is invalid
        Map<String, Object> errRslt = psaExpenseAddCardTransactionsController.lookupExpenses(JSON.serialize(new Object[]{}));
        system.assert(errRslt != null);

        test.stopTest();
    }

    // --------------------------------------------------------------------------
    // Convenient methods for constructing test subjects
    // --------------------------------------------------------------------------

    private static psaExpenseAddCardTransactionsController getSubject() {
        return getSubject(null);
    }


    private static psaExpenseAddCardTransactionsController getSubject(pse__Expense_Report__c er) {
        test.setCurrentPage(Page.psaExpenseAddCardTransactions);
        psaExpenseAddCardTransactionsController ctr = null;
        if (er != null)
        {
            ApexPages.currentPage().getParameters().put('id', er.id);
            ApexPages.StandardController stdController = new ApexPages.StandardController(er);
            ctr = new psaExpenseAddCardTransactionsController(stdController);
        }
        else
        {
            ctr = new psaExpenseAddCardTransactionsController();
        }
        return ctr;
    }

    // --------------------------------------------------------------------------
    // Mock / Stub Test Data
    // --------------------------------------------------------------------------

    private static void setupTestData()
    {
        psaTestUtils.initDefaultWorkCalendar();
        
        psaTestUtils.createPSATriggersCustomSetting(true);
        
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
        //User testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        c = psaTestUtils.createTestResource(testUser, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);

        testUser.ManagerId = u2.id;
	
        testProject = psaTestUtils.createTestProjectInProgressWithExpenseEntry('Test Project', a, testR, testP, 
            testG, null, c, testUser);
        

        pse__Permission_Control__c[] permissions = new pse__Permission_Control__c[]{};
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Staffing__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= testR.id, pse__Staffing__c=true, pse__Cascading_Permission__c = true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Resource__c = c.id, pse__Expense_Entry__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Resource__c = c.id, pse__Staffing__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=testUser.id, pse__Region__c= testR.id, pse__Staffing__c=true, pse__Cascading_Permission__c = true));

        insert permissions;

        ////////////

        pw_cc__CountryObject__c pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = 'USA',
            pw_cc__IsoCode_2__c = 'US'
        );
        insert pcc;

        pw_cc__State__c pcs = new pw_cc__State__c(
            name = 'United States',
            pw_cc__Country__c = pcc.id,
            pw_cc__IsoCode__c = 'VA');
        insert pcs;


        testExpenseReport = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, false);

        // insert a psa card transactions......
        psa_card_transaction__c ct1 = new psa_card_transaction__c();
        ct1.PSA_Salesforce_User__c = testUser.id;
        ct1.PSA_Resource__c = c.id;
        ct1.PSA_Resource_Inactive__c = false;
        ct1.PSA_Amount_in_Original_Currency__c = 100.00;
        ct1.PSA_Expense_Type__c = 'Hotel';
        ct1.PSA_Transaction_Date__c = Date.today();
        ct1.PSA_Incurred_Country__c = pcc.id;
        //ct1.PSA_Incurred_State_Province__c = pcs.id;


        psa_card_transaction__c ct2 = new psa_card_transaction__c();
        ct2.PSA_Salesforce_User__c = testUser.id;
        ct2.PSA_Resource__c = c.id;
        ct2.PSA_Resource_Inactive__c = false;
        ct2.PSA_Amount_in_Original_Currency__c = 100.00;
        ct2.PSA_Expense_Type__c = 'Hotel';
        ct2.PSA_Transaction_Date__c = Date.today();
        ct2.PSA_Incurred_Country__c = pcc.id;
        //ct2.PSA_Incurred_State_Province__c = pcs.id;


        psa_card_transaction__c ct3 = new psa_card_transaction__c();
        ct3.PSA_Salesforce_User__c = testUser.id;
        ct3.PSA_Resource__c = c.id;
        ct3.PSA_Resource_Inactive__c = false;
        ct3.PSA_Amount_in_Original_Currency__c = 100.00;
        ct3.PSA_Expense_Type__c = 'Hotel';
        ct3.PSA_Transaction_Date__c = Date.today();
        ct3.PSA_Incurred_Country__c = pcc.id;
        //ct3.PSA_Incurred_State_Province__c = pcs.id;

        testCardTransactions = new psa_card_transaction__c[]{ct1, ct2, ct3};
        insert testCardTransactions;

    }


    // todo...test it!
}