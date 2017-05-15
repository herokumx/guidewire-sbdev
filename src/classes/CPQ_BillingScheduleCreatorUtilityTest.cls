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
    
    /**
	 * Test method to check OrderItem and SBQQ__QuoteLine__c created accordingly
	 **/
    @isTest static void testMethodCreateOrderItemBillingSchedule() {

        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

		Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        oppWithContract.Service_Contract__c = serviceContrObj.Id;
        insert oppWithContract;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(true);
        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today();
        quoteObj.SBQQ__EndDate__c = Date.today();
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 24;
        quoteObj.SBQQ__BillingFrequency__c	= MONTHLY;
        insert quoteObj;

        oppWithContract.SBQQ__PrimaryQuote__c = quoteObj.Id;
		update oppWithContract;

        SBQQ__QuoteLine__c  quoteLineItemObj= CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, true);
        Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppWithContract.Id, false);
        orderObj.Is_Primary__c = true;
        orderObj.SBQQ__Quote__c = quoteObj.Id;
        insert orderObj;

        System.Test.startTest();
            update orderObj;
        System.Test.stopTest();

        List<Order> lstOrder = [SELECT Id
                                     , Name
                                     , OpportunityId
                                     , Is_Primary__c
                                     , SBQQ__Quote__c
                                     FROM Order];
        List<OrderItem> lstOrderItem = [SELECT Id
                                             , OrderId
                                             , Product2Id
                                             FROM OrderItem
                                             WHERE OrderId =: lstOrder[0].Id];

        List<CPQ_Billing_Schedule__c> lstBillingSchedule = [SELECT Id
                                                                 , Name
                                                                 , Order__c
                                                                 , startdate__c
                                                                 FROM CPQ_Billing_Schedule__c
                                                                 WHERE Order__c =: lstOrder[0].Id];

        List<SBQQ__QuoteLine__c> lstQuoteLineItem = [SELECT Id
                                                          , SBQQ__Quote__c
                                                          , SBQQ__Product__c
                                                          FROM SBQQ__QuoteLine__c
                                                          WHERE SBQQ__Quote__c =: quoteObj.Id];

        System.assertEquals(1, lstOrderItem.size());
        System.assertEquals(24, lstBillingSchedule.size());
        System.assertEquals(lstQuoteLineItem.size(), lstOrderItem.size());
        System.assertEquals(lstQuoteLineItem[0].SBQQ__Product__c, lstOrderItem[0].Product2Id);
    }

    /**
	 * Test method to check with multiple Quote Line Item
	 **/
    @isTest static void testMethodCreateOrderMultipleQuoteLineItem() {

        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

		Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        oppWithContract.Service_Contract__c = serviceContrObj.Id;
        insert oppWithContract;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(true);
        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today();
        quoteObj.SBQQ__EndDate__c = Date.today();
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c	= SEMIANNUAL;
        quoteObj.SBQQ__Opportunity2__c	= oppWithContract.Id;
        quoteObj.SBQQ__Primary__c = true;
        insert quoteObj;

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
        SBQQ__QuoteLine__c  quoteLineItemObj2 = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);

        List<SBQQ__QuoteLine__c> lstQuoteLineItemToInsert = new List<SBQQ__QuoteLine__c>();
        lstQuoteLineItemToInsert.add(quoteLineItemObj);
        lstQuoteLineItemToInsert.add(quoteLineItemObj2);
        insert lstQuoteLineItemToInsert;

        Order orderObj = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppWithContract.Id, false);
        orderObj.Is_Primary__c = true;
        orderObj.SBQQ__Quote__c = quoteObj.Id;
        insert orderObj;

        System.Test.startTest();
            update orderObj;
        System.Test.stopTest();

        List<Order> lstOrder = [SELECT Id
                                     , Name
                                     , OpportunityId
                                     , Is_Primary__c
                                     , SBQQ__Quote__c
                                     FROM Order];
        List<OrderItem> lstOrderItem = [SELECT Id
                                             , OrderId
                                             , Product2Id
                                             FROM OrderItem
                                             WHERE OrderId =: lstOrder[0].Id];

        List<CPQ_Billing_Schedule__c> lstBillingSchedule = [SELECT Id
                                                                 , Name
                                                                 , Order__c
                                                                 , startdate__c
                                                                 , Order_Product__c
                                                                 FROM CPQ_Billing_Schedule__c
                                                                 WHERE Order_Product__c =: lstOrderItem[0].Id];

        List<SBQQ__QuoteLine__c> lstQuoteLineItem = [SELECT Id
                                                          , SBQQ__Quote__c
                                                          , SBQQ__Product__c
                                                          FROM SBQQ__QuoteLine__c
                                                          WHERE SBQQ__Quote__c =: quoteObj.Id];

        System.assertEquals(2, lstOrderItem.size());
        System.assertEquals(1, lstBillingSchedule.size());
        System.assertEquals(lstQuoteLineItem.size(), lstOrderItem.size());
        System.assertEquals(lstQuoteLineItem[0].SBQQ__Product__c, lstOrderItem[0].Product2Id);
    }

}