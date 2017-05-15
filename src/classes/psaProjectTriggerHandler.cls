/**************************************************************************************
// Name          : psaAccountDiscountTriggerHandler
// Date          : March 1, 2015
// Description   : Handles all inserts/updates/deletes called by the psaAccountDiscount trigger
//                 Includes updating Discount Billing Levels on the Project, 
//                  since a Multi-select picklist field cannot be used in a Formula.
// Author        : CLD Partners
// Revisions     : 2015-03-01   Schwartz    Initial version 
//               : 2015-04-08   Klassen     Added setAccountDiscountBillingLevels method
//               : 2015-04-27   Klassen     Fix bug with soql query in for loop (pm_contacts)
//                                          and code refactor for project location creation
                 : 2015-05-04   Spano       Changed code logic to stop utilizing Sites and PSA_Location objects. Now uses
                                            Account BillingAddress fields to set Project Locaiton address fields.
                                            TBD: Whether to use the Account Contact Record instead
                 : 2015-07-08   Mayfield    Modified to remove postal code from project locations
                 : 2015-07-10   Mayfield    Modified to pull project locations for all project types,
                                            commented out several debug statements to reduce log size
                 : 2015-07-13   Mayfield    Added if statement to prevent checking change in start date if its null 
                 : 2015-07-14   Klassen     Add null check to RR and Assignment Lists when shifting dates if Project start date shifts
				 : 2016-12-06   Spano	    Add new code to change the PM user on associated billing events when the project manager changes
***************************************************************************************/
public with sharing class psaProjectTriggerHandler implements psaITriggerHandler  {
    
    Map<Id, Id> pm_resource_sfdcUserMap = new Map<Id, Id>();
    Map<Id, pse__Proj__c> projectDatesUpdated = new Map<Id, pse__Proj__c>();
    Map<Id, List<pse__Resource_Request__c>> resReqMap = new Map<Id, List<pse__Resource_Request__c>>();
    Map<Id, List<pse__Assignment__c>> assignmentMap = new Map<Id, List<pse__Assignment__c>>();
    Map<Id, pse__Schedule__c> assignmentToSched = new Map<Id, pse__Schedule__c>();

    List<pse__Project_Location__c> projLocations = new List<pse__Project_Location__c>();
    List<pse__Billing_Event__c> besToUpdate = new List<pse__Billing_Event__c>();
    List<Id> projToAddLocations = new List<Id>();
    List<pse__Resource_Request__c> rrtoUpdate = new List<pse__Resource_Request__c>();
    List<pse__Assignment__c> assignToUpdate = new List<pse__Assignment__c>();
    List<pse__Project_Location__c> locationsUpdate = new List<pse__Project_Location__c>();
    List<pse__Schedule__c> schedToUpdate = new List<pse__Schedule__c>();
    Map<Id, List<PSA_Implementer__c>> impMap = new Map<Id, List<PSA_Implementer__c>>();
    Map<Id, List<pse__Billing_Event__c>> beMap = new Map<Id, List<pse__Billing_Event__c>>();
    Map<Id, pse__Proj__c> newProjMap = new Map<Id, pse__Proj__c>();

    //Spano update 5/4
    Map<Id, Account> accounts = new Map<Id, Account>();
    Map<Id, List<Account>> childAccounts = new Map<Id, List<Account>>();

    Set<String> addressesAdded = new Set<String>();
    public psaProjectTriggerHandler(){}

    /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
        /*
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaProjectTriggerHandler')) {
            System.debug('Skipping psaProjectTriggerHandler bulkBefore method due to trigger recursion prevention');
            return;
        }
        */

        Set<Id> psaAccountDiscountIds = new Set<Id>();
        Set<Id> pm_ids = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        for(SObject so : trigger.new){
            pse__Proj__c proj = (pse__Proj__c)so;
            projectIds.add(proj.id);
            // Get a cross ref of pm to sfdc user...
            if (proj.pse__Project_Manager__c != null) {
                pm_ids.add(proj.pse__Project_Manager__c);
            }     

        }

        List<PSA_Implementer__c> implementers = [Select id,psa_Project__c from PSA_Implementer__c where psa_Project__c in :projectIds];
        if(implementers != null && implementers.size() > 0){
            for(PSA_Implementer__c imp : implementers){
                List<PSA_Implementer__c> imps = impMap.get(imp.psa_Project__c);
                if(imps == null){
                    imps = new List<PSA_Implementer__c>();
                }
                imps.add(imp);
                impMap.put(imp.psa_project__c, imps);
            }
        }

        //BEGIN Modified by cklassen 4/27/15 - Move soql outside of for loop
        List<Contact> pm_contacts = new List<Contact>();
        if (pm_ids.size() > 0) {
            pm_contacts = 
                [SELECT Id, pse__Salesforce_User__c 
                    FROM CONTACT
                    WHERE Id IN : pm_ids
                ];
        }
        //Populate the resource/user map
        if (pm_contacts != null && pm_contacts.size() > 0) {
            for (Contact pm_contact : pm_contacts) {
                pm_resource_sfdcUserMap.put(pm_contact.Id, pm_contact.pse__Salesforce_User__c);
            }
        }

        Set<Id> acctIds = new Set<Id>();
        for(SObject so : Trigger.new){
            pse__Proj__c proj = (pse__Proj__c)so;
            if(proj.Pse__Account__c != null){
                acctIds.add(proj.PSE__Account__c);
            }
         }

         if(acctIds.size() > 0){
                accounts = new Map<Id, Account>([Select Id, BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry
                 from Account where Id in :acctIds]);
                System.debug('*** The accounts related to the projects: '+accounts);
        }
        

        //END Modified by cklassen 4/27/15 - Move soql outside of for loop
    }

    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    // Updated 5/4 Spano 
    ***************************************************************************************/
    public void bulkAfter(){

        
        
        
        //Retrieve accounts related to the project
        if(Trigger.isInsert){
            if (psaTriggerMonitor.ExecutedTriggers.contains('psaProjectTriggerHandlerAfterInsert')) {
            	System.debug('Skipping psaProjectTriggerHandlerAfterInsert bulkAfter method due to trigger recursion prevention');
            	return;
        	}
        	psaTriggerMonitor.ExecutedTriggers.add('psaProjectTriggerHandlerAfterInsert');
            Set<Id> acctIds = new Set<Id>();
            Set<Id> projIds = new Set<Id>();
            for(SObject so : Trigger.new){
                pse__Proj__c proj = (pse__Proj__c)so;
                projIds.add(proj.Id);
                //Add both the customer and billing accounts to our list of account IDs to retrieve
                if(proj.PSA_Customer_Account__c != null){
                    acctIds.add(proj.PSA_Customer_Account__c);
                }
                if(proj.Pse__Account__c != null){
                    acctIds.add(proj.PSE__Account__c);
                }

                System.debug('Acctids: '+acctIds);
            }

            List<pse__Resource_Request__c> resRequests = new List<pse__Resource_Request__c>();
            List<pse__Assignment__c> assignments = new List<pse__Assignment__c>();
            if(projIds.size() > 0){
                resRequests = [Select Id,pse__Start_Date__c, pse__End_Date__c,pse__Project__c from pse__Resource_Request__c where pse__Project__c in :projIds];
                for(pse__Resource_Request__c rr : resRequests){
                    Id projId = rr.pse__Project__c;
                    if(projId != null){
                        List<pse__Resource_Request__c> existing = resReqMap.get(projId);
                        if(existing == null){
                            existing = new List<pse__Resource_Request__c>();
                        }
                        existing.add(rr);
                        resReqMap.put(projId, existing);
                    }
                }

                newProjMap = new Map<Id, pse__Proj__c>([Select ID,pse__Project_Manager__r.pse__Salesforce_User__c from pse__Proj__c where ID in :projIds]);

                List<pse__Billing_Event__c> bes = [Select ID,pse__Is_Released__c,pse__PRoject__c from pse__Billing_Event__c where pse__Project__c in :projIds];
                for(pse__Billing_Event__c be : bes){
                    List<pse__Billing_Event__c> exist = beMAp.get(be.pse__PRoject__c) != null ? beMap.get(be.pse__Project__c) : new List<pse__Billing_Event__c>();
                    exist.add(be);
                    beMap.put(be.pse__Project__c, exist);
                }

                Set<Id> schedIds = new Set<Id>();
                assignments = [Select Id, pse__Schedule__c, pse__Start_Date__c, pse__End_Date__c,pse__Project__c from pse__Assignment__c where pse__Project__c in :projIds];
                for(pse__Assignment__c a : assignments){
                    Id projId = a.pse__Project__c;
                    if(projId != null){
                        List<pse__Assignment__c> existing = assignmentMap.get(projId);
                        if(existing == null){
                            existing = new List<pse__Assignment__c>();
                        }
                        existing.add(a);
                        assignmentMap.put(projId, existing);
                    }
                    Id schedule = a.pse__Schedule__c;
                    if(schedule != null){
                        schedIds.add(schedule);
                    }
                }

                assignmentToSched = new Map<Id, pse__Schedule__c>([Select Id, pse__Start_Date__c, pse__End_Date__c from pse__Schedule__c where id in :schedIds]);
            }
            List<Account> extraAccounts = 
                [SELECT Id, ParentId, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                 from Account 
                 where ParentId in :acctIds
                ];
            if(extraAccounts != null && extraAccounts.size() > 0){
                for(Account a : extraAccounts){
                    acctIds.add(a.id);
                    
                    Id parent = a.ParentId;
                    List<Account> children = childAccounts.get(parent);
                    if(children == null){
                        children = new List<Account>();
                    }
                    children.add(a);
                    childAccounts.put(parent, children);
                }
            }
            
            //Retrieve our map of Accounts that contain our billing addresses
            if(acctIds.size() > 0){
                System.debug(LoggingLevel.ERROR, 'Account ids was > 0');
                Set<Id> recordIds = new Set<Id>();
                List<RecordType> recordTypeIds = [Select id from RecordType where SObjectType = 'Account' and (Name = 'Customer' OR Name = 'Partner')];
                for(RecordType rt : recordtypeIds){
                    recordIds.add(rt.id);
                }
                System.debug(LoggingLevel.ERROR, 'record type ids was: '+recordIds);
                List<Account> accts = [Select ID,Name,RecordType.Name,RecordTypeId,BillingCity,BillingState,BillingStreet,BillingCountry,BillingPostalCode from Account where Id in :acctIds];
                for(Account next : accts){
                    System.debug('**** '+next.recordTypeId);
                    if(recordIds.contains(next.recordTypeId)){
                        System.debug('**** Added to map');
                        accounts.put(next.id, next);
                    }
                }
                System.debug('**** Accounts is: '+accounts);
            }
            // Retrieve the projects that will have project location objects associated with them
            for (SObject so : Trigger.new){
                pse__Proj__c proj = (pse__Proj__c)so;
                
                //GMM 7/10 - Removed if statement below to add all projects, not just customer projects
                //if(proj.pse__Project_Type__c  == 'Customer Project'){
                //System.debug('**** Had to add the project');
                projToAddLocations.add(proj.Id);
                //}
            }
            
            List<pse__Proj__c> projectsForLocations = [SELECT id, 
                                                       pse__Account__c, 
                                                       PSA_Customer_Account__c,
                                                       pse__Start_Date__c,
                                                       pse__End_Date__c,
                                                       pse__Project_Type__c
                                                       FROM pse__Proj__c      
                                                       WHERE id IN: projToAddLocations];
            
            if( projectsForLocations != null){
                //System.debug(LoggingLevel.ERROR, '**** WASNT NULL');
                for(pse__Proj__c proj : projectsForLocations){
                    Set<Id> addedAccounts = new Set<Id>();
                    addressesAdded = new Set<String>();
                    //If the project Billing Account is not null, retrieve its address and create a project location
                    if(proj.pse__Account__c != null){
                        Account billAccount = accounts.get(proj.pse__Account__c);
                        
                        if(billAccount != null){
                            //System.debug(LoggingLevel.ERROR, '**** Had to add location');
                            addLocation(proj, billAccount);
                            addedAccounts.add(billAccount.id);
                            
                        }
                        
                    }
                    //If the project Customer Account is not null, retrieve its address and create a project location
                    if(proj.PSA_Customer_Account__c != null){
                        Account custAccount = accounts.get(proj.PSA_Customer_Account__c);
                        if(custAccount != null && !addedAccounts.contains(custAccount.id)){
                            addLocation(proj, custAccount);
                            addedAccounts.add(custAccount.id);
                        }
                    }
                    
                    List<Account> billChildren = childAccounts.get(proj.pse__Account__c);
                    List<Account> custChildren = childAccounts.get(proj.PSA_Customer_Account__c);
                    
                    if(billChildren != null && billChildren.size() > 0){
                        for(Account acct : billChildren){
                            if(!addedAccounts.contains(acct.id)){
                                addLocation(proj, acct);
                                addedAccounts.add(acct.id);
                            }
                        }
                    }
                    
                    if(custChildren != null && custChildren.size() > 0){
                        for(Account acct : custChildren){
                            if(!addedAccounts.contains(acct.id)){
                                addLocation(proj, acct);
                                addedAccounts.add(acct.id);
                            }
                        }
                    }
                    
                    //Create a home location
                    pse__Project_Location__c proj_location = new pse__Project_Location__c();
                    proj_location.pse__Project__c = proj.id;
                    proj_location.pse__Description__c = 'Home Location';
                    proj_location.Name = proj_location.pse__Description__c;
                    proj_location.pse__Start_Date__c = proj.pse__Start_Date__c;
                    proj_location.pse__End_Date__c = proj.pse__End_Date__c;
                    projLocations.add(proj_location);  
                    
                }
                //System.debug(LoggingLevel.Error, '*** AfterInsert: Number of project locations to create: ' + projLocations.size());    
            }
        }
        if(trigger.isUpdate){
            if (psaTriggerMonitor.ExecutedTriggers.contains('psaProjectTriggerHandlerAfterUpdate')) {
            	System.debug('Skipping psaProjectTriggerHandlerAfterUpdate bulkAfter method due to trigger recursion prevention');
            	return;
        	}
        	psaTriggerMonitor.ExecutedTriggers.add('psaProjectTriggerHandlerAfterUpdate');
            Set<Id> acctIds = new Set<Id>();
            Set<Id> projIds = new Set<Id>();
            for(SObject so : Trigger.new){
                pse__Proj__c proj = (pse__Proj__c)so;
                projIds.add(proj.Id);
                //Add both the customer and billing accounts to our list of account IDs to retrieve
                if(proj.PSA_Customer_Account__c != null){
                    acctIds.add(proj.PSA_Customer_Account__c);
                }
                if(proj.Pse__Account__c != null){
                    acctIds.add(proj.PSE__Account__c);
                }

                System.debug('Acctids: '+acctIds);
            }

            List<pse__Resource_Request__c> resRequests = new List<pse__Resource_Request__c>();
            List<pse__Assignment__c> assignments = new List<pse__Assignment__c>();
            if(projIds.size() > 0){
                resRequests = [Select Id,pse__Start_Date__c, pse__End_Date__c,pse__Project__c from pse__Resource_Request__c where pse__Project__c in :projIds];
                for(pse__Resource_Request__c rr : resRequests){
                    Id projId = rr.pse__Project__c;
                    if(projId != null){
                        List<pse__Resource_Request__c> existing = resReqMap.get(projId);
                        if(existing == null){
                            existing = new List<pse__Resource_Request__c>();
                        }
                        existing.add(rr);
                        resReqMap.put(projId, existing);
                    }
                }

                newProjMap = new Map<Id, pse__Proj__c>([Select ID,pse__Project_Manager__r.pse__Salesforce_User__c from pse__Proj__c where ID in :projIds]);

                List<pse__Billing_Event__c> bes = [Select ID,pse__Is_Released__c,pse__PRoject__c from pse__Billing_Event__c where pse__Project__c in :projIds];
                for(pse__Billing_Event__c be : bes){
                    List<pse__Billing_Event__c> exist = beMAp.get(be.pse__PRoject__c) != null ? beMap.get(be.pse__Project__c) : new List<pse__Billing_Event__c>();
                    exist.add(be);
                    beMap.put(be.pse__Project__c, exist);
                }

                Set<Id> schedIds = new Set<Id>();
                assignments = [Select Id, pse__Schedule__c, pse__Start_Date__c, pse__End_Date__c,pse__Project__c from pse__Assignment__c where pse__Project__c in :projIds];
                for(pse__Assignment__c a : assignments){
                    Id projId = a.pse__Project__c;
                    if(projId != null){
                        List<pse__Assignment__c> existing = assignmentMap.get(projId);
                        if(existing == null){
                            existing = new List<pse__Assignment__c>();
                        }
                        existing.add(a);
                        assignmentMap.put(projId, existing);
                    }
                    Id schedule = a.pse__Schedule__c;
                    if(schedule != null){
                        schedIds.add(schedule);
                    }
                }

                assignmentToSched = new Map<Id, pse__Schedule__c>([Select Id, pse__Start_Date__c, pse__End_Date__c from pse__Schedule__c where id in :schedIds]);
            }
        }
    }
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        System.debug('Inserting a project');
        pse__Proj__c project = (pse__Proj__c)so;
        Account a = accounts.get(project.pse__account__c);
        if(a != null){
            //System.debug('Project had a billing account');
            if(project.psa_Customer_Account__c == null){
                //System.debug('Updating customer account');
                project.psa_Customer_Account__c = a.id;
            }
        }
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
        pse__Proj__c proj_old = (pse__Proj__c)oldSo;
        pse__Proj__c proj_new = (pse__Proj__c)so;

        //If the stage has changed to in progress, and the project manager has not been assigned to 'owner' yet
        if((proj_old.pse__Stage__c != 'In Progress' && proj_new.pse__Stage__c == 'In Progress') 
            && proj_new.OwnerID != proj_new.pse__Project_Manager__c){
            // Assign the project Manager to project owner now that project is in progress...
            Id sfdc_user = pm_resource_sfdcUserMap.get(proj_new.pse__Project_Manager__c);
            if(sfdc_user != null){
                proj_new.OwnerID = sfdc_user;
            }
        }
        boolean isCustomer = proj_new.pse__Project_Type__c == 'Customer Project';
        validateFields(proj_new, isCustomer);

        //If the Billing Rules Status has been set to Accepted, populate the Billing Rules Status History fields
        if(proj_old.PSA_BR_Billing_Rules_Status__c != proj_new.PSA_BR_Billing_Rules_Status__c && 
                proj_new.PSA_BR_Billing_Rules_Status__c == 'Accepted') {
            proj_new.PSA_Billing_Rules_Accepted_User__c = UserInfo.getUserId();
            proj_new.PSA_Billing_Rules_Accepted_Date__c = DateTime.now();
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
    public void afterInsert(SObject so){

    }
 
    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated 
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so) {
        pse__Proj__c newProj = (pse__Proj__c)so;
        pse__Proj__c oldProj = (pse__Proj__c)oldSo;
        
        //If the start or end date has changed
        if (newProj.pse__Start_Date__c != oldProj.pse__Start_Date__c || 
                newProj.pse__End_Date__c != oldProj.pse__End_Date__c) {
            projectDatesUpdated.put(newProj.id, newProj);
        }

        if(oldProj.pse__Project_Manager__c != newProj.pse__Project_Manager__c){
            List<pse__Billing_Event__c> existing = beMap.get(newProj.id);
            if(existing != null){
                for(pse__Billing_Event__c be : existing){
                    if(!be.pse__is_Released__c){
                        be.PSA_PM_User__c = newProjMap.get(newProj.id).pse__Project_Manager__r.pse__Salesforce_User__c;
                        besToUpdate.add(be);
                    }
                }
            }
            
        }

        if(oldProj.pse__Stage__c == 'Draft' && newProj.pse__Stage__c == 'Draft' && 
            oldProj.pse__Start_Date__c != newProj.pse__Start_Date__c){
            Date oldS = oldProj.pse__Start_Date__c;
            Date newS = newProj.pse__Start_Date__c;
            Integer difference = 0;
            // GMM 7/13: Added line below to check for null values 
            if (oldS != null && newS != null)
            {
                if(oldS < newS){
                    difference = netWorkDay(oldS, newS);
                }
                else{
                    difference = netWorkDay(newS, oldS) * -1;
                    //System.debug('Work day difference is: '+difference);

                }
                updateRRandAssignments(newProj.id, oldS, difference);
            }
        }
    }
 
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

        
       
        
        if(trigger.isInsert && trigger.isAfter){
            System.debug('*** Finally: Number of project locations to create: ' + projLocations.size());
            if(projLocations.size() > 0){
                insert projLocations;
                //System.debug('*** Inserted project locations: ' + projLocations.size());
           }
        }

        //Update applicable Project Locations
        if (projectDatesUpdated.size() > 0) {
            handleDateChange();

            System.debug('*** Finally: Number of project locations dates to update: ' + locationsUpdate.size());
            if (locationsUpdate.size() > 0) {
                update locationsUpdate;
                //System.debug('*** Updated project locations: ' + locationsUpdate.size());
            }
        }
        if(rrToUpdate.size() > 0){
             System.debug('*** Finally: Updated rrs');
            update rrToUpdate;

        }
        if(schedToUpdate.size() > 0){
            System.debug('*** Finally: Updating the schedules');
            update schedToUpdate;
        }
        if(besToUpdate.size() > 0){
            update besToUpdate;
        }

         /*
        if (psaTriggerMonitor.ExecutedTriggers.contains('psaProjectTriggerHandler')) {
            System.debug('Skipping psaProjectTriggerHandler andFinally() method due to trigger recursion prevention');
            return;
        }
        

        psaTriggerMonitor.ExecutedTriggers.add('psaProjectTriggerHandler');
        */
    }

    /**************************************************************************************
    // Name         : handleDateChange
    // Description  : Update the start and/or end dates for related project locations if the 
    //                  start and/or end date on the project has changed
    // Revisions    : 2015-03-01    Schwartz    Initial Version 
    //              : 2015-04-27    Klassen     Code refactor
    ***************************************************************************************/
    private void handleDateChange() {
        //Obtain any project locations associated with the projects whose dates have changed
        List<pse__Project_Location__c> locations = 
            [SELECT pse__Start_Date__c, pse__End_Date__c, pse__Project__c 
                From pse__Project_Location__c 
                Where pse__Project__c in :projectDatesUpdated.keySet()
            ];
        if (locations != null && locations.size() > 0) {
            for (pse__Project_Location__c loc : locations) {
                //Retrieve the project associated with the project location
                pse__Proj__c thisProj = projectDatesUpdated.get(loc.pse__Project__c);
                if (thisProj != null) {
                    Date start = thisProj.pse__Start_Date__c;
                    Date endDate = thisProj.pse__End_Date__c;
                    loc.pse__Start_Date__c = start;
                    loc.pse__End_Date__c = endDate;
                    //Add the updated location to our list 
                    locationsUpdate.add(loc);
                }
            }
        }
    }

    private void checkImplementers(pse__Proj__c proj){
        List<PSA_Implementer__c> imps = [Select Id from PSA_Implementer__c where PSA_Project__c = :proj.id];
        if(imps == null || imps.isEmpty()){
            throw new psaException('At least one implementer is required for a project to be set to In progress');
        }
    }

    /**************************************************************************************
    // Name         : addLocation
    // Description  : Add a location from an account to the project 
    // Revisions    : 2015-05-07 Spano initial version
    ***************************************************************************************/
    private void addLocation(pse__Proj__c proj, Account a){
        String city = a.BillingCity;
        String state = a.BillingState;
        //String street = a.BillingStreet;
        String country = a.BillingCountry;
        //String code = a.BillingPostalCode;

        //String key = city+state+country+code;
        String key;
        
        Boolean isCustomerProject = false;

        if(proj.pse__Project_Type__c == 'Customer Project'){
            isCustomerProject = true;
        }

        if(isCustomerProject){
            key = city+state+country;
        }
        else{
            key = state+country;
        }
       
        if(addressesAdded.contains(key)){
            //System.debug('*** The address was contained');
            return;
        }

        addressesAdded.add(key);
        //System.debug('*** Added address: '+key);
        
        pse__Project_Location__c proj_location = new pse__Project_Location__c();
        proj_location.pse__Project__c = proj.id;
        
        if(isCustomerProject){
            proj_location.pse__Description__c = city+', '+state+' '+country;
            proj_location.PSA_City__c = city;
        }
        else {
            if(state != null) {
                proj_location.pse__Description__c = country+', '+state;
            }
            else {
                proj_location.pse__Description__c = country;
            }
            
        }

         proj_location.PSA_State_Province__c = state;
        
        //proj_location.PSA_Postal_Code__c = code;
        
        proj_location.PSA_Country__c = country;
        if(state != null) {
            proj_location.PSA_State_Province__c = state;
        }
        proj_location.Name = proj_location.pse__Description__c;
        proj_location.pse__Start_Date__c = proj.pse__Start_Date__c;
        proj_location.pse__End_Date__c = proj.pse__End_Date__c;
        projLocations.add(proj_location);
    }


    /**************************************************************************************
    // Name         : netWorkDay
    // Description  : Calculate the # of work days between two dates
    // Revisions    : 
    ***************************************************************************************/
    public static integer netWorkDay(Date sdate, Date edate){
        //System.debug('THIS IS A DEBUG');
        Datetime sDT = Datetime.newInstance(sdate.year(), sdate.month(), sdate.day());
        Datetime eDT = Datetime.newInstance(edate.year(), edate.month(), edate.day());
        integer count=0;
        integer wDay = sdate.daysBetween(edate);
        System.debug('WDAY: '+wDay);
     
      do{
            if(sDT.format('EEEE') == 'Saturday') {
                count++;
            }
            if(sDT.format('EEEE') == 'Sunday') {
                count++;
            }
            sDT= sDT.adddays(1);
      }while(sDT<=eDT);
     
      wDay = wDay-count;
      //System.debug('*** net days is: '+wDay);
      return wDay;
    }

    public static Integer daysWithWorkDays(Date start, Integer workDays){
        if(workDays > 0){
            Datetime nextDay = Datetime.newInstance(start.year(), start.month(), start.day()+1);
            Integer workDayCount = 0;
            Integer totalCount = 0;
            while(workDayCount < workDays){
                //System.debug('DAY IS: '+nextDay.format('EEEE'));
                if(nextDay.format('EEEE') == 'Saturday' || nextDay.format('EEEE') == 'Sunday'){
                    totalCount++;
                }
                else{
                    totalCount++;
                    workDayCount++;
                }
                nextDay = nextDay.addDays(1);
            }
            //System.debug('*** Returning: '+totalCount);
            return totalCount;
        }
        else{
            Datetime nextDay = Datetime.newInstance(start.year(), start.month(), start.day()-1);
            Integer workDayCount = 0;
            Integer totalCount = 0;
            while(workDayCount > workDays){
                //System.debug('DAY IS: '+nextDay.format('EEEE'));
                if(nextDay.format('EEEE') == 'Saturday' || nextDay.format('EEEE') == 'Sunday'){
                    totalCount--;
                }
                else{
                    totalCount--;
                    workDayCount--;
                }
                nextDay = nextDay.addDays(-1);
            }
            //System.debug('*** Returning: '+totalCount);
            return totalCount;
        }
    }

    private void updateRRandAssignments(ID projectId, Date oldStart, Integer days){
        List<pse__Resource_Request__c> requestsNeedingUpdate = resReqMap.get(projectId);
        List<pse__Assignment__c> assignmentsUpdate = assignmentMap.get(projectId);

        if (requestsNeedingUpdate != null && requestsNeedingUpdate.size() > 0) {
            for(pse__Resource_Request__c rr : requestsNeedingUpdate){
                Date start = rr.pse__Start_Date__c;
                Date endDate = rr.pse__End_date__c;
                Integer toChangeStart = daysWithWorkDays(start, days);
                Integer toChangeEnd = daysWithWorkDays(endDate, days);
                rr.pse__Start_Date__c = start+toChangeStart;
                rr.pse__End_Date__c = rr.pse__End_Date__c + toChangeEnd;
                rrToUpdate.add(rr);
            }
        }

        if (assignmentsUpdate != null && assignmentsUpdate.size() > 0) {
            for(pse__Assignment__c a : assignmentsUpdate){
                if(a.pse__Schedule__c != null){
                    pse__Schedule__c aSched = assignmentToSched.get(a.pse__Schedule__c);
                    Date start = aSched.pse__Start_Date__c;
                    Date endDate = aSched.pse__End_Date__c;
                    Integer toChangeStart = daysWithWorkDays(start, days);
                    Integer toChangeEnd = daysWithWorkDays(endDate, days);
                    aSched.pse__Start_Date__c = start+toChangeStart;
                    aSched.pse__End_Date__c = endDate + toChangeEnd;
                    schedToUpdate.add(aSched);
                }
            }
        }


    }

    private void validateFields(pse__Proj__c proj, boolean isCustomer){
        if(proj.pse__Stage__c == 'Finance Review'){
            validateFinanceReview(proj, isCustomer);
        }
        else if(proj.pse__Stage__c == 'In Progress'){
            validateInProgress(proj, isCustomer);
        }
    }

    private void validateInProgress(pse__Proj__c proj, boolean isCustomer){
        String errorMessage = 'The following field(s) are missing for Stage: In Progress: ';
        boolean isError = false;
        if(proj.PSA_VSOE_Type__c == '' || proj.PSA_VSOE_Type__c == null){
            errorMessage += 'VSOE Type';
            isError = true;
        }

        if(proj.currencyIsoCode == '' || proj.currencyIsoCode == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Currency';
            isError = true;
        }
        if(proj.pse__Start_Date__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Start Date';
            isError = true;
        }
        if(proj.pse__End_Date__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'End Date';
            isError = true;
        }
        if(proj.pse__Region__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Region';
            isError = true;
        }
        if(proj.pse__Practice__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Practice';
            isError = true;
        }
        if(proj.pse__Group__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Group';
            isError = true;
        }
        if(proj.pse__Project_Type__c == null || proj.pse__Project_Type__c == ''){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Project Type';
            isError = true;
        }
        if(proj.PSA_BR_Expenses_Billing_Type__c == null || proj.PSA_BR_Expenses_Billing_Type__c == ''){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Expenses Billing Type';
            isError = true;
        }
        if(proj.pse__Billing_Type__c == null || proj.pse__Billing_Type__c == ''){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Services Billing Type';
            isError = true;
        }
        if(proj.PSA_Revenue_Forecast_Model__c == null || proj.PSA_Revenue_Forecast_Model__c == ''){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Revenue Forecast Model';
            isError = true;
        }
        if(proj.psa_forecast_category__c != 'Committed'){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Forecast Category is not Committed';
            isError = true;
        }
        if(proj.PSA_Revenue_Recognition_Model__c == '' || proj.PSA_Revenue_Recognition_Model__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Revenue Recognition Model';
            isError = true;
        }
        if(proj.PSA_Rate_Classification__c == '' || proj.PSA_Rate_Classification__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Rate Classification';
            isError = true;
        }
        if(proj.PSA_Director__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Director';
            isError = true;
        }
        if(proj.PSA_PIA__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'PIA';
            isError = true;
        }
        if(proj.PSA_CIM__C == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'CIM';
            isError = true;
        }
        if(proj.PSA_VP__C == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'VP';
            isError = true;
        }
        if(proj.pse__Account__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Billing Account';
            isError = true;
        }
        if(proj.psa_Customer_Account__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Customer Account';
            isError = true;
        }
        if(proj.PSA_Ship_To_Contact__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Ship To Contact';
            isError = true;
        }
        if(proj.PSA_Bill_To_Contact__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Bill To Contact';
            isError = true;
        }
        if(proj.psa_Expense_Approval_Method__c == '' || proj.PSA_Time_Approval_Method__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Expense Approval Method';
            isError = true;
        }
        if(proj.psa_Time_Approval_Method__c == '' || proj.psa_Time_Approval_Method__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Time Approval Method';
            isError = true;
        }

        if(proj.psa_Services_Product__c == '' || proj.psa_services_product__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Services Product';
            isError = true;

        }
        if(proj.psa_Product_Line__c == '' || proj.psa_Product_Line__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Product Line';
            isError = true;
        }
        if(proj.PSA_Department__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Department';
            isError = true;
        }
        if(proj.pse__Project_Manager__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Project Manager';
            isError = true;
        }

        if(isError){
            proj.addError(errorMessage);
        }
    }

    private void validateFinanceReview(pse__Proj__c proj, boolean isCustomer){
        String errorMessage = 'The following field(s) are missing for Stage: Finance Review: \r\n';
        boolean isError = false;
        if(proj.pse__Project_Manager__c == null){
            errorMessage += 'Project Manager';
            isError = true;
        }
        if(proj.PSA_Director__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Director';
            isError = true;
        }
        if(proj.PSA_PIA__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'PIA';
            isError = true;
        }
        if(proj.PSA_CIM__C == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'CIM';
            isError = true;
        }
        if(proj.PSA_Billing_Legal_Entity__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Billing Legal Entity';
            isError = true;
        }
        if(proj.PSA_Billing_Detail_Template__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Billing Detail Template';
            isError = true;
        }
        if(proj.PSA_VP__C == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'VP';
            isError = true;
        }
        if(proj.pse__Account__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Billing Account';
            isError = true;
        }
        if(proj.psa_Customer_Account__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Customer Account';
            isError = true;
        }
        if(proj.PSA_Ship_To_Contact__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Ship To Contact';
            isError = true;
        }
        if(proj.PSA_Bill_To_Contact__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Bill To Contact';
            isError = true;
        }
        if(proj.psa_Expense_Approval_Method__c == '' || proj.PSA_Time_Approval_Method__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Expense Approval Method';
            isError = true;
        }
        if(proj.psa_Time_Approval_Method__c == '' || proj.psa_Time_Approval_Method__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Time Approval Method';
            isError = true;
        }

        if(proj.psa_Services_Product__c == '' || proj.psa_services_product__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Services Product';
            isError = true;

        }
        if(proj.psa_Product_Line__c == '' || proj.psa_Product_Line__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Product Line';
            isError = true;
        }
        if(proj.PSA_Department__c == null){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += 'Department';
            isError = true;
        }

        List<PSA_Implementer__c> imps = impMap.get(proj.id);
        if(imps == null || imps.isEmpty()){
            if(isError){
                errorMessage += ', ';
            }
            errorMessage += ('Implementers');
            isError = true;
            //throw new psaException('At least one implementer is required for a project to be set to In progress');
        }
        if(isError){
            proj.addError(errorMessage);
        }
    }
}