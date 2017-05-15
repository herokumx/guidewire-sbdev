global class BatchCaseTeamMemberSynch implements Database.Batchable<sObject>{

//Id batchRun = Database.executeBatch(new BatchCaseTeamMemberCleanup(), 1);
    global Database.QueryLocator start(Database.BatchableContext BC){

        string query;
        query = 'Select Id from Asset where RecordType.Name = \'Parent Asset\'';
        //query = 'Select Id from Asset where id=\'02i29000000GYA7\''; gforcedev  
        //query = 'Select Id from Asset where id=\'02i8A000002c9XA\''; UAT
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> assetIds = new Set<Id>();

        for(Asset a : (List<Asset>)scope){
            assetIds.add(a.Id);
        }
        //System.debug('+++++++Asset Id===='+assetIds);
        if(!assetIds.isEmpty()){
            updateCaseTeamMember(assetIds);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }

    public  static void updateCaseTeamMember(Set<Id> assetIds){
        
        
        //Query All the CaseTeamMember 
        //Collect the ContactID's because. we need to get the User ID of the correcponding User from the User Record Later. 
        //Make a Map of the CaseTeamMember, the key will be a composite of AssetID and Contact ID, later we will loop through the ACP to see if a corresponding Case Team Memeber exists for this key 

        
        //Map<String,CaseTeamRole> mapOfCTM = GWUtilities.getCTMRoleId();
        Map<String,CS_Asset_Contact_Permissions__c> mapAcpPermission = new Map<String,CS_Asset_Contact_Permissions__c>();
        Set<Id> setContactID = new Set<ID>();

        List<CS_Asset_Contact_Permissions__c> lstAsstContactPermission = new list<CS_Asset_Contact_Permissions__c>( [SELECT CS_Asset__c,CS_Contact__c,CS_Access_Type__c FROM CS_Asset_Contact_Permissions__c Where CS_Asset__c in :assetIds and CS_IsActive__c = :true]);
        
        for (CS_Asset_Contact_Permissions__c csACP: lstAsstContactPermission ){
            setContactID.add(csACP.CS_Contact__c);
            mapAcpPermission.put(String.valueOf(csACP.CS_Asset__c) + String.valueOf(csACP.CS_Contact__c), csACP);
            System.Debug('--mapAcpPermission--' + mapAcpPermission);   
        }

        Map<ID, User> mapUser = new Map<ID, User>([Select ID, ContactID from User where ContactID in : setContactID]);
        System.Debug('--mapUser--' + mapUser);
        Map<id,CaseTeamMember> lstUpdateCaseTeamMember = new Map<id,CaseTeamMember>();
        Map<id,CaseTeamMember> lstDeleteCaseTeamMember = new Map<id,CaseTeamMember>();
        System.Debug('--mapUser.keyset()--' + mapUser.keyset());   
        
        List<CaseTeamMember> lstCaseTeamMember= [SELECT Parent.Asset.ParentID,TeamRole.name, MemberId FROM CaseTeamMember Where Parent.Asset.ParentID in :assetIds 
                                                 and TeamRole.name in ('Customer Case Contact','Customer Support','Customer Support (View Only)','Partner')]; // We should remove the CastTeamRole and just check if the Member.PRofile is not customer support 
        System.Debug('--lstCaseTeamMember--' + lstCaseTeamMember);

        List<CaseTeamRole> listCaseTeamRole = new List<CaseTeamRole>([Select ID, Name From CaseTeamRole]);
        Map<String, Id> mapCaseTeamRole = new Map<String, ID>();
        for (CaseTeamRole casTeamRole: listCaseTeamRole)
        {
            mapCaseTeamRole.put(casTeamRole.Name, casTeamRole.Id);
        }
        

        for (CaseTeamMember casTeamMember: lstCaseTeamMember){
            String keyComp;
            System.debug('check 1');
            if(mapUser.containskey(casTeamMember.MemberId)){
                  System.debug('check 2');
                keyComp = String.valueOf(casTeamMember.Parent.Asset.ParentID) + String.valueOf(mapUser.get(casTeamMember.MemberId).ContactId);
            }
                if (keyComp != null && mapAcpPermission.get(keyComp) != NULL ) {
                    system.debug('Check 3');
                   CS_Asset_Contact_Permissions__c acpRecord = mapAcpPermission.get(keyComp);
                   System.debug(casTeamMember.TeamRole.name +'-'+acpRecord.CS_Access_Type__c);
                     if (casTeamMember.TeamRole.name != acpRecord.CS_Access_Type__c)
                     {
                         system.debug('+++++++');
                         casTeamMember.TeamRoleid = mapCaseTeamRole.get(acpRecord.CS_Access_Type__c);
                         if (acpRecord.CS_Access_Type__c !='General Customer' ){
                            if(casTeamMember.TeamRole.name !='Customer Case Contact' ) {
                                 system.debug('Update 1');
                                 if(casTeamMember.TeamRoleid!=null)lstUpdateCaseTeamMember.put(casTeamMember.Id,casTeamMember);
                            }
        
                         }

                         if (acpRecord.CS_Access_Type__c =='General Customer'){
                            lstDeleteCaseTeamMember.put(casTeamMember.Id,casTeamMember);
                         }

                     }
             }
                
            }
            

        

        if (lstUpdateCaseTeamMember.size() >0) {
            
            System.Debug('--lstUpdateCaseTeamMember--' + lstUpdateCaseTeamMember);
            List<CaseTeamMember> lstToUpdate=lstUpdateCaseTeamMember.Values();
            Update lstToUpdate;
        }

        if (lstDeleteCaseTeamMember.size() >0) {
            
            System.Debug('--lstDeleteCaseTeamMember--' + lstDeleteCaseTeamMember);
            List<CaseTeamMember> lstToDelete=lstDeleteCaseTeamMember.Values();
            Delete lstToDelete;
        }

    }
}