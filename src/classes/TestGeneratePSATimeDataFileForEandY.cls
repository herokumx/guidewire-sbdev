@isTest
   public class TestGeneratePSATimeDataFileForEandY {
	   @isTest
	  private static void TestEandYDataGeneration() {
        	
	    // insert test country and State.
	    pw_cc__CountryObject__c country = new pw_cc__CountryObject__c(
                                  Name = 'Test US',
                                  pw_cc__IsoCode_2__c = 'US',
                                  pw_cc__IsoCode_3__c = 'US'
                                );
        insert country;  
      
     
        pw_cc__State__c state = new pw_cc__State__c(
                                  Name = 'Test California',
                                  pw_cc__IsoCode__c = 'CA',
                                  pw_cc__Country__c = country.Id 
                                );
        insert state;       
	   
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

		PSA_Entity__c testentity = psaTestUtils.createTestEntity('Test E', '1234', 'TE', true);

		//Create 2 contacts, one to submit and one as the manager
		User u = psaTestUtils.createTestUser('rusr1', 'ruser123@tuser.com', 'userr123', 'testr', 'ruser12@tuser.com', 'rusr123');
		Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
		c.PSA_Fully_Loaded_Cost_Rate__c = 123;
		c.PSA_Resource_Entity__c = testentity.id;
		c.MailingCity = 'Ellicott City';
        c.MailingState = 'California';
        c.MailingPostalCode = '21042';
        c.MailingCountry = 'United States';
        c.PSA_Worker_Type__c = 'Employee';
        c.PSA_Worker_Id__c ='11111';
        
		update c;


		User u2 = psaTestUtils.createTestUser('rusr2', 'ruser321@tuser.com', 'userr321', 'testr', 'ruser32@tuser.com', 'rusr231');
		Contact c2 = psaTestUtils.createTestResource(u2, testR, testP, testG);
		
		u.ManagerId = u2.id;
		update u;

		
		//Create the project and assignment and assure that locations were created
		pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
		testProject.PSA_Time_Approval_Method__c = 'Project Manager';
		testProject.PSA_Milestone_Required__c = false;
		testProject.PSA_Billing_Legal_Entity__c = testentity.id;
		testProject.PSA_Customer_Account__c = cust.id;
		testProject.pse__Project_Type__c = 'Main';
		update testProject;

		pse__Project_Phase__c phase1 = new pse__Project_Phase__c();
		phase1.name = 'Creation';
		phase1.pse__Start_Date__c = Date.today().addDays(-30);
		phase1.pse__End_Date__c = Date.today().addDays(30);
		phase1.pse__Project__c = testProject.id;
		insert phase1;


		List<pse__Project_Location__c> locs = [Select id from pse__Project_Location__c where pse__Project__c = :testProject.id];
		pse__Assignment__c testAssignment = psaTestUtils.createTestAssignment(testProject, c, 'Data Migration Specialist');
		testAssignment.PSA_Rate_Needs_Review__c = false;
		update testAssignment;

		
		Test.startTest();
		pse__Timecard_Header__c testCard = psaTestUtils.initTestTimecardHeader(testProject.id, c.id, testAssignment.id, Date.today().addDays(-30), 8, phase1);
		insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Resource__c = c.id, pse__Timecard_Entry__c =true);
		testCard.pse__Primary_Project_Location__c = locs.get(0).id;
		testCard.pse__Bill_Rate__c = 25;
		testCard.pse__Billable__c = true;
		testCard.pse__Status__c = 'Submitted';
	    testCard.pse__Submitted__c = true;
	    insert testCard;
		
		List<Pse__Time_Date__c> timeDateList = new List<Pse__Time_Date__c>();
        Pse__Time_Date__c testTD = new PSE__Time_Date__c();
		testTD.pse__Timecard__c = testCard.id;
		testTD.pse__Date__c = Date.today().addDays(-30);
		testTD.pse__Hours__c = 8;
		timeDateList.add(testTD);
		
		
		// create duplicate
		Pse__Time_Date__c testTD2 = new PSE__Time_Date__c();
		testTD2.pse__Timecard__c = testCard.id;
		testTD2.pse__Date__c = Date.today().addDays(-30);
		testTD2.pse__Hours__c = 7;
		timeDateList.add(testTD2);
		
		Pse__Time_Date__c testTD3 = new PSE__Time_Date__c();
		testTD3.pse__Timecard__c = testCard.id;
		testTD3.pse__Date__c = Date.today().addDays(-29);
		testTD3.pse__Hours__c = 8;
		timeDateList.add(testTD3);
		insert timeDateList;
		
		// Approve Time card.
		testCard.pse__Approved__c = true;
		update testCard;
		
		// Test get request to get last month data. 
	   	GeneratePSATimeDataFileForEandY.doget();
	  
		  // test POST request to get month and year specific data.  	
		 if(System.now().month() == 1 || System.now().month() == 2){
	  	     GeneratePSATimeDataFileForEandY.getMonthSpecificData(String.valueof(12),String.valueof(System.now().year()-1));
	     }else{
	     	GeneratePSATimeDataFileForEandY.getMonthSpecificData(String.valueof(System.now().month()-1),String.valueof(System.now().year()));
	     }
	    	
	    Test.stopTest();
        
	    }
   }