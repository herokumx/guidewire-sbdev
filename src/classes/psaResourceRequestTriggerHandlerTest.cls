@isTest
private class psaResourceRequestTriggerHandlerTest {
	
	@isTest static void testDefaultRequest() {
		psaTestUtils.initDefaultWorkCalendar();
                //Create RPG
                List<Account> updates = new List<Account>();
                pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
                pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
                pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
                Account a = psaTestUtils.createTestAccount('Test Account', '12345');
                a.Participant_id__c = '1234';
        		updates.add(a);
                //update a;

                Account a2 = psaTestUtils.createTestAccount('Test Account 2', '12945');
                a2.Participant_id__c = '1294';
        		updates.add(a2);
                update updates;
                //Create 2 contacts, one to submit and one as the manager
                User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
                Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
				System.debug(LoggingLevel.WARN, '***'+Limits.getQueries());
                
                List<pse__Proj__c> projects = new List<pse__Proj__c>();
                pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u, false);
                pse__Proj__c testProject2 = psaTestUtils.createTestProjectInProgress('Test Project 2', a, testR, testP, testG, null, c, u, false);
                pse__Proj__c testProject3 = psaTestUtils.createTestProjectInProgress('Test Project 3', a2, testR, testP, testG, null, c, u, false);
                projects.add(testProject);
                projects.add(testProject2);
                projects.add(testProject3);
                insert projects;
        		System.debug(LoggingLevel.WARN, '***'+Limits.getQueries());
        		Test.startTest();
                
                insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
        	
                List<PSA_Rate_Set__c> rateSets = new List<PSA_Rate_Set__c>();
                PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
                rs.PSA_Project__c = testProject.id;
                rs.PSA_Is_Global__c = false;
                rateSets.add(rs);

                PSA_Rate_Set__c rsAccount = new PSA_Rate_Set__c();
                rsAccount.PSA_Account__c = a.id;
                rsAccount.PSA_Is_Global__c = false;
                rateSets.add(rsAccount);

                PSA_Rate_Set__c rsGlobal = new PSA_Rate_Set__c();
                rsGlobal.PSA_Is_Global__c = true;
                rateSets.add(rsGlobal);
                insert rateSets;

                List<PSA_Rate__c> rates = new List<PSA_Rate__c>();
                PSA_Rate__c rate = new PSA_Rate__c();
                rate.psa_Billing_Level__c = '120';
                rate.PSA_Average_Cost_Rate__c = 35;
                rate.PSA_Bill_Rate_Amount__c = 80;
                rate.PSA_Start_Date__c = Date.Today() - 360;
                rate.PSA_End_Date__c = Date.Today() + 360;
                rate.PSA_Bill_Rate_Set__c = rs.id;
                rates.add(rate);
                PSA_Rate__c rate2 = new PSA_Rate__c();
                rate2.psa_Billing_Level__c = '130';
                rate2.PSA_Average_Cost_Rate__c = 35;
                rate2.PSA_Bill_Rate_Amount__c = 80;
                rate2.PSA_Start_Date__c = Date.Today() - 360;
                rate2.PSA_End_Date__c = Date.Today() + 360;
                rate2.PSA_Bill_Rate_Set__c = rs.id;
                rates.add(rate2); 
                insert rates;

                pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, false);
                //testRR.pse__Account__c = a.id;
                insert testRR;

                testRR.PSA_Billing_Level__c = '130';
                testRR.pse__Start_Date__c = Date.Today() - 7;
                update testRR;
                Test.stopTest();



	}

    @isTest static void testDefaultRequest2() {
        psaTestUtils.initDefaultWorkCalendar();
                //Create RPG
                pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
                pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
                pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
                Account a = psaTestUtils.createTestAccount('Test Account', '12345');
                a.Participant_id__c = '1234';
                update a;

                Account a2 = psaTestUtils.createTestAccount('Test Account 2', '12945');
                a2.Participant_id__c = '1294';
                update a2;
                //Create 2 contacts, one to submit and one as the manager
                User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
                Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

                Test.startTest();
                List<pse__Proj__c> projects = new List<pse__Proj__c>();
                pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u, false);
                projects.add(testProject);
                insert projects;

                insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
            
                List<PSA_Rate_Set__c> rateSets = new List<PSA_Rate_Set__c>();
                PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
                rs.PSA_Project__c = testProject.id;
                rs.PSA_Is_Global__c = false;
                rateSets.add(rs);

                PSA_Rate_Set__c rsAccount = new PSA_Rate_Set__c();
                rsAccount.PSA_Account__c = a.id;
                rsAccount.PSA_Is_Global__c = false;
                rateSets.add(rsAccount);

                PSA_Rate_Set__c rsGlobal = new PSA_Rate_Set__c();
                rsGlobal.PSA_Is_Global__c = true;
                rateSets.add(rsGlobal);
                insert rateSets;

                List<PSA_Rate__c> rates = new List<PSA_Rate__c>();
                PSA_Rate__c rate = new PSA_Rate__c();
                rate.psa_Billing_Level__c = '120';
                rate.PSA_Average_Cost_Rate__c = 35;
                rate.PSA_Bill_Rate_Amount__c = 80;
                rate.PSA_Start_Date__c = Date.Today() - 360;
                rate.PSA_End_Date__c = Date.Today() + 360;
                rate.PSA_Bill_Rate_Set__c = rs.id;
                rates.add(rate);
                PSA_Rate__c rate2 = new PSA_Rate__c();
                rate2.psa_Billing_Level__c = '130';
                rate2.PSA_Average_Cost_Rate__c = 35;
                rate2.PSA_Bill_Rate_Amount__c = 80;
                rate2.PSA_Start_Date__c = Date.Today() - 360;
                rate2.PSA_End_Date__c = Date.Today() + 360;
                rate2.PSA_Bill_Rate_Set__c = rs.id;
                rates.add(rate2);


                
                insert rates;

                pse__Schedule__c testSched = new pse__Schedule__c(
                    pse__Start_Date__c = Date.today(),
                    pse__End_Date__c = Date.today().addDays(30),
                    pse__Sunday_Hours__c = 0,
                    pse__Monday_Hours__c = 8,
                    pse__Tuesday_Hours__C = 8,
                    pse__Wednesday_Hours__c = 8,
                    pse__Thursday_Hours__c = 8,
                    pse__Friday_Hours__c = 8,
                    pse__Saturday_Hours__C = 0);
                insert testSched;

                pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, false);
                testRR.pse__Staffer_Resource__c = c.id;
                testRR.pse__Resource_Held__C = true;
                testRR.pse__Preferred_Schedule__c = testSched.id;

                //testRR.pse__Account__c = a.id;
                insert testRR;

                testRR.pse__Status__c = 'Cancelled';
        		testRR.pse__Preferred_Schedule__c = null;
                update testRR;
                Test.stopTest();

                pse__Resource_Request__c result = [Select Id,pse__Preferred_Schedule__c from pse__Resource_Request__c where pse__Project__C = :testProject.id limit 1];
                System.assertEquals(Null, result.pse__Preferred_Schedule__c);



    }
	
	@isTest static void testWithHolidaysAndManyRates() {


		// Implement test code
                psaTestUtils.initDefaultWorkCalendar();
                pse__HolidayObj__c holiday = new pse__HolidayObj__c();
                holiday.name = 'Independence Day';
                holiday.pse__Date__c = Date.newInstance(2015, 7, 4);
                holiday.pse__Work_Hours__c = 0;
                holiday.pse__Work_Calendar__c = psaTestUtils.defaultWorkCalendar.id;
                insert holiday;

                //Create RPG
                pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
                pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
                pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
                Account a = psaTestUtils.createTestAccount('Test Account', '12345');
                a.Participant_id__c = '1234';
                update a;

                Account a2 = psaTestUtils.createTestAccount('Test Account 2', '12945');
                a2.Participant_id__c = '1294';
                update a2;
                //Create 2 contacts, one to submit and one as the manager
                User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
                Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

                Test.startTest();

                List<pse__Proj__c> projects = new List<pse__Proj__c>();
                pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u, false);
                //pse__Proj__c testProject2 = psaTestUtils.createTestProjectInProgress('Test Project 2', a, testR, testP, testG, null, c, u, false);
                pse__Proj__c testProject3 = psaTestUtils.createTestProjectInProgress('Test Project 3', a2, testR, testP, testG, null, c, u, false);
                projects.add(testProject);
                //projects.add(testProject2);
                projects.add(testProject3);
                insert projects;

                insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
                List<PSA_Rate_Set__c> rateSets = new List<PSA_Rate_Set__c>();
                PSA_Rate_Set__c rsAccount = new PSA_Rate_Set__c();
                rsAccount.PSA_Account__c = a.id;
                rsAccount.PSA_Is_Global__c = false;
                rateSets.add(rsAccount);
                
                PSA_Rate_Set__c rsGlobal = new PSA_Rate_Set__c();
                rsGlobal.PSA_Is_Global__c = true;
                rateSets.add(rsGlobal);
                insert rateSets;

                List<PSA_Rate__c> rates = new List<PSA_Rate__c>();
                PSA_Rate__c rate = new PSA_Rate__c();
                rate.psa_Billing_Level__c = '120';
                rate.PSA_Average_Cost_Rate__c = 35;
                rate.PSA_Bill_Rate_Amount__c = 80;
                rate.PSA_Start_Date__c = Date.Today() - 360;
                rate.PSA_End_Date__c = Date.Today() + 360;
                rate.PSA_Bill_Rate_Set__c = rsAccount.id;
                rates.add(rate);

                PSA_Rate__c rate2 = new PSA_Rate__c();
                rate2.psa_Billing_Level__c = '130';
                rate2.PSA_Average_Cost_Rate__c = 35;
                rate2.PSA_Bill_Rate_Amount__c = 80;
                rate2.PSA_Start_Date__c = Date.Today() - 360;
                rate2.PSA_End_Date__c = Date.Today() + 360;
                rate2.PSA_Bill_Rate_Set__c = rsGlobal.id;
                rates.add(rate2);
                insert rates;

                List<pse__Resource_Request__c> rrs = new List<pse__Resource_Request__c>();
                pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, false);
                pse__Resource_Request__c testRR2 = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject3.id, 'Manager - Full Time', '130', 45, false);
                //testRR.pse__Account__c = a.id;
                rrs.add(testRR);
                rrs.add(testRR2);
                insert rrs;

                delete testRR2;
	}
	
        @isTest static void testFixedFee(){
                // Implement test code
                psaTestUtils.initZeroWorkCalendar();
                pse__HolidayObj__c holiday = new pse__HolidayObj__c();
                holiday.name = 'EveryDay Holiday';
                holiday.pse__Date__c = Date.today();
                holiday.pse__Work_Hours__c = 0;
                holiday.pse__Work_Calendar__c = psaTestUtils.defaultWorkCalendar.id;
                insert holiday;

                //Create RPG
                pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
                pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
                pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
                Account a = psaTestUtils.createTestAccount('Test Account', '12345');
                a.Participant_id__c = '1234';
                update a;

                Account a2 = psaTestUtils.createTestAccount('Test Account 2', '12945');
                a2.Participant_id__c = '1294';
                update a2;
                //Create 2 contacts, one to submit and one as the manager
                User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
                Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

                Test.startTest();

                List<pse__Proj__c> projects = new List<pse__Proj__c>();
                pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u, false);
                testProject.pse__Billing_Type__c = 'Fixed Fee';
                insert testProject;

                pse__Time_Period__c thisMonth = new pse__Time_Period__c();
                thisMonth.Name = 'Monthly';
                thisMonth.pse__Start_Date__c = Date.Today() - 15;
                thisMonth.pse__End_Date__c = Date.Today() + 15;
                thisMonth.pse__Type__c = 'Month';
                insert thisMonth;

                insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
                List<pse__Resource_Request__c> rrs = new List<pse__Resource_Request__c>();
                pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, false);
                testRR.pse__Percent_Allocated__c = 0;
                rrs.add(testRR);
                insert rrs;

                testRR.PSA_Billing_Level__c = '130';
                testRR.pse__Start_Date__c = Date.today() - 4;
                update testRR;

        }

        @isTest static void testAssignedRR(){

                 // Implement test code
                psaTestUtils.initZeroWorkCalendar();
                pse__HolidayObj__c holiday = new pse__HolidayObj__c();
                holiday.name = 'EveryDay Holiday';
                holiday.pse__Date__c = Date.today();
                holiday.pse__Work_Hours__c = 0;
                holiday.pse__Work_Calendar__c = psaTestUtils.defaultWorkCalendar.id;
                insert holiday;

                //Create RPG
                pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
                pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
                pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
                Account a = psaTestUtils.createTestAccount('Test Account', '12345');
                a.Participant_id__c = '1234';
                update a;

                Account a2 = psaTestUtils.createTestAccount('Test Account 2', '12945');
                a2.Participant_id__c = '1294';
                update a2;
                //Create 2 contacts, one to submit and one as the manager
                User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
                Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

                Test.startTest();

                List<pse__Proj__c> projects = new List<pse__Proj__c>();
                pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u, false);
                testProject.pse__Billing_Type__c = 'Fixed Fee';
                insert testProject;

                pse__Time_Period__c thisMonth = new pse__Time_Period__c();
                thisMonth.Name = 'Monthly';
                thisMonth.pse__Start_Date__c = Date.Today() - 15;
                thisMonth.pse__End_Date__c = Date.Today() + 15;
                thisMonth.pse__Type__c = 'Month';
                insert thisMonth;

                insert new pse__Permission_Control__c(pse__User__c=UserInfo.getUserId(), pse__Expense_Entry__c=true, pse__Resource_Request_Entry__c = true, pse__Region__c = testR.id);
                List<pse__Resource_Request__c> rrs = new List<pse__Resource_Request__c>();
                pse__Resource_Request__c testRR = psaTestUtils.createTestResourceRequest('Test Request', testR.id, Date.today() - 5, Date.Today() + 50, testProject.id, 'Manager - Full Time', '120', 45, false);
                testRR.pse__Percent_Allocated__c = 0;
                rrs.add(testRR);
                insert rrs;

                pse__Assignment__c assign = psaTestUtils.createTestAssignment(testProject, c, 'Manager - Full Time');
                assign.pse__Resource_Request__c = testRR.id;
                update assign;

                testRR.pse__Status__c = 'Assigned';
                testRR.pse__Assignment__c = assign.id;
                update testRR;

        }


}