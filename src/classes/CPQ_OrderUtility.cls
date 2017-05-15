global class CPQ_OrderUtility {

    public static final String STR_ORDER_GENERATED = Label.Order_Generated; //Order has successfully generated;
    public static final String STR_ORDER_GENERATION_FAILED = Label.Order_Generated_Failure; //Order generation failed due to error: ;
    public static final String STR_EURO_COUNTRIES = Label.Euro_Countries;//list of euro countries
    public static final String STR_DRAFT = 'Draft';//Label.Draft; //

    public Static Id stdPricebookId;

    static {
        stdPricebookId = Test.isRunningTest()
                       ? Test.getStandardPricebookId()
                       : [SELECT Id
                            FROM Pricebook2
                           WHERE IsStandard = true
                             AND IsActive = true].Id;
    }

    /**
     * Method to Create Sales Order from Button on opportunity
     **/
    WebService static String createOrder(Id oppId, Id primaryQuoteId, Id accId, String basecurr) {

        Opportunity objOpportunity;

        List<Opportunity> lstFetchedOpportunities = [SELECT Id
                                                          , SBQQ__PrimaryQuote__r.SBQQ__BillingFrequency__c
                                                          , SBQQ__PrimaryQuote__r.SBQQ__StartDate__c
                                                          , SBQQ__PrimaryQuote__r.CPQ_Royalties__c
                                                          , Account.Participant_id__c
                                                          , Account.Payment_Term__c
                                                          , SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c
                                                          , bill_to__r.Participant_Account__r.pw_cc__BillingCountryLookup__r.pw_cc__IsoCode_2__c
                                                          , Opportunity_Type__c
                                                          , (SELECT Id
                                                                  , Is_Primary__c
                                                               FROM Orders
                                                              WHERE Is_Primary__c = : true)
                                                       FROM Opportunity
                                                      WHERE Id = :oppId];

        if( !lstFetchedOpportunities.isEmpty() ) {
            objOpportunity = lstFetchedOpportunities[0];
        }

        String strResult = 'Following fields are missing: [{0}]';
        List<String> lstMissingFields = new List<String>();

        if(String.isBlank(objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__BillingFrequency__c)) {
            lstMissingFields.add('Primary Quote > Billing Frequency');
        }

        if(NULL == objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c) {
            lstMissingFields.add('Primary Quote > Start Date');
        }

        if(String.isBlank(objOpportunity.Account.Participant_id__c)) {
            lstMissingFields.add('Account > Participant Id');
        }

        if(String.isBlank(objOpportunity.Account.Payment_Term__c)) {
            lstMissingFields.add('Account > Payment Term');
        }

        if( NULL == objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c ) {
            lstMissingFields.add('Primary Quote > Subscription Term');
        }

        if(String.isBlank(objOpportunity.bill_to__r.Participant_Account__r.pw_cc__BillingCountryLookup__r.pw_cc__IsoCode_2__c)) {
            lstMissingFields.add('Bill To > Billing Country ISO Code');
        }

        if(String.isBlank(objOpportunity.Opportunity_Type__c)) {
            lstMissingFields.add('Opportunity Type');
        }

        if( !lstMissingFields.isEmpty() ) {
            strResult = String.format(strResult, new List<String>{String.join(lstMissingFields, ', ')});
            return strResult;
        } else {
            strResult = '';
        }

        Order objOrder = new Order();
        objOrder.AccountId = accId;
        objOrder.SBQQ__Quote__c = primaryQuoteId;
        objOrder.Is_Primary__c = true;
        objOrder.Status = STR_DRAFT;
        objOrder.EffectiveDate = System.Date.Today();
        objOrder.OpportunityId = oppId;
        objOrder.Pricebook2Id = stdPricebookId;
        objOrder.Contract_Sign_Date__c = Date.today();

        if( objOpportunity != NULL ) {
            objOrder.SBQQ__BillingFrequency__c = objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__BillingFrequency__c;
            objOrder.Opportunity_Id__c = oppId;
            objOrder.SFDC_Bill_To_Customer_ID__c = objOpportunity.Account.Participant_id__c;
            objOrder.termname__c = objOpportunity.Account.Payment_Term__c;
            objOrder.Sales_Order_Date__c = objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c;
            objOrder.Subscription_Term_Duration__c = objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c;
            objOrder.CPQ_Royalties__c = objOpportunity.SBQQ__PrimaryQuote__r.CPQ_Royalties__c;
            objOrder.TaxCode__c = System.Label.CPQ_OpportunityTypeNetNew.equalsIgnoreCase(objOpportunity.Opportunity_Type__c)
                                ? System.Label.CPQ_MandatorySupport
                                : System.Label.CPQ_OptionalSupport;

            System.debug('objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c-----'+objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c);
            if( NULL != objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c
            &&  NULL != objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c ) {
                objOrder.Sales_Order_End_Date__c =
                    objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c.addMonths(Integer.valueOf(objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__SubscriptionTerm__c));
            }

        }

        //populate Lookup(Wire Message)
        if(objOpportunity.Account.Participant_id__c != NULL && (objOpportunity.Account.Participant_id__c).equalsIgnoreCase('1378')) {
            objOrder.Wire_Message__c = getWireMessage(basecurr, objOpportunity.bill_to__r.Participant_Account__r.pw_cc__BillingCountryLookup__r.pw_cc__IsoCode_2__c, true);
        } else {
            objOrder.Wire_Message__c = getWireMessage(basecurr, objOpportunity.bill_to__r.Participant_Account__r.pw_cc__BillingCountryLookup__r.pw_cc__IsoCode_2__c, false);
        }

        // Uncheck Primary checkbox for existing orders
        List<Order> listOrdersToBeUpdated = new List<Order>();
        for(Order objOrderExistingOrder: objOpportunity.Orders) {
          Order objOrderToBeUpdated = new Order();
          objOrderToBeUpdated = objOrderExistingOrder;
          objOrderToBeUpdated.Is_Primary__c =  false;
          listOrdersToBeUpdated.add(objOrderToBeUpdated);
        } // end of for

        listOrdersToBeUpdated.add(objOrder);

        Database.UpsertResult[] result = DataBase.upsert(listOrdersToBeUpdated, false);

        if(!result.isEmpty() && result[listOrdersToBeUpdated.size() - 1].isSuccess()) {
            strResult = STR_ORDER_GENERATED;
        } else if(!result.isEmpty()) {
            strResult = STR_ORDER_GENERATION_FAILED +(result[listOrdersToBeUpdated.size() - 1].getErrors())[0].getMessage();
        }
        return strResult;
    }

    public static Id getWireMessage(String basecurr, String l_classid, Boolean isCompany12) {

        String baseQuery             = 'SELECT Id'
                                     + '  FROM CPQ_Wire_Message__c ';

        String queryIsCompany12      = ' WHERE Is_Company_12__c = true';
        String queryWithStandardCase = ' WHERE Local_Currency__c = : basecurr '
                                     + '   AND BILL_TO_Country__c = : l_classid';
        String queryWithoutCountryUS = ' WHERE Local_Currency__c = : basecurr '
                                     + '   AND BILL_TO_Country__c = \'!!US\'';

        List<sObject> lstWireMsg;

        try {

            if(true == isCompany12) {
                // query on wmsg where is_company__12 == true
                lstWireMsg = Database.query(baseQuery + queryIsCompany12);
            } else if(String.isNotBlank(basecurr) && String.isNotBlank(l_classid)) {

                if(basecurr.equalsIgnoreCase('USD') && !l_classid.equalsIgnoreCase('US')) {

                    lstWireMsg = Database.query(baseQuery + queryWithoutCountryUS);

                } else if((basecurr.equalsIgnoreCase('EUR') && !l_classid.equalsIgnoreCase('GB') && !l_classid.equalsIgnoreCase('CH')) ||
                          !basecurr.equalsIgnoreCase('EUR')) {

                    lstWireMsg = Database.query(baseQuery + queryWithStandardCase);
                }
            }
        } catch(QueryException e) {
            return NULL;
        }

        if(lstWireMsg != NULL && !lstWireMsg.isEmpty()) {
            return (lstWireMsg.get(0).Id);
        } else {
            return NULL;
        }
    }
}