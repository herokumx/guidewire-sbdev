public without sharing class CPQ_QuoteLine_Utilities {

  public static void populateBaseLineInfo(Id quoteId){

    // retrieve quote detailed info
    SBQQ__Quote__c quote = [SELECT SBQQ__Type__c, SBQQ__OriginalQuote__c, CPQ_LastQuote__c, SBQQ__OriginalQuote__r.Term_Length__c, SBQQ__OriginalQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.Term_Length__c, CPQ_LastQuote__r.SBQQ__SubscriptionTerm__c, CPQ_LastQuote__r.CPQ_Baseline_Current_Year_Reference__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
    System.debug('***quote '+quote);

    // retrieve quoteline list
    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Product__r.Name, CPQ_Baseline_Current_Year_License__c, CPQ_Baseline_Last_Year_License__c, SBQQ__SubscriptionPercent__c, CPQ_Last_Quote_Invoiced_License__c, CPQ_Last_Quote_Invoiced_Support__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
    System.debug('***quoteLineList '+quoteLineList);

    Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap = getOriginalQuotesRampUpInfoMap(quote);
    Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap = getLastQuotesRampUpInfoMap(quote);

    System.debug('***originalQuotesRampUpInfoMap '+originalQuotesRampUpInfoMap);
    System.debug('***lastQuotesRampUpInfoMap '+lastQuotesRampUpInfoMap);

    // process QLIs based on if quote is first time renewal or not (original quote = last quote)
    if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c) {
      CPQ_QuoteLine_Utilities.processFirstTimeSet(quote, quoteLineList, originalQuotesRampUpInfoMap);
    }else{
      CPQ_QuoteLine_Utilities.processNonFirstTimeSet(quote, quoteLineList, originalQuotesRampUpInfoMap, lastQuotesRampUpInfoMap);
    }

    // iterate quoteLineList and populate support percent & last quote invoiced license & last quote invoiced support
    Decimal supportPercent = getSupportPercent(quoteId);
    Map<String,Decimal> lastQuoteInvoicedLicenseMap = getLastQuoteInvoicedLicenseMap(quoteId);
    Map<String, Decimal> lastQuoteInvoicedSupportMap = getLastQuoteInvoicedSupportMap(quoteId);
    Map<Id,Decimal> licenseDistributionMap = getLicenseDistributionMap(quoteId);
    Map<Id,Decimal> supportDistributionMap = getSupportDistributionMap(quoteId);

    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      quoteline.SBQQ__SubscriptionPercent__c = supportPercent;
      quoteline.CPQ_License_Distribution_Renewal__c = licenseDistributionMap.get(quoteline.SBQQ__Product__c);
      quoteline.CPQ_Distribution_Renewal__c = supportDistributionMap.get(quoteline.SBQQ__Product__c);
      if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c && quote.CPQ_Baseline_Last_Year_Reference__c != null) {
        quoteline.CPQ_Last_Quote_Invoiced_License__c = lastQuoteInvoicedLicenseMap.get(String.valueOf(quoteline.SBQQ__Product__c)+String.valueOf(quote.CPQ_Baseline_Last_Year_Reference__c));
        quoteline.CPQ_Last_Quote_Invoiced_Support__c = lastQuoteInvoicedSupportMap.get(String.valueOf(quoteline.SBQQ__Product__c)+String.valueOf(quote.CPQ_Baseline_Last_Year_Reference__c));
      }else{
        quoteline.CPQ_Last_Quote_Invoiced_License__c = lastQuoteInvoicedLicenseMap.get(String.valueOf(quoteline.SBQQ__Product__c));
        quoteline.CPQ_Last_Quote_Invoiced_Support__c = lastQuoteInvoicedSupportMap.get(String.valueOf(quoteline.SBQQ__Product__c));
      }
    }

    update quote;
    update quoteLineList;
  }

  /////////////////////////////////////////////////////////
  ///  2 methods to calculate baseline information      ///
  /////////////////////////////////////////////////////////

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
        quoteline.CPQ_Baseline_Current_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var + 1, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
      }
    }else{
      quote.CPQ_Baseline_Current_Year_Reference__c = var;
      quote.CPQ_Baseline_Last_Year_Reference__c = var;

      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Current_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
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
      var = null;
    }
    System.debug('***var '+var);

    if(var == null || var > Integer.valueOf(quote.getsObject('SBQQ__OriginalQuote__r').get('Term_Length__c'))) {
      if(var != null) {
        quote.CPQ_Baseline_Last_Year_Reference__c = var - 1;
      }
      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getAnnualNet(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Current_Year_Support__c = CPQ_QuoteLine_Utilities.getAnnualSupport(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_Support__c = CPQ_QuoteLine_Utilities.getAnnualSupport(quoteline.SBQQ__Product__c, lastQuotesRampUpInfoMap);
      }
    }else{
      quote.CPQ_Baseline_Current_Year_Reference__c = var;
      quote.CPQ_Baseline_Last_Year_Reference__c = var - 1;

      for(SBQQ__QuoteLine__c quoteline : quotelineList) {
        quoteline.CPQ_Baseline_Current_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_License__c = CPQ_QuoteLine_Utilities.getLicenseRampUp(var - 1, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Current_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
        quoteline.CPQ_Baseline_Last_Year_Support__c = CPQ_QuoteLine_Utilities.getSupportRampUp(var - 1, quoteline.SBQQ__Product__c, originalQuotesRampUpInfoMap);
      }
    }
  }

  /////////////////////////////////////////////////////////
  ///  utility methods to calculate specific values    ///
  /////////////////////////////////////////////////////////

  /*
     get baseline license value for a specific quoteline from one of this specific quoteline's associated quote's original quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getLicenseRampUp(Decimal year, Id productId, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***getLicenseRampUp');

    SBQQ__QuoteLine__c quoteLine = originalQuotesRampUpInfoMap.get(String.valueOf(productId));
    if(quoteLine == null) {
      quoteLine = originalQuotesRampUpInfoMap.get('Maintenance');
    }
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
     get baseline support value for a specific quoteline from one of this specific quoteline's associated quote's original quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getSupportRampUp(Decimal year, Id productId, Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap){
    System.debug('***getSupportRampUp');

    SBQQ__QuoteLine__c quoteLine = originalQuotesRampUpInfoMap.get(String.valueOf(productId));
    if(quoteLine == null) {
      quoteLine = originalQuotesRampUpInfoMap.get('Maintenance');
    }
    System.debug('***quoteLine '+quoteLine);

    if(year == 1) {
      return quoteLine.Year_1_Support_Ramp_Up_Total__c;
    }else if(year == 2) {
      return quoteLine.Year_2_Support_Ramp_Up_Total__c;
    }else if(year == 3) {
      return quoteLine.Year_3_Support_Ramp_Up_Total__c;
    }else if(year == 4) {
      return quoteLine.Year_4_Support_Ramp_Up_Total__c;
    }else{
      return quoteLine.Year_5_Support_Ramp_Up_Total__c;
    }
  }

  /*
     get baseline license for a specific quoteline from one of this specific quoteline's associated quote's last quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getAnnualNet(Id productId, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***getAnnualNet');

    SBQQ__QuoteLine__c quoteLine = lastQuotesRampUpInfoMap.get(String.valueOf(productId));
    if(quoteLine == null) {
      quoteLine = lastQuotesRampUpInfoMap.get('Maintenance');
    }
    System.debug('***quoteLine '+quoteLine);

    return quoteLine.CPQ_Renewal_License_Total__c;
  }

  /*
     get baseline support for a specific quoteline from one of this specific quoteline's associated quote's last quote's many quotelines (based on specific quoteline's product id)
   */
  private static Decimal getAnnualSupport(Id productId, Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap){
    System.debug('***getAnnualSupport');

    SBQQ__QuoteLine__c quoteLine = lastQuotesRampUpInfoMap.get(String.valueOf(productId));
    if(quoteLine == null) {
      quoteLine = lastQuotesRampUpInfoMap.get('Maintenance');
    }
    System.debug('***quoteLine '+quoteLine);

    return quoteLine.CPQ_Renewal_Support_Total__c;
  }

  /*
     get support percent from Maintenance product
   */
  private static Decimal getSupportPercent(Id quoteId){
    System.debug('***populateSupportPercent');

    // retrieve maintenance quoteline and get support percent
    SBQQ__QuoteLine__c maintenanceQLI = [SELECT Id, SBQQ__Quote__c, SBQQ__SubscriptionPercent__c, SBQQ__Product__r.Sku_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND SBQQ__Product__r.Sku_Type__c = 'Maintenance' LIMIT 1];
    System.debug('***maintenanceQLI '+maintenanceQLI);

    Decimal supportPercent = (maintenanceQLI == null) ? 0 : maintenanceQLI.SBQQ__SubscriptionPercent__c;
    System.debug('***supportPercent '+supportPercent);

    return supportPercent;
  }

  ////////////////////////////////////////////
  ///  utility methods to prepare maps    ///
  ////////////////////////////////////////////

  /*
     get originalQuotesRampUpInfoMap
   */
  private static Map<String, SBQQ__QuoteLine__c> getOriginalQuotesRampUpInfoMap(SBQQ__Quote__c quote){

    /*
       retrieve following fields from original quote's quotelines to calculate baseline license and baseline support
       CPQ_Year_1_Net_Amount__c - CPQ_Year_5_Net_Amount__c
       Year_1_Support_Ramp_Up_Total__c - Year_5_Support_Ramp_Up_Total__c
     */
    List<SBQQ__QuoteLine__c> quoteLineListForQriginalQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Product__r.Name, CPQ_Year_1_Net_Amount__c, CPQ_Year_2_Net_Amount__c, CPQ_Year_3_Net_Amount__c, CPQ_Year_4_Net_Amount__c, CPQ_Year_5_Net_Amount__c, Year_1_Support_Ramp_Up_Total__c, Year_2_Support_Ramp_Up_Total__c, Year_3_Support_Ramp_Up_Total__c, Year_4_Support_Ramp_Up_Total__c, Year_5_Support_Ramp_Up_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

    // create a map with key as quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> originalQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForQriginalQuotes) {
      if(String.valueOf(quoteline.getsObject('SBQQ__Product__r').get('Name')).contains('Maintenance')) {
        originalQuotesRampUpInfoMap.put('Maintenance', quoteline);
      }else{
        originalQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline);
      }
    }

    return originalQuotesRampUpInfoMap;
  }

  /*
     get lastQuotesRampUpInfoMap
   */
  private static Map<String, SBQQ__QuoteLine__c> getLastQuotesRampUpInfoMap(SBQQ__Quote__c quote){
    // retrieve quotelines with CPQ_Renewal_License_Total__c and CPQ_Renewal_Support_Total__c (to calculate baseline license and support) for last quote
    List<SBQQ__QuoteLine__c> quoteLineListForLastQuotes = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Product__r.Name, CPQ_Renewal_License_Total__c, CPQ_Renewal_Support_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.CPQ_LastQuote__c];

    // create a map with key as quoteline's productId, value as the corresponding quoteline
    Map<String,SBQQ__QuoteLine__c> lastQuotesRampUpInfoMap = new Map<String,SBQQ__QuoteLine__c>();
    for(SBQQ__QuoteLine__c quoteline : quoteLineListForLastQuotes) {
      if(String.valueOf(quoteline.getsObject('SBQQ__Product__r').get('Name')).contains('Maintenance')) {
        lastQuotesRampUpInfoMap.put('Maintenance', quoteline);
      }else{
        lastQuotesRampUpInfoMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline);
      }
    }

    return lastQuotesRampUpInfoMap;
  }

  /*
     get map for 'last quote invoiced license' for all quotelineitems
   */
  private static Map<String,Decimal> getLastQuoteInvoicedLicenseMap(Id quoteId){
    System.debug('***getLastQuoteInvoicedLicenseMap');

    // create a map with key as quoteline's productId (or productId + baselineLastYearReference for first year renewal quote), value as the corresponding invoiced license
    Map<String,Decimal> lastQuoteInvoicedLicenseMap = new Map<String,Decimal>();

    // get current quote
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__OriginalQuote__c, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

    if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c) {
      // retrieve QLIs with CPQ_Year_1_Net_Amount__c - CPQ_Year_5_Net_Amount__c
      List<SBQQ__QuoteLine__c> quoteLineOfOriginalQuoteList = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Year_1_Net_Amount__c, CPQ_Year_2_Net_Amount__c, CPQ_Year_3_Net_Amount__c, CPQ_Year_4_Net_Amount__c, CPQ_Year_5_Net_Amount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

      for(SBQQ__QuoteLine__c quoteline : quoteLineOfOriginalQuoteList) {
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'1', quoteline.CPQ_Year_1_Net_Amount__c);
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'2', quoteline.CPQ_Year_2_Net_Amount__c);
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'3', quoteline.CPQ_Year_3_Net_Amount__c);
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'4', quoteline.CPQ_Year_4_Net_Amount__c);
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'5', quoteline.CPQ_Year_5_Net_Amount__c);
      }
    }else{
      // retrieve all QLIs from last quote
      List<SBQQ__QuoteLine__c> quoteLineOfLastQuoteList = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Renewal_License_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.CPQ_LastQuote__c];

      for(SBQQ__QuoteLine__c quoteline : quoteLineOfLastQuoteList) {
        lastQuoteInvoicedLicenseMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline.CPQ_Renewal_License_Total__c);
      }
    }


    System.debug('***lastQuoteInvoicedLicenseMap '+lastQuoteInvoicedLicenseMap);

    return lastQuoteInvoicedLicenseMap;
  }

  /*
     get map for 'last quote invoiced support' for all quotelineitems
   */
  private static Map<String,Decimal> getLastQuoteInvoicedSupportMap(Id quoteId){
    System.debug('***getLastQuoteInvoicedSupportMap');

    // create a map with key as quoteline's productId (or productId + baselineLastYearReference for first year renewal quote), value as the corresponding invoiced support
    Map<String,Decimal> lastQuoteInvoicedSupportMap = new Map<String,Decimal>();

    // get current quote
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__OriginalQuote__c, CPQ_LastQuote__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

    if(quote.SBQQ__OriginalQuote__c == quote.CPQ_LastQuote__c) {
      // retrieve QLIs with Year_1_Support_Ramp_Up_Total__c - Year_5_Support_Ramp_Up_Total__c
      List<SBQQ__QuoteLine__c> quoteLineOfOriginalQuoteList = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Year_1_Support_Ramp_Up_Total__c, Year_2_Support_Ramp_Up_Total__c, Year_3_Support_Ramp_Up_Total__c, Year_4_Support_Ramp_Up_Total__c, Year_5_Support_Ramp_Up_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

      for(SBQQ__QuoteLine__c quoteline : quoteLineOfOriginalQuoteList) {
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'1', quoteline.Year_1_Support_Ramp_Up_Total__c);
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'2', quoteline.Year_2_Support_Ramp_Up_Total__c);
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'3', quoteline.Year_3_Support_Ramp_Up_Total__c);
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'4', quoteline.Year_4_Support_Ramp_Up_Total__c);
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c)+'5', quoteline.Year_5_Support_Ramp_Up_Total__c);
      }
    }else{
      // retrieve all QLIs from last quote
      List<SBQQ__QuoteLine__c> quoteLineOfLastQuoteList = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, CPQ_Renewal_Support_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.CPQ_LastQuote__c];

      for(SBQQ__QuoteLine__c quoteline : quoteLineOfLastQuoteList) {
        lastQuoteInvoicedSupportMap.put(String.valueOf(quoteline.SBQQ__Product__c), quoteline.CPQ_Renewal_Support_Total__c);
      }
    }


    System.debug('***lastQuoteInvoicedSupportMap '+lastQuoteInvoicedSupportMap);

    return lastQuoteInvoicedSupportMap;
  }

  /*
     get map for populating renewal quote's quoteline's license distribution field
   */
  private static Map<Id,Decimal> getLicenseDistributionMap(Id quoteId){
    System.debug('***getLicenseDistributionMap');

    // key as quoteline's product Id, value as original quote's corresponding quoteline's license distribution
    Map<Id,Decimal> licenseDistributionMap = new Map<Id,Decimal>();

    // get current quote
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__OriginalQuote__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

    List<SBQQ__QuoteLine__c> quoteLineOfOriginalQuoteList = [SELECT SBQQ__Product__c, CPQ_License_Distribution__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

    for(SBQQ__QuoteLine__c quoteline : quoteLineOfOriginalQuoteList) {
      licenseDistributionMap.put(quoteline.SBQQ__Product__c, quoteline.CPQ_License_Distribution__c);
    }

    System.debug('***licenseDistributionMap '+licenseDistributionMap);

    return licenseDistributionMap;
  }

  /*
     get map for populating renewal quote's quoteline's support distribution field
   */
  private static Map<Id,Decimal> getSupportDistributionMap(Id quoteId){
    System.debug('***getSupportDistributionMap');

    // key as quoteline's product Id, value as original quote's corresponding quoteline's support distribution
    Map<Id,Decimal> supportDistributionMap = new Map<Id,Decimal>();

    // get current quote
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__OriginalQuote__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

    List<SBQQ__QuoteLine__c> quoteLineOfOriginalQuoteList = [SELECT SBQQ__Product__c, CPQ_Distribution__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.SBQQ__OriginalQuote__c];

    for(SBQQ__QuoteLine__c quoteline : quoteLineOfOriginalQuoteList) {
      supportDistributionMap.put(quoteline.SBQQ__Product__c, quoteline.CPQ_Distribution__c);
    }

    System.debug('***supportDistributionMap '+supportDistributionMap);

    return supportDistributionMap;
  }
}
