/*
*****************************************************************************************************************************
Class Name - CS_CustomerOnboarding_Util
Class Type -  Util
Test Class-
Purpose- Customer Onboarding UTIL Class
*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan Xu                                           Initial Creation
Mani G      manig@slalom.com  09/09/2016          Bug Fix for DE657 and DE307
Mani G      manig@slalom.com  09/16/2016          Bug Fix for DE362 Cognos Automation Fix
*****************************************************************************************************************************
*/
public class CS_CustomerOnboarding_Util {
    private static List<Asset> allAssetsToInsert = new List<Asset>();
    private static Set<Id> allChildAssetIds = new Set<Id>();
    private static List<Asset> parentAssetListToInsert = new List<Asset>();
    private static Id accountId {get;set;}
    
    private static String accountname{get;set;}
    private static Id receipientemailId{get;set;}
    private static Id receipientUserId{get;set;}
    private static string SCName{get;set;}

    private static String accountShortName {get;set;}
    private static Set<Id> parentAssetIdSet = new Set<Id>();
    private static Set<Id> insertedEntitlementIds = new Set<Id>();
    private static String parentRecordTypeId {get;set;}
    private static String childRecordTypeId {get;set;}
    private static Id sContractId {get;set;}
    public static List<CS_Product_Relation__c> productRelations {get;set;}
    public static Boolean contractualPenalty {get;set;}
    public static Boolean reportingRequirements {get;set;}
    public static Map<String, String> sourceProductToServiceLevelMap = new Map<String, String>();
    public static Map<String, CS_Customer_Support__c> gwCustomSetting {
        get {
            return CS_Customer_Support__c.getAll();
        }
    }
    public static Set<Id> existingAssetIdSet = new Set<Id>();
    
    @future
    public static void createAssetEntitlement(Id serviceContractId, Set<Id> contractLineItemIds) {
        ServiceContract sc = [Select Name,Id, AccountId,account.name, createdbyid,createdby.username,createdby.email,Account.CS_Account_Short_Name__c,
                             Account.CS_Contractual_Penalties__c, Account.CS_Reporting_Requirements__c 
                             from ServiceContract 
                              where Id = :serviceContractId];
        accountId = sc.AccountId;
        
        //receipientemailId=sc.createdbyid;
        receipientUserId=sc.createdbyid;
        accountname=sc.account.name;
        scname=sc.Name;
        accountShortName = sc.Account.CS_Account_Short_Name__c;
        sContractId = serviceContractId;
        contractualPenalty = sc.Account.CS_Contractual_Penalties__c;
        reportingRequirements = sc.Account.CS_Reporting_Requirements__c;
        
        List<RecordType> assetRecordTypes = [Select Id, Name from RecordType where SobjectType = 'Asset'];
        for (RecordType rt : assetRecordTypes) {
            if (rt.Name == 'Parent Asset') {
                parentRecordTypeId = rt.Id;
            } else if (rt.Name == 'Child Asset') {
                childRecordTypeId = rt.Id;
            }
        }

        System.debug('serviceContractId ' + serviceContractId + ' | contractLineItemIds ' + contractLineItemIds + ' | accountShortName ' + accountShortName);
        // Step 1, call create parent assets
        if (accountId != null && serviceContractId != null && contractLineItemIds != null) {
            createParentAssets(contractLineItemIds);
        }
        System.debug('parentAssetIdSet ' + parentAssetIdSet);

        // Step 2, if child assets inserted succesfully, call createParentAsset
        if (parentAssetIdSet != null && !parentAssetIdSet.isEmpty()) {
            createChildAssets(parentAssetIdSet);
        } else if (existingAssetIdSet != null && !existingAssetIdSet.isEmpty()) {
            createChildAssets(existingAssetIdSet);
        }

        // Step 3, if both parent and child assets are created succesfully, create entitlements
        if (allChildAssetIds != null && parentAssetIdSet != null) {
            createEntitlements(allChildAssetIds, contractLineItemIds);
            SendCommentEmail(receipientUserId,accountname,SCName);
        }
    }
    

