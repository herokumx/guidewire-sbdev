@isTest
private class CPQ_QuoteLine_Utilities_Test {

  @isTest static void testPopulateBaseLineInfo() {
    Account account = CS_TestDataUtility.createProspectAccount();

    Opportunity originalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, null, null, 1, false);
    SBQQ__Quote__c originalQuote = CPQ_Quote_Utilities_Test.createQuote(originalOppty.Id, false);

    Contract originalContract = CPQ_Quote_Utilities_Test.createContract(account.Id, originalOppty.Id);
    Opportunity renewalOppty1 = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 2, true);
    SBQQ__Quote__c renewalQuote1 = CPQ_Quote_Utilities_Test.createQuote(renewalOppty1.Id, true);

    Id pricebookId = Test.getStandardPricebookId();
    Product2 product1 = createProduct('Billing Center License', 'License');
    PricebookEntry pbEntry1 = createPbEntry(product1.Id, pricebookId);
    Product2 product2 = createProduct('Maintenance - Standard', 'Maintenance');
    PricebookEntry pbEntry2 = createPbEntry(product2.Id, pricebookId);

    List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
    quoteLineList.add(createQuoteLineItem(product1.Id, originalQuote.Id));
    quoteLineList.add(createQuoteLineItem(product2.Id, originalQuote.Id));
    quoteLineList.add(createQuoteLineItem(product1.Id, renewalQuote1.Id));
    quoteLineList.add(createQuoteLineItem(product2.Id, renewalQuote1.Id));
    insert quoteLineList;

    Test.startTest();
    originalQuote.SBQQ__Primary__c = true;
    update originalQuote;

    renewalQuote1.SBQQ__Primary__c = true;
    renewalQuote1.SBQQ__OriginalQuote__c = originalQuote.Id;
    renewalQuote1.CPQ_LastQuote__c = originalQuote.Id;
    update renewalQuote1;

    CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote1.Id);
    SBQQ__Quote__c renewalQuote1_verify = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote1.Id];
    System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Current_Year_Reference__c, 2);
    System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Last_Year_Reference__c, 1);

    // SBQQ__Quote__c dummyLastQuote = CPQ_Quote_Utilities_Test.createQuote(originalOppty.Id, false);
    // renewalQuote1.CPQ_LastQuote__c = originalQuote.Id;
    // update renewalQuote1;
    // update original quote's term length to 1 in order to test the else part of processFirstTimeSet() method
    // originalQuote.Term_Length__c = 1;
    // update originalQuote;
    //
    // CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote1.Id);
    // renewalQuote1_verify = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote1.Id];
    // System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Current_Year_Reference__c, 1);
    // System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Last_Year_Reference__c, 1);

    Test.stopTest();
  }

  // @isTest static void testProcessFirstTimeSet() {
  //   Account account = CS_TestDataUtility.createProspectAccount();
  //
  //   Opportunity originalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, null, null, 1, false);
  //   SBQQ__Quote__c originalQuote = CPQ_Quote_Utilities_Test.createQuote(originalOppty.Id, false);
  //
  //   Contract originalContract = CPQ_Quote_Utilities_Test.createContract(account.Id, originalOppty.Id);
  //   Opportunity renewalOppty1 = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 2, true);
  //   SBQQ__Quote__c renewalQuote1 = CPQ_Quote_Utilities_Test.createQuote(renewalOppty1.Id, true);
  //
  //   Id pricebookId = Test.getStandardPricebookId();
  //   Product2 product1 = createProduct('Billing Center License', 'License');
  //   PricebookEntry pbEntry1 = createPbEntry(product1.Id, pricebookId);
  //   Product2 product2 = createProduct('Maintenance - Standard', 'Maintenance');
  //   PricebookEntry pbEntry2 = createPbEntry(product2.Id, pricebookId);
  //
  //   List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
  //   quoteLineList.add(createQuoteLineItem(product1.Id, originalQuote.Id));
  //   quoteLineList.add(createQuoteLineItem(product2.Id, originalQuote.Id));
  //   quoteLineList.add(createQuoteLineItem(product1.Id, renewalQuote1.Id));
  //   quoteLineList.add(createQuoteLineItem(product2.Id, renewalQuote1.Id));
  //   insert quoteLineList;
  //
  //   Test.startTest();
  //    originalQuote.Term_Length__c = 1;
  //   update originalQuote;
  //
  //   renewalQuote1.SBQQ__OriginalQuote__c = originalQuote.Id;
  //   renewalQuote1.CPQ_LastQuote__c = originalQuote.Id;
  //   update renewalQuote1;
  //
  //   CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote1.Id);
  //   SBQQ__Quote__c renewalQuote1_verify = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote1.Id];
  //   System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Current_Year_Reference__c, 2);
  //   System.assertEquals(renewalQuote1_verify.CPQ_Baseline_Last_Year_Reference__c, 1);
  //
  //   Test.stopTest();
  // }

  public static Product2 createProduct(String productName, String skuType) {
    Product2 product = new Product2();
    product.Name = productName;
    product.Sku_Type__c = skuType;
    product.IsActive = true;
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
