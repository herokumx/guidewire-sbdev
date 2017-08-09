@isTest
private class CPQ_FX_DWP_Calc_HelperTest {

  @testSetup static void test_EnableTriggerExecutionByCustomSetting(){
    CS_ByPass__c byPassValidationAndTrigger = new CS_ByPass__c();
    byPassValidationAndTrigger.CS_Disable_Trigger__c = false;
    byPassValidationAndTrigger.CS_Disable_ValidationRule__c = true;
    byPassValidationAndTrigger.CS_Batch_Context__c = true;
    byPassValidationAndTrigger.CS_Disable_WF_Rules__c = true;
    byPassValidationAndTrigger.SetupOwnerId = UserInfo.getUserId();
    insert byPassValidationAndTrigger;
  }

  @istest static void test_ToCallRunOnce(){

    CPQ_FX_DWP_Calc_Helper.runOnce();

  }

  @isTest static void test_QuoteInsert() {

    System.Test.startTest();

    Account accObj = CPQ_TestDataUtility.accountTestData(true);

    ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

    Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

    Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

    Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

    SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppWithContract1.Id, false);

    Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
    oppWithContract.Service_Contract__c = serviceContrObj.Id;
    oppWithContract.SBQQ__PrimaryQuote__c = quoteObj1.Id;
    //oppWithContract.CurrencyIsoCode = 'USD';
    insert oppWithContract;

    Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
    prod2Obj.SKU_ID__c = 'L-23001';
    insert prod2Obj;

    PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
    Id pricebookId = Test.getStandardPricebookId();

    SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
    quoteObj.SBQQ__StartDate__c = Date.today();
    quoteObj.SBQQ__EndDate__c = Date.today();
    quoteObj.SBQQ__PaymentTerms__c = 'NET15';
    quoteObj.SBQQ__SubscriptionTerm__c = 6;
    quoteObj.SBQQ__BillingFrequency__c  = 'Semiannual';
    quoteObj.SBQQ__Opportunity2__c  = oppWithContract.Id;
    quoteObj.SBQQ__Primary__c = true;
    quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
    insert quoteObj;

    System.Test.stopTest();

