/*************************************************************************
Name:           psaExpenseAttachmentManagementTest
Author:         CLD
Created Date:   10/20/2015
Description:    Tests related to psaExpenseAttachmentManagementController
*************************************************************************/
@isTest(seeAllData=false)
private class psaExpenseAttachmentManagementTest
{
    static pse__Expense_Report__c testExpenseReport;
    static pse__Expense__c testExpense;

    static {
        setupTestData();
    }



    @isTest static void itListsReceiptAttachments()
    {
        ApexPages.StandardController stdController = new ApexPages.StandardController(testExpenseReport);

        test.startTest();

        // attempt to get around too many soql issues
        // more setup!!!!
        insert testExpenseReport;
        testExpense.pse__Expense_Report__c = testExpenseReport.id;
        insert testExpense;
        //

        test.setCurrentPage(Page.psaExpenseAttachmentManagement);


        // verify we have an error that requires us to pass an id, when calling the page without an id
        psaExpenseAttachmentManagementController subject1 = new psaExpenseAttachmentManagementController(new ApexPages.StandardController(new pse__Expense_Report__c()));
        system.assertEquals(subject1.hasPageError, true);
        system.assertNotEquals(subject1.pageErrorMessage, '');


        // verify we succeed when passing a valid id
        ApexPages.currentPage().getParameters().put('id', testExpenseReport.id);
        psaExpenseAttachmentManagementController subject2 = new psaExpenseAttachmentManagementController(stdController);
        system.assertNotEquals(subject2.userExpenseReport, null);
        system.assertNotEquals(subject2.userExpenseLines, null);
        system.assertNotEquals(subject2.hasPageError, true);

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
        User testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(testUser, testR, testP, testG);
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
}