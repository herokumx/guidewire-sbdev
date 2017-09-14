public with sharing class CPQ_PB_UpdateQuoteLineCPIAndDWP {
  /*
     update quote line items CPI and DWP - invoked by process builder 'Update QuoteLine When Quote Changes'
   */
  @InvocableMethod(label='Update LineItems CPI And DWP' description='Update LineItems CPI And DWP')
  public static void updateCPIDWP(List<Id> quoteIds){
    System.debug('***updateCPIDWP');
    System.debug('***quoteIds[0] '+quoteIds[0]);

    SBQQ__Quote__c quote = [SELECT Id, CPQ_Uplift_s_To_Apply__c, Lesser_of_CPI_or_3__c, DWP_Renewal_Quote_Uplift__c, CPQ_Last_Quote_Invoiced_License__c FROM SBQQ__Quote__c WHERE Id =: quoteIds[0]];
    Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Product__c, SBQQ__Product__r.Sku_Type__c, CPQ_CPI_Uplift_License__c, CPQ_DWP_Adjustment_License__c, CPQ_Last_Quote_Invoiced_License__c, CPQ_Last_Quote_Invoiced_Support__c, CPQ_License_Distribution_Renewal__c, CPQ_Distribution_Renewal__c, SBQQ__SubscriptionPercent__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteIds[0]]);

    for(SBQQ__QuoteLine__c quoteline : quoteLineMap.values()) {
      quoteline.CPQ_CPI_Uplift_License__c = calculateCPI(quoteline.CPQ_Last_Quote_Invoiced_License__c, quote.Lesser_of_CPI_or_3__c);
      quoteline.CPQ_CPI_Uplift_Support__c = calculateCPISupport(quoteline.CPQ_Last_Quote_Invoiced_Support__c, quote.Lesser_of_CPI_or_3__c);
      quoteline.CPQ_DWP_Adjustment_License__c = calculateDWP(quote.DWP_Renewal_Quote_Uplift__c, quoteline.CPQ_License_Distribution_Renewal__c);
      quoteline.CPQ_DWP_Adjustment_Support__c = calculateDWPSupport(quote.DWP_Renewal_Quote_Uplift__c, quoteline.SBQQ__SubscriptionPercent__c, quoteline.CPQ_License_Distribution_Renewal__c, quoteline.CPQ_Distribution_Renewal__c);
    }

    // add license QLIs' dwp support and assign the value to support QLI's dwp license
    Decimal dwpLicenseForSupportQLI = 0;
    Id supportQliId;
    for(Id quotelineId : quoteLineMap.keySet()) {
      if(String.valueOf(quoteLineMap.get(quotelineId).getsObject('SBQQ__Product__r').get('Sku_Type__c')).equals('Maintenance')) {
        supportQliId = quotelineId;
      }else{
        SBQQ__QuoteLine__c licenseQLI = quoteLineMap.get(quotelineId);
        dwpLicenseForSupportQLI += licenseQLI.CPQ_DWP_Adjustment_Support__c;
      }
    }

    System.debug('***supportQliId '+supportQliId);
    System.debug('***dwpLicenseForSupportQLI '+dwpLicenseForSupportQLI);

    if(supportQliId != null) {
      SBQQ__QuoteLine__c supportQLI = quoteLineMap.get(supportQliId);
      supportQLI.CPQ_DWP_Adjustment_License__c = dwpLicenseForSupportQLI;
      quoteLineMap.put(supportQliId, supportQLI);
    }

    update quoteLineMap.values();

    return;
  }

  private static Decimal calculateCPI(Decimal lastQuoteInvoicedLicense, Decimal cpiUplift){
    System.debug('***calculateCPI');

    lastQuoteInvoicedLicense = (lastQuoteInvoicedLicense == null) ? 0 : lastQuoteInvoicedLicense;
    cpiUplift = (cpiUplift == null) ? 0 : cpiUplift;

    System.debug('***lastQuoteInvoicedLicense '+lastQuoteInvoicedLicense);
    System.debug('***cpiUplift '+cpiUplift);

    return lastQuoteInvoicedLicense * cpiUplift / 100;
  }

  private static Decimal calculateCPISupport(Decimal lastQuoteInvoicedSupport, Decimal cpiUplift){
    System.debug('***calculateCPISupport');

    lastQuoteInvoicedSupport = (lastQuoteInvoicedSupport == null) ? 0 : lastQuoteInvoicedSupport;
    cpiUplift = (cpiUplift == null) ? 0 : cpiUplift;

    System.debug('***lastQuoteInvoicedSupport '+lastQuoteInvoicedSupport);
    System.debug('***cpiUplift '+cpiUplift);

    return lastQuoteInvoicedSupport * cpiUplift / 100;
  }

  private static Decimal calculateDWP(Decimal dwpRenewalQuoteUplift, Decimal cpqDistribution){
    System.debug('***calculateDWP');

    dwpRenewalQuoteUplift = (dwpRenewalQuoteUplift == null) ? 0 : dwpRenewalQuoteUplift;
    cpqDistribution = (cpqDistribution == null) ? 0 : cpqDistribution;

    System.debug('***dwpRenewalQuoteUplift '+dwpRenewalQuoteUplift);
    System.debug('***cpqDistribution '+cpqDistribution);

    return dwpRenewalQuoteUplift * cpqDistribution / 100;
  }

  private static Decimal calculateDWPSupport(Decimal dwpRenewalQuoteUplift, Decimal supportPercent, Decimal cpqDistribution, Decimal supportDistribution){
    System.debug('***calculateDWPSupport');

    dwpRenewalQuoteUplift = (dwpRenewalQuoteUplift == null) ? 0 : dwpRenewalQuoteUplift;
    supportPercent = (supportPercent == null) ? 0 : supportPercent;
    cpqDistribution = (cpqDistribution == null) ? 0 : cpqDistribution;
    supportDistribution = (supportDistribution == null) ? 0 : supportDistribution;

    System.debug('***dwpRenewalQuoteUplift '+dwpRenewalQuoteUplift);
    System.debug('***supportPercent '+supportPercent);
    System.debug('***cpqDistribution '+cpqDistribution);
    System.debug('***supportDistribution '+supportDistribution);

    if(supportDistribution != 0) {
      return dwpRenewalQuoteUplift * supportPercent * cpqDistribution / 10000;
    }else{
      return 0;
    }
  }
}
