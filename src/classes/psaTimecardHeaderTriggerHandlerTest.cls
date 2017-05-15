/****************************************************************************************
Name            : psaTimecardHeaderTriggerHandlerTest
Author          : CLD Partners 
Created Date    : May 11, 2015 
Description     : Contains methods to test timecard header trigger handler logic 
                    
Revisions       : 2015 -  Initial version 
                : 2016-02-08  Klassen  Revised to avoid soql limits error and add more 
                    code coverage, including adding a second test method
******************************************************************************************/
@isTest
private class psaTimecardHeaderTriggerHandlerTest {
    
    @isTest (seealldata=false)
    static void test_method_one() {
        //** load test data files from static resources
        Test.loadData(appirio_core__Config_Group__c.SObjectType, 'TestDataConfigGroups');
        Test.loadData(appirio_core__Config_Option__c.SObjectType, 'TestDataConfigOptions');
        Test.loadData(appirio_core__Config_Value__c.SObjectType, 'TestDataConfigValues');

        psaTestUtils.disableAsmTriggers('false');
        Try {
            psaTestUtils.disablePsaTriggers();
        } Catch (Exception ex) {
            System.debug('Failed to disable PSA_Triggers');
        }

        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG 
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        a.BillingStreet = '123 Sesame Street';
        a.BillingCity = 'Sesame City';
        a.BillingState = 'CA';
        a.BillingPostalCode = '90210';
        a.BillingCountry = 'USA';
        update a;

        Account cust = psaTestUtils.createTestAccount('Test Customer', '23456');
        cust.BillingStreet = '901 Lane ln';
        cust.BillingCity = 'Guatemala';
        cust.BillingState = 'FS';
        cust.BillingPostalCode='11111';
        cust.BillingCountry = 'USA';
        update cust;

        Account aChild = psaTestUtils.createTestAccount('Test BillingChild', '34567');
        aChild.BillingStreet = '901 Lane ln';
        aChild.BillingCity = 'Guatemala';
        aChild.BillingState = 'GO';
        aChild.BillingPostalCode='11112';
        aChild.BillingCountry = 'USA';
        aChild.parentId = a.id;
        update aChild;

        Account cChild = psaTestUtils.createTestAccount('Test CustomerChild', '45678');
        cChild.BillingStreet = '901 Lane ln';
        cChild.BillingCity = 'Guatemala';
        cChild.BillingState = 'GO';
        cChild.BillingPostalCode='11112';
        cChild.BillingCountry = 'USA';
        cChild.parentId = cust.id;
        update cChild;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Fully_Loaded_Cost_Rate__c = 123;
        c.PSA_Resource_Entity__c = testentity.id;
        c.MailingCity = 'Ellicott City';
        c.MailingState = 'MD';
        c.MailingPostalCode = '21042';
        c.MailingCountry = 'USA';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;
        update u;
        
        //Create the project and assignment and assure that locations were created
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        //testProject.PSA_Customer_Account__c = cust.id;
        testProject.pse__Closed_for_Time_Entry__c = false;      
        update testProject;

        pse__Project_Phase__c phase1 = new pse__Project_Phase__c();
        phase1.name = 'Creation';
        phase1.pse__Start_Date__c = Date.today();
        phase1.pse__End_Date__c = Date.today()+90;
        phase1.pse__Project__c = testProject.id;
        insert phase1;

        pse__Project_Location__c pl = new pse__ProjecT_Location__c();
        pl.name = 'Home Location';
        pl.pse__Project__c = testProject.id;
        insert pl;
        pse__Project_Location__c pl2 = new pse__ProjecT_Location__c();
        pl2.name = 'Client Location';
        pl2.pse__Project__c = testProject.id;
        insert pl2;
//      List<pse__Project_Location__c> locs = [Select id from pse__Project_Location__c where pse__Project__c = :testProject.id];
//      System.debug(LoggingLevel.ERROR, '*** Locations size: '+locs);
        pse__Assignment__c testAssignment = psaTestUtils.createTestAssignment(testProject, c, 'Data Migration Specialist', Date.today(), Date.today()+90);
        testAssignment.PSA_Rate_Needs_Review__c = false;
        update testAssignment;
        
        Test.startTest();

        Date tcDate = Date.today() + 7;
        //Avoid any date that might cause a timecard to span 2 time periods which would trigger an error
        if (tcDate.day() <=7) {
            tcDate += 7;
        }
        pse__Timecard_Header__c testCard = psaTestUtils.initTestTimecardHeader(testProject.id, c.id, testAssignment.id, tcDate, 8, phase1);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Timecard_Entry__c =true);
        testCard.pse__Primary_Project_Location__c = pl.Id; //locs.get(0).id;
        insert testCard;