    SBQQ__Quote__c queryQuote = [SELECT Id,CPQ_Quote_Currency_to_USD_Conversion__c, CPQ_USD_to_Quote_Currency_Conversion__c,
                                 CPQ_Quote_Created_Currency_to_USD__c,CPQ_Quote_Created_USD_to_Currency__c FROM SBQQ__Quote__c
                                 WHERE SBQQ__BillingFrequency__c = 'SemiAnnual' LIMIT 1];
    System.assertEquals(1,queryQuote.CPQ_Quote_Currency_to_USD_Conversion__c);
    System.assertEquals(1,queryQuote.CPQ_USD_to_Quote_Currency_Conversion__c);
    System.assertEquals(1,queryQuote.CPQ_Quote_Created_Currency_to_USD__c);
    System.assertEquals(1,queryQuote.CPQ_Quote_Created_USD_to_Currency__c);


  }

  @isTest static void test_QuoteUpdate() {
    // Implement test code

    System.Test.startTest();

    Account accObj = CPQ_TestDataUtility.accountTestData(true);

    ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

    Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

    Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

    Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

    SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppWithContract1.Id, false);

    Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
    oppWithContract.Service_Contract__c = serviceContrObj.Id;
    oppWithContract.SBQQ__PrimaryQuote__c = quoteObj1.Id;
    oppWithContract.CurrencyIsoCode = 'EUR';
    insert oppWithContract;

    Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
    prod2Obj.SKU_ID__c = 'L-23001';
    insert prod2Obj;

    PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
    Id pricebookId = Test.getStandardPricebookId();

    SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
    quoteObj.SBQQ__StartDate__c = Date.today();
    quoteObj.SBQQ__EndDate__c = Date.today();
    quoteObj.SBQQ__PaymentTerms__c = 'NET15';
    quoteObj.SBQQ__SubscriptionTerm__c = 6;
    quoteObj.SBQQ__BillingFrequency__c  = 'Semiannual';
    quoteObj.SBQQ__Opportunity2__c  = oppWithContract.Id;
    quoteObj.SBQQ__Primary__c = true;
    quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
    insert quoteObj;

    SBQQ__Quote__c queryQuote = [SELECT Id,SBQQ__BillingFrequency__c FROM SBQQ__Quote__c LIMIT 1];
    queryQuote.SBQQ__BillingFrequency__c = 'Monthly';
    update queryQuote;

    System.Test.stopTest();

    SBQQ__Quote__c queryUpdatedQuote = [SELECT Id,CPQ_Quote_Currency_to_USD_Conversion__c, CPQ_USD_to_Quote_Currency_Conversion__c,
                                        CPQ_Quote_Created_Currency_to_USD__c,CPQ_Quote_Created_USD_to_Currency__c FROM SBQQ__Quote__c
                                        WHERE SBQQ__BillingFrequency__c = 'Monthly' LIMIT 1];
    System.assertEquals(1,Integer.valueOf(queryUpdatedQuote.CPQ_Quote_Currency_to_USD_Conversion__c));

  }


  @isTest static void test_ToCallUpdateFX() {
    // Implement test code

    System.Test.startTest();

    Account accObj = CPQ_TestDataUtility.accountTestData(true);

    ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

    Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

    Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

    Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

    SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppWithContract1.Id, false);

    Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
    oppWithContract.Service_Contract__c = serviceContrObj.Id;
    oppWithContract.SBQQ__PrimaryQuote__c = quoteObj1.Id;

    insert oppWithContract;

    Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
    prod2Obj.SKU_ID__c = 'L-23001';
    insert prod2Obj;

    PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
    Id pricebookId = Test.getStandardPricebookId();

    SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
    quoteObj.SBQQ__StartDate__c = Date.today();
    quoteObj.SBQQ__EndDate__c = Date.today();
    quoteObj.SBQQ__PaymentTerms__c = 'NET15';
    quoteObj.SBQQ__SubscriptionTerm__c = 6;
    quoteObj.SBQQ__BillingFrequency__c  = 'Semiannual';
    quoteObj.SBQQ__Opportunity2__c  = oppWithContract.Id;
    quoteObj.SBQQ__Primary__c = true;
    quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
    insert quoteObj;

    // CPQ_FX_DWP_Calc_Helper helperInst = new CPQ_FX_DWP_Calc_Helper(true,2);
    CPQ_FX_DWP_Calc_Helper.UpdateFX(quoteObj);

    System.Test.stopTest();

  }

  @isTest static void test_ToCallOpportunityUpdate() {
    // Implement test code

    System.Test.startTest();

    Account accObj = CPQ_TestDataUtility.accountTestData(true);

    ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

    Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
    insert oppObj;

    Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

    SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
    quoteObj1.SBQQ__StartDate__c = Date.today();
    quoteObj1.SBQQ__PaymentTerms__c = 'NET15';
    quoteObj1.SBQQ__SubscriptionTerm__c = 6;
    quoteObj1.SBQQ__BillingFrequency__c  = 'Semiannual';
    insert quoteObj1;

    Opportunity queryOpportunity1 = [SELECT Id,StageName FROM Opportunity WHERE Name = 'Test Opportunity2' LIMIT 1];
    queryOpportunity1.SBQQ__PrimaryQuote__c = quoteObj1.Id;
    queryOpportunity1.SBQQ__RenewedContract__c = contractObj.Id;
    queryOpportunity1.StageName = 'Closed - Won';
    queryOpportunity1.Deal_Type__c = 'Perpetual';
    queryOpportunity1.SBQQ__Contracted__c = true;
    update queryOpportunity1;

    System.Test.stopTest();

  }

  @isTest static void test_ToCallOpportunityUpdateWithCurrencyEur() {
    // Implement test code

    System.Test.startTest();

    Account accObj = CPQ_TestDataUtility.accountTestData(true);

    ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

    Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
    oppObj.CurrencyIsoCode = 'EUR';
    insert oppObj;

    Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

    SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
    quoteObj1.SBQQ__StartDate__c = Date.today();
    quoteObj1.SBQQ__PaymentTerms__c = 'NET15';
    quoteObj1.SBQQ__SubscriptionTerm__c = 6;
    quoteObj1.SBQQ__BillingFrequency__c  = 'Semiannual';
    insert quoteObj1;

    Opportunity queryOpportunity1 = [SELECT Id,StageName FROM Opportunity WHERE Name = 'Test Opportunity2' LIMIT 1];
    queryOpportunity1.SBQQ__PrimaryQuote__c = quoteObj1.Id;
    queryOpportunity1.SBQQ__RenewedContract__c = contractObj.Id;
    queryOpportunity1.StageName = 'Closed - Won';
    queryOpportunity1.Deal_Type__c = 'Perpetual';
    queryOpportunity1.SBQQ__Contracted__c = true;

    update queryOpportunity1;

    System.Test.stopTest();

  }


}
