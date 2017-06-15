@isTest
public class CPQ_Quote_Utilities_Test {

  @isTest static void TestPopulateOriginalAndLastQuotes() {

    Account account = CS_TestDataUtility.createProspectAccount();

    Opportunity originalOppty = createOpportunity(account.Id, null, null, 1, false);
    SBQQ__Quote__c originalQuote = createQuote(originalOppty.Id, false);
    originalQuote.SBQQ__Primary__c = true;
    update originalQuote;

    Contract originalContract = createContract(account.Id, originalOppty.Id);
    Opportunity renewalOppty1 = createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 2, true);
    SBQQ__Quote__c renewalQuote1 = createQuote(renewalOppty1.Id, true);
    renewalQuote1.SBQQ__Primary__c = true;
    update renewalQuote1;

    Test.startTest();
    CPQ_Quote_Utilities.populateOriginalAndLastQuotes(renewalQuote1.Id);
    SBQQ__Quote__c renewalQuote1_verify = [SELECT Id, SBQQ__OriginalQuote__c, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote1.Id];
    System.assertEquals(renewalQuote1_verify.SBQQ__OriginalQuote__c, originalQuote.Id);
    System.assertEquals(renewalQuote1_verify.CPQ_LastQuote__c, originalQuote.Id);

    Contract renewalContract1 = createContract(account.Id, renewalOppty1.Id);
    Opportunity renewalOppty2 = createOpportunity(account.Id, originalOppty.Id, renewalContract1.Id, 3, true);
    SBQQ__Quote__c renewalQuote2 = createQuote(renewalOppty2.Id, true);
    renewalQuote2.SBQQ__Primary__c = true;
    update renewalQuote2;

    CPQ_Quote_Utilities.populateOriginalAndLastQuotes(renewalQuote2.Id);
    SBQQ__Quote__c renewalQuote2_verify = [SELECT Id, SBQQ__OriginalQuote__c, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: renewalQuote2.Id];
    System.assertEquals(renewalQuote2_verify.SBQQ__OriginalQuote__c, originalQuote.Id);
    System.assertEquals(renewalQuote2_verify.CPQ_LastQuote__c, renewalQuote1.Id);

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
    quote.SBQQ__BillingFrequency__c = 'Quarterly';
    quote.SBQQ__SubscriptionTerm__c = 12;
    quote.Term_Length__c = isRenewal ? 1 : 5;
    quote.SBQQ__Primary__c = false;
    insert quote;
    return quote;
  }

}
