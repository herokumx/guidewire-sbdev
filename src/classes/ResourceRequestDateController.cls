public with sharing class ResourceRequestDateController {

    public Possible_Date__c possibleDate{ get; set;}
    public Possible_Date__c possibleDateOriginal{ get; set;}
    public ResourceRequest__c resourceRequest { get; set;}


    public ResourceRequestDateController(ApexPages.StandardController controller) {
        String requestID = ApexPages.currentPage().getParameters().get('ResReqID');
        if(requestID != null)
        {  //it is a new role, so let's set it up accordingly
            possibleDate = new Possible_Date__c();
                
            resourceRequest = [SELECT Id, FeedAnnouncementID__c from ResourceRequest__c
                                    WHERE Id = :requestID  LIMIT 1];
                
            possibleDate.Resource_Request__c = resourceRequest.Id ;
        }
        else
        { // it is an existing role, so just look it up from the ID
             possibleDate = [SELECT Id, Start_Date__c, End_Date__c, Status__c, Note__c,Event_Hours__c,Date_is_Flexible__c, Resource_Request__c FROM Possible_Date__c
                   WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
              
           resourceRequest = [SELECT Id, FeedAnnouncementID__c from ResourceRequest__c
                                    WHERE Id = :possibleDate.Resource_Request__c LIMIT 1];
        }
        possibleDateOriginal = possibleDate.clone();
    }
    
   public PageReference save() {
   
       try{
     
          upsert possibleDate;
       } catch(DMLException e){
//           ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, e.getdmlMessage(0) );
//           ApexPages.addMessage(msg);
           return null;
       }        
        //update the feed of the request with the information
        if(possibleDateOriginal.Start_Date__c == null) //is new possible date
        {
                //if the request is open, then we should announce the added date
            if(resourceRequest.FeedAnnouncementID__c != null)
            {
                FeedComment fcomment = new FeedComment();
                fcomment.FeedItemId = resourceRequest.FeedAnnouncementID__c; 
                fcomment.CommentBody = 'A new date has been added to the request.';
                insert fcomment;
                
            }
        }
        else // is old role
        {
            if(resourceRequest.FeedAnnouncementID__c != null)
            {
                FeedComment fcomment = new FeedComment();
                fcomment.FeedItemId = resourceRequest.FeedAnnouncementID__c; 
                fcomment.CommentBody = 'A date has been updated on the request.';
                insert fcomment;
            }
        }
        //return to page for resource request
        PageReference reqPage = new ApexPages.StandardController(resourceRequest).view();
        reqPage.setRedirect(true);
        return reqPage ;
    }
    
    

}