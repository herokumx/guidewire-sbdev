/**************************************************************************************
// Name          : psaTriggerHandlerFactory
// Date          : February 4, 2015
// Description   : Factory class that selects and calls the appropriate trigger handler
//                 Based on the recipe from:
//                 http://developer.force.com/cookbook/recipe/trigger-pattern-for-tidy-streamlined-bulkified-triggers
// Author        : CLD Partners
// Revisions     : 2015-02-04  Schwartz   Initial version
***************************************************************************************/
public with sharing class psaTriggerHandlerFactory
{
    // Instance member variable to store the map key
    private static string key = '';

    // Static variable to store Trigger_Handler__c custom setting field names - used to determine if a
    // custom setting exists before querying the database
    private static boolean fieldNameSetInitialized = false;
    private static set<string> customSettingFieldNames = null;

    /**************************************************************************************
    // Name        : createHandler
    // Description : Public static method to create and execute a trigger handler
    // Arguments   : Schema.sObjectType soType - Object type to process (SObject.sObjectType)
    // Throws      : Throws a TriggerHandlerException if no handler has been coded.
    // Assumptions :
    ***************************************************************************************/
    public static void createHandler(Schema.sObjectType soType)
    {
        // Get a handler appropriate to the object being processed
        psaITriggerHandler handler = getHandler(soType);

        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if (handler == null)
        {
            throw new psaTriggerHandlerException('No Trigger Handler registered for Object Type: ' + soType);
        }

        System.Debug('SO Type value:'+soType);

        //*** Determine whether or not to execute the handler based on the PSA Triggers custom settings object
        // Build the map key
        key  = soType.getDescribe().getName();    // Includes namespace and __c as appropriate
        key  = key.replace('__', '_');            // Remove double underscore
        key += trigger.isBefore ? '_B' : '_A';
        key += trigger.isInsert ? 'I' : (trigger.isUpdate ? 'U' : (trigger.isDelete ? 'D' : 'Un'));

        Boolean enableHandler = isEnabled();
        if (enableHandler == true) {
            //System.Debug('Handler not Disabled='+ soType + ': Key='+key);
            execute(handler);
        } else {
            System.Debug('Handler Disabled='+ soType + ': Key='+key);
        }
    }

    /**************************************************************************************
    // Name        : execute
    // Description : Private static method to control the execution of the handler
    // Arguments   : psaITriggerHandler handler - A Trigger Handler to execute
    // Assumptions :
    ***************************************************************************************/
    private static void execute(psaITriggerHandler handler)
    {
        System.Debug('Executing trigger handler.');

        // Before Trigger
        if (trigger.isBefore)
        {
            System.debug('MONITOR: Trigger is calling bulkbefore');
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore();

            // Iterate through the records to be deleted passing them to the handler.
            if (trigger.isDelete)
            {
                for (SObject so : trigger.old)
                {
                    handler.beforeDelete(so);
                }
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if (trigger.isInsert)
            {
                for (SObject so : trigger.new)
                {
                    handler.beforeInsert(so);
                }
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (trigger.isUpdate)
            {
                for (SObject so : trigger.old)
                {
                    handler.beforeUpdate(so, trigger.newMap.get(so.Id));
                }
            }
        }
        else
        {
            System.debug('MONITOR: Trigger is calling bulkAfter');
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter();

            // Iterate through the records deleted passing them to the handler.
            if (trigger.isDelete)
            {
                for (SObject so : trigger.old)
                {
                    handler.afterDelete(so);
                }
            }
            // Iterate through the records inserted passing them to the handler.
            else if (trigger.isInsert)
            {
                for (SObject so : trigger.new)
                {
                    handler.afterInsert(so);
                }
            }
            // Iterate through the records updated passing them to the handler.
            else if (trigger.isUpdate)
            {
                for (SObject so : trigger.old)
                {
                    handler.afterUpdate(so, trigger.newMap.get(so.Id));
                }
            }
        }

        System.debug('MONITOR: Calling andFinally');

        // Perform any post processing
        handler.andFinally();


    }

    /**************************************************************************************
    // Name        : getHandler
    // Description : Private static method to get the appropriate handler for the object
    //               type. Modify this method to add any additional handlers.
    // Arguments   : Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
    // Returns     : psaITriggerHandler - A trigger handler if one exists or null.
    // Assumptions :
    ***************************************************************************************/
    private static psaITriggerHandler getHandler(Schema.sObjectType soType)
    {
        // Sort the list alphabetically so it's easier to determine if a handler has been added to the factory


        if (soType == pse__Assignment__c.sObjectType)
        {
            return new psaAssignmentTriggerHandler();
        }
        else if (soType == pse__Billing_Event__c.sObjectType)
        {
            return new psaBillingEventTriggerHandler();
        }
        else if (soType == pse__Billing_Event_Item__c.sObjectType)
        {
            return new psaBillingEventItemTriggerHandler();
        }
        else if (soType == Contact.sObjectType){
            return new psaContactTriggerHandler();
        }
        else if (soType == pse__Proj__c.sObjectType)
        {
            return new psaProjectTriggerHandler();
        }
        else if (soType == pse__Resource_Request__c.sObjectType)
        {
            return new psaResourceRequestTriggerHandler();
        }
        else if (soType == pse__Timecard_Header__c.sObjectType)
        {
            return new psaTimecardHeaderTriggerHandler();
        }
        //else if (soType == PSA_Account_Discount__c.sObjectType){
        //    return new psaAccountDiscountTriggerHandler();
        //}
        else if (soType == PSA_Resource_Stage__c.sObjectType){
            return new psaResourceStageTriggerHandler();
        }
        else if (soType == PSA_Billing_Stage__c.sObjectType){
            return new psaBillingStageTriggerHandler();
        }
        else if (soType == PSA_Expense_Stage__c.sObjectType){
            return new psaExpenseStageTriggerHandler();
        }
        else if (soType == PSA_Time_Off_Stage__c.sObjectType){
            return new psaTimeOffStageTriggerHandler();
        }
        else if (soType == pse__Expense__c.sObjectType){
            return new psaExpenseTriggerHandler();
        }
        else if (soType == pse__Expense_Report__c.sObjectType){
            return new psaExpenseReportTriggerHandler();
        }
        else if(soType == Attachment.sObjectType){
            return new psaAttachmentTriggerHandler();
        }
        else if(soType == pse__Time_Date__c.sObjectType){
            return new psaTimeDateTriggerHandler();
        }
        else if(soType == PSA_Rate_Set__c.sObjectType){
            return new psaRateSetTriggerHandler();
        }
        else if(soType == PSA_Card_Transaction_Item__c.sObjectType){
            return new psaCardTransactionItemTriggerHandler();
        }
        else if(soType == PSA_Card_Transaction__c.sObjectType){
            return new psaCardTransactionTriggerHandler();
        }

/*
        else if (soType == pse__Milestone__c.sObjectType)
        {
            return new psaMilestoneTriggerHandler();
        }
        else if (soType == pse__Miscellaneous_Adjustment__c.sObjectType)
        {
            return new psaMiscAdjustmentTriggerHandler();
        }
*/
        return null;
    }

    /************************************************************************************************************
    // Name         isEnabled
    // Description  Standard implementation of the ITriggerHandler.isEnabled() interface method.
    //              This method uses the custom setting "Trigger_Handlers__c" to programmatically enable and
    //              disable trigger handling. To disable a specific handler...
    //
    //                  1. Create the Trigger_Handlers__c custom setting if it does not already exist.
    //                     The custom setting type is "List". Create a single instance of the setting. The
    //                     instance name is not important.
    //
    //                  2. Add a checkbox field the the Trigger_Handlers__c custom setting of the form:
    //
    //                          'Disable_<object name>_<trigger timing><trigger type>__c'
    //
    //                              examples: Disable_Contact_BI__c
    //                                        Disable_Account_AU__c
    //                                        Disable_pse_Proj_c_AD__c
    //                                        Disable_As_Sold_Role_c_BU__c      <-- update trigger
    //                                        Disable_Opportunity_BUn__c        <-- undelete trigger
    //
    //                     (Note that double underscores after namespaces and before the custom suffix
    //                      are converted to single underscores for the custom setting field name.)
    //
    //                  3. Set the checkbox field value to true to disable the trigger handler and false
    //                     to enable the trigger handler.
    //
    //              The TriggerHandlerFactory class will call this method before executing the handler to
    //              determine if the handler should run.
    //
    //              NOTE: It is not necessary to create a field for every event for every trigger handler in
    //              the system. Nor is it necessary to even create the custom setting until you are ready to
    //              disable a handler via a custom setting.
    //
    // Returns:     If the custom setting "Trigger_Handlers__c" does not exist or the specific handler field
    //              does not exist, this method will return true by default. Otherwise, this method returns
    //              the checkbox state of the field corresponding to the trigger handler key for this execution
    //              context.
    *************************************************************************************************************/
    public static boolean isEnabled()
    {
        // Cobble the standard custom setting disable field API name
        string fieldName = 'Disable_' + key;

        if (fieldName.length() > 40)
        {
            fieldName = fieldName.left(40);
        }

        fieldName += '__c';

        // Get the custom setting value
        list<SObject> soList = safeQueryCustomSettingField(fieldName);

        // Check if the custom setting and corresponding disable field exist
        if (soList != null && soList.size() > 0 && soList[0].get(fieldName) != null)
        {
            // Pull the value out of the result using the field API name; convert to string to avoid
            // issues with field types on the custom setting
            string disabled = string.valueOf(soList[0].get(fieldName));

            // If the trigger handler is marked as disabled, return false (not enabled)
            if (disabled.equalsIgnoreCase('true'))
            {
                return false;
            }
        }

        // Not disabled or custom setting/field not defined --> return true by default
        return true;
    }

    /************************************************************************************************************
    // Name         safeQueryCustomSettingField
    // Description  Helper method that safely queries a field on the Trigger_Handlers__c custom setting. This
    //              method first checks that the custom setting and field both exist before issuing the query
    //              and returning the query results. A return value of null means the custom setting or the field
    //              do not exist.
    *************************************************************************************************************/
    private static list<SObject> safeQueryCustomSettingField(string fieldName)
    {
        list<SObject> soList = null;

        // Get the Trigger_Handlers__c custom setting describe information; avoid governor limits by caching
        // the field names in a private static variable
        if (fieldNameSetInitialized == false)
        {
            map<string, Schema.SObjectType> sotMap = Schema.getGlobalDescribe();
            Schema.SObjectType sot = sotMap.get('PSA_Triggers__c');

            // Determine if the custom setting exists in this org
            if (sot != null)
            {
                // Custom setting exists in this org, now get the list of existing field names on the custom setting
                Schema.DescribeSObjectResult dsor = sot.getDescribe();
                customSettingFieldNames = dsor.fields.getMap().keySet();
            }

            fieldNameSetInitialized = true;
        }

        // Check if the custom setting and corresponding field exist (note: the field names returned
        // by the system are in lower case. The set.contains() method is case sensitive for sets of strings.)
        if (customSettingFieldNames != null && customSettingFieldNames.contains(fieldName.toLowerCase()))
        {
            // Query the setting
            string qs = 'SELECT ' + fieldName + ' FROM PSA_Triggers__c';
            soList = database.query(qs);
        }

        return soList;
    }
}