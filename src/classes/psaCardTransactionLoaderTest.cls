/*************************************************************************
Name:           psaCardTransactionLoaderTest
Author:         CLD
Created Date:   10/20/2015
Description:    Tests related to psaCardTransactionLoader
*************************************************************************/
@isTest(seeAllData=false)
private class psaCardTransactionLoaderTest
{
    static PSA_Card_Transaction_Stage__c[] stageObjects;
    static Contact testResource;
    static Contact testResource2;

    static pw_cc__CountryObject__c pcc ;
    static pw_cc__State__c pcs ;

    static  {
        setupTestData();
    }

    @isTest static void itSchedulesAndLoadsCardTransactions()
    {
        Integer preTransCount = [select count() from PSA_Card_Transaction__c];

        Test.startTest();

        psaCardTransactionLoaderSchedule s = new psaCardTransactionLoaderSchedule();
        s.execute(null);

        Test.stopTest();

        // verify our card transactions were created
        Integer postTransCount = [select count() from PSA_Card_Transaction__c];
        system.assert(postTransCount > preTransCount);

        // cover unassigning card transactions!
        Set<Id> stageIds = new Set<Id>();
        for (PSA_Card_Transaction__c ct : [select id from PSA_Card_Transaction__c limit 2]){  stageIds.add(ct.id); }
        psaCardTransactionLoader.unassignCardTransactions(stageIds);
    }

    @isTest static void itSyncsResourceAndOwnerFromUser()
    {
        Test.startTest();

        PSA_Card_Transaction__c cardTrans = new PSA_Card_Transaction__c();
        cardTrans.PSA_Incurred_Country__c = pcc.id;
        cardTrans.PSA_Incurred_State_Province__c = pcs.id;

        insert cardTrans;

        cardTrans.PSA_Salesforce_User__c = testResource.pse__Salesforce_User__c;

        update cardTrans;

        psaCardTransactionLoader.syncResourceAndOwnerFromUser(new PSA_Card_Transaction__c[]{cardTrans});

        Test.stopTest();

        PSA_Card_Transaction__c psaCardTrans = [select id,PSA_Salesforce_User__c,PSA_Resource__c,OwnerId,PSA_Operations_Review__c, PSA_Operations_Review_Reason__c, PSA_Incurred_Country__c, PSA_Incurred_State_Province__c from PSA_Card_Transaction__c where id = :cardTrans.id];

        //system.debug('\n ***************** \n psaCardTrans > ' + psaCardTrans + '\n ************ \n');

        system.assert(psaCardTrans.PSA_Salesforce_User__c == testResource.pse__Salesforce_User__c);
        system.assert(psaCardTrans.PSA_Resource__c == testResource.id);
        system.assert(psaCardTrans.OwnerId == testResource.pse__Salesforce_User__c);

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

        //User testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        User testUser = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        testUser.PSA_Worker_Id__c = 'userCLD2';

        User testUser2 = psaTestUtils.createTestUser('uCLDTST', 'tuserCLDTST@tuser.com', 'uCLDTST', 'test2TST', 'tuserCLDTST@tuser.com', 'tuserCLD2TST');
        testUser2.PSA_Worker_Id__c = 'userCLDTEST';

        User testUser3 = psaTestUtils.createTestUser('userCLD3', 'tuseruserCLD3@tuser.com', 'userCLD3', 'test3TST', 'tuseruserCLD3@tuser.com', 'tuserCLD3');
        testUser3.PSA_Worker_Id__c = 'ACTV';

        update new User[]{testUser, testUser2, testUser3};

        //update testUser2;

        testResource = psaTestUtils.createTestResource(testUser, testR, testP, testG);
        testResource.PSA_Resource_Entity__c = testentity.id;
        testResource.PSA_Billing_Level__c = '120';
        testResource.PSA_Worker_Id__c = 'userCLD2';

        update testResource;


        testResource2 = psaTestUtils.createTestResource(testUser3, testR, testP, testG);
        testResource2.PSA_Resource_Entity__c = testentity.id;
        testResource2.PSA_Billing_Level__c = '120';
        testResource2.PSA_Worker_Id__c = 'ACTV';
        testResource2.pse__Is_Resource_Active__c = false;
        update testResource2;


        pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = 'USA',
            pw_cc__IsoCode_2__c = 'US'
        );
        insert pcc;

        pcs = new pw_cc__State__c(
            pw_cc__Country__c = pcc.id,
            pw_cc__IsoCode__c = 'VA');
        insert pcs;

        //PSA_Card_Expense_Type_Map__c expTypeMap = new PSA_Card_Expense_Type_Map__c(
        //    PSA_Card_Expense_Category_Code__c = 'Category1',
        //    PSA_Expense_Type__c = 'ExpType1'
        //);
        //insert expTypeMap;


        // dummy up some card transaction stage objects

        stageObjects = new PSA_Card_Transaction_Stage__c[]{};

        stageObjects.add(new PSA_Card_Transaction_Stage__c(
            PSA_EmployeeId__c = 'userCLD2',
            PSA_Merchant_Country_Code__c = 'USA',
            //PSA_Expense_Category_Code__c = 'Category1',
            PSA_Merchant_State_Province__c = 'VA'
        ));

        // should produce NUSR
        stageObjects.add(new PSA_Card_Transaction_Stage__c(
            PSA_EmployeeId__c = 'xyz',
            PSA_Merchant_Country_Code__c = 'USA',
            //PSA_Expense_Category_Code__c = 'Category1',
            PSA_Merchant_State_Province__c = 'VA'
        ));

        stageObjects.add(new PSA_Card_Transaction_Stage__c(
            PSA_EmployeeId__c = 'userCLDTEST',
            PSA_Merchant_Country_Code__c = 'USA',
            //PSA_Expense_Category_Code__c = 'Category1',
            PSA_Merchant_State_Province__c = 'VA'
        ));

        stageObjects.add(new PSA_Card_Transaction_Stage__c(
            PSA_EmployeeId__c = 'ACTV',
            PSA_Merchant_Country_Code__c = 'USA',
            //PSA_Expense_Category_Code__c = 'Category1',
            PSA_Merchant_State_Province__c = 'VA'
        ));

        // should produce LCTN
        stageObjects.add(new PSA_Card_Transaction_Stage__c(
            PSA_EmployeeId__c = 'userCLD2',
            PSA_Merchant_Country_Code__c = '',
            //PSA_Expense_Category_Code__c = 'Category1',
            PSA_Merchant_State_Province__c = ''
        ));


        insert stageObjects;
   }

}