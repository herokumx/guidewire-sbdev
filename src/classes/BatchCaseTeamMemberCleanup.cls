global class BatchCaseTeamMemberCleanup implements Database.Batchable<sObject>{

//Id batchRun = Database.executeBatch(new BatchCaseTeamMemberCleanup(), 1);
    global Database.QueryLocator start(Database.BatchableContext BC){
        string query;
        query = 'Select Id from Asset where RecordType.Name = \'Parent Asset\'';
        //query = 'Select Id from Asset where id='\'02i29000000GYA7\'';
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> assetIds = new Set<Id>();

        for(Asset a : (List<Asset>)scope){
            assetIds.add(a.Id);
        }
        //System.debug('+++++++Asset Id===='+assetIds);
        if(!assetIds.isEmpty()){
            deleteCaseTeamMember(assetIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
    public void deleteCaseTeamMember(Set<Id> assetIds){
        Map<String,CS_Asset_Contact_Permissions__c> mapAcpPermission = new Map<String,CS_Asset_Contact_Permissions__c>();
        Set<Id> setContactID = new Set<ID>();

        List<CS_Asset_Contact_Permissions__c> lstAsstContactPermission = new list<CS_Asset_Contact_Permissions__c>( [SELECT CS_Asset__c,CS_Contact__c FROM CS_Asset_Contact_Permissions__c Where CS_Asset__c in :assetIds and CS_IsActive__c = :true]);
        
        for (CS_Asset_Contact_Permissions__c csACP: lstAsstContactPermission ){
            setContactID.add(csACP.CS_Contact__c);
            mapAcpPermission.put(String.valueOf(csACP.CS_Asset__c) + String.valueOf(csACP.CS_Contact__c), csACP);
            //System.Debug('--mapAcpPermission--' + mapAcpPermission);   
        }

        Map<ID, User> mapUser = new Map<ID, User>([Select ID, ContactID from User where ContactID in : setContactID]);
       // System.Debug('--mapUser--' + mapUser);
        List<CaseTeamMember> lstDeleteCaseTeamMember = new List<CaseTeamMember>();
        //System.Debug('--mapUser.keyset()--' + mapUser.keyset());   
        
        List<CaseTeamMember> lstCaseTeamMember= [SELECT Parent.Asset.ParentID, MemberId FROM CaseTeamMember Where Parent.Asset.ParentID in :assetIds 
                                                 and TeamRole.name in ('Customer Case Contact','Customer Support','Customer Support (View Only)','Partner')];
        //System.Debug('--lstCaseTeamMember--' + lstCaseTeamMember);
        
        for (CaseTeamMember casTeamMember: lstCaseTeamMember){
            String keyComp;
            if(mapUser.containskey(casTeamMember.MemberId)){
                keyComp = String.valueOf(casTeamMember.Parent.Asset.ParentID) + String.valueOf(mapUser.get(casTeamMember.MemberId).ContactId);
                System.Debug('--keyComp--' + keyComp);
            }
            if (keyComp == null || mapAcpPermission.get(keyComp) == NULL) {
                lstDeleteCaseTeamMember.add(casTeamMember);
            }

        }

        if (lstDeleteCaseTeamMember.size() >0) {
            System.Debug('--lstDeleteCaseTeamMember--' + lstDeleteCaseTeamMember);
            delete lstDeleteCaseTeamMember;
        }
    }
}