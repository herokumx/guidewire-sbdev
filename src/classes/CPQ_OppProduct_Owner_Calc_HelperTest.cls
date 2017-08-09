@isTest
public with sharing class CPQ_OppProduct_Owner_Calc_HelperTest {

    public static final String NET15 = 'Net 15';
    public static final String MONTHLY = 'Monthly';
    public static final String SEMIANNUAL = 'Semiannual';

    public static testMethod void beforeInsertProductLineName1Test() {
        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        oppWithContract.Service_Contract__c = serviceContrObj.Id;
        insert oppWithContract;

        Product2 prod2Obj1 = CPQ_TestDataUtility.productTestData(false);
        prod2Obj1.Product_line_Name__c ='Core processing';
        insert prod2Obj1;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
        prod2Obj.Product__c = prod2Obj1.Id;
        insert prod2Obj;

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today();
        quoteObj.SBQQ__EndDate__c = Date.today();
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = SEMIANNUAL;
        quoteObj.SBQQ__Opportunity2__c  = oppWithContract.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        System.Test.startTest();

            SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
            SBQQ__QuoteLine__c  quoteLineItemObj2 = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);

            List<SBQQ__QuoteLine__c> lstQuoteLineItemToInsert = new List<SBQQ__QuoteLine__c>();
            lstQuoteLineItemToInsert.add(quoteLineItemObj);
            lstQuoteLineItemToInsert.add(quoteLineItemObj2);
            insert lstQuoteLineItemToInsert;
        System.Test.stopTest();

        List<OpportunityLineItem> oliList = [
            SELECT ID
                 , CPQ_Opportunity_Product_Owner__c
                 , Opportunity.OwnerId
             FROM OpportunityLineItem
            WHERE OpportunityID = :oppWithContract.Id
         ];

         if( oliList.size() > 0 ) {
             System.debug(oliList[0].Opportunity.OwnerId + ' : ' + oliList[0].CPQ_Opportunity_Product_Owner__c);
             System.assert(oliList[0].Opportunity.OwnerId == oliList[0].CPQ_Opportunity_Product_Owner__c);
         }
    }

    public static testMethod void beforeInsertProductLineName2Test() {
        Account accObj = CPQ_TestDataUtility.accountTestData(true);
        accObj = [
            SELECT Id
                , OwnerId
            FROM Account
           WHERE Id = : accObj.Id
        ];
        accObj.MPL_Sales_Rep__c = accObj.OwnerId;
        update accObj;

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        oppWithContract.Service_Contract__c = serviceContrObj.Id;
        insert oppWithContract;

        Product2 prod2Obj1 = CPQ_TestDataUtility.productTestData(false);
        prod2Obj1.Product_line_Name__c ='Digital Engagement';
        insert prod2Obj1;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
        prod2Obj.Product__c = prod2Obj1.Id;
        insert prod2Obj;

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today();
        quoteObj.SBQQ__EndDate__c = Date.today();
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = SEMIANNUAL;
        quoteObj.SBQQ__Opportunity2__c  = oppWithContract.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        System.Test.startTest();

            SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
            SBQQ__QuoteLine__c  quoteLineItemObj2 = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);

            List<SBQQ__QuoteLine__c> lstQuoteLineItemToInsert = new List<SBQQ__QuoteLine__c>();
            lstQuoteLineItemToInsert.add(quoteLineItemObj);
            lstQuoteLineItemToInsert.add(quoteLineItemObj2);
            insert lstQuoteLineItemToInsert;
        System.Test.stopTest();

        List<OpportunityLineItem> oliList = [
            SELECT ID
                 , CPQ_Opportunity_Product_Owner__c
                 , Opportunity.OwnerId
                 , Opportunity.Account.MPL_Sales_Rep__c
             FROM OpportunityLineItem
            WHERE OpportunityID = :oppWithContract.Id
         ];

         if( oliList.size() > 0 && oliList[0].Opportunity.Account.MPL_Sales_Rep__c != null) {
             System.assert( oliList[0].Opportunity.Account.MPL_Sales_Rep__c == oliList[0].CPQ_Opportunity_Product_Owner__c);
         }
    }

}