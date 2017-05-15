public with sharing class ResourceHoldController {

    public Resource_Hold__c resourceHold {get;set;}
    public Resource_Hold__c resourceHoldOriginal {get;set;}
    public ResourceRequest__c resourceRequest {get;set;}


    public ResourceHoldController(ApexPages.StandardController controller) {
        //let's set the resource request on the object here
        //let's see if it is already set...if not, let's pull it from the request

        String resourceRequestID= ApexPages.currentPage().getParameters().get('ResReqID');
        if(resourceRequestID != null)
        {//it is a new hold, so let's set it up accordingly
            resourceHold = new Resource_Hold__c();
                
            resourceRequest = [SELECT Id from ResourceRequest__c 
                                        WHERE Id = :resourceRequestID LIMIT 1];
                    
            resourceHold.Resource_Request__c = resourceRequest.Id ;
            //let's default it the current user
            resourceHold.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              resourceHold = [SELECT Id, Who__c, Coverage_Area__c, Description__c, Resource_Request__c
                                     FROM Resource_Hold__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            resourceRequest = [SELECT Id from ResourceRequest__c 
                                        WHERE Id = :resourceHold.Resource_Request__c LIMIT 1];
        }
        resourceHoldOriginal = resourceHold.clone(); // Copy



    }
    
   public PageReference save() {
        upsert resourceHold;
        //return to page for resource request
  
      //need to recalc event hours so save salesEvent now
      // update resourceRequest;
  
       PageReference reqPage = new ApexPages.StandardController(resourceRequest).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }    

}