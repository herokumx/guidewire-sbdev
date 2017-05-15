/*
******************************************************************************************************************************
Controller Class Name- UTL_CS_CaseTeamMemberUtility
Object - 
Purpose- UTIL Class
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Mani     manig@slalom.com  9/11/2016     Removed Debug Statements
Mani     manig@slalom.com  9/17/2016     Bug Fix to Delete Case Team Member when ACP is downgraded from 
                                         Customer Support/Customer Support(Read Only) to Customer General
Mani     manig@slalom.com  09/21/2016    Bug Fix for DE1085 
Mani     manig@slalom.com  09/22/2016    Bug Fix for DE953, DE1145,DE1099,DE1100
Suchitra spurushotham      11/15/2016    Bug INC0065032 = Whenever ACP is de-activated and activated, the case team member with role customer case contact is deleted. This prevents 
         @guidewire.com                  from updating the Case Status to Updated by customer when the contact sends an email. 
*****************************************************************************************************************************
*/
public class UTL_CS_CaseTeamMemberUtility {

    static Map<String, Id> accessTypeRoleMap {get;set;}

    // This method is used to create case team member based on ACP
    public static List<CaseTeamMember> createCaseTeamMember(List<Case> caseList, Set<String> accessTypes, List<CS_Asset_Contact_Permissions__c> assetContactList) {

        Map <id,Case>   CaseMap=  new Map<id,case>();
        Map <id,CS_Asset_Contact_Permissions__c>   ACPMap=  new Map<id,CS_Asset_Contact_Permissions__c>();

        for(case  cs: caseList){
            CaseMap.put(cs.id,cs);
        }

        for(CS_Asset_Contact_Permissions__c  acp: assetContactList){
            ACPMap.put(acp.id,acp);
        }
    
        // query Case Team Roles where name matches access type of contact assets
        accessTypes.add('Customer Case Contact');
        List<CaseTeamRole> ctrList = [Select Id, Name, AccessLevel from CaseTeamRole where Name in :accessTypes];
        Map<Id, Id> contactUserMap = getContactUserMap(assetContactList);
        
        accessTypeRoleMap = getAcessTypesMap(ctrList);
        System.debug('accessTypeRoleMap ' + accessTypeRoleMap);
        
        List<CaseTeamMember> ctmListToInsert = new List<CaseTeamMember>();
        for (Case c : caseList) {
            for (CS_Asset_Contact_Permissions__c ac : assetContactList) {
            // Added check to create Case TeamMember only for  Case- Parent Asset id Matching to ACP - Asset Id
             if( ac.cs_asset__c==c.CS_Parent_AssetId__c){
                CaseTeamMember ctm = new CaseTeamMember();
                if (contactUserMap != null && contactUserMap.get(ac.CS_Contact__c) != null) {
                    if (accessTypeRoleMap != null && !accessTypeRoleMap.isEmpty() && accessTypeRoleMap.get(ac.CS_Access_Type__c.toUpperCase()) != null ) {
                            Id thisContactId = contactUserMap.get(ac.CS_Contact__c);
                            ctm.MemberId = thisContactId;
                            ctm.ParentId = c.Id;
                            //ctm.TeamRoleId = accessTypeRoleMap.get(ac.CS_Access_Type__c.toUpperCase()); ////INC0065032 Commented
                            //INC0065032 - Check if the CaseTeam Member ID is the same as the Case Contact's User ID. If Yes then The relvant role should be Customer Case Contact
                            if (c.contactId == ac.CS_Contact__c){
                                ctm.TeamRoleId = accessTypeRoleMap.get('CUSTOMER CASE CONTACT');
                            }else {
                                ctm.TeamRoleId = accessTypeRoleMap.get(ac.CS_Access_Type__c.toUpperCase());
                            } //INC0065032 - Ends here.  
                            System.debug('CTM==='+ctm);
                            ctmListToInsert.add(ctm);
                        }
                    }
                }
            }
        }
        system.debug('ctmListToInsert=='+ctmListToInsert);
        return ctmListToInsert;
    }

