@isTest
public class CPQ_In_Scope_DWP_Calc_HelperTest {

    public static final String NET15 = 'Net 15';
    public static final String MONTHLY = 'Monthly';
    public static final String SEMIANNUAL = 'Semiannual';

    public static testMethod void opportunityInsertTest() {
        Account account = CPQ_TestDataUtility.accountTestData(true);

        Opportunity originalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, null, null, 1, false);
        // SBQQ__Quote__c originalQuote = createQuote(originalOppty.Id, false);
        // originalQuote.SBQQ__Primary__c = true;
        // update originalQuote;

        Contract originalContract = CPQ_Quote_Utilities_Test.createContract(account.Id, originalOppty.Id);
        Opportunity renewalOppty1 = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 4, true);

        List<CPQ_In_Scope_DWP__c> inScopeList = [
            SELECT Id
                , Premium_Amount__c
             FROM CPQ_In_Scope_DWP__c
            WHERE Opportunity__c = :renewalOppty1.Id
        ];

        System.assert( inScopeList.size() == 0 );
    }

    public static testMethod void opportunityUpdateTest() {
        Account account = CPQ_TestDataUtility.accountTestData(true);

        Opportunity originalOppty = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, null, null, 1, false);


        Contract originalContract = CPQ_Quote_Utilities_Test.createContract(account.Id, originalOppty.Id);
        Opportunity renewalOppty1 = CPQ_Quote_Utilities_Test.createOpportunity(account.Id, originalOppty.Id, originalContract.Id, 4, true);

        Product2 prod2Obj1 = CPQ_TestDataUtility.productTestData(false);
        prod2Obj1.Product_line_Name__c ='Core processing';
        insert prod2Obj1;

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(false);
        prod2Obj.Product__c = prod2Obj1.Id;
        insert prod2Obj;

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);
        Id pricebookId = Test.getStandardPricebookId();

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(renewalOppty1.Id, false);
        quoteObj.SBQQ__StartDate__c = Date.today();
        quoteObj.SBQQ__EndDate__c = Date.today();
        quoteObj.SBQQ__PaymentTerms__c = NET15;
        quoteObj.SBQQ__SubscriptionTerm__c = 6;
        quoteObj.SBQQ__BillingFrequency__c  = SEMIANNUAL;
        quoteObj.SBQQ__Opportunity2__c  = renewalOppty1.Id;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        insert quoteObj;

        SBQQ__QuoteLine__c  quoteLineItemObj = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);
        SBQQ__QuoteLine__c  quoteLineItemObj2 = CPQ_TestDataUtility.quoteLineItemTestData(prod2Obj.Id, quoteObj.Id, false);

        List<SBQQ__QuoteLine__c> lstQuoteLineItemToInsert = new List<SBQQ__QuoteLine__c>();
        lstQuoteLineItemToInsert.add(quoteLineItemObj);
        lstQuoteLineItemToInsert.add(quoteLineItemObj2);
        insert lstQuoteLineItemToInsert;

        originalOppty.CPQ_Renewal_In_Scope_DWP__c = 1;
        originalOppty.Premium_In_Scope__c = 7000000;
        update originalOppty;

        CPQ_In_Scope_DWP__c inScopeObj = new CPQ_In_Scope_DWP__c(
            Premium_Amount__c = '100',
            Opportunity__c = renewalOppty1.Id
        );
        insert inScopeObj;


        Test.startTest();

            CPQ_In_Scope_DWP_Calc_Helper.run = true;

            renewalOppty1.CPQ_Create_Service_Contract__c = true;
            renewalOppty1.SBQQ__Renewal__c = true;
            renewalOppty1.Premium_In_Scope__c = 6000000;
            update renewalOppty1;
        Test.stopTest();

        List<CPQ_In_Scope_DWP__c> inScopeList = [
            SELECT Id
                , Premium_Amount__c
             FROM CPQ_In_Scope_DWP__c
            WHERE Opportunity__c = :renewalOppty1.Id
        ];

        System.assert( inScopeList.size() > 0 );
    }
}