@isTest
private class psaRateSetTest {
    
    @isTest static void test_method_one() {
        PageReference pg = Page.psaRateSetEntry; 
        test.setCurrentPage(pg); 
        //Set up background objects
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

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);

        Id projId = testProject.id;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('prjid', projId); 
        psaRateSetController rsc = new psaRateSetController();
        rsc.close();

        
        PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
        rs.PSA_Project__c = projId;
        rs.PSA_Is_Global__c = false;
        insert rs;

        PSA_Rate__c rate = new PSA_Rate__c();
        rate.psa_Billing_Level__c = '120';
        rate.PSA_Average_Cost_Rate__c = 35;
        rate.PSA_Bill_Rate_Amount__c = 80;
        rate.PSA_Start_Date__c = Date.Today();
        rate.PSA_End_Date__c = Date.Today() + 90;
        rate.PSA_Bill_Rate_Set__c = rs.id;
        insert rate;

        PSA_Rate__c rate2 = new PSA_Rate__c();
        rate2.psa_Billing_Level__c = '130';
        rate2.PSA_Average_Cost_Rate__c = 35;
        rate2.PSA_Bill_Rate_Amount__c = 80;
        rate2.PSA_Start_Date__c = Date.Today();
        rate2.PSA_End_Date__c = Date.Today() + 90;
        rate2.PSA_Bill_Rate_Set__c = rs.id;
        insert rate2;

        List<psaRateSetController.PSARateModel> rsm = new List<psaRateSetController.PSARateModel>();
        psaRateSetController.PSARateModel rateModel = new psaRateSetController.PSARateModel();
        rateModel.rateRecord = rate;
        psaRateSetController.PSARateModel rateModel2 = new psaRateSetController.PSARateModel('USD');
        rateModel2.rateRecord = rate2;
        rsm.add(rateModel);
        rsm.add(rateModel2);


        rsc = new psaRateSetController();
        rsc.listRateModel = rsm;
        rsc.addNewRate();
        rsc.refreshValues();

        rsc.listRateModel.get(0).isCheck = true;
        rsc.listRateModel.get(1).isCheck = true;
        rsc.removeRate();
        rsc.save();
        rsc.saveAndReturn();

        Test.stopTest();
    }
    
    @isTest static void testLoadFromProject() {

        PageReference pg = Page.psaRateSetEntry; 
        test.setCurrentPage(pg); 
        //Set up background objects
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

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        Test.startTest();
        Id projId = testProject.id;

        ApexPages.currentPage().getParameters().put('prjid', projId); 
        psaRateSetController rsc = new psaRateSetController();

        PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
        rs.PSA_Project__c = projId;
        rs.PSA_Is_Global__c = false;
        insert rs;

        PSA_Rate__c rate = new PSA_Rate__c();
        rate.psa_Billing_Level__c = '120';
        rate.PSA_Average_Cost_Rate__c = 35;
        rate.PSA_Bill_Rate_Amount__c = 80;
        rate.PSA_Start_Date__c = Date.Today();
        rate.PSA_End_Date__c = Date.Today() + 90;
        rate.PSA_Bill_Rate_Set__c = rs.id;
        insert rate;
        System.debug(LoggingLevel.ERROR, 'Trying to load from the project');
        rsc.loadFromProject();
        test.stopTest();

    }

    @isTest static void testLoadFromAccount() {
        PageReference pg = Page.psaRateSetEntry; 
        test.setCurrentPage(pg); 
        //Set up background objects
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

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        Test.startTest();
        Id projId = testProject.id;

        ApexPages.currentPage().getParameters().put('prjid', projId); 
        psaRateSetController rsc = new psaRateSetController();
        rsc.doesAccountRateExist();

        PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
        rs.PSA_Account__c = a.Id;
        rs.PSA_Is_Global__c = false;
        insert rs;

        PSA_Rate__c rate = new PSA_Rate__c();
        rate.psa_Billing_Level__c = '120';
        rate.PSA_Average_Cost_Rate__c = 35;
        rate.PSA_Bill_Rate_Amount__c = 80;
        rate.PSA_Start_Date__c = Date.Today();
        rate.PSA_End_Date__c = Date.Today() + 90;
        rate.PSA_Bill_Rate_Set__c = rs.id;
        insert rate;

        System.debug(LoggingLevel.ERROR, 'Does the rate exist?');

        rsc.doesAccountRateExist();
        System.debug(LoggingLevel.ERROR, 'loading from the account');
        rsc.loadFromAccount();
        Test.stopTest();

    }

    
}