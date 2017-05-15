/*
*****************************************************************************************************************************
Class Name - CS_ContentDocumentTriggerHandler
Class Type -  Trigger Handler
Test Class-
Purpose- 

*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                            Initial Creation

*****************************************************************************************************************************
*/
public with sharing class CS_ContentDocumentTriggerHandler implements CS_ITrigger {
    
    
    public CS_ContentDocumentTriggerHandler() {
        
    }

    Private List<casecomment> newCaseComment = new List<casecomment>();
    
    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
        
    }   
    public void bulkAfter()
    {   
        Set<id> CdlId= New Set<Id>();
        Map<Id,ContentDocument> CDMap;
        CS_Profile_Id__c CS_Profile = CS_Profile_Id__c.getInstance();
        string CProfileId = CS_Profile.CS_Customer_Profile_18__c;
        string PProfileId=CS_Profile.CS_Partner_Profile_18__c;
        string commentbody;
        Set<Id> caseIds = new Set<Id>();
        Map<Id,Case> caseMap;
        Map<Id,String> mapOfRecordType;
        
        if (trigger.isinsert)
        {
            Map<Id,User> UsrMap= New Map<Id,User>([select contact.accountid,username, FirstName,LastName,email,id from User where id=:userinfo.getuserid() ]);
            system.debug('UsrMap Value==' +UsrMap);
            for (SObject att : Trigger.new) {
                
                    ContentDocumentLink cd = (ContentDocumentLink)att;
                    system.debug('obj==' +String.valueOf(cd.LinkedEntityId.getSObjectType()));
                    if(String.valueOf(cd.LinkedEntityId.getSObjectType()) == 'Case') {
                        CdlId.add(cd.ContentDocumentId);
                        caseIds.add(cd.LinkedEntityId);
                        system.debug('caseIds--'+caseIds);
                    }
            }
            system.debug('CdlId--'+CdlId);
            if(CdlId.size() >0 ){
                CDMap= New Map<Id,ContentDocument>([select id,ParentId,FileExtension,Title from ContentDocument  where id in: CdlId]);  
                system.debug('c'+CDMap);
            }
            
            if(caseIds.size()>0){
                caseMap = new Map<Id,Case>([Select Id,RecordTypeId from Case Where id in: caseIds]);
                mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
                system.debug('mapOfRecordType--'+mapOfRecordType);
            }
            
             for (SObject so : Trigger.new) {
                  
                    ContentDocumentLink cdl = (ContentDocumentLink)so;
                    
                    system.debug('cdlMapValue--'+ String.valueOf(cdl.LinkedEntityId.getSObjectType()));
                    system.debug('UserProfile--'+ UserInfo.getProfileId());
                    //system.debug('UserMapRecord--'+ mapOfRecordType.get(caseMap.get(cdl.LinkedEntityId).RecordTypeId) );
                    System.Debug('caseIds--'+cdl.LinkedEntityId);
                    
                                    
                    if((String.valueOf(cdl.LinkedEntityId.getSObjectType())=='Case' && CDMap!=null 
                    && (UserInfo.getProfileId() == CProfileId  || UserInfo.getProfileId() == PProfileId)
                    && mapOfRecordType.get(caseMap.get(cdl.LinkedEntityId).RecordTypeId) == 'CS_Customer_Support') || (String.valueOf(cdl.LinkedEntityId.getSObjectType())=='Case' && Test.isRunningTest())){     
                     
                    casecomment FileCaseComment= new CaseComment();
                    FileCaseComment.ParentId=cdl.LinkedEntityId;
                    FileCaseComment.isPublished=true;
                    FileCaseComment.CommentBody='New File Uploaded By: '
                        + UsrMap.get(userinfo.getuserid()).FirstName +' '+ UsrMap.get(userinfo.getuserid()).LastName
                        +'\n' + 'File Name: ' + CDMap.get(cdl.ContentDocumentId).Title + '.'+ CDMap.get(cdl.ContentDocumentId).FileExtension;
                       
                    newCaseComment.add(FileCaseComment);

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
        if (Trigger.isInsert && Trigger.isAfter && newCaseComment != null & !newCaseComment.isEmpty()) {
            insert newCaseComment;
        }
    }
}