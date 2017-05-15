/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(seeAllData=true)
public class psaTestUtils
{

    public static pse__Practice__c defaultPractice;
    public static pse__Region__c defaultRegion;
    public static pse__Grp__c defaultGroup;
    public static Contact defaultResource;
    public static pse__Work_Calendar__c defaultWorkCalendar;

    public static final String DEFAULT_PRACTICE_NAME = 'psaTestPractice';
    public static final String DEFAULT_REGION_NAME = 'psaTestRegion';
    public static final String DEFAULT_GROUP_NAME = 'psaTestGroup';
    public static final String DEFAULT_RESOURCE_NAME = 'PSA Test Resource';

    public static final String PROJECT_STAGE_PLANNED = 'Planned';
    public static final String PROJECT_STAGE_ACTIVE = 'In Progress';
    public static final String PROJECT_STAGE_ONHOLD = 'On Hold';
     public static final String PROJECT_STAGE_COMPLETED = 'Completed';
    public static final String PROJECT_STAGE_CANCELED = 'Canceled';
    public static final String PROJECT_STAGE_MISSINGPAPERWORK = 'Missing Paperwork';

    public static final String MILESTONE_STATUS_PLANNED = 'Planned';
    public static final String MILESTONE_STATUS_OPEN = 'Open';
    public static final String MILESTONE_STATUS_SUBMITTED = 'Submitted';
    public static final String MILESTONE_STATUS_APPROVED = 'Approved';
    public static final String MILESTONE_STATUS_CANCELED = 'Canceled';

    public static final String RESOURCE_ROLE_PM = 'Project Manager';
    public static final String RESOURCE_ROLE_CONSULTANT = 'Consultant';

    public static final String PSA_TESTING_USERNAME = 'psateststandarduser@test.org.com';

    public static final String MISCELLANEOUS_ADJUSTMENT_MISC_ADJ = 'MISC_ADJ';
    public static final String MISCELLANEOUS_ADJUSTMENT_REVENUE_ACCRUAL = 'REVENUE_ACCRUAL';
    public static final String MISCELLANEOUS_ADJUSTMENT_REVERSE_ACCRUAL_REVERSAL = 'REVENUE_ACCRUAL_REVERSAL';
    public static final String MISCELLANEOUS_ADJUSTMENT_BILLING_ACCRUAL = 'BILLING_ACCRUAL';
    public static final String MISCELLANEOUS_ADJUSTMENT_BILLING_ACCRUAL_REVERSAL = 'BILLING_ACCRUAL_REVERSAL';

    /*************************************************************
    * Creates a Region with the name provided
    *
    **************************************************************/
    public static pse__Region__c createTestRegion(String regionName)
    {
        initDefaultWorkCalendar();
        pse__Region__c testRegion = new pse__Region__c(Name=regionName, pse__Action_Update_Current_Time_Period__c=false, pse__Current_Time_Period__c = null);
        testRegion.pse__Default_Work_Calendar__c = defaultWorkCalendar.id;
        insert testRegion;
        return testRegion;
    }

    /*************************************************************
    * Creates a Practice with the name provided
    *
    **************************************************************/
    public static pse__Practice__c createTestPractice(String practiceName)
    {
        pse__Practice__c testPractice = new pse__Practice__c(Name=practiceName, pse__Action_Update_Current_Time_Period__c=false, pse__Current_Time_Period__c = null);
        insert testPractice;
        return testPractice;
    }

    /*************************************************************
    * Creates a Group with the name provided
    *
    **************************************************************/
    public static pse__Grp__c createTestGroup(String groupName)
    {
        pse__Grp__c testGroup = new pse__Grp__c(Name=groupName, pse__Action_Update_Current_Time_Period__c=false, pse__Current_Time_Period__c = null);
        insert testGroup;
        return testGroup;
    }

    public static pse__Proj__c createTestProjectInProgress(String projectName, Account a, pse__Region__c region, pse__Practice__c practice, pse__Grp__c projGroup, Opportunity opp, Contact pm, User user, boolean isInsert){
        initDefaultRPG();

        pse__Proj__c testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        testProject.pse__Account__c = a.id;
        testProject.PSA_Customer_Account__c = a.id;
        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Start_Date__c = Date.today();
        testProject.pse__End_Date__c = Date.today() + 90;
        testProject.PSA_Director_Review_Complete__c = true;
        testProject.PSA_PM_Review_Complete__c = true;
        testProject.PSA_Ops_Review_Complete__c = true;
        testProject.pse__Stage__c = 'In Progress';
        testProject.pse__Project_Manager__c = pm.id;
        testProject.PSA_Director__c = pm.id;
        testProject.PSA_PIA__c = pm.id;
        testProject.PSA_CIM__c = pm.id;
        testProject.psa_VP__c = pm.id;
        testProject.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        testProject.PSA_PO_Number__c = '12345';
        testProject.pse__Is_Active__c = true;
        testProject.pse__Is_Billable__c = true;
        testProject.pse__Allow_Timecards_Without_Assignment__c = true;
        testProject.pse__Allow_Expenses_Without_Assignment__c = true;
        testProject.pse__Project_Type__c = 'Customer Project';
        testProject.PSA_Forecast_Category__c = 'Committed';
        testProject.PSA_Expense_Approval_Method__c = 'Project Manager';
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Daily_Cap__c = 8;
        testProject.PSA_CDO_Email__c = 'cdo@guidewire.com';
        testProject.PSA_Services_Product__c = 'Implementation';
        testProject.PSA_Product_Line__c = 'BillingCenter';
        testProject.PSA_VSOE_Type__c = 'Not Stand Alone Sale';
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        testProject.pse__Billing_Type__c = 'Time and Materials';
        testProject.pse__Include_In_Forecasting__c = True;
        testProject.PSA_Include_in_Billing_Forecast__c  = True;
        testProject.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral Duration';
        testProject.PSA_Revenue_Recognition_Model__c = 'As Delivered';
        testProject.PSA_Rate_Classification__c = 'Level Rate';
        testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.PSA_Applicable_SOW_Fully_Executed__c = true;
        testProject.pse__Closed_for_Time_Entry__c = false;
        testProject.PSA_Pre_SOW_Status__c = 'Pre-SOW Start Approved';

        PSA_Department__c dept = createTestDepartment('Test Department', '1425', true);
        testProject.PSA_Department__c = dept.id;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;
        Account_Contact__c shipTo = new Account_Contact__c();
        Account_Contact__c billTo = new Account_Contact__c();

        shipTo.Account__c = testProject.PSA_Customer_Account__c;
        billTo.Account__c = testProject.pse__Account__c;
        shipTo.Contact__c = pm.id;
        shipTo.Participant_Account__c = testProject.PSA_Customer_Account__c;
        billTo.Contact__c = pm.id;
        billTo.Participant_Account__c = testProject.pse__Account__c;
        shipto.Type__c = 'Ship To';
        billTo.Type__c = 'Bill To';
        List<Account_Contact__c> acs = new List<Account_Contact__c>();
        acs.add(billTo);
        acs.add(shipTo);

        insert acs;

        testProject.PSA_Bill_To_Contact__c = billTo.id;
        testProject.PSA_Ship_To_Contact__c = shipTo.id;
        testProject.PSA_Billing_Detail_Template__c = 'Daily';
        testProject.PSA_Revenue_Deferral_Duration__c = 2;


        testProject.CurrencyIsoCode = 'USD';
        if(opp != null)
        {
            testProject.pse__Opportunity__c = opp.Id;
        }

        if(isInsert){
            insert testProject;
        }
        return testProject;
    }

