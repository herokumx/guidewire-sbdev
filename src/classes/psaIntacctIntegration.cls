/**************************************************************************************
// Name          : psaIntacctIntegration
// Date          : April 10, 2015
// Description   : Contains methods related to the Intacct integration including 
//					and updating Expense Reports and Billing Events 
// Author        : CLD Partners 
// Revisions     : 2015-04-10  Klassen  Initial version
//				 : 2015-09-21  Klassen  Updated Billing Event processing - Switched over 
					to using PSA Billing API to take advantage of the invoice batching 
					(avoids Apex CPU timeout errors	when processing billing events with 
					a large number of line items (>400)) 
***************************************************************************************/
public with sharing class psaIntacctIntegration {
	public psaIntacctIntegration() {}

    /**************************************************************************************
    // Name        	: processExpenseReports
    // Description 	: Update Expense Report Reimbursement information
	// Author       : CLD Partners
	// Revisions    : 2015-04-10  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static void processExpenseReports(Set<Id> expenseStageIds) {
		Map<Id, pse__Expense_Report__c> expenseReportMap;
		List<pse__Expense_Report__c> expenseReportsToUpdate = new List<pse__Expense_Report__c>();
		Set<Id> expenseReportIds = new Set<Id>();

		List<PSA_Expense_Stage__c> expenseStageList = 
			[Select PSA_Expense_Report__c, PSA_GW_Integration_Id__c, PSA_Reimbursement_Status__c, 
					PSA_Processed__c, PSA_Processed_Date__c, PSA_Processing_Error_Message__c 
				From PSA_Expense_Stage__c
				Where Id In :expenseStageIds
			];

		//*** BEGIN Populate Maps
		for (PSA_Expense_Stage__c expenseStage : expenseStageList) {
			expenseReportIds.add(expenseStage.PSA_Expense_Report__c);
			expenseStage.PSA_Processed__c = true;
			expenseStage.PSA_Processed_Date__c = DateTime.now();			
		}
		expenseReportMap = new Map<Id, pse__Expense_Report__c>(
			[Select Id, PSA_Reimbursement_Status__c, PSA_Expense_Stage__c 
				From pse__Expense_Report__c
				Where Id In :expenseReportIds
			]);
		//*** END Populate Maps

		//*** BEGIN Create/Update Resources
		pse__Expense_Report__c updatedExpenseReport;
		for (PSA_Expense_Stage__c expenseStage : expenseStageList) {
	       	if (verifyExpenseReportExists(expenseReportMap, expenseStage)) {
	       		updatedExpenseReport = updateExpenseReport(expenseStage, expenseReportMap);
	       		if (updatedExpenseReport != null) {
		       		expenseReportsToUpdate.add(updatedExpenseReport);
	       		}
	       	} else {
	       		//write integration log entry - error b/c no expense report found
				String logMessage = 'Unable to find a valid Expense Report: ' + expenseStage.PSA_Expense_Report__c;
				psaIntegrationUtils.writeLogEntry(expenseStage.Id, 'Expense Report', psaIntegrationUtils.INTERGRATION_TYPE_EXPENSE_UPDATE, 
					psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, expenseStage.PSA_GW_Integration_Id__c, null);
	       	}
		}
		//*** END Create/Update Resources

		//*** BEGIN DML operations
		pse__Expense_Report__c expenseReport;
		Database.SaveResult sr;

		//Updated Resources
		Database.SaveResult[] srList = Database.Update(expenseReportsToUpdate, false);
		for (Integer i = 0; i< expenseReportsToUpdate.size(); i++) {
			sr = srList[i];
    		expenseReport = expenseReportsToUpdate[i];
			if (sr.isSuccess() == true) {
				System.debug('Successfully Updated Expense Report.  Exp. Rpt. Id: ' + expenseReport.Id + ' - ExpenseStageId:' + expenseReport.PSA_Expense_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully updated expense report';
				psaIntegrationUtils.writeLogEntry(expenseReport.PSA_Expense_Stage__c, 'Expense Report', psaIntegrationUtils.INTERGRATION_TYPE_EXPENSE_UPDATE, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, null, expenseReport.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, expenseReport.PSA_Expense_Stage__c, 
					psaIntegrationUtils.INTERGRATION_TYPE_EXPENSE_UPDATE, 'Expense Report', expenseReport.Id);
			}
		}

		//Update the Processed and Processed Date fields
		update expenseStageList;

		//BEGIN Integration Log Update
		//	Update the gw integration id in the integration log where applicable
		psaIntegrationUtils.updateGWIds('Expense Report');
		//END update the reference id and gw integration id in the integration log where applicable

		//*** END DML operations
    }

    /**************************************************************************************
    // Name        	: verifyExpenseReportExists
    // Description 	: If a Expense Report does not exist for the Worker Id, return
    //					false, else return true
	// Author       : CLD Partners
	// Revisions    : 2015-04-10  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static Boolean verifyExpenseReportExists(Map<Id, pse__Expense_Report__c> expenseReportMap, PSA_Expense_Stage__c expenseStage) {
    	Boolean expenseReportExists = true;
       	if (expenseReportMap == null) {
       		expenseReportExists = false;
       	} else {
       		pse__Expense_Report__c expenseReport = expenseReportMap.get(expenseStage.PSA_Expense_Report__c);
       		if (expenseReport == null) {
	       		expenseReportExists = false;
       		} else if (expenseReport.PSA_Reimbursement_Status__c != 'Processing Reimbursement') {
				//Write a Warning entry to the Integration Log
				String logMessage = 'Unexpected Expense Report Reimbursement Status: ' + expenseReport.PSA_Reimbursement_Status__c;
				String integrationType = psaIntegrationUtils.INTERGRATION_TYPE_EXPENSE_UPDATE;

				psaIntegrationUtils.writeLogEntry(expenseStage.Id, 'Expense Report', integrationType, 
							psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, expenseStage.PSA_GW_Integration_Id__c, expenseReport.Id);
			} 
 		}

    	return expenseReportExists;
    }

	/**************************************************************************************
    // Name        	: updateExpenseReport
    // Description 	: Update the Reimbursement Status for an Expense Report
	// Author       : CLD Partners
	// Revisions    : 2015-04-10  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Expense_Report__c updateExpenseReport(PSA_Expense_Stage__c expenseStage, Map<Id, pse__Expense_Report__c> expenseReportMap) {
    	pse__Expense_Report__c expenseReport;
		try {
			expenseReport = expenseReportMap.get(expenseStage.PSA_Expense_Report__c);
						
			expensereport.PSA_Reimbursement_Status__c = expenseStage.PSA_Reimbursement_Status__c;
		    expensereport.PSA_Expense_Stage__c = expenseStage.Id;
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType = psaIntegrationUtils.INTERGRATION_TYPE_EXPENSE_UPDATE;

			psaIntegrationUtils.writeLogEntry(expenseStage.Id, 'Expense Report', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), expenseStage.PSA_GW_Integration_Id__c, expenseReport.Id);
			return null;			
		}

    	return expenseReport;
    }

    /**************************************************************************************
    // Name        	: processBillingEvents
    // Description 	: Update Billing Event Invoice information
	// Author       : CLD Partners
	// Revisions    : 2015-04-13  Klassen  Initial version
	//				: 2015-09-21  Klassen  Switched over to using PSA Billing API to take 
	//					advantage of the invoice batching (avoids Apex CPU timeout errors
						when processing billing events with a large number of line items (>400))
    ***************************************************************************************/
    public static void processBillingEvents(Set<Id> billingStageIds) {
		Map<Id, pse__Billing_Event__c> billingEventMap;
		List<pse__Billing_Event__c> billingEventsToUpdate = new List<pse__Billing_Event__c>();
		Set<Id> billingEventIds = new Set<Id>();

		//added the following 2 variables by cklassen 9/21 to utilize native psa billing api for billing
		Map<Id, PSA_Billing_Stage__c> billingStageMap = new Map<Id, PSA_Billing_Stage__c>(
			[Select Id, Name, PSA_Invoice_Date__c, PSA_Invoice_Number__c, PSA_Integration_Status__c
				From PSA_Billing_Stage__c
				Where Id In :billingStageIds
			]);
		List<pse.BillingEventsManager.InvoiceInfo> iiList = new List<pse.BillingEventsManager.InvoiceInfo>();

		List<PSA_Billing_Stage__c> billingStageList = 
			[Select Id, PSA_Billing_Event__c, PSA_GW_Integration_Id__c, PSA_Integration_Status__c, 
					PSA_Processed__c, PSA_Processed_Date__c, PSA_Invoicing_Error_Message__c, 
					PSA_Invoice_Date__c, PSA_Invoice_Number__c  
				From PSA_Billing_Stage__c
				Where Id In :billingStageIds
			];
		System.debug('Billing Stage List: ' + billingStageList);

		//*** BEGIN Populate Maps
		for (PSA_Billing_Stage__c billingStage : billingStageList) {
			billingEventIds.add(billingStage.PSA_Billing_Event__c);
			billingStage.PSA_Processed__c = true;
			billingStage.PSA_Processed_Date__c = DateTime.now();			
		}
		billingEventMap = new Map<Id, pse__Billing_Event__c>(
			[Select Id, PSA_Integration_Status__c, PSA_Billing_Stage__c, pse__Invoice_Date__c, pse__Invoice_Number__c, 
					pse__Invoiced__c, pse__Status__c 
				From pse__Billing_Event__c
				Where Id In :billingEventIds
			]);
		//*** END Populate Maps

		//*** BEGIN Create/Update Billing Events
		pse__Billing_Event__c updatedBillingEvent;
		for (PSA_Billing_Stage__c billingStage : billingStageList) {
	       	if (verifyBillingEventExists(billingEventMap, billingStage)) {
	       		updatedBillingEvent = updateBillingEvent(billingStage, billingEventMap);
	       		if (updatedBillingEvent != null) {
		       		billingEventsToUpdate.add(updatedBillingEvent);
	       		}
	       	} else {
	       		//write integration log entry - error b/c no expense report found
				String logMessage = 'Unable to find a valid Billing Event: ' + billingStage.PSA_Billing_Event__c;
				psaIntegrationUtils.writeLogEntry(billingStage.Id, 'Billing Event', psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE, 
					psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, billingStage.PSA_GW_Integration_Id__c, null);
	       	}
		}
		//*** END Create/Update Billing Events

		//*** BEGIN DML operations
		pse__Billing_Event__c billingEvent;
		Database.SaveResult sr;
		pse.BillingEventsManager.InvoiceInfo ii;
		PSA_Billing_Stage__c billStage;

		//Updated Billing Events
		Database.SaveResult[] srList = Database.Update(billingEventsToUpdate, false);
		for (Integer i = 0; i< billingEventsToUpdate.size(); i++) {
			sr = srList[i];
    		billingEvent = billingEventsToUpdate[i];
			if (sr.isSuccess() == true) {
				System.debug('Successfully Updated Billing Event.  Bill. Evt. Id: ' + billingEvent.Id + ' - BillingStageId: ' + billingEvent.PSA_Billing_Stage__c);

				//added the next 4 lines by cklassen 9/21 to utilize native psa billing api for billing
				billStage = billingStageMap.get(billingEvent.PSA_Billing_Stage__c);
				if (billStage.PSA_Integration_Status__c == 'Complete') {
					ii = new pse.BillingEventsManager.InvoiceInfo(billingEvent.Id, billStage.PSA_Invoice_Number__c, billStage.PSA_Invoice_Date__c);
					iiList.add(ii);
				}

				//Write an entry to the Integration Log
				String logMessage = 'Successfully updated Billing Event';
				psaIntegrationUtils.writeLogEntry(billingEvent.PSA_Billing_Stage__c, 'Billing Event', psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, null, billingEvent.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, billingEvent.PSA_Billing_Stage__c, 
					psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE, 'Billing Event', billingEvent.Id);
			}
		}

		//added the next 4 lines by cklassen 9/21 to utilize native psa billing api for billing
		if (iiList.size() > 0) {
			pse.APIBillingService.BillingContextInvoice bc = new pse.APIBillingService.BillingContextInvoice();
			bc.invoiceInfo = iiList;

			pse.APICommonsService.BatchStatus bs =  pse.APIBillingService.invoice(bc);
			system.debug('****** calling - Invoice Billing API - bs = '+ bs);
		}

		//Update the Processed and Processed Date fields
		update billingStageList;

		//BEGIN Integration Log Update
		//	Update the gw integration id in the integration log where applicable
		psaIntegrationUtils.updateGWIds('Billing Event');
		//END update the reference id and gw integration id in the integration log where applicable

		//*** END DML operations
    }

    /**************************************************************************************
    // Name        	: verifyBillingEventExists
    // Description 	: If a Billing event does not exist for the Billing Event Id, return
    //					false, else return true
	// Author       : CLD Partners
	// Revisions    : 2015-04-13  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static Boolean verifyBillingEventExists(Map<Id, pse__Billing_Event__c> billingEventMap, PSA_Billing_Stage__c billingStage) {
    	Boolean billingEventExists = true;
       	if (billingEventMap == null) {
       		billingEventExists = false;
       	} else {
       		pse__Billing_Event__c billingEvent = billingEventMap.get(billingStage.PSA_Billing_Event__c);
       		if (billingEvent == null) {
	       		billingEventExists = false;
       		} else if (billingEvent.PSA_Integration_Status__c != 'Processing Invoice') {
				//Write a Warning entry to the Integration Log
				String logMessage = 'Unexpected Billing Event Status: ' + billingEvent.PSA_Integration_Status__c;
				String integrationType = psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE;

				psaIntegrationUtils.writeLogEntry(billingStage.Id, 'Billing Event', integrationType, 
							psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, billingStage.PSA_GW_Integration_Id__c, billingEvent.Id);
			} 
 		}

    	return billingEventExists;
    }

	/**************************************************************************************
    // Name        	: updateBillingEvent
    // Description 	: Update the Invoice Number and Invoice Date fields for a Billing Event
	// Author       : CLD Partners
	// Revisions    : 2015-04-13  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Billing_Event__c updateBillingEvent(PSA_Billing_Stage__c billingStage, 
    		Map<Id, pse__Billing_Event__c> billingEventMap) {
    	pse__Billing_Event__c billingEvent;
    	System.debug('Billing Stage Record: ' + billingStage);
    	

		try {
			billingEvent = billingEventMap.get(billingStage.PSA_Billing_Event__c);
			
		    //Update the BE with the billing stage id, so later in the code, the invoice date
		    // and invoice number can be retrieved from the appropriate billing stage record
		    // when setting the invoice info for the billing api
		    billingEvent.PSA_Billing_Stage__c = billingStage.Id;

		    //Verify an invoice number and invoice date were included, if the status is set to Complete
		    if (billingStage.PSA_Integration_Status__c == 'Complete' && 
		    		(billingStage.PSA_Invoice_Date__c == null || billingStage.PSA_Invoice_Number__c == null || billingStage.PSA_Invoice_Number__c == '')
		    	) {
				String logMessage = 'Missing Invoice Number and/or Invoice Date';
				String integrationType = psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE;
				psaIntegrationUtils.writeLogEntry(billingStage.Id, 'Billing Event', integrationType, 
							psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, 
							billingStage.PSA_GW_Integration_Id__c, billingEvent.Id);
				return null;					    	
		    }
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType = psaIntegrationUtils.INTERGRATION_TYPE_BILLING_UPDATE;

			psaIntegrationUtils.writeLogEntry(billingStage.Id, 'Billing Event', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
						billingStage.PSA_GW_Integration_Id__c, billingEvent.Id);
			return null;			
		}

    	return billingEvent;
    }

}