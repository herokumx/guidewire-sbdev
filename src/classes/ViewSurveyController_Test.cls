@istest
private class ViewSurveyController_Test{
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    static Entitlement ent;
    static CS_Milestone_Business_Hours__c mbh;
    //------------------------------------------------------------------------------//
    //------------------------------------------------------------------------------//

     static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        /*
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
            
        // insert child assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
        
         if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
             acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         }
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        */
        List<Case> caseList = new List<Case>();
        Case c = new Case();
        //c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        //c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '1-Blocker';
        //c.CS_Urgency__c = 'High';
        //c.CS_Contact_Asset__c = acp.Id;
        caseList.add(c);
        insert caseList;
        
        //ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
        
    }
    private static Testmethod void testViewSurveyController() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.init();
        System.assert(vsc.allQuestionsSize == 4);
        System.assert(tu.surveyId != null);


        vsc.submitResults();
        for (question q : vsc.allQuestions)
        {
            q.selectedOption = String.valueof(2);
            q.choices = String.valueof(2);
            q.selectedOptions = new List<String>();
            q.selectedOptions.add(String.valueof(2));
            vsc.submitResults();
        }
        System.assertEquals(true, vsc.thankYouRendered);


        //test something
    }

private static Testmethod void testViewSurveyController_test1() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Test.startTest();
        setupTestData();
        
        //query case
        Case insertedCase = [Select Id from Case limit 1];
        Contact insertedContact=[Select id from contact limit 1];

        

        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.currentPage().getParameters().put('caId',insertedCase.id);
        Apexpages.currentPage().getParameters().put('cId',insertedContact.id);
        viewShareSurveyComponentController stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.init();
        System.assert(vsc.allQuestionsSize == 4);
        System.assert(tu.surveyId != null);
        System.assert(insertedCase.id!=null);
        System.assert(insertedContact.id!=null);


        vsc.submitResults();
        for (question q : vsc.allQuestions)
        {
            q.selectedOption = String.valueof(2);
            q.choices = String.valueof(2);
            q.selectedOptions = new List<String>();
            q.selectedOptions.add(String.valueof(2));
            vsc.submitResults();
        }
        System.assertEquals(true, vsc.thankYouRendered);
          Test.stopTest();


        //test something
    }


    private static Testmethod void testUpdateSurveyName() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.surveyName = 'new name';
        system.assert(vsc.updateSurveyName() == null);

    }


    private static Testmethod void testupdateSurveyThankYouAndLink() {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.surveyThankYouText = 'new stuff';
        vsc.surveyThankYouURL = 'more new stff';
        system.assert(vsc.updateSurveyThankYouAndLink()==null);
    }


}