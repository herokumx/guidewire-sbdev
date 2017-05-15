/*
******************************************************************************************************************************
Controller Class Name- CS_CaseTeamController
Object - Case
Purpose- Controller for Case TeamMember VF
*****************************************************************************************************************************

Name            Email              Date         Notes 
Alice Jones                                     Initial Creation

*****************************************************************************************************************************
*/
public class CS_CaseTeamController {
    
    public String caseId  { get; set; }
    public List<CaseTeamMember> members { get; set; }

    public CS_CaseTeamController(ApexPages.StandardController stdController) {
        caseId = apexpages.currentpage().getparameters().get('id');
        getMembers();
    }
    
    public List<CaseTeamMember> getMembers() {
        if(members == null && caseId != null) {
            members = [SELECT Member.Name, Member.Id, 
                        TeamRole.Name, TeamRole.AccessLevel, 
                        LastModifiedBy.Name, LastModifiedDate
                        FROM CaseTeamMember 
                        WHERE ParentId =:caseId
                        AND TeamRole.Name IN ('Customer Case Contact')];
        }
        return members;
    }
}