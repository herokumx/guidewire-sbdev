public with sharing class psaTimeDateTriggerHandler implements psaITriggerHandler{
	
	List<pse__Timecard__c> splits = new List<pse__Timecard__c>();
    Map<Id, String> timecardToCurrency = new Map<Id, String>();

	public psaTimeDateTriggerHandler() {
		
	}

	 /**************************************************************************************
    // Name        : bulkBefore
    // Description : This method is called prior to execution of a BEFORE trigger. Use 
    //               this to cache any data required into maps prior to execution of the 
    //               trigger.
    ***************************************************************************************/
    public void bulkBefore(){

    	Date earliest = null;
    	Date latest = null;
    	Set<id> timecardIds = new Set<Id>();

    	for(SObject so : trigger.new){
    		Pse__Time_Date__c next = (PSE__Time_Date__c)so;
    		timecardIds.add(next.pse__Timecard__c);

    		if(earliest == null || next.pse__Date__c <= earliest){
    			earliest = next.pse__Date__c;
    		}
    		if(latest == null || next.pse__date__c >= latest){
    			latest = next.pse__date__c;
    		}
    	}
    	if(earliest != null && latest != null){
    		splits = [SELECT Id,PSE__Start_Date__c,pse__Timecard_Header__c,pse__End_date__c from Pse__Timecard__c where pse__Timecard_Header__c in :timecardIds];
    	}
        System.debug('Splits: '+splits);

        List<pse__Timecard_Header__c> timecards = new List<pse__Timecard_Header__c>();
        if(timecardIds.size() > 0){
            timecards = [Select Id,pse__Project__r.currencyIsoCode from pse__Timecard_Header__c where id in :timecardIds];
        }
        if(timecards != null){
            for(pse__Timecard_Header__c tc : timecards){
                timecardToCurrency.put(tc.id, tc.pse__Project__r.currencyIsoCode);
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
    	Pse__Time_Date__c next = (PSE__Time_Date__c)so;
    	for(pse__Timecard__c split : splits){
    		if(split.pse__Start_Date__c <= next.pse__Date__c && split.pse__End_Date__c >= next.pse__date__c && split.pse__Timecard_Header__c == next.pse__Timecard__c){
    			next.psa_Timecard_Split__c = split.Id;
                System.debug('The time date: '+next+' had a split of: '+split.Id);
    		}
    	}
        String currencyCode = timecardToCurrency.get(next.pse__Timecard__c);
        if(currencyCode != null && currencyCode != ''){
            next.currencyIsoCode = currencyCode;
        }
        //System.debug('The time date: '+next+' had a split of: '+split.Id))
    }
     
    /**************************************************************************************
    // Name        : beforeUpdate
    // Description : This method is called iteratively for each record to be updated 
    //               during a BEFORE trigger.
    ***************************************************************************************/
    public void beforeUpdate(SObject oldSo, SObject so){
    	Pse__Time_Date__c next = (PSE__Time_Date__c)so;

    	for(pse__Timecard__c split : splits){
    		if(split.pse__Start_Date__c <= next.pse__Date__c && split.pse__End_Date__c >= next.pse__date__c && split.pse__Timecard_Header__c == next.pse__Timecard__c){
                
    			next.psa_Timecard_Split__c = split.Id;
                System.debug('OBVIOUSLY IT WORKED' + next);
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
    public void andFinally(){}
}