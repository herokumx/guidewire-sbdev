public with sharing class ProjectEventController {

    public Project_Event__C thisEvent {get; set;}
    public Boolean reloadFailed {get; set;} 
    public String aId = apexpages.currentpage().getParameters().get('id'); 
    
    public ProjectEventController(ApexPages.StandardController controller) {
         reloadEvent();
    }
    
    public void reloadEvent()
    {
      try{
        thisEvent = [SELECT Id, Name, Project__c, Status__c, 
                            Confirmed_Start_Date__c, Confirmed_End_Date__c,
                            Preparation_Hours__c, Event_Hours__c, Participant_Hours__c,
                            Description__c
                     FROM Project_Event__C
                     WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
         reloadFailed = false;
        }catch(QueryException qe)
        {
         reloadFailed = true;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The project event that you are trying to load has beed deleted and no longer exists in the system.'));

        }
                     
                     
    }
    
    public List<Project_Participant__c> getProjectParticipantsList() {
        List<Project_Participant__c> theList = [SELECT Id, Who__c, Who__r.Name, Description__c, Event_Hours__c, LastModifiedDate ,  Project_Event__c from Project_Participant__c where Project_Event__c = :thisEvent.Id];
    
        return theList ;
    }    

    
    public List<Project_Preparation__c> getProjectPreparationsList() {
        List<Project_Preparation__c> theList = [SELECT Id, Who__c, Who__r.Name, Start__c, End__c, Note__c, Hours__c,LastModifiedDate ,  Project_Event__c from Project_Preparation__c where Project_Event__c = :thisEvent.Id];
    
        return theList ;
    }   
    
    public List<Project_Event_Possible_Date__c> getAllPossibleDatesList() {
       //need to query to get the date counts
  
        List<Project_Event_Possible_Date__c> pd = [SELECT Id, Name, Start_Date__c, End_Date__c,Event_Hours__c, Note__c, Status__c, LastModifiedDate  FROM Project_Event_Possible_Date__c where Project_Event__c = :thisEvent.Id ORDER BY Start_Date__c ];                
        return pd;
    } 

    public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
    }
        
 @RemoteAction
    public static String deleteParticipant(String commitID, String eventID)
    {
  
        Project_Participant__c toDelete = [SELECT Id FROM Project_Participant__c where Id = :commitID];
        if(toDelete != null)
        {
            delete toDelete;  
            //save this event to make sure it recalcs hours
             Project_Event__c eventToSave = [SELECT Id, Name, Project__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Preparation_Hours__c, Event_Hours__c, Participant_Hours__c,
                    Description__c
             FROM Project_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }

        }
        return 'Success';
    }
    
    @RemoteAction
    public static String deletePreparation(String prepID, String eventID)
    {
  
        Project_Preparation__c toDelete = [SELECT Id FROM Project_Preparation__c where Id = :prepID];
        if(toDelete != null)
        {
            delete toDelete;        
            //save this event to make sure it recalcs hours
            Project_Event__c eventToSave = [SELECT Id, Name, Project__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Preparation_Hours__c, Event_Hours__c, Participant_Hours__c,
                    Description__c
             FROM Project_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }
        }
        return 'Success';
    }

    @RemoteAction
    public static String requestReview(String eventID, String messageText)
    {
        //
        System.Debug(' &&&&&&&&&&&&&  Requesting Review of ' + eventID);
        
                
        String communityId = null;
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        String userToMention = UserInfo.getUserId(); //'005xx000001TDn3' //need to have multiple
        String subjectId = eventId;
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = messageText + '\n';  //'Please review this event to make sure your information is correct.\n';
        messageInput.messageSegments.add(textSegment);
        
        //need to loop over the customer commitments and preprataions to get the unique set of people
        Set<Id> usersToMention = new Set<Id>();
        List<Project_Preparation__c> theList = [SELECT Who__c, Who__r.Name from Project_Preparation__c where Project_Event__c = :eventId];
        for(Project_Preparation__c thePrepItem : theList)
        {
            if(thePrepItem.Who__c != null)
            {
                usersToMention.add(thePrepItem.Who__c);            
            }
        }
        
        List<Project_Participant__c> theCommitmentList = [SELECT Who__c, Who__r.Name from Project_Participant__c where Project_Event__c = :eventId];
        for(Project_Participant__c theCommitmentItem : theCommitmentList)
        {
            if(theCommitmentItem.Who__c != null)
            {
                usersToMention.add(theCommitmentItem.Who__c);            
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
     
    @RemoteAction
    public static String selectDate(String dateID, String eventID)
    {        
        Project_Event_Possible_Date__c possDate = [SELECT Id,Status__c, Start_Date__c, End_Date__c,Event_Hours__c, Project_Event__c from Project_Event_Possible_Date__c WHERE Id = :dateID  LIMIT 1];
        possDate.Status__c = 'Selected';
        update possDate;
        
        //now mark all other pending as not selected
        Project_Event_Possible_Date__c[] otherDates = [SELECT Id,Status__c, Project_Event__c  from Project_Event_Possible_Date__c  WHERE Project_Event__c = :possDate.Project_Event__c and Status__c = 'Possible'];
        for( Project_Event_Possible_Date__c thisDate : otherDates)
        {
            thisDate.Status__c = 'Not Selected';
        }
        update otherDates;
        
        //now copy values from this date to the event
        Project_Event__c theEvent = [SELECT Id, Status__c, Confirmed_Start_Date__c,Event_Hours__c, Confirmed_End_Date__c from Project_Event__c WHERE Id = :eventID LIMIT 1];
        theEvent.Status__c = 'Confirmed';
        theEvent.Confirmed_Start_Date__c = possDate.Start_Date__c;
        theEvent.Confirmed_End_Date__c = possDate.End_Date__c;
        theEvent.Event_Hours__c = possDate.Event_Hours__c;
        update theEvent;
        
        //post to chatter that a date was selected
        FeedItem post = new FeedItem();
        post.ParentId = eventID; 
//        post.CreatedById = getIdOfAnnouncmentUser();
        post.Body = 'Date selected for this event.';
        insert post;
        
        
        return 'Success';
    }

}