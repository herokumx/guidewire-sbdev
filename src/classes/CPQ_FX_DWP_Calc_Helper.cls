public with sharing class CPQ_FX_DWP_Calc_Helper {

  //Static run variable
  private static Map<ID,DatedConversionRate> dcrIdToDcrMap;
  private static boolean run = true;
  public static boolean runOnce() {
    if(run) {
      run=false;
      return true;
    } else {
      return run;
    }
  }

  public static void OnBeforeInsert(SBQQ__Quote__c[] newQuotes, Map<ID, SBQQ__Quote__c> quotesMap) {
    System.debug('***OnBeforeInsert');
    //Map<Id, Opportunity> quoteToOpp = new Map<Id, Opportunity>();
    Set<Id> quoteOpps = new Set<Id>();
    System.debug('Looking for related opportunities');
    for (SBQQ__Quote__c quote : newQuotes) {
      if (quote.SBQQ__Opportunity2__c != null) {
        if (Trigger.isUpdate && (quote.CPQ_Quote_Currency_to_USD_Conversion__c == null || quote.CPQ_USD_to_Quote_Currency_Conversion__c == null)) {
          quoteOpps.add(quote.SBQQ__Opportunity2__c);
        }
        else if (Trigger.isInsert) {
          quoteOpps.add(quote.SBQQ__Opportunity2__c);
        }
      }
    }

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id in:quoteOpps]);

    //Modify this date to be in the future if needed.
    Date current = Date.today();
    for (SBQQ__Quote__c quote : newQuotes) {
      System.debug('Looking for current Quote link to Opportunity {' + quote.SBQQ__Opportunity2__c + '}');
      Opportunity oppWithCurr = oppMap.get(quote.SBQQ__Opportunity2__c);
      if (oppWithCurr != null && String.isNotBlank(oppWithCurr.CurrencyIsoCode)) {
        System.debug('Found currency to look up: ' + oppWithCurr.CurrencyIsoCode);
        if (oppWithCurr.CurrencyIsoCode == 'USD') {
          quote.CPQ_Quote_Currency_to_USD_Conversion__c = 1;
          quote.CPQ_USD_to_Quote_Currency_Conversion__c = 1;
          quote.CPQ_Quote_Created_Currency_to_USD__c = 1;
          quote.CPQ_Quote_Created_USD_to_Currency__c = 1;
        }
        else {
          quote.CPQ_Quote_Currency_to_USD_Conversion__c = convertToOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
          quote.CPQ_USD_to_Quote_Currency_Conversion__c = convertFromOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
          quote.CPQ_Quote_Created_Currency_to_USD__c = convertToOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
          quote.CPQ_Quote_Created_USD_to_Currency__c = convertFromOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
        }
      }
      System.debug('Final Currency values: CPQ_Quote_Currency_to_USD_Conversion__c: ' + quote.CPQ_Quote_Currency_to_USD_Conversion__c + ' CPQ_USD_to_Quote_Currency_Conversion__c: ' + quote.CPQ_USD_to_Quote_Currency_Conversion__c);
    }
  }

  public static void OnBeforeUpdate(SBQQ__Quote__c[] newQuotes, Map<Id, SBQQ__Quote__c> quotesMap) {
    System.debug('***OnBeforeUpdate');
    CPQ_RoyaltiesCalculator.calculateRoyalties(quotesMap);
  }

  public static void UpdateFX(SBQQ__Quote__c quote) {
    System.debug('***UpdateFX');
    // DM 07-24 Changed id = :quote.id to Id = :quote.SBQQ__Opportunity2__c]);
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = : quote.SBQQ__Opportunity2__c]);

    //Modify this date to be in the future if needed.
    Date current = Date.today();
    System.debug('Looking for current Quote link to Opportunity {' + quote.SBQQ__Opportunity2__c + '}');
    Opportunity oppWithCurr = oppMap.get(quote.SBQQ__Opportunity2__c);
    if (oppWithCurr != null && String.isNotBlank(oppWithCurr.CurrencyIsoCode)) {
      System.debug('Found currency to look up: ' + oppWithCurr.CurrencyIsoCode);
      if (oppWithCurr.CurrencyIsoCode == 'USD') {
        quote.CPQ_Quote_Currency_to_USD_Conversion__c = 1;
        quote.CPQ_USD_to_Quote_Currency_Conversion__c = 1;
      }
      else {
        quote.CPQ_Quote_Currency_to_USD_Conversion__c = convertToOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
        quote.CPQ_USD_to_Quote_Currency_Conversion__c = convertFromOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, current);
      }
    }
    //DM 07-24 - Introduced Update quote.
    Update quote;
    System.debug('Final Currency values: CPQ_Quote_Currency_to_USD_Conversion__c: ' + quote.CPQ_Quote_Currency_to_USD_Conversion__c + ' CPQ_USD_to_Quote_Currency_Conversion__c: ' + quote.CPQ_USD_to_Quote_Currency_Conversion__c);
  }

  //On before update trigger expected (before)
  public static void OpportunityUpdate(Opportunity[] oldOpps, Opportunity[] newOpps, Map<ID, Opportunity> oldMap, Map<ID, Opportunity> newMap) {
    System.debug('***OpportunityUpdate');
    //Map<Id, Opportunity> quoteToOpp = new Map<Id, Opportunity>();

    Set<Id> closedQuoteIds = new Set<Id>();
    Set<Id> contractedQuoteIds = new Set<Id>();

    System.debug('Looking for modified and closed/won || contracted opportunities');
    for (Opportunity newOpp: newOpps) {
      Opportunity oldOpp = oldMap.get(newOpp.Id);
      if (newOpp.StageName == 'Closed - Won') {
        if (oldOpp.StageName != newOpp.StageName) {
          if (newOpp.SBQQ__PrimaryQuote__c != null) {
            closedQuoteIds.add(newOpp.SBQQ__PrimaryQuote__c);
          }
        }
      }

      if (newOpp.SBQQ__Contracted__c) {
        if (oldOpp.SBQQ__Contracted__c != newOpp.SBQQ__Contracted__c) {
          if (newOpp.SBQQ__PrimaryQuote__c != null) {
            contractedQuoteIds.add(newOpp.SBQQ__PrimaryQuote__c);
          }
        }
      }
    }


    Map<Id, SBQQ__Quote__c> closedQuotes = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id in:closedQuoteIds]);
    Map<Id, SBQQ__Quote__c> contractedQuotes = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id in:contractedQuoteIds]);

    //Modify this date to be in the future if needed.
    Date closedCurrent = Date.today();
    for (SBQQ__Quote__c quote : closedQuotes.values()) {
      System.debug('Looking for current Quote link to Opportunity {' + quote.SBQQ__Opportunity2__c + '}');
      Opportunity oppWithCurr = newMap.get(quote.SBQQ__Opportunity2__c);
      if (oppWithCurr != null && String.isNotBlank(oppWithCurr.CurrencyIsoCode)) {
        System.debug('Found currency to look up: ' + oppWithCurr.CurrencyIsoCode);
        if (oppWithCurr.CurrencyIsoCode == 'USD') {
          quote.CPQ_Opp_Completed_Currency_to_USD__c = 1;
          quote.CPQ_Opp_Completed_USD_to_Currency__c = 1;
        }
        else {
          quote.CPQ_Opp_Completed_Currency_to_USD__c = convertToOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, closedCurrent);
          quote.CPQ_Opp_Completed_USD_to_Currency__c = convertFromOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, closedCurrent);
        }
      }
      System.debug('Final Currency values: CPQ_Opp_Completed_Currency_to_USD__c: ' + quote.CPQ_Opp_Completed_Currency_to_USD__c + ' CPQ_Opp_Completed_USD_to_Currency__c: ' + quote.CPQ_Opp_Completed_USD_to_Currency__c);
    }

    //Modify this date to be in the future if needed.
    Date contractedCurrent = Date.today();
    for (SBQQ__Quote__c quote : contractedQuotes.values()) {
      System.debug('Looking for current Quote link to Opportunity {' + quote.SBQQ__Opportunity2__c + '}');
      Opportunity oppWithCurr = newMap.get(quote.SBQQ__Opportunity2__c);
      if (oppWithCurr != null && String.isNotBlank(oppWithCurr.CurrencyIsoCode)) {
        System.debug('Found currency to look up: ' + oppWithCurr.CurrencyIsoCode);
        if (oppWithCurr.CurrencyIsoCode == 'USD') {
          quote.CPQ_Contract_Created_Currency_to_USD__c = 1;
          quote.CPQ_Contract_Created_USD_to_Currency__c = 1;
        }
        else {
          quote.CPQ_Contract_Created_Currency_to_USD__c = convertToOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, closedCurrent);
          quote.CPQ_Contract_Created_USD_to_Currency__c = convertFromOrgCurrency(oppWithCurr.CurrencyIsoCode, 1, closedCurrent);
        }
      }
      System.debug('Final Currency values: CPQ_Contract_Created_Currency_to_USD__c: ' + quote.CPQ_Contract_Created_Currency_to_USD__c + ' CPQ_Contract_Created_USD_to_Currency__c: ' + quote.CPQ_Contract_Created_USD_to_Currency__c);
    }

    System.debug('***closedQuotes.values() '+closedQuotes.values());
    System.debug('***contractedQuotes.values() '+contractedQuotes.values());

    update closedQuotes.values();
    update contractedQuotes.values();
  }

  //  ----------------------------------------
  //  convertToOrgCurrency - convert value in some ISO currency to org currency as of given date
  //  ----------------------------------------
  public static Decimal convertToOrgCurrency(String currencyIso, Decimal currencyVal, Date currencyDate) {
    System.debug('***convertToOrgCurrency');
    Decimal res;
    if (currencyIso == null || currencyVal == null) {}
    else {
      if (dcrIdToDcrMap == null)                    // build the map only once for life of the transaction
        dcrIdToDcrMap = new Map<ID,DatedConversionRate> ([select id, isoCode, conversionrate, nextStartDate, startDate from DatedConversionRate]);
      for (DatedConversionRate dcr: dcrIdToDcrMap.values()) {
        if (dcr.isoCode != currencyIso) continue;                                                   // look for a match in table against input currency
        if (currencyDate < dcr.startDate || currencyDate >= dcr.nextStartDate) continue;            // not in the range of effective dates
        System.debug(LoggingLevel.INFO,'Converting using dcr: ' + dcr);
        res =  currencyVal / dcr.conversionRate;
        break;
      }
    }
    System.debug(LoggingLevel.INFO,'convertToOrgCurrency res= ' + res);
    return res;
  }

  //  ----------------------------------------
  //  convertFromOrgCurrency - convert value in org currency to some iso currency as of given date
  //  ----------------------------------------
  public static Decimal convertFromOrgCurrency(String currencyIso, Decimal currencyVal, Date currencyDate) {
    System.debug('***convertFromOrgCurrency');
    Decimal res;
    if (currencyIso == null || currencyVal == null) {}
    else {
      if (dcrIdToDcrMap == null)                    // build the map only once for life of the transaction
        dcrIdToDcrMap = new Map<ID,DatedConversionRate> ([select id, isoCode, conversionrate, nextStartDate, startDate from DatedConversionRate]);
      for (DatedConversionRate dcr: dcrIdToDcrMap.values()) {
        if (dcr.isoCode != currencyIso) continue;                                                   // look for a match in table against input currency
        if (currencyDate < dcr.startDate || currencyDate >= dcr.nextStartDate) continue;            // not in the range of effective dates
        System.debug(LoggingLevel.INFO,'Converting using dcr: ' + dcr);
        res =  currencyVal * dcr.conversionRate;
        break;
      }
    }
    System.debug(LoggingLevel.INFO,'convertFromOrgCurrency res= ' + res);
    return res;
  }
}
