/*
*****************************************************************************************************************************
Class Name - CS_AddContractlineitemTest
Class Type -  Trigger Handler Test Ckass 
Test Class-
Purpose- 

*****************************************************************************************************************************

Name        Email              Date             Notes 
Suchitra                                        Initial Creation

*****************************************************************************************************************************
*/

@isTest(seeAlldata = True)
private class CS_AddContractlineitemTest{

    //Test the Custom Visualforce page and its related CS_AddContractLineItems
    static testMethod void testCS_AddContractlineitemTest() {
   
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
        Product2 prd = CS_TestDataUtility.createProductRecord();

        //create pricebook 
        Pricebook2 pb = CS_TestDataUtility.createPriceBook();

        //create pricebookentry 

        PricebookEntry pbe = CS_TestDataUtility.createPriceBookEntry(prd,pb);

        //create child asset
        Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');

        //create contact
        Contact con = CS_TestDataUtility.createContact(acc, 'General Customer');

        //create service contract 
        ServiceContract sc = CS_TestDataUtility.createServiceContract(acc);  

        //create service contracl line items 
        ContractLineItem cntractLineItem =  CS_TestDataUtility.createServiceContractLineItem(sc,  pbe) ; 
  
        //Actual test begins from here. create a standard controller for the service contract. 
        ApexPages.StandardController scControl = new ApexPages.StandardController(sc);


        CS_AddContractlineitem csAddContractLineItem = new CS_AddContractlineitem(scControl); 
        csAddContractLineItem.priceBookCheck();
        //csAddContractLineItem.forcePricebookSelection = true;

        //PageReference priceBookCheck =csAddContractLineItem.priceBookCheck();
        //csAddContractLineItem.updateAvailableList();
        csAddContractLineItem.addToShoppingCart(); 
        csAddContractLineItem.removeFromShoppingCart();   
        PageReference pgeOnSave = csAddContractLineItem.onSave(); 
        PageReference pgeOnCancel = csAddContractLineItem.onCancel(); 

   
    }

}