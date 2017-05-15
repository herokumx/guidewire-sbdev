/*
*****************************************************************************************************************************
Class Name - addCaseTeamMember
Class Type -  VF Controller
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Alice                                           Initial Creation
Mani                          09/10/2016        Bug Fix DE557
*****************************************************************************************************************************
*/
public  class   addCaseTeamMember {
    
    // public variables
    public Case cases;
    public List < wrapMember > memberList { get; set; }
    public String userRole { get; set; }
    public String selectedRoleId { get; set; }    
    public List< SelectOption > roleOptions { get; set; }   
    public String assetId { get; set; }
    public Boolean isErrorOnPage { get; set; }
    public string customerContactQueryStr {get;set;}
    
    // private variables
    private Map<Id, String> rolesMap;
    private Map<String, Id> roleNameToIDMap;
    private Set<String> excludedRoleSet = new Set<String>{'Customer Support', 'Customer Support (View Only)', 'Partner'};
    private Map<Id, CaseTeamMember> existingCtmMap;
    private Map<Id, CaseTeamMember> upsertMap;
    private Map<Id, CaseTeamMember> deleteMap;
    private Map<Id, Case> caseMap;

    public addCaseTeamMember(ApexPages.StandardController controller)
    {   
        if (!Test.isRunningTest()) {
            controller.addFields(new List<String>{'assetId', 'asset.ParentId'});
        }
        existingCtmMap = new Map<Id, CaseTeamMember>();
        upsertMap = new Map<Id, CaseTeamMember>();
        deleteMap = new Map<Id, CaseTeamMember>();
        caseMap = new Map<Id, Case>();
        cases = (Case) controller.getRecord();
        assetId = cases.asset.ParentId;
        System.debug('===assetId=== ' + assetId);
        
        // get roles Map - role ID -> role Name
        rolesMap = new Map<Id, String>();
        roleNameToIDMap = new Map<String, Id>();
        roleOptions = new List<SelectOption>();
        for(CaseTeamRole role : [SELECT Id, Name
                                    FROM CaseTeamRole 
                                    ORDER BY Name])
        {
            rolesMap.put(role.Id, role.Name);
            roleNameToIDMap.put(role.Name, role.Id);
            if(!excludedRoleSet.contains(role.Name))
                roleOptions.add(new SelectOption(role.Id,role.Name));
        }
        
        // construct the query string for customer case contact that to be sent to the typeahead custom components
        // Profiles required for Case Team member Are fetched from Custom Setting
        String tempQueryStr_Profile;
        for (CS_GW_Profile__c usrpforile :[select Profile_Id_18__c from CS_GW_Profile__c where CS_CTM_Search__c=true]){

            if(tempQueryStr_Profile == null)
                tempQueryStr_Profile = '\'' + usrpforile.Profile_Id_18__c + '\'';
            else
                tempQueryStr_Profile += ', \'' + usrpforile.Profile_Id_18__c + '\'';
        }
        customerContactQueryStr = ' IsActive=true and ';
        customerContactQueryStr += ' (profileid in (';
        customerContactQueryStr += tempQueryStr_Profile +')';
        customerContactQueryStr += ' or Id in (';
        String tempQueryStr;
        for(User u : [SELECT Id, FirstName, LastName FROM User 
                                                    WHERE ContactId IN 
                                                    (SELECT CS_Contact__c FROM CS_Asset_Contact_Permissions__c 
                                                                        WHERE CS_Asset__c = :assetId
                                                                        AND CS_Access_Type__c IN :excludedRoleSet
                                                                        AND CS_IsActive__c = true)
                                                    ORDER BY FirstName, LastName])
        {
            if(tempQueryStr == null)
                tempQueryStr = '\'' + u.Id + '\'';
            else
                tempQueryStr += ', \'' + u.Id + '\'';
        }
        customerContactQueryStr += tempQueryStr + '))';
        // Get the existing team members to be displayed in the UI and form the wrapper list
        memberList = new List < wrapMember > ();
        for(CaseTeamMember cl : [SELECT Id, Member.Name, Member.Id, MemberId,  
                                        TeamRoleId, TeamRole.Name, TeamRole.AccessLevel, 
                                        LastModifiedBy.Name, LastModifiedDate,ParentId
                                        FROM CaseTeamMember 
                                        WHERE ParentId =: cases.Id
                                        AND TeamRole.Name NOT IN :excludedRoleSet]) {
            wrapMember wMember = new wrapMember(cl);
            memberList.add(wMember);
            System.debug('====memberList==== ' + memberList);
        }
        
        // All Team Members
        for(CaseTeamMember m : [SELECT MemberId, Id, TeamRoleId FROM CaseTeamMember WHERE ParentId =: cases.Id]) {
            existingCtmMap.put(m.MemberId, m);
        }
    }
    
