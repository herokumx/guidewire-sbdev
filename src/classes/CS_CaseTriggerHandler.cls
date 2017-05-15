/*
*****************************************************************************************************************************
Class Name - CS_CaseTriggerHandler
Class Type -  Trigger Handler
Test Class-
Purpose- Case Trigger Handler


*****************************************************************************************************************************

Name            Email              Date              Notes 
Shanxu                                             Initial Creation
Mani           manig@slalom.com   09/7/2016        Bug Fix DE639
Mani           manig@slalom.com   09/9/2016        Bug Fix DE627
Mani           manig@slalom.com   09/16/2016       Test Class Fixes
*****************************************************************************************************************************
*/
public without sharing class CS_CaseTriggerHandler implements CS_ITrigger {

    private Set<Id> closedCaseIds = new Set<Id>();
    private Set<Id> CaseRestorationId= new Set<Id>();
    
    private List<CaseTeamMember> newCaseTeamMemberList = new List<CaseTeamMember>();
    private List<CaseTeamMember> newCaseTeamMemberListAll = new List<CaseTeamMember>();
    //private List<CaseTeamMember> updateCaseTeamMemberList = new List<CaseTeamMember>();
    private List<CaseTeamMember> newCaseContactList = new List<CaseTeamMember>();
    private List<CaseTeamMember> updateCaseContactList = new List<CaseTeamMember>();
    private List<CaseTeamMember> newCustomerSupportList = new List<CaseTeamMember>();
    private List<CaseTeamMember> updateCustomerSupportList = new List<CaseTeamMember>();
    
    Private List<casecomment> newCaseComment = new List<casecomment>();
    
    //for creating case team members by ACP
    //public List < Case > caseList { get; set; }
    public List < CS_Asset_Contact_Permissions__c > assetContactList { get; set; }
    
    // Constructor
    public CS_CaseTriggerHandler() {
        
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
        if (Trigger.isInsert) {

            Set<id> setCastid= New Set<id>();
            Set<id> setAsstid= New Set<id>();
            Set<id> setCaseClose= New Set<id>();
            Set<id> setCaseReOpen= New Set<id>();
            //System.debug('User Type=======' +userinfo.getUserType());
            
            for(SObject so: Trigger.new){
                Case c = (Case)so;
                 System.debug('c.recordtype.developerName ' + c.recordtype.developerName);
                 
                 if (c.Assetid !=Null){
                    setAsstid.add(c.Assetid) ;
                   // c.setOptions(dmlOpts);
                 }
                 else if( c.CS_Contact_Asset__c !=Null){
                    setCastid.add(c.CS_Contact_Asset__c) ;
                 }

            }
        
            if(setAsstid.size()>0){
                CS_Case_Util.EntMatchbyAST(setAsstid,Trigger.New);
            }    
            /*
            Commented it  out by Mani G on 09/16 as Entitlement Match by ACP is not a valid Scenario
            else if(setCastid.size()>0){
                CS_Case_Util.EntMatchbyACP(setCastid,Trigger.New);
            }
            */

        }
    }
       
    public void bulkAfter()
    {
        if (Trigger.isInsert) {

            List < Case > caseList = new List < Case > ();
            Set < Id > assetIds = new Set < Id > ();
            Set < String > assetAccessTypes = new Set < String > ();
            Set < Id > assetContactIds = new Set < Id > ();
            Set < Id> pseAssignment= new Set < Id >();

            Set < Id > caseIds = new Set < Id > ();
            Set < String > caseContactAccessTypes = new Set < String > ();
            Set < Id > caseContactIds = new Set < Id > ();
            Set < Id > newCaseContactUserIds = new Set < Id > ();
            Set < Id > updateCaseContactUserIds = new Set < Id > ();
            List< Case > caseUpateforCaseAssignment= New List< Case >();

           
            Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
        
            for (SObject so : Trigger.new) {
                Case c = (Case)so;
                caseList.add(c);
                assetIds.add(c.CS_Parent_AssetId__c);
                caseIds.add(c.Id);
                pseAssignment.add(c.CS_Project_Assignment__c);
                if(c.ContactId!=null) {
                    caseContactIds.add(c.ContactId);
                    caseContactAccessTypes.add('CUSTOMER CASE CONTACT');
                }
                
                
                // Creating case comments when a new case is created
                 if(mapOfRecordType.get(c.recordtypeid) == 'CS_Customer_Support' && c.Description!=null){
                     casecomment caseCommentObj= new CaseComment(); 
                     caseCommentObj.ParentId=c.Id;
                     if(c.Description.length() > 3960){
                        caseCommentObj.CommentBody = c.Description.substring(0,3950); 
                     }else{
                        caseCommentObj.CommentBody = c.Description; 
                     }
                     caseCommentObj.isPublished=true;
                     newCaseComment.add(caseCommentObj);  
                 }
                 
                 // Ends
            }
             //Case Assignment 
            //Fetching the assignment rules on case

            for(Case theCase:[select id,CS_Case_Record_Type__c from case where  id in:caseIds]){
                if(theCase.CS_Case_Record_Type__c=='Customer Support'){
                        Database.DMLOptions dmo = new Database.DMLOptions();
                        dmo.assignmentRuleHeader.useDefaultRule = true;
                        theCase.setOptions(dmo);
                        Database.update(theCase);    
                }

            }

            //Add Case Team Members By Asset
            //If Case Contact in the existing Asset Contact List
            //remove from asset contact list because will be adding separately

            List<CS_Asset_Contact_Permissions__c> assetContactList = [Select Id, CS_Asset__c, CS_Contact__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c 
                                                                    where CS_Asset__c in :assetIds and CS_Access_Type__c in 
                                                                    (:Label.Customer_Support, :Label.Customer_Support_View_Only, :Label.Partner)];

            Integer i = 0;
            Integer iRemoveContactId;
            for (CS_Asset_Contact_Permissions__c ac : assetContactList) {
                Id assetContactId = ac.CS_Contact__c;
                if(!caseContactIds.contains(assetContactId)) {
                    assetContactIds.add(ac.CS_Contact__c);
                    assetAccessTypes.add(ac.CS_Access_Type__c.toUpperCase());
                } else {
                    iRemoveContactId = i;    
                }
                i++;
            }
            
            if(iRemoveContactId!=null) {
                assetContactList.remove(iRemoveContactId);
            }

            
          


            //Add Customer Case Contact
            if(caseContactIds.size()>0) {
                for(User u : [SELECT Id, ContactId FROM User WHERE IsActive=true AND ContactId =: caseContactIds]) {
                    newCaseContactUserIds.add(u.Id);
                }

                Set<String> UsrId= New Set<String>();
                if(newCaseContactUserIds.isEmpty() && !pseAssignment.isEmpty()){
                    for(pse__Assignment__c ps : [Select CS_Salesforce_UserId__c from pse__Assignment__c where  id in:pseAssignment]){
                        UsrId.add(Id.valueOf(ps.CS_Salesforce_UserId__c));
                    }
                    if (!UsrId.isEmpty()){
                        for(User u : [SELECT Id, ContactId FROM User WHERE IsActive=true AND id in :UsrId]){
                            newCaseContactUserIds.add(u.Id);                     
                        }
                    }    
                }   


                
           
                    
            }
           
            if(assetContactList.size()>0) {
                newCaseTeamMemberList = UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(caseList, assetAccessTypes, assetContactList);
                newCaseTeamMemberListAll.addall(newCaseTeamMemberList);
            }
            
            
            if(newCaseContactUserIds.size()>0) {
                newCaseContactList = UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(caseIds, newCaseContactUserIds, caseContactAccessTypes);
                newCaseTeamMemberListAll.addall(newCaseContactList);
            }




        }


        if(Trigger.isUpdate) {

            Set < Id > caseIds = new Set < Id > ();
            Set < Id > assetIds = new Set < Id > ();
            Set < Id > caseContactUserIds = new Set < Id > ();
            Set < Id>  casetoReAssign= new Set<Id>();
            Map < Id, Id > caseContactUserMap = new Map < Id, Id > ();
            Map < Id, String > assetContactRoleMap = new Map < Id, String > ();

            Set < Id > assetContactIds = new Set < Id > ();

            Set < Id > newCaseContactIds = new Set < Id > ();
            Set < Id > addCaseContactUserIds = new Set < Id > ();
            Set < Id > updateCaseContactUserIds = new Set < Id > ();
            Set < String > newAccessTypes = new Set < String > ();

            Set < Id > oldCaseContactIds = new Set < Id > ();
            Set < Id > addCustomerSupportUserIds = new Set < Id > ();
            Set < Id > updateCustomerSupportUserIds = new Set < Id > ();
            Set < String > updateAccessTypes = new Set < String > ();


           
            
            for (SObject so : Trigger.new) {
                System.debug('Level 2'); 
                Case c = (Case)so;
                Map<Id, Case> CaseOldMap = (Map<Id, Case>)Trigger.oldMap;
                Id caseId = c.Id;

                //Close Cases and Restore Closed Cases
                // Added  by Mani G 09/08/2016 DE639
                // Added Verified Check to Auto Close Milestone
                if(c.status=='Closed' || c.status=='Verified'){
                    closedCaseIds.add(caseId);
                }
                if(C.CS_Restoration_Milestone_Completed__c==True && CaseOldMap.get(caseId).CS_Restoration_Milestone_Completed__c==false) {
                   CaseRestorationId.add(caseId);
                }
                if(CaseOldMap.get(caseId).status=='Closed' && c.status=='Updated by customer'){
                    casetoReAssign.add(c.id);
                }
                
                /*
                Commenting it for DE628
                if(CaseOldMap.get(caseId).status=='Verified' && c.status=='Updated by customer'){
                    casetoReAssign.add(c.id);
                }
                */
                
                //Get Old and New Case Contact Ids
                Id oldContactId = CaseOldMap.get(c.id).ContactId;
                Id newContactId = c.ContactId;
                Id newAssetId = c.CS_Parent_AssetId__c;
                assetIds.add(c.AssetId);
                caseIds.add(caseId);

                if(oldContactId!=null && oldContactId != newContactId) {
                    oldCaseContactIds.add(oldContactId);
                }
                if(newContactId!=null && oldContactId != newContactId) {
                    newCaseContactIds.add(newContactId);
                }

            }

            /*
            Commenting it for DE628
            for(Case theCase:[select id,CS_Case_Record_Type__c from case where  id in:casetoReAssign]){
                if(theCase.CS_Case_Record_Type__c=='Customer Support'){
                        Database.DMLOptions dmo = new Database.DMLOptions();
                        dmo.assignmentRuleHeader.useDefaultRule = true;
                        theCase.setOptions(dmo);
                        Database.update(theCase);    
                }

            }
            */

            
            
            System.debug('newCaseContactIds = ' + newCaseContactIds);
            System.debug('oldCaseContactIds = ' + oldCaseContactIds);
            
            
            //Get Existing Case Team Members
            for(CaseTeamMember ctm : [SELECT Id, ParentId, MemberId, TeamRoleId FROM CaseTeamMember WHERE ParentId IN :caseIds]) {
                caseContactUserIds.add(ctm.MemberId);
            }
            
            System.debug('caseContactUserIds = ' + caseContactUserIds);
            
            if(caseContactUserIds.size()>0) {
                for(User u : [SELECT ContactId, Id from User WHERE IsActive = true AND Id in :caseContactUserIds]){
                    caseContactUserMap.put(u.ContactId,u.Id);
                }
                /*
                for(Id uid : caseContactUserIds) {
                    User[] users = [SELECT ContactId, Id from User WHERE IsActive = true AND Id = :uid];
                    if(users.size() > 0) {
                        caseContactUserMap.put(users[0].ContactId,users[0].Id);
                    }
                }
                */
            }
            
            System.debug('caseContactUserMap = ' + caseContactUserMap);
            
            List<CS_Asset_Contact_Permissions__c> assetContactList = [Select Id, CS_Asset__c, CS_Contact__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c 
                                                                        where CS_Asset__c in :assetIds and CS_Access_Type__c in 
                                                                        (:Label.Customer_Support, :Label.Customer_Support_View_Only, :Label.Partner)];
    
            for(CS_Asset_Contact_Permissions__c acp : assetContactList) {
                assetContactRoleMap.put(acp.CS_Contact__c,acp.CS_Access_Type__c);
            }

            if(caseContactUserMap.size()>0) {
                    for(Id nid : newCaseContactIds) {
                        System.debug('Debug: nid = ' + nid);
                        newAccessTypes.add('CUSTOMER CASE CONTACT');
                        if(caseContactUserMap.containsKey(nid)) {
                            System.debug('Level 4a');
                            updateCaseContactUserIds.add(caseContactUserMap.get(nid));
                        } else { 
                            System.debug('Level 4b');
                            User[] users = [SELECT ContactId, Id from User WHERE IsActive = true AND ContactId = :nid];
                            if(users.size() > 0) {
                                addCaseContactUserIds.add(users[0].Id);
                            }
                        }
                    }
                
                    for(Id oid : oldCaseContactIds) {
                        if(caseContactUserMap.containsKey(oid)) {
                            updateCustomerSupportUserIds.add(caseContactUserMap.get(oid));
                            if(assetContactRoleMap.containsKey(oid)) {
                                String cContactRole = assetContactRoleMap.get(oid);
                                updateAccessTypes.add(cContactRole.toUpperCase());
                            } else {
                                updateAccessTypes.add('CUSTOMER SUPPORT');                            
                            }
                        } else { 
                            addCustomerSupportUserIds.add(oid);
                            updateAccessTypes.add('CUSTOMER SUPPORT');
                        }
                    }  

                //System.debug('addCaseContactUserIds = ' + addCaseContactUserIds + ' ' + newAccessTypes);
                //System.debug('updateCaseContactUserIds = ' + updateCaseContactUserIds + ' ' + newAccessTypes);
                //System.debug('addCustomerSupportUserIds = ' + addCustomerSupportUserIds + ' ' + updateAccessTypes);
                //System.debug('updateCustomerSupportUserIds = ' + updateCustomerSupportUserIds + ' ' + updateAccessTypes);


                if(addCaseContactUserIds.size()>0) {
                    System.debug('Level 6');
                    newCaseContactList = UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(caseIds, addCaseContactUserIds, newAccessTypes);            
                }
            
                if(updateCaseContactUserIds.size()>0) {
                    System.debug('Level 7');
                    updateCaseContactList = UTL_CS_CaseTeamMemberUtility.updateCaseTeamMember(caseIds, updateCaseContactUserIds, newAccessTypes);            
                }
            
                if(addCustomerSupportUserIds.size()>0) {
                    System.debug('Level 8');
                    newCustomerSupportList = UTL_CS_CaseTeamMemberUtility.updateCaseTeamMember(caseIds, addCustomerSupportUserIds, updateAccessTypes);            
                }

                if(updateCustomerSupportUserIds.size()>0) {
                    System.debug('Level 9');
                    updateCustomerSupportList = UTL_CS_CaseTeamMemberUtility.updateCaseTeamMember(caseIds, updateCustomerSupportUserIds, updateAccessTypes);            
                }
            }
        }
    }

        
    public void beforeInsert(SObject so)
    {
        
    }
    
    public void beforeUpdate(SObject oldSo, SObject newSo)
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
        system.debug('newCaseTeamMemberListAll==' +newCaseTeamMemberListAll);
        

        if (Trigger.isInsert && Trigger.isAfter && newCaseTeamMemberListAll !=null && !newCaseTeamMemberListAll.isEmpty()) {

            try {
                insert newCaseTeamMemberListAll;
            } catch (DmlException e) {
                System.debug('The following Error has occured ' + e.getMessage());
            }
            /*
            if(newCaseTeamMemberList != null && !newCaseTeamMemberList.isEmpty()) {
                System.debug('Debug1: newCaseTeamMemberList = ' + newCaseTeamMemberList);
                insert newCaseTeamMemberList;
            }
            if(newCaseContactList != null && !newCaseContactList.isEmpty()) {
                System.debug('Debug2: newCaseContactList = ' + newCaseContactList);
                insert newCaseContactList;
            }
            */
            
        }
        
        if(Trigger.isInsert && newCaseComment != null && !newCaseComment.isEmpty()){
            insert newCaseComment;
        }
        if (Trigger.isUpdate && Trigger.isAfter) {
            /*
            if(updateCaseTeamMemberList != null && !updateCaseTeamMemberList.isEmpty()) {
                System.debug('Debug: updateCaseTeamMemberList = ' + updateCaseTeamMemberList);
                update updateCaseTeamMemberList;
            }
            */
            if(newCaseContactList != null && !newCaseContactList.isEmpty()) {
                System.debug('Debug: newCaseContactList = ' + newCaseContactList);
                insert newCaseContactList;
            }
            if(updateCaseContactList != null && !updateCaseContactList.isEmpty()) {
                System.debug('Debug: updateCaseContactList = ' + updateCaseContactList);
                update updateCaseContactList;            
            }
            if(newCustomerSupportList != null && !newCustomerSupportList.isEmpty()) {
                System.debug('Debug: newCustomerSupportList = ' + newCustomerSupportList);
                insert newCustomerSupportList;
            }
            if(updateCustomerSupportList != null && !updateCustomerSupportList.isEmpty()) {
                System.debug('Debug: updateCustomerSupportList = ' + updateCustomerSupportList);
                update updateCustomerSupportList;
            }
        }

        if(closedCaseIds!=null  && !closedCaseIds.isEmpty()){
            CS_Caseclose_Util.CloseSTR(closedCaseIds);
        }

         if(closedCaseIds!=null  && !closedCaseIds.isEmpty()){
            CS_Caseclose_Util.CloseCMS(closedCaseIds);
        }
            
        if(CaseRestorationId!=null  && !CaseRestorationId.isEmpty()){
            CS_Case_Util.CloseRestorationMS(CaseRestorationId);
        }


    }

}