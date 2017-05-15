public with sharing class ResourceRequestAssignmentController {

    public Resource_Assignment__c resourceAssignment { get; set;}
    public ResourceRequest__c resourceRequest { get; set;}


    public ResourceRequestAssignmentController(ApexPages.StandardController controller) {

        //let's set the resource request on the object here
        //let's see if it is already set...if not, let's pull it from the request

        String requestID = ApexPages.currentPage().getParameters().get('ResReqID');
        if(requestID != null)
        {  //it is a new role, so let's set it up accordingly
            resourceAssignment = new Resource_Assignment__c();
                
            resourceRequest = [SELECT Id from ResourceRequest__c
                                    WHERE Id = :requestID  LIMIT 1];
                
            resourceAssignment.Resource_Request__c = resourceRequest.Id ;
        }
        else
        { // it is an existing role, so just look it up from the ID
             resourceAssignment = [SELECT Resource_Role__r.Role__c, Note__c, Status__c, User__c, Resource_Request__c, Resource_Role__c FROM Resource_Assignment__c
                   WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
              
           resourceRequest = [SELECT Id from ResourceRequest__c
                                    WHERE Id = :resourceAssignment.Resource_Request__c LIMIT 1];
        }
    }
    
   public PageReference save() {
        upsert resourceAssignment ;
        //return to page for resource request
                
        PageReference reqPage = new ApexPages.StandardController(resourceRequest).view();
        reqPage.setRedirect(true);
        return reqPage ;
    }
    
    public Boolean getIsPresalesManager() {
      return (GWUserProfileHelper.isPresalesManager());
    }


}