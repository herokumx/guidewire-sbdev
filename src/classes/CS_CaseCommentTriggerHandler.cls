/*
*****************************************************************************************************************************
Class Name - CS_CaseCommentTriggerHandler
Class Type -  Handler
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Hari                           09/21/2016       Added code in bulk before to prevent Case Team Members with role - Customer Support (View Only) from adding a Case Comment.
Vipin                          08/29/2016
Mani G                         09/01/2016       Added New Field Update on Case CS_Recent_Public_Case_Comment_Source__c='Case Feed';
Mani G                         09/05/2016       Added  Validation to Prevent Converting Private Comment to a Public Comment
Mani G                         10/26/2016       Fixed for  INC0063973
Suchitra                       10/27/20116      DE381 Added  Enhancement a comment is made by a Customer(/PSA Customer), Update the case status to Updated by customer 
Suchitra                       11/14/2016       INC0064632 Update the Status to Updated By Customer only after the Internal Support Rep touches the case by adding a case comment. 
Suchitra                       11/28/2016       INC0065732 Remove the profile check to categorize the comment as Internal posted vs external posted. 
*****************************************************************************************************************************
*/
public without sharing class CS_CaseCommentTriggerHandler implements CS_ITrigger{
    
    private List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
    private List<CaseComment> LstfeedItem= New List<CaseComment>();
    private List<Case> lstCaseUpdate=New List<Case>();
    private Id caseContactRoleId ;
    private List<CaseTeamMember> lstCTMUpdate= new List<CaseTeamMember>();
    private List<CaseTeamMember> lstCTMInsert= new List<CaseTeamMember>();
      
    public CS_CaseCommentTriggerHandler() {}
    
    private Map<Id,Case> caseMap;

    private CS_ByPass__c bypass {
        get {
            return  CS_ByPass__c.getInstance(UserInfo.getUserId());
        }
    }
    
     /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
        if(Trigger.isInsert)
        {
             set<id> caseIds = new set<id>();
             for(SObject so : trigger.new)
              {
                CaseComment cc = (CaseComment)so;
                caseIds.add(cc.ParentId);
              }
    
              set<id> memberIds = new set<id>();
              List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember> ([SELECT Id, Member.Id, Member.Email, TeamRole.Name, ParentId, MemberId FROM CaseTeamMember WHERE ParentId IN: caseIds
                                                                                  AND TeamRole.Name IN('Customer Support (View Only)') ]);
              if(caseTeamMembers.size() >0)
              {
                  for(CaseTeamMember ct : caseTeamMembers)
                  {
                      memberIds.add(ct.MemberId);
                  }
              }
          
    
              for(SObject so : trigger.new)
              {
                CaseComment cc = (CaseComment)so;
                if(memberIds.contains(userinfo.getUserId()))
                {
                  cc.addError( 'You have Customer Support (View Only) access, you cannot comment on the case' );
                }
              }
         }
     }
     
    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter() {        
        if (Trigger.isInsert) {

            Set<Id> newFeedItemId = new Set<Id>();
            Set<Id> caseIdSet = new Set<Id>();
            Set<Id> projectIds = new Set<Id>();
            Set<Id> createdByIds = new Set<Id>();
            integer ctmSize = 0;
            //INC0065732 - Commenting the Profile Check. Going forward, if anyone in the Case Team Member with Role, customer case contact, 
            // customer support and partner role adds a comment it will be considered as Customer Posted comment, if anyone other than those roles post a comment its considered internally posted comment. 
          
            CS_Profile_Id__c CS_Profile = CS_Profile_Id__c.getInstance();
            //string CProfileId = CS_Profile.CS_Customer_Profile_18__c;
            //string PProfileId=CS_Profile.CS_Partner_Profile_18__c;
            string PSProfileId=CS_Profile.CS_Service_Profile_18__c;
            
            //INC0064632 
            string PSSTDProfileId=CS_Profile.GW_Standard_PSA_18__c;
            string PSPSAProfileId=CS_Profile.GW_Services_PSA_18__c;
            
            
            //INC0064632 - Ends Here 
            CS_FeedItemEmailHelper  newCS_FeedItemEmailHelper = new CS_FeedItemEmailHelper ();
            Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
            Map<String, CaseTeamMember> mapcaseTeamMember = new Map<String,CaseTeamMember>(); //DE381 
            Map<Id,List<CaseTeamMember>> mapCaseIdToCaseTeamMember = new Map<Id,List<CaseTeamMember>>(); //INC0065732
            Map<String,CaseTeamMember> mapcaseTeamMemberAll = new Map<String,CaseTeamMember>(); //INC0065732
             Map<String, pse__Assignment__c> mapProjectAssignment = New Map<String, pse__Assignment__c>();
            Map<String, ID> mapCTMRole = new Map<String, ID>();

            Map<String,List<CaseTeamMember>> mapUserIdToCaseTeamMember = new Map<String,List<CaseTeamMember>>(); //INC0065732
            Map<Id,Case> mapCase = new map<Id,Case>(); //INC0064632
            Map<Id, Integer> mapCaseToCaseTeamCount = new Map<Id, Integer>(); //INC0065732
            
            for (SObject so : Trigger.new) {
                CaseComment feedItem = (CaseComment)so;
                
                if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case') {
                    
                    caseIdSet.add(feedItem.ParentId);
                    createdByIds.add(feedItem.CreatedById); 
                    if (FeedItem.isPublished == True) {
                        newFeedItemId.add(feedItem.Id);                    
                    }    
                }
            }
            
            if(caseIdSet.size()>0){
                
                //INC0064632 - Make a map of Case ID and Case 
                mapCase = new Map<Id,Case>([Select ID, CS_Public_Comment_By_Internal_User__c,CS_Project_Assignment__r.pse__Project__c,OwnerId, RecordTypeId FROM Case Where Id In:caseIdSet]);
                for (Case cse:mapCase.values()){
                    if (cse.CS_Project_Assignment__r.pse__Project__c != null){
                    projectIds.add(cse.CS_Project_Assignment__r.pse__Project__c);
                    }
                }
               
                //INC0065732 - Additional Roles added to the Case team member check 
                List<CaseTeamMember> lstCaseTeamMember = new List<CaseTeamMember>([Select MemberId, ParentId,TeamRole.Name from CaseTeamMember Where ParentId in:caseIdSet]);
                List<pse__Assignment__c> lstProjectAssignments = New List<pse__Assignment__c>([Select ID, pse__Project__c, pse__Resource__r.pse__Salesforce_User__c from pse__Assignment__c Where pse__Project__c IN:projectIds And pse__Resource__r.pse__Salesforce_User__c IN:createdByIds]);
                //INC0065732 
                List<CaseTeamRole> lstCTMRole= new List<CaseTeamRole>([Select ID, Name from CaseTeamRole]);
                for (CaseTeamRole ctmRole:lstCTMRole){
                    mapCTMRole.put((ctmRole.Name).ToUpperCase(), ctmRole.Id);
                }
                for (pse__Assignment__c projectPse:lstProjectAssignments){
                    mapProjectAssignment.put(String.ValueOf(projectPse.pse__Project__c) + String.ValueOf(projectPse.pse__Resource__r.pse__Salesforce_User__c),projectPse);
                }
                
                System.Debug('::First Check' + mapProjectAssignment);

                for (CaseTeamMember caseTeamMem:lstCaseTeamMember){
                    
                    if (caseTeamMem.TeamRole.Name == 'Customer Case Contact' ||  caseTeamMem.TeamRole.Name == 'Customer Support' || caseTeamMem.TeamRole.Name == 'Partner'){
                    mapcaseTeamMember.put(String.Valueof(caseTeamMem.ParentId) + String.Valueof(caseTeamMem.MemberId), caseTeamMem);
                    }
                    mapcaseTeamMemberAll.put(String.Valueof(caseTeamMem.ParentId) + String.Valueof(caseTeamMem.MemberId), caseTeamMem);

                    if (mapCaseIdToCaseTeamMember.containsKey(caseTeamMem.ParentId)){
                       List<CaseTeamMember> lstTemCaseTeamMember = mapCaseIdToCaseTeamMember.get(caseTeamMem.ParentId);
                       lstTemCaseTeamMember.add(caseTeamMem);
                       mapCaseIdToCaseTeamMember.put(caseTeamMem.ParentId, lstTemCaseTeamMember);
                    }else {
                        mapCaseIdToCaseTeamMember.put(caseTeamMem.ParentId, new List<CaseTeamMember>{caseTeamMem});
                    }
                    if (mapUserIdToCaseTeamMember.containsKey(caseTeamMem.MemberId)){
                       List<CaseTeamMember> lstTemCaseTeamMember = mapCaseIdToCaseTeamMember.get(caseTeamMem.MemberId);
                       lstTemCaseTeamMember.add(caseTeamMem);
                       mapUserIdToCaseTeamMember.put(caseTeamMem.MemberId,lstTemCaseTeamMember);
                    }else {
                        mapUserIdToCaseTeamMember.put(caseTeamMem.MemberId, new List<CaseTeamMember>{caseTeamMem});
                    }
                }//DE381 - ends here.

                //INC0065732 Loop Thu the CaseSet ID, Check it the mapCaseIdToCaseTeamMember has the corresponding SET Size, if yes then get the size else add the size as 0 
                for (ID idVal: caseIdSet)
                {
                    List<CaseTeamMember> lstCaseTeamMemberVar = new List<CaseTeamMember>();
                    lstCaseTeamMemberVar = mapCaseIdToCaseTeamMember.get(idVal);
                    if (lstCaseTeamMemberVar != null)
                    {
                        integer caseTeamMemberSize = lstCaseTeamMemberVar.size();
                        mapCaseToCaseTeamCount.put(idVal, caseTeamMemberSize );
                    } else {
                        mapCaseToCaseTeamCount.put(idVal, 0);
                    }
                }
            }
            
            
            for (SObject so : Trigger.new) {
                CaseComment feedItem = (CaseComment)so;
                CaseTeamMember ctmRecord = mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId()));
                CaseTeamMember ctmRecordAll = mapcaseTeamMemberAll.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId()));
                System.Debug('::ctmRecordAll' + ctmRecordAll);   
                // Check Feed Item type to Case and Its Public Stamp  Public  Post,Public Post made by and Public Posted Date on Case Record 
                             
                if(mapCase!= null && !mapCase.isEmpty() && mapOfRecordType.get(mapCase.get(feedItem.parentId).RecordTypeId) == 'CS_Customer_Support' ){


                     if (ctmRecordAll == null && mapCase.get(feedItem.ParentId).OwnerID != feedItem.CreatedById){
                                    CaseTeamMember newCTM = new CaseTeamMember(); 
                                    newCTM.TeamRoleId = mapCTMRole.get('COLLABORATOR');
                                    if (mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null) {
                                       newCTM.TeamRoleId = mapCTMRole.get('CUSTOMER CASE CONTACT'); 
                                    }
                                    newCTM.MemberId = feedItem.CreatedById;
                                    newCTM.ParentId = feedItem.ParentId;
                                    lstCTMInsert.add(newCTM);
                                } 
                   
                    
                    if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case' &&  FeedItem.isPublished == True){
                     //Modified to check if its a CaseTeammemeber with status Customer Case Contact DE381
                     ////INC0065732 - Just check if the currently logged in user is a part of the Case Team Member. 
                         System.Debug('::true Third Check' + mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId())));   
                        if(mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId())) != null ||
                        mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null){  
    
                            // Update Public comment fields on Case when Public comment posted by Customer or Partner also update the Case Status to "Updated by Customer"
                            Case lstCase = New Case(Id=feedItem.ParentId,
                                                    CS_Recent_Public_Case_Comment__c=newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.commentbody),
                                                    CS_Recent_Public_Comment_Postedby__c=UserInfo.getName(),
                                                    CS_Recent_Public_Comment_Posteddate__c=system.now(),
                                                    CS_Recent_Public_Case_Comment_Source__c='Case Comment'
                                                    );//Modifiedl to add Status DE381
                           //INC0064632 - Check for the indicator is ready to start flagging the Case as Updated by Customer.  
                            System.Debug('::Third Check' + mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c);                   
                            if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == true && mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId())) != null ){
                                lstCase.Status = 'Updated by customer';
                            } //INC0064632 - Ends here 
                            else if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == true && mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null ){
                                lstCase.Status = 'Updated by customer';
                            }
                            
                            lstCaseUpdate.add(lstCase);  
                            LstfeedItem.add(feedItem);
                            
                            //If the role of the Case Team Member is support or Partner, change it to Customer case Contact.
                                if(mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(feedItem.createdbyid)) != null){
                                    if (ctmRecord.TeamRole.Name == 'Partner' || ctmRecord.TeamRole.Name == 'Customer Support'){
                                      ctmRecord.TeamRoleId = mapCTMRole.get('CUSTOMER CASE CONTACT');
                                     
                                      lstCTMUpdate.add(ctmRecord);
                                    }
                                }
                                
                            }
                        else {
     
                            System.Debug('::Third check Check');
                            Case lstCase = New Case(Id=feedItem.ParentId,
                                                    CS_Recent_Public_Case_Comment__c=newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.commentbody),
                                                    CS_Recent_Public_Comment_Postedby__c=UserInfo.getName(),
                                                    CS_Recent_Public_Comment_Posteddate__c=system.now(),
                                                    CS_Recent_Public_Case_Comment_Source__c='Case Comment',CS_Public_Comment_By_Internal_User__c = true);
                            System.Debug('::Fourth Check' + mapCaseToCaseTeamCount.get(feedItem.ParentId));
                            if (mapCaseToCaseTeamCount.get(feedItem.ParentId) == 0)
                            {
                                lstCase.CS_Public_Comment_By_Internal_User__c = false;
                            }
                            System.Debug('::Fifth Check' + lstCase.CS_Public_Comment_By_Internal_User__c);
                            lstCaseUpdate.add(lstCase);  
                            LstfeedItem.add(feedItem);
                        }
    
                    }
                    // Check Feed Item is for Private Post   to send it for Email Notification to Internal Users 
                    else if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case' &&  FeedItem.isPublished == False){
                    
                      System.Debug('::4th check');
                            Case lstCase = New Case(Id=feedItem.ParentId,
                                                    CS_Recent_Private_Comment__c=newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.commentbody),
                                                    CS_Recent_Private_Comment_Postedby__c=UserInfo.getName(),
                                                    CS_Recent_Private_Comment_Posteddate__c=system.now());
                        /*
                        if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == false && mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c != null && 
                        mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) == null)
                        {
                        lstCase.CS_Public_Comment_By_Internal_User__c = true;
                        }*/
                        if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == true && mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null ){
                                lstCase.Status = 'Updated by customer';
                            }                          
                        lstCaseUpdate.add(lstCase);      
                        LstfeedItem.add(feedItem);
                        
                    }  
                   
                }
            }
             
            // query all public textpost comments related that are in caseIdSet 
            // INC0065732 - Just check if the currently logged in user is a part of the Case Team Member. 
            //UserInfo.getProfileId() !=CProfileId && UserInfo.getProfileId() !=PProfileId && UserInfo.getProfileId() !=PSProfileId
            if(mapUserIdToCaseTeamMember.get(UserInfo.getUserId()) == Null && (UserInfo.getProfileId() !=PSSTDProfileId || UserInfo.getProfileId()!=PSPSAProfileId || UserInfo.getProfileId() != PSProfileId)){

                List<FeedItem> relatedCaseFeedItemList = [Select Id, ParentId, Visibility from FeedItem where ParentId in :caseIdSet and Visibility = 'AllUsers' and Type = 'TextPost' and Id not in :newFeedItemId];
                System.debug('relatedCaseFeedItemList ' + relatedCaseFeedItemList); 

                if ((relatedCaseFeedItemList == null || relatedCaseFeedItemList.isEmpty()) && !newFeedItemId.isEmpty()) {
                    List<CaseMilestone> caseMileStoneList = [Select Id, CaseId, CompletionDate, IsCompleted from CaseMilestone 
                                                             where CaseId in :caseIdSet and MilestoneType.Name like '%Initial Response%'
                                                             and IsCompleted=false ];
                                                             // Fixed for INC0063973 added IsCompleted check
                    for (CaseMilestone cm : caseMileStoneList) {
                        cm.CompletionDate = Datetime.now();

                        caseMilestoneListToUpdate.add(cm);
                    }
                }  
                else if(newFeedItemId!=null && !newFeedItemId.isEmpty()){

                    List<CaseMilestone> caseMileStoneList = [Select Id, CaseId, CompletionDate, IsCompleted from CaseMilestone 
                                                             where CaseId in :caseIdSet and MilestoneType.Name like '%Initial Response%' 
                                                             and IsCompleted=false ];

                    for (CaseMilestone cm : caseMileStoneList) {
                        cm.CompletionDate = Datetime.now();

                        caseMilestoneListToUpdate.add(cm);
                    }                                         

                }   
            } 
           
        }

        if(Trigger.isUpdate){


            Map<Id,CaseComment> casecommentMap = new  Map<Id,CaseComment>(); 
            System.debug('Iam Inside the Case Comment Update');
            Set<Id> newFeedItemId = new Set<Id>();
            for (SObject cco : Trigger.new) {
                CaseComment CC = (CaseComment)cco;
                Map<Id, casecomment> CCOldMap = (Map<Id, casecomment>)Trigger.oldMap;
                if (CC.isPublished ==True && CCOldMap.get(CC.Id).isPublished==False){
                    System.debug('+++++++++++You are trying to Change it to  Public+++++++++');
                    casecommentMap.put(cc.id,cc);
                    System.debug('+++++++++++Added to Map +++++++++');
                    }    
              }

            for (SObject CaseCO : Trigger.new){
                casecomment cco = (casecomment)CaseCO;

                if(casecommentMap.get(cco.id)!= Null)
                {
                    System.debug('+++++++++++Inside Raise Exception Area+++++++++');
                    cco.addError('System Alert: Private comment cannot be converted to a public comment.');     
                }
            } 
        }
    }

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(SObject so) {}

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(SObject oldSo, SObject so) {}

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so) {}

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(SObject so) {}

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(SObject oldSo, SObject so) {      

    }

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(SObject so) {}

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        
            //Insert new Case Team Member 
            if (lstCTMInsert != null && !lstCTMInsert.isEmpty()){
                try {
                    if (!(bypass.CS_Batch_Context__c)){
                        System.Debug( '::lstCTMInsert' + lstCTMInsert);
                        Insert lstCTMInsert;
                    }
                } catch (DmlException ex){
                    System.debug('DmlException on Case Team Insert ' + ex.getMessage());
                }

            }
            //Update the Case Team Member 
            if (lstCTMUpdate != null && !lstCTMUpdate.isEmpty()) {
                try {
                    if (!(bypass.CS_Batch_Context__c)){
                        update lstCTMUpdate ;
                    }
                } catch (DmlException ex) {
                    System.debug('DmlException on Case Team Update ' + ex.getMessage());
                }
            }
             //  Update Case Milestone Response Target on first Public comment
            if (caseMilestoneListToUpdate != null && !caseMilestoneListToUpdate.isEmpty()) {
                try {
                    if (!(bypass.CS_Batch_Context__c)){
                        update caseMilestoneListToUpdate;
                    }
                } catch (DmlException ex) {
                    System.debug('DmlException on Case Milestone Update ' + ex.getMessage());
                }
            }
        
             //  Copy the last Public comment to Case Record   
            if (lstCaseUpdate != null && !lstCaseUpdate.isEmpty()) {
                try {
                    system.debug('lstCaseUpdate==' +lstCaseUpdate);
                    if (!(bypass.CS_Batch_Context__c)){
                        update lstCaseUpdate;
                    }
                } catch (DmlException ex) {
                    System.debug('DmlException on  Copying Public Comment to Case' + ex.getMessage());
                }
            }
        
            // Calling  Internal Email on Private Posting 
            if(Lstfeeditem!=null) {
                try {
                    system.debug('LstfeedItem==' +LstfeedItem);
                    if (!(bypass.CS_Batch_Context__c)) {
                        CS_FeedItemEmailHelper CSFeed= new CS_FeedItemEmailHelper();
                        CSFeed.SendCaseCommentEmail(LstfeedItem); 
                    }
                  }
                  catch (Exception ex) {
                    System.debug('Exception  on Sending Email on Case Feed to Internal Users' + ex.getMessage());
                 }
               }

    }
}