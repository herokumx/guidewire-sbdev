public with sharing class CPQ_BillingScheduleCreatorUtility {

  public static final String YEAR = ' Year ';
  public static final String STRING_1 = '1: ';
  public static final String TO = ' to ';

  public static final String SBQQ_TYPE_RENEWAL = 'Renewal';
  public static final String PRODUCT_SKU_TYPE_LICENSE = 'License';
  public static final String PRODUCT_SKU_TYPE_MAINTENANCE = 'Maintenance';

  public static final String REVRECTEMPLATE_UPFRONT = 'For Upfront Recognition';
  public static final String REVRECTEMPLATE_PRORATE = 'Exact Days Period Prorate Day';

  public static Boolean generateBillingSchedule = false;

  public static final Map<String, Integer> mapDuration_MonthCount = new Map<String, Integer> {
    'Monthly' => 1,
    'Quarterly' => 3,
    'Semiannual' => 6,
    'Annual' => 12
  };

  public static final Map<String, String> mapDuration_DurationName = new Map<String, String> {
    'Monthly' => 'Month',
    'Quarterly' => 'Quarter',
    'Semiannual' => '1/2 Year',
    'Annual' => 'Year'
  };

  public static final Map<String, Integer> mapPaymentTerm_DayCount = new Map<String, Integer> {
    'Net 15' => -15,
    'Net 30' => -30,
    'Net 45' => -45,
    'Net 60' => -60,
    'Net 90' => -90
  };

  // public CPQ_BillingScheduleCreatorUtility() {
  //     // @TODO: Nothing
  // }

  public static void createBillingSchedules(
    Map<Id, Order> pMapId_OldOrder, Map<Id, Order> pMapId_NewOrder, Boolean isGeneratingOrderItems) {

    OrderItem orderProductPlaceHolder;
    Integer monthCount;
    Date startDatePlaceHolder;
    Attachment attachmentPlaceholder;
    String startDateString, endDateString;

    System.debug('------ pMapId_NewOrder ------ : ' + pMapId_NewOrder);
    System.debug('------ isGeneratingOrderItems ------ : ' + isGeneratingOrderItems);

    generateBillingSchedule = true;

    Set<Id> setQuoteIds = new Set<Id>();
    Set<Id> setFilteredOrderIds = new Set<Id>();
    Set<Id> setProductIds = new Set<Id>();
    Set<String> setCurrencyCodes = new Set<String>();

    List<SBQQ__QuoteLine__c> lstQuoteLines = new List<SBQQ__QuoteLine__c>();
    List<OrderItem> lstOrderProducts_ToInsert = new List<OrderItem>();
    List<Order> lstOrders = new List<Order>();
    List<OrderItem> lstOrderProducts_ToDelete = new List<OrderItem>();
    List<CPQ_Billing_Schedule__c> lstBillingSchedules_ToDelete = new List<CPQ_Billing_Schedule__c>();

    Map<Id, Id> mapQuoteLineId_PricebookEntryId = new Map<Id, Id>();
    Map<Id, List<OrderItem>> mapOrderId_OrderItems = new Map<Id, List<OrderItem>>();
    Map<Id, Order> mapOrderId_OrderRecord = new Map<Id, Order>();
    Map<Id, List<Decimal>> mapOrderLineId_PerYearPrices = new Map<Id, List<Decimal>>();
    Map<Id, String> mapOrderLineId_OptionalSkuId = new Map<Id, String>();
    Map<Id, String> mapOrderLineId_OptionalSkuDesc = new Map<Id, String>();
    Map<Id, List<CPQ_Billing_Schedule__c>> mapOrderId_BillingSchedules =
      new Map<Id, List<CPQ_Billing_Schedule__c>>();

    for(Id orderIdIterator : pMapId_NewOrder.keySet()) {

      if( NULL != pMapId_NewOrder.get(orderIdIterator).SBQQ__Quote__c
          &&  true == pMapId_NewOrder.get(orderIdIterator).Is_Primary__c ) {

        setFilteredOrderIds.add(orderIdIterator);
        setQuoteIds.add(pMapId_NewOrder.get(orderIdIterator).SBQQ__Quote__c);
      }
    }
    System.debug('------ setQuoteIds ------ : ' + setQuoteIds);

    if( setQuoteIds.isEmpty() || setFilteredOrderIds.isEmpty() ) {
      return;
    }

    Map<Id, Order> mapId_OrderWithOppData = new Map<Id, Order>([
                                                                 SELECT Id
                                                                 , Opportunity.Service_Contract__r.StartDate
                                                                 , SBQQ__Quote__r.SBQQ__Type__c
                                                                 , SBQQ__Quote__r.SBQQ__StartDate__c
                                                                 , SBQQ__Quote__r.SBQQ__EndDate__c
                                                                 , SBQQ__Quote__r.SBQQ__PaymentTerms__c
                                                                 , SBQQ__Quote__r.SBQQ__SubscriptionTerm__c
                                                                 , SBQQ__Quote__r.CPQ_Prorated_Start_Date__c
                                                                 // , SBQQ__Quote__r.CPQ_Term_End_Date__c
                                                                 , Optional_Support_Start_Date__c
                                                                 , CPQ_First_Period_Prorated_Amount__c
                                                                 , Contract_Sign_Date__c
                                                                 , Software_Delivery_Date__c
                                                                 , Out_Clause_date__c
                                                                 , Contract_Effective_Date__c
                                                                 , First_Period_Start_Date__c
                                                                 , First_Invoice_Date__c
                                                                 , termname__c
                                                                 , (SELECT Id
                                                                    FROM OrderItems)
                                                                 , (SELECT Id
                                                                    FROM Billing_Schedules__r)
                                                                 FROM Order
                                                                 WHERE Id IN:setFilteredOrderIds
                                                               ]);

    for(Id orderIdIterator : mapId_OrderWithOppData.keySet()) {

      if(NULL != mapId_OrderWithOppData.get(orderIdIterator).OrderItems
         && !mapId_OrderWithOppData.get(orderIdIterator).OrderItems.isEmpty()) {
        lstOrderProducts_ToDelete.addAll(mapId_OrderWithOppData.get(orderIdIterator).OrderItems);
      }

      if(NULL != mapId_OrderWithOppData.get(orderIdIterator).Billing_Schedules__r
         && !mapId_OrderWithOppData.get(orderIdIterator).Billing_Schedules__r.isEmpty()) {
        lstBillingSchedules_ToDelete.addAll(mapId_OrderWithOppData.get(orderIdIterator).Billing_Schedules__r);
      }
    }

    Set<String> setQuoteLineFields = Schema.SObjectType.SBQQ__QuoteLine__c.fields.getMap().keySet();

    String quoteQuery = 'SELECT Id, (SELECT ';

    quoteQuery += String.join(new List<String>(setQuoteLineFields), ', ');

    quoteQuery += ' , SBQQ__Product__r.SKU_Description__c, SBQQ__Product__r.SKU_ID__c, SBQQ__Product__r.RevRec_Template__c ';
    quoteQuery += ' FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE Id IN : setQuoteIds ';
    quoteQuery += ' AND SBQQ__Primary__c = true';

    Map<Id, SBQQ__Quote__c> mapId_ParentQuote =
      new Map<Id, SBQQ__Quote__c>( (List<SBQQ__Quote__c>)Database.query(quoteQuery));

    for(Id quoteIdIterator : mapId_ParentQuote.keySet()) {
      for(SBQQ__QuoteLine__c quoteLineIterator : mapId_ParentQuote.get(quoteIdIterator).SBQQ__LineItems__r) {

        lstQuoteLines.add(quoteLineIterator);
        setProductIds.add(quoteLineIterator.SBQQ__Product__c);
        setCurrencyCodes.add(quoteLineIterator.CurrencyIsoCode);
      }
    }

    List<PricebookEntry> lstPricebookEntries = [SELECT Id
                                                , Product2Id
                                                , CurrencyIsoCode
                                                , Product2.Sku_Type__c
                                                FROM PricebookEntry
                                                WHERE Product2Id IN : setProductIds
                                                AND CurrencyIsoCode IN : setCurrencyCodes];

    Map<Id, String> mapPbeId_ProductSkuType = new Map<Id, String>();

    for(SBQQ__QuoteLine__c quoteLineIterator : lstQuoteLines) {
      for(PricebookEntry pbeIterator : lstPricebookEntries) {

        if(quoteLineIterator.SBQQ__Product__c == pbeIterator.Product2Id
           && quoteLineIterator.CurrencyIsoCode == pbeIterator.CurrencyIsoCode) {

          mapQuoteLineId_PricebookEntryId.put(quoteLineIterator.Id, pbeIterator.Id);
          mapPbeId_ProductSkuType.put(pbeIterator.Id, pbeIterator.Product2.Sku_Type__c);
        }
      }
    }

    System.Savepoint stableState = Database.setSavepoint();

    if(true == isGeneratingOrderItems) {

      for(Id orderIdIterator : setFilteredOrderIds) {

        if( !pMapId_NewOrder.containsKey(orderIdIterator) ) {
          continue;
        }

        if(pMapId_NewOrder.get(orderIdIterator).SBQQ__Quote__c == NULL
           || !mapId_ParentQuote.containsKey(pMapId_NewOrder.get(orderIdIterator).SBQQ__Quote__c)) {
          continue;
        }

        for(SBQQ__QuoteLine__c quoteLineIterator :
            mapId_ParentQuote.get(pMapId_NewOrder.get(orderIdIterator).SBQQ__Quote__c).SBQQ__LineItems__r) {

          if( !mapQuoteLineId_PricebookEntryId.containsKey(quoteLineIterator.Id) ) {
            continue;
          }

          orderProductPlaceHolder = new OrderItem(OrderId = orderIdIterator);
          orderProductPlaceHolder.PricebookEntryId =
            mapQuoteLineId_PricebookEntryId.get(quoteLineIterator.Id);
          orderProductPlaceHolder.itemdesc_original__c =
            quoteLineIterator.SBQQ__Product__r.SKU_Description__c;
          orderProductPlaceHolder.itemid__c =
            quoteLineIterator.SBQQ__Product__r.SKU_ID__c;
          orderProductPlaceHolder.revrectemplate__c =
            quoteLineIterator.SBQQ__Product__r.RevRec_Template__c;
          orderProductPlaceHolder.SBQQ__QuoteLine__c = quoteLineIterator.Id;
          orderProductPlaceHolder.Quantity = quoteLineIterator.SBQQ__Quantity__c;
          orderProductPlaceHolder.UnitPrice = quoteLineIterator.SBQQ__NetTotal__c + (quoteLineIterator.CPQ_Prorated_Ramp_Up_Total__c != NULL ? quoteLineIterator.CPQ_Prorated_Ramp_Up_Total__c : 0);
          orderProductPlaceHolder.price__c = quoteLineIterator.SBQQ__NetTotal__c;

          orderProductPlaceHolder.revrecstartdate__c
            = orderProductPlaceHolder.revrecenddate__c
                = orderProductPlaceHolder.startdate__c
                    = mapId_OrderWithOppData.get(orderIdIterator).Opportunity.Service_Contract__r.StartDate;

          startDateString = mapId_OrderWithOppData.get(orderIdIterator).SBQQ__Quote__r.SBQQ__StartDate__c != NULL
                            ? DateTime.newInstance(mapId_OrderWithOppData.get(orderIdIterator).SBQQ__Quote__r.SBQQ__StartDate__c, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy') + TO
                            : '';
          endDateString = mapId_OrderWithOppData.get(orderIdIterator).SBQQ__Quote__r.SBQQ__EndDate__c != NULL
                          ? DateTime.newInstance(mapId_OrderWithOppData.get(orderIdIterator).SBQQ__Quote__r.SBQQ__EndDate__c, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy')
                          : '';

          orderProductPlaceHolder.memo__c = (String.isNotBlank(mapId_OrderWithOppData.get(orderIdIterator).SBQQ__Quote__r.SBQQ__Type__c) ? 'Order' : '')
                                            + YEAR + STRING_1
                                            + startDateString
                                            + endDateString;

          lstOrderProducts_ToInsert.add(orderProductPlaceHolder);
        }
      }

      try {
        delete lstBillingSchedules_ToDelete;
        delete lstOrderProducts_ToDelete;
        insert lstOrderProducts_ToInsert;
      } catch(DmlException exceptionInstance) {
        Database.rollback(stableState); return;
      }

    }

    System.debug('------ lstOrderProducts_ToInsert ------ : ' + lstOrderProducts_ToInsert);

    mapOrderId_OrderItems = new Map<Id, List<OrderItem>>();
    Set<String> setOrderItemFields = Schema.SObjectType.OrderItem.fields.getMap().keySet();
    String setOrderIds = '(\'' + String.join(new List<Id>(pMapId_NewOrder.keySet()), '\', \'') + '\')';

    String orderItemQuery = 'SELECT ';

    orderItemQuery += String.join(new List<String>(setOrderItemFields), ', ');
    orderItemQuery += ' , Order.Software_Delivery_Date__c ';
    orderItemQuery += ' , Order.Out_Clause_date__c ';
    orderItemQuery += ' , Order.CPQ_Royalties__c ';
    orderItemQuery += ' , Order.Perpetual_Buyout_Option__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Distribution__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Year_1_Net_Amount__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Year_2_Net_Amount__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Year_3_Net_Amount__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Year_4_Net_Amount__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Year_5_Net_Amount__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.CPQ_Renewal_Support_Total__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.SBQQ__Product__r.CPQ_Optional_Support_Plan__r.SKU_Description__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.SBQQ__Product__r.CPQ_Optional_Support_Plan__r.SKU_ID__c ';
    orderItemQuery += ' , SBQQ__QuoteLine__r.SBQQ__Product__r.Sku_Type__c ';
    orderItemQuery += ' , Order.CurrencyIsoCode ';
    orderItemQuery += ' FROM OrderItem WHERE OrderId IN ' + setOrderIds;

    System.debug('------ setOrderIds ------ : ' + setOrderIds);

    for(OrderItem orderItemIterator : (List<OrderItem>)Database.query(orderItemQuery)) {

      if( !mapOrderId_OrderItems.containsKey(orderItemIterator.OrderId) ) {
        mapOrderId_OrderItems.put(orderItemIterator.OrderId, new List<OrderItem> {orderItemIterator});
      } else {
        mapOrderId_OrderItems.get(orderItemIterator.OrderId).add(orderItemIterator);
      }

      // License > CPQ_Renewal_License_Total__c
      // Maintenance > CPQ_Renewal_Support_Total__c
      if(String.isNotBlank(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c)
         && SBQQ_TYPE_RENEWAL.equalsIgnoreCase(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c)) {

        if(String.isNotBlank(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.Sku_Type__c)
           && PRODUCT_SKU_TYPE_MAINTENANCE.equalsIgnoreCase(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.Sku_Type__c)) {
          mapOrderLineId_PerYearPrices.put(orderItemIterator.Id, new List<Decimal>{
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0
          });
        } else if(String.isNotBlank(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.Sku_Type__c)
                  && PRODUCT_SKU_TYPE_LICENSE.equalsIgnoreCase(orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.Sku_Type__c)) {
          mapOrderLineId_PerYearPrices.put(orderItemIterator.Id, new List<Decimal>{
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Renewal_License_Total__c
            : 0
          });

        } else {
          mapOrderLineId_PerYearPrices.put(orderItemIterator.Id, new List<Decimal>{
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_1_Net_Amount__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_1_Net_Amount__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_2_Net_Amount__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_2_Net_Amount__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_3_Net_Amount__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_3_Net_Amount__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_4_Net_Amount__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_4_Net_Amount__c
            : 0,
            orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_5_Net_Amount__c != NULL
            ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_5_Net_Amount__c
            : 0
          });
        }
      } else {
        mapOrderLineId_PerYearPrices.put(orderItemIterator.Id, new List<Decimal>{
          orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_1_Net_Amount__c != NULL
          ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_1_Net_Amount__c
          : 0,
          orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_2_Net_Amount__c != NULL
          ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_2_Net_Amount__c
          : 0,
          orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_3_Net_Amount__c != NULL
          ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_3_Net_Amount__c
          : 0,
          orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_4_Net_Amount__c != NULL
          ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_4_Net_Amount__c
          : 0,
          orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_5_Net_Amount__c != NULL
          ? orderItemIterator.SBQQ__QuoteLine__r.CPQ_Year_5_Net_Amount__c
          : 0
        });
      }

      mapOrderLineId_OptionalSkuId.put(
        orderItemIterator.Id,
        orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.CPQ_Optional_Support_Plan__r.SKU_ID__c
        );

      mapOrderLineId_OptionalSkuDesc.put(
        orderItemIterator.Id,
        orderItemIterator.SBQQ__QuoteLine__r.SBQQ__Product__r.CPQ_Optional_Support_Plan__r.SKU_Description__c
        );
    }

    List<OrderItem> lstOrderItems = new List<OrderItem>();

    for(List<OrderItem> itemsPerOrder : mapOrderId_OrderItems.values()) {
      lstOrderItems.addAll(itemsPerOrder);
    }

    Boolean isFirstBillingSchedule = false;
    Date startDate, revrecstartdate, revrecenddate, termStartDate, termEndDate, proratedStartDate, currentProratedStartDate, subscriptionEndDate, calculateStartDate;
    Integer yearCount = 1, yearCounter, monthCounter;
    Integer billingFrequency = 1;
    Integer billingScheduleCounter;
    Integer proratedDurationInDays = 0;
    Decimal billingSchedulePrice = 0.0;
    Decimal proratedAmountOnOrder = 0.0;
    Decimal proratedAmountDerived = 0.0;
    Decimal totalBillingPrice = 0.0;
    Decimal perYearPrice = 0.0;
    String perYearPriceFieldName = '';

    System.debug('------ lstOrderItems ------ : ' + lstOrderItems);

    for(OrderItem orderItemIterator : lstOrderItems) {

      if(NULL == mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__SubscriptionTerm__c) {
        continue;
      }

      monthCount = mapDuration_MonthCount.get(pMapId_NewOrder.get(orderItemIterator.OrderId).Quote_Billing_Frequency__c);
      monthCount = monthCount != NULL ? monthCount : 0;
      if(monthCount == 0) {
        Database.rollback(stableState);
        return;
      }

      System.debug('------ orderItemIterator ------ : ' + orderItemIterator);

      startDatePlaceHolder = mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__StartDate__c;

      calculateStartDate = getLatestDate( new List<Date> {
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Sign_Date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Out_Clause_date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Effective_Date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).First_Period_Start_Date__c
      } );

      proratedStartDate = mapId_OrderWithOppData.get(orderItemIterator.OrderId).First_Period_Start_Date__c != NULL
                          ? mapId_OrderWithOppData.get(orderItemIterator.OrderId).First_Period_Start_Date__c
                          : mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.CPQ_Prorated_Start_Date__c;

      proratedAmountOnOrder = mapId_OrderWithOppData.get(orderItemIterator.OrderId).CPQ_First_Period_Prorated_Amount__c;

      if( !mapOrderId_BillingSchedules.containsKey(orderItemIterator.OrderId) ) {
        mapOrderId_BillingSchedules.put(orderItemIterator.OrderId, new List<CPQ_Billing_Schedule__c>());
      }

      isFirstBillingSchedule = true;
      yearCount = Integer.valueOf(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__SubscriptionTerm__c / 12);
      billingFrequency = 12 / monthCount;
      billingScheduleCounter = 0;
      billingSchedulePrice = 0.0;
      totalBillingPrice = 0.0;
      yearCounter = 0;
      monthCounter = 0;
      perYearPrice = mapOrderLineId_PerYearPrices.get(orderItemIterator.Id).get(yearCounter);
      perYearPriceFieldName = '';

      List<Date> lstDates;

      if( NULL != proratedStartDate
          &&  NULL != startDatePlaceHolder ) {
        proratedDurationInDays = proratedStartDate.daysBetween(startDatePlaceHolder);
        proratedAmountDerived = ((perYearPrice / 365) * proratedDurationInDays).setScale(2, System.RoundingMode.CEILING);
      }

      System.debug('...proratedDurationInDays: '+proratedDurationInDays);
      System.debug('...yearCounter: '+yearCounter);
      System.debug('...proratedAmountDerived: '+proratedAmountDerived);

      if( NULL != proratedDurationInDays
          &&  0 < proratedDurationInDays
          &&  0 == yearCounter
          &&  0 < proratedAmountDerived ) {
        lstDates = new List<Date> {
          mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Sign_Date__c,
          mapId_OrderWithOppData.get(orderItemIterator.OrderId).Software_Delivery_Date__c,
          proratedStartDate,
          mapId_OrderWithOppData.get(orderItemIterator.OrderId).Out_Clause_date__c,
          mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Effective_Date__c
        };

        billingSchedulePrice = NULL != proratedAmountOnOrder && 0 != proratedAmountOnOrder
                               ? proratedAmountOnOrder
                               : proratedAmountDerived;

        startDate = calculateStartDate;
        currentProratedStartDate = startDate;
        System.debug('***SCENARIO: CREATE PRORATED BILLING SCHEDULES');
        System.debug('***startDate '+startDate);
        revrecstartdate = getLatestDate( lstDates );
        termStartDate = proratedStartDate;
        revrecenddate = (REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? startDatePlaceHolder : proratedStartDate).addDays(REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? -1 : 0);
        if ( revrecenddate < revrecstartdate ) {
          revrecenddate = revrecstartdate;
        }
        termEndDate = startDatePlaceHolder.addDays(-1);

        startDateString = termStartDate != NULL
                          ? DateTime.newInstance(termStartDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy') + TO
                          : '';
        endDateString = termEndDate != NULL
                        ? DateTime.newInstance(termEndDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy')
                        : '';

        System.debug('------ billingSchedulePrice ------- : ' + billingSchedulePrice);
        System.debug('------ perYearPrice ------- : ' + perYearPrice);
        System.debug('------ proratedAmountOnOrder ------- : ' + proratedAmountOnOrder);
        System.debug('------ proratedAmountDerived ------- : ' + proratedAmountDerived);
        System.debug('------ CurrencyIsoCode ------- : ' + orderItemIterator.getsObject('Order').get('CurrencyIsoCode'));

        mapOrderId_BillingSchedules.get(orderItemIterator.OrderId).add(new CPQ_Billing_Schedule__c(
                                                                         Order__c = orderItemIterator.OrderId,
                                                                         Order_Product__c = orderItemIterator.Id,
                                                                         Billing_Schedule_Type__c = 'Billing',
                                                                         Software_Delivery_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Software_Delivery_Date__c')),
                                                                         Out_Clause_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Out_Clause_Date__c')),
                                                                         Support_Distribution__c = Decimal.valueOf(String.valueOf(orderItemIterator.getsObject('SBQQ__QuoteLine__r').get('CPQ_Distribution__c'))),
                                                                         Royalties__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('CPQ_Royalties__c')),
                                                                         Perpetual_Buyout_Option__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('Perpetual_Buyout_Option__c')),
                                                                         CurrencyIsoCode = String.valueOf(orderItemIterator.getsObject('Order').get('CurrencyIsoCode')),
                                                                         revrecstartdate__c = revrecstartdate,
                                                                         revrecenddate__c = revrecenddate,
                                                                         startdate__c = startDate,
                                                                         Term_Start_Date__c = termStartDate,
                                                                         Term_End_Date__c = termEndDate,
                                                                         revrectemplate__c = orderItemIterator.revrectemplate__c,
                                                                         termname__c = mapId_OrderWithOppData.get(orderItemIterator.OrderId).termname__c,
                                                                         memo__c = 'Prorated Daily : ' + startDateString
                                                                                   + endDateString,
                                                                         itemdesc_original__c = orderItemIterator.itemdesc_original__c,
                                                                         itemid__c = orderItemIterator.itemid__c,
                                                                         price__c = billingSchedulePrice
                                                                         ));

        if(proratedAmountOnOrder != NULL) {
          if(proratedAmountOnOrder < (perYearPrice + proratedAmountDerived)) {
            perYearPrice = NULL != proratedAmountOnOrder && 0 != proratedAmountOnOrder
                           ? (perYearPrice + proratedAmountDerived) - proratedAmountOnOrder
                           : perYearPrice;
          } else if(Trigger.isExecuting) {
            pMapId_NewOrder.get(orderItemIterator.OrderId).addError(System.Label.CPQ_ProratedAmountError);
          }
        }
        mapOrderId_OrderRecord.put(orderItemIterator.OrderId, new Order(
                                     Id = orderItemIterator.OrderId,
                                     First_Period_Start_Date__c = termStartDate,
                                     First_Period_End_Date__c = termEndDate
                                     ));
      }

      lstDates = new List<Date> {
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Sign_Date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Software_Delivery_Date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__StartDate__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Out_Clause_date__c,
        mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Effective_Date__c
      };

      subscriptionEndDate = mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__EndDate__c != NULL
                            ? mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__EndDate__c
                            : mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__StartDate__c.addMonths(Integer.valueOf(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__SubscriptionTerm__c)).addDays(-1);


      System.debug('...startDatePlaceHolder: '+startDatePlaceHolder);
      System.debug('...subscriptionEndDate: '+subscriptionEndDate);
      System.debug('...monthCount: '+monthCount);
      System.debug('...yearCount : '+yearCount);
      System.debug('...perYearPrice: '+perYearPrice);

      while( startDatePlaceHolder < subscriptionEndDate
             && monthCount != 0 ) {
        system.debug('perYearPrice'+perYearPrice);
        system.debug('perYearPrice == 0'+(perYearPrice == 0));
        System.debug('...monthCount: '+monthCount);
        System.debug('...yearCount : '+yearCount);
        if(perYearPrice == NULL || perYearPrice == 0) {
          break;
        }

        billingSchedulePrice = 0.0;
        monthCounter += monthCount;

        System.debug('...monthCounter outside if: '+monthCounter);
        System.debug('...yearCounter outside if: '+yearCounter);
        if(monthCounter > 12) {

          monthCounter = 3;
          yearCounter++;
          perYearPrice = mapOrderLineId_PerYearPrices.get(orderItemIterator.Id).get(yearCounter);
          totalBillingPrice = 0.0;
          System.debug('...monthCounter: '+monthCounter);
          System.debug('...yearCounter : '+yearCounter);
        }

        if(isFirstBillingSchedule == true) {
          if( NULL != proratedDurationInDays
              &&  0 < proratedDurationInDays
              &&  0 == yearCounter
              &&  0 < proratedAmountDerived ) {
            startDate = startDatePlaceHolder.addDays(mapPaymentTerm_DayCount.get(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__PaymentTerms__c));
            if(startDate < currentProratedStartDate) {
              System.debug('***startDate is less than currentProratedStartDate');
              startDate = currentProratedStartDate;
            }
            System.debug('***SCENARIO: CREATE 1st BILLING SCHEDULE WITH PRORATED PEIROD');
            System.debug('***startDate '+startDate);
          } else {
            startDate = getLatestDate( new List<Date> {
              mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Sign_Date__c,
              mapId_OrderWithOppData.get(orderItemIterator.OrderId).Out_Clause_date__c,
              mapId_OrderWithOppData.get(orderItemIterator.OrderId).Contract_Effective_Date__c,
              mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__StartDate__c
            } );
            System.debug('***SCENARIO: CREATE 1st BILLING SCHEDULE WITHOUT PRORATED PERIOD');
            System.debug('***startDate '+startDate);
          }


          termStartDate = startDatePlaceHolder;
          revrecstartdate = getLatestDate( lstDates );
          system.debug('----revrecstartdate: ' + revrecstartdate);
          revrecenddate = startDatePlaceHolder.addMonths(REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? monthCount : 0).addDays(REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? -1 : 0);
          if ( revrecenddate < revrecstartdate ) {
            revrecenddate = revrecstartdate;
          }
          termEndDate = startDatePlaceHolder.addMonths(monthCount).addDays(-1);

          startDateString = termStartDate != NULL
                            ? DateTime.newInstance(termStartDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy') + TO
                            : '';
          endDateString = termEndDate != NULL
                          ? DateTime.newInstance(termEndDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy')
                          : '';

          billingSchedulePrice = (perYearPrice / billingFrequency).setScale(2, System.RoundingMode.CEILING);
          if(billingSchedulePrice == 0 ) {
            continue;
          }
          totalBillingPrice += billingSchedulePrice;

          System.debug('------ billingSchedulePrice ------ : ' + billingSchedulePrice);
          System.debug('------ totalBillingPrice ------ : ' + totalBillingPrice);
          System.debug('------ CurrencyIsoCode ------- : ' + orderItemIterator.getsObject('Order').get('CurrencyIsoCode'));

          mapOrderId_BillingSchedules.get(orderItemIterator.OrderId).add(new CPQ_Billing_Schedule__c(
                                                                           Order__c = orderItemIterator.OrderId,
                                                                           Order_Product__c = orderItemIterator.Id,
                                                                           Billing_Schedule_Type__c = 'Billing',
                                                                           Software_Delivery_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Software_Delivery_Date__c')),
                                                                           Out_Clause_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Out_Clause_Date__c')),
                                                                           Support_Distribution__c = Decimal.valueOf(String.valueOf(orderItemIterator.getsObject('SBQQ__QuoteLine__r').get('CPQ_Distribution__c'))),
                                                                           Royalties__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('CPQ_Royalties__c')),
                                                                           Perpetual_Buyout_Option__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('Perpetual_Buyout_Option__c')),
                                                                           CurrencyIsoCode = String.valueOf(orderItemIterator.getsObject('Order').get('CurrencyIsoCode')),
                                                                           revrecstartdate__c = revrecstartdate,
                                                                           revrecenddate__c = revrecenddate,
                                                                           startdate__c = startDate,
                                                                           Term_Start_Date__c = termStartDate,
                                                                           Term_End_Date__c = termEndDate,
                                                                           revrectemplate__c = orderItemIterator.revrectemplate__c,
                                                                           termname__c = mapId_OrderWithOppData.get(orderItemIterator.OrderId).termname__c,
                                                                           memo__c = ((String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && !SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c))
                                                                                      ? 'Order'
                                                                                      : (String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c))
                                                                                      ? SBQQ_TYPE_RENEWAL
                                                                                      : '')
                                                                                     + ' '
                                                                                     + mapDuration_DurationName.get(pMapId_NewOrder.get(orderItemIterator.OrderId).Quote_Billing_Frequency__c) + ' Payment ' + ++billingScheduleCounter
                                                                                     + ': ' + startDateString
                                                                                     + endDateString,
                                                                           itemdesc_original__c = getSKUInfo(mapId_OrderWithOppData, mapOrderLineId_OptionalSkuDesc, null, mapPbeId_ProductSkuType, orderItemIterator, termStartDate, isFirstBillingSchedule),
                                                                           itemid__c = getSKUInfo(mapId_OrderWithOppData, null, mapOrderLineId_OptionalSkuId, mapPbeId_ProductSkuType, orderItemIterator, termStartDate, isFirstBillingSchedule),
                                                                           price__c = billingSchedulePrice
                                                                           ));
          isFirstBillingSchedule = false;

        } else {
          startDate = startDatePlaceHolder.addDays(mapPaymentTerm_DayCount.get(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__PaymentTerms__c));
          System.debug('***SCENARIO THREE');
          System.debug('***startDate '+startDate);
          revrecstartdate = termStartDate = startDatePlaceHolder;
          revrecenddate = startDatePlaceHolder.addMonths(REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? monthCount : 0).addDays(REVRECTEMPLATE_PRORATE.equalsIgnoreCase(orderItemIterator.revrectemplate__c) ? -1 : 0);
          if ( revrecenddate < revrecstartdate ) {
            revrecenddate = revrecstartdate;
          }
          termEndDate = startDatePlaceHolder.addMonths(monthCount).addDays(-1);

          startDateString = termStartDate != NULL
                            ? DateTime.newInstance(termStartDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy') + TO
                            : '';
          endDateString = termEndDate != NULL
                          ? DateTime.newInstance(termEndDate, Time.newInstance(0, 0, 0, 0)).format('d MMMM yyyy')
                          : '';

          billingSchedulePrice = (perYearPrice / billingFrequency).setScale(2, System.RoundingMode.CEILING);
          if(billingSchedulePrice == 0 ) {
            continue;
          }
          totalBillingPrice += billingSchedulePrice;

          System.debug('------ billingSchedulePrice ------ : ' + billingSchedulePrice);
          System.debug('------ yearCounter ------ : ' + yearCounter);
          System.debug('------ totalBillingPrice ------ : ' + totalBillingPrice);
          System.debug('------ termStartDate ------ : ' + termStartDate + ' >= mapId_OrderWithOppData.get(orderItemIterator.OrderId).Optional_Support_Start_Date__c ------ : ' + mapId_OrderWithOppData.get(orderItemIterator.OrderId).Optional_Support_Start_Date__c);
          System.debug('------ productSkuType ------ : ' + mapPbeId_ProductSkuType.get(orderItemIterator.PricebookEntryId));
          System.debug('------ option sku check ------ : ' + (termStartDate >= mapId_OrderWithOppData.get(orderItemIterator.OrderId).Optional_Support_Start_Date__c && PRODUCT_SKU_TYPE_MAINTENANCE.equalsIgnoreCase(mapPbeId_ProductSkuType.get(orderItemIterator.PricebookEntryId))));
          System.debug('------ optional sku ------ : ' + mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id));
          System.debug('------ CurrencyIsoCode ------- : ' + orderItemIterator.getsObject('Order').get('CurrencyIsoCode'));

          if(totalBillingPrice > perYearPrice) {
            billingSchedulePrice = billingSchedulePrice - (totalBillingPrice - perYearPrice);
            if(billingSchedulePrice == 0) {
              continue;
            }
          }

          mapOrderId_BillingSchedules.get(orderItemIterator.OrderId).add(new CPQ_Billing_Schedule__c(
                                                                           Order__c = orderItemIterator.OrderId,
                                                                           Order_Product__c = orderItemIterator.Id,
                                                                           Billing_Schedule_Type__c = 'Billing',
                                                                           Software_Delivery_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Software_Delivery_Date__c')),
                                                                           Out_Clause_Date__c = Date.valueOf(orderItemIterator.getsObject('Order').get('Out_Clause_Date__c')),
                                                                           Support_Distribution__c = Decimal.valueOf(String.valueOf(orderItemIterator.getsObject('SBQQ__QuoteLine__r').get('CPQ_Distribution__c'))),
                                                                           Royalties__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('CPQ_Royalties__c')),
                                                                           Perpetual_Buyout_Option__c = Boolean.valueOf(orderItemIterator.getsObject('Order').get('Perpetual_Buyout_Option__c')),
                                                                           CurrencyIsoCode = String.valueOf(orderItemIterator.getsObject('Order').get('CurrencyIsoCode')),
                                                                           revrecstartdate__c = revrecstartdate,
                                                                           revrecenddate__c = revrecenddate,
                                                                           startdate__c = startDate,
                                                                           Term_Start_Date__c = termStartDate,
                                                                           Term_End_Date__c = termEndDate,
                                                                           revrectemplate__c = orderItemIterator.revrectemplate__c,
                                                                           termname__c = mapId_OrderWithOppData.get(orderItemIterator.OrderId).termname__c,
                                                                           memo__c = ((String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && !SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c))
                                                                                      ? 'Order'
                                                                                      : (String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c))
                                                                                      ? SBQQ_TYPE_RENEWAL
                                                                                      : '')
                                                                                     + ' '
                                                                                     + mapDuration_DurationName.get(pMapId_NewOrder.get(orderItemIterator.OrderId).Quote_Billing_Frequency__c) + ' Payment ' + ++billingScheduleCounter
                                                                                     + ': ' + startDateString
                                                                                     + endDateString,
                                                                           itemdesc_original__c = getSKUInfo(mapId_OrderWithOppData, mapOrderLineId_OptionalSkuDesc, null, mapPbeId_ProductSkuType, orderItemIterator, termStartDate, isFirstBillingSchedule),
                                                                           itemid__c = getSKUInfo(mapId_OrderWithOppData, null, mapOrderLineId_OptionalSkuId, mapPbeId_ProductSkuType, orderItemIterator, termStartDate, isFirstBillingSchedule),
                                                                           price__c = billingSchedulePrice
                                                                           ));

        }

        startDatePlaceHolder = startDatePlaceHolder.addMonths(monthCount);
        System.debug('------ startDatePlaceHolder ------ : ' + startDatePlaceHolder);
      }
    }

    List<CPQ_Billing_Schedule__c> lstBillingSchedules = new List<CPQ_Billing_Schedule__c>();

    for(List<CPQ_Billing_Schedule__c> billingSchedulesPerOrder : mapOrderId_BillingSchedules.values()) {
      lstBillingSchedules.addAll(billingSchedulesPerOrder);
    }

    // update orderitem's unit price
    List<OrderItem> lstOrderItem = [SELECT Id, UnitPrice, Quantity FROM OrderItem WHERE OrderId IN : setFilteredOrderIds];
    List<CPQ_Billing_Schedule__c> lstBillingSchedule = [SELECT Id, Order_Product__c, Price__c FROM CPQ_Billing_Schedule__c WHERE Order__c IN : setFilteredOrderIds];

    Map<Id, Decimal> mapOrderItemIdPriceSum = new Map<Id, Decimal>();
    for(CPQ_Billing_Schedule__c billingSchedule : lstBillingSchedule) {
      if(mapOrderItemIdPriceSum.get(billingSchedule.Order_Product__c) == NULL) {
        mapOrderItemIdPriceSum.put(billingSchedule.Order_Product__c, billingSchedule.Price__c);
      }else{
        mapOrderItemIdPriceSum.put(billingSchedule.Order_Product__c, mapOrderItemIdPriceSum.get(billingSchedule.Order_Product__c) + billingSchedule.Price__c);
      }
    }
    for(OrderItem oItem : lstOrderItem) {
      oItem.UnitPrice = (mapOrderItemIdPriceSum.get(oItem.Id) == NULL ? 0 : mapOrderItemIdPriceSum.get(oItem.Id)) / oItem.Quantity;
    }

    try {
      if( false == isGeneratingOrderItems ) {
        delete lstBillingSchedules_ToDelete;
      }
      insert lstBillingSchedules;
    } catch(DmlException exceptionInstance) {
      generateBillingSchedule = false;
      System.debug('------ Exception caught: ----- : ' + exceptionInstance.getMessage());
      Database.rollback(stableState); return;
    }

    System.debug('...mapOrderId_OrderRecord.values()' + mapOrderId_OrderRecord.values());

    try {
      update mapOrderId_OrderRecord.values();
    } catch(DmlException exceptionInstance) {
      generateBillingSchedule = false;
      Database.rollback(stableState);
      System.debug('...Exception caught: ----- : ' + exceptionInstance.getMessage()); return;
    }

    try {
      update lstOrderItem;
    } catch(DmlException exceptionInstance) {
      generateBillingSchedule = false;
      System.debug('------ Exception caught: ----- : ' + exceptionInstance.getMessage());
      Database.rollback(stableState); return;
    }

    generateBillingSchedule = false;

  }

  @TestVisible private static Date getLatestDate(List<Date> lstDates) {
    if(lstDates == NULL || lstDates.isEmpty()) {
      return NULL;
    }

    if(lstDates.size() == 1) {
      return lstDates[0];
    }

    lstDates.sort();
    System.debug('------ lstDates[lstDates.size() - 1] ------ : ' + lstDates[lstDates.size() - 1]);
    return lstDates[lstDates.size() - 1];
  }

  @TestVisible private static String getSKUInfo(Map<Id, Order> mapId_OrderWithOppData, Map<Id, String> mapOrderLineId_OptionalSkuDesc, Map<Id, String> mapOrderLineId_OptionalSkuId, Map<Id, String> mapPbeId_ProductSkuType, OrderItem orderItemIterator, Date termStartDate, Boolean isFirstBillingSchedule) {

    System.debug('***getSKUInfo');

    if(isFirstBillingSchedule) {
      System.debug('***first billing schedule');
      if(String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c)) {
        System.debug('***renewal');
        if(mapOrderLineId_OptionalSkuDesc != null && String.isNotBlank(mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id);
        }
        if(mapOrderLineId_OptionalSkuId != null && String.isNotBlank(mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id);
        }
      }
    }else{
      System.debug('***not first billing schedule');
      if(String.isNotBlank(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c) && SBQQ_TYPE_RENEWAL.equalsIgnoreCase(mapId_OrderWithOppData.get(orderItemIterator.OrderId).SBQQ__Quote__r.SBQQ__Type__c)) {
        System.debug('***renewal');
        if(mapOrderLineId_OptionalSkuDesc != null && String.isNotBlank(mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id);
        }
        if(mapOrderLineId_OptionalSkuId != null && String.isNotBlank(mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id);
        }
      }
      if(termStartDate >= mapId_OrderWithOppData.get(orderItemIterator.OrderId).Optional_Support_Start_Date__c && PRODUCT_SKU_TYPE_MAINTENANCE.equalsIgnoreCase(mapPbeId_ProductSkuType.get(orderItemIterator.PricebookEntryId))) {
        System.debug('***start date ready');
        if(mapOrderLineId_OptionalSkuDesc != null && String.isNotBlank(mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuDesc.get(orderItemIterator.Id);
        }
        if(mapOrderLineId_OptionalSkuId != null && String.isNotBlank(mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id))) {
          return mapOrderLineId_OptionalSkuId.get(orderItemIterator.Id);
        }
      }
    }

    System.debug('reached end');
    if(mapOrderLineId_OptionalSkuDesc != null) {
      return orderItemIterator.itemdesc_original__c;
    }else{
      return orderItemIterator.itemid__c;
    }
  }
}