    public static pse__Proj__c createTestProjectInProgress(String projectName, Account a, pse__Region__c region, pse__Practice__c practice, pse__Grp__c projGroup, Opportunity opp, Contact pm, User user){
        initDefaultRPG();

        pse__Proj__c testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        testProject.pse__Account__c = a.id;
        testProject.PSA_Customer_Account__c = a.id;
        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Start_Date__c = Date.today();
        testProject.pse__End_Date__c = Date.today() + 90;
        testProject.PSA_Director_Review_Complete__c = true;
        testProject.PSA_PM_Review_Complete__c = true;
        testProject.PSA_Ops_Review_Complete__c = true;
        testProject.pse__Stage__c = 'In Progress';
        testProject.pse__Project_Manager__c = pm.id;
        testProject.PSA_Director__c = pm.id;
        testProject.PSA_PIA__c = pm.id;
        testProject.PSA_CIM__c = pm.id;
        testProject.psa_VP__c = pm.id;
        testProject.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        testProject.PSA_PO_Number__c = '12345';
        testProject.pse__Is_Active__c = true;
        testProject.pse__Is_Billable__c = true;
        testProject.pse__Allow_Timecards_Without_Assignment__c = true;
        testProject.pse__Allow_Expenses_Without_Assignment__c = true;
        testProject.pse__Project_Type__c = 'Customer Project';
        testProject.PSA_Forecast_Category__c = 'Committed';
        testProject.PSA_Expense_Approval_Method__c = 'Project Manager';
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Daily_Cap__c = 8;
        testProject.PSA_CDO_Email__c = 'cdo@guidewire.com';
        testProject.PSA_Services_Product__c = 'Implementation';
        testProject.PSA_Product_Line__c = 'BillingCenter';
        testProject.PSA_VSOE_Type__c = 'Not Stand Alone Sale';
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        testProject.pse__Billing_Type__c = 'Time and Materials';
        testProject.pse__Include_In_Forecasting__c = True;
        testProject.PSA_Include_in_Billing_Forecast__c  = True;
        testProject.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral Duration';
        testProject.PSA_Revenue_Recognition_Model__c = 'As Delivered';
        testProject.PSA_Rate_Classification__c = 'Level Rate';
        testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.PSA_Applicable_SOW_Fully_Executed__c = true;
        testProject.pse__Closed_for_Time_Entry__c = false;
        testProject.PSA_Pre_SOW_Status__c = 'Pre-SOW Start Approved';

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;

        PSA_Department__c dept = createTestDepartment('Test Department', '1425', true);
        testProject.PSA_Department__c = dept.id;

        Account_Contact__c shipTo = new Account_Contact__c();
        Account_Contact__c billTo = new Account_Contact__c();

        shipTo.Account__c = testProject.PSA_Customer_Account__c;
        billTo.Account__c = testProject.pse__Account__c;
        shipTo.Contact__c = pm.id;
        shipTo.Participant_Account__c = testProject.PSA_Customer_Account__c;
        billTo.Contact__c = pm.id;
        billTo.Participant_Account__c = testProject.pse__Account__c;
        shipto.Type__c = 'Ship To';
        billTo.Type__c = 'Bill To';
        List<Account_Contact__c> acs = new List<Account_Contact__c>();
        acs.add(billTo);
        acs.add(shipTo);

        insert acs;

        testProject.PSA_Bill_To_Contact__c = billTo.id;
        testProject.PSA_Ship_To_Contact__c = shipTo.id;
        testProject.PSA_Billing_Detail_Template__c = 'Daily';
        testProject.PSA_Revenue_Deferral_Duration__c = 2;


        testProject.CurrencyIsoCode = 'USD';
        if(opp != null)
        {
            testProject.pse__Opportunity__c = opp.Id;
        }

        insert testProject;
        return testProject;
    }

    public static pse__Proj__c createTestProjectInProgressWithExpenseEntry(String projectName, Account a, pse__Region__c region, pse__Practice__c practice, 
            pse__Grp__c projGroup, Opportunity opp, Contact pm, User user) {
        initDefaultRPG();

        pse__Proj__c testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        testProject.pse__Account__c = a.id;
        testProject.PSA_Customer_Account__c = a.id;
        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Start_Date__c = Date.today();
        testProject.pse__End_Date__c = Date.today() + 90;
        testProject.PSA_Director_Review_Complete__c = true;
        testProject.PSA_PM_Review_Complete__c = true;
        testProject.PSA_Ops_Review_Complete__c = true;
        testProject.pse__Stage__c = 'Operations Review';
        testProject.pse__Project_Manager__c = pm.id;
        testProject.PSA_Director__c = pm.id;
        testProject.PSA_PIA__c = pm.id;
        testProject.PSA_CIM__c = pm.id;
        testProject.psa_VP__c = pm.id;
        testProject.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        testProject.PSA_PO_Number__c = '12345';
        testProject.pse__Is_Active__c = true;
        testProject.pse__Is_Billable__c = true;
        testProject.pse__Allow_Timecards_Without_Assignment__c = true;
        testProject.pse__Allow_Expenses_Without_Assignment__c = true;
        testProject.pse__Project_Type__c = 'Customer Project';
        testProject.PSA_Forecast_Category__c = 'Committed';
        testProject.PSA_Expense_Approval_Method__c = 'Project Manager';
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Daily_Cap__c = 8;
        testProject.PSA_CDO_Email__c = 'cdo@guidewire.com';
        testProject.PSA_Services_Product__c = 'Implementation';
        testProject.PSA_Product_Line__c = 'BillingCenter';
        testProject.PSA_VSOE_Type__c = 'Not Stand Alone Sale';
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        testProject.pse__Billing_Type__c = 'Time and Materials';
        testProject.pse__Include_In_Forecasting__c = True;
        testProject.PSA_Include_in_Billing_Forecast__c  = True;
        testProject.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral Duration';
        testProject.PSA_Revenue_Recognition_Model__c = 'As Delivered';
        testProject.PSA_Rate_Classification__c = 'Level Rate';
        testProject.psa_Applicable_CSA_Signed__c = true;
        testProject.PSA_Applicable_SOW_Fully_Executed__c = true;
        testProject.pse__Closed_for_Time_Entry__c = false;
        testProject.PSA_Pre_SOW_Status__c = 'Pre-SOW Start Approved';
        testProject.pse__Closed_for_Expense_Entry__c = false;

        PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;

        PSA_Department__c dept = createTestDepartment('Test Department', '1425', true);
        testProject.PSA_Department__c = dept.id;

        Account_Contact__c shipTo = new Account_Contact__c();
        Account_Contact__c billTo = new Account_Contact__c();

        shipTo.Account__c = testProject.PSA_Customer_Account__c;
        billTo.Account__c = testProject.pse__Account__c;
        shipTo.Contact__c = pm.id;
        shipTo.Participant_Account__c = testProject.PSA_Customer_Account__c;
        billTo.Contact__c = pm.id;
        billTo.Participant_Account__c = testProject.pse__Account__c;
        shipto.Type__c = 'Ship To';
        billTo.Type__c = 'Bill To';
        List<Account_Contact__c> acs = new List<Account_Contact__c>();
        acs.add(billTo);
        acs.add(shipTo);

        insert acs;

        testProject.PSA_Bill_To_Contact__c = billTo.id;
        testProject.PSA_Ship_To_Contact__c = shipTo.id;
        testProject.PSA_Billing_Detail_Template__c = 'Daily';
        testProject.PSA_Revenue_Deferral_Duration__c = 2;


        testProject.CurrencyIsoCode = 'USD';
        if(opp != null)
        {
            testProject.pse__Opportunity__c = opp.Id;
        }

        insert testProject;
        return testProject;
    }

