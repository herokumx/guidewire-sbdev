@isTest
private class psaAttachmentTriggerHandlerTest {
    
    @isTest static void test_method_one() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
      //  Test.startTest();
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
        
        Test.startTest();

        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', false);
        insert expense;

        List<Attachment> attachs = new List<Attachment>();
        Attachment at1 = new Attachment();
        at1.Name = 'Test Attachment';
        at1.parentId = expense.id;
        at1.body = blob.toPDF('This is a fake pdf');
        Attachment at2 = new Attachment();
        at2.Name = 'Test Attachment 2';
        at2.parentId = expense.id;
        at2.body = blob.toPDF('This is a fake pdf2');
        attachs.add(at1);
        attachs.add(at2);
        insert attachs;

        delete attachs;
        Test.stopTest();

    }
    
    @isTest static void testAttachToBE() {
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
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Resource_Entity__c = testentity.id;
        c.PSA_Billing_Level__c = '120';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
        
        Test.startTest();

        System.debug('INSERTING THE EVENT');
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
        event.PSA_Current_Billing_Amount__c = 100;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        insert event;

        List<Attachment> attchs = new List<Attachment>();
        Attachment at1 = new Attachment();
        at1.Name = 'Test Detail.xlsx';
        at1.parentId = event.id;
        at1.body = blob.toPDF('This is a fake xlsx');
        attchs.add(at1);
        Attachment at2 = new Attachment();
        at2.Name = 'Test Detail.pdf';
        at2.parentId = event.id;
        at2.body = blob.toPDF('This is a fake pdf');
        attchs.add(at2);
        insert attchs;
        
        Test.stopTest();

    }
    
}