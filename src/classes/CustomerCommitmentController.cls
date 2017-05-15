public with sharing class CustomerCommitmentController {

    public Customer_Commitment__c customerCommitment {get;set;}
    public Customer_Commitment__c customerCommitmentOriginal {get;set;}
    public Sales_Event__c salesEvent {get;set;}
    public Boolean isNew {get;set;}

    public CustomerCommitmentController(ApexPages.StandardController controller) {

        //let's set the resource request on the object here
        //let's see if it is already set...if not, let's pull it from the request
        isNew = false;
        String salesEventID= ApexPages.currentPage().getParameters().get('SalesEventID');
        if(salesEventID!= null)
        {//it is a new commitment, so let's set it up accordingly
            isNew = true;
            customerCommitment = new Customer_Commitment__c();
                
            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :salesEventID LIMIT 1];
                    
            customerCommitment.Sales_Event__c = salesEvent.Id ;
            //let's default it the current user
            customerCommitment.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              customerCommitment  = [SELECT Id, Name, Who__c, Coverage_Area__c, Description__c, Event_Hours__c, Sales_Event__c,
                                      (SELECT Start__c, End__C, Note__C from Date_Ranges__r)
                                     FROM Customer_Commitment__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :customerCommitment.Sales_Event__c LIMIT 1];
        }
        customerCommitmentOriginal = customerCommitment.clone(); // Copy
    }
    
    

   public List<Customer_Commitment_Date_Range__c> getAllDateRanges()
   {
       List<Customer_Commitment_Date_Range__c> drs = [SELECT Start__c, End__C, Note__C, Customer_Commitment__c from Customer_Commitment_Date_Range__c where Customer_Commitment__c = :customerCommitment.Id];
        return drs;
   }
    
        
   public PageReference save() {
        upsert customerCommitment;
        //return to page for resource request
  
      //need to recalc event hours so save salesEvent now
       update salesEvent;
  
       PageReference reqPage = new ApexPages.StandardController(salesEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
    
    @RemoteAction
    public static String deleteDateRange(String rangeID, String commitID)
    {
        Customer_Commitment_Date_Range__c toDelete = [SELECT Id FROM Customer_Commitment_Date_Range__c where Id = :rangeID];
        if(toDelete != null)
        {
            delete toDelete;  

        }

        return 'success';
    }

}