/**
* ==================================================================================
*    Version        Date                          Comment
* ==================================================================================
*    Initial                          Test class for class CPQ_GenerateOrderFile
*                                       
*                                       
*/
@isTest
private class CPQ_GenerateOrderFileTest {

    
    /**
     * Method to Create Contract record 
     */
    public static Contract contractTestData(Id accId, Id oppId) {

        Contract contObj = new Contract();
        contObj.AccountId = accId;
        contObj.Status = 'Draft';
        contObj.CurrencyIsoCode = 'USD';
        contObj.StartDate = System.Today();
        contObj.SBQQ__Opportunity__c = oppId;
        contObj.Renewal_Status__c = 'Not Started ';
        // contObj.Invoice_Date__c = System.Today();
        insert contObj;
        return contObj;
    }

    /**
     * Method to Create Opportunity record 
     */
    public static Opportunity createOppTestData(Id accId) {

        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'TestOpportunity';
        objOpportunity.AccountId = accId;
        objOpportunity.StageName = 'Working';
        objOpportunity.CloseDate = System.Date.Today().addDays(15);
        objOpportunity.Opportunity_Type__c = 'Renewal Type';
        objOpportunity.CurrencyIsoCode = 'USD';
        insert objOpportunity;
        return objOpportunity;
    }

    /**
     * Method to Create CPQ_Billing_Schedule__c record 
     */
    public static CPQ_Billing_Schedule__c createBillingSchedule(Order orderObj, OrderItem orderItemObj) {

        CPQ_Billing_Schedule__c billingScheduleObj = new CPQ_Billing_Schedule__c(
            transactiontype__c = 'Automated Sales Order 33',
            exchratetype__c = 'Intacct Daily Rate',
            ch_Warranty_Period__c = '365 days from Notification Date',
            quantity__c = 1,
            unit__c = 'Each',
            Order__c = orderObj.Id,
            Order_Product__c = orderItemObj.Id,
            departmentid__c = '310',
            ch_Baseline_Measure__c = 'GWP = Gross Written Premiums',
            ch_AUTO_RENEWAL__c = 'Y',
            ch_Term_Years__c = 1,
            ch_Escalation_on_Fees__c = 'Y',
            ch_Escalation_Description__c = 'Lesser of CPI or 3%',
            ch_Growth_Rate_Clause__c = 'Y',
            ch_Reduction_Rate_Clause__c = 'N',
            ch_Notification_Required__c = 'N',
            ch_Perpetual_Buyout_Option__c = 'N',
            ch_Growth_Rate_Buffer__c = '>0%'
        );
        insert billingScheduleObj;
        return billingScheduleObj;
    }

    /**
     * Method to Create Product2 record 
     */
    public static Product2 createProduct() {
        Product2 prod = new Product2(Name = 'Laptop X200',
            Family = 'Hardware');
        insert prod;
        return prod;
    }

    /**
     * Method to Create PriceBookEntry record 
     */
    public static PricebookEntry createPriceBookEntry(Product2 productObj) {

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productObj.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        return standardPrice;
    }

    /**
     * Method to Create CPQ_Wire_Message__c record 
     */
    public static CPQ_Wire_Message__c createWiremessage() {
        CPQ_Wire_Message__c wiremessage = new CPQ_Wire_Message__c(
            Message__c = 'Incoming wire payment instruction: Currency USD To: SIL VLY BK SJ 3003 Tasman Drive, Santa Clara, CA Routing&Transit: 121140399 Account #: 3300604026',
            BILL_TO_Country__c = 'USD',
            Local_Currency__c = 'USD',
            CurrencyIsoCode = 'USD'
        );
        insert wiremessage;
        return wiremessage;
    }

    /**
     * Method to Create Order record 
     */
    public static Order createOrder(Account objAcc, Contract contObj, Opportunity objOpportunity, CPQ_Wire_Message__c wiremessage) {

        Id pricebookId = Test.getStandardPricebookId();

        Order orderObj = new Order();
        orderObj.AccountID = objAcc.ID;
        orderObj.EffectiveDate = System.TODAY();
        orderObj.CurrencyIsoCode = 'USD';
        orderObj.ContractID = contObj.ID;
        orderObj.Status = 'Draft';
        orderObj.OpportunityID = objOpportunity.ID;
        orderObj.Is_Primary__c = true;
        orderObj.Wire_Message__c = wiremessage.ID;
        orderObj.Pricebook2ID = pricebookId;
        insert orderObj;
        return orderObj;
    }

    /**
     * Method to Create OrderItem record 
     */
    public static OrderItem createOrderItem(Order orderObj, PricebookEntry standardPrice) {

        OrderItem orderItemObj = new Orderitem(
            OrderId = orderObj.Id,
            UnitPrice = 20000,
            Quantity = 1,
            price__c = 2204328,
            PriceBookEntryId = standardPrice.Id
        );
        insert orderItemObj;
        return orderItemObj;
    }

    /**
     * Method to test AttachmentRecord record 
     */
    @isTest static void test_AttachmentRecord() {

        Account objAcc = new Account();
        objAcc.Name = 'TestAcc';
        objAcc.Participant_id__c = '1234';
        insert objAcc;


        Opportunity objOpportunity = createOppTestData(objAcc.Id);

        Contract contObj = contractTestData(objAcc.Id, objOpportunity.Id);

        Product2 productObj = createProduct();

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPrice = createPriceBookEntry(productObj);

        CPQ_Wire_Message__c wiremessage = createWiremessage();

        Order orderObj = createOrder(objAcc, contObj, objOpportunity, wiremessage);

        OrderItem orderItemObj = createOrderItem(orderObj, standardPrice);

        CPQ_Billing_Schedule__c billingScheduleObj = createBillingSchedule(orderObj, orderItemObj);

        CPQ_GenerateOrderFile.createOrderAttachment(orderObj.Id);
        List < Attachment > attchmentList = [Select Id, Body, Name, ParentId From Attachment];
        System.assertEquals(attchmentList.size(), 1);
        System.assertEquals(attchmentList[0].ParentId, orderObj.Id);

    }
}