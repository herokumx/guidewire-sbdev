/****************************************************************************************
Name            : psaInvoiceSummaryLineRefresh
Author          : CLD Partners
Created Date    : April 22, 2015
Description     : Rebuilds the Invoice Summary lines for billing events that have just had
					billing rules applied to them
Revisions       : 2015-04-22 - Initial version (extracted from psaBillingRulesApplication)
				: 2015-08-04 - Added custom apex debug logging
                : 2015-11-17 - Modified to use Expense and Misc. Adj. source amounts rather than BEI amounts
******************************************************************************************/
public class psaInvoiceSummaryLineRefresh {
    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaInvoiceSummaryLineRefresh';
    private static Integer apexLogMethodSequenceMaster = 0;

    public psaInvoiceSummaryLineRefresh() {}

    /**************************************************************************************
    // Name        	: refreshInvoiceSummaryLines
    // Description 	: After Billing Rules have been applied, re-create all Invoice Summary Lines for each Billing
    //					Event that was just updated.
	// Author       : CLD Partners
	// Revisions    : 2015-03-01  Klassen  Initial version (prototype)
	//				: 2015-04-21  Klassen  Initial Implementation
    ***************************************************************************************/
    public static void refreshInvoiceSummaryLines(Set<Id> projectIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'refreshInvoiceSummaryLines';

        //Clear out existing InvoiceSummaryLines for the current set of Projects (un-released billing events only)
        delete [Select Id
            From PSA_Invoice_Summary_Line__c
            Where PSA_Billing_Event__c In (
                Select Id 
                From pse__Billing_Event__c
                Where pse__Project__c = :projectIds
                And pse__Is_Released__c = false
            )
        ];

        List<PSA_Invoice_Summary_Line__c> invoiceSummaryLinesToInsert = new List<PSA_Invoice_Summary_Line__c>();
        PSA_Invoice_Summary_Line__c invoiceSummaryLine;
        List<pse__Billing_Event_Item__c> beItems = 
            [Select pse__Billing_Event__c, pse__Billing_Event__r.Name, pse__Timecard_Split__c, pse__Expense__c, 
                    pse__Milestone__c, pse__Milestone__r.PSA_Milestone_Type__c, pse__Milestone__r.PSA_Invoice_Description__c, 
                    pse__Miscellaneous_Adjustment__c, pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, 
                    pse__Miscellaneous_Adjustment__r.pse__Amount__c, pse__Miscellaneous_Adjustment__r.Name, pse__Amount__c, 
                    pse__Miscellaneous_Adjustment__r.pse__Description__c, pse__Timecard_Split__r.pse__Total_Billable_Amount__c, 
                    pse__Billing_Event__r.CurrencyISOCode, pse__Expense__r.pse__Billing_Amount__c, pse__Milestone__r.pse__Milestone_Amount__c  
                From pse__Billing_Event_Item__c
                Where pse__Project__c = :projectIds
                And pse__Billing_Event__r.pse__Is_Released__c = false
                And pse__Billing_Event__c != null 
                Order By pse__Billing_Event__c, pse__Timecard_Split__c , pse__Expense__c, pse__Milestone__c, 
                    pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c
            ];
        System.debug('Inv Sum Ref: beItems: ' + beItems);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Inv Sum Ref: beItems', String.valueOf(beItems), (List<SObject>)beItems);

        if (beItems != null && beItems.size() > 0) {
            String previousKey = 'InitialValueOfPreviousKey';
            String currentKey;
            String currentLineType;
            Decimal currentAmount;
            for (pse__Billing_Event_Item__c beItem : beItems) {
                currentKey = getInvoiceSummaryLineKey(beItem);
                if (currentKey != previousKey) {
                    if (invoiceSummaryLine != null) {
                        invoiceSummaryLinesToInsert.add(invoiceSummaryLine);
                    }
                    invoiceSummaryLine = new PSA_Invoice_Summary_Line__c();
                    invoiceSummaryLine.Name = currentKey;
                    invoiceSummaryLine.PSA_Billing_Event__c = beItem.pse__Billing_Event__c;
                    invoiceSummaryLine.PSA_Summary_Line_Type__c = getInvoiceSummaryLineType(beItem);
                    invoiceSummaryLine.PSA_Description__c = getInvoiceSummaryLineDescription(beItem);
                    invoiceSummaryLine.PSA_Amount__c = 0.0;
                    invoiceSummaryLine.CurrencyISOCode = beItem.pse__Billing_Event__r.CurrencyISOCode;   
                }
                //Special logic to handle a holdback release problem where the be item amount doesn't match the misc. adj. amount
                if (beItem.pse__Miscellaneous_Adjustment__c != null && beItem.pse__Amount__c != beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c) {
                    beItem.pse__Amount__c = beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
                } else if (beItem.pse__Timecard_Split__c != null && beItem.pse__Amount__c != beItem.pse__Timecard_Split__r.pse__Total_Billable_Amount__c) {
                    beItem.pse__Amount__c = beItem.pse__Timecard_Split__r.pse__Total_Billable_Amount__c;
                } else if (beItem.pse__Expense__c != null && beItem.pse__Amount__c != beItem.pse__Expense__r.pse__Billing_Amount__c) {
                    beItem.pse__Amount__c = beItem.pse__Expense__r.pse__Billing_Amount__c;
                } else if (beItem.pse__Milestone__c != null && beItem.pse__Amount__c != beItem.pse__Milestone__r.pse__Milestone_Amount__c) {
                    beItem.pse__Amount__c = beItem.pse__Milestone__r.pse__Milestone_Amount__c;
                }

                invoiceSummaryLine.PSA_Amount__c += beItem.pse__Amount__c;

                previousKey = currentKey;
            }
            invoiceSummaryLinesToInsert.add(invoiceSummaryLine);            
        }

        //If there are any invoice summary lines, consolidate them and then insert them
        if (invoiceSummaryLinesToInsert.size() > 0) {
            //System.debug('invoiceSummaryLinesToInsert:' + invoiceSummaryLinesToInsert);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'invoiceSummaryLinesToInsert', String.valueOf(invoiceSummaryLinesToInsert), null);

            //Rollup the invoice summary lines by Type (although the query was sorted, multiple records
            // for the same type could have been created)
            insert combineInvoiceSummaryLinesByType(invoiceSummaryLinesToInsert);
        }
    }

