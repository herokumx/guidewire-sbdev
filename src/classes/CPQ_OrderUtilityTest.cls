@isTest
private class CPQ_OrderUtilityTest {

    /**
     * Test method to create Opportunity for Contract test data
     */
    public static Opportunity createOppTestData1(Id accId){

      Opportunity objOpportunity = new Opportunity();
      objOpportunity.Name = 'TestOpportunity';
      objOpportunity.AccountId = accId;
      objOpportunity.StageName = 'Working';
      objOpportunity.CloseDate = System.Date.Today().addDays(15);
      objOpportunity.Opportunity_Type__c = 'Renewal Type';
      objOpportunity.CurrencyIsoCode = 'USD';
      insert objOpportunity;
      return objOpportunity;
    }
    /**
     * Test method to create Contract test data
     */
    public static Contract contractTestData(Id accId, Id oppId) {

      Contract contObj = new Contract();
      contObj.AccountId = accId;
      contObj.Status = 'Draft';
      contObj.CurrencyIsoCode = 'USD';
      contObj.StartDate = System.Today();
      contObj.SBQQ__Opportunity__c = oppId;
      contObj.Renewal_Status__c = 'Not Started ';
      // contObj.Invoice_Date__c = System.Today();
      insert contObj;
      return contObj;
    }

    /**
     * Test method to create Opportunity for Contract test data
     */
    public static Opportunity createOriginalOppTestData(Id accId){

      Opportunity objOpportunity = new Opportunity();
      objOpportunity.Name = 'TestOriginalOpportunity';
      objOpportunity.AccountId = accId;
      objOpportunity.StageName = 'Working';
      objOpportunity.CloseDate = System.Date.Today().addDays(15);
      objOpportunity.CPQ_Renewal_In_Scope_DWP__c = 6000000;
      objOpportunity.Premium_In_Scope__c = 6000000;
      objOpportunity.CurrencyIsoCode = 'USD';
      insert objOpportunity;
      return objOpportunity;
    }

    public static Account_Contact__c createBillToData(Id accId, Id contactId) {
        Five_Digit_Id__c recordCounter = new Five_Digit_Id__c(Current_Value__c = 1);
        insert recordCounter;
        Account_Contact__c billTo = new Account_Contact__c(
            Name = 'Bill To Account',
            RecordStatus__c = 'Active',
            Account__c = accId,
            Contact__c = contactId,
            Participant_Account__c = accId
        );

        insert billTo;
        return billTo;
    }

    /**
     * Test method to create Opportunity test data
     */
    public static Opportunity createOppTestData(Id accId, id oppId) {
            Contract contObj = contractTestData(accId, oppId);

            Contact objCon = new Contact(
                LastName = 'Test Contact',
                Email = 'test@contact.com'
            );
            insert objCon;

            Opportunity objOpportunity = new Opportunity();
            objOpportunity.pse__Parent_Opportunity__c = oppId;
            objOpportunity.Name = 'TestOpportunity';
            objOpportunity.AccountId = accId;
            objOpportunity.StageName = 'Working';
            objOpportunity.CloseDate = System.Date.Today().addDays(15);
            objOpportunity.Opportunity_Type__c = 'Net New +';
            objOpportunity.SBQQ__Renewal__c = true;
            objOpportunity.SBQQ__RenewedContract__c = contObj.Id;
            objOpportunity.CurrencyIsoCode = 'USD';
            objOpportunity.Bill_To__c = createBillToData(accId, objCon.Id).Id;

            insert objOpportunity;
            return objOpportunity;
    }

