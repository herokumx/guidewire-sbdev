public without sharing class CPQ_QuoteLine_Utilities {
  /*
       populate baseline information:
       Quote:
        CPQ_Baseline_Current_Year_Reference__c (Number)
        CPQ_Baseline_Last_Year_Reference__c (Number)

       QuoteLine:
        CPQ_Baseline_Current_Year_License__c (Currency)
        CPQ_Baseline_Last_Year_License__c (Currency)
   */
  public static void populateBaseLineInfo(Id quoteId){

    // retrieve quote detailed info
    SBQQ__Quote__c quote = [SELECT SBQQ__Type__c, SBQQ__OriginalQuote__c, CPQ_LastQuote__c, SBQQ__OriginalQuote__r.Term_Length__c, SBQQ__OriginalQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.Term_Length__c, CPQ_LastQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.CPQ_Baseline_Current_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
    System.debug('***quote '+quote);

    // retrieve quoteline list
    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT SBQQ__Quote__c, SBQQ__Product__c, CPQ_Baseline_Current_Year_License__c, CPQ_Baseline_Last_Year_License__c, SBQQ__SubscriptionPercent__c, CPQ_Last_Quote_Invoiced_License__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
    System.debug('***quoteLineList '+quoteLineList);

    // retrieve quotelines with CPQ_Year_1_Net_Amount__c - CPQ_Year_5_Net_Amount__c (to calculate baseline license) for original quote
    List<SBQQ__QuoteLine__c> quoteLineListForQriginalQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Year_1_Net_Amount__c, CPQ_Year_2_Net_Amount__c, CPQ_Year_3_Net_Amount__c, CPQ_Year_4_Net_Amount__c, CPQ_Year_5_Net_Amount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

    // create a map with key as quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForQriginalQuotes) {
      originalQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline);
    }

    // retrieve quotelines with CPQ_Annual_Net_Amount__c (to calculate baseline license) for last quote
    List<SBQQ__QuoteLine__c> quoteLineListForLastQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Annual_Net_Amount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.CPQ_LastQuote__c];

    // create a map with key as quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForLastQuotes) {
      lastQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline);
    }

    System.debug('***originalQuotesRampUpInfoMap '+originalQuotesRampUpInfoMap);
    System.debug('***lastQuotesRampUpInfoMap '+lastQuotesRampUpInfoMap);

    // process QLIs based on if quote is first time renewal or not (original quote = last quote)
    if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c) {
      CPQ_QuoteLine_Utilities.processFirstTimeSet(quote, quoteLineList, originalQuotesRampUpInfoMap);
    }else{
      CPQ_QuoteLine_Utilities.processNonFirstTimeSet(quote, quoteLineList, originalQuotesRampUpInfoMap, lastQuotesRampUpInfoMap);
    }

    // iterate quoteLineList and populate support percent & last quote invoiced license
    Decimal supportPercent = getSupportPercent(quoteId);
    Map<String,Decimal> lastQuoteInvoicedLicenseMap = getLastQuoteInvoicedLicenseMap(quoteId);

    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      quoteline.SBQQ__SubscriptionPercent__c = supportPercent;
      quoteline.CPQ_Last_Quote_Invoiced_License__c = lastQuoteInvoicedLicenseMap.get(String.valueOf(quoteline.SBQQ__Product__c));
    }

    if(!Test.isRunningTest()) {
      update quote;
      update quoteLineList;
    }
  }

  /*
     process quotelines whose associated quote satisfying (original quote == last quote)
   */
  private static void processFirstTimeSet(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> quoteLineList, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***processFirstTimeSet');
    System.debug('***quote '+quote);
    System.debug('***quoteLineList '+quoteLineList);

    Integer var = Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('SBQQ__SubscriptionTerm__c')) / 12;
    System.debug('***var '+var);

    if(Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('Term_Length__c')) * 12 > Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('SBQQ__SubscriptionTerm__c'))) {
      quote.CPQ_Baseline_Current_Year_Reference__c = var + 1;
      quote.CPQ_Baseline_Last_Year_Reference__c = var;

      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var + 1, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
      }
    }else{
      quote.CPQ_Baseline_Current_Year_Reference__c = var;
      quote.CPQ_Baseline_Last_Year_Reference__c = var;

      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
      }
    }
  }

  /*
     process quotelines whose associated quote satisfying (original quote != last quote)
   */
  private static void processNonFirstTimeSet(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> quoteLineList, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***processNonFirstTimeSet');
    System.debug('***quote '+quote);
    System.debug('***quoteLineList '+quoteLineList);

    Integer var;
    try {
      var = Integer.valueOf(quote.getsObject('CPQ_LastQuote__r').get('CPQ_Baseline_Current_Year_Reference__c')) + 1;
    } catch(Exception ex){
      System.debug('***Exception: '+ex.getMessage());
      return;
    }
    System.debug('***var '+var);

    if(var > Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('Term_Length__c'))) {
      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
      }
    }else{
      quote.CPQ_Baseline_Current_Year_Reference__c = var;
      quote.CPQ_Baseline_Last_Year_Reference__c = var - 1;

      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var - 1, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
      }
    }
  }

  /*
     get baseline license value for a specific quoteline from one of this specific quoteline's associated quote's original quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getLicenseRampUp(Decimal year, Id productId, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***getLicenseRampUp');

    SBQQ__QuoteLine__c quoteLine = originalQuotesRampUpInfoMap.get(String.valueOf(productId));
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
     get baseline license for a specific quoteline from one of this specific quoteline's associated quote's last quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getAnnualNet(Id productId, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***getAnnualNet');

    SBQQ__QuoteLine__c quoteLine = lastQuotesRampUpInfoMap.get(String.valueOf(productId));
    System.debug('***quoteLine '+quoteLine);

    return quoteLine.CPQ_Annual_Net_Amount__c;
  }


  /*
     get support percent from Maintenance product
   */
  private static Decimal getSupportPercent(Id quoteId){
    System.debug('***populateSupportPercent');

    // retrieve maintenance quoteline and get support percent
    SBQQ__QuoteLine__c maintenanceQLI = [SELECT Id, SBQQ__Quote__c, SBQQ__SubscriptionPercent__c, SBQQ__Product__r.Sku_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND SBQQ__Product__r.Sku_Type__c = 'Maintenance' LIMIT 1];
    System.debug('***maintenanceQLI '+maintenanceQLI);

    Decimal supportPercent = (maintenanceQLI == null) ? null : maintenanceQLI.SBQQ__SubscriptionPercent__c;
    System.debug('***supportPercent '+supportPercent);

    return supportPercent;
  }

  /*
     get map for 'last quote invoiced license' for all quotelineitems
   */
  private static Map<String,Decimal> getLastQuoteInvoicedLicenseMap(Id quoteId){
    System.debug('***populateLastQuoteInvoicedLicense');

    // get current quote
    SBQQ__Quote__c quote = [SELECT Id, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

    // retrieve all QLIs from last quote
    List<SBQQ__QuoteLine__c> quoteLineOfLastQuoteList = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.CPQ_LastQuote__c];
    System.debug('***quoteLineOfLastQuoteList '+quoteLineOfLastQuoteList);

    // create a map with key as quoteline's productId, value as the corresponding quoteline's net total
    Map<String,Decimal> lastQuoteInvoicedLicenseMap = new Map<String,Decimal>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineOfLastQuoteList) {
      lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline.SBQQ__NetTotal__c);
    }
    System.debug('***lastQuoteInvoicedLicenseMap '+lastQuoteInvoicedLicenseMap);

    return lastQuoteInvoicedLicenseMap;
  }
}
