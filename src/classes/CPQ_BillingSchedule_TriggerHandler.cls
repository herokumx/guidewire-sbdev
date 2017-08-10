public without sharing class CPQ_BillingSchedule_TriggerHandler implements CS_ITrigger {

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
      for (sObject so : Trigger.new) {
        CPQ_Billing_Schedule__c bs = (CPQ_Billing_Schedule__c)so;
        if(bs.Billing_Schedule_Status__c == 'Submitted to ERP' || bs.Billing_Schedule_Status__c == 'Terminated') {
          bs.Billing_Schedule_Integration_Status__c = 'Eligible for Billing Schedule Setup';
        }
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


  }
}
