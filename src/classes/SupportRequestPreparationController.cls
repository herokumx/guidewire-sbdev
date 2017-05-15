public with sharing class SupportRequestPreparationController {

    public Support_Request_Preparation__c preparation {get;set;}
    public Support_Request_Preparation__c preparationOriginal {get;set;}
    public Sales_Support_Request__c salesSupportRequest {get;set;}


    public SupportRequestPreparationController(ApexPages.StandardController controller) {
        //let's see if it is already set...if not, let's pull it from the event

        String requestID= ApexPages.currentPage().getParameters().get('RequestID');
        if(requestID!= null)
        {//it is a new commitment, so let's set it up accordingly
            preparation = new Support_Request_Preparation__c();
                
            salesSupportRequest = [SELECT Id from Sales_Support_Request__c
                                        WHERE Id = : requestID LIMIT 1];
                    
            preparation.Sales_Support_Request__c = salesSupportRequest.Id ;
            //let's default it the current user
            preparation.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              preparation = [SELECT Id, Who__c, Hours__c, Start__c, End__c, Note__c, Sales_Support_Request__c
                                     FROM Support_Request_Preparation__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            salesSupportRequest = [SELECT Id from Sales_Support_Request__c
                                        WHERE Id = : preparation.Sales_Support_Request__c LIMIT 1];
        }
        preparationOriginal = preparation.clone(); // Copy


    }
    
     public PageReference save() {
        upsert preparation;
    
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(salesSupportRequest).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
    

}