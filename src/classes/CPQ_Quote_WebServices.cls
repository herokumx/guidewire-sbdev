global class CPQ_Quote_WebServices {
  webservice static void processQuote(Id quoteId){
    System.debug('***quoteId '+quoteId);
    CPQ_Quote_Utilities.populateOriginalAndLastQuotes(quoteId);
    CPQ_QuoteLine_Utilities.populateBaseLineInfo(quoteId);
    CPQ_QuoteLine_Utilities.populateSupportPercent(quoteId);
    CPQ_QuoteLine_Utilities.populateLastQuoteInvoicedLicense(quoteId);
    return;
  }
}
