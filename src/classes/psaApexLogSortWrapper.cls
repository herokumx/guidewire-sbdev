/****************************************************************************************
Name            : psaApexLogSortWrapper
Author          : CLD Partners
Created Date    : August 20, 2015
Description     : Sorts Apex Logs by the Log DateTime Descending then Sequence Descending
Revisions       : 8/20/15  - Initial version
				: 
******************************************************************************************/
global without sharing class psaApexLogSortWrapper implements Comparable {
	public PSA_Apex_Log__c apexLog;

	//Constructor
	public psaApexLogSortWrapper(PSA_Apex_Log__c apexLogIn) {
		apexLog = apexLogIn;
	}	

    // Compare Apex Logs based on the Log DateTime.
    global Integer compareTo(Object compareTo) {
        // Cast argument to ApexLogSortWrapper
        psaApexLogSortWrapper compareToApexLog = (psaApexLogSortWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (apexLog.PSA_Log_DateTime__c > compareToApexLog.apexLog.PSA_Log_DateTime__c) {
            // Set return value to a negative value.
            returnValue = -1;
        } else if (apexLog.PSA_Log_DateTime__c < compareToApexLog.apexLog.PSA_Log_DateTime__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (apexLog.PSA_Sequence__c > compareToApexLog.apexLog.PSA_Sequence__c) {
        	// set return value to a negative value.
        	returnValue = -1;
        } else if (apexLog.PSA_Sequence__c < compareToApexLog.apexLog.PSA_Sequence__c) {
        	// set return value to a positive value.
        	returnValue = 1;
        }
        
        return returnValue;       
    }
}