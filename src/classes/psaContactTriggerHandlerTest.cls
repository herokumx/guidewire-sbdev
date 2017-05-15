@isTest
private class psaContactTriggerHandlerTest {
	
	@isTest static void test_method_one() {
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager

        PSA_Department__c dep = new PSA_Department__C();
        dep.Name = 'Test Department';
        dep.PSA_Department_Code__c = '1243';
        dep.PSA_PS_Department__c = true;
        insert dep;

        PSA_PS_Level_Billing_Level__c level1 = new PSA_PS_Level_Billing_Level__c();
        level1.PSA_Billing_Level__c = '100';
        level1.PSA_PS_Level__c = '100';
        level1.PSA_Title__c = 'The Title';
        insert level1;

        PSA_PS_Level_Billing_Level__c level2 = new PSA_PS_Level_Billing_Level__c();
        level2.PSA_Billing_Level__c = '200';
        level2.PSA_PS_Level__c = '200';
        level2.PSA_Title__c = 'The Title 2';
        insert level2;

        PSA_Entity__c entity = new PSA_Entity__c();
        entity.PSA_Billing_Entity__c = false;
        entity.psa_entity_code__c = '1234';
        entity.PSA_GLA_In__c = '515324';
        entity.PSA_GLA_Out__c = '15345';
        entity.PSA_Short_Name__c = 'name1';
        insert entity;

        PSA_Cost_Rate__c rate = new PSA_Cost_Rate__c();
        rate.CurrencyIsoCode = 'USD';
        rate.PSA_Delivery_Cost_Rate__c = 123;
        rate.PSA_Effective_Date__c = Date.Today() - 5;
        rate.PSA_Fully_Loaded_Cost_Rate__c = 143;
        rate.PSA_Legal_Entity__c = entity.id;
        rate.PSA_PS_Level__c = '100';
        rate.PSA_Propagated_Date__c = Date.Today() - 4;
        rate.PSA_Department__c = dep.id;
        insert rate;

 

        Test.StartTest();
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG, false);
        c.LastName = 'Test1';
        c.PSA_Termination_Date__c = Date.today() + 15;
        c.PSA_Absence_Start_Date__c = Date.today() - 5;
        c.PSA_Absence_End_Date__c = Date.today() + 5;
        c.PSA_PS_Level__c = '100';
        c.PSA_Global_Mobile__c = true;
        insert c;

        User u2 = psaTestUtils.createTestUser('userCLD3', 'tuserCLD3@tuser.com', 'userCLD3', 'test3', 'tuserCLD3@tuser.com', 'tuserCLD3');
        Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG, false);
        c2.PSA_Termination_Date__c = Date.today() + 15;
        c2.lastName = 'Test2';
        c2.PSA_Absence_Start_Date__c = Date.today() - 5;
        c2.PSA_Absence_End_Date__c = Date.today() + 5;
        c2.PSA_PS_Level__c = '100';
        c2.PSA_Global_Mobile__c = false;
        c2.PSA_Resource_Department__c = dep.id;
        insert c2;

        //Testing an updated contact where department changes, 
        PSA_Department__c dep2 = new PSA_Department__C();
        dep2.Name = 'Test Department';
        dep2.PSA_Department_Code__c = '1243';
        dep2.PSA_PS_Department__c = false;
        insert dep2;

        PSA_Department__c dep3 = new PSA_Department__C();
        dep3.Name = 'Test Department';
        dep3.PSA_Department_Code__c = '1243';
        dep3.PSA_PS_Department__c = false;
        insert dep3;

        PSA_Cost_Rate__c rate2 = new PSA_Cost_Rate__c();
        rate2.CurrencyIsoCode = 'USD';
        rate2.PSA_Delivery_Cost_Rate__c = 123;
        rate2.PSA_Effective_Date__c = Date.Today() - 5;
        rate2.PSA_Fully_Loaded_Cost_Rate__c = 143;
        rate2.PSA_Legal_Entity__c = entity.id;
        rate2.PSA_PS_Level__c = '200';
        rate2.PSA_Propagated_Date__c = Date.Today() - 4;
        rate2.PSA_Department__c = dep2.id;
        insert rate2;


        c2.PSA_Absence_End_Date__c = Date.Today() + 4;
        c2.PSA_Absence_Start_Date__c = Date.Today() - 6;
        c2.PSA_Resource_Department__c = dep3.id;
        c2.PSA_PS_Level__c = '300';
        c2.PSA_Global_Mobile__c = true;
        c2.PSA_Termination_Date__c = Date.Today() + 25;
        update c2;

        c2.PSA_Global_Mobile__c = false;
        update c2;


	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}