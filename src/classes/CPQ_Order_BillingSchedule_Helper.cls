public with sharing class CPQ_Order_BillingSchedule_Helper {

    //Static run variable
    @TestVisible private static Boolean run = true;

    private Boolean m_isExecuting = false;
    private Integer batchSize = 0;

    public static Boolean runOnce() {

        if(run) {
            run = false;
            return true;

        } else {
            return run;
        }
    }

    //Constructor
    public CPQ_Order_BillingSchedule_Helper(Boolean isExecuting, Integer size) {
        System.debug('CPQ_Order_BillingSchedule_Helper Helper Created');
        m_isExecuting = isExecuting;
        batchSize = size;
    }

    public void OnAfterInsert(List<Order> pLstNewOrders, Map<Id, Order> pId_NewOrder) {
        // @TODO: Invoke BillingScheduleCreatorUtility
    }

    public void OnAfterUpdate(List<Order> pLstOldOrders, List<Order> pLstNewOrders, Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder) {
        // @TODO: Invoke BillingScheduleCreatorUtility
        System.debug('------ arrived here! ------' + pId_NewOrder);
        CPQ_OrderActivationUtility.updateRelatedOrderStatus(pLstNewOrders, pId_OldOrder);
        CPQ_BillingScheduleCreatorUtility.createBillingSchedules(pId_OldOrder, pId_NewOrder,true);
    }
}