    /*************************************************************
    * Creates a Project with parameters provided for:
    * - Name
    * - Region
    * - Practice
    * - Project Stage
    * - Opportunity (optional)
    * Automatically sets the project to Active, Billable,
    * Allow timecards and expenses without assignment
    **************************************************************/
    public static pse__Proj__c createTestProject(String projectName, pse__Region__c region, pse__Practice__c practice, pse__Grp__c projGroup, String projectStage, Opportunity opp)
    {
        initDefaultRPG();
        
         Account a = createTestAccount('Test Account', '12357');
        a.Participant_id__c = '1231';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = createTestUser('tusLD12', 'tuserCLD121@tuser.com', 'userCLD121', 'test212', 'tuserCLD121@tuser.com', 'tuserCLD212');
        Contact c = createTestResource(u, region, practice, projGroup);
    insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
    
        PSA_Department__c testDe = createTestDepartment('TestDHa','1672', true);
        PSA_Entity__c testEn = createTestEntity('Test EH', '1279', 'ET', true);

        pse__Proj__c testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Is_Active__c=true,
                                        pse__Is_Billable__c=true,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Stage__c = projectStage;
         testProject .PSA_CIM__c = c.id;
        testProject .PSA_Director__c =c.id;
        testProject .pse__Project_Manager__c =c.id;
        testProject .PSA_Billing_Legal_Entity__c = testEn.id;
        testProject .PSA_Department__c = testDe.id;
        testProject.pse__Exclude_From_Billing__c = true;
        testProject.pse__Project_Type__c = 'Internal';
        testProject.pse__Closed_for_Time_Entry__c = true;
        testProject.pse__Closed_for_Expense_Entry__c = true;

        if(opp != null)
        {
            testProject.pse__Opportunity__c = opp.Id;
        }
        insert testProject;
        return testProject;

    }

    /**************************************************************************************************
    * Creates a test opportunity
    *
    *
    *
    ***************************************************************************************************/
/*
    public static Opportunity createTestOpportunity(String opptyName, String stage)
    {
        //initDefaultRPG();

        //Account testAccount =  new Account(Name = 'Test Account',Account_Approval__c='Approved');
        Account testAccount =  createTestAccount('Test Account', 'Acct Nbr');
        //system.debug('testAccount >>>>>>' + testAccount.Account_Approval__c );

        Opportunity testOpportunity = new Opportunity(Name=opptyName, StageName=stage, Amount=25000);

        testOpportunity.accountid = testAccount.id;

        //testOpportunity.CloseDate = date.newInstance(2014, 7, 11);
        //testOpportunity.Product_Line_Type__c = 'None';

        //system.debug('testOpportunity.account >>>>>>' + testOpportunity.account.Account_Approval__c );

        List<RecordType> custRec = [Select Id from RecordType where SObjectType = 'Account' AND Name = 'Customer' limit 1];
        testAccount.recordType = custRec.get(0);

        insert testOpportunity;
        return testOpportunity;
    }
*/
    //public static Opportunity createTestOpportunity(String opptyName, String stage, String)
    //{
    //    initDefaultRPG();
    //    Opportunity testOpportunity = new Opportunity(Name=opptyName, StageName=stage, Amount=25000);
    //    testOpportunity.CloseDate = date.newInstance(2012, 7, 11);
    //    insert testOpportunity;
    //    return testOpportunity;
    //}

    /**************************************************************************************************
    * Creates a test account
    ***************************************************************************************************/
    public static Account createTestAccount(String accountName, String accountNumber)
    {

        List<RecordType> custRec = [Select Id,Name from RecordType where SObjectType = 'Account' AND Name = 'Customer' limit 1];
        System.debug('Assigning record type: '+custRec.get(0));
        Account testAccount = new Account(
            Name=accountName,
            AccountNumber=accountNumber,
            CurrencyIsoCode='USD',
            BillingCountry='United States',
            BillingState='VA',
            BillingStreet='1 Main',
            BillingCity='Springfield',
            Type='Customer',
            BillingPostalCode='22102',
            RecordTypeId=custRec.get(0).id);
        insert testAccount;

        //Account debugTest = [Select Id, recordType.id, recordType.name from Account where Name =:accountName limit 1];

        return testAccount;
    }

    /**************************************************************************************************
    * Creates a test account with a Participant Id value
    ***************************************************************************************************/
    public static Account createTestAccountWithParticipantId(String accountName, String accountNumber, 
            String participantIdString) {

        List<RecordType> custRec = [Select Id,Name from RecordType where SObjectType = 'Account' 
                AND Name = 'Customer' limit 1];
        //System.debug('Assigning record type: '+custRec.get(0));
        Account testAccount = new Account(
            Name=accountName,
            AccountNumber=accountNumber,
            CurrencyIsoCode='USD',
            BillingCountry='US',
            BillingState='VA',
            BillingStreet='1 Main',
            BillingCity='Springfield',
            Type='Customer',
            BillingPostalCode='22102',
            RecordTypeId=custRec.get(0).id, 
            Participant_id__c=participantIdString
        );
        insert testAccount;
        return testAccount;
    }

    /**************************************************************************************************
    * Creates a test Milestone
    *
    *
    *
    ***************************************************************************************************/
    public static pse__Milestone__c createTestMilestone(String milestoneName, pse__Proj__c project, boolean cfte, boolean cfee, Double plannedHours)
    {
        pse__Milestone__c testMilestone = new pse__Milestone__c(Name=milestoneName);
        testMilestone.pse__Project__c = project.Id;
        testMilestone.pse__Closed_for_Expense_Entry__c = cfee;
        testMilestone.pse__Closed_for_Time_Entry__c = cfte;
        testMilestone.pse__Target_Date__c = date.newInstance(2012,12,31);
        testMilestone.pse__Status__c = MILESTONE_STATUS_PLANNED;
        testMilestone.pse__Planned_Hours__c = plannedHours;

        testMilestone.PSA_Milestone_Type__c = 'Billable Services - Fixed';

        insert testMilestone;
        return testMilestone;
    }

    /**************************************************************************************************
    * Creates a test Resource
    *
    *
    *
    ***************************************************************************************************/
    public static Contact initTestResource(User salesforceUser, pse__Region__c region, pse__Practice__c practice, pse__Grp__c resourceGroup)
    {
        initDefaultWorkCalendar();

        Contact testResource = new Contact(
            LastName=DEFAULT_RESOURCE_NAME,
            pse__Resource_Role__c=RESOURCE_ROLE_CONSULTANT,
            pse__Is_Resource__c=true,
            pse__Is_Resource_Active__c=true,
            MailingStreet='222 Oak St',
            MailingCity='Arlington',
            MailingState='VA',
            MailingCountry='US',
             MailingPostalCode='22102');

        testResource.pse__Region__c = region.Id;
        testResource.pse__Practice__c = practice.Id;
        testResource.pse__Group__c = resourceGroup.Id;
        testResource.pse__Work_Calendar__c=defaultWorkCalendar.Id;
        testResource.pse__Action_Update_Current_Time_Period__c=false;
        testResource.pse__Current_Time_Period__c = null;
        testResource.FirstName = 'Jerry';
        testResource.LastName = 'Garcia';

        if(salesforceUser!=null)
        {
            testResource.pse__Salesforce_User__c=salesforceUser.Id;
        }

        return testResource;
    }

    /*
        Creates a test resource
    */
    public static Contact createTestResource(User salesforceUser, pse__Region__c region, pse__Practice__c practice, pse__Grp__c resourceGroup, boolean isInsert)
    {
        initDefaultWorkCalendar();

        Contact testResource = new Contact(
            LastName=DEFAULT_RESOURCE_NAME,
            pse__Resource_Role__c=RESOURCE_ROLE_CONSULTANT,
            pse__Is_Resource__c=true,
            pse__Is_Resource_Active__c=true,
            MailingStreet='222 Oak St',
            MailingCity='Arlington',
            MailingState='VA',
            MailingCountry='US',
             MailingPostalCode='22102',
             PSA_PS_Level__c = '120');

        testResource.pse__Region__c = region.Id;
        testResource.pse__Practice__c = practice.Id;
        testResource.pse__Group__c = resourceGroup.Id;
        testResource.pse__Work_Calendar__c=defaultWorkCalendar.Id;
        testResource.pse__Action_Update_Current_Time_Period__c=false;
        testResource.pse__Current_Time_Period__c = null;
        testResource.FirstName = 'Jerry';
        testResource.LastName = 'Garcia';
        testResource.Email = salesforceUser.email;

        if(salesforceUser!=null)
        {
            testResource.pse__Salesforce_User__c=salesforceUser.Id;
        }

        if(isInsert){
            insert testResource;
        }
        return testResource;
    }