    // When the Role in a row is changed, reset the other columns
    public void changeUserRole()
    {
        Integer rowNo = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowNo'));
        if(memberList[rowNo].ctm.Id != null)
        {
            deleteMap.put(memberList[rowNo].MemberId, new CaseTeamMember(Id = memberList[rowNo].ctm.Id));
        }
        memberList[rowNo].ctm = new CaseTeamMember(ParentId = cases.Id);
        memberList[rowNo].roleName = rolesMap.get(memberList[rowNo].roleId);
        memberList[rowNo].Id = memberList[rowNo].memberId = memberList[rowNo].memberName = null;
    }
    
    // Add New Member
    public void addRow() {
        wrapMember ctmWrapper = new wrapMember(new CaseTeamMember(ParentId = cases.Id));
        ctmWrapper.roleId = selectedRoleId;
        memberList.add(ctmWrapper);
    }
    
    // When a row is deleted, check if the role exists as ACP - if so, delete from UI but update the ACP's access type in the backend
    // if doesn't existing as ACP, delete from UI and backend
    public void deleteRow()
    {
        Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
        Id memberContactID;
        wrapMember wMem = memberList[rowIndex];
        System.debug('==== wMem === ' + wMem);
        memberList.remove(rowIndex);
        if(wMem.MemberId != null && wMem.MemberId != '')
        {
            memberContactID = getContactID(wMem.memberId);
        }
        if(wMem.Id != null && memberContactID != null)
        {
            CS_Asset_Contact_Permissions__c acp = getACP(memberContactID);
            System.debug('===acp==== ' + acp + '====memberContactID=== ' + memberContactID);
            if(roleNameToIDMap.containsKey(acp.CS_Access_Type__c))
            {
                upsertMap.put(wMem.memberID, new CaseTeamMember(Id = wMem.Id, TeamRoleId = roleNameToIDMap.get(acp.CS_Access_Type__c)));
                case caseRec = new Case();
                if (wMem.ctm.Parentid != Null){
                caseRec.Id = wMem.ctm.Parentid;
                caseMap.put(caseRec.Id, caseRec);
                }

            }
            else
            {
                if(wMem.id!=null)
                {
                    deleteMap.put(wMem.MemberId, wMem.ctm);
                     case caseRec = new Case();
                     if (wMem.ctm.Parentid != Null){ 
                     caseRec.Id = wMem.ctm.Parentid;
                     caseMap.put(caseRec.Id, caseRec);
                     }
                } 
            }
        }
        else
        {
            if(wMem.id!=null)
            {
                deleteMap.put(wMem.MemberId, wMem.ctm);
                case caseRec = new Case();
                caseRec.Id = cases.id;
                caseMap.put(caseRec.Id, caseRec);
            } 
        }
    }
    