    /**
     * Test method to create SBQQ__Quote__c test data
     */
    public static SBQQ__Quote__c createQuoteTestData(Id oppId) {

            SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
            objQuote.SBQQ__Opportunity2__c = oppId;
            objQuote.SBQQ__Primary__c = true;
            objQuote.CPQ_In_Scope_DWP_Input__c = 2;
            objQuote.CPQ_In_Scope_DWP_Input_Type__c = 'Direct DWP';
            objQuote.SBQQ__BillingFrequency__c = 'Monthly';
            objQuote.SBQQ__StartDate__c = System.Today();
            objQuote.SBQQ__SubscriptionTerm__c = 6;
            objQuote.SBQQ__Type__c = 'Quote';
            objQuote.CPQ_Royalties__c = false;
            //objQuote.CurrencyIsoCode = 'USD';
            //objAccount.Email = strEmail;
            //objAccount.Company = 'TestCompany';
            insert objQuote;
            return objQuote;
    }

    /**
     * Test method to check Order creation with WireMessage IsCompany = true
     */
    @isTest static void test_createOrder() {

           // insert account
           Account objAcc = CPQ_TestDataUtility.accountTestData(false);
           objAcc.Participant_id__c = '1378';
           objAcc.Payment_Term__c = 'Net 30';
           insert objAcc ;
           system.debug('Created Account: ' + objAcc);

           Opportunity originalOpp = createOriginalOppTestData(objAcc.Id);
           system.debug('Created Original Opp: ' + originalOpp);
           Opportunity objOpportunity = createOppTestData(objAcc.Id, originalOpp.Id);
           system.debug('Created Opportunity: ' + objOpportunity);
           SBQQ__Quote__c objQuote = createQuoteTestData(objOpportunity.Id);
           system.debug('Created Quote: ' + objQuote);
           List<sObject> testDataOfWireMessages = Test.loadData(CPQ_Wire_Message__c.sObjectType, 'CPQ_TestDataWireMessage');
           // Verify that all 3 test accounts were created
           //System.assert(testDataOfWireMessages.size() == 1);
           List<Order> lstOrder = [Select Id From Order];
           system.assertEquals(0,lstOrder.size());
           system.debug('Verify there was no Order so far');

           Test.startTest();
                //Id oppId,Id primaryQuoteId,Id accId,String basecurr,String l_classid
                String returned = CPQ_OrderUtility.createOrder(objOpportunity.Id,objQuote.Id,objAcc.Id,'USD');
                System.debug('------ returned ------ : ' + returned);
           Test.stopTest();
           List<Order> lstOrderInserted = [Select Id,SBQQ__Quote__c,Is_Primary__c,Status,Pricebook2Id,Contract_Sign_Date__c  From Order];
           system.assertNotEquals(null,lstOrder);
           system.assertEquals(objQuote.ID,lstOrderInserted[0].SBQQ__Quote__c );
           system.assertEquals(true,lstOrderInserted[0].Is_Primary__c );
           system.assertEquals('Draft',lstOrderInserted[0].Status);
           system.assertEquals(Test.getStandardPricebookId(),lstOrderInserted[0].Pricebook2Id);
           system.assertEquals(Date.today(),lstOrderInserted[0].Contract_Sign_Date__c );
    }

