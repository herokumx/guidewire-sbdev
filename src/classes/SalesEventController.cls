global with sharing class SalesEventController {

    public Sales_Event__C thisEvent {get; set;}
    public Boolean reloadFailed {get; set;} 
    public Boolean displayDelete{get; set;} 
    Public String SalesEventid{get;set;}
    Public String strdelsaleseventfeedbackId{get;set;}
    Public List<SalesEventFeedbackWrapper> lstSalesEventFeedback = new List<SalesEventFeedbackWrapper>();
    Public List<SalesEventFeedbackWrapper> getlstSalesEventFeedback(){
    return lstSalesEventFeedback;
    }
    public String aId = apexpages.currentpage().getParameters().get('id'); 
    
    public SalesEventController(ApexPages.StandardController controller) {
        if(aId!=null){
        SalesEventid = aId; 
        }
        reloadEvent();
        lstSalesEventFeedback.clear();
        User usr = [Select Id,Name,Profile.Name from user where id=:UserInfo.getUserId() limit 1];
        
        //By Rakshik 14th July 2014
        List<PermissionSet> permissionSetList = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Presales_Manager_Sales_Event_Feedback' LIMIT 1];
        List<PermissionSetAssignment> permissionSetAssignmentList = new List<PermissionSetAssignment>();
        if( !permissionSetList.isEmpty())
            permissionSetAssignmentList = [SELECT AssigneeId,PermissionSetId FROM PermissionSetAssignment Where PermissionSetId = :permissionSetList[0].Id AND AssigneeId = :usr.Id LIMIT 1];     
        //End
         
         
        //Added PermissionSet and Profiles Condition
        if(usr.Profile.Name=='GW Presales Management' || usr.Profile.Name=='System Administrator' || !permissionSetAssignmentList.isEmpty()){
        displayDelete=true;
        //for(Sales_Event_Feedback__c sef:[Select Id,Name,CreatedBy.Name,CreatedDate,CreatedById,Domain_Expertise_Section_Score__c,Selling_Skill_Section_Score__c,Total_Feedback_Score__c,Total_Negative_Answers__c,Presentation_Section_Score__c from Sales_Event_Feedback__c where Sales_Event__c=:ApexPages.currentPage().getParameters().get('id')]){
        for(Sales_Event_Feedback__c sef:[Select Id,Name,CreatedBy.Name,CreatedDate,CreatedById,Domain_Expertise_Section_Score__c,Selling_Skill_Section_Score__c,Total_Feedback_Score__c,Total_Negative_Answers__c,Presentation_Section_Score__c from Sales_Event_Feedback__c where Sales_Event__c=:aId]){
        SalesEventFeedbackWrapper sefw = new SalesEventFeedbackWrapper();
        sefw.strCreatedBy = sef.CreatedBy.Name;
        sefw.strCreatedById = sef.CreatedById;
        // By Rakshit 15th July 2014
        sefw.strCreatedDate = sef.CreatedDate;
        //sefw.strCreatedDate = sef.CreatedDate.format('MM/dd/yyyy HH:mm:ss','America/New_York')+'';
        //End Here
        sefw.strTotalFeedbackStore = sef.Total_Feedback_Score__c+'';
        sefw.strTotalNegativeAnswer = sef.Total_Negative_Answers__c+'';
        sefw.strPresentationSectionScore = sef.Presentation_Section_Score__c+'' ;
        sefw.strDomainExpertiseSectionScore = sef.Domain_Expertise_Section_Score__c+'';
        sefw.strSellingSkillSectionScore = sef.Selling_Skill_Section_Score__c+'';
        sefw.strRecordId = sef.Id;
        lstSalesEventFeedback.add(sefw);
        }
        } else {
        displayDelete=false;
        for(Sales_Event_Feedback__c sef:[Select Id,Name,CreatedById,CreatedBy.Name,CreatedDate,Domain_Expertise_Section_Score__c,Selling_Skill_Section_Score__c,Total_Feedback_Score__c,Total_Negative_Answers__c,Presentation_Section_Score__c from Sales_Event_Feedback__c where Sales_Event__c=:ApexPages.currentPage().getParameters().get('id') and CreatedById=:UserInfo.getUserId()]){
        SalesEventFeedbackWrapper sefw = new SalesEventFeedbackWrapper();
        sefw.strCreatedBy = sef.CreatedBy.Name;
        sefw.strCreatedById = sef.CreatedById;
        // By Rakshit 15th July 2014
        sefw.strCreatedDate = sef.CreatedDate;
        //sefw.strCreatedDate = sef.CreatedDate.format('MM/dd/yyyy HH:mm:ss','America/New_York')+'';
        //End Here
        sefw.strTotalFeedbackStore = sef.Total_Feedback_Score__c+'';
        sefw.strTotalNegativeAnswer = sef.Total_Negative_Answers__c+'';
        sefw.strPresentationSectionScore = sef.Presentation_Section_Score__c+'' ;
        sefw.strDomainExpertiseSectionScore = sef.Domain_Expertise_Section_Score__c+'';
        sefw.strSellingSkillSectionScore = sef.Selling_Skill_Section_Score__c+'';
        sefw.strRecordId = sef.Id;
        lstSalesEventFeedback.add(sefw);
        }
         }
    }
    Public pagereference DeleteSaleEventFeedback(){
       system.debug('Working del'+strdelsaleseventfeedbackId);
       if(strdelsaleseventfeedbackId!=null){
         Sales_Event_Feedback__c saaa = new Sales_Event_Feedback__c ();
          saaa.Id =  strdelsaleseventfeedbackId;
          delete saaa;
          }
          PageReference pr = new PageReference('/apex/SalesEvent?id='+SalesEventid);
           return pr ;
         }
    public void reloadEvent()
    {
      try{
        thisEvent = [SELECT Id, Name, Event_Goals__c,Event_Type__c, Opportunity__c, Status__c, 
                            Confirmed_Start_Date__c, Confirmed_End_Date__c, Presentation_Type__c, 
                            Location__c, Preparation_Hours__c, Event_Hours__c, Customer_Hours__c,Demo_team_Hours__c,
                            Description__c, RFx_Received__c, RFx_Internal_Due__c, RFx_External_Due__c, success_indicator__c, Success_Indicator_temp__c 
                     FROM Sales_Event__C
                     WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
         reloadFailed = false;
        }catch(QueryException qe)
        {
         reloadFailed = true;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The sales event that you are trying to load has beed deleted and no longer exists in the system.'));

        }
                     
                     
    }
    public pagereference openFeedbackPage()
    {
        pagereference p=new pagereference('/apex/SalesEventFeedback?SalesEventId='+thisEvent.id);
        
        p.setredirect(true);
        return p;
    }
    public PageReference save() {
        update thisEvent;
        reloadEvent();
        return null;
    }

    public PageReference cancel() {    
        //cancel method to return to the account detail page
        return new PageReference('/'+aId);
    }

    public Boolean getIsSalesOrPresalesManager() {
      return (GWUserProfileHelper.isSales() || GWUserProfileHelper.isPresalesManager());
    }

    public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
    }


    public List<Customer_Commitment__c> getCustomerCommitmentsList() {
        List<Customer_Commitment__c> theList = [SELECT Id, Who__c, Who__r.Name, Coverage_Area__c, Description__c, Event_Hours__c, LastModifiedDate ,  Sales_Event__c from Customer_Commitment__c where Sales_Event__c = :thisEvent.Id];
    
        return theList ;
    }    

    
    public List<Preparation__c> getPreparationsList() {
        List<Preparation__c> theList = [SELECT Id, Who__c, Who__r.Name, Start__c, End__c, Note__c, Hours__c,LastModifiedDate ,  Sales_Event__c from Preparation__c where Sales_Event__c = :thisEvent.Id];
    
        return theList ;
    } 
    
    public List<Demo_Team__c> getDemoteamsList() {
        List<Demo_Team__c> theList = [SELECT Id, Name, Start__c, End__c, Note__c, Hours__c, LastModifiedDate , Sales_Event__c from Demo_Team__c where Sales_Event__c = :thisEvent.Id];
    
        return theList ;
    }  

    public List<Event_Possible_Date__c> getAllPossibleDatesList() {
        //need to query to get the date counts
  
        List<Event_Possible_Date__c> pd = [SELECT Id, Name, Start_Date__c, End_Date__c,Event_Hours__c, Note__c, Status__c,Date_is_Flexible__c, LastModifiedDate  FROM Event_Possible_Date__c where Sales_Event__c = :thisEvent.Id ORDER BY Start_Date__c ];                
        return pd;
    }


    @RemoteAction
    global static String deleteCommitment(String commitID, String eventID)
    {
  
        Customer_Commitment__c toDelete = [SELECT Id FROM Customer_Commitment__c where Id = :commitID];
        if(toDelete != null)
        {
            delete toDelete;  
            //save this event to make sure it recalcs hours
             Sales_Event__c eventToSave = [SELECT Id, Name, Event_Type__c, Opportunity__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Presentation_Type__c, 
                    Location__c, Preparation_Hours__c, Event_Hours__c, Customer_Hours__c,Demo_team_Hours__c,
                    Description__c
             FROM Sales_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }

        }
        return 'Success';
    }
    
    @RemoteAction
    global static String deletePreparation(String prepID, String eventID)
    {
  
        Preparation__c toDelete = [SELECT Id FROM Preparation__c where Id = :prepID];
        if(toDelete != null)
        {
            delete toDelete;        
            //save this event to make sure it recalcs hours
             Sales_Event__c eventToSave = [SELECT Id, Name, Event_Type__c, Opportunity__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Presentation_Type__c, 
                    Location__c, Preparation_Hours__c, Event_Hours__c, Customer_Hours__c,Demo_team_Hours__c,
                    Description__c
             FROM Sales_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }
        }
        return 'Success';
    }
    
    @RemoteAction
    global static String deleteDemoTeam(String teamID, String eventID)
    {
  
        Demo_Team__c toDelete = [SELECT Id FROM Demo_Team__c where Id = :teamID];
        if(toDelete != null)
        {
            delete toDelete;        
            //save this event to make sure it recalcs hours
             Sales_Event__c eventToSave = [SELECT Id, Name, Event_Type__c, Opportunity__c, Status__c, 
                    Confirmed_Start_Date__c, Confirmed_End_Date__c, Presentation_Type__c, 
                    Location__c, Preparation_Hours__c, Event_Hours__c, Customer_Hours__c,Demo_team_Hours__c,
                    Description__c
             FROM Sales_Event__c
             WHERE Id = :eventID LIMIT 1];
             if(eventToSave != null)
             {
                 update eventToSave;
             }
        }
        return 'Success';
    }   

    @RemoteAction
    global static String requestReview(String eventID, String messageText)
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
        List<Preparation__c> theList = [SELECT Who__c, Who__r.Name from Preparation__c where Sales_Event__c = :eventId];
        for(Preparation__c thePrepItem : theList)
        {
            if(thePrepItem.Who__c != null)
            {
                usersToMention.add(thePrepItem.Who__c);            
            }
        }
        
        List<Customer_Commitment__c> theCommitmentList = [SELECT Who__c, Who__r.Name from Customer_Commitment__c where Sales_Event__c = :eventId];
        for(Customer_Commitment__c theCommitmentItem : theCommitmentList)
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
    global static String selectDate(String dateID, String eventID)
    {        
        Event_Possible_Date__c possDate = [SELECT Id,Status__c, Start_Date__c, End_Date__c,Event_Hours__c, Sales_Event__c from Event_Possible_Date__c WHERE Id = :dateID  LIMIT 1];
        possDate.Status__c = 'Selected';
        update possDate;
        
        //now mark all other pending as not selected
        Event_Possible_Date__c[] otherDates = [SELECT Id,Status__c, Sales_Event__c  from Event_Possible_Date__c  WHERE Sales_Event__c = :possDate.Sales_Event__c and Status__c = 'Possible'];
        for( Event_Possible_Date__c thisDate : otherDates)
        {
            thisDate.Status__c = 'Not Selected';
        }
        update otherDates;
        
        //now copy values from this date to the event
        Sales_Event__c theEvent = [SELECT Id, Status__c, Confirmed_Start_Date__c,Event_Hours__c, Confirmed_End_Date__c from Sales_Event__c WHERE Id = :eventID LIMIT 1];
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

    //commented by RB  as no longer needed 10th July 2014
    /*private static Id getIdOfAnnouncmentUser()
    {
        User theUser = [SELECT Id from User where Name='Announcement' LIMIT 1];
        return theUser.Id;
    }*/
   Public Class SalesEventFeedbackWrapper{
   Public String strCreatedBy{get;set;}
   Public String strCreatedById{get;set;}
   //Public String strCreatedDate{get;set;}
   Public DateTime strCreatedDate{get;set;}
   Public String strTotalFeedbackStore{get;set;}
   Public String strTotalNegativeAnswer{get;set;}
   Public String strPresentationSectionScore{get;set;}
   Public String strDomainExpertiseSectionScore{get;set;}
   Public String strSellingSkillSectionScore{get;set;} 
   Public String strRecordId{get;set;} 
   }
}