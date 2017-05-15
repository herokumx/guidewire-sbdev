@isTest
public with sharing class TestGenerateBillingsForecastDetails {
	
	private static void setupdata(){
      
     // create Project Forecast Detail
       
      //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');

        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('tuser121', 'tuser121@tuser.com', 'tser121', 'test', 'tuser121@tuser.com', 'ttser123');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        
        Date startDate = system.today().adddays(-61);
        Date endDate = system.today().adddays(-30);
        Double seasonalityFactor = 0.90;
        pse__Time_Period__c timePeriod = psaTestUtils.createTestTimePeriod('Test Period', seasonalityFactor, startDate, endDate, 'Month', true);

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        PSA_Project_Forecast__c prjForecast = new PSA_Project_Forecast__c(PSA_Project__c = testProject.Id, PSA_Include_in_Forecast__c = true,PSA_Time_Period__c =  timePeriod.ID);
        insert prjForecast;
        PSA_Project_Forecast_Detail__c forecastDetails = new PSA_Project_Forecast_Detail__c(PSA_Project_Forecast__c = prjForecast.Id,CurrencyIsoCode ='USD',PSA_Scheduled_Cost__c= 1,PSA_Scheduled_Time_Billings__c =1); 
        insert forecastDetails;

	}

	@isTest
	private static void TestForecastDetails() {
	    setupdata(); 
	    Test.startTest();
        String sDate = String.valueOf(system.today().addDays(-365));
        String eDate = String.valueOf(system.today());
        // validate if data is returned for the Forecast Detail report.
		System.assert(GenerateBillingsForecastDetails.getForecastDetails(sDate,eDate).size()>0);
		Test.stopTest();
	}

}