    /**
     * Test method to check Order record creation with Existing Order record
     */
    @isTest static void test_createOrderWithExistingOrder() {

        List<sObject> countryCode = Test.loadData(pw_cc__CountryObject__c.sObjectType, 'CPQ_TestDataCountryObject');
        pw_cc__CountryObject__c countryObj = (pw_cc__CountryObject__c)countryCode[2];

           // insert account
           Account objAcc = CPQ_TestDataUtility.accountTestData(false);
           objAcc.Participant_id__c = '1378';
           insert objAcc ;

           Opportunity originalOpp = createOriginalOppTestData(objAcc.Id);

           Contract contObj = contractTestData(objAcc.Id, originalOpp.Id);
           contObj.AccountId  = objAcc.ID;
           update contObj;

           Opportunity objOpportunity = createOppTestData(objAcc.Id, originalOpp.Id);
           SBQQ__Quote__c objQuote = createQuoteTestData(objOpportunity.Id);
           List<sObject> testDataOfWireMessages = Test.loadData(CPQ_Wire_Message__c.sObjectType, 'CPQ_TestDataWireMessage');
           // Verify that all 3 test accounts were created
           //System.assert(testDataOfWireMessages.size() == 1);
           List<Order> lstOrder = [Select Id From Order];
           system.assertEquals(0,lstOrder.size());

           Order orderObj = new Order();
           orderObj.AccountID = objAcc .ID;
           orderObj.EffectiveDate = System.TODAY();
           orderObj.CurrencyIsoCode = 'USD';
           orderObj.ContractID = contObj.ID;
           orderObj.Status = 'Draft';
           orderObj.OpportunityID =objOpportunity.ID;
           orderObj.Is_Primary__c = true;
           insert  orderObj ;

           Test.startTest();
               //Id oppId,Id primaryQuoteId,Id accId,String basecurr,String l_classid
               CPQ_OrderUtility.createOrder(objOpportunity.Id,objQuote.Id,objAcc.Id,'USD');
           Test.stopTest();
           List<Order> lstOrderInserted = [Select Id,SBQQ__Quote__c,Is_Primary__c,Status,Pricebook2Id,Contract_Sign_Date__c,CreatedDate
                                           From Order
                                           Order By CreatedDate  asc];
           system.assertNotEquals(null,lstOrder);
           system.assertEquals(objQuote.ID,lstOrderInserted[0].SBQQ__Quote__c );
           system.assertEquals(false,lstOrderInserted[0].Is_Primary__c );
           system.assertEquals('Draft',lstOrderInserted[0].Status);
           system.assertEquals(Test.getStandardPricebookId(),lstOrderInserted[1].Pricebook2Id);
           system.assertEquals(Date.today(),lstOrderInserted[1].Contract_Sign_Date__c );
    }

    /**
     * Test method to check Order creation With WireMessage isCompany=false
     */
    @isTest public static void test_createOrderWithOutCompanyWireMessage() {

              List<sObject> countryCode = Test.loadData(pw_cc__CountryObject__c.sObjectType, 'CPQ_TestDataCountryObject');
              pw_cc__CountryObject__c countryObj = (pw_cc__CountryObject__c)countryCode[2];

               // insert account
               Account objAcc = new Account();
               objAcc.Name = 'TestAcc';
               objAcc.pw_cc__BillingCountryLookup__c = countryObj.ID;
               objAcc.Participant_id__c = '1234';
               insert  objAcc;

               Contact contObj = new Contact();
               contObj.LastName = 'testcontact';
               contObj.Email = 'test@testorg.com';
               insert contObj;

               Account accObject = CPQ_TestDataUtility.accountTestData(false);
               accObject.Participant_id__c = '2351';
               insert accObject;
               system.debug('Created Account: ' + accObject);

               Account_Contact__c accContactObj = new Account_Contact__c();
               accContactObj.Name = 'testing';
               accContactObj.Contact__c =contObj.ID;
               accContactObj.Participant_Account__c = objAcc.ID;
               accContactObj.Account__c=accObject.ID;
               insert accContactObj;

               Opportunity originalOpp = createOriginalOppTestData(accObject.Id);
               system.debug('Created Original Opp: ' + originalOpp);

               Contract contractObj = contractTestData(accObject.Id, originalOpp.Id);
               system.debug('Created Contract: ' + contractObj);
               //Opportunity objOpportunity = CPQ_TestDataUtility.opportunityTestData(objAcc.Id,contractObj.ID,false);
               Opportunity objOpportunity = createOppTestData(accObject.Id, originalOpp.Id);
               system.debug('Created Opp: ' + objOpportunity);
               objOpportunity.Bill_To__c = accContactObj.ID;
               update  objOpportunity;
               system.debug('Updated Opp: ' + objOpportunity);

               SBQQ__Quote__c objQuote = createQuoteTestData(objOpportunity.Id);
               system.debug('Created Quote: ' + objQuote);
               List<sObject> testDataOfWireMessages = Test.loadData(CPQ_Wire_Message__c.sObjectType, 'CPQ_TestDataWireMessage');
               // Verify that all 3 test accounts were created
               //System.assert(testDataOfWireMessages.size() == 1);
               List<Order> lstOrder = [Select Id From Order];
               system.assertEquals(0,lstOrder.size());

               Test.startTest();
                   //Id oppId,Id primaryQuoteId,Id accId,String basecurr,String l_classid
                   CPQ_OrderUtility.createOrder(objOpportunity.Id,objQuote.Id,accObject.Id,'USD');
               Test.stopTest();
               List<Order> lstOrderInserted = [Select Id,SBQQ__Quote__c,Is_Primary__c,Status,Pricebook2Id,Contract_Sign_Date__c  From Order];
           system.assertNotEquals(null,lstOrder);
           system.assertEquals(objQuote.ID,lstOrderInserted[0].SBQQ__Quote__c );
           system.assertEquals(true,lstOrderInserted[0].Is_Primary__c );
           system.assertEquals('Draft',lstOrderInserted[0].Status);
           system.assertEquals(Test.getStandardPricebookId(),lstOrderInserted[0].Pricebook2Id);
           system.assertEquals(Date.today(),lstOrderInserted[0].Contract_Sign_Date__c );

        }

