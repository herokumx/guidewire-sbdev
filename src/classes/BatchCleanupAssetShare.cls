global class BatchCleanupAssetShare implements Database.Batchable<sObject>{
    public String query;
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        query = 'Select Id, Name, AccountId, ContactId from Asset Where RecordType.Name = \'Parent Asset\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Asset> parentAssets) {
        List<AssetShare> allAssetShareToDeleteList = new List<AssetShare>();
        Set<Id> assetIds = new Set<Id>();
        Map<Id, Id> contactToAssetAcpMap = new Map<Id, Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Asset a : parentAssets) {
            assetIds.add(a.Id);
        }
        // query ACP
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, CS_Asset__c, CS_Contact__c 
                                                      from CS_Asset_Contact_Permissions__c
                                                      where CS_Asset__c in :assetIds
                                                       and CS_IsActive__c = true];
        for (CS_Asset_Contact_Permissions__c acp : acpList) {
            contactIds.add(acp.CS_Contact__c);
            contactToAssetAcpMap.put(acp.CS_Contact__c, acp.CS_Asset__c);
        }
        
        Map<Id, Id> userToContactMap = new Map<Id, Id>();
        List<User> users = [Select Id, ContactId from User where ContactId in :contactToAssetAcpMap.keySet()];
        for (User u : users) {
            userToContactMap.put(u.Id, u.ContactId);
        }
        List<AssetShare> assetShareListToDelte = new List<AssetShare>();
        // query asset share
        List<AssetShare> assetShares = [Select Id, UserOrGroupId, UserOrGroup.Name, UserOrGroup.UserRole.Name, Asset.Name, Asset.RecordType.Name, AssetId from AssetShare where AssetId in :contactToAssetAcpMap.values() and RowCause = 'Manual'];
       
        
        System.debug('====contactToAssetAcpMap==== ' + contactToAssetAcpMap);
        List<String> roleName = new List<String>();
        for (AssetShare ah : assetShares) {
            System.debug('contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId) ' + contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)));
            System.debug('ah.AssetId ' + ah.AssetId);
            
            if (contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)) == null || contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)) != ah.AssetId) {
                assetShareListToDelte.add(ah);
               
            }
        }
       
        // add parent asset share to delete to the overall list
        allAssetShareToDeleteList.addAll(assetShareListToDelte);
        system.debug('====assetShareListToDelte==== '+ assetShareListToDelte);
        
        Set<Id> parentAstId = new Set<Id>();
        Set<Id> allChildAssetIds = new Set<Id>();
        Map<Id, Set<Id>> parentToChildAssetMap = new Map<Id, Set<Id>>();
        Map<Id, Id> childToParentAssetMap = new Map<Id, Id>();
        for(Id i : contactToAssetAcpMap.keyset()) {
            parentAstId.add(contactToAssetAcpMap.get(i));
        }
        if(!parentAstId.isEmpty()){
            for(Asset a : [Select Id, ParentId from Asset where Parentid in :parentAstId]){
                if (!childToParentAssetMap.containsKey(a.Id)) {
                    childToParentAssetMap.put(a.Id, a.ParentId);
                }
                allChildAssetIds.add(a.Id);
                if(parentToChildAssetMap.containsKey(a.ParentId))
                    parentToChildAssetMap.get(a.ParentId).add(a.Id);
                else
                    parentToChildAssetMap.put(a.ParentId, new Set<Id>{a.Id});
            }
        }
        List<AssetShare> childAssetShareListToDelete = new List<AssetShare>();
        // query child Asset shares
        List<AssetShare> childAssetShares = [Select Id, UserOrGroupId, AssetId from AssetShare where AssetId in :allChildAssetIds and RowCause = 'Manual'];
        for (AssetShare ah : childAssetShares) {
            //System.debug('contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)) ' + contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)) );
            //System.debug('childToParentAssetMap.get(ah.AssetId)' + childToParentAssetMap.get(ah.AssetId));
            if (contactToAssetAcpMap.get(userToContactMap.get(ah.UserOrGroupId)) != childToParentAssetMap.get(ah.AssetId)){
                childAssetShareListToDelete.add(ah);
            }
        }
       
        System.debug('==========childAssetShareListToDelete============' + childAssetShareListToDelete);
        allAssetShareToDeleteList.addAll(childAssetShareListToDelete);
        System.debug('=======allAssetShareToDeleteList======== ' + allAssetShareToDeleteList.size());
        if (allAssetShareToDeleteList != null && !allAssetShareToDeleteList.isEmpty()) {
       		delete allAssetShareToDeleteList;
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
}