@isTest
private class CS_GW_GenerateEntitledBatchTest {

    static testmethod void testGW_GenerateEntitledAssetsForDMBatch() {     



       Test.startTest();
       //Create an instance of the standard controller for the Service Contract 
        Account acc = CS_TestDataUtility.createCustomerAccount();

        //Add an opporutnity 
        /*
         opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500,
                                           Premium_In_Scope__c = 100,
        */

        //create parent asset
        List<Asset> parentAsset = CS_TestDataUtility.createParentAssetRecord(acc,true);

        //create product
        Product2 prd = CS_TestDataUtility.createStandardProduct();

        Product2 prd1 = CS_TestDataUtility.createEntitledProduct();

        //create pricebook 
        Pricebook2 pb = CS_TestDataUtility.createPriceBook();

        //create pricebookentry 

        PricebookEntry pbe = CS_TestDataUtility.createPriceBookEntry(prd,pb);

        //create child asset
        Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');
        childAsset.CS_RightNow_ID__c = 'abc';        
        update childAsset;

        //create child asset
        Asset childAsset1 = CS_TestDataUtility.createChildAssetRecord(acc, prd1, parentAsset[0], 'Implementation');
        childAsset.CS_RightNow_ID__c = 'abc';
        
        update childAsset1;
        //create contact
        Contact con = CS_TestDataUtility.createContact(acc, 'General Customer');
        CS_Product_Relation__c prdRel = CS_TestDataUtility.createStandardEntitledProductRelations(prd,prd1);
        prdRel.CS_Support_Group_Name__c = 'Billing System';
        update prdRel;
        Entitlement en = CS_TestDataUtility.createEntitlement(childAsset,acc);

       Database.executeBatch(new GW_GenerateEntitledAssetsForDMBatch());        
       Test.stopTest();
    }

    static testmethod void testGW_GenerateEntitledEntitlementForDMBatch() {       

       Test.startTest();
       //Create an instance of the standard controller for the Service Contract 
        Account acc = CS_TestDataUtility.createCustomerAccount();

        //Add an opporutnity 
        /*
         opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500,
                                           Premium_In_Scope__c = 100,
        */

        //create parent asset
        List<Asset> parentAsset = CS_TestDataUtility.createParentAssetRecord(acc,true);

        //create product
        Product2 prd = CS_TestDataUtility.createStandardProduct();

        Product2 prd1 = CS_TestDataUtility.createEntitledProduct();

        //create pricebook 
        Pricebook2 pb = CS_TestDataUtility.createPriceBook();

        //create pricebookentry 

        PricebookEntry pbe = CS_TestDataUtility.createPriceBookEntry(prd,pb);

        //create child asset
        Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');
        childAsset.CS_RightNow_ID__c = 'ENT-1';
        update childAsset;

        //create child asset
        Asset childAsset1 = CS_TestDataUtility.createChildAssetRecord(acc, prd1, parentAsset[0], 'Implementation');
        childAsset1.CS_RightNow_ID__c = 'ENT-2';
        childAsset1.Name = 'TCA TestEntitledProduct';
        update childAsset1;
        //create contact
        Contact con = CS_TestDataUtility.createContact(acc, 'General Customer');
        CS_Product_Relation__c prdRel = CS_TestDataUtility.createStandardEntitledProductRelations(prd,prd1);
        prdRel.CS_Support_Group_Name__c = 'Billing System';
        update prdRel;
        Entitlement en = CS_TestDataUtility.createEntitlement(childAsset,acc);
       Database.executeBatch(new GW_GenerateEntitledEntitlementForDMBatch());        
       Test.stopTest();
    }
}