    /**************************************************************************************
    // Name         : combineInvoiceSummaryLinesByType
    // Description  : Rollup invoice summary lines with the same line type.  This method
    //                  uses a custom "Sort Wrapper" class to allow the Billing Event Item
    //                  records to be sorted in a custom way.  Salesforce has no other way
    //                  to sort SObjects in a non-standard way.  In this case, we need to be
    //                  able to sort by the Summary Line Type
    // Author       : CLD Partners 
    // Revisions    : 2015-04-21  Klassen  Initial Implementation
    ***************************************************************************************/
    private static List<PSA_Invoice_Summary_Line__c> combineInvoiceSummaryLinesByType(List<PSA_Invoice_Summary_Line__c> invoiceSummaryLines) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'combineInvoiceSummaryLinesByType';

        List<PSA_Invoice_Summary_Line__c> combinedInvoiceSummaryLines = new List<PSA_Invoice_Summary_Line__c>();

        psaInvoiceSummaryLineSortWrapper[] invSumLineWrapperList = new List<psaInvoiceSummaryLineSortWrapper>();
        for (PSA_Invoice_Summary_Line__c invoiceSummaryLine : invoiceSummaryLines) {
            invSumLineWrapperList.add(new psaInvoiceSummaryLineSortWrapper(invoiceSummaryLine));
        }
        invSumLineWrapperList.sort();
        System.debug('invSumLineWrapperList:' + invSumLineWrapperList);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'invSumLineWrapperList', String.valueOf(invSumLineWrapperList), null);

        PSA_Invoice_Summary_Line__c InvoiceSummaryLine;
        PSA_Invoice_Summary_Line__c previousInvoiceSummaryLine;
        String previousKey = 'InitialValueOfPreviousKey';
        String currentKey;
        Decimal runningTotal = 0.0;
        for (psaInvoiceSummaryLineSortWrapper invoiceSummaryLineWrapper : invSumLineWrapperList) {
            invoiceSummaryLine = invoiceSummaryLineWrapper.invoiceSummaryLine;
            currentKey = invoiceSummaryLine.Name;
            //System.debug('current Key:' + currentKey);
            if (currentKey != previousKey) {
                if (previousInvoiceSummaryLine != null) {
                    previousInvoiceSummaryLine.PSA_Amount__c = runningTotal;
                    combinedInvoiceSummaryLines.add(previousInvoiceSummaryLine);
                    runningTotal = 0.0;
                }
            }
            runningTotal += invoiceSummaryLine.PSA_Amount__c;

            previousKey = currentKey;
            previousInvoiceSummaryLine = invoiceSummaryLine;
        }
        //Add the final line
        previousInvoiceSummaryLine.PSA_Amount__c = runningTotal;
        combinedInvoiceSummaryLines.add(previousInvoiceSummaryLine);
    
        //System.debug('combinedInvoiceSummaryLines:' + combinedInvoiceSummaryLines);

        return combinedInvoiceSummaryLines;
    }

    /**************************************************************************************
    // Name        	: getInvoiceSummaryLineDescription
    // Description 	: Set the Invoice Summary Line Description field.  The "default" logic
    //                  is to use same value as the Invoice Summary Line Type
	// Author       : CLD Partners
	// Revisions    : 2015-04-21  Klassen  Initial Implementation (STUB)
    ***************************************************************************************/
    private static String getInvoiceSummaryLineDescription(pse__Billing_Event_Item__c beItem) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getInvoiceSummaryLineDescription';

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Item', String.valueOf(beItem), null);

        String lineDescription = 'TBD';
        if (beItem.pse__Timecard_Split__c != null) {
        	//BR 1: Services Time and Materials
            lineDescription = 'Consulting Services';
        } else if (beItem.pse__Milestone__c != null) {
            //BR 2 and 3: Services Fixed Fee or Fixed Fee Expenses
        	lineDescription = beItem.pse__Milestone__r.PSA_Invoice_Description__c != null ? beItem.pse__Milestone__r.PSA_Invoice_Description__c : '';
        } else if (beItem.pse__Expense__c != null) {
        	//Br 4: Expenses As Incurred
            lineDescription = 'Billable Expenses Charge - As Incurred';
        } else if (beItem.pse__Miscellaneous_Adjustment__c != null) {
    		if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Time and Materials') {
    			//BR 1: Services Time and Materials
    			lineDescription = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Fixed Fee') {
    			//BR 2: Services Fixed Fee
    			lineDescription = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - Fixed Amount') {
    			//BR 3: Fixed Fee Expenses
    			lineDescription = 'Billable Expenses Charge - Fixed Amount';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - As Incurred') {
    			//BR 4: Expenses as Incurred
    			lineDescription = 'Billable Expenses Charge - As Incurred';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Percent of Services') {
    			//BR 5: Expenses as a Percent of Services
                lineDescription = 'Billable Expenses Charge - As % of Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Flat Amount') {
    			//BR 6: Expenses as Flat Amount per Day
                lineDescription = 'Billable Expenses Charge - As Flat Amount per Day';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Percent of Services') {
    			//BR 7: Expenses - Cap at Percent of Services
                lineDescription = 'Billable Expenses Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Flat Amount') {
    			//BR8: Expenses - Cap at Flat Amount
                lineDescription = 'Billable Expenses Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Minimum Hours') {
    			//BR 9: Services - Minimum Billable Hours - Monthly
    			lineDescription = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Cap Flat Amount') {
    			//BR 10: Services - Cap at Flat Amount
                lineDescription = 'Consulting Services Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Holdback') {
                //BR 11: Services - Holdback
    			lineDescription = 'Holdback';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Holdback Release') {
                //BR 11: Services - Holdback
    			lineDescription = 'Holdback Release';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Customer Discount') {
                //BR 12: Services - Discount - Project-Level
    			lineDescription = 'Customer Credit - Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Project Discount') {
                //BR 13: Services - Discount - Account-Level
    			lineDescription = 'Customer Credit - Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Domestic LTA') {
                //BR 14: Domestic LTA
    			lineDescription = beItem.pse__Miscellaneous_Adjustment__r.pse__Description__c;
    		} else {
                //Unknown misc. adj...
    			lineDescription = 'TBD-Misc. Adj.:' + beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c;
    		}
        }

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Line Description', lineDescription, null);

        return lineDescription;
    }

    /**************************************************************************************
    // Name        	: getInvoiceSummaryLineType
    // Description 	: Determine the Invoice Summary Line Type based on the source of the 
    //					Billing Event Item and potentially values for the related Billing 
    //					Event Item Source object such as Milestone Type and Billing Rule Type
	// Author       : CLD Partners
	// Revisions    : 2015-03-01  Klassen  Initial version (prototype)
	//				: 2015-04-21  Klassen  Initial Implementation
    ***************************************************************************************/
    private static String getInvoiceSummaryLineType(pse__Billing_Event_Item__c beItem) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getInvoiceSummaryLineType';

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Item', String.valueOf(beItem), null);

        String lineType = '';
        if (beItem.pse__Timecard_Split__c != null) {
        	//BR 1: Services Time and Materials
            lineType = 'Consulting Services';
        } else if (beItem.pse__Milestone__c != null) {
        	if (beItem.pse__Milestone__r.PSA_Milestone_Type__c != null && beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Services - Fixed') {
        		//BR 2: Fixed Fee Services
        		lineType = 'Consulting Services';
        	} else if (beItem.pse__Milestone__r.PSA_Milestone_Type__c != null && beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Expenses - Fixed') { 
        		//BR 3: Fixed Amount Expenses
            	lineType = 'Billable Expenses Charge - Fixed Amount';
        	} else {
        		//Unknown line type
        		lineType = 'TBD-Milestone:' + beItem.pse__Milestone__r.PSA_Milestone_Type__c;
        	}
        } else if (beItem.pse__Expense__c != null) {
        	//Br 4: Expenses As Incurred
            lineType = 'Billable Expenses Charge - As Incurred';
        } else if (beItem.pse__Miscellaneous_Adjustment__c != null) {
    		if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Time and Materials') {
    			//BR 1: Services Time and Materials
    			lineType = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Fixed Fee') {
    			//BR 2: Services Fixed Fee
    			lineType = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - Fixed Amount') {
    			//BR 3: Fixed Amount Expenses
    			lineType = 'Billable Expenses Charge - Fixed Amount';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - As Incurred') {
    			//BR 4: Expenses as Incurred
    			lineType = 'Billable Expenses Charge - As Incurred';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Percent of Services') {
    			lineType = 'Billable Expenses Charge - As % of Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Flat Amount') {
    			lineType = 'Billable Expenses Charge - As Flat Amount per Day';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Percent of Services') {
    			lineType = 'Billable Expenses Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Flat Amount') {
    			lineType = 'Billable Expenses Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Minimum Hours') {
    			//BR 9: Minimum Hours Monthly
    			lineType = 'Consulting Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Cap Flat Amount') {
    			lineType = 'Consulting Services Credit';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Holdback') {
    			lineType = 'Holdback';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Holdback Release') {
    			lineType = 'Holdback Release';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Customer Discount') {
    			lineType = 'Customer Credit - Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Project Discount') {
    			lineType = 'Customer Credit - Services';
    		} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Domestic LTA') {
    			lineType = 'LTA';
    		} else {
    			if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == null) {
    				lineType = 'Misc. Adj.: ' + beItem.pse__Miscellaneous_Adjustment__r.Name;
    			} else { 
	    			lineType = 'Misc. Adj.:' + beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c;
    			}
    		}
        }

        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Line Type', lineType, null);

        return lineType;
    }

    /**************************************************************************************
    // Name        	: getInvoiceSummaryLineKey
    // Description 	: Set a lineKey which is used to roll up individual Billing Event Items
    //					by Source object, including some fields on the Source objects such as
    //					as Milestone Type and Billing Rule Type
	// Author       : CLD Partners
	// Revisions    : 2015-03-01  Klassen  Initial version (prototype)
	//				: 2015-04-21  Klassen  Initial Implementation
    ***************************************************************************************/
    private static String getInvoiceSummaryLineKey(pse__Billing_Event_Item__c beItem) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getInvoiceSummaryLineKey';

        String lineKey = beItem.pse__Billing_Event__r.Name + ':';
        System.debug('lineKey Start:' + lineKey);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'lineKey Start: ' + lineKey, null, null);

        if (beItem.pse__Timecard_Split__c != null) {
        	//BR 1: Timecards (Services - Time and Materials)
            lineKey += 'Consulting Services';
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Timecard BEI: ' + beItem.pse__Timecard_Split__c, null, null);
        } else if (beItem.pse__Milestone__c != null) {
        	lineKey += beItem.pse__Milestone__c;
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Milestone BEI: ' + beItem.pse__Milestone__c, null, null);
        	/*
        	if (beItem.pse__Milestone__r.PSA_Milestone_Type__c != null && beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Services - Fixed') {
        		//BR 2: Fixed Fee Services
        		lineKey += 'Consulting Services';
        	} else if (beItem.pse__Milestone__r.PSA_Milestone_Type__c != null && beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Expenses - Fixed') { 
        		//BR 3: Fixed Fee Expenses
            	lineKey += 'Billable Expenses Charge - Fixed Amount';
        	} else {
        		//Unknown line type
        		lineKey += 'TBD:' + beItem.pse__Milestone__r.PSA_Milestone_Type__c;
        	}
			*/
        } else if (beItem.pse__Expense__c != null) {
        	//BR 4: Expenses As Incurred
            lineKey += 'Billable Expenses';
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Expense BEI: ' + beItem.pse__Expense__c, null, null);
        } else if (beItem.pse__Miscellaneous_Adjustment__c != null && beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c != null) {
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Misc. Adj. BEI: ' + beItem.pse__Miscellaneous_Adjustment__c, 'Billing Rule Type: ' + beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, null);

            //If more than one Billing Rule Type value gets rolled up on the same line, set the lineKey to a specific
            // value.  Otherwise, just use the Billing Rule Type value as the lineKey
            if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Minimum Hours') {
                //BR 9: Minimum Monthly Hours
                lineKey += 'Consulting Services';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Time and Materials') {
                //Non-billing rule created misc. adj.
                lineKey += 'Consulting Services';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Fixed Fee') {
                //BR 2: Services Fixed Fee
                lineKey += 'Consulting Services';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Percent of Services') {
                //BR 7: Expenses Cap Pct of Services
                lineKey += 'Billable Expenses Credit';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Flat Amount') {
                //BR 8: Expenses Cap Flat Amount
                lineKey += 'Billable Expenses Credit';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Customer Discount') {
                //BR 13: Account-level Discount
                lineKey += 'Customer Credit - Services';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Project Discount') {
                //BR 12: Project-level Discount
                lineKey += 'Customer Credit - Services';
            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Domestic LTA') {
                //BR 14: Domestic LTA
                lineKey += beItem.pse__Miscellaneous_Adjustment__c;
            } else {
                lineKey += beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c;
            }
        }

        System.debug('lineKey End:' + lineKey);
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'lineKey End: ' + lineKey, null, null);

        return lineKey;
    }

}