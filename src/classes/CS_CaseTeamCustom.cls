/*
******************************************************************************************************************************
Controller Class Name- CS_CaseTeamCustom
Object - Case
Purpose- 
*****************************************************************************************************************************

Name            Email              Date         Notes 
Alice Jones                                     Initial Creation

*****************************************************************************************************************************
*/
public class CS_CaseTeamCustom {
    
    public String caseId { get; set; }
    public List<CaseTeamMember> caseContacts;
    Map<Id,String> userMap = new Map<Id,String>();
    Public Case  C;
    ApexPages.StandardController sController;  
    
    public CS_CaseTeamCustom() {
        //caseId = apexpages.currentpage().getparameters().get('id');
    }
    public CS_CaseTeamCustom(ApexPages.StandardController stdController) {
        this.C = (Case)stdController.getRecord();
        //caseId = apexpages.currentpage().getparameters().get('id');
        caseId = C.Id;
    }
    
    public List<CaseTeamMember> getCaseContacts() {
        if(caseContacts == null && caseId != null) {
            caseContacts = new List<CaseTeamMember>([
                SELECT ParentId, MemberId, Member.Name,
                TeamRoleId, TeamRole.Name, TeamRole.AccessLevel, 
                LastModifiedBy.Name, LastModifiedDate
                FROM CaseTeamMember 
                WHERE ParentId =:caseId
                AND TeamRole.Name NOT IN ('Customer Support', 'Customer Support (View Only)', 'Partner')]);
        }
        
        if(caseContacts.size()>0) {
            for(CaseTeamMember mem : caseContacts) {
                User[] users = [SELECT Id, UserType FROM User WHERE Id = :mem.MemberId];
                if(users.size()>0) {
                    if(users[0].UserType.contains('Partner')) {
                        userMap.put(mem.MemberId,'Partner');
                    } else if(users[0].UserType!='Standard'){
                        userMap.put(mem.MemberId,'Customer Portal User');
                    } else {
                        userMap.put(mem.MemberId,'User');
                    }
                }
            }
        }
        
        return caseContacts;
    }
    
    public Map<Id,String> getUserMap() {
        return userMap;
    }

}