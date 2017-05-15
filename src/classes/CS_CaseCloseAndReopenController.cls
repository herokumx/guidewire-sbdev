/*
******************************************************************************************************************************
Controller Class Name- CS_CaseCloseAndReopenController
Object - Case
Purpose- Controller  Class Case Close  Lighnting  Component
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Shan Xu                     9/23/2016    DE631

*****************************************************************************************************************************
*/
public with sharing class CS_CaseCloseAndReopenController {
    @AuraEnabled
    public static Case getCase(String id) {
        return [SELECT Id, Status, ClosedDate FROM Case WHERE Id =:id];
    }

    @AuraEnabled
    public static String closeCase(String caseId) {
        System.debug('case Id ' + caseId);
        Case caseToClose = [Select Status, CS_Customer_Case_Closed_Date__c from Case where Id = :caseId];
        caseToClose.Status = 'Closed by customer';
        
        Database.SaveResult sr = Database.update(caseToClose);
        System.debug('sr ' + sr);
        if (sr.isSuccess() == true) {
            return 'Success';
        } else {
            return 'Fail';
        }

    }
    
    @AuraEnabled
    public static String reopenCase(String caseId) {
        Case caseToUpdate= [Select Status, ClosedDate from Case where Id = :caseId];
        caseToUpdate.Status = 'Updated by customer';
        //caseToUpdate.CS_Customer_Case_Closed_Date__c = Date.today();
        
        Database.SaveResult sr = Database.update(caseToUpdate);
        System.debug('sr ' + sr);
        if (sr.isSuccess() == true) {
            return 'Success';
        } else {
            return 'Fail';
        }
    }
    
    @AuraEnabled
    public static Boolean getReadOnlyAccess(String caseId) {
        User user = [Select Id, AccountId, ContactId from User where Id = :UserInfo.getUserId()];
        CaseTeamMember ctm;
        CaseTeamMember[] ctmList = [Select TeamRole.AccessLevel from CaseTeamMember where MemberId = :user.Id and ParentId = :caseId];
        if (ctmList != null && ctmList.size() > 0) {
            ctm = ctmList[0];
        }
        if (ctm == null || ctm.TeamRole.AccessLevel == 'Read' || ctm.TeamRole.AccessLevel == 'None') {
            return true;
        } else {
            return false;
        }
    }
    
    @AuraEnabled
    public static Boolean disableReopen(String caseId) {
        Case c = [SELECT Id, Status, ClosedDate FROM Case WHERE Id =:caseId];
        if (c.ClosedDate != null && Datetime.now() >= c.ClosedDate.addDays(30)) {
            return true;
        } else {
            return false;
        }
    }
}