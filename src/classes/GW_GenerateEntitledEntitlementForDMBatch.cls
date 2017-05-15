public with sharing class GW_GenerateEntitledEntitlementForDMBatch implements Database.Batchable<Entitlement> {
    public Iterable<Entitlement> start(Database.BatchableContext BC) {
       return GW_GenerateEntitledAssetsForDM.getAllEntitledEntitlementsforcreation();
     // get data from UTIL file and return.
    } 
    
       

    public void execute(Database.BatchableContext info, List<Entitlement> entListForInsert) {
      System.debug('Entitlement>>>>>'+entListForInsert.size());
	  System.debug('Entitlement>>>>>'+entListForInsert);
	  
      Database.insert(entListForInsert);
    } 
   
    public void finish(Database.BatchableContext info) {}
}