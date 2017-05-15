public with sharing class GW_GenerateEntitledAssetsForDMBatch implements Database.Batchable<Asset> {
    public Iterable<Asset> start(Database.BatchableContext BC) {
       return GW_GenerateEntitledAssetsForDM.getAllEntitledAssetsforcreation();
     // get data from UTIL file and return.
    } 
    
       

    public void execute(Database.BatchableContext info, List<Asset> assetListForInsert) {
      System.debug(assetListForInsert.size());
	  Database.insert(assetListForInsert);
    } 
   
    public void finish(Database.BatchableContext info) {}
}