    public static void createAssetEntitlementSync(Id serviceContractId, Set<Id> contractLineItemIds) {
        ServiceContract sc = [Select Name,Id, AccountId,account.name, createdbyid,createdby.username,createdby.email,Account.CS_Account_Short_Name__c, 
                              Account.CS_Contractual_Penalties__c, Account.CS_Reporting_Requirements__c 
                              from ServiceContract 
                              where Id = :serviceContractId];
        accountId = sc.AccountId;
        
        //receipientemailId=sc.createdbyid;
        receipientUserId=sc.createdbyid;
        accountname=sc.account.name;
        scname=sc.Name;
        accountShortName = sc.Account.CS_Account_Short_Name__c;
        sContractId = serviceContractId;
        contractualPenalty = sc.Account.CS_Contractual_Penalties__c;
        reportingRequirements = sc.Account.CS_Reporting_Requirements__c;
        
        List<RecordType> assetRecordTypes = [Select Id, Name from RecordType where SobjectType = 'Asset'];
        for (RecordType rt : assetRecordTypes) {
            if (rt.Name == 'Parent Asset') {
                parentRecordTypeId = rt.Id;
            } else if (rt.Name == 'Child Asset') {
                childRecordTypeId = rt.Id;
            }
        }

        System.debug('serviceContractId ' + serviceContractId + ' | contractLineItemIds ' + contractLineItemIds + ' | accountShortName ' + accountShortName);
        // Step 1, call create parent assets
        if (accountId != null && serviceContractId != null && contractLineItemIds != null) {
            createParentAssets(contractLineItemIds);
        }
        System.debug('parentAssetIdSet ' + parentAssetIdSet);

        // Step 2, if child assets inserted succesfully, call createParentAsset
        if (parentAssetIdSet != null && !parentAssetIdSet.isEmpty()) {
            createChildAssets(parentAssetIdSet);
        } else if (existingAssetIdSet != null && !existingAssetIdSet.isEmpty()) {
            createChildAssets(existingAssetIdSet);
        }

        // Step 3, if both parent and child assets are created succesfully, create entitlements
        if (allChildAssetIds != null && parentAssetIdSet != null) {
            createEntitlements(allChildAssetIds, contractLineItemIds);
            SendCommentEmail(receipientUserId,accountname,SCName);
        }
    }
    
