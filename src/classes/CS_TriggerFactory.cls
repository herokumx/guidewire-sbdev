/*
 *****************************************************************************************************************************
   Class Name - CS_TriggerFactory
   Class Type - Trigger Factory Handler
   Test Class-
   Purpose-

 *****************************************************************************************************************************

   Name        Email              Date                 Notes
   Shan Xu                                            Initial Creation

 *****************************************************************************************************************************
 */
public class CS_TriggerFactory {
  /**
   * Public static method to create and execute a trigger handler
   *
   * Arguments:   Schema.sObjectType soType - Object type to process (SObject.sObjectType)
   *
   * Throws a TriggerException if no handler has been coded.
   */
  public static void createHandler(Schema.sObjectType soType)
  {
    // Get a handler appropriate to the object being processed
    CS_ITrigger handler = getHandler(soType);

    // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
    if (handler == null)
    {
      //throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
    }

    // Execute the handler to fulfil the trigger
    execute(handler);
  }

  /**
   * private static method to control the execution of the handler
   *
   * Arguments:   CS_ITrigger handler - A Trigger Handler to execute
   */
  private static void execute(CS_ITrigger handler)
  {
    // Before Trigger
    if (Trigger.isBefore)
    {
      // Call the bulk before to handle any caching of data and enable bulkification
      handler.bulkBefore();

      // Iterate through the records to be deleted passing them to the handler.
      if (Trigger.isDelete)
      {
        for (SObject so : Trigger.old)
        {
          handler.beforeDelete(so);
        }
      }
      // Iterate through the records to be inserted passing them to the handler.
      else if (Trigger.isInsert)
      {
        for (SObject so : Trigger.new)
        {
          handler.beforeInsert(so);
        }
      }
      // Iterate through the records to be updated passing them to the handler.
      else if (Trigger.isUpdate)
      {
        for (SObject so : Trigger.old)
        {
          handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
        }
      }
    }
    else
    {
      // Call the bulk after to handle any caching of data and enable bulkification
      handler.bulkAfter();

      // Iterate through the records deleted passing them to the handler.
      if (Trigger.isDelete)
      {
        for (SObject so : Trigger.old)
        {
          handler.afterDelete(so);
        }
      }
      // Iterate through the records inserted passing them to the handler.
      else if (Trigger.isInsert)
      {
        for (SObject so : Trigger.new)
        {
          handler.afterInsert(so);
        }
      }
      // Iterate through the records updated passing them to the handler.
      else if (Trigger.isUpdate)
      {
        for (SObject so : Trigger.old)
        {
          handler.afterUpdate(so, Trigger.newMap.get(so.Id));
        }
      }
    }

    // Perform any post processing
    handler.andFinally();
  }

  /**
   * private static method to get the appropriate handler for the object type.
   * Modify this method to add any additional handlers.
   *
   * Arguments:   Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
   *
   * Returns:     CS_ITrigger - A trigger handler if one exists or null.
   */
  private static CS_ITrigger getHandler(Schema.sObjectType soType)
  {
    if (soType == Case.sObjectType) {
      return new CS_CaseTriggerHandler();
    }
    if (soType == CS_Asset_Contact_Permissions__c.sObjectType) {
      return new CS_AssetContactTriggerHandler();
    }
    if (soType == Asset.sObjectType) {
      return new CS_AssetTriggerHandler();
    }
    if (soType == CS_Release__c.sObjectType) {
      return new CS_ReleaseTriggerHandler();
    }
    if (soType == CS_Request__c.sObjectType) {
      return new CS_RequestTriggerHandler();
    }
    if (soType == FeedItem.sObjectType) {
      return new CS_FeedItemTriggerHandler();
    }
    if (soType == emailmessage.sObjectType) {
      return new CS_EmailmessageTriggerHandler();
    }
    if (soType == ContentDocumentLink.sObjectType) {
      return new CS_ContentDocumentTriggerHandler();
    }
    if (soType == ServiceContract.sObjectType) {
      return new CS_ServiceContractTriggerHandler();
    }
    if (soType == ContractlineItem.sObjectType) {
      return new CS_ContractLineItemTriggerHandler();
    }
    if (soType == CaseComment.sObjectType) {
      return new CS_CaseCommentTriggerHandler();
    }
    if (soType == SBQQ__Quote__c.sObjectType) {
      return new CPQ_Quote_TriggerHandler();
    }
    if (soType == SBQQ__QuoteLine__c.sObjectType) {
      return new CPQ_QuoteLine_TriggerHandler();
    }
    if (soType == CPQ_Billing_Schedule__c.sObjectType) {
      return new CPQ_BillingSchedule_TriggerHandler();
    }

    return null;
  }
}