    /*
        Creates a test resource
    */
    public static Contact createTestResource(User salesforceUser, pse__Region__c region, pse__Practice__c practice, pse__Grp__c resourceGroup)
    {
        initDefaultWorkCalendar();

        Contact testResource = new Contact(
            LastName=DEFAULT_RESOURCE_NAME,
            pse__Resource_Role__c=RESOURCE_ROLE_CONSULTANT,
            pse__Is_Resource__c=true,
            pse__Is_Resource_Active__c=true,
            MailingStreet='222 Oak St',
            MailingCity='Arlington',
            MailingState='VA',
            MailingCountry='US',
             MailingPostalCode='22102',
             PSA_PS_Level__c = '120');

        testResource.pse__Region__c = region.Id;
        testResource.pse__Practice__c = practice.Id;
        testResource.pse__Group__c = resourceGroup.Id;
        testResource.pse__Work_Calendar__c=defaultWorkCalendar.Id;
        testResource.pse__Action_Update_Current_Time_Period__c=false;
        testResource.pse__Current_Time_Period__c = null;
        testResource.FirstName = 'Jerry';
        testResource.LastName = 'Garcia';
        testResource.Email = salesforceUser.email;

        if(salesforceUser!=null)
        {
            testResource.pse__Salesforce_User__c=salesforceUser.Id;
        }

        insert testResource;
        
        return testResource;
    }

    public static Contact createTestResource(User salesforceUser, pse__Region__c region, pse__Practice__c practice, pse__Grp__c resourceGroup, Account acct)
    {
        initDefaultWorkCalendar();

        Contact testResource = new Contact(
            LastName=DEFAULT_RESOURCE_NAME,
            pse__Resource_Role__c=RESOURCE_ROLE_CONSULTANT,
            pse__Is_Resource__c=true,
            pse__Is_Resource_Active__c=true,
            MailingStreet='222 Oak St',
            MailingCity='Arlington',
            MailingState='VA',
            MailingCountry='US',
            MailingPostalCode='22102', 
            AccountId=acct.Id,
            PSA_PS_Level__c = '120');

        testResource.pse__Region__c = region.Id;
        testResource.pse__Practice__c = practice.Id;
        testResource.pse__Group__c = resourceGroup.Id;
        testResource.pse__Work_Calendar__c=defaultWorkCalendar.Id;
        testResource.pse__Action_Update_Current_Time_Period__c=false;
        testResource.pse__Current_Time_Period__c = null;
        testResource.FirstName = salesforceUser.FirstName;
        testResource.LastName = 'salesforceUser.LastName';
        testResource.pse__Salesforce_User__c=salesforceUser.Id;

        insert testResource;
        return testResource;
    }

    /**************************************************************************************************
    * Creates a test Entity
    *
    ***************************************************************************************************/
    public static psa_Entity__c createTestEntity(String name, String code, String shortName, boolean billingEntity){
        PSA_Entity__c entity = new PSA_Entity__c();
        entity.name = name;
        entity.PSA_Entity_Code__c = code;
        entity.PSA_Short_Name__c = shortName;
        entity.PSA_Billing_Entity__c = billingEntity;
        insert entity;
        return entity;
    }

    /**************************************************************************************************
    * Creates a test Department
    *
    ***************************************************************************************************/
    public static PSA_Department__c createTestDepartment(String name, String code, boolean isPSDept){
        PSA_Department__c dept = new PSA_Department__c();
        dept.Name = name;
        dept.PSA_Department_Code__c = code;
        dept.PSA_PS_Department__c = isPSDept;
        insert dept;
        return dept;
    }

