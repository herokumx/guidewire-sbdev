public without sharing class CPQ_Quote_Utilities {

  /*
     populate original/last quotes
   */
  public static void populateOriginalAndLastQuotes(Id quoteId){

    // retrieve detailed information for quote (associatedOppId, associatedOpp.Name, associatedOpp.TermSequence, associatedOpp.originalOppId)
    SBQQ__Quote__c renewalQuote = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.Original_Opportunity_New__c, SBQQ__Opportunity2__r.CPQ_Term_Sequence__c FROM SBQQ__Quote__c WHERE Id = : quoteId];

    System.debug('***renewalQuote '+renewalQuote);

    /* LOGIC FOR GETTING ORIGINAL QUOTES */

    // get renewalQuote's associatedOpp's originalOppId
    Id originalOppId = (Id)renewalQuote.getsObject('SBQQ__Opportunity2__r').get('Original_Opportunity_New__c');
    System.debug('***originalOppId '+originalOppId);

    // get primary quote Id for the given originalOppId
    SBQQ__Quote__c primaryQuoteForOriginalOpp = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = : originalOppId AND SBQQ__Primary__c = true];
    System.debug('***primaryQuoteForOriginalOpp '+primaryQuoteForOriginalOpp);


    /* LOGIC FOR GETTING LAST QUOTES */

    // get orignal opp with its associated renewal opps (with Id and TermSequence)
    Opportunity originalOppWithRenewalOpps = [SELECT Id, Name, (SELECT Id, CPQ_Term_Sequence__c FROM Opportunities__r) FROM Opportunity WHERE Id = : originalOppId];
    System.debug('***originalOppWithRenewalOpps '+originalOppWithRenewalOpps);

    // create the following map => key is a Renewal opp's TermSequence, value is that Renewal opp's Id
    Map<Decimal, Id> termIdMap = new Map<Decimal, Id>();
    List<Opportunity> renewalOppList = originalOppWithRenewalOpps.getsObjects('Opportunities__r');
    for(Opportunity renewalOpp : renewalOppList) {
      termIdMap.put(renewalOpp.CPQ_Term_Sequence__c, renewalOpp.Id);
    }
    System.debug('***termIdMap '+termIdMap);

    // based on renewalQuote's associated opp's TermSequence, find the corresponding renewal opp (whose primary quote will be used as last quote)
    Decimal termSequence = (Decimal)renewalQuote.getsObject('SBQQ__Opportunity2__r').get('CPQ_Term_Sequence__c') - 1;
    Id renewalOppId = termIdMap.get(termSequence);
    System.debug('***termSequence '+termSequence);
    System.debug('***renewalOppId '+renewalOppId);

    // get primary quote Id for the given renewalOppId (if the target term seqeunce is 1, then the last quote is same as original quote)
    SBQQ__Quote__c primaryQuoteForRenewalOpp = (termSequence == 1) ? primaryQuoteForOriginalOpp : [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = : renewalOppId AND SBQQ__Primary__c = true];
    System.debug('***primaryQuoteForRenewalOpp '+primaryQuoteForRenewalOpp);

    /* UPDATE QUOTES */

    // set the original quote
    renewalQuote.SBQQ__OriginalQuote__c = primaryQuoteForOriginalOpp.Id;

    // set the last quote
    renewalQuote.CPQ_LastQuote__c = primaryQuoteForRenewalOpp.Id;

    update renewalQuote;

    return;
  }
}
