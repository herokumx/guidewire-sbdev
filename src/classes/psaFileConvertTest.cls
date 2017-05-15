/**************************************************************************************
// Name          : psaFileConvertTest
// Date          : March 4, 2016 
// Description   : Test class for psaFileConvert, psaFileConvertZamzar, psaFileConvertSchedulable
// Author        : CLD Partners 
// Revisions     : 2016-03-04 Klassen initial version
//               : 
***************************************************************************************/
@isTest(seeAllData=false)
private class psaFileConvertTest {

	private static pse__Proj__c testProject;
	private static User u;
	private static Contact c;
	private static pse__Expense_Report__c testExpReport;
	private static pse__Expense__c testExpense;
	private static Attachment testAttachment;
	private static pse__Work_Calendar__c defaultWorkCalendar;

	@isTest static void TestBatch() {
		populateCombineReceiptsCustomSetting();

		//Create users, project, and expense report with related objects
		setupTestData1();

		//testAttachment = new Attachment(Name='Test Attachment', ParentId=c.Id);
        //testAttachment.body = blob.toPDF('This is a fake pdf');
        //insert testAttachment;

		setupTestData2();

        String jsonString = psaZamzarMock.getResponseString();

        //Insert PSA_File_Convert__c record
		PSA_File_Convert__c fileToConvert = new PSA_File_Convert__c();
		fileToConvert.PSA_Batch_Number__c = 1;
		fileToConvert.PSA_Expense__c = testAttachment.ParentId;
		fileToConvert.PSA_Attachment_Parent_Id__c = testAttachment.ParentId;
		fileToConvert.PSA_Target_Format__c = 'png';
		fileToConvert.PSA_Source_Attachment_Id__c = testAttachment.Id;
		fileToConvert.PSA_Source_File_Name__c = testAttachment.Name;
		fileToConvert.PSA_File_Convert_HTTP_Response__c = jsonString;
		fileToConvert.PSA_Conversion_Status__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'status', null);
		fileToConvert.PSA_Conversion_Job_Id__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'id', null);
		fileToConvert.PSA_Source_File_Job_Id__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'source_file', 'id');
		fileToConvert.PSA_Batch_Type__c = 'BillingEvent';
		insert fileToConvert;

        //Insert PSA_File_Convert__c record
		PSA_File_Convert__c fileToConvert2 = new PSA_File_Convert__c();
		fileToConvert2.PSA_Batch_Number__c = 2;
		fileToConvert.PSA_Expense__c = testAttachment.ParentId;
		fileToConvert2.PSA_Attachment_Parent_Id__c = testAttachment.ParentId;
		fileToConvert2.PSA_Target_Format__c = 'png';
		fileToConvert2.PSA_Source_Attachment_Id__c = testAttachment.Id;
		fileToConvert2.PSA_Source_File_Name__c = testAttachment.Name;
		fileToConvert2.PSA_File_Convert_HTTP_Response__c = jsonString;
		fileToConvert2.PSA_Conversion_Status__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'status', null);
		//fileToConvert.PSA_Conversion_Job_Id__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'id', null);
		fileToConvert2.PSA_Source_File_Job_Id__c = psaFileConvert.parseJSONForKeyValue(jsonString, 'source_file', 'id');
		fileToConvert2.PSA_Batch_Type__c = 'BillingEvent';
		fileToConvert2.PSA_Conversion_Job_Id__c = '16';
		insert fileToConvert2;

		Test.startTest();


		// Set mock callout class
        psaZamzarMock zm = new psaZamzarMock();
        Test.setMock(HttpCalloutMock.class, zm);

        Set<Id> expenseIds = new Set<Id>();
        expenseIds.add(testExpense.Id);
        Set<Id> attachmentIds = new Set<Id>();
        attachmentIds.add(testAttachment.Id);

        psaFileConvert.initiateConversionBatch(expenseIds, testExpReport.Id, 'ExpenseReport');
        //psaFileConvert.uploadFileToConvert(testAttachment.body, testAttachment.Name, psaFileConvertZamzar.getBaseURL() + 'jobs?target_format=' + 'png');
        //psaFileConvertZamzar.checkCredits();
        
        psaFileConvertZamzar.testAuthentication();

        psaFileConvert.getNextBatchNumber(expenseIds);
        //psaFileConvert.sendEmailNotification('test', 'test');

        //the following line results in a "uncommitted work pending callout exception"
        //psaFileConvert.checkJobsByBatch(1, testExpReport.Id, 'ExpenseReport', 1);

        Set<Id> fileAttachIds = new Set<Id>();
        fileAttachIds.add(fileToConvert.Id);
