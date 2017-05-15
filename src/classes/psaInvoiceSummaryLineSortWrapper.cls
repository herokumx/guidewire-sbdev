/****************************************************************************************
Name            : psaInvoiceSummaryLineSortWrapper
Author          : CLD Partners
Created Date    : April 22, 2015
Description     : Sorts Invoice Summary Lines by the Summary Line Type field
Revisions       : 4/22/15  - Initial version
				: 
******************************************************************************************/
global with sharing class psaInvoiceSummaryLineSortWrapper implements Comparable {
	public PSA_Invoice_Summary_Line__c invoiceSummaryLine;

	//Constructor
	public psaInvoiceSummaryLineSortWrapper(PSA_Invoice_Summary_Line__c invoiceSummaryLineIn) {
		invoiceSummaryLine = invoiceSummaryLineIn;
	}	

    // Compare Invoice Summary Lines based on the Invoice Summary Line Type.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        psaInvoiceSummaryLineSortWrapper compareToInvoiceSummaryLine = (psaInvoiceSummaryLineSortWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (invoiceSummaryLine.PSA_Summary_Line_Type__c > compareToInvoiceSummaryLine.invoiceSummaryLine.PSA_Summary_Line_Type__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (invoiceSummaryLine.PSA_Summary_Line_Type__c < compareToInvoiceSummaryLine.invoiceSummaryLine.PSA_Summary_Line_Type__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}