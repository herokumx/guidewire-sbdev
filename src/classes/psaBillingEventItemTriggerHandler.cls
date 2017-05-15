/**************************************************************************************
// Name          : psaBillingEventItemTriggerHandler
// Date          : March 6, 2015
// Description   : Handles all inserts/updates/deletes called by the psaBillingEventItem trigger
// Author        : CLD Partners
// Revisions     : 2015-03-06  Klassen  Initial version
//				 : 
***************************************************************************************/
public with sharing class psaBillingEventItemTriggerHandler implements psaITriggerHandler {
	List<pse__Miscellaneous_Adjustment__c> miscAdjToDeleteList;
    Set<Id> projectIds = new Set<Id>();

	public psaBillingEventItemTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter(){
    	//Populate the contactMap
    	if(Trigger.isDelete) {
	        // Define Set to hold Misc. Adj. IDs for each billing event item
	        Set<Id> miscAdjIds = new Set<Id>();

	        // Get list of Misc. Adj. Ids associated with each billing event item
	        pse__Billing_Event_Item__c bei;
	        for (SObject so : Trigger.old) {
	        	bei = (pse__Billing_Event_Item__c)so;
	        	if (bei.pse__Miscellaneous_Adjustment__c != null) {
	        		miscAdjIds.add(bei.pse__Miscellaneous_Adjustment__c);
	        	}
	        }
	        System.debug('BEI Trigger - bulkAfter: Misc Adj Ids:'+miscAdjIds);

	        // SOQL to get a list of Misc. Adj. Ids to delete
	        miscAdjToDeleteList = 
	        	[SELECT Id, Name, pse__Project__c, PSA_Billing_Rule_Type__c, pse__Amount__c, 
                        PSA_BR_Eligible_Discount_Amount__c 
                     FROM pse__Miscellaneous_Adjustment__c  
                     WHERE Id =: miscAdjIds
                     AND PSA_Created_By_Billing_Rule__c = true
                     AND PSA_Billing_Rule_Type__c != 'Services Charge - Holdback Release' 
                ];
            System.debug('BEI Trigger - bulkAfter: Misc Adj List bulkAfter:'+miscAdjToDeleteList);
    	}    	
    }
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        System.debug('Nothing to do');
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        System.debug('Nothing to do');
    }
 
    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so){
        System.debug('Nothing to do');
    }
 
    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted 
    //               during an AFTER trigger. Always put field validation in the 'After' 
    //               methods in case another trigger has modified any values. The record 
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so){
        System.debug('Nothing to do');
    }
 
    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated 
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){
        System.debug('Nothing to do');
    }
 
    /**************************************************************************************
    // Name        : afterDelete
    // Description : This method is called iteratively for each record deleted 
    //               during an AFTER trigger.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void afterDelete(SObject so) {
        pse__Billing_Event_Item__c beItem = (pse__Billing_Event_Item__c)so;
        projectIds.add(beItem.pse__Project__c);
    }
 
    /**************************************************************************************
    // Name        : andFinally
    // Description : This method is called once all records have been processed by the 
    //               trigger. Use this method to accomplish any final operations such as
    //               creation or updates of other records.
    // Arguments   : SObject so - the object that initiated the trigger
    ***************************************************************************************/
    public void andFinally() {
    	//If there are any Misc. Adjs. to be deleted, update any related holdback release
        // misc. adjs. and then delete the misc. adjs.
        if (miscAdjToDeleteList.size() > 0) {
            System.debug('BEI Trigger - andFinally: About to update any related holdback releases and then delete Misc Adjs:' + miscAdjToDeleteList);
            updateHoldbackReleaseAdjustments(miscAdjToDeleteList, projectIds);
            delete miscAdjToDeleteList;
	    }
    }

    /**************************************************************************************
    // Name        : updateHoldbackReleaseAdjustments
    // Description : This method updates any related Holdback Release Misc. Adjs
    // Arguments   : Set<Id> billingEventIds - each BE Id that is being deleted
    ***************************************************************************************/
    private void updateHoldbackReleaseAdjustments(List<pse__Miscellaneous_Adjustment__c> miscAdjs, 
            Set<Id> projectIds) {
        //Initialize list of holdback release misc. adjs. to update
        List<pse__Miscellaneous_Adjustment__c> miscAdjsToUpdate = new List<pse__Miscellaneous_Adjustment__c>();

        //Use the psaBillingRulesApplication class to check for an existing holdback release in 
        // the list of miscAdjsToUpdate 
        //Use the psaBillingRulesApplication class to get a map of holdback release Misc. Adjs.
        psaBillingRulesApplication psaBillingRulesApp = new psaBillingRulesApplication();
        Map<Id, pse__Miscellaneous_Adjustment__c> holdbackReleaseMap = psaBillingRulesApp.getHoldbackReleaseMiscAdjByProjectMap(projectIds);
        pse__Miscellaneous_Adjustment__c holdbackReleaseMiscAdj;

        //Loop through each misc. adj. checking to see if we have any for Holdback
        for (pse__Miscellaneous_Adjustment__c miscAdj : miscAdjs) {
            if (miscAdj.PSA_Billing_Rule_Type__c == 'Services Credit - Holdback') {
                System.debug('BEI Trigger - updateHoldbackReleaseAdjustments: Found holdback misc adj: ' + miscAdj);

                holdbackReleaseMiscAdj = psaBillingRulesApp.getHoldBackReleaseMiscAdjForProject(miscAdjsToUpdate, miscAdj.pse__Project__c);
                if (holdbackReleaseMiscAdj != null) {
                    holdbackReleaseMiscAdj.pse__Amount__c += miscAdj.pse__Amount__c;
                    holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c += miscAdj.PSA_BR_Eligible_Discount_Amount__c;
                    System.debug('BEI Trigger - updateHoldbackReleaseAdjustments: Updated existing holdback release misc adj in miscAdjsToUpdate: ' + holdbackReleaseMiscAdj);
                } else {
                    //Find the corresponding holdback release misc adj from the map and decrement it by the holdback amount
                    holdbackReleaseMiscAdj = holdbackReleaseMap.get(miscAdj.pse__Project__c);
                    System.debug('BEI Trigger - updateHoldbackReleaseAdjustments: Holdback Release Misc Adj: ' + holdbackReleaseMiscAdj);
                    if (holdbackReleaseMiscAdj != null) {
                        holdbackReleaseMiscAdj.pse__Amount__c += miscAdj.pse__Amount__c;
                        holdbackReleaseMiscAdj.PSA_BR_Eligible_Discount_Amount__c += miscAdj.PSA_BR_Eligible_Discount_Amount__c;
                        miscAdjsToUpdate.add(holdbackReleaseMiscAdj);
                    }                    
                }
            }
        }

        //DML
        System.debug('BEI Trigger - updateHoldbackReleaseAdjustments: Holdback Release Misc. Adjs To Update: ' + miscAdjsToUpdate);
        if (miscAdjsToUpdate.size() > 0) {
            update miscAdjsToUpdate;
        }
    }
}