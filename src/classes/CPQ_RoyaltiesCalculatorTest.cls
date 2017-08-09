@isTest
private class CPQ_RoyaltiesCalculatorTest {

	@isTest static void test_WithQuoteRecords() {
		Account accObj = CPQ_TestDataUtility.accountTestData(true);

		ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);
        /*oppObj.Original_Opportunity_New__c = opportunityId;
        insert oppObj;*/

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

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, true);

		Map<Id, SBQQ__Quote__c> mapId_QuoteRecord = new Map<Id, SBQQ__Quote__c>();
		mapId_QuoteRecord.put(quoteObj.Id,quoteObj);

		CPQ_RoyaltiesCalculator.calculateRoyalties(mapId_QuoteRecord);

         SBQQ__Quote__c quoteObject = [Select Id,CPQ_Royalties__c From SBQQ__Quote__c];
		 System.assertEquals(true,quoteObject.CPQ_Royalties__c);
	}

	@isTest static void test_WithoutQuoteRecords() {
		Account accObj = CPQ_TestDataUtility.accountTestData(true);

		ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);
        /*oppObj.Original_Opportunity_New__c = opportunityId;
        insert oppObj;*/

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

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, true);

		Map<Id, SBQQ__Quote__c> mapId_QuoteRecord = new Map<Id, SBQQ__Quote__c>();
		//mapId_QuoteRecord.put(quoteObj.Id,quoteObj);

		CPQ_RoyaltiesCalculator.calculateRoyalties(mapId_QuoteRecord);

		SBQQ__Quote__c quoteObject = [Select Id,CPQ_Royalties__c From SBQQ__Quote__c];
		System.assertEquals(true,quoteObject.CPQ_Royalties__c);

	}

}