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
  //private   List<Servicecontract> Newservicecontract= New List<Servicecontract>();
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
          //SCLI.add(cli.id);
        }
      }

      ServiceContract UpdateServiceContract = New ServiceContract();

      //for(Id SC:SerCon ){
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
      //update  Newservicecontract;

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

  public void afterUpdate(SObject oldSo, SObject so)
  {
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


  }

}
