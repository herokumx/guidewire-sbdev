@isTest
public class TestCS_ContractLineItemTriggerHandler {
	static User usr;
    static Account customerAcc;
    static Account partnerAcc;
    static PriceBook2 priceBook;
    static PricebookEntry pbeSku;
    static PricebookEntry pbeSku1;
    static PricebookEntry pbeSku2;
    static PricebookEntry pbeSku3;
    static PricebookEntry pbeMaintenance;
    static Product2 skuProduct;
    static Product2 skuProduct1;
    static Product2 skuProduct2;
    static Product2 skuProduct3;
    static ServiceContract serviceContract;
    static ContractLineItem cLineItemSku;
    static ContractLineItem cLineItemSku1;
    static ContractLineItem cLineItemSku2;
    static ContractLineItem cLineItemSku3;
    static ContractLineItem cLineItemMaintenance;
	
    
    static testMethod void testContractLineItemInsert() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        Product2 prodParent = new Product2();
        prodParent.Name = 'Rating Management';
        prodParent.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        insert prodParent;
        
        skuProduct = CS_TestDataUtility.createSkuProduct2(prodParent);
        priceBook = CS_TestDataUtility.createPriceBook();
        pbeSku = CS_TestDataUtility.createPriceBookEntry(skuProduct, priceBook);
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);
        
        Test.startTest();
        cLineItemSku = new ContractLineItem();
        cLineItemSku.ServiceContractId = serviceContract.Id;
        cLineItemSku.PricebookEntryId=pbeSku.Id;
        cLineItemSku.Quantity=1;
        cLineItemSku.UnitPrice=100.0;
        
        insert cLineItemSku;
        Test.stopTest();
    }
    
    static testMethod void testContractLineItemInsert2() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        Product2 prodParent = new Product2();
        prodParent.Name = 'Reinsurance';
        prodParent.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        insert prodParent;
        
        skuProduct = CS_TestDataUtility.createSkuProduct2(prodParent);
        priceBook = CS_TestDataUtility.createPriceBook();
        pbeSku = CS_TestDataUtility.createPriceBookEntry(skuProduct, priceBook);
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);
        
        Test.startTest();
        cLineItemSku = new ContractLineItem();
        cLineItemSku.ServiceContractId = serviceContract.Id;
        cLineItemSku.PricebookEntryId=pbeSku.Id;
        cLineItemSku.Quantity=1;
        cLineItemSku.UnitPrice=100.0;
        
        insert cLineItemSku;
        Test.stopTest();
    } 
    
    static testMethod void testContractLineItemInsert3() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        Product2 prodParent = new Product2();
        prodParent.Name = 'SAP';
        prodParent.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        insert prodParent;
        
        skuProduct = CS_TestDataUtility.createSkuProduct2(prodParent);
        priceBook = CS_TestDataUtility.createPriceBook();
        pbeSku = CS_TestDataUtility.createPriceBookEntry(skuProduct, priceBook);
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);
        
        Test.startTest();
        cLineItemSku = new ContractLineItem();
        cLineItemSku.ServiceContractId = serviceContract.Id;
        cLineItemSku.PricebookEntryId=pbeSku.Id;
        cLineItemSku.Quantity=1;
        cLineItemSku.UnitPrice=100.0;
        
        insert cLineItemSku;
        Test.stopTest();
    } 
    
    static testMethod void testContractLineItemInsert4() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        Product2 prodParent = new Product2();
        prodParent.Name = 'BFO';
        prodParent.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        insert prodParent;
        


        skuProduct = CS_TestDataUtility.createSkuProduct2(prodParent);
        priceBook = CS_TestDataUtility.createPriceBook();
        pbeSku = CS_TestDataUtility.createPriceBookEntry(skuProduct, priceBook);
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);
        
        Test.startTest();
        cLineItemSku = new ContractLineItem();
        cLineItemSku.ServiceContractId = serviceContract.Id;
        cLineItemSku.PricebookEntryId=pbeSku.Id;
        cLineItemSku.Quantity=1;
        cLineItemSku.UnitPrice=100.0;
        
        insert cLineItemSku;
        Test.stopTest();
    } 

