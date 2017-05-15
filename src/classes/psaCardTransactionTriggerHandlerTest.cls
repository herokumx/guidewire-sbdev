/*************************************************************************
Name:           psaCardTransactionTriggerHandlerTest
Author:         CLD
Created Date:   10/20/2015
Description:    Tests related to psaCardTransactionTriggerHandler
*************************************************************************/
@isTest(seeAllData=false)
private class psaCardTransactionTriggerHandlerTest
{

    static pse__Expense_Report__c testExpenseReport;
    static pse__Expense__c testExpense;
    static psa_card_transaction__c testCardTransaction;
    static psa_card_transaction_item__c[] testCardTransactionItems;
    static User testUser;
    static Contact c;

    static {
        setupTestData();
    }

    @isTest static void itUnassignsWhenPreviouslyEnteredUnchecked()
    {
        test.startTest();

        setupTestStartedData(); // attempt to get around too many soql issues


        testCardTransaction.PSA_Previously_Entered__c = false;
        update testCardTransaction;


        psa_card_transaction__c[] postCardTrans = [
            select id, PSA_Previously_Entered__c, PSA_Status__c
            from psa_card_transaction__c
            where id = :testCardTransaction.id
        ];
        system.assert(postCardTrans != null && postCardTrans.size() > 0);

        system.assert(postCardTrans[0].PSA_Status__c == 'Unassigned');

        test.stopTest();
    }

    // -- covers non used, but implemented PsaITriggerHandler instances
    @isTest static void itImplementsITriggerHandler()
    {
        test.startTest();

        PsaITriggerHandler th = new psaCardTransactionTriggerHandler();
        try{ th.bulkBefore(); } catch(Exception e) { }
        try{ th.bulkAfter(); } catch(Exception e) { }
        try{ th.beforeInsert(null); } catch(Exception e) { }
        //try{ th.beforeUpdate(null, null); } catch(Exception e) { }
        try{ th.beforeDelete(null); } catch(Exception e) { }
        try{ th.afterInsert(null); } catch(Exception e) { }
        try{ th.afterUpdate(null, null); } catch(Exception e) { }
        try{ th.afterDelete(null); } catch(Exception e) { }

        test.stopTest();
    }

    private static void setupTestData()
    {
        psaTestUtils.initDefaultWorkCalendar();
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

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, testUser);
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;

        pse__Permission_Control__c[] permissions = new pse__Permission_Control__c[]{};
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Staffing__c=true));
        permissions.add(new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= testR.id, pse__Staffing__c=true, pse__Cascading_Permission__c = true));
        insert permissions;

        testExpenseReport = psaTestUtils.createTestExpenseReport('Test Expense Report', testProject.id, c.id, false);

        testExpense = psaTestUtils.createTestExpenseOnReport(testExpenseReport.id, testProject.id, c.id, 500, 'Lodging - Hotel', Date.today(), false);

    }

/*
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

*/

    private static void setupTestStartedData()
    {
        insert testExpenseReport;

        // insert a psa card transactions......
        psa_card_transaction__c ct1 = new psa_card_transaction__c();
        ct1.PSA_Salesforce_User__c = testUser.id;
        ct1.PSA_Resource__c = c.id;
        ct1.PSA_Resource_Inactive__c = false;
        ct1.PSA_Amount_in_Original_Currency__c = 100.00;
        ct1.PSA_Expense_Type__c = 'Hotel';
        ct1.PSA_Transaction_Date__c = Date.today();
        ct1.PSA_Expense_Report__c = testExpenseReport.id;
        ct1.PSA_Previously_Entered__c = true;

        insert ct1;



testCardTransaction = ct1;

        testExpense.pse__Expense_Report__c = testExpenseReport.id;
        testExpense.psa_card_transaction__c = ct1.id;
        insert testExpense;

        // create a couple of card transaction items
        testCardTransactionItems = new PSA_Card_Transaction_Item__c[]{};
        testCardTransactionItems.add(
            new PSA_Card_Transaction_Item__c(
                psa_card_transaction__c = ct1.id,
                psa_charge_type__c = 'Company',
                PSA_Amount_in_Original_Currency__c = 50
            )
        );

        testCardTransactionItems.add(
            new PSA_Card_Transaction_Item__c(
                psa_card_transaction__c = ct1.id,
                psa_charge_type__c = 'Personal',
                PSA_Amount_in_Original_Currency__c = 50
            )
        );

        insert testCardTransactionItems;
    }

}