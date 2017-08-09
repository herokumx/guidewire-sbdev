@isTest
private class CPQ_Quote_TriggerHandlerTest {

	@isTest static void test_method_one() {
		// Implement test code
	}

	@isTest static void test_InsertQuote() {
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

		System.Test.stopTest();
	}

	@isTest static void test_UpdateQuote() {
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

		   SBQQ__Quote__c queryQuote = [SELECT Id,SBQQ__BillingFrequency__c FROM SBQQ__Quote__c WHERE SBQQ__BillingFrequency__c = 'Semiannual'];
		   queryQuote.SBQQ__BillingFrequency__c = 'Monthly';
		   update queryQuote;

		System.Test.stopTest();
	}

	@isTest static void test_DeleteQuote() {
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

		   SBQQ__Quote__c queryQuote = [SELECT Id,SBQQ__BillingFrequency__c FROM SBQQ__Quote__c WHERE SBQQ__BillingFrequency__c = 'Semiannual'];
		   delete queryQuote;


		System.Test.stopTest();
	}

}