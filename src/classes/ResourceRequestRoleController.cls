public with sharing class ResourceRequestRoleController {

    public Resource_Role__c resourceRole { get; set;}
    public Resource_Role__c resourceRoleOriginal { get; set;}
    public ResourceRequest__c resourceRequest { get; set;}

    public ResourceRequestRoleController(ApexPages.StandardController controller) {
        //let's set the resource request on the object here
        //let's see if it is already set...if not, let's pull it from the request

        String requestID = ApexPages.currentPage().getParameters().get('ResReqID');
        if(requestID != null)
        {  //it is a new role, so let's set it up accordingly
            resourceRole = new Resource_Role__c();
                
            resourceRequest = [SELECT Id, FeedAnnouncementID__c from ResourceRequest__c
                                    WHERE Id = :requestID  LIMIT 1];
                
            resourceRole.Resource_Request__c = resourceRequest.Id ;
        }
        else
        { // it is an existing role, so just look it up from the ID
             resourceRole = [SELECT Role__c, Status__c, Note__c, Resource_Request__c FROM Resource_Role__c
                   WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
              
           resourceRequest = [SELECT Id, FeedAnnouncementID__c from ResourceRequest__c
                                    WHERE Id = :resourceRole.Resource_Request__c LIMIT 1];
        }
        resourceRoleOriginal = resourceRole.clone(); // Copy
        
    }
    
   public PageReference save() {
        upsert resourceRole ;
        //need to save the resource request in order to recalculate the role string (that is used in the feed)
        update resourceRequest;
        
        String comment = '';
        if(resourceRoleOriginal.Role__c == null) //is new role
        {
                //if the request is open, then we should announce the change of the role
            if(resourceRequest.FeedAnnouncementID__c != null)
            {
                FeedComment fcomment = new FeedComment();
                fcomment.FeedItemId = resourceRequest.FeedAnnouncementID__c; 
                fcomment.CommentBody = resourceRole.Role__c  + ' role has been added to the request.\nStatus:' + resourceRole.Status__c  + '.';
                if(resourceRole.Note__c != null) 
                {
                    fcomment.CommentBody = fcomment.CommentBody + '\nNote: ' + resourceRole.Note__c;
                }
                insert fcomment;
                
            }
        }
        else // is old role
        {
            if((resourceRole.Status__c != resourceRoleOriginal.Status__c || resourceRole.Note__c != resourceRoleOriginal.Note__c) && resourceRequest.FeedAnnouncementID__c != null)
            {
                FeedComment fcomment = new FeedComment();
                fcomment.FeedItemId = resourceRequest.FeedAnnouncementID__c; 
                fcomment.CommentBody = resourceRole.Role__c  + ' role has been updated.';
                if(resourceRole.Status__c != resourceRoleOriginal.Status__c )
                {
                    fcomment.CommentBody = fcomment.CommentBody + '\nStatus is now: ' + resourceRole.Status__c;                    
                }
                if(resourceRole.Note__c != resourceRoleOriginal.Note__c )
                {
                    fcomment.CommentBody = fcomment.CommentBody + '\nNote is now: ' + resourceRole.Note__c;                    
                }
                insert fcomment;
                
            }
        
        }
        
                
        //return to page for resource request                
        PageReference reqPage = new ApexPages.StandardController(resourceRequest).view();
        reqPage.setRedirect(true);
        return reqPage ;
    }

}