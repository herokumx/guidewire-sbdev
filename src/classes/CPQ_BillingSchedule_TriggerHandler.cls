public without sharing class CPQ_BillingSchedule_TriggerHandler implements CS_ITrigger {

  Set<Id> updateOrderIdSet = new Set<Id>();
  Map<Id, String> orderIdStatusMap = new Map<Id, String>();

  public CPQ_BillingSchedule_TriggerHandler() {

  }

  /**
   * bulkBefore
   *
   * This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  public void bulkBefore(){
    if (Trigger.isInsert) {

    }

    if(Trigger.isUpdate) {
      Set<Id> orderIdSet = new Set<Id>();
      for(SObject so : Trigger.new) {
        CPQ_Billing_Schedule__c bs = (CPQ_Billing_Schedule__c)so;
        orderIdSet.add(bs.Order__c);
      }
      Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Status FROM Order WHERE Id IN:orderIdSet]);
      for(Id orderId : orderMap.keySet()) {
        orderIdStatusMap.put(orderId, String.valueOf(orderMap.get(orderId).get('Status')));
      }
    }
  }

  public void bulkAfter(){
    if (Trigger.isInsert) {

    }


    if(Trigger.isUpdate) {

    }
  }


  public void beforeInsert(SObject so){

  }

  public void beforeUpdate(SObject oldSo, SObject newSo){
    CPQ_Billing_Schedule__c oldBS = (CPQ_Billing_Schedule__c)oldSo;
    CPQ_Billing_Schedule__c newBS = (CPQ_Billing_Schedule__c)newSo;
    if(oldBS.Revrectemplate__c != newBS.Revrectemplate__c
       || oldBS.Revrecstartdate__c != newBS.Revrecstartdate__c
       || oldBS.Revrecenddate__c != newBS.Revrecenddate__c
       || oldBS.Software_Delivery_Date__c != newBS.Software_Delivery_Date__c
       || oldBS.Billing_Schedule_Status__c != 'Terminated' && newBS.Billing_Schedule_Status__c == 'Terminated') {
      if(orderIdStatusMap.get(newBS.Order__c) == 'Rev Team Review Complete'
         || orderIdStatusMap.get(newBS.Order__c) == 'Terminated'
         || orderIdStatusMap.get(newBS.Order__c) == 'Order Activated') {
        newBS.Billing_Schedule_Integration_Status__c = 'Eligible for Billing Schedule Setup';
        updateOrderIdSet.add(newBS.Order__c);
      }
    }

    if(oldBS.ERP_Billing_Schedule_Integration_Status__c != 'Closed' && newBS.ERP_Billing_Schedule_Integration_Status__c == 'Closed') {
      newBS.Billing_Schedule_Status__c = 'Invoiced';
    }
  }

  /**
   * beforeDelete
   *
   * This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   */
  public void beforeDelete(SObject so){

  }

  public void afterInsert(SObject so){

  }

  public void afterUpdate(SObject oldSo, SObject so){

  }

  public void afterDelete(SObject so){

  }

  /**
   * andFinally
   *
   * This method is called once all records have been processed by the trigger. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  public void andFinally(){

    if(updateOrderIdSet.size() > 0) {
      List<Order> orderList = [SELECT Id, Order_Integration_Status__c FROM Order WHERE Id IN : updateOrderIdSet];
      for(Order o: orderList) {
        o.Order_Integration_Status__c = 'Eligible for Order Setup';
      }
      if(!Test.isRunningTest()) {
        update orderList;
      }
    }

  }
}