        System.debug(LoggingLevel.ERROR, '*** Time card is: '+testCard);
        Pse__Time_Date__c testTD = new PSE__Time_Date__c();
        testTD.pse__Timecard__c = testCard.id;
        testTD.pse__Date__c = Date.today();
        testTD.pse__Hours__c = 8;
        insert testTD;

        testTD.pse__Hours__c = 7;
        update testTD;


        List<pse__Time_Date__c> timeDates = [Select id from pse__Time_Date__c where pse__Timecard__c = :testCard.id];
        System.debug(LoggingLevel.ERROR, '*** Time dates created: '+timeDates);

        testProject.PSA_Time_Approval_Method__c = 'Resource Manager';
        testProject.pse__Project_Type__c = 'Internal';
        testProject.pse__Start_Date__c = Date.Today() + 10;
        update testProject;
        /*pse__Assignment__c testAssignment2 = psaTestUtils.createTestAssignment(testProject, c, 'Business Consultant');
        testAssignment2.PSA_Rate_Needs_Review__c = false;
        update testAssignment2;*/

        /*pse__Timecard_Header__c testCard2 = psaTestUtils.initTestTimecardHeader(testProject.id, c.id, testAssignment.id, Date.today(), 8, phase1);
        System.debug(LoggingLevel.ERROR, '*** Time card is: '+testCard2);
        testCard2.pse__Primary_Project_Location__c = locs.get(0).id;
        insert testCard2;*/
        testCard.pse__Primary_Project_Location__c = pl2.Id; //locs.get(1).id;
        testCard.pse__Bill_Rate__c = 265;
        update testCard;

        Test.stopTest();

    }

    @isTest (seealldata=false)
    static void test_multiple_months() {
        //** load test data files from static resources
        Test.loadData(appirio_core__Config_Group__c.SObjectType, 'TestDataConfigGroups');
        Test.loadData(appirio_core__Config_Option__c.SObjectType, 'TestDataConfigOptions');
        Test.loadData(appirio_core__Config_Value__c.SObjectType, 'TestDataConfigValues');

        psaTestUtils.disableAsmTriggers('false');
        Try {
            psaTestUtils.disablePsaTriggers();
        } Catch (Exception ex) {
            System.debug('Failed to disable PSA_Triggers');
        }

        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG 
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        //Create test account with a location so that locations will be created
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        a.BillingStreet = '123 Sesame Street';
        a.BillingCity = 'Sesame City';
        a.BillingState = 'CA';
        a.BillingPostalCode = '90210';
        a.BillingCountry = 'USA';
        update a;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        c.PSA_Fully_Loaded_Cost_Rate__c = 123;
        c.PSA_Resource_Entity__c = testentity.id;
        c.MailingCity = 'Ellicott City';
        c.MailingState = 'MD';
        c.MailingPostalCode = '21042';
        c.MailingCountry = 'USA';
        update c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
        
        u.ManagerId = u2.id;
        update u;

        //Create the project and assignment and assure that locations were created
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Milestone_Required__c = false;
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        //testProject.PSA_Customer_Account__c = cust.id;
        testProject.pse__Closed_for_Time_Entry__c = false;      
        update testProject;

        pse__Project_Phase__c phase1 = new pse__Project_Phase__c();
        phase1.name = 'Creation';
        phase1.pse__Start_Date__c = Date.today();
        phase1.pse__End_Date__c = Date.today()+90;
        phase1.pse__Project__c = testProject.id;
        insert phase1;

        pse__Project_Location__c pl = new pse__ProjecT_Location__c();
        pl.name = 'Home Location';
        pl.pse__Project__c = testProject.id;
        insert pl;
        pse__Assignment__c testAssignment = psaTestUtils.createTestAssignment(testProject, c, 'Data Migration Specialist', Date.today(), Date.today()+90);
        testAssignment.PSA_Rate_Needs_Review__c = false;
        update testAssignment;

        
        Test.startTest();

        //Start on a day which will cause the timecard to span multiple months
       // Date tcDate = Date.newInstance(2016, 2, 1);
       // Date tcDate = Date.today() + 7;
        Date tcDate = Date.today() + 14;
        pse__Timecard_Header__c testCard = psaTestUtils.initTestTimecardHeader(testProject.id, c.id, testAssignment.id, tcDate, 8, phase1);
        testCard.pse__Tuesday_Hours__c = 8;
        testCard.pse__Wednesday_Hours__c = 8;
        testCard.pse__Thursday_Hours__c = 8;
        testCard.pse__Friday_Hours__c = 8;
        testCard.pse__Billable__c = true;
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Timecard_Entry__c =true);
        testCard.pse__Primary_Project_Location__c = pl.Id;
        insert testCard;

        Test.stopTest();

    }       
}