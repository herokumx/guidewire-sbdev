public without sharing class CPQ_BillingSchedule_TriggerHandler implements CS_ITrigger {

  Set<Id> orderIdSet = new Set<Id>();

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
      for(SObject so : Trigger.new) {
        CPQ_Billing_Schedule__c bs = (CPQ_Billing_Schedule__c)so;

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
      newBS.Billing_Schedule_Integration_Status__c = 'Eligible for Billing Schedule Setup';
      orderIdSet.add(newBS.Order__c);
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

    if(orderIdSet.size() > 0) {
      List<Order> orderList = [SELECT Id, Order_Integration_Status__c FROM Order WHERE Id IN : orderIdSet];
      for(Order o: orderList) {
        o.Order_Integration_Status__c = 'Eligible for Order Setup';
      }
      if(!Test.isRunningTest()) {
        update orderList;
      }
    }

  }
}
