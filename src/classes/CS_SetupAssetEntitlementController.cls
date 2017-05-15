/*
*****************************************************************************************************************************
Class Name - CS_SetupAssetEntitlementController
Class Type -  VF Controller
Test Class-
Purpose- 

*****************************************************************************************************************************

Name        Email              Date                 Notes 
Shan Xu                                            Initial Creation
Shan Xu                       09/26/2016           Fixed for DE1183  remove Non Standard from Maintenance SKU Picklist 
*****************************************************************************************************************************
*/

public with sharing class CS_SetupAssetEntitlementController {
    /*** Properties***/
    Id serviceContractId;
    public List<Product2> products {get;set;}
    public Integer[] productLength {get;set;}
    public List<ContractLineItem> cLineItemList {
        get {
            return [Select Id, LineItemNumber, CS_Entitlement_Process_Name__c, CS_Business_Hours__c,
            ServiceContractId, CS_Product_Name__c, CS_Product_Code__c, CS_SKU_Id__c, CS_Product_Serial_Number__c,
            AssetId, StartDate, PriceBookEntryId from ContractLineItem where ServiceContractId = :serviceContractId];
        }
    }
    public Integer CLICount { 
        get {
            return cLineItemList.size() ;
            }
    }
    public Set<Id> contractLineItemIds = new Set<Id>();
    public ServiceContract serviceContractAccount {get;set;}
    public Set<Id> maintenanceSkuPbeIdSet = new Set<Id>();
    public Map<Integer, Boolean> assetsExist {get;set;}

    public Set<Id> productIdSet = new Set<Id>();

    public List<SelectOption> maintenanceSKUs {get;set;}
    public String[] selectedMaintenanceSKUs {get;set;}
    public String[] selectedBusinessHour {get;set;}

    public String[] dateStrings {get;set;}
    public Date[] selectedDates {get;set;}

    public List<SelectOption> businessHours {get;set;}

    public Set<Id> cliPriceBookEntrySet = new Set<Id>();

    public Map<Integer, List<SelectOption>> maintenanceSkuMap {
        get {
            Map<Integer, List<SelectOption>> tempMap = new Map<Integer, List<SelectOption>>();

            if (products.size() > 0) {
                    for (Integer i = 0; i < products.size(); i++) {
                            tempMap.put(i, maintenanceSKUs);
                    }
            }

            return tempMap;
        }
    }

    public String defaultMaintenanceSku {get;set;}
    public Map<Integer, List<SelectOption>> businessHoursMap {
        get {
            Map<Integer, List<SelectOption>> tempMap = new Map<Integer, List<SelectOption>>();
            if (products.size() > 0) {
                    for (Integer i = 0; i < products.size(); i++) {
                            tempMap.put(i, businessHours);
                    }
            }

            return tempMap;
        }
    }
    public Set<Id> updatedCliIds = new Set<Id>();

    public Map<String, String> productToSlaMap = new Map<String, String>();
    public Map<String, String> productToBusinessHourMap = new Map<String, String>();
    /***End properties***/

    public CS_SetupAssetEntitlementController(ApexPages.StandardController stdController) {
        ServiceContract sc = (ServiceContract)stdController.getRecord();
        serviceContractId = sc.Id;
        serviceContractAccount = [Select Account.Name, AccountId from ServiceContract where Id = :serviceContractId];

        Date today = Date.today();

        if (cLineItemList != null && !cLineItemList.isEmpty()) {
            for (ContractLineItem cli : cLineItemList) {
                contractLineItemIds.add(cli.Id);
            }
        }

        products = retrieveSKUProducts();
        maintenanceSKUs = retrieveMaintenanceSKUs();
        businessHours = retrieveBusinessHours();

        assetsExist =  getExistingAssets();

        getExistingSlaInfo();

         if (products != null) {
            selectedMaintenanceSKUs = new String[]{};
            selectedBusinessHour = new String[]{};
            selectedDates = new Date[]{};
            productLength = new Integer[]{};
            
            System.debug('productToSlaMap ' + productToSlaMap);

            for (Integer i = 0; i < products.size(); i++) {
                System.debug('assetsExist ' + assetsExist.get(i));
                if (assetsExist.get(i) == true) {
                    productLength.add(i);
                    selectedDates.add(today);
                    selectedMaintenanceSKUs.add(productToSlaMap.get(products[i].SKU_ID__c) != null ? productToSlaMap.get(products[i].SKU_ID__c) : '');
                    selectedBusinessHour.add(productToBusinessHourMap.get(products[i].SKU_ID__c) != null ? productToBusinessHourMap.get(products[i].SKU_ID__c) : '');
                } else {
                    productLength.add(i);
                    selectedDates.add(today);
                    selectedMaintenanceSKUs.add('');
                    selectedBusinessHour.add('');
                }
            }
        }

    }

    public List<Product2> retrieveSKUProducts() {
        // get a pricebookentry ids for querying related products
        Set<Id> priceBookEntryIdSet = new Set<Id>();
        //List<ContractLineItem> cLineItemLst = [Select Id, LineItemNumber, ServiceContractId, PriceBookEntryId from ContractLineItem where ServiceContractId = :cLineItem.Id];
        if (cLineItemList != null) {
                for (ContractLineItem lineItem : cLineItemList) {
                        priceBookEntryIdSet.add(lineItem.PriceBookEntryId);
                }
        }
        System.debug('priceBookEntryIdSet ' + priceBookEntryIdSet);

        //List<String> productNames = new List<String>();

        List<PriceBookEntry> pbEntryList = [Select Id, Product2Id, Product2.Name from PriceBookEntry where Id in :priceBookEntryIdSet and Product2.CS_Support_Type__c = null];
        System.debug('pbEntryList ' + pbEntryList);
        for (PriceBookEntry pbe : pbEntryList) {
                productIdSet.add(pbe.Product2Id);
                //productNames.add(pbe.Product2.Name);
                cliPriceBookEntrySet.add(pbe.Id);
        }

        System.debug('cliPriceBookEntrySet ' + cliPriceBookEntrySet);

        // query related products based on pricebookentryids
        List<Product2> productSKUs = [Select Id, Name, SKU_ID__c from Product2 where Id in :productIdSet];

        return productSKUs;

    }

    public List<SelectOption> retrieveMaintenanceSKUs() {
        List<SelectOption> soList = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = ContractLineItem.CS_Entitlement_Process_Name__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        Set<Id> otherPriceBookEntryIdSet = new Set<Id>();
        // query other service contract records belong to this account
        List<ServiceContract> otherServiceContractList = [Select Id, (Select Id, PriceBookEntryId from ContractLineItems) from ServiceContract where AccountId =:serviceContractAccount.AccountId];
        for (ServiceContract sc : otherServiceContractList) {
            for (ContractLineItem cli : sc.ContractLineItems) {
                otherPriceBookEntryIdSet.add(cli.PriceBookEntryId);
            }
        }
        Set<String> maintenanceProductNames = new Set<String>();
        List<PriceBookEntry> otherPbEntryList = [Select Id, Product2Id, Product2.Name from PriceBookEntry where Id in :otherPriceBookEntryIdSet and Product2.CS_Support_Type__c != null];
        if (otherPbEntryList != null && otherPbEntryList.size() > 0) {
            //defaultMaintenanceSku = otherPbEntryList[0].Product2Id;
        
            for (PriceBookEntry pbe : otherPbEntryList) {
                maintenanceProductNames.add(pbe.Product2.Name);
            }
            System.debug('maintenanceProductNames ' + maintenanceProductNames);
            for (Schema.PicklistEntry f: ple) {
                for (String s : maintenanceProductNames) {
                    String sub = f.getLabel().substringBefore(' ');
                    System.debug( 's.contains(sub.) ' + s.contains(sub) );
                    if (s.contains(sub)) {
                        //defaultMaintenanceSku = f.getValue();
                        soList.add(new SelectOption(f.getLabel(), f.getValue()));
                    }
                } 
            } 
        } 
        //soList.add(new SelectOption('Non-Standard', 'Non-Standard'));
        soList.add(new SelectOption('None', 'None'));

        return soList;
    }

    public List<SelectOption> retrieveBusinessHours() {
        List<SelectOption> businessHoursSoList = new List<SelectOption>();
        List<BusinessHours> businessHours = [Select Id, Name from BusinessHours];

        for (BusinessHours bh : businessHours) {
                businessHoursSoList.add(new SelectOption(bh.Id, bh.Name));
        }

        return businessHoursSoList;
    }

    public Map<Integer, Boolean> getExistingAssets() {

        Map<String, Boolean> cliAssetExistMap = new Map<String, Boolean>();
        List<ContractLineItem> existingAssetCli = [Select Id, CS_SKU_Id__c, CS_Asset_Processed__c from ContractLineItem
                                                  where Product_Type__c = 'Product SKU'
                                                  and ServiceContractId = :serviceContractId];
        for(ContractLineItem cli : existingAssetCli) {
            cliAssetExistMap.put(cli.CS_SKU_Id__c, cli.CS_Asset_Processed__c);
        }
        System.debug('cliAssetExistMap ' + cliAssetExistMap);
        Map<Integer, Boolean> productAssetExistMap = new Map<Integer, Boolean>();
        for (Integer i=0; i<products.size(); i++) {
            if (cliAssetExistMap.get(products[i].SKU_Id__c) == false) {
                productAssetExistMap.put(i, false);
            } else {
                productAssetExistMap.put(i, true);
            }
        }
        System.debug('productAssetExistMap' + productAssetExistMap);
        return productAssetExistMap;
    }

    public void submit() {
        /*** Step 1
        * Assign SlaProcess and BusinessHours input to Contract Line Items
         ****/
        assignCliFieldValues();

        /*** Step 2 
        *Call future method to create assets, entitlements 
        */
        Map<Id, ContractLineItem> contractLineItemToSetupMap = new Map<Id, ContractLineItem>([Select Id from ContractLineItem where ServiceContractId = :serviceContractId
                                                                                              and CS_Asset_Processed__c = false]);
        if (contractLineItemToSetupMap != null && !contractLineItemToSetupMap.isEmpty() &&  serviceContractId != null) {
            CS_CustomerOnboarding_Util.createAssetEntitlement(serviceContractId, contractLineItemToSetupMap.keySet());
            
        }

    }


public void submitnow() {
        /*** Step 1
        * Assign SlaProcess and BusinessHours input to Contract Line Items
         ****/
        assignCliFieldValues();

        /*** Step 2 
        *Call future method to create assets, entitlements 
        */
        Map<Id, ContractLineItem> contractLineItemToSetupMap = new Map<Id, ContractLineItem>([Select Id from ContractLineItem where ServiceContractId = :serviceContractId
                                                                                              and CS_Asset_Processed__c = false]);
        if (contractLineItemToSetupMap != null && !contractLineItemToSetupMap.isEmpty() &&  serviceContractId != null) {
            
            CS_CustomerOnboarding_Util.createAssetEntitlementSync(serviceContractId, contractLineItemToSetupMap.keySet());
        }

    }


    /*
    * This method assigns businesshours and slaProcess input to corresponding SCLI field values
    */
    public void assignCliFieldValues() {
        Map<String, String> skuToMaintenanceMap = new Map<String, String>();
        Map<String, String> skuToBusinessHourMap = new Map<String, String>();
        Map<String, Date> skuToStartDateMap = new Map<String, Date>();
        Map<Integer, Boolean> assetExist = getExistingAssets();
        for (Integer i=0; i< products.size(); i++) {
            if (assetExist.get(i) == false) {
                skuToMaintenanceMap.put(products[i].SKU_ID__c, selectedMaintenanceSKUs[i]);
                skuToBusinessHourMap.put(products[i].SKU_ID__c, selectedBusinessHour[i]);
                skuToStartDateMap.put(products[i].SKU_ID__c, selectedDates[i]);
            }
        }
		System.debug('skuToMaintenanceMap ' + skuToMaintenanceMap);
        Map<String, Id> slaProcessMap = new Map<String, Id>();
        List<SlaProcess> slaProcessList = [Select Id, Name from SlaProcess where Name in :selectedMaintenanceSKUs];
        for (SlaProcess sla : slaProcessList) {
            slaProcessMap.put(sla.Name, sla.Id);
        }
        
        // retrieve GW customer support custom setting to get # of solution owners
        Map<String, CS_Customer_Support__c> gwCustomSetting = CS_Customer_Support__c.getAll();

        List<ContractLineItem> cLineItemListToUpdate = new List<ContractLineItem>();
        for (ContractLineItem cli : cLineItemList) {
            // exclude the maintenance sku line item
            if (skuToMaintenanceMap.get(cli.CS_SKU_Id__c) != null) {
                cli.CS_Entitlement_Process_Name__c = skuToMaintenanceMap.get(cli.CS_SKU_Id__c);
                cli.CS_Business_Hours__c = skuToBusinessHourMap.get(cli.CS_SKU_Id__c);
                cli.StartDate = skuToStartDateMap.get(cli.CS_SKU_Id__c);
                System.debug('skuToMaintenanceMap.get(cli.CS_SKU_Id__c)) ' + skuToMaintenanceMap.get(cli.CS_SKU_Id__c));
                cli.CS_Solution_Owners_Allowed__c = (decimal)gwCustomSetting.get(skuToMaintenanceMap.get(cli.CS_SKU_Id__c)).get('CS_Number_Of_Solution_Owners__c');
    
                cLineItemListToUpdate.add(cli);
            }
        }

        System.debug('cLineItemList to update ' + cLineItemListToUpdate);
        try {
            Database.SaveResult[] srList = Database.update(cLineItemListToUpdate);
            System.debug('srList ' + srList);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess() == true) {
                    updatedCliIds.add(sr.getId());
                }
            }
        } catch (Exception ex) {
            System.debug('you have encountered following error while updating ContractLineItem ' + ex.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error: you have encountered following error while updating ContractLineItem' + ex.getMessage()));
        }
    }

    public void getExistingSlaInfo() {

        if (cLineItemList != null && !cLineItemList.isEmpty()) {
            for (ContractLineItem c : cLineItemList) {
                if (c.CS_SKU_Id__c != null) {
                    productToSlaMap.put(c.CS_SKU_ID__c, c.CS_Entitlement_Process_Name__c);
                    productToBusinessHourMap.put(c.CS_SKU_ID__c, c.CS_Business_Hours__c);
                }
            }
        }
    }

}