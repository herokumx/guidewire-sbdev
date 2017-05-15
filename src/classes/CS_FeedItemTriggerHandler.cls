/*
*****************************************************************************************************************************
Class Name - /*
*****************************************************************************************************************************
Class Name - CS_FeedItemTriggerHandler
Class Type -  Handler
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan Xu                        05/13/2016       Initial Creation
Mani G                         09/01/2016       Added New Field Update on Case CS_Recent_Public_Case_Comment_Source__c='Case Feed';
Mani G                         09/09/2016       Added Code to Prevent Deleting Internal Post DE51
Suchitra                       10/25/2016       Fix for DE624
Suchitra                       11/28/2016       INC0065732 Added code to remove the Profile Check and added the Case Team member check. 
*****************************************************************************************************************************
*/
public without sharing class CS_FeedItemTriggerHandler implements CS_ITrigger{

    private List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
    private List<Case> lstCaseUpdate=New List<Case>();
    private List<FeedItem> LstfeedItem= New List<FeedItem>();
    public CS_FeedItemTriggerHandler() {}
    Private List<casecomment> newCaseComment = new List<casecomment>();
    private List<CaseTeamMember> lstCTMUpdate= new List<CaseTeamMember>();
    private List<CaseTeamMember> lstCTMInsert= new List<CaseTeamMember>();
    
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
    public void bulkBefore() {
        
            // Added code for bug fix DE51
            if(Trigger.isbefore && Trigger.isdelete){

            Set<Id> Caseid= New Set<id>();
            for (SObject so : Trigger.old) {
                FeedItem feedItm = (FeedItem)so;
                if(String.valueOf(feedItm.ParentId.getSObjectType()) == 'Case'){
                    Caseid.add(feedItm.ParentId);
                }
            }
            Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
            Map<Id,Profile> mapOfProfile= GWUtilities.getProfileName(userinfo.getProfileId());
            system.debug('++++++++Caseid++++++' +Caseid);
            Map<id,Case> CaseMap= New Map<id,Case>([Select id,RecordTypeId,Recordtype.name from Case where id in :Caseid]);
            system.debug('++++++++Case Map++++++' +CaseMap);
            if(caseid!=null && !caseid.isEmpty()){
                for (SObject so : Trigger.old) {
                    FeedItem ast = (FeedItem)so;
                    if (String.valueOf(ast.ParentId.getSObjectType()) == 'Case' 
                        && (ast.Type=='TextPost' || ast.Type=='EmailMessageEvent' || ast.Type=='ContentPost')
                        &&  mapOfRecordType.get(CaseMap.get(ast.ParentId).Recordtypeid) == 'CS_Customer_Support' 
                        &&  mapOfProfile.get(userinfo.getProfileId()).name !='System Administrator') {
                        ast.addError('System Alert: Internal posts can not be deleted,please contact IS');
                    }
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
            Set<Id> contentVersionIdSet = new Set<Id>();
            Map<Id,ContentVersion> contentVersionMap;
            Map<Id,Case> mapCase = new map<Id,Case>(); 
            Map<String, ID> mapCTMRole = new Map<String, ID>();
            Map<String, pse__Assignment__c> mapProjectAssignment = New Map<String, pse__Assignment__c>();
            Map<String,CaseTeamMember> mapcaseTeamMemberAll = new Map<String,CaseTeamMember>(); //INC0065732
            Map<Id,List<CaseTeamMember>> mapCaseIdToCaseTeamMember = new Map<Id,List<CaseTeamMember>>(); //INC0065732
            Map<Id, Integer> mapCaseToCaseTeamCount = new Map<Id, Integer>(); //INC0065732
            //INC0065732 - Commenting the Profile Check.
            /*
            CS_Profile_Id__c CS_Profile = CS_Profile_Id__c.getInstance();
            string CProfileId = CS_Profile.CS_Customer_Profile_18__c;
            string PProfileId=CS_Profile.CS_Partner_Profile_18__c;
            string PSProfileId=CS_Profile.CS_Service_Profile_18__c;
           */
            CS_FeedItemEmailHelper  newCS_FeedItemEmailHelper = new CS_FeedItemEmailHelper ();
            Map<String, CaseTeamMember> mapcaseTeamMember = new Map<String,CaseTeamMember>(); //INC0065732
            Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
            
            
            for(SObject so : Trigger.new){
                
                FeedItem feedItem = (FeedItem)so;
                // if FeedItem is of type Case, add parentId to case Id Set
                if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case') {
           
                     caseIdSet.add(feedItem.ParentId);
                     createdByIds.add(feedItem.CreatedById);
                }
                
                // if current feed item is public
                if (FeedItem.Visibility == 'AllUsers') {
                    newFeedItemId.add(feedItem.Id);
                }
                
                //to query contentversion
                if (FeedItem.Type == 'ContentPost') {
                    contentVersionIdSet.add(feedItem.RelatedRecordId);
                }
                
            }
            
            if(caseIdSet.size()>0){
               mapCase = new Map<Id,Case>([Select ID, CS_Public_Comment_By_Internal_User__c,OwnerID,CS_Project_Assignment__r.pse__Project__c, RecordTypeId FROM Case Where Id In:caseIdSet]);
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
                    
                }

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
            
            if(contentVersionIdSet.size()>0){
                contentVersionMap = new Map<Id,ContentVersion>([SELECT FileExtension,Title FROM ContentVersion Where id in: contentVersionIdSet]);
            }
            
            for (SObject so : Trigger.new) {
                FeedItem feedItem = (FeedItem)so;
                CaseTeamMember ctmRecord = mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId()));
                CaseTeamMember ctmRecordAll = mapcaseTeamMemberAll.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId()));
                if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case') {
                 if (ctmRecordAll == null && mapCase.get(feedItem.ParentId).OwnerID != feedItem.CreatedById ){
                                    CaseTeamMember newCTM = new CaseTeamMember(); 
                                    newCTM.TeamRoleId = mapCTMRole.get('COLLABORATOR');
                                    if (mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null) {
                                       newCTM.TeamRoleId = mapCTMRole.get('CUSTOMER CASE CONTACT'); 
                                    }
                                    newCTM.MemberId = feedItem.CreatedById;
                                    newCTM.ParentId = feedItem.ParentId;
                                    lstCTMInsert.add(newCTM);
                                } 
               }
                if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case' &&  FeedItem.Visibility == 'AllUsers' && FeedItem.type=='TextPost'){
                     //INC0065732 - remove profile check and add the case team member check. 
                    //UserInfo.getProfileId() ==CProfileId  || UserInfo.getProfileId()==PProfileId || UserInfo.getProfileId() == PSProfileId     
                    if(mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId())) != null ||
                        mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null){  

                        // Update Public comment fields on Case when Public comment posted by Customer or Partner also update the Case Status to "Updated by Customer"
                        Case lstCase = New Case(Id=feedItem.ParentId,
                                                CS_Recent_Public_Case_Comment__c=newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.body),
                                                CS_Recent_Public_Comment_Postedby__c=UserInfo.getName(),
                                                CS_Recent_Public_Comment_Posteddate__c=system.now(),
                                                CS_Recent_Public_Case_Comment_Source__c='Case Feed');
                                                //Status='Updated by customer');
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
                    else{

                        Case lstCase = New Case(Id=feedItem.ParentId,
                                                CS_Recent_Public_Case_Comment__c=newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.body),
                                                CS_Recent_Public_Comment_Postedby__c=UserInfo.getName(),
                                                CS_Recent_Public_Comment_Posteddate__c=system.now(),
                                                CS_Recent_Public_Case_Comment_Source__c='Case Feed', CS_Public_Comment_By_Internal_User__c = true);
                         if (mapCaseToCaseTeamCount.get(feedItem.ParentId) == 0)
                            {
                                lstCase.CS_Public_Comment_By_Internal_User__c = false;
                            }
                        lstCaseUpdate.add(lstCase);  
                        LstfeedItem.add(feedItem);
                    }

                }
                // Check Feed Item is for Private Post   to send it for Email Notification to Internal Users 
                else if (String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case' &&  FeedItem.Visibility == 'InternalUsers'){

                    /*Fix for DE624 */
                    String casePrivateComment = '';
                    if (mapOfRecordType.get(mapCase.get(feedItem.ParentId).RecordTypeId) == 'CS_Customer_Support'
                    && feedItem.Type == 'ContentPost' && contentVersionMap!= null && contentVersionMap.containsKey(feedItem.RelatedRecordId))
                    {
                        String customComment = '';
                        if (newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.body) != NULL){
                            customComment = ' \n' + newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.body) ;
                        }
                        casePrivateComment =  'New file uploaded.'
                           +'\n File Name:' + contentVersionMap.get(feedItem.RelatedRecordId).Title + '.' + contentVersionMap.get(feedItem.RelatedRecordId).FileExtension + customComment ;
                    } else 
                    {
                        casePrivateComment = newCS_FeedItemEmailHelper.stripHTMLTags(FeedItem.body); 
                    }

                        
                        Case lstCase = New Case(Id=feedItem.ParentId,
                                                CS_Recent_Private_Comment__c=casePrivateComment,
                                                CS_Recent_Private_Comment_Postedby__c=UserInfo.getName(),
                                                CS_Recent_Private_Comment_Posteddate__c=system.now()); /*Fix for DE624 Ends Here*/
                    
                    /*if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == false && mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c != null && 
                        mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) == null)
                        {
                        lstCase.CS_Public_Comment_By_Internal_User__c = true;
                        }
                     */
                    if (mapCase.get(feedItem.ParentId).CS_Public_Comment_By_Internal_User__c == true && mapProjectAssignment.get(String.ValueOf(mapCase.get(feedItem.ParentId).CS_Project_Assignment__r.pse__Project__c) + String.ValueOf(feedItem.CreatedById)) != null ){
                        lstCase.Status = 'Updated by customer';
                    }       
                    lstCaseUpdate.add(lstCase);      
                    LstfeedItem.add(feedItem);
                
                
                
                
                }             
                
                if(String.valueOf(feedItem.ParentId.getSObjectType()) == 'Case' && FeedItem.Visibility == 'AllUsers'
                    && mapOfRecordType.get(mapCase.get(feedItem.ParentId).RecordTypeId) == 'CS_Customer_Support'
                    && feedItem.Type == 'ContentPost' && contentVersionMap!= null && contentVersionMap.containsKey(feedItem.RelatedRecordId)){  
                     
                        casecomment FileCaseComment= new CaseComment();
                        FileCaseComment.ParentId=feedItem.ParentId;
                        FileCaseComment.isPublished=true;
                        FileCaseComment.CommentBody='New file uploaded.'
                           +'\n File Name:' + contentVersionMap.get(feedItem.RelatedRecordId).Title + '.' + contentVersionMap.get(feedItem.RelatedRecordId).FileExtension;
                           
                        newCaseComment.add(FileCaseComment);
                }
            }
            system.debug('lstCaseUpdate 000 ==='+lstCaseUpdate);
            system.debug('LstfeedItem 0=='+LstfeedItem);
            

            /* Response Target Mile stone  Auto Close on First Public Comment posted on Case */

            // query all public textpost feedItems related that are in caseIdSet 
             //INC0065732 - remove profile check and add the case team member check. 
                    //UserInfo.getProfileId() ==CProfileId  || UserInfo.getProfileId()==PProfileId || UserInfo.getProfileId() == PSProfileId     
         if(mapcaseTeamMember.get(String.ValueOf(feedItem.ParentId) + String.ValueOf(UserInfo.getUserId())) != Null){  
        

                List<FeedItem> relatedCaseFeedItemList = [Select Id, ParentId, Visibility from FeedItem where ParentId in :caseIdSet and Visibility = 'AllUsers' and Type = 'TextPost' and Id not in :newFeedItemId];
                System.debug('relatedCaseFeedItemList ' + relatedCaseFeedItemList); 

                if ((relatedCaseFeedItemList == null || relatedCaseFeedItemList.isEmpty()) && !newFeedItemId.isEmpty()) {
                    List<CaseMilestone> caseMileStoneList = [Select Id, CaseId, CompletionDate, IsCompleted from CaseMilestone 
                                                             where CaseId in :caseIdSet and MilestoneType.Name like '%Initial Response%' and IsCompleted=false];
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


            System.debug('caseMilestoneListToUpdate ' + caseMilestoneListToUpdate);
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
    public void afterUpdate(SObject oldSo, SObject so) {}

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
                        System.debug('DmlException on Case Milestone Update' + ex.getMessage());
                    }
                }
        
            // Calling  Internal Email on Private Posting 
            if(Lstfeeditem!=null) {
                try {
                    system.debug('LstfeedItem==' +LstfeedItem);
                    if (!(bypass.CS_Batch_Context__c)) {
                        CS_FeedItemEmailHelper CSFeed= new CS_FeedItemEmailHelper();
                        CSFeed.SendCaseFeedEmail(LstfeedItem);
                    }
                  }
                  catch (Exception ex) {
                    System.debug('Exception  on Sending Email on Case Feed to Internal Users' + ex.getMessage());
                 }
             }
             
             if (Trigger.isInsert && Trigger.isAfter && newCaseComment != null & !newCaseComment.isEmpty()) {
                insert newCaseComment;
             }

    }
}