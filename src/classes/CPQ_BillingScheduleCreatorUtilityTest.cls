/* =================================================================================================
*   Version     Date                   Comment
* =================================================================================================
*   1.0         04-Apr-2017           Test class for CPQ_BillingScheduleCreatorUtility.
**/
@isTest
public with sharing class CPQ_BillingScheduleCreatorUtilityTest {

    public static final String NET15 = 'Net 15';
    public static final String MONTHLY = 'Monthly';
    public static final String SEMIANNUAL = 'Semiannual';
    public static Id accountId;
    public static Id serviceContractId;
    public static Id opportunityId;
    public static Id contractId;
    public static Id quoteId;

    /*@testSetup static void commonObjects() {

        Account accObj = CPQ_TestDataUtility.accountTestData(true);
        accountId = accObj.Id;

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);
        serviceContractId = serviceContrObj.Id;

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);
        opportunityId = oppObj.Id;



    }*/

    /**
     * Test method to check OrderItem and SBQQ__QuoteLine__c created accordingly
     **/
    @isTest static void renewalMaintenanceCreateOrderItemBillingSchedule() {

        //Account obj = [Select Id,Name From Account Where Name = 'Test Account' Limit 1];
        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
        oppObj.Original_Opportunity_New__c = opportunityId;
        insert oppObj;

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

        oppObj.SBQQ__RenewedContract__c = contractObj.Id;
        update oppObj;
        //Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

        SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);

        // Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        // oppWithContract.Service_Contract__c = serviceContractId;
        oppObj.SBQQ__PrimaryQuote__c = quoteObj1.Id;
        oppObj.SBQQ__Renewal__c = true;
        update oppObj;


        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
        prod2Obj.Sku_Type__c = CPQ_BillingScheduleCreatorUtility.PRODUCT_SKU_TYPE_MAINTENANCE;
        insert prod2Obj;

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today() + 1;
        quoteObj.SBQQ__EndDate__c = Date.today().addYears(1).addMonths(2);
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = 'Monthly';
        quoteObj.SBQQ__Opportunity2__c  = oppObj.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
        quoteLineItemObj.CPQ_Last_Quote_Invoiced_Support__c = 1000000;
        insert quoteLineItemObj;

        System.Test.startTest();
        Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppObj.Id, false);
        orderObj.Is_Primary__c = true;
        orderObj.SBQQ__Quote__c = quoteObj.Id;
        orderObj.SBQQ__BillingFrequency__c  = 'Monthly';
        orderObj.First_Invoice_Date__c = System.Today();
        orderObj.First_Period_Start_Date__c = System.Today();
        insert orderObj;

         quoteObj.SBQQ__Type__c = CPQ_BillingScheduleCreatorUtility.SBQQ_TYPE_RENEWAL;
         update quoteObj;

         System.debug('...CPQ_Order_BillingSchedule_Helper.run before order' + CPQ_Order_BillingSchedule_Helper.run);

         CPQ_Order_BillingSchedule_Helper.run = true;
         update orderObj;

         System.Test.stopTest();

         List<OrderItem> lstOrderItem = [SELECT Id
                                              , OrderId
                                              , Product2Id
                                          FROM OrderItem
                                         WHERE OrderId =: orderObj.Id
                                          ];
         system.debug('...lstOrderItem: '+lstOrderItem);

         List<CPQ_Billing_Schedule__c> lstBillingSchedule = [
         SELECT Id
             , Name
             , Order__c
             , startdate__c
             , Order_Product__c
             FROM CPQ_Billing_Schedule__c
             WHERE Order_Product__c =: lstOrderItem[0].Id
         ];
         System.assertEquals(1, lstOrderItem.size());
         System.assertEquals(15, lstBillingSchedule.size());
    }

    // @isTest static void renewalMaintenanceZeroCreateOrderItemBillingSchedule() {
    //
    //     //Account obj = [Select Id,Name From Account Where Name = 'Test Account' Limit 1];
    //     Account accObj = CPQ_TestDataUtility.accountTestData(true);
    //
    //     Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
    //     oppObj.Original_Opportunity_New__c = opportunityId;
    //     insert oppObj;
    //
    //     Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);
    //
    //     oppObj.SBQQ__RenewedContract__c = contractObj.Id;
    //     update oppObj;
    //     //Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
    //
    //     SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
    //
    //     // Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
    //     // oppWithContract.Service_Contract__c = serviceContractId;
    //     oppObj.SBQQ__PrimaryQuote__c = quoteObj1.Id;
    //     oppObj.SBQQ__Renewal__c = true;
    //     update oppObj;
    //
    //
    //     Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
    //     prod2Obj.Sku_Type__c = CPQ_BillingScheduleCreatorUtility.PRODUCT_SKU_TYPE_MAINTENANCE;
    //     insert prod2Obj;
    //
    //     PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
    //     Id pricebookId = Test.getStandardPricebookId();
    //
    //     SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
    //     quoteObj.SBQQ__StartDate__c = Date.today() + 1;
    //     quoteObj.SBQQ__EndDate__c = Date.today().addYears(1).addMonths(2);
    //     quoteObj.SBQQ__PaymentTerms__c = NET15;
    //     quoteObj.SBQQ__SubscriptionTerm__c = 6;
    //     quoteObj.SBQQ__BillingFrequency__c  = 'Monthly';
    //     quoteObj.SBQQ__Opportunity2__c  = oppObj.Id;
    //     quoteObj.SBQQ__Primary__c = true;
    //     quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
    //     insert quoteObj;
    //
    //     SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, true);
    //
    //     System.Test.startTest();
    //     Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppObj.Id, false);
    //     orderObj.Is_Primary__c = true;
    //     orderObj.SBQQ__Quote__c = quoteObj.Id;
    //     orderObj.SBQQ__BillingFrequency__c  = 'Monthly';
    //     orderObj.First_Invoice_Date__c = System.Today();
    //     orderObj.First_Period_Start_Date__c = System.Today();
    //     insert orderObj;
    //
    //      quoteObj.SBQQ__Type__c = CPQ_BillingScheduleCreatorUtility.SBQQ_TYPE_RENEWAL;
    //      update quoteObj;
    //
    //      CPQ_Order_BillingSchedule_Helper.run = true;
    //      update orderObj;
    //
    //      System.Test.stopTest();
    //
    // }


    @isTest static void renewalLicensecreateOrderItemBillingSchedule() {

        //Account obj = [Select Id,Name From Account Where Name = 'Test Account' Limit 1];
        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
        oppObj.Original_Opportunity_New__c = opportunityId;
        insert oppObj;

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

        oppObj.SBQQ__RenewedContract__c = contractObj.Id;
        update oppObj;
        //Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

        SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);

        // Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        // oppWithContract.Service_Contract__c = serviceContractId;
        oppObj.SBQQ__PrimaryQuote__c = quoteObj1.Id;
        oppObj.SBQQ__Renewal__c = true;
        update oppObj;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
        prod2Obj.Sku_Type__c = CPQ_BillingScheduleCreatorUtility.PRODUCT_SKU_TYPE_LICENSE;
        insert prod2Obj;

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today() + 1;
        quoteObj.SBQQ__EndDate__c = Date.today().addYears(1);
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = 'Monthly';
        quoteObj.SBQQ__Opportunity2__c  = oppObj.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
        quoteLineItemObj.CPQ_Last_Quote_Invoiced_License__c = 1000000;
        insert quoteLineItemObj;

        System.Test.startTest();

        Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppObj.Id, false);
        orderObj.Is_Primary__c = true;
        orderObj.SBQQ__Quote__c = quoteObj.Id;
        orderObj.SBQQ__BillingFrequency__c  = 'Monthly';
        orderObj.First_Invoice_Date__c = System.Today();
        orderObj.First_Period_Start_Date__c = System.Today();
        orderObj.CPQ_First_Period_Prorated_Amount__c = 5000;
        insert orderObj;


         quoteObj.SBQQ__Type__c = CPQ_BillingScheduleCreatorUtility.SBQQ_TYPE_RENEWAL;
         update quoteObj;

         CPQ_Order_BillingSchedule_Helper.run = true;
         update orderObj;

         System.Test.stopTest();
         List<OrderItem> lstOrderItem = [SELECT Id
                                     , OrderId
                                     , Product2Id
                                 FROM OrderItem
                                WHERE OrderId =: orderObj.Id
                                 ];
        system.debug('...lstOrderItem: '+lstOrderItem);

        List<CPQ_Billing_Schedule__c> lstBillingSchedule = [
        SELECT Id
            , Name
            , Order__c
            , startdate__c
            , Order_Product__c
            FROM CPQ_Billing_Schedule__c
            WHERE Order_Product__c =: lstOrderItem[0].Id
        ];
        System.assertEquals(1, lstOrderItem.size());
        System.assertEquals(13, lstBillingSchedule.size());
    }

    @isTest static void otherCreateOrderItemBillingSchedule() {

        //Account obj = [Select Id,Name From Account Where Name = 'Test Account' Limit 1];
        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, false);
        oppObj.Original_Opportunity_New__c = opportunityId;
        insert oppObj;

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id,oppObj.Id,true);

        oppObj.SBQQ__RenewedContract__c = contractObj.Id;
        update oppObj;
        //Opportunity oppWithContract1 = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);

        SBQQ__Quote__c quoteObj1 = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);

        // Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        // oppWithContract.Service_Contract__c = serviceContractId;
        oppObj.SBQQ__PrimaryQuote__c = quoteObj1.Id;
        oppObj.SBQQ__Renewal__c = true;
        update oppObj;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(true);

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppObj.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today() + 1;
        quoteObj.SBQQ__EndDate__c = Date.today().addYears(1);
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = 'Monthly';
        quoteObj.SBQQ__Opportunity2__c  = oppObj.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
        quoteLineItemObj.CPQ_Last_Quote_Invoiced_License__c = 1000000;
        insert quoteLineItemObj;

        System.Test.startTest();

        Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppObj.Id, false);
        orderObj.Is_Primary__c = true;
        orderObj.SBQQ__Quote__c = quoteObj.Id;
        orderObj.SBQQ__BillingFrequency__c  = 'Monthly';
        orderObj.First_Invoice_Date__c = System.Today();
        orderObj.First_Period_Start_Date__c = System.Today();
        insert orderObj;

         CPQ_Order_BillingSchedule_Helper.run = true;
         update orderObj;

         System.Test.stopTest();
         List<OrderItem> lstOrderItem = [SELECT Id
                                     , OrderId
                                     , Product2Id
                                 FROM OrderItem
                                WHERE OrderId =: orderObj.Id
                                 ];
        system.debug('...lstOrderItem: '+lstOrderItem);

        // List<CPQ_Billing_Schedule__c> lstBillingSchedule = [
        // SELECT Id
        //     , Name
        //     , Order__c
        //     , startdate__c
        //     , Order_Product__c
        //     FROM CPQ_Billing_Schedule__c
        //     WHERE Order_Product__c =: lstOrderItem[0].Id
        // ];
        System.assertEquals(1, lstOrderItem.size());
        //System.assertEquals(13, lstBillingSchedule.size());
    }


}