//        fileAttachIds.add(fileToConvert2.Id);
//        psaFileConvert.checkJobs(fileAttachIds);

 //       psaFileConvert.scheduleJobByBatchNumber(1, c.Id, 'BillingEvent', 10);
        //psaFileConvert.checkJobStatusByBatch(2, c.Id, 'BillingEvent', 9);

        //** Call a batch job to upload the non-image files to Zamzar, one at a time (batch size=1).  This is done
        // to help prevent a heap size limit error
        Integer BATCH_SIZE = 1; 
        Boolean sendEmail = false;           
        psaFileConvertBatch fileConvertBatch = new psaFileConvertBatch(attachmentIds, 
                2, sendEmail, 'ExpenseReport', testExpReport.Id);
        Id batchId = database.executeBatch(fileConvertBatch, BATCH_SIZE);    
        System.debug('**** psaFileConvert: Batch executed batchId: ' +batchId); 

        //** Call a batch job to upload the non-image files to Zamzar, one at a time (batch size=1).  This is done
        // to help prevent a heap size limit error
        BATCH_SIZE = 1; 
        sendEmail = false;           
        psaFileConvertCheckJobsBatch fileConvertCheckJobs = new psaFileConvertCheckJobsBatch( 
                3, testExpReport.Id, 'ExpenseReport', 1, sendEmail);
        batchId = database.executeBatch(fileConvertCheckJobs, BATCH_SIZE);    
        System.debug('**** psaFileConvert.checkJobsByBatch executed batchId: ' +batchId);             


        //Test the sendProcessCompleteEmail code
        psaCombineExpenseReceipts.sendProcessCompleteEmail(testExpReport.Id, 'ExpenseReport', UserInfo.getSessionId());

		Test.stopTest();
	}

    private static void setupTestData1() {

        //Create RPG
        pse__Region__c testR = createTestRegion('Corporate'); //copied from TestUtils
        pse__Practice__c testP = createTestPractice('Corporate'); //copied from TestUtils
        pse__Grp__c testG = createTestGroup('Corporate'); //copied from TestUtils
        Account a = createTestAccountWithParticipantId('Test Account', '12345', '1234'); //copied from TestUtils

        //Create 2 contacts, one to submit and one as the manager
        u = createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2'); //copied from TestUtils
        c = createTestResource(u, testR, testP, testG); //copied from TestUtils
        insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Expense_Entry__c=true);
        createTestProjectInProgressWithExpenseEntry('Test Project', a, testR, testP, testG, null, c, u);
	}

	private static void setupTestData2() {
        testExpReport = createTestExpenseReport('Test Expense Report', testProject.id, c.id, true);
        testExpense = createTestExpenseOnReport(testExpReport.id, testProject.id, c.id, 500, 'Lodging - Hotel', Date.today(), true);

		testAttachment = new Attachment(Name='Test Attachment', ParentId=testExpense.Id);
        testAttachment.body = blob.toPDF('This is a fake pdf');
        insert testAttachment;
	}

	private static void populateCombineReceiptsCustomSetting() {
		PSA_Combine_Receipts__c psaCombineReceipts = new PSA_Combine_Receipts__c(Name='default');
		psaCombineReceipts.PSA_Notification_Threshold__c = 10;
		psaCombineReceipts.PSA_Email_Notify_List__c = 'testCLD@test.com';
		psaCombineReceipts.PSA_Zamzar_API_Key__c = '123';
		psaCombineReceipts.PSA_Target_Format__c = 'png';
		psaCombineReceipts.PSA_Test_Mode__c = true;
		psaCombineReceipts.PSA_Zamzar_Prod_URL__c = 'https://api.zamzar.com/v1/';
		psaCombineReceipts.PSA_Zamzar_Test_URL__c = 'https://sandbox.zamzar.com/v1/';
		psaCombineReceipts.PSA_Send_Low_Credit_Notifications__c = true;
		psaCombineReceipts.PSA_Max_Convert_Attempts__c = 10;

		insert psaCombineReceipts;		
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
/*
        Creates a test resource
    */
    public static Contact createTestResource(User salesforceUser, pse__Region__c region, pse__Practice__c practice, pse__Grp__c resourceGroup)
    {
        initDefaultWorkCalendar();

        Contact testResource = new Contact(
            LastName='User',
            pse__Resource_Role__c='Consultant',
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
    public static pse__Proj__c createTestProjectInProgressWithExpenseEntry(String projectName, Account a, pse__Region__c region, pse__Practice__c practice, 
            pse__Grp__c projGroup, Opportunity opp, Contact pm, User user) {

        testProject = new pse__Proj__c(  Name=projectName,
                                        pse__Allow_Timecards_Without_Assignment__c=true,
                                        pse__Allow_Expenses_Without_Assignment__c=true);

        //testProject.Is_Test__c = true;
        testProject.pse__Account__c = a.id;
        testProject.PSA_Customer_Account__c = a.id;
        testProject.pse__Region__c = region.Id;
        testProject.pse__Practice__c = practice.Id;
        testProject.pse__Group__c = projGroup.Id;
        testProject.pse__Start_Date__c = Date.today();
        testProject.pse__End_Date__c = Date.today() + 90;
        //testProject.PSA_Director_Review_Complete__c = true;
        //testProject.PSA_PM_Review_Complete__c = true;
        //testProject.PSA_Ops_Review_Complete__c = true;
        testProject.pse__Stage__c = 'Draft';
        testProject.pse__Project_Manager__c = pm.id;
        testProject.PSA_Director__c = pm.id;
        testProject.PSA_CIM__c = pm.id;
        //testProject.PSA_PIA__c = pm.id;
        //testProject.psa_VP__c = pm.id;
        //testProject.PSA_BR_Billing_Rules_Status__c = 'Accepted';
        testProject.PSA_PO_Number__c = '12345';
        testProject.pse__Is_Active__c = true;
        testProject.pse__Is_Billable__c = true;
        testProject.pse__Exclude_From_Billing__c = true;
        testProject.pse__Project_Type__c = 'Customer Project';
        testProject.PSA_Forecast_Category__c = 'Committed';
        testProject.PSA_Expense_Approval_Method__c = 'Project Manager';
        testProject.PSA_Time_Approval_Method__c = 'Project Manager';
        testProject.PSA_Daily_Cap__c = 8;
        //testProject.PSA_CDO_Email__c = 'cdo@guidewire.com';
        testProject.PSA_Services_Product__c = 'Implementation';
        testProject.PSA_Product_Line__c = 'BillingCenter';
        testProject.PSA_VSOE_Type__c = 'Not Stand Alone Sale';
        testProject.PSA_BR_Expenses_Billing_Type__c = 'As Incurred';
        testProject.pse__Billing_Type__c = 'Time and Materials';
        //testProject.pse__Include_In_Forecasting__c = True;
        //testProject.PSA_Include_in_Billing_Forecast__c  = True;
        //testProject.PSA_Revenue_Forecast_Model__c = 'As Delivered - Fixed Deferral Duration';
        //testProject.PSA_Revenue_Recognition_Model__c = 'As Delivered';
        //testProject.PSA_Rate_Classification__c = 'Level Rate';
        //testProject.psa_Applicable_CSA_Signed__c = true;
        //testProject.PSA_Applicable_SOW_Fully_Executed__c = true;
        //testProject.pse__Closed_for_Time_Entry__c = false;
        //testProject.PSA_Pre_SOW_Status__c = 'Pre-SOW Start Approved';
        testProject.pse__Closed_for_Expense_Entry__c = false;

        PSA_Entity__c testentity = createTestEntity('Test E', '1234', 'TE', true);
        testProject.PSA_Billing_Legal_Entity__c = testentity.id;

        PSA_Department__c dept = createTestDepartment('Test Department', '1425', true);
        testProject.PSA_Department__c = dept.id;

        //Account_Contact__c shipTo = new Account_Contact__c();
        //Account_Contact__c billTo = new Account_Contact__c();

        //shipTo.Account__c = testProject.PSA_Customer_Account__c;
        //billTo.Account__c = testProject.pse__Account__c;
        //shipTo.Contact__c = pm.id;
        //shipTo.Participant_Account__c = testProject.PSA_Customer_Account__c;
        //billTo.Contact__c = pm.id;
        //billTo.Participant_Account__c = testProject.pse__Account__c;
        //shipto.Type__c = 'Ship To';
        //billTo.Type__c = 'Bill To';
        //List<Account_Contact__c> acs = new List<Account_Contact__c>();
        //acs.add(billTo);
        //acs.add(shipTo);
        //insert acs;

        //testProject.PSA_Bill_To_Contact__c = billTo.id;
        //testProject.PSA_Ship_To_Contact__c = shipTo.id;
        //testProject.PSA_Billing_Detail_Template__c = 'Daily';
        //testProject.PSA_Revenue_Deferral_Duration__c = 2;


        //testProject.CurrencyIsoCode = 'USD';
        //if(opp != null)
        //{
         //   testProject.pse__Opportunity__c = opp.Id;
        //}

        insert testProject;
        return testProject;
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
}