static testMethod void testContractLineItemInsertAll() {

        Test.startTest();
        customerAcc = CS_TestDataUtility.createCustomerAccount();

        RecordType StandardRecordType = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'Standard_Products' and SobjectType = 'Product2' limit 1];
        Product2 prodParent1 = new Product2();
        prodParent1.Name = 'Rating Management';
        prodParent1.SKU_ID__c='Rating Management';
        prodParent1.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        prodParent1.RecordTypeId = StandardRecordType.Id;
        insert prodParent1;


        Product2 prodParent2 = new Product2();
        prodParent2.Name = 'Reinsurance';
        prodParent2.SKU_ID__c='Reinsurance';
        prodParent2.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        prodParent2.RecordTypeId = StandardRecordType.Id;
        insert prodParent2;


        Product2 prodParent3 = new Product2();
        prodParent3.Name = 'SAP';
        prodParent3.SKU_ID__c='SAP';
        prodParent3.CS_Serial_Number__c = 'TESTSERIALNUMBER';
        prodParent3.RecordTypeId = StandardRecordType.Id;
        insert prodParent3;
        

        priceBook = CS_TestDataUtility.createPriceBook();
        serviceContract = CS_TestDataUtility.createServiceContract(customerAcc);

        skuProduct1 = CS_TestDataUtility.createSkuProduct2A(prodParent1,'Rating Management','10001');
        pbeSku1 = CS_TestDataUtility.createPriceBookEntry(skuProduct1, priceBook);

        skuProduct2 = CS_TestDataUtility.createSkuProduct2A(prodParent2,'Reinsurance','10002');
        pbeSku2 = CS_TestDataUtility.createPriceBookEntry(skuProduct2, priceBook);

        skuProduct3 = CS_TestDataUtility.createSkuProduct2A(prodParent3,'SAP','1003');
        pbeSku3 = CS_TestDataUtility.createPriceBookEntry(skuProduct3, priceBook);
        

        
        skuProduct1 = CS_TestDataUtility.createSkuProduct2(prodParent1);
       
        List<ContractLineItem> newCLI= New List<ContractLineItem>();

        cLineItemSku1 = new ContractLineItem();
        cLineItemSku1.ServiceContractId = serviceContract.Id;
        cLineItemSku1.PricebookEntryId=pbeSku1.Id;
        cLineItemSku1.Quantity=1;
        cLineItemSku1.UnitPrice=100.0;
        newCLI.add(cLineItemSku1);

        cLineItemSku2 = new ContractLineItem();
        cLineItemSku2.ServiceContractId = serviceContract.Id;
        cLineItemSku2.PricebookEntryId=pbeSku2.Id;
        cLineItemSku2.Quantity=1;
        cLineItemSku2.UnitPrice=100.0;

        newCLI.add(cLineItemSku2);


        cLineItemSku3 = new ContractLineItem();
        cLineItemSku3.ServiceContractId = serviceContract.Id;
        cLineItemSku3.PricebookEntryId=pbeSku3.Id;
        cLineItemSku3.Quantity=1;
        cLineItemSku3.UnitPrice=100.0;

        newCLI.add(cLineItemSku3);
        System.debug('---------newCLI---------'+newCLI);
        insert newCLI;

        Servicecontract newSC= [select CS_BFO__c,CS_Rating_Management__c,
                                              CS_Rating_Management_Key__c,CS_Re_Insurance__c, CS_Re_Insurance_Key__c,CS_SAP_Production__c,
                                              CS_SAP_Production_Key__c from ServiceContract where id=:serviceContract.Id];
        System.debug('------SC--------' +newSC);                              
        Test.stopTest();
    }

}