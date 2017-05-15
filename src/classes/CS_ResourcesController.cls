/*
*****************************************************************************************************************************
Class Name - CS_ResourcesController
Class Type -  Controller
Test Class-
Purpose-  Resource  filter Lightning Component Controller


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan xu                                            Initial Creation

*****************************************************************************************************************************
*/
public without  sharing class CS_ResourcesController {
    static User user {
        get {
            return [Select Id, AccountId, ContactId from User where Id = :UserInfo.getUserId()];
        }
    }
    
    @AuraEnabled
    public static List<String> getReleaseProducts() {
        List<CS_Release__c> releases = [Select CS_Product__r.Name, CS_Product__c from CS_Release__c];
        Set<String> productNameSet = new Set<String>();
        for (CS_Release__c r : releases) {
            productNameSet.add(r.CS_Product__r.Name);
        }
        List<String> productNameList = new List<String>(productNameSet);
        System.debug('productNameList ' + productNameList);
        return productNameList;
    }
    
    @AuraEnabled
    public static List<String> getProductVersions (String product) {
        List<CS_Release__c> releases = [Select CS_Minor_Release_Version__c, CS_Patch_Version__c, CS_Major_Release_version__c, CS_Version__c, CS_Release_Type__c, CS_Localization__c, CS_Product__c from CS_Release__c
                                        where CS_Product__r.Name = :product
                                        order by CS_Version__c desc];
        Set<String> productVersionSet = new Set<String>();
        for (CS_Release__c r: releases) {
            productVersionSet.add(r.CS_Version__c);
        }
        system.debug('product versions ' + productVersionSet);
        return new List<String>(productVersionSet);
    }
    
    
    @AuraEnabled
    public static List<String> getLanguagePickval() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = CS_Release__c.CS_Localization__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry p : ple) {
            options.add(p.getLabel());
        }
        return options;
    }
    
    
    @AuraEnabled
    public static Map<String, String> getReleaseProductByAsset(String assetId) {
        Asset asset = [Select Id, Product2Id, Product2.Name, Product2.Product_Group_Name__c from Asset where Id = :assetId];

       
        Map<String, String> assetProductMap = new Map<String, String>();
        if (asset != null) {
            assetProductMap.put('product', asset.Product2.Name);
            assetProductMap.put('productGroup', asset.Product2.Product_Group_Name__c);
        }
         System.debug('assetProductMap ' + assetProductMap);
        return assetProductMap;
    }

    // Method created by Mani on 8/20  to display Product Groups on Resource Page
    @AuraEnabled
    public static List<String> getProductGroupPickvals() {
      List<String> options = new List<String>();      
        // Find all the Product Group in the custom setting GW Product Group
        Map<String, CS_Product_Group__c> PGs = CS_Product_Group__c.getAll();
        // Sort them by name
        List<String> PGNames = new List<String>();
        PGNames.addAll(PGs.keySet());
        PGNames.sort();
        // Create the Select Options.
        for (String PGName : PGNames) {
            CS_Product_Group__c PG = PGs.get(PGName);
            options.add(PG.CS_Product_Group_Name__c);
        }
        return options;
     }
   
    @AuraEnabled
    public static List<String> getProductsByProductGroup(String productGroup) {
        List<CS_Release__c> releases = [Select CS_Product__r.Name, CS_Product__c from CS_Release__c where CS_Product__r.Product_Group_Name__c = :productGroup];
        Set<String> productNameSet = new Set<String>();
        for (CS_Release__c r : releases) {
            productNameSet.add(r.CS_Product__r.Name);
        }
        List<String> productNameList = new List<String>(productNameSet);
        System.debug('productNameList ' + productNameList);
        return productNameList;
    }
}