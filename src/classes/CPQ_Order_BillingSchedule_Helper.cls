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

  public void OnBeforeUpdate(List<Order> pLstOldOrders, List<Order> pLstNewOrders, Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder) {
    for(Order o : pLstNewOrders) {
      if(o.Status == 'Rev Team Review Complete') {
        o.Order_Integration_Status__c = 'Eligible for Order Setup';
      }
    }
  }

  public void OnAfterInsert(List<Order> pLstNewOrders, Map<Id, Order> pId_NewOrder) {
    // @TODO: Invoke BillingScheduleCreatorUtility
  }

  public void OnAfterUpdate(List<Order> pLstOldOrders, List<Order> pLstNewOrders, Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder) {
    // @TODO: Invoke BillingScheduleCreatorUtility
    System.debug('------ arrived here! ------' + pId_NewOrder);
    CPQ_OrderActivationUtility.updateRelatedOrderStatus(pLstNewOrders, pId_OldOrder);
    CPQ_BillingScheduleCreatorUtility.createBillingSchedules(pId_OldOrder, pId_NewOrder,true);
    updateBillingScheduleStatus(pId_OldOrder, pId_NewOrder);
  }

  private void updateBillingScheduleStatus(Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder){
    Set<Id> orderIdSet = new Set<Id>();
    for(Id orderId : pId_NewOrder.keySet()) {
      if(pId_NewOrder.get(orderId).get('Status') == 'Rev Team Review Complete') {
        orderIdSet.add(orderId);
      }
    }
    List<CPQ_Billing_Schedule__c> billingScheduleList = [SELECT Id, Billing_Schedule_Status__c FROM CPQ_Billing_Schedule__c WHERE Order__c IN : orderIdSet];
    if(billingScheduleList.size() > 0) {
      for(CPQ_Billing_Schedule__c billingSchedule : billingScheduleList) {
        billingSchedule.Billing_Schedule_Status__c = 'Submitted to ERP';
      }
      update billingScheduleList;
    }
  }
}