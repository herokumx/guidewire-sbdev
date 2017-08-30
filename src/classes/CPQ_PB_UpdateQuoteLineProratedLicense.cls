public with sharing class CPQ_PB_UpdateQuoteLineProratedLicense {
  /*
     update quote line items Prorated License and Support - invoked by process builder 'Update QuoteLine When Quote Changes'
   */
  @InvocableMethod(label='Update LineItems Prorated License' description='Update LineItems Prorated License')
  public static void updateProratedLicense(List<Id> quoteIds){
    System.debug('***updateProratedLicense');
    System.debug('***quoteIds[0] '+quoteIds[0]);

    SBQQ__Quote__c quote = [SELECT Id, CPQ_Prorated_Start_Date__c, SBQQ__StartDate__c FROM SBQQ__Quote__c WHERE Id =: quoteIds[0]];
    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, CPQ_Prorated_License_Ramp_Up_Total__c, CPQ_Prorated_Support_Ramp_Up_Total__c, CPQ_Year_1_Net_Amount__c, Year_1_Support_Ramp_Up_Total__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteIds[0]];

    for(SBQQ__QuoteLine__c quoteline : quoteLineList) {
      quoteline.CPQ_Prorated_License_Ramp_Up_Total__c = calculateLicense(quote.CPQ_Prorated_Start_Date__c, quote.SBQQ__StartDate__c, quoteline.CPQ_Year_1_Net_Amount__c);
      quoteline.CPQ_Prorated_Support_Ramp_Up_Total__c = calculateSupport(quote.CPQ_Prorated_Start_Date__c, quote.SBQQ__StartDate__c, quoteline.Year_1_Support_Ramp_Up_Total__c);
    }

    update quoteLineList;

    return;
  }

  private static Decimal calculateLicense(Date proratedStartDate, Date startDate, Decimal annualNetAmount){
    System.debug('***calculateLicense');

    if(proratedStartDate != null && startDate != null) {
      return annualNetAmount / 365.4 * proratedStartDate.daysBetween(startDate);
    }else{
      return 0;
    }
  }

  private static Decimal calculateSupport(Date proratedStartDate, Date startDate, Decimal annualMaintenanceCost){
    System.debug('***calculateCPI');

    if(proratedStartDate != null && startDate != null) {
      return annualMaintenanceCost / 365.4 * proratedStartDate.daysBetween(startDate);
    }else{
      return 0;
    }
  }
}
