/*
******************************************************************************************************************************
Controller Class Name- CS_EmailmessageTriggerHandler
Object - EmailMessage
Purpose- Trigger Handler 
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Suchitra P spurushotham@guidewire.com    Enhancement DE381 - Everytime an Email response creates a case comment, update the case public comment fields. 
Suchitra spurushotham@guidewire.com    INC0064632 Update the Status to Updated By Customer only after the Internal Support Rep touches the case by adding a Public Case comment. 
*****************************************************************************************************************************
*/
public with sharing class CS_EmailmessageTriggerHandler  implements CS_ITrigger {
    
    Private List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
    Private List<CaseMilestone> caseMilestoneListToUpdatefinal = new List<CaseMilestone>();
    private List<CaseComment> lstCaseComments = new List<CaseComment>(); //DE381 
    private List<Case> lstCase = new List<Case>();
    private Map<Id,String> mapOfRecordType;

    public CS_EmailmessageTriggerHandler() {
        
    }


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

        if (Trigger.isInsert)
        {
            Set<id> setemailMessageCase= New Set<id>();
            Set<id> setemailMessage= New Set<id>();
            Set<string> contactEmails= New Set<string>();
            Set<id> caseIds= New Set<id>();         
            Map<String,String> setToemailMessage= New Map<String,String>();
            Map<Id,Case> caseMap;
            Map<string,User> userMap = new Map<string,User>();
            Map<String,CaseTeamMember> mapCaseTeamMember = new Map<String,CaseTeamMember>();


            for(SObject so: Trigger.new){
                emailmessage em = (emailmessage)so;
                if(em.ParentId !=null){
                 if (String.valueOf(em.ParentId.getSObjectType())=='Case' ){
                    setemailMessageCase.add(em.ParentId) ;
                    setemailMessage.add(em.id);
                    setToemailMessage.put(em.ToAddress,em.subject);
                    caseIds.add(em.ParentId);
                    contactEmails.add(em.FromAddress);

                 }
                }
            }
           
            if(caseIds.size()>0){
                caseMap = new Map<Id,Case>([Select Id,RecordTypeId,CS_Public_Comment_By_Internal_User__c from Case Where id in: caseIds]);
                mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Case');
                system.debug('mapOfRecordType--'+mapOfRecordType);
            }   

            if(contactEmails.size()>0){
                List<User> usrList = [Select Id,contact.email from User Where contact.email in: contactEmails and isactive = true];
                for (user u: usrList){       
                    
                    userMap.put(u.contact.email,u);
                }
                //DE381
                List<CaseTeamMember> lstCaseTeamMember = [Select MemberId, ParentId from CaseTeamMember Where Member.Email in: contactEmails AND TeamRole.Name = 'Customer Case Contact' AND ParentId in:setemailMessageCase];
                for (CaseTeamMember ctm: lstCaseTeamMember){
                    mapCaseTeamMember.put(String.ValueOf(ctm.ParentId) + String.ValueOf(ctm.MemberId), ctm);
                    
                }
                
                    
            }           

        for(SObject To: Trigger.new){
                emailmessage emsg = (emailmessage)To;
         if(emsg.ParentId !=null){
                System.debug('Case Parent Id'+emsg.ParentId);

                // create case comment

                if(String.valueOf(emsg.ParentId.getSObjectType())=='Case' 
                    && mapOfRecordType.get(caseMap.get(emsg.ParentId).RecordTypeId) == 'CS_Customer_Support'){
                    //DE381 
                    Case caseRec = new Case();    
                    caseRec.Id = emsg.ParentId;
                    //DE381 ends here 
                    CaseComment caseComm = new CaseComment();
                    caseComm.parentid = emsg.ParentId;
                    if(emsg.TextBody.length() > 3960){
                        caseComm.commentbody = emsg.TextBody.substring(0,3950); 
                        caseRec.CS_Recent_Public_Case_Comment__c = emsg.TextBody.substring(0,3950); //DE381 
                    }else{
                        caseComm.commentbody = emsg.TextBody; 
                        caseRec.CS_Recent_Public_Case_Comment__c = emsg.TextBody; //DE381 
                    }
                    caseComm.ispublished = true;
                    if (userMap != null && !userMap.isEmpty()) {
                        caseComm.createdbyid=userMap.get(emsg.FromAddress).id;
                       
                        //DE381 - Check if the corresponding user has a CaseTeamMember with the Role Customer Case Contact to Case. If Yes, then update the Status of the Case to 'Updated by Customer' 
                        if (mapCaseTeamMember.get(String.ValueOf(caseRec.Id) + String.ValueOf(caseComm.createdbyid)) != Null && caseMap.get(emsg.ParentId).CS_Public_Comment_By_Internal_User__c == True)
                        {
                            caseRec.Status = 'Updated by customer';
                        }//DE381 Ends here 
                       
                    }
                    //DE381 
                    caseRec.CS_Recent_Public_Case_Comment_Source__c = 'Email';
                    caseRec.CS_Recent_Public_Comment_Postedby__c = UserInfo.getName();
                    caseRec.CS_Recent_Public_Comment_Posteddate__c = system.now();
                    lstCase.add(caseRec);
                    //DE381 
                    lstCaseComments.add(caseComm);
                }   

                if(String.valueOf(emsg.ParentId.getSObjectType())=='Case' ){
                            System.debug('SObject'+emsg.ParentId.getSObjectType());
                        if(CS_Case_Util.AutoCloseResponseTime_FirstEmail( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
                                System.debug('setemailMessageCase'+setemailMessageCase);
                                System.debug('setemailMessage'+setemailMessage);
                                System.debug('setToemailMessage'+setToemailMessage);
                                caseMilestoneListToUpdate=CS_Case_Util.AutoCloseResponseTime_FirstEmail( setemailMessageCase, setemailMessage, setToemailMessage);
                                //caseMilestoneListToUpdatefinal.add(caseMilestoneListToUpdate);
                                caseMilestoneListToUpdatefinal.addall(caseMilestoneListToUpdate);
                        }

                }
            
                if (String.valueOf(emsg.ParentId.getSObjectType())=='Case'  && emsg.subject.contains(System.Label.CS_Response_Target_Milestone) ){

                        if(CS_Case_Util.AutoCloseResponseTime( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
                                caseMilestoneListToUpdate=CS_Case_Util.AutoCloseResponseTime( setemailMessageCase, setemailMessage, setToemailMessage);
                                //caseMilestoneListToUpdatefinal.add(caseMilestoneListToUpdate);
                                caseMilestoneListToUpdatefinal.addall(caseMilestoneListToUpdate);
                        }

                }


                if (String.valueOf(emsg.ParentId.getSObjectType())=='Case'  && emsg.subject.contains(System.Label.CS_Preliminary_Action_Plan_Milestone) ){

                        if(CS_Case_Util.AutoClosePrelimAPTarget( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
                                caseMilestoneListToUpdate=CS_Case_Util.AutoClosePrelimAPTarget( setemailMessageCase, setemailMessage, setToemailMessage);
                                //caseMilestoneListToUpdatefinal.add(caseMilestoneListToUpdate);
                                caseMilestoneListToUpdatefinal.addall(caseMilestoneListToUpdate);
                        }

                }

                if (String.valueOf(emsg.ParentId.getSObjectType())=='Case'  && emsg.subject.contains(System.Label.CS_Detailed_Action_Plan_Milestone) ){

                        if(CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
                                caseMilestoneListToUpdate=CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage);
                                //caseMilestoneListToUpdatefinal.add(caseMilestoneListToUpdate);
                                caseMilestoneListToUpdatefinal.addall(caseMilestoneListToUpdate);
                        }

                }

/*
                if (String.valueOf(emsg.ParentId.getSObjectType())=='Case'  && emsg.subject.contains('Restoration Status Delivery') ){

                        if(CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
                                caseMilestoneListToUpdate=CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage);
                                //caseMilestoneListToUpdatefinal.add(caseMilestoneListToUpdate);
                                caseMilestoneListToUpdatefinal.addall(caseMilestoneListToUpdate);
                        }

                }
*/        

           }
          }

            system.debug('Case Id=' +setemailMessageCase);
            system.debug('Email Message Id=' +setemailMessage);
            system.debug('To Subject Map=' +setToemailMessage);



           /*
           if(CS_Case_Util.AutoCloseResponseTime( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
            caseMilestoneListToUpdate=CS_Case_Util.AutoCloseResponseTime( setemailMessageCase, setemailMessage, setToemailMessage);
           }

           if(CS_Case_Util.AutoClosePrelimAPTarget( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
            caseMilestoneListToUpdate=CS_Case_Util.AutoClosePrelimAPTarget( setemailMessageCase, setemailMessage, setToemailMessage);
           }


           if(CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage).size()>0){
            caseMilestoneListToUpdate=CS_Case_Util.AutoClosePrelimDPTarget( setemailMessageCase, setemailMessage, setToemailMessage);
           }

    */

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
        
        
        if (caseMilestoneListToUpdatefinal != null && !caseMilestoneListToUpdatefinal.isEmpty()) {
            try {
                update caseMilestoneListToUpdateFinal;
            } catch (DmlException ex) {
                System.debug('DmlException ' + ex.getMessage());
            }
        }
        if (lstCaseComments != null && !lstCaseComments.isEmpty()) {
            try {
                insert lstCaseComments;
            } catch (DmlException ex) {
                System.debug('DmlException ' + ex.getMessage());
            }
        }
        //DE381 
            if (lstCase != null && !lstCase.isEmpty()) {
            try {
                update lstCase;
            } catch (DmlException ex) {
                System.debug('DmlException ' + ex.getMessage());
            }
        }//DE381 
    
    }

}