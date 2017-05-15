@isTest
private class CS_AssignmentCaseControllerTest 
{
    static testmethod void testAssignment()
    {
        psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
      
        //Create test account with a location so that locations will be created
        Account a = psaTestUtils.createTestAccount('Test Account', '98675');
        a.Participant_id__c = '8796';
        update a;
        
         User u = psaTestUtils.createTestUser('tuCs', 'tuserCase@tuser.com', 'userCase', 'test22', 'tuserCase@tuser.com', 'tuserCa');
      
        //Create 2 contacts, one to submit and one as the manager
         Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
         c.PSA_Billing_Level__c = '110';
         update c;
         
     //  test.startTest();
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Time Off', a, testR, testP, testG, null, c, u);
        testProject.PSA_Milestone_Required__c = false;
        update testProject;
        test.startTest();
        PSA_Rate_Set__c rs = new PSA_Rate_Set__c();
        rs.PSA_Project__c = testProject.id;
        rs.PSA_Is_Global__c = false;
        insert rs;

        PSA_Rate__c rate = new PSA_Rate__c();
        rate.psa_Billing_Level__c = '120';
        rate.PSA_Average_Cost_Rate__c = 35;
        rate.PSA_Bill_Rate_Amount__c = 80;
        rate.PSA_Start_Date__c = Date.Today() - 20;
        rate.PSA_End_Date__c = Date.Today() + 200;
        rate.PSA_Bill_Rate_Set__c = rs.id;
        insert rate;
       
       pse__Assignment__c testAssignment = psaTestUtils.createTestSimpleAssignment(testProject, c, 'Data Migration Specialist'); 
       
       system.debug('Total quries :' +Limits.getQueries());
              
       
        Product2 pd = new Product2();
        pd.Name='TestProduct'; 
        pd.ProductCode='TEPD';
        pd.Product_Group_Name__c = 'BillingCenter Group';
        insert pd;
        
         CS_Release__c release = new CS_Release__c();
         release.CS_Product__c = pd.Id;
         release.CS_IsActive__c = true;
         release.CS_Major_Release_version__c = '8';
         release.CS_Minor_Release_Version__c ='1';
         insert release;
        
        Asset parentAsset = new Asset();
        parentAsset.Name='TestParentAssetProspect'; 
                                     parentAsset.AccountId=a.Id; 
                                     parentAsset.CS_Support_Group__c='Billing System';
                                     parentAsset.Status = 'Prospect';
                                     parentAsset.CS_Is_Active__c = true;
        insert parentAsset;
        
        Asset childAst = CS_TestDataUtility.createChildAssetWithRelease(a,pd,parentAsset,release,'active');
      
       
       PageReference pref = Page.CS_CreateCase_for_PS;       
    
       Test.setCurrentPage(pref);
       ApexPages.currentPage().getParameters().put('id', testAssignment.id); 
       
       ApexPages.StandardController sc = new ApexPages.StandardController(testAssignment);
              
       AssignmentCaseController disCon = new AssignmentCaseController(sc);
       
     //  System.assertEquals(NUM_QUERY, Limits.getQueries());
       system.debug('Total quries :' +Limits.getLimitQueries());
       system.debug('Total quries :' +Limits.getQueries());
         
         List<SelectOption> assets = disCon.getAssetList();
         disCon.setAset(childAst.Id);
         List<SelectOption> versions = disCon.getVersionList();      
         PageReference result = disCon.checkResource();
         PageReference result1 = disCon.saveMe(); 
       test.stopTest();
    //   System.assertEquals(NUM_QUERY, Limits.getQueries());
      
   }
    
}