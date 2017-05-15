public with sharing class SalesSupportRequestController {

    public Sales_Support_Request__C thisRequest {get; set;}
    public Boolean reloadFailed {get; set;} 

    public String aId = apexpages.currentpage().getParameters().get('id'); 

    public SalesSupportRequestController(ApexPages.StandardController controller) {
        reloadRequest();
    }

    public void reloadRequest()
    {
        
      try{
        thisRequest = [SELECT Id, Name, Type__c, Opportunity__c, Account__c, Campaign__c, Stage__c, 
                              Actual_Completion_Date__c,Requested_Completion_Date__c, Target_Completion_Date__c,
                              Assigned_To__c, Create_Date__c, Description__c, Hours__c, Status__c
                       FROM Sales_Support_Request__c
                       WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
        
         reloadFailed = false;
        }catch(QueryException qe)
        {
         reloadFailed = true;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The sales support request that you are trying to load has beed deleted and no longer exists in the system.'));
        }
                     
                     
    }

    public PageReference save() {
        update thisRequest;
        reloadRequest();
        return null;
    }

    public PageReference cancel() {    
        //cancel method to return to the detail page
        return new PageReference('/'+aId);
    }

    public Boolean getIsSalesOrPresalesManager() {
      return (GWUserProfileHelper.isSales() || GWUserProfileHelper.isPresalesManager());
    }

    public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
    }

    public List<Support_Request_Preparation__c> getPreparationsList() {
        List<Support_Request_Preparation__c> theList = [SELECT Id, Who__c, Who__r.Name, Start__c, End__c, Note__c, Hours__c,LastModifiedDate ,  Sales_Support_Request__c from Support_Request_Preparation__c where Sales_Support_Request__c = :thisRequest.Id];
    
        return theList ;
    }    

    @RemoteAction
    public static String completeRequest(String reqId)
    {
                Sales_Support_Request__c theRequest = [SELECT Id, Name, Type__c, Opportunity__c, Account__c, Campaign__c,
                              Actual_Completion_Date__c,Requested_Completion_Date__c, Target_Completion_Date__c,
                              Assigned_To__c, Create_Date__c, Description__c, Hours__c, Status__c, Stage__c
                       FROM Sales_Support_Request__c
                       WHERE Id = :reqId LIMIT 1];

            theRequest.Actual_Completion_Date__c = Date.today();
            theRequest.Status__c = 'Completed';
            
            upsert theRequest;
            
            return 'Success';

    }

    @RemoteAction
    public static String deletePreparation(String prepID, String eventID)
    {
  
        Support_Request_Preparation__c toDelete = [SELECT Id FROM Support_Request_Preparation__c where Id = :prepID];
        if(toDelete != null)
        {
            delete toDelete;        
            //save this event to make sure it recalcs hours
 /*            Sales_Event__c eventToSave = [SELECT Id, Name, Event_Type__c, Opportunity__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Presentation_Type__c, 
                    Location__c, Preparation_Hours__c, Event_Hours__c, Customer_Hours__c,
                    Description__c
             FROM Sales_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }
   */     }
        return 'Success';
    }

    @RemoteAction
    public static String requestReview(String requestID, String messageText)
    {
        //
        System.Debug(' &&&&&&&&&&&&&  Requesting Review of ' + requestID);
        
                
        String communityId = null;
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        String userToMention = UserInfo.getUserId(); //'005xx000001TDn3' //need to have multiple
        String subjectId = requestID;
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = messageText + '\n';  //'Please review this event to make sure your information is correct.\n';
        messageInput.messageSegments.add(textSegment);
        
        //need to loop over the customer commitments and preprataions to get the unique set of people
        Set<Id> usersToMention = new Set<Id>();
        List<Support_Request_Preparation__c> theList = [SELECT Who__c, Who__r.Name from Support_Request_Preparation__c where Sales_Support_Request__c = :requestId];
        for(Support_Request_Preparation__c thePrepItem : theList)
        {
            if(thePrepItem.Who__c != null)
            {
                usersToMention.add(thePrepItem.Who__c);            
            }
        }        

        for(Id theUserToMention : usersToMention)
        {
        
            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = theUserToMention;
            messageInput.messageSegments.add(mentionSegment);
                
        }
        
//        textSegment = new ConnectApi.TextSegmentInput();
//        textSegment.text = 'Please review this request.';
//        messageInput.messageSegments.add(textSegment);
        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        
        ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
                
        return 'Success';
    }   


}