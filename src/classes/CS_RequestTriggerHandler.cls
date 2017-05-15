/*
*****************************************************************************************************************************
Class Name - CS_RequestTriggerHandler
Class Type -  Handler
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                           Initial Creation
hari                        09/22/2016         Include the FeedPost on Case for Dev Request creation and Email on Dev Request update.
Suchitra P                  10/24/2016         Added Code to Update Case whenever the feed is created or modified. (Rally Requirement #381)

*****************************************************************************************************************************
*/
public with sharing class CS_RequestTriggerHandler implements CS_ITrigger {
    public CS_RequestTriggerHandler() {
        
    }
    
     RecordType rt = [Select id,name,DeveloperName from RecordType where SobjectType = 'CS_Request__c' and DeveloperName = 'Dev_Request'];
     private List<FeedItem> CaseFeedPosts = new List<FeedItem>();
     private set<id> newReqIds = new set<id>();  // to store the New Request ids from bulk after.
     private set<id> caseIds = new set<id>();   // to store the parent(Case) ids from the bulk after.

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
        
        if(Trigger.isinsert || Trigger.IsUpdate){
            Set<Id> RequestCaseIds = new Set<Id>(); 
            Set<Id> RequestID= new Set<Id>();
            /* Added for DE97 */
            Set<Id> caseswithDevAssigned = new Set<Id>();   
            Set<Id> devAssignedUserIds= new Set<Id>();
            Map<String, CS_Request__c> csMapCaseMember = new Map<String, CS_Request__c>();
            List<CaseTeamMember> caseTeamMemberInsertList = new List<CaseTeamMember>();
            /* ends DE97 */

            //Map<Id,Id> RequestCaseMap = new Map<Id,Id> ();    

            for (SObject so : Trigger.new) {
                CS_Request__c c = (CS_Request__c)so;
                        if(c.CS_is_Active__c==True){
                        RequestCaseIds.add(c.CS_Case__c);   
                        RequestID.add(C.id);
                        }
                        //RequestCaseMap .put() 
                        
                        /* Added for DE97 */
                        /*Code added for DE970, Everytime there is a change in the DeV_assigne__c on the Request Record or if the Dev Request is newly added with an assigne
                        check if the assigne is a part of the case team member, if not create a case team member with role colloborator */

                        if (Trigger.isInsert)
                        {
                        
                               
                                if (c.Dev_Assignee__c != null)
                                {
                                    system.Debug('c.Dev_Assignee__c --' + c.Dev_Assignee__c);
                                    caseswithDevAssigned.Add(c.CS_Case__c);
                                    devAssignedUserIds.add(c.Dev_Assignee__c); 
                                    csMapCaseMember.put(String.valueOf(c.CS_Case__c) + String.valueOf(c.Dev_Assignee__c), c) ;
                                   system.Debug('csMapCaseMember1 --' + csMapCaseMember);
                                }

                        }
                        else if (Trigger.isUpdate){
                               CS_Request__c cOld =  (CS_Request__c)Trigger.oldMap.get(c.ID); /* Added for DE97 */
                            System.Debug('cOld --' + c.Dev_Assignee__c  != null);
                            if (cOld != null )
                            {
                            if (c.Dev_Assignee__c != null ){
                                    if (cOld.Dev_Assignee__c  != c.Dev_Assignee__c){
                                    caseswithDevAssigned.Add(c.CS_Case__c);
                                    devAssignedUserIds.add(c.Dev_Assignee__c); 
                                    csMapCaseMember.put(String.valueOf(c.CS_Case__c) + String.valueOf(c.Dev_Assignee__c), c) ;
                                    }
                                }
                            }
                            else if (c.Dev_Assignee__c != null) {
                            
                          
                                    caseswithDevAssigned.Add(c.CS_Case__c);
                                    devAssignedUserIds.add(c.Dev_Assignee__c); 
                                    csMapCaseMember.put(String.valueOf(c.CS_Case__c) + String.valueOf(c.Dev_Assignee__c), c) ;
                                
                                } 
                            

                        }
                        

                        /* ends DE97 */
                    
            }   
            

            List<CS_Request__c>  ErrorRequest =  New List<CS_Request__c>([Select Id,Name,CS_Case__c,CS_is_Active__c from  CS_Request__c where CS_Case__c 
                                           in :RequestCaseIds and RecordType.Developername='Dev_Request' and CS_is_Active__c=TRUE and Id Not in :RequestID] );

            
            Map<Id,Map<Id,CS_Request__c>>  MMapCaseRequest= New Map<Id,Map<Id,CS_Request__c>>();
            Map<Id,CS_Request__c> MapCSR = New Map<Id,CS_Request__c>();

            if(ErrorRequest.size() >0 ){
                for(CS_Request__c er:ErrorRequest){
                    MapCSR.Put(er.CS_Case__c,er);
                    MMapCaseRequest.put(er.CS_Case__c,MapCSR);
                }
            }

            /* Added for DE97 */
            if (caseswithDevAssigned.size() >0 ) 
            {
                List<CaseTeamMember> caseTeamMemberList = new List<CaseTeamMember> ([SELECT Id,MemberId,ParentId,TeamRole.Id, TeamRole.Name FROM CaseTeamMember Where ParentID in:caseswithDevAssigned AND MemberId in:devAssignedUserIds]);
                Map<String,CaseTeamMember> caseTeamMap = new Map<String, CaseTeamMember>();
                ID caseTeamRoleID;
                
                for (CaseTeamMember caseMember: caseTeamMemberList ){
                caseTeamMap.put(String.ValueOf(caseMember.ParentId) + String.ValueOf(caseMember.MemberId),caseMember);
                }
                
                List<CaseTeamRole> caseTeamRole = new List<CaseTeamRole>([SELECT Id,Name FROM CaseTeamRole Where Name = 'Collaborator']);
                
                if (caseTeamRole.size()>0 ){
                caseTeamRoleID = caseTeamRole[0].ID;
                
                } 
                if (caseTeamRoleID != NULL){//Note only if the CaseTeamMemberRoleID is present in the RoleID, Only then the team member role will be created. 
                for (CS_Request__c cRequest: csMapCaseMember.Values()){
                
                   
                    if (caseTeamMap.get(String.ValueOf(cRequest.CS_Case__c) + String.ValueOf(cRequest.Dev_Assignee__c)) == Null){
                    if (cRequest.Dev_Assignee__c != null){
                        CaseTeamMember newCaseTeamMember = new CaseTeamMember();
                        newCaseTeamMember.MemberId = cRequest.Dev_Assignee__c;
                        newCaseTeamMember.ParentID = cRequest.CS_Case__c;
                        newCaseTeamMember.TeamRoleId =  caseTeamRoleID ;
                        caseTeamMemberInsertList.add(newCaseTeamMember);
                    }
                    }
                }
                if (caseTeamMemberInsertList.size() > 0){
                    insert caseTeamMemberInsertList;
                }
                }
                
            
            }

            /* ends DE97 */
            /*

            for (SObject CSR : Trigger.new){
                CS_Request__c cr = (CS_Request__c)CSR;

                if(MMapCaseRequest.get(cr.CS_Case__c)!= Null)
                {

                    cr.addError('Dev Request '+(String) MMapCaseRequest.get(cr.CS_Case__c).get(cr.CS_Case__c).get('Name') + ' is Active, Case can have only one Active Dev Request' );
                    
                }

            }       
            */                     


        }



    }
    
    public void bulkAfter()
    {

        
        List<Case> lstCaseUpdate = new List<Case>();/*Added By Suchitra DE381 **/
        // Added by Hari to post the dev request created on the case feed.
        if(Trigger.isInsert)
        {
            for (SObject so : Trigger.new) 
            {
               CS_Request__c req = (CS_Request__c)so;
                if(req.recordtypeId == rt.Id)
                {
                    FeedItem post2 = new FeedItem();
                       post2.ParentId = req.CS_Case__c;
                       post2.Body = 'New Request is created: \n Request Name: ' + req.Name + '\n Request Type: ' + req.CS_Request_Type__c + '\n Request Status: ' + req.CS_Request_Status__c + '\n Information Request: ' + req.CS_Information_Request__c + '\n Desired Response: ' + req.CS_Desired_Response_Date__c + '\n Customer Impact: ' + req.CS_Customer_Impact__c;
                       post2.Title = Req.Name;
                       post2.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + req.Id;
           
                       CaseFeedPosts.add(post2);
                }

                /*Added By Suchitra DE381 **/
                Case cs = new Case();
                cs.Id = req.CS_Case__c;
                lstCaseUpdate.add(cs); /**End of DE381 **/
            }
         }
         
        if(Trigger.isUpdate)
        {
             Map<id, CS_Request__c> oldReqMap= (Map<id,CS_Request__c>)Trigger.OldMap;
            
             for (SObject so : Trigger.new) 
             {
               CS_Request__c newReq = (CS_Request__c)so;
               if(newReq.RecordTypeId == rt.Id)
               {
                  CS_Request__c oldReq = oldReqMap.get(newReq.Id);
                  if(newReq.CS_Submitted_First_Time__c == oldReq.CS_Submitted_First_Time__c && newReq.CS_Submitted_First_Time__c == true && (newReq.CS_Request_Owner__c != oldReq.CS_Request_Owner__c || newReq.Pgm_Request_Owner__c != oldReq.Pgm_Request_Owner__c || newReq.CS_Request_Status__c != oldReq.CS_Request_Status__c || newReq.CS_Information_Request__c != oldReq.CS_Information_Request__c ||
                      newReq.CS_Case__c != oldReq.CS_Case__c || newReq.CS_Escalation_Note__c != oldReq.CS_Escalation_Note__c || newReq.CS_Fix_by_Version__c != oldReq.CS_Fix_by_Version__c || newReq.CS_Customer_Commitment__c != oldReq.CS_Customer_Commitment__c ||
                      newReq.CS_Dev_Jira__c != oldReq.CS_Dev_Jira__c || newReq.CS_Associated_Jira__c != oldReq.CS_Associated_Jira__c || newReq.CS_Request_Type__c != oldReq.CS_Request_Type__c || newReq.CS_Request_Reason__c != oldReq.CS_Request_Reason__c ||
                      newReq.CS_Next_Dev_Response__c != oldReq.CS_Next_Dev_Response__c || newReq.Dev_Assignee__c!= oldReq.Dev_Assignee__c|| newReq.CS_Dev_Current_Status__c != oldReq.CS_Dev_Current_Status__c || newReq.Dev_Assignee_Group__c != oldReq.Dev_Assignee_Group__c) )
                      {
                         caseIds.add(newReq.CS_Case__c);
                         newReqIds.add(newReq.Id); 
                      }
               }

                /*Added By Suchitra DE381 **/
                Case cs = new Case();
                cs.Id = newReq.CS_Case__c;
                lstCaseUpdate.add(cs); /**End of DE381 **/
             }
             system.debug('Update Cases ==' +caseIds.size());
             system.debug('Update Req Ids==' +newReqIds.size());
          }
          
          /*Added By Suchitra DE381 **/
           if (lstCaseUpdate.size() > 0) {
              Update lstCaseUpdate; /**End of DE381 **/
          }
          
        
    }
        
    public void beforeInsert(SObject so)
    {
        

    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }
    
    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so)
    {   

    }
    
    public void afterInsert(SObject so)
    {
        
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {


    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally()
    {
         //  Post the Dev Requests created on the Case Feed.
            if (CaseFeedPosts != null && !CaseFeedPosts.isEmpty()) {
                try {
                      system.debug('PostsCreated==' +CaseFeedPosts.size() );
                      insert CaseFeedPosts;
                    }
                catch (DmlException ex) {
                    System.debug('DmlException on  creation of Posts on Case' + ex.getMessage());
                }
            }
            
            if(newReqIds != null)
            {
                try{
                     CS_DevRequestEmailHelper devEmail = new CS_DevRequestEmailHelper();
                     devEmail.SendDevRequestEmail(newReqIds,caseIds);
                   }
                catch(Exception e){
                     System.debug('Exception  on Sending Email on Dev Request to Users' + e.getMessage());
                }
        
            }
    }
}