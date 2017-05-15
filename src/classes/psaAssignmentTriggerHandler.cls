/**************************************************************************************
// Name          : psaAssignmentTriggerHandler
// Date          : March 4, 2015
// Description   : Handles all inserts/updates/deletes called by the psaAssignment trigger
// Author        : CLD Partners
// Revisions     : 2015-03-04  Klassen  Initial version
//				 : 2015-05-04  Klassen  Removed PSA Home Location fields since they will
//                  be pulled directly from the timecard related Contact record
//               
***************************************************************************************/
public with sharing class psaAssignmentTriggerHandler implements psaITriggerHandler {
	Map<Id, Contact> resourceMap;
    Map<Id, Id> projectToAccount;
    Map<Id, pse__Proj__c> projectMap;
    Map<Id, Map<String, List<psaRateLookup>>> rateBucket = new Map<Id, Map<String, List<psaRateLookup>>>();
    //List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
    Set<pse__Proj__c> uniqueProjects = new Set<pse__Proj__c>();
    Map<id, pse__Proj__c> projectsToUpdate = new Map<Id, pse__Proj__c>();
    Boolean needRateLookup = false;

	public psaAssignmentTriggerHandler() {}

   /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
    	//Populate the contactMap
    	if(trigger.isInsert || trigger.isUpdate || trigger.isDelete){
	        // Define Set to hold Resource IDs for each assignment
	        set<id> resourceIds = new set<id>();

	        // Get list of Resource Ids associated with each assignment, get old version of assignment if update
	        for (SObject so : trigger.new) {
	        	pse__Assignment__c assignment = (pse__Assignment__c)so;
                resourceIds.add(assignment.pse__Resource__c);
                if(trigger.isUpdate){
                    pse__Assignment__c oldAssignment = (pse__Assignment__c)Trigger.oldMap.get(assignment.Id);

                    // Determine if Rates need to be looked up
                    Boolean hasBillLevelChanged = (oldAssignment.PSA_Billing_Level__c != assignment.PSA_Billing_Level__c);
                    Boolean startChanged = assignment.PSE__Start_Date__c != oldAssignment.pse__Start_Date__c;
                    Boolean endChanged = assignment.PSE__End_Date__c != oldAssignment.pse__End_Date__c;
                    Boolean isClosed = assignment.pse__Status__c == 'Closed';
                    //Check start and end date as well pse__Start_Date__c
                    if(!isClosed && (hasBillLevelChanged || endChanged || startChanged) && assignment.PSA_Override_Bill_Rate__c == false){
                        needRateLookup = true;
                    }
                }
                if(trigger.isInsert && !assignment.PSA_Override_Bill_Rate__c){
                    needRateLookup = true;
                }
            }

            if(needRateLookup == true){
                // SOQL to look up Billing Level associated with each assignment's resource record
                resourceMap = new Map<Id, Contact>(
                [SELECT id, PSA_Billing_Level__c    
                     FROM Contact  
                     WHERE ID in : resourceIds
                ]);

                // Rate and Rate Cards Code...
                List<String> currencies = new List<String>();
                Set<Id> account_ids = new Set<Id>();
                Set<Id> project_ids = new Set<Id>();
                for(SObject so : Trigger.new){
                    pse__Assignment__c assignment = (pse__Assignment__c)so;
                    currencies.add(assignment.currencyIsoCode);
                    if(assignment.pse__Project__c != null){
                       project_ids.add(assignment.pse__Project__c);
                    }
                }

                projectMap = new Map<Id, pse__Proj__c>([SELECT ID,pse__Billing_Type__c,pse__Project_Type__c,psa_Project_Rate_Set__c,psa_Account_Rate_Set__c from pse__Proj__c where ID in :project_ids]);
                System.debug('Project map projects: '+projectMap.keySet());
                List<pse__proj__c> projects = [SELECT Id,pse__Account__c from pse__Proj__c where ID in :project_ids];
                projectToAccount = new Map<Id, Id>();
                for(pse__proj__c nextProj : projects){
                    account_ids.add(nextProj.pse__Account__c);
                    if(nextProj.pse__Account__c != null){
                        projectToAccount.put(nextProj.ID, nextProj.pse__Account__c);
                    }
                }

                rateBucket  = psaRateSetUtils.setRateBucket(account_ids, project_ids, currencies);
                System.debug('Rate bucket is: '+rateBucket);
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

    	if(needRateLookup == true)
        {
            pse__Assignment__c assignment = (pse__Assignment__c)so;
            System.debug('Before insert!');
            pse__Proj__c proj = projectMap.get(assignment.pse__Project__c);
            String type = proj.pse__project_Type__c;

            if(type == 'Customer Project'){
                if(!assignment.PSA_Override_Bill_Rate__c){
                    setBillingLevel(assignment);   
                    setBillingRate(assignment);
                    if(proj.pse__Billing_Type__c == 'Fixed Fee'){
                        assignment.pse__Bill_Rate__c = 0;
                    }
                }
            } 
        }

       /*if(type == 'Customer Project'){
            if(assignment.PSA_Billing_Level__c == null && assignment.PSA_Override_Bill_Rate__c == false){
                System.debug('Setting billing level!');
                setBillingLevel(assignment);    
            }
            if(assignment.pse__Resource_Request__c == null || assignment.pse__Resource_Request__c == ''
                && assignment.PSA_Override_Bill_Rate__c == false){
                System.debug('Setting the bill rate');
                setBillingRate(assignment);
            }
        }*/
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        
        if(needRateLookup == true)
        {
            pse__Assignment__c assignment = (pse__Assignment__c)so;
            pse__Assignment__c oldAssignment = (pse__Assignment__c)oldSo;
            pse__Proj__c proj = projectMap.get(assignment.pse__Project__c);

            Boolean isCustomer = (proj.pse__project_Type__c == 'Customer Project');
            Boolean hasBillLevelChanged = (oldAssignment.PSA_Billing_Level__c != assignment.PSA_Billing_Level__c);
            Boolean startChanged = assignment.PSE__Start_Date__c != oldAssignment.pse__Start_Date__c;
            Boolean endChanged = assignment.PSE__End_Date__c != oldAssignment.pse__End_Date__c;
            Boolean isClosed = assignment.pse__Status__c == 'Closed';
            Boolean needsChange = isCustomer && !isClosed && (hasBillLevelChanged || endChanged || startChanged);
           //Check start and end date as well pse__Start_Date__c
            if(needsChange){
                if(!assignment.PSA_Override_Bill_Rate__c){  
                    setBillingRate(assignment);
                    if(proj.pse__Billing_Type__c == 'Fixed Fee'){
                        assignment.pse__Bill_Rate__c = 0;
                    }
                }
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
    public void andFinally(){
        if(projectsToUpdate.values() != null && projectsToUpdate.size() > 0 ){
            System.debug('Updating projects to update');
            List<pse__Proj__c> toUpdate = projectsToUpdate.values();
            update toUpdate;
        }
    }

    /**************************************************************************************
    // Name        : setBillingLevel
    // Description : This method copies the Billing Level from the PSA Resource to the  
    //               Assignment
    // Arguments   : pse__Assignment__c assignment - each record that is being inserted
    ***************************************************************************************/
    private void setBillingLevel(pse__Assignment__c assignment) {
    	Contact resource = resourceMap.get(assignment.pse__Resource__c);
    	if (resource != null) {
            if (resource.PSA_Billing_Level__c != null) {
    		  assignment.PSA_Billing_Level__c = resource.PSA_Billing_Level__c;
            }
    	}
    }

    private void setBillingRate(pse__Assignment__c assignment){
        Boolean flagForReview = false;
        System.debug('Applying bill cost rates, flag is false');
        String whichRate = '';
        if(assignment.PSA_Billing_Level__c != null){
            // first try project...
            Map<String, List<psaRateLookup>> rateMap = rateBucket.get(assignment.pse__Project__c);
            if(rateMap != null){
                System.debug('Project Rate Set Check');
                boolean found = false;
                List<psaRateLookup> rates = rateMap.get(assignment.PSA_Billing_Level__c);
                if(rates != null){
                    for(psaRateLookup rate : rates){
                        System.debug('Checking rate: '+rate);
                        if((rate.Start == null || rate.Start <= assignment.pse__Start_Date__c) &&
                            (rate.EndDate == null || rate.EndDate >= assignment.pse__Start_Date__c)){
                            if(rate.CurrencyIsoCode == assignment.currencyIsoCode){
                                found = true;
                                System.debug('Rate used is: '+rate);
                                pse__Proj__c project = projectMap.get(assignment.pse__Project__c);
                                //pse__Proj__c toChange = project.clone(true, true, true, true);
                                if(project != null && project.PSA_Project_Rate_Set__c == null){
                                    pse__Proj__c existing = projectsToUpdate.get(project.id);
                                    if(existing == null){
                                        existing = project.clone(true, true, true, true);
                                    }
                                    existing.psa_Project_Rate_Set__c = rate.rateSetId;
                                    projectsToUpdate.put(existing.id, existing);
                                }
                                Double billRate = rate.BillRate;
                                assignment.pse__Bill_Rate__c = billRate;
                                assignment.PSA_Rate_Set__c = rate.RateSetId;
                                System.debug(assignment);
                            }
                        }
                    }
                }
                if(!found){
                    rateMap = null;
                }
                
            }
            if(rateMap == null){
                boolean found = false;
                Id accountId = projectToAccount.get(assignment.pse__Project__c);
                if(accountId != null){
                    // try Account next
                    rateMap = rateBucket.get(projectToAccount.get(assignment.pse__Project__c));
                    if(rateMap != null){
                        List<psaRateLookup> rates = rateMap.get(assignment.PSA_Billing_Level__c);
                        if(rates != null){
                            for(psaRateLookup rate : rates){
                                System.debug('Checking rate: '+rate);
                                if((rate.Start == null || rate.Start <= assignment.pse__Start_Date__c) &&
                                (rate.EndDate == null || rate.EndDate >= assignment.pse__Start_Date__c)){
                                    if(rate.CurrencyIsoCode == assignment.currencyIsoCode){
                                        System.debug('Rate used is: '+rate);
                                        found = true;
                                        pse__Proj__c project = projectMap.get(assignment.pse__Project__c);
                                        if(project != null && project.PSA_Account_Rate_Set__c == null){
                                            pse__Proj__c existing = projectsToUpdate.get(project.id);
                                            if(existing == null){
                                                existing = project.clone(true, true, true, true);
                                            }
                                            existing.psa_Account_Rate_Set__c = rate.rateSetId;
                                            projectsToUpdate.put(existing.id, existing);
                                        }
                                        Double billRate = rate.BillRate;
                                        assignment.pse__Bill_Rate__c = billRate;
                                        assignment.PSA_Rate_Set__c = rate.RateSetId;
                                        System.debug(assignment);
                                    }
                                }
                            }
                        }
                    }
                }
                if(!found){
                    rateMap = null;
                }
            }

            if(rateMap == null){
                // default to org bill rates
                flagForReview = true;
                rateMap = rateBucket.get(null);
                if(rateMap != null){
                    List<psaRateLookup> rates = rateMap.get(assignment.PSA_Billing_Level__c);
                    if(rates != null){
                        for(psaRateLookup rate : rates){
                            System.debug('Checking rate: '+rate);
                            if((rate.Start == null || rate.Start <= assignment.pse__Start_Date__c) &&
                                (rate.EndDate == null || rate.EndDate >= assignment.pse__Start_Date__c)){
                                if(rate.CurrencyIsoCode == assignment.currencyIsoCode){
                                    Double billRate = rate.BillRate;
                                    assignment.pse__Bill_Rate__c = billRate;
                                    assignment.PSA_Rate_Set__c = rate.RateSetId;
                                    System.debug(assignment);
                                }
                            }
                        }
                    }
                }
            }

            assignment.PSA_Rate_Needs_Review__c = flagForReview;
            //added by cklassen 5/14 3pm b/c unable to create assignment from project
            // validation rule fired saying if rate needs review, then closed for time entry must be true
            if (flagForReview) {
                assignment.pse__Closed_for_Time_Entry__c = true;
            }
        }   
        System.debug('Still here and PTU is: '+projectsToUpdate);
        
    }
}