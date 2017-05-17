public without sharing class CPQ_Quote_Utilities {

  /*
     bulkified method for original/last quotes population
   */
  public static void populateOriginalAndLastQuotes(List<SBQQ__Quote__c> quoteList){

    // filter out quotes based on type (Renewal)
    Set<Id> renewalQuoteIdSet = new Set<Id>();

    for(SBQQ__Quote__c quote : quoteList) {
      if(quote.SBQQ__Type__c == 'Renewal') {
        renewalQuoteIdSet.add(quote.Id);
      }
    }

    // if no Renewal type quotes, then quit
    if(renewalQuoteIdSet.size() == 0) return;

    // retrieve detailed information for quotes (associatedOppId, associatedOpp.Name, associatedOpp.TermSequence, associatedOpp.originalOppId)
    List<SBQQ__Quote__c> renewalQuoteList = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.Original_Opportunity_New__c, SBQQ__Opportunity2__r.CPQ_Term_Sequence__c FROM SBQQ__Quote__c WHERE Id IN : renewalQuoteIdSet];

    System.debug('***renewalQuoteList '+renewalQuoteList);

    /* LOGIC FOR GETTING ORIGINAL QUOTES */

    // group quotes based on their associatedOpp's originalOppId
    Map<Id, List<SBQQ__Quote__c>> originalOppIdListofQuotesMap = new Map<Id, List<SBQQ__Quote__c>>();

    for(SBQQ__Quote__c quote : renewalQuoteList) {
      Id originalOppId = (Id)quote.getsObject('SBQQ__Opportunity2__r').get('Original_Opportunity_New__c');
      System.debug('***originalOppId '+originalOppId);

      if(originalOppIdListofQuotesMap.get(originalOppId) == null) {
        List<SBQQ__Quote__c> quoteWithSameOriginOppIdList = new List<SBQQ__Quote__c>();
        quoteWithSameOriginOppIdList.add(quote);
        originalOppIdListofQuotesMap.put(originalOppId, quoteWithSameOriginOppIdList);
      }else{
        List<SBQQ__Quote__c> quoteWithSameOriginOppIdList = originalOppIdListofQuotesMap.get(originalOppId);
        quoteWithSameOriginOppIdList.add(quote);
        originalOppIdListofQuotesMap.put(originalOppId, quoteWithSameOriginOppIdList);
      }
    }

    System.debug('***originalOppIdListofQuotesMap '+originalOppIdListofQuotesMap);

    // get primary quote Id for the given set of originalOppId

    List<SBQQ__Quote__c> primaryQuotesForOriginalOppsList = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN : originalOppIdListofQuotesMap.keySet() AND SBQQ__Primary__c = true];

    System.debug('***primaryQuotesForOriginalOppsList '+primaryQuotesForOriginalOppsList);

    Map<Id, Id> originalOppIdOriginalQuoteIdMap = new Map<Id, Id>();
    for(SBQQ__Quote__c primaryQuote : primaryQuotesForOriginalOppsList) {
      originalOppIdOriginalQuoteIdMap.put(primaryQuote.SBQQ__Opportunity2__c, primaryQuote.Id);
    }

    System.debug('***originalOppIdOriginalQuoteIdMap '+originalOppIdOriginalQuoteIdMap);

    /* LOGIC FOR GETTING LAST QUOTES */

    // get all orignal opps and their associated renewal opps (with Id and TermSequence)
    List<Opportunity> originalOppList = [SELECT Id, Name, (SELECT Id, CPQ_Term_Sequence__c FROM Opportunities__r) FROM Opportunity WHERE Id IN : originalOppIdListofQuotesMap.keySet()];

    System.debug('***originalOppList '+originalOppList);

    // create the following map => parent map's key is originalOppId, child map's key is a Renewal opp's TermSequence, value is that Renewal opp's Id
    Map<Id, Map<Decimal,Id>> originalOppIdTermIdDoubleMap = new Map<Id, Map<Decimal,Id>>();
    for(Opportunity originalOpp : originalOppList) {
      Map<Decimal, Id> termIdMap = new Map<Decimal, Id>();
      List<Opportunity> renewalOppList = originalOpp.getsObjects('Opportunities__r');
      for(Opportunity renewalOpp : renewalOppList) {
        termIdMap.put(renewalOpp.CPQ_Term_Sequence__c, renewalOpp.Id);
      }
      originalOppIdTermIdDoubleMap.put(originalOpp.Id, termIdMap);
    }

    System.debug('***originalOppIdTermIdDoubleMap '+originalOppIdTermIdDoubleMap);

    // itereate all quotes in (Map<Id, List<SBQQ__Quote__c>> originalOppIdListofQuotesMap), for each quote (based on its associated opp's TermSequence), find the corresponding renewal opp (which we should use its primary quote as last quote)
    Map<Id, Id> quoteIdRenewalOppIdMap = new Map<Id, Id>();
    for(Id originalOppId : originalOppIdListofQuotesMap.keySet()) {
      System.debug('***originalOppId '+originalOppId);
      for(SBQQ__Quote__c quote : originalOppIdListofQuotesMap.get(originalOppId)) {
        Decimal termSequence = (Decimal)quote.getsObject('SBQQ__Opportunity2__r').get('CPQ_Term_Sequence__c') - 1;
        System.debug('***termSequence '+termSequence);
        quoteIdRenewalOppIdMap.put(quote.Id, originalOppIdTermIdDoubleMap.get(originalOppId).get(termSequence));
      }
    }

    System.debug('***quoteIdRenewalOppIdMap '+quoteIdRenewalOppIdMap);

    // get primary quote Id for the given set of renewalOppId

    List<SBQQ__Quote__c> primaryQuotesForRenewalOppsList = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN : quoteIdRenewalOppIdMap.values() AND SBQQ__Primary__c = true];

    System.debug('***primaryQuotesForRenewalOppsList '+primaryQuotesForRenewalOppsList);

    Map<Id, Id> renewalOppIdLastQuoteIdMap = new Map<Id, Id>();
    for(SBQQ__Quote__c primaryQuote : primaryQuotesForRenewalOppsList) {
      renewalOppIdLastQuoteIdMap.put(primaryQuote.SBQQ__Opportunity2__c, primaryQuote.Id);
    }

    System.debug('***renewalOppIdLastQuoteIdMap '+renewalOppIdLastQuoteIdMap);

    /* UPDATE QUOTES */
    List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c>();
    for(Id originalOppId : originalOppIdListofQuotesMap.keySet()) {
      System.debug('***originalOppId '+originalOppId);
      for(SBQQ__Quote__c quote : originalOppIdListofQuotesMap.get(originalOppId)) {
        // set the original quote
        quote.SBQQ__OriginalQuote__c = originalOppIdOriginalQuoteIdMap.get(originalOppId);

        // set the last quote (if the target term seqeunce is 1, then the last quote is same as original quote)
        Decimal termSequence = (Decimal)quote.getsObject('SBQQ__Opportunity2__r').get('CPQ_Term_Sequence__c') - 1;
        if(termSequence == 1) {
          quote.CPQ_LastQuote__c = originalOppIdOriginalQuoteIdMap.get(originalOppId);
        }else{
          quote.CPQ_LastQuote__c = renewalOppIdLastQuoteIdMap.get(quoteIdRenewalOppIdMap.get(quote.Id));
        }

        updateQuoteList.add(quote);
      }
    }

    if(updateQuoteList.size() > 0 && !Test.isRunningTest()) {
      update updateQuoteList;
    }

    return;
  }
}