    // upsert the list to be upserted after error validation and delete the list that has to be deleted
    public PageReference save()
    {
        Set<Id> uniqueMemberIds = new Set<Id>();
        Map<Id, CaseTeamMember> existingCtmMapClone = existingCtmMap.deepClone();
        isErrorOnPage = false;
        for(WrapMember wm : memberList)
        {
            if ((null==wm.memberId) || (wm.memberId.trim().length()==0))
            {
                wm.displayMemberError='Team Member must be defined';
                isErrorOnPage = true;
            }
            else if(wm.memberId!=null)
            {
                if(uniqueMemberIds.contains(wm.MemberId))
                {
                    wm.displayMemberError='Team Member already exists';
                    isErrorOnPage = true;
                }
                else
                {
                    uniqueMemberIds.add(wm.MemberId);
                    if(existingCtmMapClone.containsKey(wm.MemberId))
                    {
                        CaseTeamMember ctm = existingCtmMapClone.get(wm.MemberId);
                        if(ctm.TeamRoleID != wm.RoleID)
                        {
                            ctm.TeamRoleId = wm.RoleId;
                            system.debug('1 Adding to upsert list =====> ' + ctm);
                            upsertMap.put(wm.MemberId, ctm);
                            //DE381
                            case caseRec = new Case();
                            caseRec.Id = ctm.Parentid;
                            if (caseRec.Id != Null){
                            caseMap.put(caseRec.Id, caseRec);//DE381
                             }
                           
                        }
                        existingCtmMapClone.remove(wm.MemberId);
                        if(deleteMap.containsKey(wm.MemberId))
                            deleteMap.remove(wm.MemberId);
                    }
                    else
                    {
                        CaseTeamMember ctm = new CaseTeamMember(ParentId = cases.Id);
                        ctm.MemberID = wm.MemberId;
                        ctm.TeamRoleId = wm.RoleId;
                     
                        upsertMap.put(wm.MemberId, ctm);
                         //DE381
                        case caseRec = new Case();
                        caseRec.Id = cases.Id;
                        if (caseRec.Id != Null){
                        caseMap.put(caseRec.Id, caseRec);}//DE381
                      
                    }
                }
            }
        }
        for(CaseTeamMember ctm : existingCtmMapClone.values())
        {
            if(!excludedRoleSet.contains(rolesMap.get(ctm.TeamRoleId)) && !upsertMap.containsKey(ctm.MemberId))
                deleteMap.put(ctm.MemberId, ctm);
                //DE381
                        case caseRec = new Case();
                        caseRec.Id = cases.Id;
                        caseMap.put(caseRec.Id,caseRec);//DE381
                      
        }
        
        if(isErrorOnPage)
            return null;
        
        if(!deleteMap.isEmpty())
        {
            List<CaseTeamMember> ctmList = deleteMap.values();
                delete ctmList;
        }
        
        if(!upsertMap.isEmpty())
        {
            List<CaseTeamMember> ctmList = upsertMap.values();
            upsert ctmList;
        }
        if(!caseMap.isEmpty())
        {
            List<Case> caseList = caseMap.values();
            Update caseList;
        }
        
        PageReference pageRef = new ApexPages.StandardController(cases).view();
        return pageRef.setRedirect(true);
    }
    
    // Wrapper Class
    public class wrapMember {
        public CaseTeamMember ctm { get; set; }
        public String id { get; set; }
        public String memberId { get; set; }
        public String memberName { get; set; }
        public String roleId { get; set; }
        public String roleName { get; set; }
        
        public String displayMemberError { get; set; }
        
        public wrapMember ( CaseTeamMember c ) {
            ctm = c;
            id = ctm.id;
            memberId = ctm.MemberId;
            memberName = ctm.Member.Name;
            roleId = ctm.TeamRoleId;
            if(roleId!=null){
                roleName = ctm.TeamRole.Name;
            }
            displayMemberError = '';
        }
        
        public boolean isContact(Id inUser) {
            return (inUser.getSObjectType()== Contact.sObjectType);
        }
    }
    
    // Get contact id of the user
    public Id getContactID(Id memberId)
    {
        try
        {
            if(memberID != null)
            {
                User u = [Select ContactId from User where Id = :memberId];
                return u.ContactId;
            }
            else
                return null;
        }
        catch(Exception e)
        {
            return null;
        }
    }
    
    // check if the deleted member is an active ACP
    @TestVisible private CS_Asset_Contact_Permissions__c getACP(Id memberContactId)
    {
        try
        {
            CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Access_Type__c from CS_Asset_Contact_Permissions__c
                                                            where CS_Asset__c = :assetId and CS_IsActive__c = true
                                                            and CS_Contact__c = :memberContactID];
            return acp;
        }
        catch(Exception e)
        {
            return null;
        }
    }
    
}