    public static void createParentAssets(Set<Id> contractLineItemIds) {
        Set<String> skuIdSet = new Set<String>();
        Set<String> productCodeSet = new Set<String>(); 
        Set<String> sourceProductIds = new Set<String>();
    
        List<ContractLineItem> contractLineItems = [Select Id, CS_Product_Code__c, CS_SKU_Id__c, CS_Entitlement_Process_Name__c from ContractLineItem 
                                                   where Id in :contractLineItemIds];
        for (ContractLineItem cli : contractLineItems) {
            skuIdSet.add(cli.CS_SKU_Id__c);
            productCodeSet.add(cli.CS_Product_Code__c);
            if (cli.CS_SKU_Id__c != null) {
                sourceProductIds.add(cli.CS_SKU_Id__c);
                sourceProductToServiceLevelMap.put(cli.CS_SKU_Id__c, cli.CS_Entitlement_Process_Name__c);
            } 
            if (cli.CS_Product_Code__c != null) {
                sourceProductIds.add(cli.CS_Product_Code__c);
                sourceProductToServiceLevelMap.put(cli.CS_Product_Code__c, cli.CS_Entitlement_Process_Name__c);
            }
        }
        //System.debug('sourceProductToServiceLevelMap ' + sourceProductToServiceLevelMap);
        Set<String> supportGroupSet = new Set<String>();
        system.debug('++++++++++++ Source Product Ids==' + sourceProductIds  +'+++++++++++++++');
        // query product Relations for all scenarios and get the support group set to add to set
        // Added new Column CS_Source_Product__r.SKU_ID__c in Query for DE657
        productRelations = [Select CS_Source_Product__c, CS_Source_Product_Id__c, CS_Target_Product_Id__c,
                            CS_Target_Product__c, CS_Source_Product__r.recordtype.name, CS_Support_Group_Name__c,
                            CS_Target_Product__r.Name,CS_Target_Product__r.recordtype.name,CS_Source_Product__r.SKU_ID__c,
                            CS_No_Customer_Contact__c,CS_No_Software_Downloads__c from CS_Product_Relation__c
                            where CS_Source_Product_Id__c in :sourceProductIds and CS_Create_Asset__c=true];
        system.debug('++++++++++++ productRelations==' + productRelations  +'+++++++++++++++');
        Map<String,boolean>GrpNoacp= New Map<String,boolean>();
        Map<String,boolean>GrpNoSD= New Map<String,boolean>();
        //Bug Fix for Defect DE362
        for (CS_Product_Relation__c pr : productRelations) {
            if (pr.CS_Support_Group_Name__c != null ) {
                supportGroupSet.add(pr.CS_Support_Group_Name__c);     
                if(GrpNoacp.get(pr.CS_Support_Group_Name__c) ==null ){   
                        GrpNoacp.put(pr.CS_Support_Group_Name__c,pr.CS_No_Customer_Contact__c);  
                }  
                if(GrpNoSD.get(pr.CS_Support_Group_Name__c) ==null ){   
                        GrpNoSD.put(pr.CS_Support_Group_Name__c,pr.CS_No_Software_Downloads__c);  
                }    
            }
        }
        System.debug('supportGroupSet' +supportGroupSet);
        System.debug('GrpNoacp ' + GrpNoacp);
         System.debug('GrpNoSD ' + GrpNoSD);
    
        // query existing parent asset
        List<Asset> existingParentAssets = [Select Id, CS_Support_Group__c from Asset 
                                                where CS_Support_Group__c in :supportGroupSet
                                                and AccountId = :accountId 
                                                and RecordType.Name = 'Parent Asset'];
        
        //System.debug('existingParentAssets ' + existingParentAssets);
        Set<String> existingSupportGroupSet = new Set<String>();
        
        /* if parent asset exist for some CLIs, exclude the CLIs that have parent assets,
        * and create parent assets for only CLIs that don't have parent assets 
        * else if none of CLI has parent asset exist, create parent asset for each support group CLI belongs to
        */
        if (existingParentAssets != null && !existingParentAssets.isEmpty()) {
            for (Asset a : existingParentAssets) {
                existingSupportGroupSet.add(a.CS_Support_Group__c);
                existingAssetIdSet.add(a.Id);
            }
    
            Set<String> notExistSupportGroup = new Set<String>();
            for (String sGroup : existingSupportGroupSet) {
                if (!supportGroupSet.contains(sGroup)) {
                    notExistSupportGroup.add(sGroup);
                } 
            }
            System.debug('notExistSupportGroup ' + notExistSupportGroup);
            if (notExistSupportGroup != null && !notExistSupportGroup.isEmpty()) {
                // create parent asset and add to list
                for (String supportGroup : notExistSupportGroup) {
                    Asset parentAsset = new Asset();
                    parentAsset.CS_Support_Group__c = supportGroup;
                    parentAsset.Name = supportGroup;
                    parentAsset.AccountId = accountId;
                    parentAsset.RecordTypeId = parentRecordTypeId;
                    parentAsset.CS_No_Customer_Contact__c=GrpNoacp.get(supportGroup);
                    if(GrpNoacp.get(supportGroup)==true & GrpNoSD.get(supportGroup)==false){
                        parentAsset.CS_Not_in_Use__c=true;
                    }
                    parentAssetListToInsert.add(parentAsset);
                }
            } 
        } else {
            for (String sGroup : supportGroupSet) {
                Asset parentAsset = new Asset();
                parentAsset.CS_Support_Group__c = sGroup;
                parentAsset.Name = accountShortName+' '+sGroup;
                parentAsset.AccountId = accountId;
                parentAsset.RecordTypeId = parentRecordTypeId;
                parentAsset.Status='Implementation';
                parentAsset.CS_No_Customer_Contact__c=GrpNoacp.get(sGroup);
                if(GrpNoacp.get(sGroup)==true & GrpNoSD.get(sGroup)==false){
                        parentAsset.CS_Not_in_Use__c=true;
                    }
                //parentAsset.CS_Not_in_Use__c=GrpNoSD.get(sGroup);  
               
                parentAssetListToInsert.add(parentAsset);
            }
        }
        //System.debug('existingSupportGroupSet ' + existingSupportGroupSet);
        //System.debug('parentAssetListToInsert ' + parentAssetListToInsert);
        // insert parent assets
        try {
            Database.SaveResult[] srList = Database.insert(parentAssetListToInsert);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess() == true) {
                    parentAssetIdSet.add(sr.getId());
                }
            }
        } catch (DmlException ex) {  
           CS_ExceptionHandler.createErrorRecord(ex.getMessage(),sContractId);                               
            System.debug('an error has occured while inserting parent asset ' + ex.getMessage());
        }
    }  

    public static void createChildAssets(Set<Id> parentAssetIds) {
        // query inserted parent asssets
        system.debug('parentAssetIds=='+parentAssetIds);
        List<Asset> parentAssets  = [Select Id, CS_Support_Group__c 
                                    from Asset 
                                    where Id in :parentAssetIds];
        List<Asset> childAssetListToInsert = new List<Asset>();
    
        for (Asset parent : parentAssets) {
            for (CS_Product_Relation__c pr : productRelations) {
                if (parent.CS_Support_Group__c == pr.CS_Support_Group_Name__c) {
                    Asset child = new Asset();
                    child.ParentId = parent.Id;
                    child.Product2Id = pr.CS_Target_Product__c;
                    child.Name = accountShortName + ' ' + pr.CS_Target_Product__r.Name;
                    child.AccountId = accountId;
                    child.status='Implementation';
                    child.RecordTypeId = childRecordTypeId;
                    child.CS_Support_Group__c = parent.CS_Support_Group__c;
                    child.CS_Service_Level__c = sourceProductToServiceLevelMap.get(pr.CS_Source_Product_Id__c);
                    child.CS_Contractual_Financial_Penalties__c = contractualPenalty;
                    child.CS_Reporting_Requirements__c = reportingRequirements;
                    child.CS_Solution_Owners_By_Contract__c = (decimal)gwCustomSetting.get(sourceProductToServiceLevelMap.get(pr.CS_Source_Product_Id__c)).get('CS_Number_Of_Solution_Owners__c');
                    // Added check to Set Not in Flag to true only for Licensed to entitled product for DE307
                    if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' &&  pr.CS_Source_Product__r.recordtype.name=='Standard Products'){
                        child.CS_Not_in_Use__c=true;
                    }
                    if(pr.CS_No_Software_Downloads__c== true){
                        child.CS_No_Software_Downloads__c=true;
                       
                    }

                    // Stamping the SKU id on Child Asset for DE657
                    if(pr.CS_Source_Product__r.SKU_ID__c!=null){
                        child.CS_Product_SKU_ID__c=pr.CS_Source_Product__r.SKU_ID__c;
                    }
                    childAssetListToInsert.add(child);
                }
            }
        }
        //System.debug('===========childAssetListToInsert======= ' + childAssetListToInsert);
        try {
            Database.SaveResult[] srList = Database.insert(childAssetListToInsert);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess() == true) {
                    allChildAssetIds.add(sr.getId());
                }
            }
        } catch(DmlException ex) {
            CS_ExceptionHandler.createErrorRecord(ex.getMessage(),sContractId);                     
            System.debug('an error has occured while creating child assets ' + ex.getMessage());
        }
    
        /* query licensed product just inserted
         * and ind one and only one if there are more
         * then tie the licensed-to-licensed asset back to CLI
         */
        List<Asset> insertedlicensedAssets = [Select Id, Product2Id, CS_Support_Group__c, Product2.ProductCode  
                                           from Asset
                                           where Id in :allChildAssetIds
                                           and Product2.RecordType.Name = 'Standard Products'];
        //System.debug('insertedlicensedAssets ' + insertedlicensedAssets);
        Set<String> insertedAssetsSupportGroup = new Set<String>();
        Map<String, String> licensedAssetMap = new Map<String, String>();
        Map<String, String> licensedAssetToTargetProductMap = new Map<String, String>();
        
    
        Id licensedAssetId;
        
        if (insertedlicensedAssets != null && insertedlicensedAssets.size() > 0) {
            for (Asset a : insertedlicensedAssets) {
                licensedAssetMap.put(a.CS_Support_Group__c, a.Id);
                licensedAssetToTargetProductMap.put(a.Product2.ProductCode, a.Id);
            }
            licensedAssetId = insertedlicensedAssets[0].Id;
        }
        //System.debug('licensedAssetId ' + licensedAssetId);
        
        Map<Id, Id> licensedProductToAssetMap = new Map<Id, Id>();
        for (Asset a : insertedlicensedAssets) {
            licensedProductToAssetMap.put(a.Product2Id, licensedAssetId);
        }
        
        Map<String, String> targetToSourceMap = new Map<String, String>();
        Map<String, String> sourceToTargetMap = new Map<String, String>();
        Map<String, String> productGroupMap = new Map<String, String>();
        List<CS_Product_Relation__c> prList = [Select CS_Source_Product_Id__c, CS_Target_Product__c,CS_Support_Group_Name__c,
                                               CS_Target_Product_Id__c  from CS_Product_Relation__c
                                                   where CS_Target_Product__c in :licensedProductToAssetMap.keySet()
                                                   and CS_Product_Relation_Type__c 
                                                   in('Standard Products-Standard Products')];
        System.debug('licensed to licensed product relationship ' + prList);
        if (prList != null && !prList.isEmpty()) {
            for (CS_Product_Relation__c pr : prList) {
                sourceToTargetMap.put(pr.CS_Source_Product_Id__c, pr.CS_Target_Product_Id__c);
                productGroupMap.put(pr.CS_Source_Product_Id__c, pr.CS_Support_Group_Name__c);
                targetToSourceMap.put(pr.CS_Target_Product_Id__c, pr.CS_Source_Product_Id__c);
            }
        }
        
        Map<String, String> cliToSourceProductCodeMap = new Map<String, String>();
          
        // get source to target list map for linking asset to cli
        Map<String, List<String>> sourceToTargetListMap = new Map<String, List<String>>();
        for (String key : targetToSourceMap.keySet()) {
            if (!sourceToTargetListMap.containsKey(targetToSourceMap.get(key))) {
                sourceToTargetListMap.put(targetToSourceMap.get(key), new List<String>());
            }
            sourceToTargetListMap.get(targetToSourceMap.get(key)).add(key);
        }
        
        //System.debug('licensed to licensed sourceToTargetMap ' + sourceToTargetMap);
        // query source products' corresponding SCLIs
        List<ContractLineItem> lineItems = [Select Id, CS_Asset_Processed__c, AssetId, CS_Product_Code__c
                                            from ContractLineItem
                                            where ServiceContractId = :sContractId];
        //System.debug('sourceToTargetListMap ' + sourceToTargetListMap);
        // tie the licensed assets back to SCLIs
        List<ContractLineItem> lineItemsToUpdate = new List<ContractLineItem>();
        if (lineItems != null && !lineItems.isEmpty()) {
            for (ContractLineItem li : lineItems) {
                cliToSourceProductCodeMap.put(li.Id, li.CS_Product_Code__c);
                //system.debug('cliToSourceProductCodeMap.get(li.Id) ' + cliToSourceProductCodeMap.get(li.Id));
                if(cliToSourceProductCodeMap.get(li.Id) !=null){
                    if (sourceToTargetListMap != null && !sourceToTargetListMap.isEmpty() && sourceToTargetListMap.get(cliToSourceProductCodeMap.get(li.Id)) != null) {
                        for (String target : sourceToTargetListMap.get(cliToSourceProductCodeMap.get(li.Id))) {
                            if (licensedAssetToTargetProductMap != null && !licensedAssetToTargetProductMap.isEmpty() && licensedAssetToTargetProductMap.get(target) != null) {
                                li.AssetId = licensedAssetToTargetProductMap.get(target);
                                lineItemsToUpdate.add(li);
                            }
                        }
                    }
                }
                    
            }
    
            // update original lincensed line items
            //System.debug('updated line itmes ' + lineItemsToUpdate);
            if (lineItemsToUpdate != null && !lineItemsToUpdate.isEmpty()) {
                try {
                    update lineItemsToUpdate;
                } catch (DmlException ex) {
                    CS_ExceptionHandler.createErrorRecord(ex.getMessage(),sContractId);                     
                    System.debug('an error has occured ' + ex.getMessage());
                }
            }
        }
    }       
    
    
    public static void createEntitlements(Set<Id> childAssetIds, Set<Id> contractLineItemIds) {
        Set<String> productCodes = new Set<String>();
        Set<String> skuIds = new Set<String>();
        
        Map<String, String> cliToSlaMap = new Map<String, String>();
        Map<String, String> cliToBusinessHourMap = new Map<String, String>();
        Map<String, Date> contractLineItemStartDate = new Map<String, Date>();
        Set<String> lineItemProductSkuIds = new Set<String>();
        Set<String> lineItemProductCodes = new Set<String>();

        // query SCLIs
        List<ContractLineItem> lineItems = [Select Id, CS_Product_Code__c, StartDate, CS_SKU_Id__c, CS_Entitlement_Process_Name__c, CS_Business_Hours__c
                                            from ContractLineItem
                                            where Id in :contractLineItemIds];
        
        Map<String, String> assetToSkuIdOrProductCodeMap = new Map<String, String>();

        List<Asset> childAssets = [select Id, Product2Id, Product2.ProductCode, Product2.SKU_Id__c, product2.Name, AccountId ,CS_Product_SKU_ID__c
                                  from Asset
                                  where Id in :childAssetIds];
        
        Map<String, String> cliToSourceProductCodeMap = new Map<String, String>();
        Map<String, String> cliToSourceProductSkuMap = new Map<String, String>();
        Map<String, List<String>> sourceToTargetListMap = new Map<String, List<String>>();
        Map<String, String> assetToTargetProductSkuMap = new Map<String, String>();
        Map<String, String> assetToTargetProductCodeMap = new Map<String, String>();
        
        for (ContractLineItem cli : lineItems) {
            if (cli.CS_Product_Code__c != null) {
              
                cliToSlaMap.put(cli.CS_Product_Code__c, cli.CS_Entitlement_Process_Name__c);
                cliToBusinessHourMap.put(cli.CS_Product_Code__c, cli.CS_Business_Hours__c);
                contractLineItemStartDate.put(cli.CS_Product_Code__c, cli.StartDate);
                lineItemProductCodes.add(cli.CS_Product_Code__c);
                cliToSourceProductCodeMap.put(cli.Id, cli.CS_Product_Code__c);
            }
            if (cli.CS_SKU_Id__c != null) {
                cliToSlaMap.put(cli.CS_SKU_Id__c, cli.CS_Entitlement_Process_Name__c);
                cliToBusinessHourMap.put(cli.CS_SKU_Id__c, cli.CS_Business_Hours__c);
                contractLineItemStartDate.put(cli.CS_SKU_Id__c, cli.StartDate);
                lineItemProductSkuIds.add(cli.CS_SKU_Id__c);
                cliToSourceProductSkuMap.put(cli.Id, cli.CS_SKU_Id__c);
            }
            
        }
        System.debug('cliToSlaMap ' + cliToSlaMap + ' | contractLineItemStartDate' + contractLineItemStartDate);
        
        System.debug('childAssets ' + childAssets);
        for (Asset a : childAssets) {
            productCodes.add(a.Product2.ProductCode);
            if (a.Product2.ProductCode != null) {
                assetToSkuIdOrProductCodeMap.put(a.Id, a.Product2.ProductCode);
                assetToTargetProductCodeMap.put(a.Product2.ProductCode, a.Id);
            }

            
            if (a.Product2.SKU_Id__c != null) {
                assetToSkuIdOrProductCodeMap.put(a.Id, a.Product2.SKU_Id__c);
                assetToTargetProductSKuMap.put(a.Product2.SKU_Id__c, a.Id);
            }

        }
        //System.debug('assetToSkuIdOrProductCodeMap key set ' + assetToSkuIdOrProductCodeMap.values());

        Map<String, String> targetToSourceMap = new Map<String, String>();
        // query product relations and use maps to trace the target product back to the source product
        if (assetToSkuIdOrProductCodeMap != null && !assetToSkuIdOrProductCodeMap.isEmpty()) {
            
            List<CS_Product_Relation__c> licensedRelations = [Select Id, CS_Source_Product_Id__c, CS_Source_Product__c, CS_Target_Product_Id__c
                                                             from CS_Product_Relation__c
                                                             where CS_Target_Product_Id__c in :assetToSkuIdOrProductCodeMap.values()
                                                             and ( CS_Source_Product_Id__c in :lineItemProductSkuIds 
                                                                  or CS_Source_Product_Id__c in :lineItemProductCodes)];
            for (CS_Product_Relation__c pr : licensedRelations) {
                if (pr.CS_Target_Product_Id__c != null) {
                    targetToSourceMap.put(pr.CS_Target_Product_Id__c, pr.CS_Source_Product_Id__c);
                }
            }                                                 
        }
        //System.debug('targetToSourceMap ' + targetToSourceMap);
        
        // get source to target list map for linking asset to cli
        for (String key : targetToSourceMap.keySet()) {
            if (!sourceToTargetListMap.containsKey(targetToSourceMap.get(key))) {
                sourceToTargetListMap.put(targetToSourcemap.get(key), new List<String>());
            }
            sourceToTargetListMap.get(targetToSourceMap.get(key)).add(key);
        }
    
        
        // query slaProcess 
        Map<String, Id> slaProcessMap = new Map<String, Id>();
        List<SlaProcess> entitlementProcessList = [Select Id, Name 
                                                   from SlaProcess 
                                                   where Name in :cliToSlaMap.values()
                                                   and IsActive = true and IsVersionDefault = true];
        for (SlaProcess ep : entitlementProcessList) {
               slaProcessMap.put(ep.Name, ep.Id);
        }
    
        // query businessHours
        Map<String, Id> businessHoursMap = new Map<String, Id>();
        List<BusinessHours> businessHours = [Select Id, Name from BusinessHours where Name in :cliToBusinessHourMap.values()];
        for (BusinessHours bh : businessHours) {
            businessHoursMap.put(bh.Name, bh.Id);
        } 
        //System.debug('cliToBusinessHourMap ' + cliToBusinessHourMap + ' | assetToSkuIdOrProductCodeMap ' + assetToSkuIdOrProductCodeMap +  '| targetToSourceMap ' + targetToSourceMap);
        List<Entitlement> entitlmentListToInsert = new List<Entitlement>();
        for (Asset a : childAssets) {
            if (slaProcessMap != null && !slaProcessMap.isEmpty()) {
                Entitlement ent = new Entitlement();
                ent.AssetId = a.Id;
                ent.Name = accountShortName + ' ' + a.Product2.Name;
                ent.ServiceContractId = sContractId;
                ent.AccountId = a.AccountId;
                ent.SlaProcessId = slaProcessMap.get(cliToSlaMap.get(targetToSourceMap.get(assetToSkuIdOrProductCodeMap.get(a.Id))));
                System.debug(' business hour Id ' + cliToBusinessHourMap.get(targetToSourceMap.get(assetToSkuIdOrProductCodeMap.get(a.Id))));
                ent.BusinessHoursId = cliToBusinessHourMap.get(targetToSourceMap.get(assetToSkuIdOrProductCodeMap.get(a.Id)));
                ent.StartDate = contractLineItemStartDate.get(targetToSourceMap.get(assetToSkuIdOrProductCodeMap.get(a.Id)));
    
                entitlmentListToInsert.add(ent);
            }
        }

        //System.debug('entitlmentListToInsert ' + entitlmentListToInsert);

        // insert entitlement
        try {
            Database.SaveResult[] srList = Database.insert(entitlmentListToInsert);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess() == true) {
                    insertedEntitlementIds.add(sr.getId());
                }
            }
            //System.debug('assetToTargetProductCodeMap ' + assetToTargetProductCodeMap  + ' | assetToTargetProductSkuMap ' + assetToTargetProductSkuMap+ ' |sourceToTargetListMap ' + sourceToTargetListMap + ' |cliToSourceProductCodeMap ' + cliToSourceProductCodeMap + ' | cliToSourceProductSkuMap ' + cliToSourceProductSkuMap);
            if (insertedEntitlementIds != null && parentAssetIdSet != null && allChildAssetIds != null) {
                // if creation succeed, update asset processed flag on SCLI
                List<ContractLineItem> lineItemListToUpdate = new List<ContractLineItem>();
                //system.debug('++++++++++++lineItems='+lineItems + '+++++++++++++++');
                //system.debug('++++++++++++sourceToTargetListMap='+sourceToTargetListMap + '+++++++++++++++');
                //system.debug('++++++++++++cliToSourceProductCodeMap='+cliToSourceProductCodeMap + '+++++++++++++++');
                //system.debug('++++++++++++cliToSourceProductSkuMap='+cliToSourceProductSkuMap + '+++++++++++++++');
                //system.debug('++++++++++++assetToTargetProductSkuMap='+assetToTargetProductSkuMap + '+++++++++++++++');                
                //system.debug('++++++++++++++++sourceToTargetListMap='+ sourceToTargetListMap +'++++++++++');
                for (ContractLineItem cli : lineItems) {
                   // System.debug('  match: ' + sourceToTargetListMap.get(cliToSourceProductSkuMap.get(cli.Id)) + ' | ' + sourceToTargetListMap.get(cliToSourceProductSkuMap.get(cli.Id)));
                    if (sourceToTargetListMap.get(cliToSourceProductSkuMap.get(cli.Id)) != null) {
                        for (String target : sourceToTargetListMap.get(cliToSourceProductSkuMap.get(cli.Id))){

                            //System.debug('assetToTargetProductCodeMap ' + assetToTargetProductCodeMap.get(target));
                            // Using Product  MAP
                            if (assetToTargetProductCodeMap.get(target) != null) {
                                //system.debug('assetToTargetProductCodeMap=='+assetToTargetProductCodeMap);
                                cli.CS_Asset_Processed__c = true;
                                 // Stamping the Asset id on CLI  for DE657
                                cli.assetid=assetToTargetProductCodeMap.get(target);
                                lineItemListToUpdate.add(cli);
                                break;
                            }
                            // Added Else for SKU MAP
                            else if (assetToTargetProductSkuMap.get(target) != null){
                                //system.debug('assetToTargetProductSkuMap=='+assetToTargetProductSkuMap);
                                cli.CS_Asset_Processed__c = true;
                                 // Stamping the Asset id on CLI  for DE657
                                cli.assetid=assetToTargetProductSkuMap.get(target);
                                lineItemListToUpdate.add(cli);
                                break;

                            }
                        }


                    } 

                    if (sourceToTargetListMap.get(cliToSourceProductCodeMap.get(cli.Id)) != null) {
                        for (String target : sourceToTargetListMap.get(cliToSourceProductCodeMap.get(cli.Id))){
                            //System.debug('assetToTargetProductCodeMap ' + assetToTargetProductCodeMap.get(target));
                            if (assetToTargetProductCodeMap.get(target) != null) {
                                cli.CS_Asset_Processed__c = true;
                                 //cli.assetid=assetToTargetProductCodeMap.get(target);
                                lineItemListToUpdate.add(cli);
                                break;
                            }
                        }
                    }
                }
                if (lineItemListToUpdate != null && !lineItemListToUpdate.isEmpty()) {
                    update lineItemListToUpdate;
                }
            }

        } catch (DmlException ex) {
            CS_ExceptionHandler.createErrorRecord(ex.getMessage(),sContractId);                     
            System.debug('an error has occured while creating entitlements ' + ex.getMessage());
        }
    }

    public static void SendCommentEmail( Id receipientId,string SCAccountname,string strscname) {

        
        string Subject='Service Contract  for -'+ SCAccountname;                
        string TXTEmailBody='Service Contract -'+ strscname +' Processed Sucessfully';
        //TXTEmailBody +'\n***** System generated email , Please do not reply *****';
           
        // Send Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(receipientId);            
        mail.setSubject(Subject);
        mail.setPlainTextBody(TXTEmailBody);
        mail.setReplyTo('noreply@salesforce.com');
        mail.setUseSignature(false);
        mail.saveAsActivity = false;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
            mail
        });
    }            

}