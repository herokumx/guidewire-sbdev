/*
Apex Class Name - CaseDataController
Description - UsedBy the CaseDataReportwithTeam VF Page to print the cases in a certain view. 
*/

public class CaseDataReportwithTeam{

        public PageReference processRequests() {
            
            return null;
        }
        
        public String userSelected {get; set;}
        public String userList {get; set;}
                
        public List<SelectOption> getUserIDs() {
            List<SelectOption> options = new List<SelectOption>();
            List<User> userList = new List<User>([Select ID, Name, FirstName, LastName from User Where IsActive = True AND User.Profile.UserLicense.Name = 'Salesforce' AND CS_User_Team__c ='Support' ORDER By NAME ASC]);
            for (User usr:userList){
            options.add(new SelectOption(usr.Id,usr.Name));
            }
            return options;
        }

        public List<wrapCase> caseList{
            
                get {
                
                ID userID =  UserInfo.getUserId(); 
      
                if (userSelected != null )
                { 
                    if (userSelected !=''){
                    userID = userSelected ; 
                    }
                }
                
                System.Debug('The User ID is..' + userId);
                
                List<wrapCase> lstWrapCase = new List<wrapCase>();
                if (caseList== null) {

                
                //Get the list of cases. 
                List<case> caseData = [Select CaseNumber, ID, Owner.Id,LastModifiedDate, Owner.Name, Severity__c,Contact.Id,Contact.Name,Subject, OwnerID, Asset.ParentID,CreatedDate,Status, Asset.Parent.Name, Asset.CS_Primary_Supp_Partner__c, Asset.CS_Primary_Supp_Partner__r.Name,  (SELECT MemberID, Member.Username, Member.Name, TeamRole.Name FROM TeamMembers) FROM CASE WHERE (CS_Owner_Team__c='Support' AND Status != 'Closed' AND Status!= 'Verified' AND RecordType.Name= 'Customer Support' AND ISClosed = false) ORDER BY CreatedDate DESC LIMIT 10000 ];
                for (case caseRec:caseData){
                
                     string highlightMyName = '';
                     string endhighlightMyName = '';
                     String assetPrimaryContact = '';
                     String caseOwnerStartTag = '';
                     String caseOwnerEndTag = '';
                     String collaborator='';
                     String followtheSun='';
                     String leads='';
                     Set<ID> collaboratorIDs = new Set<ID>();
                     Set<ID> followtheSunIDs= new Set<ID>();
                     Set<ID> leadIDs= new Set<ID>();
                     
                     
                    //Datetime createdTimeCust;
                     if (caseRec.Asset.CS_Primary_Supp_Partner__c != Null){
                         if (caseRec.Asset.CS_Primary_Supp_Partner__c ==userID){
                         
                         assetPrimaryContact   = '<mark>' + caseRec.Asset.CS_Primary_Supp_Partner__r.Name + '</mark>';
                         }
                         else {
                         assetPrimaryContact = caseRec.Asset.CS_Primary_Supp_Partner__r.Name;
                         }
                    }
                   
                    //Highlight the Owner 
                    if (caseRec.OwnerId ==userID){

                        caseOwnerStartTag = '<mark>' ; 
                        caseOwnerEndTag = '</mark>';
                    }
                  
                    
                    
                     CaseTeamMember CaseTeamMember= new CaseTeamMember();
                     List<CaseTeamMember> caseTeamMemberList = caseRec.TeamMembers;
                     //If the Case has case team members, parse through and build the tags. 
                     if (caseTeamMemberList!= NULL){
                     for (CaseTeamMember teamMember: caseTeamMemberList )
                     {
                        
                        string teamMemberName = teamMember.Member.Name;
                        
                        if (teamMember.MemberID ==userID){
                        highlightMyName = '<mark>' ;
                        endhighlightMyName = '</mark>';
                        }
                        if (teamMember.TeamRole.Name.toUpperCase() == 'COLLABORATOR')
                         { 
                             if (collaborator != ''){ 
                             collaborator = collaborator  + ' , ' + highlightMyName +  teamMemberName + endhighlightMyName ;} 
                             else {
                             collaborator =  highlightMyName + teamMemberName + endhighlightMyName ;
                             }
                             collaboratorIDs.add(teamMember.MemberID);
                         }
                        else if (teamMember.TeamRole.Name.toUpperCase() =='FOLLOW THE SUN')
                         {
                             if (followtheSun!= ''){ 
                             followtheSun= followtheSun+ ', ' + highlightMyName + teamMemberName + endhighlightMyName ;} 
                             else {
                             followtheSun= highlightMyName + teamMemberName + endhighlightMyName ;
                             }
                             followtheSunIDs.add(teamMember.MemberID);
                         }
                          else if (teamMember.TeamRole.Name.toUpperCase() =='LEADS')
                         {
                             if (leads != ''){ 
                             leads = leads + ', ' + highlightMyName + teamMemberName + endhighlightMyName ;} 
                             else {
                             leads = highlightMyName + teamMemberName + endhighlightMyName ;
                             }
                             leadIDs.add(teamMember.MemberID);
                         }
                         
                         highlightMyName = '' ;
                         endhighlightMyName = '';
                      }
                      
                     
                   }
                   if (caseRec.OwnerId == userID || caseRec.Asset.CS_Primary_Supp_Partner__c ==userID || 
                   collaboratorIDs.contains(userID) || 
                   followtheSunIDs.contains(userID)  || 
                   leadIDs.contains(userID)) 
                   {
                   wrapCase wrapCase1 = new wrapCase(caseRec,caseOwnerStartTag, caseOwnerEndTag, assetPrimaryContact,collaborator,followtheSun,leads, caseRec.CreatedDate.format(),caseRec.LastModifiedDate.format());
                   lstWrapCase.add(wrapCase1 );
                   }
                }
               }
           return lstWrapCase ;
        }
        set;
    }
      
    
    public class wrapCase {
    
            public case caseRecord {get; set;}
            public String collaborator{get;set;}
            public String caseOwnerStartTag{get;set;}
            public String caseOwnerEndTag{get;set;}
            public String followtheSun{get;set;}
            public String leads{get;set;}
            public String createdDateFormated{get;set;}
            public String lastModDateFormated{get;set;}
            public String assetPrimaryContact{get;set;}
    
     
            public wrapCase(Case caseRecord, String caseOwnerStartTag, String caseOwnerEndTag, String assetPrimaryContact, String collaborator, String FollowtheSun, String leads, String createdDateFormated, String lastModDateFormated) {
                this.caseRecord = caseRecord;
                this.caseOwnerStartTag = caseOwnerStartTag;
                this.caseOwnerEndTag = caseOwnerEndTag;
                this.collaborator = collaborator;
                this.assetPrimaryContact = assetPrimaryContact;
                this.followtheSun =  followtheSun; 
                this.leads = leads;
                this.createdDateFormated = createdDateFormated;
                this.lastModDateFormated = lastModDateFormated;
            }
        }
       
    }