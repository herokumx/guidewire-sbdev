/*
 *****************************************************************************************************************************
   Class Name - CS_ContractLineItemTriggerHandler
   Class Type -  Trigger Handler
   Test Class-
   Purpose-

 *****************************************************************************************************************************

   Name        Email              Date             Notes
   Mani                                             Initial Creation
   Mani       manig@slalom        10/12/2016       Bug Fix  to Set Fields  CS_Rating_Management__c
                                    CS_Re_Insurance_Key__c
                                    CS_SAP_Production_Key__c
                                    CS_BFO_Key__c
                             to True


 *****************************************************************************************************************************
 */
public with sharing class CS_ContractLineItemTriggerHandler implements CS_ITrigger {

  private Set<Id> SC= New set<Id>();
  private Set<Id> SCLI= New set<Id>();

  Set<Id> contractLineItemIdSet = new Set<Id>();

  private Map<id,Servicecontract> Newservicecontract= New Map<id,Servicecontract>();
  public CS_ContractLineItemTriggerHandler() {

  }


  /**
   * bulkBefore
   *
   * This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  public void bulkBefore()
  {

  }
  public void bulkAfter()
  {

    if (Trigger.isafter && Trigger.isInsert) {


      for(SObject so: Trigger.new) {
        ContractLineItem cli = (ContractLineItem)so;
        if (cli.CS_Product_Serial_Number__c !=Null) {
          SC.add(cli.servicecontractid);
        }
      }

      ServiceContract UpdateServiceContract = New ServiceContract();

      for(servicecontract SerCon : [select CS_BFO__c,CS_Rating_Management__c,
                                    CS_Rating_Management_Key__c,CS_Re_Insurance__c, CS_Re_Insurance_Key__c,CS_SAP_Production__c,
                                    CS_SAP_Production_Key__c from ServiceContract where id=:SC ]) {
        for(SObject so: Trigger.new) {
          ContractLineItem Tcli = (ContractLineItem)so;


          If(TCLI.servicecontractid== SerCon.id && TCLI.CS_Product_Serial_Number__c!=null && TCLI.CS_Product_Name__c.contains('Rating Management') ){

            UpdateServiceContract= New ServiceContract(id=SerCon.id,
                                                       CS_Rating_Management__c=true,
                                                       CS_Rating_Management_Key__c=TCLI.CS_Product_Serial_Number__c);

            if(Newservicecontract.get(SerCon.id)!=null ) {
              Newservicecontract.get(SerCon.id).CS_Rating_Management_Key__c=TCLI.CS_Product_Serial_Number__c;
              Newservicecontract.get(SerCon.id).CS_Rating_Management__c=true;
            }
            else{
              Newservicecontract.put(SerCon.id,UpdateServiceContract);
            }

          }

          If(TCLI.servicecontractid== SerCon.id && TCLI.CS_Product_Serial_Number__c!=null && TCLI.CS_Product_Name__c.contains('Reinsurance') ){
            UpdateServiceContract= New ServiceContract(id=SerCon.id,
                                                       CS_Re_Insurance__c=true,
                                                       CS_Re_Insurance_Key__c=TCLI.CS_Product_Serial_Number__c);
            if(Newservicecontract.get(SerCon.id)!=null ) {
              Newservicecontract.get(SerCon.id).CS_Re_Insurance_Key__c=TCLI.CS_Product_Serial_Number__c;
              Newservicecontract.get(SerCon.id).CS_Re_Insurance__c=true;
            }
            else{
              Newservicecontract.put(SerCon.id,UpdateServiceContract);
            }
          }

          If(TCLI.servicecontractid== SerCon.id && TCLI.CS_Product_Serial_Number__c!=null && TCLI.CS_Product_Name__c.contains('SAP') ){
            UpdateServiceContract= New ServiceContract(id=SerCon.id,
                                                       CS_SAP_Production__c=true,
                                                       CS_SAP_Production_Key__c=TCLI.CS_Product_Serial_Number__c);
            if(Newservicecontract.get(SerCon.id)!=null ) {
              Newservicecontract.get(SerCon.id).CS_SAP_Production_Key__c=TCLI.CS_Product_Serial_Number__c;
              Newservicecontract.get(SerCon.id).CS_SAP_Production__c=true;
            }
            else{
              Newservicecontract.put(SerCon.id,UpdateServiceContract);
            }
          }

          If(TCLI.servicecontractid== SerCon.id && TCLI.CS_Product_Serial_Number__c!=null && TCLI.CS_Product_Name__c.contains('BFO') ){
            UpdateServiceContract= New ServiceContract(id=SerCon.id,
                                                       CS_BFO__c=true,
                                                       CS_BFO_Key__c=TCLI.CS_Product_Serial_Number__c);


            if(Newservicecontract.get(SerCon.id)!=null ) {
              Newservicecontract.get(SerCon.id).CS_BFO_Key__c=TCLI.CS_Product_Serial_Number__c;
              Newservicecontract.get(SerCon.id).CS_BFO__c=true;

            }
            else{
              Newservicecontract.put(SerCon.id,UpdateServiceContract);
            }
          }
        }

      }

    }

  }

  public void beforeInsert(SObject so){
  }

  public void beforeUpdate(SObject oldSo, SObject newSo)
  {

  }

  /**
   * beforeDelete
   *
   * This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   */
  public void beforeDelete(SObject so)
  {

  }

  public void afterInsert(SObject so)
  {

  }

  public void afterUpdate(SObject oldSo, SObject newSo)
  {
    ContractLineItem oldCLI = (ContractLineItem)oldSo;
    ContractLineItem newCLI = (ContractLineItem)newSo;
    // if contractlineitem's CS_Software_Delivery_Date__c field changed, then collect its Id
    if(newCLI.CS_Software_Delivery_Date__c != NULL && newCLI.CS_Software_Delivery_Date__c != oldCLI.CS_Software_Delivery_Date__c) {
      contractLineItemIdSet.add(newCLI.Id);
    }
  }

  public void afterDelete(SObject so)
  {
  }

  /**
   * andFinally
   *
   * This method is called once all records have been processed by the trigger. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  public void andFinally()
  {

    // insert ACP record
    if (Trigger.isInsert && Trigger.isAfter && Newservicecontract != null && !Newservicecontract.isEmpty()) {
      try {
        Update Newservicecontract.values();
      } catch (DmlException e) {
        System.debug('The following Error has occured ' + e.getMessage());
      }
    }

    if(contractLineItemIdSet.size() > 0) {
      System.debug('***populate Software Delivery Date on quotelines');
      System.debug('***contractLineItemIdSet ' + contractLineItemIdSet);

      // create map of contractLineItemId => opportunityId, map of contractLineItemId => product2Id, and map of contractLineItemId => softwareDeliveryDate
      Map<Id, Id> contractLineItemIdOpportunityIdMap = new Map<Id, Id>();
      Map<Id, Id> contractLineItemIdProductIdMap = new Map<Id, Id>();
      Map<Id, Date> contractLineItemIdSoftwareDeliveryDate = new Map<Id, Date>();

      List<ContractLineItem> lstOfChangedCLI = [SELECT Id, ServiceContract.CPQ_Opportunity__c, PricebookEntry.Product2Id, CS_Software_Delivery_Date__c FROM ContractLineItem WHERE Id IN: contractLineItemIdSet];
      for(ContractLineItem cli : lstOfChangedCLI) {
        contractLineItemIdOpportunityIdMap.put(cli.Id, (Id)cli.getsObject('ServiceContract').get('CPQ_Opportunity__c'));
        contractLineItemIdProductIdMap.put(cli.Id, (Id)cli.getsObject('PricebookEntry').get('Product2Id'));
        contractLineItemIdSoftwareDeliveryDate.put(cli.Id, (Date)cli.get('CS_Software_Delivery_Date__c'));
      }
      System.debug('***contractLineItemIdProductIdMap ' + contractLineItemIdProductIdMap);
      System.debug('***contractLineItemIdOpportunityIdMap ' + contractLineItemIdOpportunityIdMap);
      System.debug('***contractLineItemIdSoftwareDeliveryDate ' + contractLineItemIdSoftwareDeliveryDate);

      // query opportunity products (with product2Id and quotelineId) based on opportunityId
      List<OpportunityLineItem> lstOfOLIs = [SELECT Id, OpportunityId, Product2Id, SBQQ__QuoteLine__c FROM OpportunityLineItem WHERE OpportunityId IN : contractLineItemIdOpportunityIdMap.values()];
      System.debug('***lstOfOLIs ' + lstOfOLIs);

      if(lstOfOLIs.isEmpty()) return;

      // create a map of opportunityId => (productId => quotelineId), and a quotelineId set
      Map<Id, Map<Id, Id>> oppId_productIdQuotelineIdMap = new Map<Id, Map<Id, Id>>();
      Set<Id> quotelineIdSet = new Set<Id>();

      for(OpportunityLineItem oli : lstOfOLIs) {
        quotelineIdSet.add(oli.SBQQ__QuoteLine__c);
        if(oppId_productIdQuotelineIdMap.get(oli.OpportunityId) == NULL) {
          Map<Id, Id> productIdQuotelineIdMap = new Map<Id, Id>();
          productIdQuotelineIdMap.put(oli.Product2Id, oli.SBQQ__QuoteLine__c);
          oppId_productIdQuotelineIdMap.put(oli.OpportunityId, productIdQuotelineIdMap);
        }else{
          Map<Id, Id> productIdQuotelineIdMap = oppId_productIdQuotelineIdMap.get(oli.OpportunityId);
          productIdQuotelineIdMap.put(oli.Product2Id, oli.SBQQ__QuoteLine__c);
          oppId_productIdQuotelineIdMap.put(oli.OpportunityId, productIdQuotelineIdMap);
        }
      }
      System.debug('***quotelineIdSet ' + quotelineIdSet);
      System.debug('***oppId_productIdQuotelineIdMap ' + oppId_productIdQuotelineIdMap);

      // query SBQQ__QuoteLine__c based on the quotelineIdSet
      Map<Id, SBQQ__QuoteLine__c> quotelineMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, CS_Software_Delivery_Date__c FROM SBQQ__QuoteLine__c WHERE Id IN:quotelineIdSet]);

      // iterate all the changed contractLineItem, find the corresponding quotelineitem, and update the softwareDeliveryDate field
      for(Id contractLineItemId : contractLineItemIdOpportunityIdMap.keySet()) {
        Id opportunityId = contractLineItemIdOpportunityIdMap.get(contractLineItemId);
        System.debug('***opportunityId ' + opportunityId);

        Map<Id, Id> productIdQuotelineIdMap = oppId_productIdQuotelineIdMap.get(opportunityId);
        Id productId = contractLineItemIdProductIdMap.get(contractLineItemId);
        System.debug('***productId ' + productId);

        Id quotelineId = productIdQuotelineIdMap.get(productId);
        System.debug('***quotelineId ' + quotelineId);

        SBQQ__QuoteLine__c quoteline = quotelineMap.get(quotelineId);
        quoteline.CS_Software_Delivery_Date__c = contractLineItemIdSoftwareDeliveryDate.get(contractLineItemId);
        System.debug('***quoteline ' + quoteline);
      }

      update quotelineMap.values();
    }


  }

}
