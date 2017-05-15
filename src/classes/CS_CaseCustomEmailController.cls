/*
******************************************************************************************************************************
Controller Class Name- CS_CaseCustomEmailController
Object - Case
Purpose- Controller for Case Email VF
*****************************************************************************************************************************

Name            Email              Date         Notes 
Alice Jones                                     Initial Creation

*****************************************************************************************************************************
*/
public with sharing class CS_CaseCustomEmailController {
    private final Case caseRec;
    public Case caseRecord {get;set;}
    public OrgWideEmailAddress supportEmailAddress {get;set;}
    public string ToAddress {get;set;}
    public string ToCCAddress {get;set;}
    public string ToBCCAddress {get;set;}
    public Set<String> allEmailAddrNoDupes = new Set<String>();
    
    public CS_CaseCustomEmailController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>{'CS_CC_Email_List__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_1__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_2__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_3__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_4__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_5__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_6__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_7__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_8__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_9__c'});
            stdController.addFields(new List<String>{'CS_Carbon_Copy_Email_10__c'});
        }
        this.caseRec = (Case)stdController.getRecord();
        caseRecord = new Case();

        ToAddress = '';
        ToCCAddress = '';
        ToBCCAddress = '';

        supportEmailAddress = [SELECT id, Address FROM OrgWideEmailAddress WHERE DisplayName ='Guidewire Community Support'];
        
        caseRecord = [SELECT contact.Email FROM case WHERE Id =: this.caseRec.Id];
        if(caseRecord.contact.Email!=null && isNewAddress(caseRecord.contact.Email)){
            ToAddress = caseRecord.contact.Email;
        }
        
        for(CaseTeamMember caseTeam : [SELECT Id, Member.Email, TeamRole.Name 
                                         FROM CaseTeamMember
                                         WHERE ParentId =: caseRec.Id 
                                         AND TeamRole.Name IN ('Customer Case Contact')]){
            if(caseTeam.Member.Email!=null && isNewAddress(caseTeam.Member.Email)){
                ToCCAddress += caseTeam.Member.Email + '; ';
            }
        }

        if(this.CaseRec.CS_Carbon_Copy_Email_1__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_1__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_1__c + '; ';
        }
        if(this.CaseRec.CS_Carbon_Copy_Email_2__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_2__c)){        
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_2__c + '; ';
        }
        if(this.CaseRec.CS_Carbon_Copy_Email_3__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_3__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_3__c + '; ';
        }

        if(this.CaseRec.CS_Carbon_Copy_Email_4__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_4__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_4__c + '; ';
        }

        if(this.CaseRec.CS_Carbon_Copy_Email_5__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_5__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_5__c + '; ';
        }

        if(this.CaseRec.CS_Carbon_Copy_Email_6__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_6__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_6__c + '; ';
        }

        if(this.CaseRec.CS_Carbon_Copy_Email_7__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_7__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_7__c + '; ';
        }
        if(this.CaseRec.CS_Carbon_Copy_Email_8__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_8__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_8__c + '; ';
        }
        if(this.CaseRec.CS_Carbon_Copy_Email_9__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_9__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_9__c + '; ';
        }
        if(this.CaseRec.CS_Carbon_Copy_Email_10__c!=null && isNewAddress(this.CaseRec.CS_Carbon_Copy_Email_10__c)){
            ToCCAddress += this.CaseRec.CS_Carbon_Copy_Email_10__c + '; ';
        }

/*
        if(this.CaseRec.CS_CC_Email_List__c!=null && isNewAddress(this.CaseRec.CS_CC_Email_List__c)) {
            List<String> stringList = this.CaseRec.CS_CC_Email_List__c.split(',');
            if(stringList!=null){
                for(String s : stringList) {
                    if(s!=null && isNewAddress(s)) {
                        ToCCAddress += s + '; ';
                    }
                }
             }
         }
        
        */
        if(ToCCAddress!=null) {
            ToCCAddress.replace('; ;','');
        }
         
        for(CaseTeamMember caseTeam : [SELECT Id, Member.Email, TeamRole.Name 
                                         FROM CaseTeamMember
                                         WHERE ParentId =: caseRec.Id 
                                         AND TeamRole.Name IN ('GW Watcher', 'Follow the Sun','Leads','Collaborator')]){
            if(caseTeam.Member.Email!=null && isNewAddress(caseTeam.Member.Email)){
                ToBCCAddress += caseTeam.Member.Email + '; ';
            }
        }
        
        for(EntitySubscription followers : [SELECT Id, Subscriber.Email FROM EntitySubscription
                                             WHERE ParentId =:caseRec.Id  limit 100]){
            if(followers.Subscriber.Email!=null && isNewAddress(followers.Subscriber.Email)){
                ToBCCAddress += followers.Subscriber.Email + '; ';
            }
        }
        
        if(ToBCCAddress!=null){
            ToBCCAddress.replace('; ;','');
        }
        
        scrubCurrentUser(UserInfo.getUserId());
        
    }
    
    //Test if address is a duplicate to the To, CC or BCC list
    public Boolean isNewAddress(String inAddress) {
        Boolean bool = false;
        Integer initialCount = allEmailAddrNoDupes.size();
        allEmailAddrNoDupes.add(inAddress);
        if(allEmailAddrNoDupes.size()>initialCount) {
            bool = true;
        } else {
            bool = false;
        }
        return bool;
    }
    
    //If Current User Email Setting Auto BCC set to true
    //We need to remove from the CC and BCC lists because
    //user will be automatically added to default BCC list
    public void scrubCurrentUser(String currentUserId) {
        if(currentUserId!=null) {
            User currentUser = [SELECT Id, Email, EmailPreferencesAutoBcc FROM User WHERE Id=:currentUserId];
            if(currentUser.EmailPreferencesAutoBcc==true) {
                ToCCAddress = ToCCAddress.replace(currentUser.Email + ';','');
                ToBCCAddress = ToBCCAddress.replace(currentUser.Email + ';','');
            }
        }
    }
        
}