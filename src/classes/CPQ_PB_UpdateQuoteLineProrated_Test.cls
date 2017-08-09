@isTest
private class CPQ_PB_UpdateQuoteLineProrated_Test {

  @isTest static void testUpdateProratedLicense() {

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

    Id pricebookId = Test.getStandardPricebookId();
    Product2 product1 = CPQ_QuoteLine_Utilities_Test.createProduct('Billing Center License', 'License');
    PricebookEntry pbEntry1 = CPQ_QuoteLine_Utilities_Test.createPbEntry(product1.Id, pricebookId);
    Product2 product2 = CPQ_QuoteLine_Utilities_Test.createProduct('Maintenance - Standard', 'Maintenance');
    PricebookEntry pbEntry2 = CPQ_QuoteLine_Utilities_Test.createPbEntry(product2.Id, pricebookId);

    List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
    quoteLineList.add(CPQ_QuoteLine_Utilities_Test.createQuoteLineItem(product1.Id, originalQuote.Id));
    quoteLineList.add(CPQ_QuoteLine_Utilities_Test.createQuoteLineItem(product2.Id, originalQuote.Id));
    quoteLineList.add(CPQ_QuoteLine_Utilities_Test.createQuoteLineItem(product1.Id, originalQuote.Id));
    quoteLineList.add(CPQ_QuoteLine_Utilities_Test.createQuoteLineItem(product2.Id, originalQuote.Id));
    insert quoteLineList;

    Test.startTest();
    List<Id> quoteIds = new List<Id>();
    quoteIds.add(originalQuote.Id);
    CPQ_PB_UpdateQuoteLineProratedLicense.updateProratedLicense(quoteIds);
    Test.stopTest();
  }

}