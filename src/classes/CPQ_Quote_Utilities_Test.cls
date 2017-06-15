@isTest
private class CPQ_Quote_Utilities_Test {

  @isTest static void TestPopulateOriginalAndLastQuotes() {
    Account account = CS_TestDataUtility.createProspectAccount();
    Opportunity originalOppty = createOpportunity(account.Id, null, null, 1, false);
    SBQQ__Quote__c originalQuote = createQuote(originalOppty.Id, false);
    Contract originalContract = createContract(account.Id, originalOppty.Id);

    Opportunity renewalOppty1 = createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 2, true);
    System.debug('***renewalOppty1 '+renewalOppty1);

    SBQQ__Quote__c renewalQuote1 = createQuote(renewalOppty1.Id, true);
    System.debug('***renewalOppty1 '+renewalOppty1);

    // System.debug('***renewalQuote.SBQQ__OriginalQuote__c '+renewalQuote.SBQQ__OriginalQuote__c);
    // System.debug('***renewalQuote.CPQ_LastQuote__c '+renewalQuote.CPQ_LastQuote__c);

    Test.startTest();
    // CPQ_Quote_Utilities.populateOriginalAndLastQuotes(renewalQuote.Id);
    // System.debug('***AFTER CALLING');
    // System.debug('***renewalQuote.SBQQ__OriginalQuote__c '+renewalQuote.SBQQ__OriginalQuote__c);
    // System.debug('***renewalQuote.CPQ_LastQuote__c '+renewalQuote.CPQ_LastQuote__c);
    Test.stopTest();
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
    oppty.Deal_Type__c = 'Term';
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
    quote.SBQQ__SubscriptionTerm__c = 12;
    quote.Term_Length__c = isRenewal ? 1 : 5;
    quote.SBQQ__BillingFrequency__c = 'Quarterly';
    quote.SBQQ__Primary__c = true;
    insert quote;
    return quote;
  }

}