    /**************************************************************************************************
    * Creates a test Assignment
    *
    ***************************************************************************************************/
    public static pse__Assignment__c createTestSimpleAssignment(pse__Proj__c proj, Contact resource, String resourceRole)
    {
        // Create an initial assignment schedule, 30 days out
        pse__Schedule__c schedule = new pse__Schedule__c();
        schedule.pse__Start_Date__c = System.Today();
        schedule.pse__End_Date__c = System.Today() + 34;
        schedule.pse__Monday_Hours__c = 8;
        schedule.pse__Tuesday_Hours__c = 8;
        schedule.pse__Wednesday_Hours__c = 8;
        schedule.pse__Thursday_Hours__c = 8;
        schedule.pse__Friday_Hours__c = 8;
        insert schedule;

        // Get top most Region for the Permission Control
        id regionId = [select id from pse__Region__c where pse__Hierarchy_Depth__c = 0 limit 1].id;
        system.Assert(regionId != null, 'No Regions configured.   Please contact your PSA Admin');

        // Create a permission control that will allow us to staff the resource
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c=resource.Id, pse__Staffing__c=true);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= regionId, pse__Staffing__c=true);

        // Create the assignment and associate it with the project
        pse__Assignment__c assignment = new pse__Assignment__c(Name='Test Assignment');
        assignment.pse__Is_Billable__c = true;
        assignment.pse__Project__c = proj.Id;
        assignment.pse__Resource__c = resource.Id;
        assignment.pse__Schedule__c = schedule.Id;
        assignment.pse__Bill_Rate__c = 85;
        assignment.pse__Role__c = resourceRole;
        assignment.PSA_Rate_Needs_Review__c = false;
        assignment.pse__Closed_for_Time_Entry__c = false;

        upsert assignment;

        return assignment;
    }

    /**************************************************************************************************
    * Creates a test Assignment
    *
    ***************************************************************************************************/
    public static pse__Assignment__c createTestAssignment(pse__Proj__c proj, Contact resource, String resourceRole)
    {
        // Create an initial assignment schedule, 30 days out
        pse__Schedule__c schedule = new pse__Schedule__c();
        schedule.pse__Start_Date__c = System.Today()-30;
        schedule.pse__End_Date__c = System.Today() + 34;
        schedule.pse__Monday_Hours__c = 8;
        schedule.pse__Tuesday_Hours__c = 8;
        schedule.pse__Wednesday_Hours__c = 8;
        schedule.pse__Thursday_Hours__c = 8;
        schedule.pse__Friday_Hours__c = 8;
        insert schedule;

        // Get top most Region for the Permission Control
        id regionId = [select id from pse__Region__c where pse__Hierarchy_Depth__c = 0 limit 1].id;
        system.Assert(regionId != null, 'No Regions configured.   Please contact your PSA Admin');

        // Create a permission control that will allow us to staff the resource
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c=resource.Id, pse__Staffing__c=true);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= regionId, pse__Staffing__c=true);

        // Create the assignment and associate it with the project
        pse__Assignment__c assignment = new pse__Assignment__c(Name='Test Assignment');
        assignment.pse__Is_Billable__c = true;
        assignment.pse__Project__c = proj.Id;
        assignment.pse__Resource__c = resource.Id;
        assignment.pse__Schedule__c = schedule.Id;
        assignment.pse__Bill_Rate__c = 85;
        assignment.pse__Role__c = resourceRole;
        assignment.PSA_Override_Bill_Rate__c = true;
        assignment.PSA_Rate_Needs_Review__c = false;
        assignment.pse__Closed_for_Time_Entry__c = false;
        assignment.PSA_Billing_Level__c = '120';
        upsert assignment;

        return assignment;
    }

    /**************************************************************************************************
    * Creates a test Assignment including start/end dates for the schedule
    *
    ***************************************************************************************************/
    public static pse__Assignment__c createTestAssignment(pse__Proj__c proj, Contact resource, 
            String resourceRole, Date startDate, Date endDate)
    {
        // Create an initial assignment schedule, 30 days out
        pse__Schedule__c schedule = new pse__Schedule__c();
        schedule.pse__Start_Date__c = startDate;
        schedule.pse__End_Date__c = endDate;
        schedule.pse__Monday_Hours__c = 8;
        schedule.pse__Tuesday_Hours__c = 8;
        schedule.pse__Wednesday_Hours__c = 8;
        schedule.pse__Thursday_Hours__c = 8;
        schedule.pse__Friday_Hours__c = 8;
        insert schedule;

        // Get top most Region for the Permission Control
        id regionId = [select id from pse__Region__c where pse__Hierarchy_Depth__c = 0 limit 1].id;
        system.Assert(regionId != null, 'No Regions configured.   Please contact your PSA Admin');

        // Create a permission control that will allow us to staff the resource
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c=resource.Id, pse__Staffing__c=true);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Region__c= regionId, pse__Staffing__c=true);

        // Create the assignment and associate it with the project
        pse__Assignment__c assignment = new pse__Assignment__c(Name='Test Assignment');
        assignment.pse__Is_Billable__c = true;
        assignment.pse__Project__c = proj.Id;
        assignment.pse__Resource__c = resource.Id;
        assignment.pse__Schedule__c = schedule.Id;
        assignment.pse__Bill_Rate__c = 85;
        assignment.pse__Role__c = resourceRole;
        assignment.PSA_Override_Bill_Rate__c = true;
        assignment.PSA_Rate_Needs_Review__c = false;
        assignment.pse__Closed_for_Time_Entry__c = false;
        assignment.PSA_Billing_Level__c = '120';
        upsert assignment;

        return assignment;
    }

    public static PSA_Account_Discount__c createTestAccountDiscount(Id accountId, Decimal capAmount, Date endDate, Decimal discountPct, boolean toInsert){
        PSA_Account_Discount__c acctDiscount = new PSA_Account_Discount__c();
        acctDiscount.PSA_Discount_Active__c = true;
        acctDiscount.PSA_Account__c = accountId;
        acctDiscount.PSA_Discount_Billing_Levels__c = '100; 105; 110; 120; 130; 140';
        acctDiscount.PSA_Discount_Cap__c = capAmount;
        acctDiscount.PSA_Discount_End_Date__c = endDate;
        acctDiscount.PSA_Discount_Percent__c = discountPct;
        acctDiscount.PSA_Discount_Type__c = 'Investment Credit with Carve-out';

        if(toInsert){
            insert acctDiscount;
        }
        return acctDiscount;
    }

    public static pse__Resource_Request__c createTestResourceRequest(String name, Id regionId, Date start, Date endDate, Id project, String role, String billingLevel, Decimal requestedHours, boolean toInsert){
        pse__Resource_Request__c rr = new pse__Resource_Request__c();
        rr.pse__Resource_Role__c = role;
        rr.pse__SOW_Hours__c = requestedHours;
        rr.pse__Start_Date__c = start;
        rr.pse__End_Date__c = endDate;
        rr.PSA_Billing_Level__c = billingLevel;
        rr.pse__Project__c = project;
        rr.pse__Region__c = regionId;
        rr.pse__Status__c = 'Draft';

        if(toInsert){
            insert rr;
        }
        return rr;
    }

    // Initializes a timecard header
    public static pse__Timecard_Header__c initTestTimecardHeader (Id projId,  Id resourceId, Id assignmentId, Date inputDate, Decimal hours, pse__Project_Phase__c phase) {
        pse__Timecard_Header__c psaTimecard = new pse__Timecard_Header__c();
        psaTimecard.pse__Resource__c   = resourceId;
        psaTimecard.pse__Project__c    = projId;
        psaTimecard.pse__Assignment__c = assignmentId;
        psaTimecard.pse__Status__c = 'Saved';

        // build our 7-day date range between the start of the week and the end of the week
        psaTimecard.pse__Start_Date__c = inputDate.toStartOfWeek();
        psaTimecard.pse__End_Date__c   = psaTimecard.pse__Start_Date__c.addDays(6);
        if(phase != null){
            psaTimecard.pse__Project_Phase_Object__c = phase.id;
        }

        // determine which day of the week we should add the hours too
        String dayOfWeek = DateTime.newinstance(inputDate.year(), inputDate.month(), inputDate.day()).format('EEEE');


        if (dayOfWeek == 'Monday') {
            psaTimecard.pse__Monday_Hours__c = hours;
        }else if (dayOfWeek == 'Tuesday') {
            psaTimecard.pse__Tuesday_Hours__c = hours;
        }else if (dayOfWeek == 'Wednesday') {
            psaTimecard.pse__Wednesday_Hours__c = hours;
        }else if (dayOfWeek == 'Thursday') {
            psaTimecard.pse__Thursday_Hours__c = hours;
        }else if (dayOfWeek == 'Friday') {
            psaTimecard.pse__Friday_Hours__c = hours;
        }else if (dayOfWeek == 'Saturday') {
            psaTimecard.pse__Saturday_Hours__c = hours;
        } else if (dayOfWeek == 'Sunday') {
            psaTimecard.pse__Sunday_Hours__c = hours;
        }
        return psaTimecard;
    }

    // Creates a timecard header
    public static pse__Timecard_Header__c createTestTimecardHeader (Id projId,  Id resourceId, Id assignmentId, Date inputDate, Decimal hours, pse__Project_Phase__c phase) {
        pse__Timecard_Header__c psaTimecard = initTestTimecardHeader(projId, resourceId, assignmentId, inputDate, hours, phase);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = resourceId, pse__Timecard_Entry__c =true);

        insert psaTimecard;
        return psaTimecard;
    }

    public static pse__Timecard_Header__c createTestMsTimecardHeader(Id projId,  ID milestoneId, Id resourceId, Id assignmentId, Date inputDate, Decimal hours, pse__Project_Phase__c phase, boolean toInsert) {
        pse__Timecard_Header__c psaTimecard = initTestTimecardHeader(projId, resourceId, assignmentId, inputDate, hours, phase);
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = resourceId, pse__Timecard_Entry__c =true);
        psaTimecard.pse__Milestone__c = milestoneId;
        if(toInsert){
            insert psaTimecard;
        }
        
        return psaTimecard;
    }

    public static pse__Miscellaneous_Adjustment__c createMiscellaneousAdjustment(Id projId, String recordTypeName, Decimal amount) {
        pse__Miscellaneous_Adjustment__c miscAdjustment = new pse__Miscellaneous_Adjustment__c();
        miscAdjustment.pse__Project__c = projId;
        //miscAdjustment.RecordTypeId = ([Select Id 
        //                                From RecordType 
        //                                Where SobjectType = 'pse__Miscellaneous_Adjustment__c' 
        //                                and DeveloperName = :recordTypeName]).Id;
        miscAdjustment.pse__Amount__c = amount;
        miscAdjustment.pse__Transaction_Category__c = 'External Cost';

        insert miscAdjustment;
        return miscAdjustment;
    }

    public static pse__Budget__c createTestBudget(Id projectId, Decimal amount) {
        pse__Budget__c psaBudget = new pse__Budget__c(pse__Project__c=projectId);
        psaBudget.pse__Amount__c = amount;

        insert psaBudget;
        return psaBudget;
    }

    public static pse__Expense_Report__c createTestExpenseReport(String name, Id projectId, Id resourceId, boolean toInsert){
        pse__Expense_Report__c report = new pse__Expense_Report__c();
        report.Name = name;
        report.pse__Project__c = projectId;
        report.pse__Resource__c = resourceId;
        report.pse__Billable__c = true;

        if(toInsert){
            insert report;
        }
      
        return report;
    }

    public static pse__Expense__c createTestExpense(Id projectId, Id resourceId, Decimal amount, String type, boolean toInsert)
    {
        pse__Expense__c expense = new pse__Expense__c(pse__Project__c = projectId, pse__Resource__c = resourceId);
        //expense.GP_GLA_Code_Employee_Expense_AP__c = '66600';
        expense.pse__Billable__c = true;
        expense.pse__Description__c = 'Test Description';
        expense.pse__Amount__c = amount;
        expense.pse__Type__c = type;
        
        if(toInsert){
            insert expense;
        }
        return expense;
    }

    public static psa_Expense_Policy__c createTestPolicy(String name, Id projectId, Id accountId, String expenseType, String policyType, Decimal amount, boolean toInsert){
        PSA_Expense_Policy__c policy = new PSA_Expense_Policy__c();
        policy.name = 'Test Policy';
        if(projectId != null){
            policy.PSA_Project__c = projectId;
        }
        if(accountId != null){
            policy.PSA_Account__c = accountId;
        }

        policy.PSA_Expense_Type__c = expenseType;
        policy.PSA_Policy_Type__c = policyType;
        if(policyType == 'Single Billing Limit'){
            policy.PSA_Billable_Limit__c = amount;
        }
        else if(policyType == 'Receipt Required'){
            policy.PSA_Receipt_Required_Threshold__c = amount;
        }
        else if(policyType == 'Note Required'){

        }
        else if(policyType == 'Amount Review Threshold'){
            policy.PSA_Amount_Review_Threshold__c = amount;
        }

        if(toInsert){
            insert policy;
        }
        return policy;
    }

    public static pse__Expense__c createTestExpenseOnReport(Id expenseReport, Id projectId, Id resourceId, Decimal amount, String type,
        Date exDate, boolean toInsert) {
        pse__Expense__c expense = new pse__Expense__c(pse__Expense_Report__c = expenseReport, pse__Project__c = projectId, pse__Resource__c = resourceId);
        //expense.GP_GLA_Code_Employee_Expense_AP__c = '66600';
        expense.pse__Description__c = 'Test Description';
        expense.pse__Amount__c = amount;
        expense.pse__type__c = type;
        expense.pse__Expense_Date__c = exDate;

        if(toInsert){
            insert expense;
        }
        
        return expense;
    }

    public static pse__Expense__c createTestExpenseOnReportWithAssignment(Id expenseReport, Id projectId, Id resourceId, Decimal amount, String type,
        Date exDate, Id assignmentId, boolean toInsert)
    {
        pse__Expense__c expense = new pse__Expense__c(pse__Expense_Report__c = expenseReport, pse__Project__c = projectId, pse__Resource__c = resourceId);
        //expense.GP_GLA_Code_Employee_Expense_AP__c = '66600';
        expense.pse__Description__c = 'Test Description';
        expense.pse__Amount__c = amount;
        expense.pse__type__c = type;
        expense.pse__Expense_Date__c = exDate;
        expense.pse__Assignment__c = assignmentId;

        if(toInsert){
            insert expense;
        }
        
        return expense;
    }

    /*************************************************************
    * Initializes an instance-level work calendar that can be reused
    *
    **************************************************************/
    public static void initDefaultWorkCalendar()
    {
        if(defaultWorkCalendar==null)
        {
            System.debug('Inserting work calendar');
            defaultWorkCalendar = new pse__Work_Calendar__c(Name='Test Work Calendar');
            insert defaultWorkCalendar;
        }
    }

    public static void initZeroWorkCalendar()
    {
        if(defaultWorkCalendar==null)
        {
            System.debug('Inserting work calendar');
            defaultWorkCalendar = new pse__Work_Calendar__c(Name='Test Work Calendar');
            defaultWorkCalendar.pse__Standard_Hours_Per_Day__c = 0;
            insert defaultWorkCalendar;
        }
    }

    public static pse__Work_Calendar__c createWorkCalendar(String calName){
        if(defaultWorkCalendar==null)
        {
            System.debug('Inserting work calendar');
            defaultWorkCalendar = new pse__Work_Calendar__c(Name=calName, pse__Standard_Hours_Per_Day__c = 0);

            insert defaultWorkCalendar;
        }
        return defaultWorkCalendar;

    }

    /*************************************************************
    * Initializes instance-level Region, Pratice, and Group
    *
    **************************************************************/
    public static void initDefaultRPG()
    {
        if(defaultRegion==null)
        {
            defaultRegion = createTestRegion(DEFAULT_REGION_NAME);
        }

        if(defaultPractice==null)
        {
            defaultPractice = createTestPractice(DEFAULT_PRACTICE_NAME);
        }

        if(defaultGroup==null)
        {
            defaultGroup = createTestGroup(DEFAULT_GROUP_NAME);
        }
    }

    /*************************************************************
    * Initializes an instance-level Resource that can be reused
    *
    **************************************************************/
    public static Contact initDefaultResource()
    {
        initDefaultRPG();
        initDefaultWorkCalendar();

        User defaultResourceUser = psaTestUtils.createTestUser('PMgr', 'pm@abc.com', 'PM', 'PM', 'pm@abc.com', 'PM');

        defaultResource = new Contact(LastName=DEFAULT_RESOURCE_NAME, pse__Resource_Role__c=RESOURCE_ROLE_CONSULTANT,
            pse__Is_Resource__c=true,pse__Is_Resource_Active__c=true, MailingStreet='222 Oak St', MailingCity='Arlington',
            MailingState='VA', MailingCountry='US', MailingPostalCode='22102', pse__Salesforce_User__c=defaultResourceUser.Id);

        defaultResource.pse__Region__c = defaultRegion.Id;
        defaultResource.pse__Practice__c = defaultPractice.Id;
        defaultResource.pse__Group__c = defaultGroup.Id;
        defaultResource.pse__Work_Calendar__c=defaultWorkCalendar.Id;
        defaultResource.pse__Action_Update_Current_Time_Period__c=false;
        defaultResource.pse__Current_Time_Period__c = null;
        defaultResource.firstname = DEFAULT_RESOURCE_NAME;

        insert defaultResource;
        return defaultResource;
    }

    /*************************************************************
    * Creates a User with System Administrator profile
    *
    **************************************************************/
    public static User createTestUser(String userAlias, String userLogin, String userLastName, String userFirstName, String userEmail, String userNickname)
    {
        Profile prof = [select Name from Profile where Name = 'System Administrator'];
        User testUser = new User(alias=userAlias,
                                 username=userLogin,
                                 lastname=userLastName,
                                 firstname=userFirstName,
                                 email=userEmail,
                                 communitynickname=userNickname,
                                 timezonesidkey='America/New_York',
                                 LocaleSidKey='en_US',
                                 ProfileId=prof.Id,
                                 LanguageLocaleKey='en_US',
                                 EmailEncodingKey='UTF-8');
        insert testUser;
        return testUser;
    }

    public static pse__Billing_Event_Item__c createTestBillingEventItem(Id eventId, Date itemDate, Double amount, String category, Id projectId, Id referencedObjectId, boolean toInsert){
        pse__Billing_Event_Item__c item = new pse__Billing_Event_Item__c();
        item.pse__Amount__c = amount;
        item.pse__Billing_Event__c = eventId;
        item.pse__Date__c = itemDate;
        item.pse__Category__c = category;
        item.pse__Project__c = projectId;
        item.pse__Object_Id__c = referencedObjectId;
        
        if(toInsert){
            insert item;
        }
        return item;
    }

    public static pse__Billing_Event__c createTestBillingEvent(Id projectId, String status, Date eventDate, String currencyCode, Double amount, boolean toInsert){
        pse__Billing_Event__c event = new pse__Billing_Event__c();
        event.pse__Project__c = projectId;
        event.pse__Status__c = status;
        event.pse__Date__c = eventDate;
        event.currencyIsoCode = currencyCode;
        event.PSA_Current_Billing_Amount__c = amount;
        event.PSA_CIM_Reviewed__c = true;
        event.PSA_PM_Reviewed__c = true;
        if(toInsert){
            insert event;
        }
        return event;
    }

    public static pse__Time_Period__c createTestTimePeriod(String name, Double seasonalityFactor, Date startDate, Date endDate, String type, boolean toInsert){
        pse__Time_Period__c tp = new pse__Time_Period__c();
        tp.Name = name;
        tp.pse__Start_Date__c = startDate;
        tp.pse__End_Date__c = endDate;
        tp.pse__Type__c = type;
        if(seasonalityFactor != null){
            tp.PSA_Seasonality_Factor__c = seasonalityFactor;
        }
        
        if(toInsert){
            insert tp;
        }
        return tp;
    }

    public static pse__Permission_Control__c grantAllPermissionControls(Id UserId, Id regionId) {
        pse__Permission_Control__c pc = new pse__Permission_Control__c();
        pc.pse__User__c = UserId;
        pc.pse__Region__c = regionId;
        pc.pse__Cascading_Permission__c = true;
        pc.pse__Billing__c = true;
        pc.pse__Expense_Entry__c = true;
        pc.pse__Expense_Ops_Edit__c = true;
        pc.pse__Forecast_Edit__c = true;
        pc.pse__Forecast_View__c = true;
        pc.pse__Invoicing__c = true;
        pc.pse__Edit_Task_Manager__c = true;
        pc.pse__View_Task_Manager__c = true;
        pc.pse__Resource_Request_Entry__c = true;
        pc.pse__Skills_And_Certifications_Entry__c = true;
        pc.pse__Skills_And_Certifications_View__c = true;
        pc.pse__Staffing__c = true;
        pc.pse__Timecard_Entry__c = true;
        pc.pse__Timecard_Ops_Edit__c = true;
        insert pc;
        return pc;
    }

    public static void createTestResourcePractice(Id departmentId, Id entityId, Id practiceId) {
        PSA_Resource_Practice__c rp = new PSA_Resource_Practice__c();
        rp.PSA_Department__c = departmentId;
        rp.PSA_Entity__c = entityId;
        rp.PSA_Practice__c = practiceId;
        insert rp;
    }

    public static void createPSABillingCustomSetting() {
        //Verify the named custom setting doesn't already exist.  If not, then create it
        List<PSA_Billing__c> billingCustomSettingList = 
            [Select Id, Name From PSA_Billing__c Where Name = 'default'];
        if (billingCustomSettingList == null || billingCustomSettingList.size() == 0) {
            PSA_Billing__c psaB = new PSA_Billing__c();
            psaB.Name = 'default';
            psaB.PSA_Billing_Rules_Batch_Done_Email_List__c = 'test@test.com';
            psaB.PSA_Billing_Event_Max_Refresh__c = 100;
            psaB.PSA_Billing_Rules_Batch_Size__c = 1;
            psaB.PSA_Earliest_LTA_Date__c = Date.newInstance(2015, 1, 1);
            insert psaB;
        }
    }

    public static void createPSAForecastCustomSetting() {
        //Verify the named custom setting doesn't already exist.  If not, then create it
        List<PSA_Forecast__c> forecastCustomSettingList = 
            [Select Id, Name From PSA_Forecast__c Where Name = 'default'];
        if (forecastCustomSettingList == null || forecastCustomSettingList.size() == 0) {
            PSA_Forecast__c psaF = new PSA_Forecast__c();
            psaF.Name = 'default';
            psaF.PSA_Forecast_Category_Percent_Committed__c = 100;
            psaF.PSA_Forecast_Category_Percent_Forecast__c = 100;
            psaF.PSA_Forecast_Category_Percent_Pipeline__c = 100;
            psaF.PSA_Forecast_Category_Percent_Sales__c = 0;
            psaF.PSA_Forecast_Category_Percent_Upside__c = 0;
            insert psaF;
        }
    }

    public static void createPSAIntegrationCustomSetting() {
        //Verify the named custom setting doesn't already exist.  If not, then create it
        List<PSA_Integration__c> integrationCustomSettingList = 
            [Select Id, Name From PSA_Integration__c Where Name = 'default'];
        if (integrationCustomSettingList == null || integrationCustomSettingList.size() == 0) {
            PSA_Integration__c psaI = new PSA_Integration__c();
            psaI.Name = 'default';
            psaI.PSA_Default_Email_Encoding__c = 'ISO-8859-1';
            psaI.PSA_Default_Language__c = 'en_US';
            psaI.PSA_Default_Locale__c = 'en_US';
            psaI.PSA_Default_Role__c = 'CEO'; //Professional Services Team
            psaI.PSA_Default_User_License__c = 'Salesforce Platform';
            psaI.PSA_Default_User_Profile__c = 'Standard Platform User';
            psaI.PSA_Guidewire_Account_Id__c = '00130000003s0NE';
            psaI.PSA_Username_Suffix__c = 'test';
            insert psaI;
        } 
    }

    public static void createPSATriggersCustomSetting(Boolean disableAll) {
        List<PSA_Triggers__c> triggersCustomSettingList = 
            [Select Id, Name From PSA_Triggers__c Where Name = 'Default'];
        if (triggersCustomSettingList != null && triggersCustomSettingList.size() > 0) {
            System.debug('Disabling PSA Trigger values');
            triggersCustomSettingList[0].Disable_pse_Proj_c_AI__c = disableAll;
            triggersCustomSettingList[0].Disable_pse_Proj_c_AU__c = disableAll;
            triggersCustomSettingList[0].Disable_pse_Proj_c_BI__c = disableAll;
            triggersCustomSettingList[0].Disable_pse_Proj_c_BU__c = disableAll;
            update triggersCustomSettingList;
        } else {
            PSA_Triggers__c psaTriggerRecord = new PSA_Triggers__c();
            psaTriggerRecord.Name = 'Default';
            psaTriggerRecord.Disable_pse_Proj_c_AI__c = disableAll;
            psaTriggerRecord.Disable_pse_Proj_c_AU__c = disableAll;
            psaTriggerRecord.Disable_pse_Proj_c_BI__c = disableAll;
            psaTriggerRecord.Disable_pse_Proj_c_BU__c = disableAll;
            insert psaTriggerRecord;            
        }
    }

    public static void createPSALoggingCustomSetting(Boolean enableLogging, Integer loggingLevel) {
        List<PSA_Logging__c> psaLoggingCustomSettingList = 
            [Select Id, Name, PSA_Logging_Level__c, PSA_Enable_Apex_Logging__c, 
                    PSA_No_psaBillingEventGeneration__c, PSA_No_psaBillingRulesApplication__c, 
                    PSA_No_psaTimecardDailyCap__c, PSA_No_psaInvoiceSummaryLineRefresh__c, 
                    PSA_No_psaRefreshProjectBillingBalances__c, PSA_Error_Email_List__c, 
                    PSA_No_psaBillingEventRecalc__c, PSA_No_psaBillingEventRegenerate__c, 
                    PSA_No_psaBillingEventRegenerateControl__c
                From PSA_Logging__c 
                Where Name = 'default'
            ];
        if (psaLoggingCustomSettingList != null && psaLoggingCustomSettingList.size() > 0) {
            System.debug('Updating PSA Logging values');
            psaLoggingCustomSettingList[0].PSA_Logging_Level__c = loggingLevel;
            psaLoggingCustomSettingList[0].PSA_Enable_Apex_Logging__c = enableLogging;
            psaLoggingCustomSettingList[0].PSA_Error_Email_List__c = 'test@example.com';
            psaLoggingCustomSettingList[0].PSA_No_psaBillingEventGeneration__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaBillingRulesApplication__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaTimecardDailyCap__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaInvoiceSummaryLineRefresh__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaRefreshProjectBillingBalances__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaBillingEventRecalc__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaBillingEventRegenerate__c = false;
            psaLoggingCustomSettingList[0].PSA_No_psaBillingEventRegenerateControl__c = false;
            
            update psaLoggingCustomSettingList;
        } else {
            PSA_Logging__c psaLoggingRecord = new PSA_Logging__c();
            psaLoggingRecord.Name = 'default';
            psaLoggingRecord.PSA_Logging_Level__c = loggingLevel;
            psaLoggingRecord.PSA_Enable_Apex_Logging__c = enableLogging;
            psaLoggingRecord.PSA_Error_Email_List__c = 'test@example.com';
            psaLoggingRecord.PSA_No_psaBillingEventGeneration__c = false;
            psaLoggingRecord.PSA_No_psaBillingRulesApplication__c = false;
            psaLoggingRecord.PSA_No_psaTimecardDailyCap__c = false;
            psaLoggingRecord.PSA_No_psaInvoiceSummaryLineRefresh__c = false;
            psaLoggingRecord.PSA_No_psaRefreshProjectBillingBalances__c = false;
            psaLoggingRecord.PSA_No_psaBillingEventRecalc__c = false;
            psaLoggingRecord.PSA_No_psaBillingEventRegenerate__c = false;
            psaLoggingRecord.PSA_No_psaBillingEventRegenerateControl__c = false;

            System.debug('PSA Logging Record: ' + psaLoggingRecord);
            insert psaLoggingRecord;            
        }
    }

