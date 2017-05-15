public with sharing class ResourceRequestController {

    public ResourceRequest__c resourceRequest { get; set;}
    public Map<Id,String> possibleDateLabelsMap {get; set;} 
    public Boolean reloadFailed {get; set;} 

    public Boolean RFxDatesSetOnNonRFx{get; set;}


    public Boolean roleBeingEdited {get; set;}

    public Resource_Role__c availabilityRole{ get; set;}
    public User availabilityFor { get; set;}

    public String aId = apexpages.currentpage().getParameters().get('id'); 
    
    public List<ResourceRequestController.cResourceAssignment> lastReturnedList{get; set;} // = new List<ResourceRequestController.cResourceAssignment>();

    public PageReference save() {
        update resourceRequest ;
        return null;
    }

    public PageReference cancel() {
    
    //cancel method to return to the account detail page
    return new PageReference('/'+aId);
    }
        
    public ResourceRequestController() {
        reloadRequest();
    }
    
    public ResourceRequestController(ApexPages.StandardController stdController) {
        reloadRequest();
    }
    
        
    public void reloadRequest()
    {
      try{
        resourceRequest = [SELECT Id, Name, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Region__c, CreatedById, CreatedDate,  LastModifiedById, LastModifiedDate, 
                                  RFx_Received__c, RFx_Internal_Due__c, RFx_External_Due__c,event_goals__c  
                           FROM ResourceRequest__c
                           WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
                   
        possibleDateLabelsMap = new Map<Id,String>();    
        //populate the labels
        getPossibleDatesList();
         reloadFailed = false;
         RFxDatesSetOnNonRFx = false;
         
         if(resourceRequest.Event_Type__c != 'RFI / RFP' && (resourceRequest.RFx_Received__c != null || resourceRequest.RFx_Internal_Due__c != null || resourceRequest.RFx_External_Due__c != null ))
         {
             RFxDatesSetOnNonRFx = true;
         }
        }catch(QueryException qe)
        {
         reloadFailed = true;
         
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The request that you are trying to load has beed deleted and no longer exists in the system.'));

        }
       
    }
    
    @RemoteAction
    public static String openRequest(String requestID)
    {
        System.Debug('           ^^^^^^^^^^^^ openRequest called for ' + requestID);
         ResourceRequest__c resReq = [SELECT Id, Name, Description__c, Event_Type__c,RolesAsString__c, event_goals__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Region__c, Opportunity__r.ownerId, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate 
                                      FROM ResourceRequest__c
                                      WHERE Id = :requestID LIMIT 1];
        system.debug('req name'+resreq.Name);
        system.debug('req name'+resreq.CreatedbyId);
        
        try{
        
         if(resReq.Opportunity__r.Region__c != null && (resReq.Opportunity__r.Region__c == 'EMEA' || resReq.Opportunity__r.Region__c =='APAC'))
            {
               //post to chatter that the request is open on this request
          	   FeedItem post = new FeedItem();
           	   post.ParentId = requestID; 
               post.Body = 'This request has been opened.';
               insert post;              
                
               //find the group for SC Staffing for the region
                 String staffingChatterGroupName = resReq.Opportunity__r.Region__c + ' SC Staffing';
                system.debug('staffingChatterGroupName'+ staffingChatterGroupName);
                CollaborationGroup sCStaffingGroup = [SELECT Id, Name from CollaborationGroup WHERE Name = :staffingChatterGroupName LIMIT 1];
                   
                FeedItem post2 = new FeedItem();
                post2.ParentId = sCStaffingGroup.Id;   // requestID; //fix this to be the right group
                post2.Body = 'New Staffing Request:\n' + resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')\nRoles Needed: ' + resReq.RolesAsString__c;
                post2.Title = resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')';
                post2.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
    
                insert post2;
                
                //store the feed id
                 resReq.FeedAnnouncementID__c = post2.Id;
                 resReq.Status__c = 'Open';
                 upsert resReq;  
                
              }
        
          if(resReq.Opportunity__r.Region__c != null && resReq.Opportunity__r.Region__c == 'AMER')  
            {
              // Post_RR_to_Team__c is a custom setting which consists of Owner Id, Role Name and the Group Name with fields Owner_Id__c,Role_Name__c and Group_Name__c.
              
                 Set<string> RoleNames = new Set<string>();
                 List<string> GroupNames = new List<string>();
                 Map<id,string> ChatterGroupMap = new Map<id,string>();
                 Set<id> Ownerids = new Set<id>();
        
                List<Post_RR_to_Team__c> ReqGroup = Post_RR_to_Team__c.getall().values();
        
                for(Post_RR_to_Team__c pos : ReqGroup)
                 {
                   GroupNames.add(pos.Group_Name__c);
                   RoleNames.add(pos.Role_Name__c);
                   Ownerids.add(pos.Owner_Id__c);
          		   ChatterGroupMap.put(pos.Owner_Id__c, pos.Group_Name__c);
       			 }
         
     			set<id> ForecastManager = new set<id>();
      
      	   		User OppOwner = [select id,name,email,userroleid, userrole.parentroleId from User where id =: resReq.Opportunity__r.ownerId ];
        
                UserRole ParentRole = [select id,name,parentroleid,forecastUserId from  UserRole where id =: OppOwner.userrole.parentroleId];
                system.debug('parent role ' +parentrole.Name);        
                
                if(RoleNames.contains(ParentRole.name))
                  {
            		ForecastManager.add(ParentRole.forecastUserId); 
       			  }
        
     		    if(!RoleNames.contains(ParentRole.name))
  			       {
  			          UserRole URole = [select id,name,parentroleid from UserRole where id =: ParentRole.id];
  			          UserRole FinalParentRole = [select id,name,forecastUserId from UserRole where id =: URole.parentroleid];
 			           ForecastManager.add(FinalParentRole.forecastUserId);
  			        } 
        
        
         		 User FstManager = [select id,name,email,userroleid from User where id =: ForecastManager Limit 1];  
            		system.debug('User name '+fstmanager.name);
        
        		//update status to Open if Pending
        		
         	 if(resReq.Status__c == 'Pending' && FstManager.id != Null && Ownerids.contains(FstManager.id))
        	  {
            
         	   //post to chatter that the request is open on this request
          	   FeedItem post = new FeedItem();
           	   post.ParentId = requestID; 
               post.Body = 'This request has been opened.';
               insert post;

               string grpName = ChatterGroupMap.get(FstManager.id);
               CollaborationGroup Group1 = [SELECT Id, Name, ownerId from CollaborationGroup WHERE  Name =: grpName ];
         
               FeedItem post3 = new FeedItem();
               post3.ParentId = Group1.Id;   // requestID; //fix this to be the right group
               post3.Body = 'New Staffing Request:\n' + resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')\nRoles Needed: ' + resReq.RolesAsString__c;
               post3.Title = resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')';
               post3.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
    
               insert post3;               
    
               //store the feed id
                 resReq.FeedAnnouncementID__c = post3.Id;
                 resReq.Status__c = 'Open';
                 upsert resReq;   
    
                //gather information for the chatter posts:  opportunity name, event name, roles needed, event type, 
                //TODO:  post to staffing chatter group
                //TODO:  post to staffing management group              
                        
             }
                
              if(resReq.Status__c == 'Pending' && !Ownerids.contains(FstManager.id))
        	  {
            
         	   //post to chatter that the request is open on this request
          	   FeedItem post = new FeedItem();
           	   post.ParentId = requestID; 
               post.Body = 'This request has been opened.';
               insert post;              
                
               //find the group for SC Staffing for the region
                 String staffingChatterGroupName = resReq.Opportunity__r.Region__c + ' SC Staffing';
                system.debug('staffingChatterGroupName'+ staffingChatterGroupName);
                CollaborationGroup sCStaffingGroup = [SELECT Id, Name from CollaborationGroup WHERE Name = :staffingChatterGroupName LIMIT 1];
                   
                FeedItem post2 = new FeedItem();
                post2.ParentId = sCStaffingGroup.Id;   // requestID; //fix this to be the right group
                post2.Body = 'New Staffing Request:\n' + resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')\nRoles Needed: ' + resReq.RolesAsString__c;
                post2.Title = resReq.Opportunity__r.Name + ' - '+resReq.Name +' ('+resReq.Event_Type__c+')';
                post2.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
    
                insert post2;
                
                //store the feed id
                 resReq.FeedAnnouncementID__c = post2.Id;
                 resReq.Status__c = 'Open';
                 upsert resReq;  
                
    
                //gather information for the chatter posts:  opportunity name, event name, roles needed, event type, 
                //TODO:  post to staffing chatter group
                //TODO:  post to staffing management group              
                        
           }
                                
        }
        return 'Success';
      }
            
        Catch(QueryException e)
        {    
            string error = e.getMessage();
           // ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Please contact Salesforce Administrator');
           // ApexPages.addMessage(myMsg); 
            return error;            
        }              
    }

    @RemoteAction
    public static String revokeRequest(String requestID)
    {
        System.Debug('           ^^^^^^^^^^^^ revokeRequest called for ' + requestID);
         ResourceRequest__c resReq = [SELECT Id, Name,FeedAnnouncementID__c,  Description__c, event_goals__c,Event_Type__c,RolesAsString__c,  Presentation_Type__c, Location__c, Status__c, Opportunity__c, Opportunity__r.Name  FROM ResourceRequest__c
                   WHERE Id = :requestID LIMIT 1];
    
        //update status to Open if Pending
            resReq.Status__c = 'Revoked';
            upsert resReq;
            
            if(resReq.FeedAnnouncementID__c != null)
            {
                FeedComment fcomment = new FeedComment();
                fcomment.FeedItemId = resReq.FeedAnnouncementID__c; 
                fcomment.CommentBody = 'This request has be canceled.';
                insert fcomment;
            }

            FeedItem post = new FeedItem();
            post.ParentId = requestID; 
            post.Body = 'This request has been canceled.';
            insert post;

                
        return 'Success';
    }

    @RemoteAction
    public static String convertPendingRequestToEvent(String requestID)
    {
        // 10/23/2013: currently only available in EMEA
        System.Debug('           ^^^^^^^^^^^^ convertPendingRequestToEvent called for ' + requestID);
        
        ResourceRequest__c resReq = [SELECT Id, Name,FeedAnnouncementID__c,  Description__c, event_goals__c,Event_Type__c,
                                             RolesAsString__c,  Presentation_Type__c, Location__c, Status__c, 
                                             Opportunity__r.Name, Opportunity__c,
                                             RFx_Internal_Due__c, RFx_External_Due__c, RFx_Received__c 
                                             FROM ResourceRequest__c
                                             WHERE Id = :requestID LIMIT 1];
        
        resReq.Status__c = 'Completed';
        //  update any dates that are pending to not selected, assuming something is selected
        Possible_Date__c[] selectedDates= [SELECT Id,Status__c, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID and Status__c = 'Selected'];      
        if(selectedDates.size() > 0)
        {
            Possible_Date__c[] otherDates = [SELECT Id,Status__c, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID and Status__c = 'Possible'];
            for( Possible_Date__c thisDate : otherDates)
            {
                thisDate.Status__c = 'Not Selected';
            }            
            update otherDates;
        }  

        //save the updates to this request        
            upsert resReq;

        Sales_Event__c newEvent = null;
        Set<Id> selectedPeople = new Set<Id>();


            //create the new event
            newEvent = new Sales_Event__c();
            newEvent.Name = resReq.Name;
            newEvent.Opportunity__c = resReq.Opportunity__c;
            newEvent.Description__c = resReq.Description__c;
            newEvent.Location__c = resReq.Location__c;
            newEvent.Event_Type__c = resReq.Event_Type__c;
            newEvent.Presentation_Type__c = resReq.Presentation_Type__c;
            newEvent.Original_Request__c = resReq.Id;
            //newEvent.Status__c = 'Tentative';
            newEvent.Event_Goals__c = resReq.Event_Goals__c;
        
            if(newEvent.Event_Type__c == 'RFI / RFP')
            {
                newEvent.Status__c = 'Confirmed';
                newEvent.RFx_Internal_Due__c = resReq.RFx_Internal_Due__c;
                newEvent.RFx_External_Due__c = resReq.RFx_External_Due__c;
                newEvent.RFx_Received__c = resReq.RFx_Received__c;
                
            }
            else
            {
                newEvent.Status__c = 'Tentative';            
            }
            
            insert newEvent;        
            
        //  copy over dates that not selected
            //get the dates for this request 
            
            if(newEvent.Event_Type__c != 'RFI / RFP')
            {

                Possible_Date__c[] reqDates = [SELECT Id, Status__c, Start_Date__c, End_Date__c, Date_is_Flexible__c,Event_Hours__c, Note__c, Name, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID];
                for( Possible_Date__c thisReqDate : reqDates )
                {
                    //for each of them, create a new date on the event with the same values and status
                   Event_Possible_Date__c newEDate = new Event_Possible_Date__c();
                   newEDate.Start_Date__c = thisReqDate.Start_Date__c;
                   newEDate.End_Date__c = thisReqDate.End_Date__c;
                   newEDate.Status__c = thisReqDate.Status__c;
                   newEDate.Note__c = thisReqDate.Note__c;
                   newEDate.Date_is_Flexible__c = thisReqDate.Date_is_Flexible__c;
                   newEDate.Name = thisReqDate.Name;
                   newEDate.Event_Hours__c = thisReqDate.Event_Hours__c;
                   //assign this newEDate to the same opportunity
                   newEDate.Sales_Event__c = newEvent.Id;                   
                   
                    //if the status for this date is selected, also set it on the new event as status and confirmed fields
                   if(thisReqDate.Status__c == 'Selected')
                   {
                       System.Debug(' ******* Found a confirmed date so updating event');
                       newEvent.Status__c = 'Confirmed';
                       newEvent.Confirmed_Start_Date__c = thisReqDate.Start_Date__c;
                       newEvent.Confirmed_End_Date__c = thisReqDate.End_Date__c;
                       newEvent.Event_Hours__c = thisReqDate.Event_Hours__c;
                      // newEvent.Date_is_Flexible__c = thisReqDate.Date_is_Flexible__c;
                   }
                   
                   insert newEDate;
                }
                
             }
                        
                        
           //change this to look at holds
           //        List<Resource_Hold__c> holds = [SELECT Id, Who__c, Coverage_Area__c, Description__c FROM Resource_Hold__c where Resource_Request__c = :resourceRequest.Id];       

           List<Resource_Hold__c> allHolds = [SELECT Id, Who__c, Coverage_Area__c, Description__c FROM Resource_Hold__c where Resource_Request__c = :requestID ];       
            
            Map<ID, Customer_Commitment__c> commitmentMap = new Map<ID, Customer_Commitment__c>();
            for(Resource_Hold__c thisHold: allHolds)
            {
                //see if they are already on the event.
                Customer_Commitment__c theCommitment = commitmentMap.get(thisHold.Who__c);
            
                //if not, add a new commitment
                if(theCommitment == null)
                {
                    theCommitment = new Customer_Commitment__c();
                    theCommitment.Sales_Event__c = newEvent.Id;
                    theCommitment.Who__c = thisHold.Who__c;
                    //theCommitment.Description = //come from the role_description
                    //add this person to the set of selected people
                    selectedPeople.add(thisHold.Who__c);
                }
                //need to add this role to the coverage area 
                if(theCommitment.Coverage_Area__c == null)
                {
                    theCommitment.Coverage_Area__c = thisHold.Coverage_Area__c;
                }
                else
                {
                    //see if the value already contains this...if so, don't set it again
                    if( !theCommitment.Coverage_Area__c.contains(thisHold.Coverage_Area__c))
                    {
                        theCommitment.Coverage_Area__c = theCommitment.Coverage_Area__c + ';' + thisHold.Coverage_Area__c;
                    }
                }
                
                //now put the udpated version of the commitment back in the map
                commitmentMap.put(thisHold.Who__c, theCommitment);                    
            
        
            }
            
            //now need to insert all of the commitments
            for(Id commitmentID : commitmentMap.keySet())
            {
                //insert the commitment
                insert commitmentMap.get(commitmentID);
            }
            
            //trigger any recalc of hours based on changes
            update newEvent;
                
               
        //now, we need to handle announcements        
        if(!selectedPeople.isEmpty())
        {
            String communityId = null;
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String userToMention = UserInfo.getUserId(); //'005xx000001TDn3' //need to have multiple
            String subjectId = resReq.Id;
            if(newEvent != null) //post on the new event  
            {
                subjectId = newEvent.Id;
            }
            
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = 'Congratulations on being selected for the event \'' + resReq.Name   + '\' on the opportunity \'' + resReq.Opportunity__r.Name + '\'.\n\n';
            messageInput.messageSegments.add(textSegment);
            
            ConnectApi.LinkSegmentInput linkSegment = new ConnectApi.LinkSegmentInput();
            linkSegment.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
            messageInput.messageSegments.add(linkSegment);
    
            ConnectApi.TextSegmentInput textSegment2 = new ConnectApi.TextSegmentInput();
            textSegment2.text = '\n\nThe team: ';
            messageInput.messageSegments.add(textSegment2);
            
            for(Id theUserToMention : selectedPeople)
            {
            
                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                mentionSegment.id = theUserToMention;
                messageInput.messageSegments.add(mentionSegment);
                    
            }
                    
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
              
            ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
            
        }
    
        if(newEvent != null)
        {
            //  send them to the new event page
      
            PageReference reqPage = new ApexPages.StandardController(newEvent).view();
            reqPage.setRedirect(true);
           // return reqPage ;    
           return reqPage.getUrl();        
        }
        
        
        
    
        return 'Success';
    }


    @RemoteAction
    public static String completeRequest(String requestID, Boolean shouldConvert)
    {

    
        System.Debug('           ^^^^^^^^^^^^ completeRequest called for ' + requestID + ' with convert specified as ' + shouldConvert);
    
         ResourceRequest__c resReq = [SELECT Id, Name,FeedAnnouncementID__c,  Description__c,event_goals__c, Event_Type__c,
                                             RolesAsString__c,  Presentation_Type__c, Location__c, Status__c, 
                                             Opportunity__r.Name, Opportunity__c,
                                             RFx_Internal_Due__c, RFx_External_Due__c, RFx_Received__c 
                                             FROM ResourceRequest__c
                                             WHERE Id = :requestID LIMIT 1];
    
    
        //things that are common to both
        //  set status of this request to complete
            resReq.Status__c = 'Completed';
            
        //  update any dates that are pending to not selected, assuming something is selected
        Possible_Date__c[] selectedDates= [SELECT Id,Status__c, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID and Status__c = 'Selected'];      
        if(selectedDates.size() > 0)
        {
            Possible_Date__c[] otherDates = [SELECT Id,Status__c, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID and Status__c = 'Possible'];
            for( Possible_Date__c thisDate : otherDates)
            {
                thisDate.Status__c = 'Not Selected';
            }            
            update otherDates;
        }  
        
        //  update people that are pending to be not selected
        Resource_Assignment__c[]  theOtherRAs = [SELECT Id, Resource_Request__c, Note__c, Status__c from Resource_Assignment__c  where Resource_Request__c = :requestID and Status__c = 'Not Selected' ];
        
        //update all of them to be not selected
        for(Resource_Assignment__c thisAssign :theOtherRAs )
        {
            thisAssign.Status__c = 'Not Selected';
        }
        update theOtherRAs; 
        
        
        //save the updates to this request        
            upsert resReq;
        
        Sales_Event__c newEvent = null;
        Set<Id> selectedPeople = new Set<Id>();
        Set<Id> notSelectedPeople = new Set<Id>();
        if(!shouldConvert)
        {
            //  announce that the request has been completed
            FeedItem post = new FeedItem();
            post.ParentId = requestID; 
            post.Body = 'The request has been closed and marked as completed.';
            insert post;        


           

            //now, specific to not converting
            //  return back to this page
            //  alert those that they were selected (but no event was created)
            //
            return 'Success';
        }
        else          //specific to converting to sales event
        {
        
                //create the new event
                newEvent = new Sales_Event__c();
                newEvent.Name = resReq.Name;
                newEvent.Opportunity__c = resReq.Opportunity__c;
                newEvent.Description__c = resReq.Description__c;
                newEvent.Location__c = resReq.Location__c;
                newEvent.Event_Type__c = resReq.Event_Type__c;
                newEvent.Presentation_Type__c = resReq.Presentation_Type__c;
                newEvent.Original_Request__c = resReq.Id;
                //newEvent.Status__c = 'Tentative';
                newEvent.Event_Goals__c = resReq.Event_Goals__c;
            
                if(newEvent.Event_Type__c == 'RFI / RFP')
                {
                    newEvent.Status__c = 'Confirmed';
                    newEvent.RFx_Internal_Due__c = resReq.RFx_Internal_Due__c;
                    newEvent.RFx_External_Due__c = resReq.RFx_External_Due__c;
                    newEvent.RFx_Received__c = resReq.RFx_Received__c;
                    
                }
                else
                {
                    newEvent.Status__c = 'Tentative';            
                }
                
                insert newEvent;        
                
            //  copy over dates that not selected
                //get the dates for this request 
                
                if(newEvent.Event_Type__c != 'RFI / RFP')
                {

                    Possible_Date__c[] reqDates = [SELECT Id, Status__c, Start_Date__c, End_Date__c, Event_Hours__c, Note__c, Name,Date_is_Flexible__c, Resource_Request__c  from Possible_Date__c  WHERE Resource_Request__c = :requestID];
                    for( Possible_Date__c thisReqDate : reqDates )
                    {
                        //for each of them, create a new date on the event with the same values and status
                       Event_Possible_Date__c newEDate = new Event_Possible_Date__c();
                       newEDate.Start_Date__c = thisReqDate.Start_Date__c;
                       newEDate.End_Date__c = thisReqDate.End_Date__c;
                       newEDate.Status__c = thisReqDate.Status__c;
                       newEDate.Note__c = thisReqDate.Note__c;
                       newEDate.Name = thisReqDate.Name;
                       newEDate.Event_Hours__c = thisReqDate.Event_Hours__c;
                       newEDate.Date_is_Flexible__c = thisReqDate.Date_is_Flexible__c;
                       //assign this newEDate to the same opportunity
                       newEDate.Sales_Event__c = newEvent.Id;                   
                       
                        //if the status for this date is selected, also set it on the new event as status and confirmed fields
                       if(thisReqDate.Status__c == 'Selected')
                       {
                           System.Debug(' ******* Found a confirmed date so updating event');
                           newEvent.Status__c = 'Confirmed';
                           newEvent.Confirmed_Start_Date__c = thisReqDate.Start_Date__c;
                           newEvent.Confirmed_End_Date__c = thisReqDate.End_Date__c;
                           newEvent.Event_Hours__c = thisReqDate.Event_Hours__c;
                        //   newEvent.Date_is_Flexible__c = thisReqDate.Date_is_Flexible__c;
                       }
                       
                       insert newEDate;
                    }
                    
                 }
                        
             Resource_Assignment__c[]  allRAs= [SELECT Id, Resource_Request__c, Note__c, Status__c, User__r.Name, Resource_Role__r.Role__c from Resource_Assignment__c  where Resource_Request__c = :requestID ];
            //  add anyone that was selected to the commitments list
            
            
            Map<ID, Customer_Commitment__c> commitmentMap = new Map<ID, Customer_Commitment__c>();
            for(Resource_Assignment__c thisRA : allRAs)
            {
                //for each assignment that has a status of selected/confirmed, 
                    if(thisRA.Status__c == 'Selected')
                    {
                        //see if they are already on the event.
                        Customer_Commitment__c theCommitment = commitmentMap.get(thisRA.User__c);
                    
                        //if not, add a new commitment
                        if(theCommitment == null)
                        {
                            theCommitment = new Customer_Commitment__c();
                            theCommitment.Sales_Event__c = newEvent.Id;
                            theCommitment.Who__c = thisRA.User__c;
                            //theCommitment.Description = //come from the role_description
                            //add this person to the set of selected people
                            selectedPeople.add(thisRA.User__c);
                        }
                        //need to add this role to the coverage area 
                        if(theCommitment.Coverage_Area__c == null)
                        {
                            theCommitment.Coverage_Area__c = thisRA.Resource_Role__r.Role__c;
                        }
                        else
                        {
                            //see if the value already contains this...if so, don't set it again
                            if( !theCommitment.Coverage_Area__c.contains(thisRA.Resource_Role__r.Role__c))
                            {
                                theCommitment.Coverage_Area__c = theCommitment.Coverage_Area__c + ';' + thisRA.Resource_Role__r.Role__c;
                            }
                        }
                        
                        //now put the udpated version of the commitment back in the map
                        commitmentMap.put(thisRA.User__c, theCommitment);                    
                    
                    }
                    else
                    {    //not selected so add the IDs to the list of people that 
                          notSelectedPeople.add(thisRA.User__c);

                    }
            
            }
            
            //now need to insert all of the commitments
            for(Id commitmentID : commitmentMap.keySet())
            {
                //insert the commitment
                insert commitmentMap.get(commitmentID);
            }
            
            //trigger any recalc of hours based on changes
            update newEvent;


             //before we send out the message, need to purge from the unselected group anyone that was selected for one role but not another.  
                
        }
        
        //now, we need to handle announcements
        
        if(!selectedPeople.isEmpty())
        {
            String communityId = null;
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String userToMention = UserInfo.getUserId(); //'005xx000001TDn3' //need to have multiple
            String subjectId = resReq.Id;
            if(newEvent != null) //post on the new event  
            {
                subjectId = newEvent.Id;
            }
            
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = 'Congratulations on being selected for the event \'' + resReq.Name   + '\' on the opportunity \'' + resReq.Opportunity__r.Name + '\'.\n\n';
            messageInput.messageSegments.add(textSegment);
            
            ConnectApi.LinkSegmentInput linkSegment = new ConnectApi.LinkSegmentInput();
            linkSegment.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
            messageInput.messageSegments.add(linkSegment);
    
            ConnectApi.TextSegmentInput textSegment2 = new ConnectApi.TextSegmentInput();
            textSegment2.text = '\n\nThe team: ';
            messageInput.messageSegments.add(textSegment2);
            
            for(Id theUserToMention : selectedPeople)
            {
            
                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                mentionSegment.id = theUserToMention;
                messageInput.messageSegments.add(mentionSegment);
                    
            }
                    
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
              
            ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
            
        }
        
        if(!notSelectedPeople.isEmpty())
        {
            String communityId = null;
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String userToMention = UserInfo.getUserId(); //'005xx000001TDn3' //need to have multiple
            String subjectId = resReq.Id;
            
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = 'Thank you for volunteering for the event \'' + resReq.Name   + '\' on the opportunity \'' + resReq.Opportunity__r.Name + '\'.  Your assistance will not be needed on this event.\n\n';
            messageInput.messageSegments.add(textSegment);
            
            for(Id theUserToMention : notSelectedPeople)
            {
            
                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                mentionSegment.id = theUserToMention;
                messageInput.messageSegments.add(mentionSegment);
                    
            }
                    
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
              
            ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
            
        }
            
    
        if(newEvent != null)
        {
            //  send them to the new event page
      
            PageReference reqPage = new ApexPages.StandardController(newEvent).view();
            reqPage.setRedirect(true);
           // return reqPage ;    
           return reqPage.getUrl();        
        }
    
    

        return 'Success';
    }
    

    @RemoteAction
    public static String deleteHold(String holdId, String requestID)
    {
        //use the hold
        Resource_Hold__c theHold = [SELECT Id from Resource_Hold__c  where Id = :holdId LIMIT 1];
        
        delete theHold;
        
        
        
        return 'success';

    }

    @RemoteAction
    public static String deleteRole(String roleID, String requestID)
    {
        //use the hold
        //first, check to see if there are commitments pointed at this role
        Resource_Assignment__c[] commits = [SELECT Id from Resource_Assignment__c where Resource_Role__c = : roleId];
        
        if(commits.size()> 0)
        {
           return null;
        }
        else
        {
            Resource_Role__c theRole= [SELECT Id from Resource_Role__c  where Id = :roleId LIMIT 1];
            
            delete theRole;
            
        }
        
        return 'success';

    }


    @RemoteAction
    public static String selectDate(String dateID, String requestID)
    {
        
        Possible_Date__c possDate = [SELECT Id,Status__c, Start_Date__c, End_Date__c, Event_Hours__c, Resource_Request__c from Possible_Date__c WHERE Id = :dateID  LIMIT 1];
        possDate.Status__c = 'Selected';
        update possDate;
        
        //now mark all other pending as not selected
        Possible_Date__c[] otherDates = [SELECT Id,Status__c, Resource_Request__c from Possible_Date__c  WHERE Resource_Request__c = :possDate.Resource_Request__c and Status__c = 'Possible'];
        for( Possible_Date__c thisDate : otherDates)
        {
            thisDate.Status__c = 'Not Selected';
        }
        update otherDates;
        
        
        //post to chatter that a date was selected
        FeedItem post = new FeedItem();
        post.ParentId = requestID; 
        post.Body = 'Date selected for this event.';
        insert post;
        
        
        return 'Success';
        
    }

    @RemoteAction
    public static String deleteAssignment(String thisAssignment, String requestID)
    {
       System.Debug(' %%%%%%%%% deleteAssignment called with ' + thisAssignment + ' by ' + UserInfo.getName() + ' on ' + requestID);
       Resource_Assignment__c  theRA = [SELECT Id, (Select Id from Resource_Availabilities__r) from Resource_Assignment__c  where Id = :thisAssignment LIMIT 1];
        //need to delete this assignment, and all the associated availability
       //first, delete the availabilities
       delete theRa.Resource_Availabilities__r;
       delete theRa;
        
        return 'Success';
    }

    @RemoteAction
    public static String releaseAssignment(String thisAssignment, String requestID)
    {
       System.Debug(' %%%%%%%%% releaseAssignment called with ' + thisAssignment + ' by ' + UserInfo.getName() + ' on ' + requestID);
    
        //grab the assignment for this ID
//        Resource_Assignment__c  theRA = [SELECT Id, Resource_Role__c, Role__c,  Status__c from Resource_Assignment__c  where Id = :thisAssignment LIMIT 1];
        Resource_Assignment__c  theRA = [SELECT Id, Resource_Role__c, Note__c, User__r.Name, Resource_Role__r.Role__c, Resource_Role__r.Status__c, User__c,  Status__c from Resource_Assignment__c  where Id = :thisAssignment LIMIT 1];
        //update it to be selected
        theRA.Status__c = 'Pending';
        theRA.Resource_Role__r.Status__c = 'Required';
        update theRA;
        update theRA.Resource_Role__r;
        
        //now grab all others that are status of not selected and point to this role
        Resource_Assignment__c[]  theOtherRAs = [SELECT Id, Resource_Role__c, Note__c, Status__c from Resource_Assignment__c  where Resource_Role__c = :theRA.Resource_Role__c and Status__c = 'Not Selected' ];
        
        //update all of them to be not selected
        for(Resource_Assignment__c thisAssign :theOtherRAs )
        {
            thisAssign.Status__c = 'Pending';
        }
        update theOtherRAs; 
        
        //now post to chatter
//        FeedItem post = new FeedItem();
//        post.ParentId = requestID; 
//        post.Body = 'The ' + theRA.Resource_Role__r.Role__c + ' role is now available again.';
//        insert post;

        //get the info for the request
        ResourceRequest__c  theReq = [SELECT Id, Name, Opportunity__r.Name from ResourceRequest__c  where Id = :requestID LIMIT 1];
        
        String communityId = null;
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        String userToMention = theRA.User__c; 
        String subjectId = requestID;

        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = userToMention;
        messageInput.messageSegments.add(mentionSegment);

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' has been released from the ' + theRA.Resource_Role__r.Role__c + ' role for the event \'' + theReq.Name   + '\' on the opportunity \'' + theReq.Opportunity__r.Name + '\'.\n\n';
        messageInput.messageSegments.add(textSegment);
        
        ConnectApi.LinkSegmentInput linkSegment = new ConnectApi.LinkSegmentInput();
        linkSegment.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
        messageInput.messageSegments.add(linkSegment);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        
        ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                

        return 'success';
    }


    @RemoteAction
    public static String confirmAssignment(String thisAssignment, String requestID)
    {
       System.Debug(' %%%%%%%%% confirmAssignment called with ' + thisAssignment + ' by ' + UserInfo.getName() + ' on ' + requestID);
    
        //grab the assignment for this ID
        Resource_Assignment__c  theRA = [SELECT Id, Resource_Role__c, Note__c, User__r.Name, Resource_Role__r.Role__c, Resource_Role__r.Status__c , User__c,  Status__c from Resource_Assignment__c  where Id = :thisAssignment LIMIT 1];
        //update it to be selected
        theRA.Status__c = 'Selected';
        theRA.Resource_Role__r.Status__c = 'Filled';
        update theRA;
        update theRA.Resource_Role__r;
        
        //now grab all others that are status of pending and point to this role
        Resource_Assignment__c[]  theOtherRAs = [SELECT Id, Resource_Role__c, Note__c, User__r.Name,  Status__c from Resource_Assignment__c  where Resource_Role__c = :theRA.Resource_Role__c and Status__c = 'Pending' ];
        
        //update all of them to be not selected
        for(Resource_Assignment__c thisAssign :theOtherRAs )
        {
            thisAssign.Status__c = 'Not Selected';
        
        }
        update theOtherRAs; 
         
         
        //now post to chatter
//        FeedItem post = new FeedItem();
//        post.ParentId = requestID; 
//        post.Body = theRA.Who__c + ' has been selected for the ' + theRA.Resource_Role__r.Role__c + ' role.';
//        insert post;
        
        //get the info for the request
        ResourceRequest__c  theReq = [SELECT Id, Name, Opportunity__r.Name from ResourceRequest__c  where Id = :requestID LIMIT 1];
        
        String communityId = null;
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        String userToMention = theRA.User__c; 
        String subjectId = requestID;

        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = userToMention;
        messageInput.messageSegments.add(mentionSegment);

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' has been selected for the ' + theRA.Resource_Role__r.Role__c + ' role for the event \'' + theReq.Name   + '\' on the opportunity \'' + theReq.Opportunity__r.Name + '\'.\n\n';
        messageInput.messageSegments.add(textSegment);
        
        ConnectApi.LinkSegmentInput linkSegment = new ConnectApi.LinkSegmentInput();
        linkSegment.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + requestID;
        messageInput.messageSegments.add(linkSegment);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        
        ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
    
    
        return 'success';
    
    }
    

    @RemoteAction
    public static String addCurrentUserForSpecifiedRole(String thisRole, String requestID)
    {
       System.Debug(' %%%%%%%%% addCurrentUserForSpecifiedRole called with ' + thisRole + ' for ' + UserInfo.getName() + ' on ' + requestID);
     
     //get the ResourceRequest__c 
     ResourceRequest__c  theReq = [SELECT Id from ResourceRequest__c  where Id = :requestID LIMIT 1];
     System.Debug('   %%%%% Found req: ' +  theReq.Id);
                 Resource_Assignment__c ras = new Resource_Assignment__c();
            ras.Name = 'Autogenerated by AddMe';
            
            ras.Resource_Request__c = theReq.Id;
            ras.User__c = UserInfo.getUserId();
            
            //MATT:  temporarily assign role here
            Resource_Role__c roleToAssign = [SELECT Id, Role__c, Resource_Request__c from Resource_Role__c where Resource_Request__c = :theReq.ID  and Role__c = :thisRole LIMIT 1];
            System.Debug('   %%%%% Found role: ' +  roleToAssign.Role__c);
            ras.Resource_Role__c = roleToAssign.Id;
            
            
            insert ras; 
        //return 'success';
       return     ras.Id;    
    }


    public Boolean getIsPresalesManager() {
      return (GWUserProfileHelper.isPresalesManager());
    }

    public Boolean getIsSalesOrPresalesManager() {
      return (GWUserProfileHelper.isSales() || GWUserProfileHelper.isPresalesManager());
    }

    public Boolean getIsSales() {
      return GWUserProfileHelper.isSales();
    }


    public List<Resource_Hold__c> getAllResourceHoldsList() {
        //need to query to get them
        List<Resource_Hold__c> holds = [SELECT Id, Who__c, Coverage_Area__c, Description__c FROM Resource_Hold__c where Resource_Request__c = :resourceRequest.Id];       
         
        return holds;
    }


    public List<Possible_Date__c> getAllPossibleDatesList() {
        //need to query to get the date counts
        List<Possible_Date__c> pd = [SELECT Id, Name, Start_Date__c, End_Date__c, Event_Hours__c, Note__c, Status__c,Date_is_Flexible__c,LastModifiedDate  FROM Possible_Date__c where Resource_Request__c = :resourceRequest.Id ORDER BY Start_Date__c ];       
         
        return pd;
    }

    public List<Possible_Date__c> getPossibleDatesList() {
        //need to query to get the date counts
        List<Possible_Date__c> retval = new List<Possible_Date__c>();
        List<Possible_Date__c> pd = getAllPossibleDatesList();
        
        //add the formatted strings to the map
        for(Possible_Date__c thisPD : pd)
        {
            //let's only include ones that are still valid
            if(thisPD.Status__c != 'No Longer Available')
            {
                String label = thisPD.Start_Date__c.format() + ' -<br>'+ thisPD.End_Date__c.format() ;
            
                possibleDateLabelsMap.put(thisPD.Id, label);
                retval.add(thisPD);
                
            }
        
        }
         
        return retval;
    }


    public List<SelectOption> getRequestedResourceRolesAsSelect() {

        List<SelectOption> options = new List<SelectOption>();
        if(reloadFailed) return options;
        List<Resource_Role__c> rrrList = [SELECT Id,Role__c,  Resource_Request__c from Resource_Role__c where Resource_Request__c = :resourceRequest.Id];
        for(Resource_Role__c rrr : rrrList )
        {
            if(rrr.Role__c != null)  options.add(new SelectOption(rrr.Id, rrr.Role__c));
        }
    
        return options;
    }
    
    public boolean getRequiredRolesFilled()
    {
      if(reloadFailed) return false;
      List<Resource_Role__c> roles = getRequestedResourceRoles();
      for(Resource_Role__c ro : roles)
      {
          if(ro.Status__c == 'Required') return false;
      }
      return true;
        
    }

    public boolean getHasAtLeastOneRole()
    {
      if(reloadFailed) return false;
      List<Resource_Role__c> roles = getRequestedResourceRoles();
      if(roles.size() > 0) return true;
      return false;
        
    }


    public List<Resource_Role__c>getRequestedResourceRoles() {
        List<Resource_Role__c> rrrList = [SELECT Id, Role__c,Status__c, Note__c,LastModifiedDate ,  Resource_Request__c from Resource_Role__c where Resource_Request__c = :resourceRequest.Id];
    
        return rrrList ;
    }


    public void clearAssignmentsList() {
        lastReturnedList  = null;
    }

    public List<cResourceAssignment> getAssignmentsList() {
    
        //get the list of actual Resource_Assignment__c  objects
        
        if(lastReturnedList != null) return lastReturnedList;
        
        roleBeingEdited = false;
        System.Debug(' ***** Looking for assignments:' + resourceRequest.Resource_Assignments__r);        
        List<Resource_Assignment__c> theAssignmentList = [SELECT Id, Resource_Request__c, User__c, Status__c, Note__c, Resource_Role__r.Role__c, Resource_Role__r.Status__c, 
                                                          (Select Id, Possible_Date__c,Resource_Assignment__c, Availability__c from Resource_Availabilities__r)
                                                          from Resource_Assignment__c 
                                                          where Resource_Request__c= :ResourceRequest.Id ORDER BY Resource_Role__r.Role__c];
        System.Debug(' ***** Found ' + theAssignmentList.size() + ' assignments.');
        //convert them to the wrapper class list
        List<cResourceAssignment> returnList = new List<cResourceAssignment>();
        for(Resource_Assignment__c ra : theAssignmentList )
        {    
            System.Debug('$$$$$ assignment note: ' + ra.Note__c);
            //let's make sure this should be in the table
            //  so exclude roles that are no longer neede
            cResourceAssignment cra = new cResourceAssignment(ra, this);
            if(cra.rRole.Status__c != 'No Longer Needed')
            {
                returnList.add(cra);
            
            }
        }
    
        //store the list before returning
        lastReturnedList = returnList;
        //return the list
        return returnList;
    }

    public void saveResources()
    {
        System.Debug(' ***** Save called!');
        
        //let's call save on all of the availabilities that need updating
        for(cResourceAssignment ra : lastReturnedList )
        {    
            
            for(Resource_Availability__c rav:  ra.availabilityObjectMap.values())
            {
                if(rav.Availability__c == null ) rav.Availability__c = 'Not Specified';
            }
            update ra.availabilityObjectMap.values();
//                            update rav;

        }
        
        
        //need to have the local ones stored here
        //and let's refresh the maps
        for(cResourceAssignment cra :  getAssignmentsList())
        {
            cra.setupMaps();
        }
        
        
        
    }
    
//    public void 

/***************************   CLASS cResourceAssignment  ******************************************/

    public class cResourceAssignment {
    
        public ResourceRequestController rRequestController {get; set;}        
        public Resource_Assignment__c rAssignment {get; set;}        
        public Resource_Role__c rRole {get; set;}        

        public Boolean editRole {get; set;}
       // public String resourceName {get; set;}


        
        public Map<Id,String> availabilityMap  {get; set;} 
        public Map<Id,Resource_Availability__c> availabilityObjectMap  {get; set;} 
        
        public Integer cursor {get;set;}
        
        public cResourceAssignment(Resource_Assignment__c ra, ResourceRequestController reqCont) {
            rRequestController = reqCont;
            editRole = false;
            cursor = -1;
            
            
            availabilityMap = new Map<Id, String>();
            availabilityObjectMap   = new Map<Id,Resource_Availability__c> ();
            rAssignment = ra;
            
            boolean result  = setupMaps();
            
           rRole = ra.Resource_Role__r; //[Select Id, Role__c, Status__c from Resource_Role__c where Id = :rAssignment.Resource_Role__c LIMIT 1];        
                     
                   
        }    
        
        public boolean setupMaps()
        {
            availabilityMap = new Map<Id, String>();
            availabilityObjectMap   = new Map<Id,Resource_Availability__c> ();
            //now build the availability map for this user
            //get all of the possible for this event and use those IDs in combination with the resource assignment ID

            System.Debug(' ***** Note on assignment:' + rAssignment.Note__c );

            
            List<Resource_Availability__c> availabilities =  rAssignment.Resource_Availabilities__r; //[SELECT Id, Possible_Date__c,Resource_Assignment__c, Availability__c from Resource_Availability__c where Resource_Assignment__c = :rAssignment.Id];
            System.Debug(' ***** Found ' + availabilities.size() + ' availabilities.');
            for(Resource_Availability__c avail : availabilities )
            {
                System.Debug(' ***** Key:' + avail.Possible_Date__c + '; val:' + avail.Availability__c);
                if(avail != null && avail.Possible_Date__c != null /*&& avail.Availability__c  != null*/ )
                {
                    if(avail.Availability__c == null)  //if the value has been deleted, let's put in a temp value
                    {
                        avail.Availability__c = 'Not Specified';                       
                    }
                    availabilityMap.put(avail.Possible_Date__c,avail.Availability__c );                                
                    availabilityObjectMap.put(avail.Possible_Date__c,avail );                
                }
            }     
            
            return true;
        
        }
        
        public void enableEditRole()
        {
            editRole= !editRole;
            rRequestController.roleBeingEdited = editRole;
            System.Debug(' *************** enableEditRole called!  EditRole now ' + editRole);        

        }

        public void changeRole()
        {
            editRole= false;
            System.Debug(' *************** changeRole called!');  
            update rAssignment;
            
            rRequestController.roleBeingEdited = false;

            //reload these table data
            rRequestController.clearAssignmentsList();
                        
        }

        
        public String getResourceName()
        {
            User theUser = [Select Id, FirstName, LastName from User where Id = :rAssignment.User__c LIMIT 1];            
            return theUser.FirstName + ' ' + theUser.LastName ;
        }

       public Map<Id, String> getAvailabilities()
        {
            return availabilityMap;
            //return availabilityMap.get(possibleDateID);
        }
        
        
        
    }

}