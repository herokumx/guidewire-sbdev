public without sharing class CPQ_QuoteLine_Utilities {

  private static Boolean alreadyRunPopulateBaselineInfo = false;
  private static Boolean alreadySyncSupportPercent = false;

  /*
     bulkified method for populate baseline information
   */
  public static void populateBaseLineInfo(List<SBQQ__QuoteLine__c> quoteLineList){

    if(CPQ_QuoteLine_Utilities.alreadyRunPopulateBaselineInfo) return;
    CPQ_QuoteLine_Utilities.alreadyRunPopulateBaselineInfo = true;

    /*
       Quote:
        CPQ_Baseline_Current_Year_Reference__c (Number)
        CPQ_Baseline_Last_Year_Reference__c (Number)

       QuoteLine:
        CPQ_Baseline_Current_Year_License__c (Currency)
        CPQ_Baseline_Last_Year_License__c (Currency)
     */

    // group quotelines based on their associated quotes
    Map<Id, List<SBQQ__QuoteLine__c>> quoteIdQLIListMap = new Map<Id, List<SBQQ__QuoteLine__c>>();

    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      if(quoteIdQLIListMap.get(quoteline.SBQQ__Quote__c) == null) {
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        qliList.add(quoteline);
        quoteIdQLIListMap.put(quoteline.SBQQ__Quote__c, qliList);
      }else{
        List<SBQQ__QuoteLine__c> qliList = quoteIdQLIListMap.get(quoteline.SBQQ__Quote__c);
        qliList.add(quoteline);
        quoteIdQLIListMap.put(quoteline.SBQQ__Quote__c, qliList);
      }
    }
    System.debug('***quoteId Set '+quoteIdQLIListMap.keySet());
    System.debug('***quoteIdQLIList Map '+quoteIdQLIListMap);

    // retrieve quotes detailed info
    Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([SELECT SBQQ__Type__c, SBQQ__OriginalQuote__c, CPQ_LastQuote__c, SBQQ__OriginalQuote__r.Term_Length__c, SBQQ__OriginalQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.Term_Length__c, CPQ_LastQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.CPQ_Baseline_Current_Year_Reference__c FROM SBQQ__Quote__c WHERE Id IN:quoteIdQLIListMap.keySet()]);
    System.debug('***quoteMap '+quoteMap);

    Set<Id> firstTimeSet = new Set<Id>();
    Set<Id> nonFirstTimeSet = new Set<Id>();
    Set<Id> originalQuoteIdSet = new Set<Id>();
    Set<Id> lastQuoteIdSet = new Set<Id>();

    /*
       1. filter out non renewal type quotes, and categorize the remaining qutoes into 2 sets based on whether their original quote = last quote
       2. collect all orginal quote Ids, which will be used to retrieve corresponding QLIs with CPQ_Year_1_Net_Amount__c - CPQ_Year_5_Net_Amount__c (to calculate baseline license)
       3. collect all last quote Ids, which will be used to retrieve corresponding QLIs with CPQ_Annual_Net_Amount__c (to calculate baseline license)
     */
    for(SBQQ__Quote__c quote : quoteMap.values()) {
      if(quote.SBQQ__Type__c != 'Renewal') {
        quoteIdQLIListMap.remove(quote.Id);
      }else{
        originalQuoteIdSet.add(quote.SBQQ__OriginalQuote__c);
        lastQuoteIdSet.add(quote.CPQ_LastQuote__c);
        if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c) {
          firstTimeSet.add(quote.Id);
        }else{
          nonFirstTimeSet.add(quote.Id);
        }
      }
    }

    // retrieve quotelines for all original quotes
    List<SBQQ__QuoteLine__c> quoteLineListForQriginalQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Year_1_Net_Amount__c, CPQ_Year_2_Net_Amount__c, CPQ_Year_3_Net_Amount__c, CPQ_Year_4_Net_Amount__c, CPQ_Year_5_Net_Amount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : originalQuoteIdSet];

    // create a map with key as original quote's Id + corresponding quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForQriginalQuotes) {
      originalQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Quote__c)+String.valueOf(quoteline.SBQQ__Product__c), quoteline);
    }

    // retrieve quotelines for all last quotes
    List<SBQQ__QuoteLine__c> quoteLineListForLastQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Annual_Net_Amount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : lastQuoteIdSet];

    // create a map with key as last quote's Id + corresponding quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForLastQuotes) {
      lastQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Quote__c)+String.valueOf(quoteline.SBQQ__Product__c), quoteline);
    }

    System.debug('***quoteIdQLIListMap size after filtering '+quoteIdQLIListMap.size());
    System.debug('***firstTimeSet '+firstTimeSet);
    System.debug('***nonFirstTimeSet '+nonFirstTimeSet);
    System.debug('***originalQuoteIdSet '+originalQuoteIdSet);
    System.debug('***originalQuotesRampUpInfoMap '+originalQuotesRampUpInfoMap);
    System.debug('***lastQuoteIdSet '+lastQuoteIdSet);
    System.debug('***lastQuotesRampUpInfoMap '+lastQuotesRampUpInfoMap);

    // if no renewal type quotes, then simply quit
    if(quoteIdQLIListMap.size() == 0) return;

    // process QLIs for first time renewal quotes
    if(firstTimeSet.size() != 0 && !Test.isRunningTest()) {
      CPQ_QuoteLine_Utilities.processFirstTimeSet(firstTimeSet, quoteMap, quoteIdQLIListMap, originalQuotesRampUpInfoMap);
    }

    // process QLIs for non first time renewal quotes
    if(nonFirstTimeSet.size() != 0 && !Test.isRunningTest()) {
      CPQ_QuoteLine_Utilities.processNonFirstTimeSet(nonFirstTimeSet, quoteMap, quoteIdQLIListMap, originalQuotesRampUpInfoMap, lastQuotesRampUpInfoMap);
    }
  }

  /*
     process quotelines whose associated quote satisfying (original quote == last quote)
   */
  private static void processFirstTimeSet(Set<Id> quoteIdSet, Map<Id, SBQQ__Quote__c> quoteMap, Map<Id, List<SBQQ__QuoteLine__c>> quoteIdQLIListMap, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***processFirstTimeSet '+quoteIdSet);

    List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c>();
    // List<SBQQ__QuoteLine__c> updateQuoteLineList = new List<SBQQ__QuoteLine__c>();

    for(Id quoteId : quoteIdSet) {
      SBQQ__Quote__c quote = quoteMap.get(quoteId);
      Integer var = Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('SBQQ__SubscriptionTerm__c')) / 12;
      List<SBQQ__QuoteLine__c> quotelineList = quoteIdQLIListMap.get(quoteId);

      System.debug('***quote '+quote);
      System.debug('***var '+var);
      System.debug('***quotelineList '+quotelineList);

      if(Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('Term_Length__c')) * 12 > Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('SBQQ__SubscriptionTerm__c'))) {
        quote.CPQ_Baseline_Current_Year_Reference__c = var + 1;
        quote.CPQ_Baseline_Last_Year_Reference__c = var;
        updateQuoteList.add(quote);

        for(SBQQ__QuoteLine__c quoteline : quotelineList) {
          quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var + 1, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          // updateQuoteLineList.add(quoteline);
        }
      }else{
        quote.CPQ_Baseline_Current_Year_Reference__c = var;
        quote.CPQ_Baseline_Last_Year_Reference__c = var;
        updateQuoteList.add(quote);

        for(SBQQ__QuoteLine__c quoteline : quotelineList) {
          quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          // updateQuoteLineList.add(quoteline);
        }
      }
    }

    System.debug('***updateQuoteList '+updateQuoteList);
    // System.debug('***updateQuoteLineList '+updateQuoteLineList);

    if(updateQuoteList.size() != 0 && !Test.isRunningTest()) {
      update updateQuoteList;
    }

    // if(updateQuoteLineList.size() != 0 && !Test.isRunningTest()) {
    //   update updateQuoteLineList;
    // }
  }

  /*
     process quotelines whose associated quote satisfying (original quote != last quote)
   */
  private static void processNonFirstTimeSet(Set<Id> quoteIdSet, Map<Id, SBQQ__Quote__c> quoteMap, Map<Id, List<SBQQ__QuoteLine__c>> quoteIdQLIListMap, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***processNonFirstTimeSet '+quoteIdSet);

    List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c>();
    // List<SBQQ__QuoteLine__c> updateQuoteLineList = new List<SBQQ__QuoteLine__c>();

    for(Id quoteId : quoteIdSet) {
      SBQQ__Quote__c quote = quoteMap.get(quoteId);
      Integer var = Integer.valueOf(quote.getsObject('CPQ_LastQuote__r').get('CPQ_Baseline_Current_Year_Reference__c')) + 1;
      List<SBQQ__QuoteLine__c> quotelineList = quoteIdQLIListMap.get(quoteId);

      System.debug('***quote '+quote);
      System.debug('***var '+var);
      System.debug('***quotelineList '+quotelineList);

      if(var > Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('Term_Length__c'))) {

        for(SBQQ__QuoteLine__c quoteline : quotelineList) {
          quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quote.CPQ_LastQuote__c, quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
          quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quote.CPQ_LastQuote__c, quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
          // updateQuoteLineList.add(quoteline);
        }
      }else{
        quote.CPQ_Baseline_Current_Year_Reference__c = var;
        quote.CPQ_Baseline_Last_Year_Reference__c = var - 1;
        updateQuoteList.add(quote);

        for(SBQQ__QuoteLine__c quoteline : quotelineList) {
          quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var - 1, quote.SBQQ__OriginalQuote__c, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
          // updateQuoteLineList.add(quoteline);
        }
      }
    }

    System.debug('***updateQuoteList '+updateQuoteList);
    // System.debug('***updateQuoteLineList '+updateQuoteLineList);

    if(updateQuoteList.size() != 0 && !Test.isRunningTest()) {
      update updateQuoteList;
    }

    // if(updateQuoteLineList.size() != 0 && !Test.isRunningTest()) {
    //   update updateQuoteLineList;
    // }
  }

  /*
     get baseline license value for a specific quoteline from one of this specific quoteline's associated quote's original quote's many quotelines (based on original quote id and specific quoteline's product id)
   */
  private static Decimal getLicenseRampUp(Decimal year, Id originalQuoteId, Id productId, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***getLicenseRampUp');

    SBQQ__QuoteLine__c quoteLine = originalQuotesRampUpInfoMap.get(String.valueOf(originalQuoteId)+String.valueOf(productId));
    System.debug('***quoteLine '+quoteLine);

    if(year == 1) {
      return quoteLine.CPQ_Year_1_Net_Amount__c;
    }else if(year == 2) {
      return quoteLine.CPQ_Year_2_Net_Amount__c;
    }else if(year == 3) {
      return quoteLine.CPQ_Year_3_Net_Amount__c;
    }else if(year == 4) {
      return quoteLine.CPQ_Year_4_Net_Amount__c;
    }else{
      return quoteLine.CPQ_Year_5_Net_Amount__c;
    }
  }

  /*
     get baseline license for a specific quoteline from one of this specific quoteline's associated quote's last quote's many quotelines (based on last quote id and specific quoteline's product id)
   */
  private static Decimal getAnnualNet(Id lastQuoteId, Id productId, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***getAnnualNet');
    System.debug('***lastQuoteId '+lastQuoteId);
    System.debug('***productId '+productId);
    System.debug('***key '+String.valueOf(lastQuoteId)+String.valueOf(productId));
    System.debug('***lastQuotesRampUpInfoMap '+lastQuotesRampUpInfoMap);

    SBQQ__QuoteLine__c quoteLine = lastQuotesRampUpInfoMap.get(String.valueOf(lastQuoteId)+String.valueOf(productId));
    System.debug('***quoteLine '+quoteLine);

    return quoteLine.CPQ_Annual_Net_Amount__c;
  }

  /*
     bulkified method for sync support percent
   */
  public static void syncSupportPercent(List<SBQQ__QuoteLine__c> newQuoteLineList, Map<Id, sObject> oldOuoteLineMap){

    for(SBQQ__QuoteLine__c quoteline : newQuoteLineList) {
      System.debug('***id '+quoteline.Id);
      System.debug('***support percent '+quoteline.SBQQ__SubscriptionPercent__c);
    }

    if(CPQ_QuoteLine_Utilities.alreadySyncSupportPercent) return;
    CPQ_QuoteLine_Utilities.alreadySyncSupportPercent = true;

    System.debug('***enter syncSupportPercent');

    Set<Id> quotelineIdSet = new Set<Id>();

    if(oldOuoteLineMap == null) {
      System.debug('***handle insert');
      // for insert trigger, collect all quoteline Ids where SBQQ__SubscriptionPercent__c is not null
      for(SBQQ__QuoteLine__c quoteline : newQuoteLineList) {
        if(quoteline.SBQQ__SubscriptionPercent__c != null) {
          quotelineIdSet.add(quoteline.Id);
        }
      }
    }else{
      System.debug('***handle update');
      // for update trigger, collect all quoteline Ids where SBQQ__SubscriptionPercent__c is not null and been changed
      for(SBQQ__QuoteLine__c quoteline : newQuoteLineList) {
        if(quoteline.SBQQ__SubscriptionPercent__c != null && oldOuoteLineMap.get(quoteline.Id).get('SBQQ__SubscriptionPercent__c') != quoteline.SBQQ__SubscriptionPercent__c) {
          quotelineIdSet.add(quoteline.Id);
        }
      }
    }

    System.debug('***quotelineIdSet '+quotelineIdSet);

    if(quotelineIdSet.size() != 0 && !Test.isRunningTest()) {
      CPQ_QuoteLine_Utilities.processSupportPercentSync(quotelineIdSet);
    }
  }

  private static void processSupportPercentSync(Set<Id> quotelineIdSet){
    System.debug('***processSupportPercentSync '+quotelineIdSet);

    // get detailed info for all passed in QLI Ids
    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__Quote__c, SBQQ__SubscriptionPercent__c, SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__Product__r.Sku_Type__c FROM SBQQ__QuoteLine__c WHERE Id IN : quotelineIdSet];
    System.debug('***quoteLineList '+quoteLineList);

    // iterate list, select those whose product's sku type is 'Maintenance', and create a map (quoteId, supportPercent)
    Map<Id, Decimal> quoteIdSupportPercentMap = new Map<Id, Decimal>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      if(quoteline.getsObject('SBQQ__Product__r').get('Sku_Type__c') == 'Maintenance') {
        quoteIdSupportPercentMap.put(quoteline.SBQQ__Quote__c, quoteline.SBQQ__SubscriptionPercent__c);
      }
    }
    System.debug('***quoteIdSupportPercentMap '+quoteIdSupportPercentMap);

    // retrieve all QLIs based on quoteId set, and update support percent fields
    List<SBQQ__QuoteLine__c> updateQuoteLineList = [SELECT Id, SBQQ__Quote__c, SBQQ__SubscriptionPercent__c, SBQQ__Product__r.Sku_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : quoteIdSupportPercentMap.keySet() AND SBQQ__Product__r.Sku_Type__c != 'Maintenance'];
    for(SBQQ__QuoteLine__c quoteline : updateQuoteLineList) {
      quoteline.SBQQ__SubscriptionPercent__c = quoteIdSupportPercentMap.get(quoteline.SBQQ__Quote__c);
    }
    System.debug('***updateQuoteLineList '+updateQuoteLineList);

    if(updateQuoteLineList.size() != 0 && !Test.isRunningTest()) {
      System.debug('***do the update!');
      upsert updateQuoteLineList;
    }
  }
}