        /**
         * Test method to check Order creation With Currency = EUR
         */
        @isTest public static void test_createOrderWithCurrencyEURWireMessage() {

              List<sObject> countryCode = Test.loadData(pw_cc__CountryObject__c.sObjectType, 'CPQ_TestDataCountryObject');
              pw_cc__CountryObject__c countryObj = (pw_cc__CountryObject__c)countryCode[2];

               // insert account
               Account objAcc = new Account();
               objAcc.Name = 'TestAcc';
               objAcc.pw_cc__BillingCountryLookup__c = countryObj.ID;
               objAcc.Participant_id__c = '1234';
               insert  objAcc;

               Contact contObj = new Contact();
               contObj.LastName = 'testcontact';
               contObj.Email = 'test@testorg.com';
               insert contObj;

               Account accObject = CPQ_TestDataUtility.accountTestData(true);

               Account_Contact__c accContactObj = new Account_Contact__c();
               accContactObj.Name = 'testing';
               accContactObj.Contact__c =contObj.ID;
               accContactObj.Participant_Account__c = objAcc.ID;
               accContactObj.Account__c=accObject.ID;
               insert accContactObj;

               Opportunity originalOpp = createOriginalOppTestData(objAcc.Id);

               Contract contractObj = contractTestData(objAcc.Id, originalOpp.Id);
               Opportunity objOpportunity = CPQ_TestDataUtility.opportunityTestData(objAcc.Id,contractObj.ID,false);
               objOpportunity.Bill_To__c = accContactObj.ID;
               insert  objOpportunity;

               SBQQ__Quote__c objQuote = createQuoteTestData(objOpportunity.Id);
               List<sObject> testDataOfWireMessages = Test.loadData(CPQ_Wire_Message__c.sObjectType, 'CPQ_TestDataWireMessage');
               // Verify that all 3 test accounts were created
               //System.assert(testDataOfWireMessages.size() == 1);
               List<Order> lstOrder = [Select Id From Order];
               system.assertEquals(0,lstOrder.size());

               Test.startTest();
                   //Id oppId,Id primaryQuoteId,Id accId,String basecurr,String l_classid
                   CPQ_OrderUtility.createOrder(objOpportunity.Id,objQuote.Id,objAcc.Id,'EUR');
               Test.stopTest();
               List<Order> lstOrderInserted = [Select Id,SBQQ__Quote__c,Is_Primary__c,Status,Pricebook2Id,Contract_Sign_Date__c  From Order];
           system.assertNotEquals(null,lstOrder);
           system.assertEquals(objQuote.ID,lstOrderInserted[0].SBQQ__Quote__c );
           system.assertEquals(true,lstOrderInserted[0].Is_Primary__c );
           system.assertEquals('Draft',lstOrderInserted[0].Status);
           system.assertEquals(Test.getStandardPricebookId(),lstOrderInserted[0].Pricebook2Id);
           system.assertEquals(Date.today(),lstOrderInserted[0].Contract_Sign_Date__c );
        }


}