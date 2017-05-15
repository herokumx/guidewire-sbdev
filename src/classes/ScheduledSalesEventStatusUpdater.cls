global class ScheduledSalesEventStatusUpdater
 {  
    global static void execute() {
  
      
       Date todayDate = Date.today();
      
       Sales_Event__c[] eventsToUpdate =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, 
                                                  Event_Type__c, Presentation_Type__c, Location__c, Status__c, 
                                                  Opportunity__c,  Opportunity__r.Name,  Opportunity__r.region__c, Opportunity__r.ownerid,
                                    (SELECT Id , Who__c, Who__r.Name, Coverage_Area__c, Sales_Event__c FROM Customer_Commitments__r ),
                                    (SELECT Id, Start__c, End__c, Who__c, Who__r.Name, Note__c, Hours__c FROM Preparations__r  )

                                           FROM Sales_Event__c
                                           WHERE 
                                             Status__c = 'Confirmed' AND
                                              ((Event_Type__c <> 'RFI / RFP' AND
                                              Confirmed_End_Date__c < :todayDate)
                                               OR
                                               (Event_Type__c = 'RFI / RFP' AND
                                                RFx_External_Due__c < :todayDate)
                                              )
                                              //name = 'Test Chatter Post'
                                          ];
       
       for(Sales_Event__c thisEvent : eventsToUpdate )
       {
           thisEvent.Status__c  = 'Completed';
           
           //also need to post accordingly for updates
           
            System.Debug(' &&&&&&&&&&&&&  Requesting Review of recent sales event ' + thisEvent.ID);
                    
            String communityId = null;
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String userToMention = UserInfo.getUserId(); 
            String subjectId = thisEvent.Id;
            String completedText = null;
            String ApacCompletedText = null;
            
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            completedText = 'This event has been completed.  Please review to make sure your preparation time is still accurate\n';
            ApacCompletedText = 'This event has been completed.  Please review to make sure your preparation time is still accurate and provide your feedback here\n';
           
           
           if(thisEvent.opportunity__r.region__c != null) 
           {
           textSegment.text = !thisEvent.opportunity__r.region__c.equals('AMER')?
                     ApacCompletedText + (URL.getSalesforceBaseUrl().toExternalForm() + '/apex/SalesEventFeedback?SalesEventId='+ thisEvent.id + '\n'):completedText ;
           }
           else
              textSegment.text = completedText;
           
           messageInput.messageSegments.add(textSegment);
           
           
            //need to loop over the customer commitments and preprataions to get the unique set of people
            Set<Id> usersToMention = new Set<Id>();
            for(Preparation__c thePrepItem : thisEvent.Preparations__r)
            {
                if(thePrepItem.Who__c != null)
                {
                    usersToMention.add(thePrepItem.Who__c);            
                }
            }
            
            for(Customer_Commitment__c theCommitmentItem : thisEvent.Customer_Commitments__r )
            {
                if(theCommitmentItem.Who__c != null)
                {
                    usersToMention.add(theCommitmentItem.Who__c);            
                }
            }
            
            //APAC Region only - Add Oppty Owner
            if(thisEvent.opportunity__r.region__c != null && !thisEvent.opportunity__r.region__c.equals('AMER'))
            {    
    //        if(!thisEvent.opportunity__r.region__c.equals('AMER'))
            
                usersToMention.add(thisEvent.opportunity__r.ownerid);
            }
       
            for(Id theUserToMention : usersToMention)
            {
            
                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                mentionSegment.id = theUserToMention;
                messageInput.messageSegments.add(mentionSegment);
                    
            }
                                   
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
            
            ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                
                           
                               
                   
       }
       
       update eventsToUpdate;
      
      
       // now let's do the same for personal events
      Personal_Event__c[]  peventsToUpdate = [Select Id, Status__c, End__c from Personal_Event__c
                                              WHERE Status__c = 'Confirmed'  and End__c < :Date.today()];
                                              
       
       for(Personal_Event__c thisEvent : peventsToUpdate  )
       {
           thisEvent.Status__c  = 'Completed';
       }

       update peventsToUpdate;

       
       // and finally let's do the same for projects
       Project_Event__c[] projectEventsToUpdate =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, 
                                                  Status__c, Project__c, Project__r.Name,
                                    (SELECT Id , Who__c, Who__r.Name, Project_Event__c FROM Project_Participants__r ),
                                    (SELECT Id, Start__c, End__c, Who__c, Who__r.Name, Note__c, Hours__c FROM Preparations__r  )

                                           FROM Project_Event__c
                                           WHERE 
                                              Status__c = 'Confirmed' AND
                                              Confirmed_End_Date__c < :todayDate
                                             
                                          ];
       
       for(Project_Event__c thisEvent : projectEventsToUpdate )
       {
           thisEvent.Status__c  = 'Completed';
           
           //also need to post accordingly for updates
           
            System.Debug(' &&&&&&&&&&&&&  Requesting Review of recent project event ' + thisEvent.ID);
                    
            String communityId = null;
            ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
            String userToMention = UserInfo.getUserId(); 
            String subjectId = thisEvent.Id;
            
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = 'This event has been completed.  Please review to make sure your preparation time is still accurate\n';
            messageInput.messageSegments.add(textSegment);
            
            //need to loop over the customer commitments and preprataions to get the unique set of people
            Set<Id> projectUsersToMention = new Set<Id>();
            for(Project_Preparation__c thePrepItem : thisEvent.Preparations__r)
            {
                if(thePrepItem.Who__c != null)
                {
                    projectUsersToMention.add(thePrepItem.Who__c);            
                }
            }
            
            for(Project_Participant__c theParticipationItem : thisEvent.Project_Participants__r )
            {
                if(theParticipationItem.Who__c != null)
                {
                    projectUsersToMention.add(theParticipationItem.Who__c);            
                }
            }
       
            for(Id theUserToMention : projectUsersToMention)
            {
            
                ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                mentionSegment.id = theUserToMention;
                messageInput.messageSegments.add(mentionSegment);
                    
            }
                                   
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
            
            ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);                                   
       }
       
       update projectEventsToUpdate;
   }
 }