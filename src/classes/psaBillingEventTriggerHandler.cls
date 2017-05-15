/**************************************************************************************
// Name          : psaBillingEventTriggerHandler
// Date          : March 8, 2015
// Description   : Handles all inserts/updates/deletes called by the psaBillingEvent trigger
// Author        : CLD Partners
// Revisions     : 2015-03-08  Klassen  Initial version
                   2015-05-14  Spano  updated to include attachment joining
                   2015-06-26  Klassen  updated to include CIM User field population
                   2015-09-08  ----- moved attachment logic future call to andFinally method
                   2015-09-27  Klassen  Removed all Expense Receipt Attachment Logic since
                        it's now being performed in the psaBillingEventRelease custom VF page
                   2016-03-07  Klassen  Add method to create a copy of Billing Event info
                        when a Released billing event is deleted
***************************************************************************************/
public with sharing class psaBillingEventTriggerHandler implements psaITriggerHandler {
    Map<Id, pse__Proj__c> projectMap;
    Set<Id> billingEventIdsToRefresh = new Set<Id>();
    Set<Id> accountDiscountIds = new Set<Id>();
    Map<Id, List<Attachment>> attachMap = new Map<Id, List<Attachment>>();
    List<pse__Billing_Event__c> billingEventsToArchive = new List<pse__Billing_Event__c>();

    public psaBillingEventTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore() {
        if(Trigger.isUpdate || Trigger.isInsert){
            System.debug('*** The update trigger!');
            Set<id> allEvents = new Set<id>();
            Set<id> projectIDs = new Set<id>();
            for(SObject so : Trigger.new){
                pse__Billing_Event__c next = (pse__Billing_Event__c)so;
                if(next.pse__Status__c == 'Released'){
                    projectIds.add(next.pse__Project__c);
                }
            }
            System.debug('Project ids: '+projectIds);
            projectMap = new Map<Id, pse__Proj__c>([Select id,PSA_Customer_Requires_Expense_Receipts__c from pse__proj__c where id in :projectIDs]);
            for(SObject so : Trigger.new){
                pse__Billing_Event__c next = (pse__Billing_Event__c)so;
                pse__Proj__c related = projectMap.get(next.pse__Project__c);
                System.debug('Related id: '+related);
                if(related != null && related.PSA_Customer_Requires_Expense_Receipts__c == true){
                    allEvents.add(next.id);
                }
            }
            System.debug('All events: '+allEvents);
        }

        //Populate the projectMap
        if(Trigger.isInsert) {
            // Define Set to hold Project Ids for each Billing Event
            Set<Id> projectIds = new Set<Id>();

            // Get list of Project Ids associated with each Billing Event
            for (SObject so : Trigger.new) {
                pse__Billing_Event__c billingEvent = (pse__Billing_Event__c)so;
                projectIds.add(billingEvent.pse__Project__c);
            }

            // SOQL to look up invoice-related fields from related Projects
            projectMap = new Map<Id, pse__Proj__c>(
                [SELECT Id, PSA_Billing_Detail_Template__c, PSA_Bill_To_Contact__c, PSA_Ship_To_Contact__c,
                        PSA_Customer_Requires_Expense_Receipts__c, PSA_CIM__r.pse__Salesforce_User__c
                     FROM pse__Proj__c
                    WHERE Id in : projectIds
                ]);
        
            //Schedule a job to link Billing Events with Prior Billing Events (Billing Event History)
            psaBillingHistory.scheduleLinkNewBEtoPriorBE();
        }

        //Populate a set of PSA Account Discount Ids that need to be updated
        if (Trigger.isDelete) {
            System.debug('BE Trigger Handler:bulkAfter:oldMap Keyset: ' + Trigger.oldMap.keySet());

            //If the billing event is related to a project that has a PSA Account Discount
            // associated with it, build a list of Account Discount Ids which will need to be updated
            List<pse__Billing_Event__c> billingEvents =
                [Select pse__Project__r.PSA_BR_Account_Discount__c
                    From pse__Billing_Event__c
                    Where Id = :Trigger.oldMap.keySet()
                    And pse__Project__r.PSA_BR_Account_Discount__c != null
                ];
            if (billingEvents != null && billingEvents.size() > 0) {
                for (pse__Billing_Event__c billingEvent : billingEvents) {
                    accountDiscountIds.add(billingEvent.pse__Project__r.PSA_BR_Account_Discount__c);
                }
            }
        }
    }

    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use
    //               this to cache any data required into maps prior to execution of the
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter(){}

    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        pse__Billing_Event__c billingEvent = (pse__Billing_Event__c)so;
        setDefaultValues(billingEvent);
    }

    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so) {
        pse__Billing_Event__c billingEventOld = (pse__Billing_Event__c)oldSo;
        pse__Billing_Event__c billingEventNew = (pse__Billing_Event__c)so;

        //If the billing event amount is changed or the billing event item count has changed
        // and the CIM Reviewed or PM Reviewed boxes are checked, uncheck them
        if (billingEventOld.PSA_Current_Billing_Amount__c != billingEventNew.PSA_Current_Billing_Amount__c ||
                    billingEventOld.PSA_Current_Billing_Event_Item_Count__c != billingEventNew.PSA_Current_Billing_Event_Item_Count__c) {
            if (billingEventNew.PSA_CIM_Reviewed__c == true) {
                billingEventNew.PSA_CIM_Reviewed__c = false;
            }
            if (billingEventNew.PSA_PM_Reviewed__c == true) {
                billingEventNew.PSA_PM_Reviewed__c = false;
            }
        }
        //System.debug('BE Trigger: ' + billingEventOld.Name + '-' + billingEventOld.PSA_Current_Billing_Amount__c + '-' + billingEventNew.PSA_Current_Billing_Amount__c);
        //System.debug('BE Trigger: ' + billingEventOld.Name + '-' + billingEventOld.PSA_Current_Billing_Event_Item_Count__c + '-' + billingEventNew.PSA_Current_Billing_Event_Item_Count__c);
    }

    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so) {
        pse__Billing_Event__c billingEvent = (pse__Billing_Event__c)so;
        billingEventIdsToRefresh.add(billingEvent.Id);
        if (billingEvent.pse__Is_Released__c == true) {
            System.debug('Released BE to be Archived: ' + billingEvent);
            billingEventsToArchive.add(billingEvent);
        }
    }

    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted
    //               during an AFTER trigger. Always put field validation in the 'After'
    //               methods in case another trigger has modified any values. The record
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){}

    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){}

    /**************************************************************************************
    // Name        : afterDelete
    // Description : This method is called iteratively for each record deleted
    //               during an AFTER trigger.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void afterDelete(SObject so){}

    /**************************************************************************************
    // Name        : andFinally
    // Description : This method is called once all records have been processed by the
    //               trigger. Use this method to accomplish any final operations such as
    //               creation or updates of other records.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void andFinally() {
        //If this is a released billing event that's being deleted, archive the Billing Event record
        if (billingEventsToArchive.size() > 0) {
            System.debug('Archiving Deleted Billing Event(s): ' + billingEventsToArchive);
            psaBillingHistory.copyBillingEvent(billingEventsToArchive);
        }

        //Delete all related PSA Project Balance records and update any Holdback Release
        // Misc. Adjs.
        if (billingEventIdsToRefresh.size() > 0) {
            System.debug('Billing Event Trigger Handler:andFinally - BE Ids: ' + billingEventIdsToRefresh);
            delete [Select Id From PSA_Project_Balance__c Where PSA_Billing_Event__c = :billingEventIdsToRefresh];
        }

        //Update PSA Account Discount, if applicable, to remove any eligible services to date
        // that came from these deleted Billing Events
        if (accountDiscountIds.size() > 0) {
            System.debug('Billing Event Trigger Handler:andFinally - PSA Account Discount Ids: ' + accountDiscountIds);
            psaRefreshProjectBillingBalances.updateAccountDiscountBalances(accountDiscountIds);
        }
    }

    /**************************************************************************************
    // Name        : setDefaultValues
    // Description : This method copies specific Billing-related values from the Project to
    //                  the Billing Event
    // Arguments   : pse__Billing_Event__c billingEvent - each BE record that is being inserted
    ***************************************************************************************/
    private void setDefaultValues(pse__Billing_Event__c billingEvent) {
        pse__Proj__c project = projectMap.get(billingEvent.pse__Project__c);
        if (project != null) {
            if (project.PSA_Billing_Detail_Template__c != null) {
                billingEvent.PSA_Billing_Detail_Template__c = project.PSA_Billing_Detail_Template__c;
            }
            billingEvent.PSA_Bill_To_Contact__c = project.PSA_Bill_To_Contact__c;
            billingEvent.PSA_Ship_To_Contact__c = project.PSA_Ship_To_Contact__c;
            billingEvent.PSA_CIM_User__c = project.PSA_CIM__r.pse__Salesforce_User__c;
        }
    }
}