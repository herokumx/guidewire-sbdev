@isTest
private class psaPDFTest {

    @isTest static void testPDF2(){
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
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.pse__Closed_for_Expense_Entry__c = false;
        update testProject;
        Test.startTest();
        //List<pse__Expense__c> expenses = new List<pse__Expense__c>();
        pse__Expense__c expense = psaTestUtils.createTestExpense(testProject.id, c.id, 500, 'Lodging - Hotel', true);
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = testProject.id;
        event.pse__Status__c = 'Draft';
        event.pse__Date__c = Date.today();
        event.currencyIsoCode = 'USD';
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

        expense.pse__Billing_Event_Item__c = first.id;
        update expense;

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


        PSA_Billing_Event_Expense_Receipt_Docs__c next = new PSA_Billing_Event_Expense_Receipt_Docs__c();
        next.name = 'Test Named';
        next.PSA_Attachment_Ids__c = ''+at1.id+','+at2.id;
        insert next;
        //List<Id> ids = new List<Id>();
        //ids.add(next.id);

        PSA_Combined_Expense_Receipt__c combinedExpReceipt = new PSA_Combined_Expense_Receipt__c();
        combinedExpReceipt.name = 'Test Named';
        combinedExpReceipt.PSA_Attachment_Ids__c = ''+at1.id+','+at2.id;
        insert combinedExpReceipt;
        List<Id> ids = new List<Id>();
        ids.add(combinedExpReceipt.id);

        psaPDFGenerationUtil.doWork(ids, 'BillingEvent', event.Id, 1, 1);
        Test.stopTest();
        //Test.startTest();
        //psaPDFGenerationUtil.generatePDF(ids, UserInfo.getSessionId());
        //Test.stopTest();
    }



}