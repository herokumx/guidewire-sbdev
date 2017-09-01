public with sharing class CPQ_Order_BillingSchedule_Helper {

  //Static run variable
  @TestVisible private static Boolean runForInsertOnce = true;
  @TestVisible private static Boolean runForUpdateOnce = true;

  public static Boolean insertContext = false;

  private Boolean m_isExecuting = false;
  private Integer batchSize = 0;

  public static Boolean runForInsertOnce() {

    if(runForInsertOnce) {
      runForInsertOnce = false;
      return true;

    } else {
      return runForInsertOnce;
    }
  }

  public static Boolean runForUpdateOnce() {

    if(runForUpdateOnce) {
      runForUpdateOnce = false;
      return true;

    } else {
      return runForUpdateOnce;
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
      if(pId_OldOrder.get(o.Id).get('Status') != 'Rev Team Review Complete' && pId_NewOrder.get(o.Id).get('Status') == 'Rev Team Review Complete') {
        o.Order_Integration_Status__c = 'Eligible for Order Setup';
      }
      if(pId_OldOrder.get(o.Id).get('Order_Integration_Status__c') != 'Integrated' && pId_NewOrder.get(o.Id).get('Order_Integration_Status__c') == 'Integrated'
         || pId_OldOrder.get(o.Id).get('ERP_Sales_Order_Status__c') != 'Draft' && pId_NewOrder.get(o.Id).get('ERP_Sales_Order_Status__c') == 'Draft'
         || pId_OldOrder.get(o.Id).get('ERP_Sales_Order_Status__c') != 'Processed' && pId_NewOrder.get(o.Id).get('ERP_Sales_Order_Status__c') == 'Processed') {
        o.Status = Label.CPQ_Order_Status_Activated;
      }
    }
    updateBillingScheduleStatus(pId_OldOrder, pId_NewOrder);
  }

  public void OnAfterInsert(List<Order> pLstNewOrders, Map<Id, Order> pId_NewOrder) {
    CPQ_BillingScheduleCreatorUtility.createBillingSchedules(NULL, pId_NewOrder,true);
  }

  public void OnAfterUpdate(List<Order> pLstOldOrders, List<Order> pLstNewOrders, Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder) {
    CPQ_OrderActivationUtility.updateRelatedOrderStatus(pLstNewOrders, pId_OldOrder);
  }

  private void updateBillingScheduleStatus(Map<Id, Order> pId_OldOrder, Map<Id, Order> pId_NewOrder){
    String billingScheduleStatusValue = '';
    String billingScheduleIntegationStatusValue = '';
    Set<Id> orderIdSet = new Set<Id>();

    for(Id orderId : pId_NewOrder.keySet()) {
      if(pId_OldOrder.get(orderId).get('Status') != 'Rev Team Review Complete' && pId_NewOrder.get(orderId).get('Status') == 'Rev Team Review Complete') {
        billingScheduleStatusValue = 'Submitted to ERP';
        billingScheduleIntegationStatusValue = 'Eligible for Billing Schedule Setup';
        orderIdSet.add(orderId);
      }
      if(pId_OldOrder.get(orderId).get('Status') != 'Cancelled' && pId_NewOrder.get(orderId).get('Status') == 'Cancelled') {
        billingScheduleStatusValue = 'Cancelled';
        orderIdSet.add(orderId);
      }
    }

    List<CPQ_Billing_Schedule__c> billingScheduleList = [SELECT Id, Billing_Schedule_Status__c FROM CPQ_Billing_Schedule__c WHERE Order__c IN : orderIdSet];
    if(billingScheduleList.size() > 0) {
      for(CPQ_Billing_Schedule__c billingSchedule : billingScheduleList) {
        billingSchedule.Billing_Schedule_Status__c = billingScheduleStatusValue;
        billingSchedule.Billing_Schedule_Integration_Status__c = billingScheduleIntegationStatusValue;
      }
      update billingScheduleList;
    }
  }
}
