public with sharing class CPQ_TestDataUtility {

    /**
    * Test method to create Account test data
    */
    public static Account accountTestData(Boolean isInsert) {
        pw_cc__CountryObject__c countryCode = new pw_cc__CountryObject__c(
            Name = 'USA',
            pw_cc__IsoCode_2__c = 'US',
            pw_cc__IsoCode_3__c = 'USA'
        );
        insert countryCode;
        Account accObj = new Account();
        accObj.Name = 'Test Account';
        accObj.pw_cc__BillingCountryLookup__c = countryCode.Id;
        if (isInsert == true) {
            insert accObj;
        }
        return accObj;
    }

    /**
    * Test method to create Opportunity test data
    */
    public static Opportunity opportunityTestData(Id accountId, Id contractId, Boolean isInsert) {
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test Opportunity';
        oppObj.StageName = 'Qualified';
        oppObj.CloseDate = Date.Today();
        oppObj.AccountId = accountId;
        oppObj.Region__c = 'AMER';
        oppObj.Opportunity_Type__c = 'Net New';
        oppObj.CurrencyIsoCode = 'USD';
        oppObj.SBQQ__RenewedContract__c = contractId;
        oppObj.SBQQ__Renewal__c = true;
        if (isInsert == true) {
            insert oppObj;
        }
        return oppObj;
    }

    /**
    * Test method to create Opportunity for Contract test data
    */
    public static Opportunity opportunityForContTestData(Id accountId, Boolean isInsert) {
        Opportunity oppObj = new Opportunity();
        oppObj.Name = 'Test Opportunity2';
        oppObj.StageName = 'Qualified';
        oppObj.CloseDate = Date.Today();
        oppObj.AccountId = accountId;
        oppObj.Region__c = 'AMER';
        oppObj.Opportunity_Type__c = 'Net New';
        oppObj.CurrencyIsoCode = 'USD';
        if (isInsert == true) {
            insert oppObj;
        }
        return oppObj;
    }

    /**
    * Test method to create Quote test data
    */
    public static SBQQ__Quote__c quoteTestData(Id opportunityId, Boolean isInsert) {
        SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
        quoteObj.SBQQ__Opportunity2__c = opportunityId;
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.CPQ_Prorated_Start_Date__c = System.Today();
        if (isInsert == true) {
            insert quoteObj;
        }
        return quoteObj;
    }

    /**
    * Test method to create Contract test data
    */
    public static Contract contractTesData(Id accountId, Id opportunityId, Boolean isInsert) {
        Contract contObj = new Contract();
        contObj.AccountId = accountId;
        contObj.Status = 'Draft';
        contObj.CurrencyIsoCode = 'USD';
        contObj.SBQQ__Opportunity__c = opportunityId;
        if (isInsert == true) {
            insert contObj;
        }
        return contObj;
    }

    /**
    * Test method to create Orders test data
    */
    public static List<Order> orderTestData(Id accountId,Id opportunityId, Boolean isInsert) {
        Id pricebookId = Test.getStandardPricebookId();
        List<Order> orderList = new List<Order>();

        for(Integer i = 0 ;i < 4 ;i++) {
            Order orderObj = new Order();
            orderObj.AccountId = accountId;
            orderObj.OpportunityId = opportunityId;
            orderObj.Status = 'Draft';
            orderObj.EffectiveDate = Date.Today();
            orderObj.CurrencyIsoCode = 'USD';
            orderObj.Pricebook2Id = pricebookId;
            orderList.add(orderObj);
        }
        if (isInsert == true) {
            insert orderList;
        }
        return orderList;
    }

    /**
    * Test method to create Order test data
    */
    public static Order singleOrderUpdate(Id accountId, Id opportunityId, Boolean isInsert) {
        Id pricebookId = Test.getStandardPricebookId();
        Order orderObj = new Order();
        orderObj.AccountId = accountId;
        orderObj.OpportunityId = opportunityId;
        orderObj.Status = 'Draft';
        orderObj.EffectiveDate = Date.Today();
        orderObj.CurrencyIsoCode = 'USD';
        orderObj.Pricebook2Id = pricebookId;
        if (isInsert == true) {
            insert orderObj;
        }
        return orderObj;
    }

    /**
    * Test method to create Product2 test data
    */
    public static Product2 productTestData(Boolean isInsert) {
        Product2 prodObj = new Product2();
        prodObj.Name = 'Test Prod';
        prodObj.ProductCode = 'code1';
        prodObj.IsActive = true;
        if (isInsert == true) {
            insert prodObj;
        }
        return prodObj;
    }

    /**
    * Test method to create PricebookEntry test data
    */
    public static PricebookEntry pbEntryTestData(Id product2Id, Boolean isInsert) {
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbEntryObj = new PricebookEntry();
        pbEntryObj.Pricebook2Id = pricebookId;
        pbEntryObj.Product2Id = product2Id;
        pbEntryObj.UnitPrice = 100.00;
        pbEntryObj.IsActive = true;
        if (isInsert == true) {
            insert pbEntryObj;
        }
        return pbEntryObj;
    }

    /**
    * Test method to create OrderItem test data
    */
    public static OrderItem orderItemTestData(Id orderId, Id pbEntryId, Boolean isInsert) {
        OrderItem orderItemObj = new OrderItem();
        orderItemObj.UnitPrice = 100.00;
        orderItemObj.Quantity = 1;
        orderItemObj.OrderId = orderId;
        orderItemObj.PricebookEntryId = pbEntryId;
        if (isInsert == true) {
            insert orderItemObj;
        }
        return orderItemObj;
    }

    public static ServiceContract serviceContractTestData(Id accountId, Boolean isInsert) {
        ServiceContract serviceContrObj = new ServiceContract();
        serviceContrObj.Name = 'Test Service Contract';
        serviceContrObj.AccountId = accountId;
        serviceContrObj.StartDate = Date.today();
        if (isInsert == true) {
            insert serviceContrObj;
        }
        return serviceContrObj;
    }

    public static SBQQ__QuoteLine__c quoteLineItemTestData(Id product2Id, Id quoteId, Boolean isInsert) {
        SBQQ__QuoteLine__c quoteLineItemObj = new SBQQ__QuoteLine__c();
        quoteLineItemObj.SBQQ__Quote__c = quoteId;
        quoteLineItemObj.SBQQ__Product__c = product2Id;
        if (isInsert == true) {
            insert quoteLineItemObj;
        }
        return quoteLineItemObj;
    }

    public static OpportunityLineItem opppLineItemTestData(PricebookEntry pbEntryObj, Id oppId, Boolean isInsert) {
        OpportunityLineItem oppLineItemObj = new OpportunityLineItem();
        oppLineItemObj.OpportunityId = oppId;
        oppLineItemObj.PricebookEntryId  = pbEntryObj.ID;
        oppLineItemObj.Quantity= 2;
        oppLineItemObj.TotalPrice = pbEntryObj.UnitPrice * oppLineItemObj.Quantity;
        if (isInsert == true) {
            insert oppLineItemObj;
        }
        return oppLineItemObj;
    }

}