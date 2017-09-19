public with sharing class CS_ServiceContractTriggerHandler implements CS_ITrigger {

  Map<Id, Date> serviceContractIdSoftwareDeliveryDateMap = new Map<Id, Date>();

  public CS_ServiceContractTriggerHandler() {

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

  public void afterUpdate(SObject oldSo, SObject newSo){
    ServiceContract oldSC = (ServiceContract)oldSo;
    ServiceContract newSC = (ServiceContract)newSo;
    if(newSC.CS_Software_Delivery_Date__c != NULL && newSC.CS_Software_Delivery_Date__c != oldSC.CS_Software_Delivery_Date__c) {
      serviceContractIdSoftwareDeliveryDateMap.put(newSC.Id, newSC.CS_Software_Delivery_Date__c);
    }
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

    if(serviceContractIdSoftwareDeliveryDateMap.keySet().size() > 0) {
      List<ContractlineItem> contractLineItemList = [SELECT Id, CS_Software_Delivery_Date__c, ServiceContractId FROM ContractlineItem WHERE ServiceContractId IN : serviceContractIdSoftwareDeliveryDateMap.keySet()];
      System.debug('***contractLineItemList ' + contractLineItemList);

      for(ContractlineItem cli : contractLineItemList) {
        cli.CS_Software_Delivery_Date__c = serviceContractIdSoftwareDeliveryDateMap.get(cli.ServiceContractId);
      }

      if(!contractLineItemList.isEmpty()) {
        System.debug('***update contractLineItemList');
        update contractLineItemList;
      }
    }
  }
}