    //create a case team member(s) and assign to a particular accessType
    public static List<CaseTeamMember> createCaseTeamMember(Set<Id> caseIds, Set<Id> memberIds, Set<String> accessTypes) {
        System.debug('Iam Called from Second CreateCaseTeamMember');
        List<CaseTeamRole> ctrList = [Select Id, Name, AccessLevel from CaseTeamRole where Name in :accessTypes];
        accessTypeRoleMap = getAcessTypesMap(ctrList);
        List<CaseTeamMember> newCaseTeamMemberList = [Select MemberId, ParentId, TeamRoleId from CaseTeamMember where MemberId in :memberIds and ParentId in :caseIds];
        List<CaseTeamMember> caseTeamMemberListToCreate = new List<CaseTeamMember>();
        if(newCaseTeamMemberList.size()==0) {
            for(Id caseId : caseIds) {
                for(Id memberId : memberIds) {
                    for(String accessType : accessTypes) {
                        if (accessTypeRoleMap != null && !accessTypeRoleMap.isEmpty() && accessTypeRoleMap.get(accessType.toUpperCase()) != null ) {
                            CaseTeamMember ctm = new CaseTeamMember();
                            ctm.parentId = caseId;
                            ctm.memberId = memberId;
                            ctm.teamroleid = accessTypeRoleMap.get(accessType.toUpperCase());
                            caseTeamMemberListToCreate.add(ctm);
                        }
                    }
                }
            }
        } else {
            for (CaseTeamMember ctm : newCaseTeamMemberList) {
                if(!memberIds.contains(ctm.MemberId)){
                    for (String accessType : accessTypes) {
                        if (accessTypeRoleMap != null && !accessTypeRoleMap.isEmpty() && accessTypeRoleMap.get(accessType.toUpperCase()) != null) {
                            ctm.TeamRoleId = accessTypeRoleMap.get(accessType.toUpperCase());
                            caseTeamMemberListToCreate.add(ctm);
                        }
                    }
                }
            }
        }

        return caseTeamMemberListToCreate;
    }

    public static List<CaseTeamMember> updateCaseTeamMember(Set<Id> caseIds, Set<Id> memberIds, Set<String> accessTypes) {
        List<CaseTeamRole> ctrList = [Select Id, Name, AccessLevel from CaseTeamRole where Name in :accessTypes];
        system.debug('Case Team Role==' +ctrList);
        accessTypeRoleMap = getAcessTypesMap(ctrList);
        system.debug('accessTypeRoleMap' +accessTypeRoleMap);
        List<CaseTeamMember> newCaseTeamMemberList = [Select MemberId, ParentId, TeamRoleId from CaseTeamMember where MemberId in :memberIds and ParentId in :caseIds];
        system.debug('newCaseTeamMemberList' +newCaseTeamMemberList);
        List<CaseTeamMember> caseTeamMemberListToUpdate = new List<CaseTeamMember>();

        if (accessTypeRoleMap != null && !accessTypeRoleMap.isEmpty() && accessTypes != null && !accessTypes.isEmpty()) {
            for (CaseTeamMember ctm : newCaseTeamMemberList) {
                for (String accessType : accessTypes) {
                    if (accessTypeRoleMap.get(accessType.toUpperCase()) != null) {
                        ctm.TeamRoleId = accessTypeRoleMap.get(accessType.toUpperCase());
                        caseTeamMemberListToUpdate.add(ctm);
                    }
                }
            }
        }
        return caseTeamMemberListToUpdate;
    }

    public static List<CaseTeamMember> deleteCaseTeamMember(Set<Id> memberIdSet, Set<Id> caseIdSet) {
        //System.debug('------Iam Called ---------');
        //System.debug('memberIdSet' + memberIdSet);
        //System.debug('caseIdSet' + caseIdSet);
        List<CaseTeamMember> caseTeamMemberToDelete;
        // Added Null check  by Mani G on 09/17 
        if(caseIdSet!=null && !caseIdSet.isEmpty()){
                //system.debug('----------Case Id Set is Not Null -------');
                caseTeamMemberToDelete = [Select Id from CaseTeamMember where MemberId in :memberIdSet and ParentId in :caseIdSet];
        }
        else if  (caseIdSet==null && caseIdSet.isEmpty()) {

                //system.debug('----------Case Id Set is Null -------');
                caseTeamMemberToDelete = [Select Id from CaseTeamMember where MemberId in :memberIdSet];
        }
        else{
                //system.debug('----------Inside Else Block -------');
               caseTeamMemberToDelete = [Select Id from CaseTeamMember where MemberId in :memberIdSet];  
            }
        return caseTeamMemberToDelete;
    }

    public static Map<String, Id> getAcessTypesMap(List<CaseTeamRole> ctrList) {
        Map<String, Id> accessTypeMap = new Map<String, Id>();
        for (CaseTeamRole ctr : ctrList) {
            if (!accessTypeMap.containsKey(ctr.AccessLevel)) {
                accessTypeMap.put(ctr.Name.toUpperCase(), ctr.Id);
            }
        }

        return accessTypeMap;
    }

    public static Map<Id, Id> getContactUserMap(List<CS_Asset_Contact_Permissions__c> acpList) {
        Set<Id> contactIdSet = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c acp : acpList) {
            contactIdSet.add(acp.CS_Contact__c);
        }
        Map<Id, Id> contactToUserMap = new Map<Id, Id>();
        // Added Isactive check  for DE1085 
        List<User> users = [Select Id, Name, ContactId from User where ContactId in :contactIdSet and isactive=true];
        for (User u : users) {
            contactToUserMap.put(u.ContactId, u.Id);
        }
        return contactToUserMap;
    }
    

}