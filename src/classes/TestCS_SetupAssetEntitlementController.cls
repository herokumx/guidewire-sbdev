@isTest
public class TestCS_SetupAssetEntitlementController {
    static User usr;
    static Account customerAcc;
    static Account partnerAcc;
    static PriceBook2 priceBook;
    static PricebookEntry pbeSku;
    static PricebookEntry pbeMaintenance;
    static Product2 skuProduct;
    static Product2 maintenanceProduct;
    static Product2 entitledProduct;
    static Product2 standardProduct;
    static CS_Customer_Support__c customerSupportCustomSetting;
    static ServiceContract serviceContract;
    static ContractLineItem cLineItemSku;
    static ContractLineItem cLineItemMaintenance;
    static CS_Product_Relation__c skuEntitledRelation;
    static CS_Product_Relation__c standardToEntitledRelation;
    static CS_Product_Relation__c standardToStandardRelation;
    static CS_SetupAssetEntitlementController controllerExt;
    
    private static void setupTestData() {
        usr = CS_TestDataUtility.createTestUser();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        priceBook = CS_TestDataUtility.createPriceBook();
        skuProduct = CS_TestDataUtility.createSkuProduct();
        entitledProduct = CS_TestDataUtility.createEntitledProduct();
        standardProduct = CS_TestDataUtility.createStandardProduct();
		skuEntitledRelation = CS_TestDataUtility.createSkuEntitledProductRelations(skuProduct, entitledProduct);
        standardToEntitledRelation = CS_TestDataUtility.createStandardEntitledProductRelations(standardProduct, entitledProduct);
        standardToStandardRelation = CS_TestDataUtility.createStandardToStandardProductRelations(standardProduct, standardProduct);
        maintenanceProduct = CS_TestDataUtility.createMaintenanceProduct();
        System.debug('maintenanceProduct ' + maintenanceProduct);
        pbeSku = CS_TestDataUtility.createPriceBookEntry(skuProduct, priceBook);
        pbeMaintenance = CS_TestDataUtility.createPriceBookEntry(maintenanceProduct, priceBook);
        customerSupportCustomSetting = CS_TestDataUtility.createNumberOfSoluttionOwnerCustomSettings();
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);
        cLineItemSku = CS_TestDataUtility.createServiceContractLineItem(serviceContract, pbeSku);
        cLineItemMaintenance = CS_TestDataUtility.createServiceContractLineItem(serviceContract, pbeMaintenance);
    }
    
    private static void setupProperties() {
        ApexPages.StandardController con = new ApexPages.StandardController(ServiceContract);
        controllerExt = new CS_SetupAssetEntitlementController(con);
        List<ContractLineItem> lineItems = controllerExt.cLineItemList;
        controllerExt.selectedMaintenanceSKUs[0] = 'Gold';
        BusinessHours bh = [Select Id, Name from BusinessHours where Name = 'GMT' limit 1];
        controllerExt.selectedBusinessHour[0] = bh.Id;
        //List<SelectOption> maintenanceSkus = controllerExt.retrieveMaintenanceSKUs();
        //List<SelectOption> businessHours = controllerExt.retrieveBusinessHours();
        //List<Product2> skuProducts = controllerExt.retrieveSKUProducts();
        
    }
    
    static testMethod void testSubmit() {
        setupTestData();
        setupProperties();
        
        Test.startTest();
        controllerExt.submit();
        Test.stopTest();
    } 
    
    static testMethod void testSubmitNow() {
        setupTestData();
        setupProperties();
        
        Test.startTest();
        controllerExt.submitNow();
        Test.stopTest();
    } 
}