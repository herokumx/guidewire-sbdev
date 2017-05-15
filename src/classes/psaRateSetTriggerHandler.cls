/**************************************************************************************
// Name          : psaRateSetTriggerHandler
// Date          : May 27, 2015
// Description   : Handles all inserts/updates/deletes called by the psaRateSet trigger
// Author        : CLD Partners
// Revisions     : 2015-05-27 Spano initial version

//               
***************************************************************************************/
public with sharing class psaRateSetTriggerHandler implements psaITriggerHandler{
    
    Map<Id, pse__Proj__c> projectMap;
    List<pse__Proj__c> toUpdate;

    Map<Id, PSA_Rate_Set__c> projectSets = new Map<Id, PSA_Rate_Set__c>();
    Map<Id, PSA_Rate_Set__c> accountSets = new Map<Id, PSA_Rate_Set__c>();
    List<PSA_Rate_Set__c> globalSet;


    public psaRateSetTriggerHandler() {
        toUpdate = new List<pse__Proj__c>();
        
    }

    /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){
        Set<Id> projectIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for(SObject so : Trigger.new){
            psa_Rate_Set__c rs = (PSA_Rate_Set__c)so;
            if(rs.psa_Project__c != null){
                projectIds.add(rs.PSA_Project__c);
            }
            if(rs.psa_Account__c != null){
                accountIds.add(rs.psa_Account__c);
            }
        }

        globalSet = [Select Id from PSA_Rate_Set__c where PSA_Project__c = '' and psa_Account__c = ''];
        List<PSA_Rate_Set__c> tempAccounts = [Select Id,PSA_Account__c from PSA_Rate_Set__c where PSA_Account__c in :accountIds];
        List<PSA_Rate_Set__c> tempProjects = [Select Id,PSA_Project__c from PSA_Rate_Set__c where PSA_Project__c in :projectIds];
        for(PSA_Rate_Set__c next : tempAccounts){
            accountSets.put(next.PSA_Account__c, next);
        }
        for(PSA_Rate_Set__c nextP : tempProjects){
            projectSets.put(nextP.PSA_Project__c, nextP);
        }


    }
     
    /**************************************************************************************
    // Name        : bulkAfter
    // Description : This method is called prior to execution of a AFTER trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkAfter(){
        if(Trigger.isInsert || Trigger.isUpdate){

            Set<Id> projectIds = new Set<Id>();
            for(SObject so : Trigger.new){
                psa_Rate_Set__c rs = (PSA_Rate_Set__c)so;
                projectIds.add(rs.psa_Project__c);
            }

            projectMap = new Map<Id, pse__Proj__c>([Select Id, psa_Project_Rate_Set__c, psa_Account_Rate_Set__c from pse__Proj__c where id in :projectIds]);
        }
    }
     
    /**************************************************************************************
    // Name        : beforeInsert
    // Description : This method is called iteratively for each record to be inserted 
    //               during a BEFORE trigger. Never execute any SOQL/SOSL etc in this and 
    //               other iterative methods.
    ***************************************************************************************/
    public void beforeInsert(SObject so){
        psa_Rate_Set__c rs = (PSA_Rate_Set__c)so;
        if(rs.PSA_Project__c != null && rs.PSA_Account__c != null){
            so.addError('A rate set may not have both a project and an account');
            //throw new psaException('A rate set may not have both a project and an account');
        }
        if(rs.PSA_Is_Global__c && globalSet != null && globalSet.size() > 0){
            so.addError('A global rate set already exists');
            //throw new psaException('A global rate set already exists');
        }
        if(rs.PSA_Project__c == null && rs.PSA_Account__c == null && globalSet != null && globalSet.size() > 0){
            so.addError('A global rate set already exists');
            //throw new psaException('A global rate set already exists');
        }

        if(rs.PSA_Project__c != null){
            if(projectSets.get(rs.PSA_Project__c) != null){
                so.addError('A rate set already exists for this project');
                //throw new psaException('A rate set already exists for this project');
            }
        }
        if(rs.PSA_Account__c != null){
            if(accountSets.get(rs.PSA_Account__c) != null){
                so.addError('A rate set already exists for this account');
                //throw new psaException('A rate set already exists for this account');
            }
        }

    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
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
        PSA_Rate_Set__c rateSet = (PSA_Rate_Set__c)so;
        System.debug('Rate set is: '+rateSet);
        if(rateSet.psa_Project__c != null){
            updateProjectLookup(rateSet);
        }
    }
 
    /**************************************************************************************
    // Name        : afterUpdate
    // Description : This method is called iteratively for each record updated 
    //               during an AFTER trigger.
    ***************************************************************************************/
    public void afterUpdate(SObject oldSo, SObject so){
        PSA_Rate_Set__c rateSet = (PSA_Rate_Set__c)so;
        if(rateSet.psa_Project__c != null){
            updateProjectLookup(rateSet);
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
        System.debug('Executing andFinally');
        if(toUpdate != null && toUpdate.size() > 0){
            System.debug('updating projects: '+toUpdate);
            update toUpdate;
        }

    }

    private void updateProjectLookup(PSA_Rate_Set__c rateSet){
        pse__Proj__c project = projectMap.get(rateSet.psa_Project__c);
        System.debug('Prioject is: '+project);
        if(project != null){
            project.PSA_Project_Rate_Set__c = rateSet.id;
            toUpdate.add(project);
        }
    }
}