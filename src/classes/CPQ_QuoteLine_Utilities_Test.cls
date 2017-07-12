@isTest
public class CPQ_QuoteLine_Utilities_Test {

  @isTest static void TestTrigger() {
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
  }

  @isTest static void populateBaseLineInfo_processFirstTimeSet() {
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

    CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote.Id);
    SBQQ__Quote__c verifyQuote1 = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote.Id];
    System.assertEquals(verifyQuote1.CPQ_Baseline_Current_Year_Reference__c, 2);
    System.assertEquals(verifyQuote1.CPQ_Baseline_Last_Year_Reference__c, 1);

    // update original quote's term length to 1 in order to test the else part of processFirstTimeSet() method
    originalQuote.Term_Length__c = 1;
    update originalQuote;

    CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote.Id);
    SBQQ__Quote__c verifyQuote2 = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote.Id];
    System.assertEquals(verifyQuote2.CPQ_Baseline_Current_Year_Reference__c, 1);
    System.assertEquals(verifyQuote2.CPQ_Baseline_Last_Year_Reference__c, 1);

    Test.stopTest();
  }

  @isTest static void populateBaseLineInfo_processNonFirstTimeSet() {
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

    // create a dummy quote which would be used as last quote so processNonFirstTimeSet() would be run
    SBQQ__Quote__c dummyLastQuote = CPQ_Quote_Utilities_Test.createQuote(originalOppty.Id, false);

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
    // add quotelineitems for dummy quote
    quoteLineList.add(createQuoteLineItem(product1.Id, dummyLastQuote.Id));
    quoteLineList.add(createQuoteLineItem(product2.Id, dummyLastQuote.Id));
    insert quoteLineList;

    Test.startTest();
    dummyLastQuote.CPQ_Baseline_Current_Year_Reference__c = 2;
    update dummyLastQuote;

    originalQuote.SBQQ__Primary__c = true;
    update originalQuote;

    renewalQuote.SBQQ__Primary__c = true;
    renewalQuote.SBQQ__OriginalQuote__c = originalQuote.Id;
    renewalQuote.CPQ_LastQuote__c = dummyLastQuote.Id;
    update renewalQuote;

    CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote.Id);
    SBQQ__Quote__c verifyQuote2 = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote.Id];
    System.assertEquals(verifyQuote2.CPQ_Baseline_Current_Year_Reference__c, 3);
    System.assertEquals(verifyQuote2.CPQ_Baseline_Last_Year_Reference__c, 2);

    // update original quote's term length to 1 in order to test the if part of processNonFirstTimeSet() method
    originalQuote.Term_Length__c = 1;
    update originalQuote;

    // reset renewalQuote
    renewalQuote.CPQ_Baseline_Current_Year_Reference__c = null;
    renewalQuote.CPQ_Baseline_Last_Year_Reference__c = null;
    update renewalQuote;

    CPQ_QuoteLine_Utilities.populateBaseLineInfo(renewalQuote.Id);
    SBQQ__Quote__c verifyQuote3 = [SELECT Id, CPQ_Baseline_Current_Year_Reference__c, CPQ_Baseline_Last_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote.Id];
    System.assertEquals(verifyQuote3.CPQ_Baseline_Current_Year_Reference__c, null);
    System.assertEquals(verifyQuote3.CPQ_Baseline_Last_Year_Reference__c, 2);

    Test.stopTest();
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
