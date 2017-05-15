/**************************************************************************************
// Name          : psaContactTriggerHandler
// Date          : March 4, 2015
// Description   : Handles all inserts/updates/deletes called by the psaContact trigger
//                 Includes creating/updating Resources and Salesforce Users
// Author        : CLD Partners
// Revisions     : 2015-03-04   Schwartz    Initial version
//               : 2015-04-09   Klassen     Add logic for Workday Integration
***************************************************************************************/
public with sharing class psaContactTriggerHandler implements psaITriggerHandler{
	public psaContactTriggerHandler() {}

    List<PSA_Cost_Rate__c> costRates;
    List<pse__Assignment__c> assignments;
    List<pse__Assignment__c> assignmentsToUpdate;
    Map<String, PSA_PS_Level_Billing_Level__c> psLevelBillLevelMap = new Map<String, PSA_PS_Level_Billing_Level__c>();
	Map<Id,Boolean> checkPSdepartmentMap = new Map<Id,Boolean>();

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
        //Load the PSA Cost Rates list
        costRates = psaCostRates.loadCostRates();

        // Load the PS Level Bill Level map
        List<PSA_PS_Level_Billing_Level__c> psLevelBillLevelList = 
            [Select PSA_PS_Level__c, PSA_Billing_Level__c
                From PSA_PS_Level_Billing_Level__c
            ];
        for (PSA_PS_Level_Billing_Level__c psLevelBillLevel : psLevelBillLevelList) {
            psLevelBillLevelMap.put(psLevelBillLevel.PSA_PS_Level__c, psLevelBillLevel);
        }

		List<PSA_Department__c> departnemntlList = 
            [Select Id, PSA_PS_Department__c
                From PSA_Department__c
            ];
         
		 for(PSA_Department__c dep: departnemntlList){
		   checkPSdepartmentMap.put(dep.Id, dep.PSA_PS_Department__c);
		 }
    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter() {}
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods. 
    ***************************************************************************************/
    public void beforeInsert(SObject so) { 
        Contact cont = (Contact)so;
        
        //Set Resource Review Status multi-select picklist
        setResourceReviewStatus(cont, 'New Resource');
        if (cont.PSA_Termination_Date__c != null) {
            setResourceReviewStatus(cont, 'Termination');
        }
        if (cont.PSA_Absence_Start_Date__c != null || cont.PSA_Absence_End_Date__c != null) {
            setResourceReviewStatus(cont, 'Leave of Absence');
        }

        //Set the Billing Level
        setBillingLevel(cont, true);

        //Set the PSA Cost Rates
        // If the Resource Global Mobile flag = true, set the cost rate needs review flag
        if (cont.PSA_Global_Mobile__c == true) {
            cont.PSA_Cost_Rate_Needs_Review__c = true;
        } else {
            if (psaCostRates.setResourceCostRates(cont, costRates) == false) {
                cont.PSA_Cost_Rate_Needs_Review__c = true;
            }
        }
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
		Contact contact_old = (Contact)oldSo;
		Contact contact_new = (Contact)so;

        //BEGIN Set the Resource Review Status
        //TODO-1.x: revise logic to to only set this value if specific "key" fields have changed 
        setResourceReviewStatus(contact_new, 'Updated Resource');
        //Transfer Out logic (Rohit- correction in logic to get parent field)
   //     if (contact_new.PSA_Resource_Department__c != contact_old.PSA_Resource_Department__c && contact_new.PSA_Resource_Department__r.PSA_PS_Department__c != true) {
        if (contact_new.PSA_Resource_Department__c != contact_old.PSA_Resource_Department__c &&  (contact_new.PSA_Resource_Department__c == null || (checkPSdepartmentMap.get(contact_new.PSA_Resource_Department__c) != null &&  !checkPSdepartmentMap.get(contact_new.PSA_Resource_Department__c)))) {
            setResourceReviewStatus(contact_new, 'Transfer Out');
        }
        //Termination logic
        if (contact_new.PSA_Termination_Date__c != null && contact_new.PSA_Termination_Date__c != contact_old.PSA_Termination_Date__c) {
            setResourceReviewStatus(contact_new, 'Termination');
        }
        //Leave of Absence logic
        if (
                (contact_new.PSA_Absence_Start_Date__c != null && contact_new.PSA_Absence_Start_Date__c != contact_old.PSA_Absence_Start_Date__c) 
                ||
                (contact_new.PSA_Absence_End_Date__c != null && contact_new.PSA_Absence_End_Date__c != contact_old.PSA_Absence_End_Date__c) 
           ) {
            setResourceReviewStatus(contact_new, 'Leave of Absence');
        }
        //END Set the Resource Review Status

        //Set the Billing Level (if the PS Level has changed)
        if (contact_new.PSA_PS_Level__c != contact_old.PSA_PS_Level__c) {
            setBillingLevel(contact_new, true);
        }

        //Set the Cost Rates if not global mobile and either ps level, department, and/or entity has changed
		// If the Resource is updated with Global Mobile = true, set the cost rate needs review flag
        if (contact_new.PSA_Global_Mobile__c == true && contact_new.PSA_Global_Mobile__c != contact_old.PSA_Global_Mobile__c) {
            contact_new.PSA_Cost_Rate_Needs_Review__c = true;
        } else if(contact_new.PSA_Global_Mobile__c != true && (
            contact_new.PSA_PS_Level__c != contact_old.PSA_PS_Level__c ||
		     contact_new.PSA_Resource_Department__c != contact_old.PSA_Resource_Department__c ||
		     contact_new.PSA_Resource_Entity__c != contact_old.PSA_Resource_Entity__c) ) {
			if (psaCostRates.setResourceCostRates(contact_new, costRates) == false) {
                contact_new.PSA_Cost_Rate_Needs_Review__c = true;
            }
        }
    }
 
    /**************************************************************************************
    // Name        : beforeDelete
    // Description : This method is called iteratively for each record to be deleted 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeDelete(SObject so){}
 
    /**************************************************************************************
    // Name        : afterInsert
    // Description : This method is called iteratively for each record inserted 
    //               during an AFTER trigger. Always put field validation in the 'After' 
    //               methods in case another trigger has modified any values. The record 
    //               is 'read only' by this point.
    ***************************************************************************************/
    public void afterInsert(SObject so) {}
 
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
    public void andFinally() {}

    /**************************************************************************************
    // Name         : setResourceReviewStatus 
    // Description  : Update the resource review status
    //                  to include the value passed in to the method.
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private void setResourceReviewStatus(Contact cont, String valueToAdd) {
        if (cont.PSA_Resource_Review_Status__c == null) {
            cont.PSA_Resource_Review_Status__c = valueToAdd;
        } else if (cont.PSA_Resource_Review_Status__c.contains(valueToAdd) == false) {
            cont.PSA_Resource_Review_Status__c += ';' + valueToAdd;
        }
    }

    /**************************************************************************************
    // Name         : setBillingLevel 
    // Description  : If the criteria used to set the Billing Level for a resource has changed, 
    //                 or if this is a new resource, set the Resource's Billing Level
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private void setBillingLevel(Contact resource, Boolean newResource) {
        System.debug('Contact PS Level/Billing Level: ' + resource.PSA_PS_Level__c + '/' + resource.PSA_Billing_Level__c);

        PSA_PS_Level_Billing_Level__c psLevelBillLevel;
        psLevelBillLevel = psLevelBillLevelMap.get(resource.PSA_PS_Level__c);
        if (psLevelBillLevel != null && resource.PSA_PS_Level__c != null) {
            resource.PSA_Billing_Level__c = psLevelBillLevel.PSA_Billing_Level__c;
        } else {
            if (newResource == true && resource.PSA_Billing_Level__c != null) {
                resource.PSA_Billing_Level__c = null;
            }
            //Set the Resources
            String logMessage = 'Failed to Set Billing Level for PS Level: ' + resource.PSA_PS_Level__c + 
                ' for Worker Id: ' + resource.PSA_Worker_Id__c;
            System.debug(logMessage);
            //Removed custom exception at request of Dinakar during implementation 5/4/15
            //Throw new psaException(logMessage);
        }
    }	

}