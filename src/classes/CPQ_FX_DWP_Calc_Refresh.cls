public with sharing class CPQ_FX_DWP_Calc_Refresh {
  //Apex properties or variables

  public Id Id { get; set; }
  public SBQQ__Quote__c quote { get; set; }

  //constructor to get the quote record
  public CPQ_FX_DWP_Calc_Refresh(ApexPages.StandardController controller) {
    quote = (SBQQ__Quote__c) controller.getRecord();
    Id = quote.Id;
    System.debug('The quote record: ' + quote);
    quote = [SELECT Id, SBQQ__Opportunity2__c, CPQ_Quote_Currency_to_USD_Conversion__c, CPQ_USD_to_Quote_Currency_Conversion__c FROM SBQQ__Quote__c WHERE Id = :Id];
  }

  //Method to refresh the FX DWP Calculation on demand
  public PageReference refreshFX() {
    System.debug('Quote Id: ' + Id);
    //perform the calculation
    CPQ_FX_DWP_Calc_Helper.UpdateFX(quote);
    PageReference pageRef = new PageReference('/'+Id);
    pageRef.setRedirect(true);
    return pageRef; //Returns to the quote page
  }
}