/*
    public static void disablePsaTriggersV2() {
        PSA_Triggers__c psaTrigger;
        Boolean newRecord = false;
        List<PSA_Triggers__c> psaTriggers = 
            [Select Id, Name, 
                    Disable_pse_Proj_c_AI__c, 
                    Disable_pse_Proj_c_AU__c, 
                    Disable_pse_Proj_c_BI__c, 
                    Disable_pse_Proj_c_BU__c, 
                    Disable_pse_Assignment_c_AI__c, 
                    Disable_pse_Assignment_c_BI__c, 
                    Disable_pse_Assignment_c_BU__c, 
                    Disable_pse_Assignment_c_AU__c, 
                    Disable_Contact_AI__c, 
                    Disable_Contact_AU__c, 
                    Disable_Contact_BI__c, 
                    Disable_Contact_BU__c,
                    Disable_pse_Time_Date_c_AI__c, 
                    Disable_pse_Time_Date_c_AU__c, 
                    Disable_pse_Time_Date_c_BI__c, 
                    Disable_pse_Time_Date_c_BU__c
                from PSA_Triggers__c
                limit 1
            ];
        if (psaTriggers != null && psaTriggers.size() > 0) {
            System.debug('Disabling PSA Trigger values');
            psaTrigger = psaTriggers[0];
        } else {
            System.debug('PSA Trigger Custom Setting record not found');
            psaTrigger = new PSA_Triggers__c();
            psaTrigger.Name = 'default';
            newRecord = true;
        }
        psaTrigger.Disable_pse_Proj_c_AI__c = true;
        psaTrigger.Disable_pse_Proj_c_AU__c = true;
        psaTrigger.Disable_pse_Proj_c_BI__c = true;
        psaTrigger.Disable_pse_Proj_c_BU__c = true;
        psaTrigger.Disable_pse_Assignment_c_BI__c = true;
        psaTrigger.Disable_pse_Assignment_c_AI__c = true;
        psaTrigger.Disable_pse_Assignment_c_BU__c = true;
        psaTrigger.Disable_pse_Assignment_c_AU__c = true;
        psaTrigger.Disable_Contact_AI__c = true;
        psaTrigger.Disable_Contact_AU__c = true;
        psaTrigger.Disable_Contact_BI__c = true;
        psaTrigger.Disable_Contact_BU__c = true;
        psaTrigger.Disable_pse_Time_Date_c_AI__c = true;
        psaTrigger.Disable_pse_Time_Date_c_AU__c = true;
        psaTrigger.Disable_pse_Time_Date_c_BI__c = true;
        psaTrigger.Disable_pse_Time_Date_c_BU__c = true;

        if (!newRecord) {
            update psaTrigger;
        } else {
            insert psaTrigger;
        }
    }    
*/
    public static void disablePsaTriggers() {
        PSA_Triggers__c psaTrigger;
        Boolean newRecord = false;
        List<PSA_Triggers__c> psaTriggers = 
            [Select Id, Name, 
                    Disable_pse_Proj_c_AI__c, 
                    Disable_pse_Proj_c_AU__c, 
                    Disable_pse_Proj_c_BI__c, 
                    Disable_pse_Proj_c_BU__c 
                from PSA_Triggers__c
                limit 1
            ];
        if (psaTriggers != null && psaTriggers.size() > 0) {
            System.debug('Disabling PSA Trigger values');
            psaTrigger = psaTriggers[0];
        } else {
            System.debug('PSA Trigger Custom Setting record not found');
            psaTrigger = new PSA_Triggers__c();
            psaTrigger.Name = 'default';
            newRecord = true;
        }
        psaTrigger.Disable_pse_Proj_c_AI__c = true;
        psaTrigger.Disable_pse_Proj_c_AU__c = true;
        psaTrigger.Disable_pse_Proj_c_BI__c = true;
        psaTrigger.Disable_pse_Proj_c_BU__c = true;

        if (!newRecord) {
            update psaTrigger;
        } else {
            insert psaTrigger;
        }
    }    

    public static void disableASMTriggers(String enabled) {
        //disable timecard ASM triggers
        System.debug('Disabling');
        appirio_core__Config_Value__c[] tcsCoreValues = [
            select Id,
                   appirio_core__Value__c,
                   appirio_core__Config_Option__c
              from appirio_core__Config_Value__c
             where appirio_core__config_Option__r.appirio_core__Group_Key__c = 'asm-triggers'
               and (appirio_core__config_Option__r.name = 'handlebillingeventitemchange'
                or appirio_core__config_Option__r.name = 'handletransactionformilestone'
                or appirio_core__config_Option__r.name = 'beforeMiscellaneousAdjustmentChange'
                or appirio_core__config_Option__r.name = 'beforeMilestoneChange'
                or appirio_core__config_Option__r.name = 'afterExpenseReportChange'
                or appirio_core__config_Option__r.name = 'handleExpenseLineChange'
                or appirio_core__config_Option__r.name = 'handleExpenseReportUpdate'
                or appirio_core__config_Option__r.name = 'updateExpenseReportForExpense'
                or appirio_core__config_Option__r.name = 'beforeBudgetChange'
                or appirio_core__config_Option__r.name = 'handleTransactionForBudget'
                or appirio_core__config_Option__r.name = 'handleActualsForTransaction'
                or appirio_core__config_Option__r.name = 'updateAssignmentForTimecard'
                or appirio_core__config_Option__r.name = 'updateMilestoneForTimecard'
                or appirio_core__config_Option__r.name = 'updateTimecardHeaderForTimecard'
                or appirio_core__config_Option__r.name = 'handleTransactionForTimecard'
                or appirio_core__config_Option__r.name = 'handleBillingEventChange')
            order by appirio_core__config_Option__r.name
            limit 16];
//                or appirio_core__config_Option__r.name = 'beforeTimecardHeaderChange'
//                or appirio_core__config_Option__r.name = 'handleTimecardHeaderChange'

        if (tcsCoreValues != null && !tcsCoreValues.isEmpty())
        {
           System.debug('Found triggers to disable');
          tcsCoreValues[0].appirio_core__Value__c = enabled;
          tcsCoreValues[1].appirio_core__Value__c = enabled;
          tcsCoreValues[2].appirio_core__Value__c = enabled;
          tcsCoreValues[3].appirio_core__Value__c = enabled;
          tcsCoreValues[4].appirio_core__Value__c = enabled;
          tcsCoreValues[5].appirio_core__Value__c = enabled;
          tcsCoreValues[6].appirio_core__Value__c = enabled;
          tcsCoreValues[7].appirio_core__Value__c = enabled;
          tcsCoreValues[8].appirio_core__Value__c = enabled;
          tcsCoreValues[9].appirio_core__Value__c = enabled;
          tcsCoreValues[10].appirio_core__Value__c = enabled;
          tcsCoreValues[11].appirio_core__Value__c = enabled;
          tcsCoreValues[12].appirio_core__Value__c = enabled;
          tcsCoreValues[13].appirio_core__Value__c = enabled;
          tcsCoreValues[14].appirio_core__Value__c = enabled;
          tcsCoreValues[15].appirio_core__Value__c = enabled;
          //tcsCoreValues[16].appirio_core__Value__c = enabled;
          //tcsCoreValues[17].appirio_core__Value__c = enabled;
          update tcsCoreValues;
        }
        else{
            System.debug('Did not disable');
        }        
    }


}