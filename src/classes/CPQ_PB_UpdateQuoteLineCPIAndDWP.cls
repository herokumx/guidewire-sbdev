public with sharing class CPQ_PB_UpdateQuoteLineCPIAndDWP {
  /*
     update quote line items CPI and DWP - invoked by process builder 'Update QuoteLine When Quote Changes'
   */
  @InvocableMethod(label='Update LineItems CPI And DWP' description='Update LineItems CPI And DWP')
  public static void updateCPIDWP(List<Id> quoteIds){
    System.debug('***updateCPIDWP');
    System.debug('***quoteIds[0] '+quoteIds[0]);

    SBQQ__Quote__c quote = [SELECT Id, CPQ_Uplift_s_To_Apply__c, Lesser_of_CPI_or_3__c, DWP_Renewal_Quote_Uplift__c FROM SBQQ__Quote__c WHERE Id =: quoteIds[0]];
    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, CPQ_CPI_Uplift_License__c, CPQ_DWP_Adjustment_License__c, CPQ_Last_Quote_Invoiced_License__c, CPQ_License_Distribution_Renewal__c, CPQ_Distribution_Renewal__c, SBQQ__SubscriptionPercent__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteIds[0]];

    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      quoteline.CPQ_CPI_Uplift_License__c = calculateCPI(quote.CPQ_Uplift_s_To_Apply__c, quoteline.CPQ_Last_Quote_Invoiced_License__c, quote.Lesser_of_CPI_or_3__c);
      quoteline.CPQ_CPI_Uplift_Support__c = calculateCPISupport(quote.CPQ_Uplift_s_To_Apply__c, quoteline.CPQ_Last_Quote_Invoiced_License__c, quoteline.SBQQ__SubscriptionPercent__c, quoteline.CPQ_Distribution_Renewal__c);
      quoteline.CPQ_DWP_Adjustment_License__c = calculateDWP(quote.CPQ_Uplift_s_To_Apply__c, quote.DWP_Renewal_Quote_Uplift__c, quoteline.CPQ_License_Distribution_Renewal__c);
      quoteline.CPQ_DWP_Adjustment_Support__c = calculateDWPSupport(quote.CPQ_Uplift_s_To_Apply__c, quote.DWP_Renewal_Quote_Uplift__c, quoteline.SBQQ__SubscriptionPercent__c, quoteline.CPQ_Distribution_Renewal__c);
    }

    update quoteLineList;

    return;
  }

  private static Decimal calculateCPI(String optionName, Decimal lastQuoteInvoicedLicense, Decimal cpiUplift){
    System.debug('***calculateCPI '+optionName);

    lastQuoteInvoicedLicense = (lastQuoteInvoicedLicense == null) ? 0 : lastQuoteInvoicedLicense;
    cpiUplift = (cpiUplift == null) ? 0 : cpiUplift;

    System.debug('***lastQuoteInvoicedLicense '+lastQuoteInvoicedLicense);
    System.debug('***cpiUplift '+cpiUplift);

    if(optionName == 'CPI Uplift' || optionName == 'Both') {
      return lastQuoteInvoicedLicense * cpiUplift / 100;
    }else{
      return 0;
    }
  }

  private static Decimal calculateCPISupport(String optionName, Decimal lastQuoteInvoicedLicense, Decimal supportPercent, Decimal supportDistribution){
    System.debug('***calculateCPISupport '+optionName);

    lastQuoteInvoicedLicense = (lastQuoteInvoicedLicense == null) ? 0 : lastQuoteInvoicedLicense;

    System.debug('***lastQuoteInvoicedLicense '+lastQuoteInvoicedLicense);
    System.debug('***supportPercent '+supportPercent);
    System.debug('***supportDistribution '+supportDistribution);

    if(optionName == 'CPI Uplift' || optionName == 'Both') {
      return lastQuoteInvoicedLicense * supportPercent *  supportDistribution / 10000;
    }else{
      return 0;
    }
  }

  private static Decimal calculateDWP(String optionName, Decimal dwpRenewalQuoteUplift, Decimal cpqDistribution){
    System.debug('***calculateDWP '+optionName);

    dwpRenewalQuoteUplift = (dwpRenewalQuoteUplift == null) ? 0 : dwpRenewalQuoteUplift;
    cpqDistribution = (cpqDistribution == null) ? 0 : cpqDistribution;

    System.debug('***dwpRenewalQuoteUplift '+dwpRenewalQuoteUplift);
    System.debug('***cpqDistribution '+cpqDistribution);

    if(optionName == 'DWP Adjustment' || optionName == 'Both') {
      return dwpRenewalQuoteUplift * cpqDistribution / 100;
    }else{
      return 0;
    }
  }

  private static Decimal calculateDWPSupport(String optionName, Decimal dwpRenewalQuoteUplift, Decimal supportPercent, Decimal supportDistribution){
    System.debug('***calculateDWPSupport '+optionName);

    dwpRenewalQuoteUplift = (dwpRenewalQuoteUplift == null) ? 0 : dwpRenewalQuoteUplift;

    System.debug('***dwpRenewalQuoteUplift '+dwpRenewalQuoteUplift);
    System.debug('***supportPercent '+supportPercent);
    System.debug('***supportDistribution '+supportDistribution);

    if(optionName == 'DWP Adjustment' || optionName == 'Both') {
      return dwpRenewalQuoteUplift * supportPercent * supportDistribution / 10000;
    }else{
      return 0;
    }
  }
}
