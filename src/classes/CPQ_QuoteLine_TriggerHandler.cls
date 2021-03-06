/*
 *****************************************************************************************************************************
   Class Name - CPQ_QuoteLine_TriggerHandler
   Class Type -  Trigger Handler
   Test Class-
   Purpose- SBQQ__QuoteLine__c Trigger Handler
 *****************************************************************************************************************************

   Name            Email              Date              Notes
   Jacky Z    jzhao@guidewire.com   17/5/2017       Initial Creation
 *****************************************************************************************************************************
 */
public without sharing class CPQ_QuoteLine_TriggerHandler implements CS_ITrigger {

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