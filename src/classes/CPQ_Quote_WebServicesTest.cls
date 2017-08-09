@isTest
private class CPQ_Quote_WebServicesTest {

    @isTest static void test_QuoteWebServices() {

      CS_ByPass__c byPassValidationAndTrigger = new CS_ByPass__c();
      byPassValidationAndTrigger.CS_Disable_Trigger__c = true;
      byPassValidationAndTrigger.CS_Disable_ValidationRule__c = true;
      byPassValidationAndTrigger.CS_Batch_Context__c = true;
      byPassValidationAndTrigger.CS_Disable_WF_Rules__c = true;
      byPassValidationAndTrigger.SetupOwnerId = UserInfo.getUserId();
      insert byPassValidationAndTrigger;

      Account account = CS_TestDataUtility.createProspectAccount();

      Opportunity originalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, null, null, 1, false);
      SBQQ__Quote__c originalQuote = CPQ_Quote_Utilities_Test.createQuote(originalOppty.Id, false);

      Contract originalContract = CPQ_Quote_Utilities_Test.createContract(account.Id, originalOppty.Id);
      Opportunity renewalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 2, true);
      SBQQ__Quote__c renewalQuote = CPQ_Quote_Utilities_Test.createQuote(renewalOppty.Id, true);

      Id pricebookId = Test.getStandardPricebookId();
      Product2 product1 = createProduct('Billing Center License', 'License');
      PricebookEntry pbEntry1 = createPbEntry(product1.Id, pricebookId);
      Product2 product2 = createProduct('Maintenance - Standard', 'Maintenance');
      PricebookEntry pbEntry2 = createPbEntry(product2.Id, pricebookId);

      List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
      quoteLineList.add(createQuoteLineItem(product1.Id, originalQuote.Id));
      quoteLineList.add(createQuoteLineItem(product2.Id, originalQuote.Id));
      quoteLineList.add(createQuoteLineItem(product1.Id, renewalQuote.Id));
      quoteLineList.add(createQuoteLineItem(product2.Id, renewalQuote.Id));
      insert quoteLineList;

      Test.startTest();
      originalQuote.SBQQ__Primary__c = true;
      update originalQuote;

      renewalQuote.SBQQ__Primary__c = true;
      renewalQuote.SBQQ__OriginalQuote__c = originalQuote.Id;
      renewalQuote.CPQ_LastQuote__c = originalQuote.Id;
      update renewalQuote;

      // update original quote's term length to 1 in order to test the else part of processFirstTimeSet() method
      originalQuote.Term_Length__c = 1;
      update originalQuote;

      CPQ_Quote_WebServices.processQuote(renewalQuote.Id);
      
      SBQQ__Quote__c renewalQuote2_verify = [SELECT Id, SBQQ__OriginalQuote__c, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote.Id];
      System.assertEquals(renewalQuote2_verify.SBQQ__OriginalQuote__c, originalQuote.Id);

    }

    public static Opportunity createOpportunity(Id accountId, Id originalOpptyId, Id contractId, Integer termSequence, Boolean isRenewal) {
      Opportunity oppty = new Opportunity();
      oppty.AccountId = accountId;
      oppty.Name = isRenewal ? 'Renewal Opportunity' : 'Initial Opportunity';
      oppty.Region__c = 'AMER';
      oppty.Opportunity_Type__c = 'Net New';
      oppty.CloseDate = Date.Today();
      oppty.StageName = 'Qualified';
      oppty.CPQ_Term_Sequence__c = termSequence;
      // oppty.Deal_Type__c = 'Term';
      oppty.CurrencyIsoCode = 'USD';
      oppty.SBQQ__Renewal__c = isRenewal;
      oppty.Original_Opportunity_New__c = isRenewal ? originalOpptyId : null;
      oppty.SBQQ__RenewedContract__c = isRenewal ? contractId : null;
      insert oppty;
      return oppty;
    }

    public static Contract createContract(Id accountId, Id opptyId) {
      Contract contract = new Contract();
      contract.AccountId = accountId;
      contract.Status = 'Draft';
      contract.CurrencyIsoCode = 'USD';
      contract.SBQQ__Opportunity__c = opptyId;
      insert contract;
      return contract;
    }

    public static SBQQ__Quote__c createQuote(Id opptyId, Boolean isRenewal) {
      SBQQ__Quote__c quote = new SBQQ__Quote__c();
      quote.SBQQ__Opportunity2__c = opptyId;
      quote.SBQQ__Type__c = isRenewal ? 'Renewal' : 'Quote';
      quote.CPQ_In_Scope_DWP_Input__c = 500000000;
      quote.CPQ_In_Scope_DWP_Input_Type__c = 'Direct DWP';
      quote.SBQQ__StartDate__c = Date.Today();
      quote.SBQQ__BillingFrequency__c = 'Quarterly';
      quote.SBQQ__SubscriptionTerm__c = 12;
      quote.Term_Length__c = isRenewal ? 1 : 5;
      quote.SBQQ__Primary__c = false;
      insert quote;
      return quote;
    }

    public static Product2 createProduct(String productName, String skuType) {
      Product2 product = new Product2();
      product.Name = productName;
      product.Sku_Type__c = skuType;
      product.IsActive = true;
      product.SBQQ__SubscriptionPercent__c = 15;
      insert product;
      return product;
    }

    public static PricebookEntry createPbEntry(Id product2Id, Id pricebookId) {
      PricebookEntry pbEntry = new PricebookEntry();
      pbEntry.Pricebook2Id = pricebookId;
      pbEntry.Product2Id = product2Id;
      pbEntry.UnitPrice = 100.00;
      pbEntry.IsActive = true;
      insert pbEntry;
      return pbEntry;
    }

    public static SBQQ__QuoteLine__c createQuoteLineItem(Id productId, Id quoteId) {
      SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c();
      quoteLineItem.SBQQ__Quote__c = quoteId;
      quoteLineItem.SBQQ__Product__c = productId;
      return quoteLineItem;
    }
}