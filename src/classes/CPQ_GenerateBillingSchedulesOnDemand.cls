global with sharing class CPQ_GenerateBillingSchedulesOnDemand {

    Webservice static void createBillingSchedules(Id pOrderId) {

        Set<String> setOrderFields = Schema.SObjectType.Order.fields.getMap().keySet();

        String orderQuery = 'SELECT ';

        orderQuery += String.join(new List<String>(setOrderFields), ', ');
        orderQuery += ' FROM Order WHERE Id = : pOrderId ';

        System.debug('------ orderQuery ------ : ' + orderQuery);
        Map<Id, Order> mapId_OrderRecord = new Map<Id, Order>((List<Order>) Database.query(orderQuery));

        CPQ_BillingScheduleCreatorUtility.createBillingSchedules(NULL, mapId_OrderRecord, false);
    }

}