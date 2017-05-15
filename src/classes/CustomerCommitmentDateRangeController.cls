public with sharing class CustomerCommitmentDateRangeController {

    public Customer_Commitment_Date_Range__c dateRange{get;set;}
    public Customer_Commitment__c customerCommitment{get;set;}


    public CustomerCommitmentDateRangeController(ApexPages.StandardController controller) {
        String custCommitmentID = ApexPages.currentPage().getParameters().get('CustomerCommitmentID');
        if(custCommitmentID!= null)
        {//it is a new commitment, so let's set it up accordingly
            dateRange = new Customer_Commitment_Date_Range__c();
                
            customerCommitment = [SELECT Id from Customer_Commitment__c
                                        WHERE Id = :custCommitmentID LIMIT 1];
                    
            dateRange.Customer_Commitment__c = customerCommitment.Id ;        
        }
        else
        { //it already exists, so look it up from the ID
              dateRange = [SELECT Id,  Start__c, End__c, Note__c, Customer_Commitment__c
                                     FROM Customer_Commitment_Date_Range__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

              customerCommitment = [SELECT Id from Customer_Commitment__c
                                        WHERE Id = :dateRange.Customer_Commitment__c LIMIT 1];
        }

    }

     public PageReference save() {
       try{  
        upsert dateRange;
       } catch(DMLException e){
//           ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, e.getdmlMessage(0) );
//           ApexPages.addMessage(msg);
           return null;
       }     
      //need to recalc event hours so save salesEvent now
       update customerCommitment;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(customerCommitment).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }

}