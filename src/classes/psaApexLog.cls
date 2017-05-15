/****************************************************************************************
Name            : psaApexLog
Author          : CLD Partners
Created Date    : June 28, 2015
Description     : Contains methods to process PSA Apex Logs
Revisions       : 2015-06-28 - Initial version
				: 2015-08-04 - added insertApexLogRecords and other minor modifications
				: 2015-08-21 - added additional conditional logging controls based on 
								PSA Logging custom setting
				: 2015-08-26 - added apex log insert if size > 500 to keep heap size down 
******************************************************************************************/
public class psaApexLog {

    public static List<PSA_Apex_Log__c> apexLogs = new List<PSA_Apex_Log__c>();
    private static Integer logSequence = 1;
    private static Boolean customSettingsLoaded = false;
    private static String errorEmailList;
    private static Boolean errorLoggingEnabled;
    private static Decimal batchNumber;
    private static Decimal loggingLevelSetting;
    private static Boolean excludeBillingEventGeneration;
    private static Boolean excludeBillingRulesApplication;
    private static Boolean excludeTimecardDailyCap;
    private static Boolean excludeInvoiceSummaryLineRefresh;
    private static Boolean excludeRefreshProjectBillingBalances;
    private static Boolean excludeBillingEventRecalc;
    private static Boolean excludeBillingEventRegenerateController;
    private static Boolean excludeBillingEventRegenerate;

    /**************************************************************************************
    // Name        	: createApexLog
    // Description 	: Create a new apex log record 
	// Author       : CLD Partners
	// Revisions    : 2015-06-28  Klassen  Initial version
	//				: 2015-08-21  Klassen  Added optional logging logic
    ***************************************************************************************/
	public static PSA_Apex_Log__c createApexLog(Integer logLevel, String source, String apexMethod, 
			Integer methodSequence, String message, String longMessage, 
			List<SObject> objectsForIdList) { 
		//Load the custom settings variables if not already loaded - will only have to do this one time
		if (customSettingsLoaded == false) {
			loadCustomSettingsVariables();
		}

		PSA_Apex_Log__c apexLog = new PSA_Apex_Log__c();
		//Only add the apex log if logging is enabled and the log level is at or below the log level setting
		if (errorLoggingEnabled == true && logLevel <= loggingLevelSetting) {
			
			if (batchNumber == null) {
				//get next batch number
				batchNumber = getNextBatchNumber();
			}

			//Only add the apex log if the source is not excluded - one custom setting per source is needed
			if (
				(source == 'psaBillingRulesApplication' && excludeBillingRulesApplication == false) ||
				(source == 'psaRefreshProjectBillingBalances' && excludeRefreshProjectBillingBalances == false) ||
				(source == 'psaInvoiceSummaryLineRefresh' && excludeInvoiceSummaryLineRefresh == false) ||
				(source == 'psaTimecardDailyCap' && excludeTimecardDailyCap == false) ||
				(source == 'psaBillingEventRecalc' && excludeBillingEventRecalc == false) ||
				(source == 'psaBillingEventRegenerateController' && excludeBillingEventRegenerateController == false) ||
				(source == 'psaBillingEventRegenerate' && excludeBillingEventRegenerate == false) ||
				(source == 'psaBillingEventGeneration' && excludeBillingEventGeneration == false)
			) {
				apexLog.PSA_Source__c = source;
				apexLog.PSA_Sequence__c = logSequence;
				apexLog.PSA_Message__c = message;
				apexLog.PSA_Long_Message__c = longMessage;
				apexLog.PSA_Apex_Method__c = apexMethod;
				apexLog.PSA_Method_Sequence__c = methodSequence;
				apexLog.PSA_Log_DateTime__c = DateTime.now();
				apexLog.PSA_Batch_Number__c = batchNumber;
				apexLog.PSA_Log_Level__c = logLevel;
				if (objectsForIdList != null && objectsForIdList.size() > 0) {
					apexLog.PSA_Id_List__c = getIdList(objectsForIdList);
				}
				apexLogs.add(apexLog);

				//Check the apex log list size and reset it if over 500
				// This helps with keeping the Heap Size down
				if (apexLogs.size() >= 500) {
					insertApexLogRecords();
				}
				logSequence+=1;
			}
		}

		return apexLog;
    }

    /**************************************************************************************
    // Name        	: createApexLogGovernerLimits
    // Description 	: Create a new apex log record with governor limits
	// Author       : CLD Partners
	// Revisions    : 2015-06-28  Klassen  Initial version
	//				: 
    ***************************************************************************************/
	public static PSA_Apex_Log__c createApexLogGovernerLimits(String source, String apexMethod) { 
		String message = 'SOQL:' + Limits.getQueries() + '-';
		message += 'Rows Queried:' + Limits.getQueryRows() + '-';
		message += 'DML Rows:' + Limits.getDmlRows() + '-';
		message += 'DML Statements:' + Limits.getDmlStatements() + '-';
		message += 'CPU Time:' + Limits.getCpuTime() + '-';
		message += 'Heap Size:' + Limits.getHeapSize() + '-';
		message += 'Apex Log Size (additional DML Rows):' + apexLogs.size();

		String longMessage = 'SOQL Queries Limit:' + Limits.getLimitQueries() + '-';
		longMessage += 'Rows Queried Limit:' + Limits.getLimitQueryRows() + '-';
		longMessage += 'Total DML Records Limit:' + Limits.getLimitDmlRows() + '-';
		longMessage += 'Total DML Statements Limit:' + Limits.getLimitDmlStatements() + '-';
		longMessage += 'Total CPU Usage time (in ms) Limit:' + Limits.getLimitCpuTime();
		longMessage += 'Total Heap Size Limit:' + Limits.getLimitHeapSize();

		return createApexLog(1, source, apexMethod, 0, message, longMessage, null);
	} 

    /**************************************************************************************
    // Name        	: insertApexLogRecords
    // Description 	: Insert new records if there are any.  If the number of apex log records
    //					being inserted will exceed the dml records governor limit, remove
    //					the records, starting with the earliest ones.  Attach the removed
    //					logs to an email that will get sent for further analysis
	// Author       : CLD Partners
	// Revisions    : 2015-08-04  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static void insertApexLogRecords() {
    	Integer totalDMLRows = Limits.getDmlRows();
    	Integer dmlRowLimit = Limits.getLimitDmlRows();
    	Integer apexLogsSize = apexLogs.size();
    	Integer currentApexLogSize=apexLogsSize;
    	Integer remainingDMLRows = dmlRowLimit - totalDMLRows;
    	System.debug(LoggingLevel.ERROR, 'Total DML Rows and Apex Log Size:' + totalDMLRows + ' & ' + apexLogsSize);
    	List<String> removedLogsStringList = new List<String>();
    	String removedLogsString = '';
    	Integer logSplitSize = 250;

        if (apexLogs.size()>0) {

        	//Sort the apex log list by log date/time desc
        	psaApexLogSortWrapper[] apexLogWrapperList = new List<psaApexLogSortWrapper>();
	        for (PSA_Apex_Log__c apexLog : apexLogs) {
	            apexLogWrapperList.add(new psaApexLogSortWrapper(apexLog));
	        }
	        apexLogWrapperList.sort();

        	if (apexLogsSize > remainingDMLRows) {
        		//remove rows from apexLogs list, starting with the most granular level
        		Integer rowsToRemove = apexLogsSize - remainingDMLRows;
				Integer rowsRemovedCount = 0;
				PSA_Apex_Log__c apexLog;

				System.debug(LoggingLevel.ERROR, 'Start by removing Log Level 3 rows (rows to remove): ' + rowsToRemove);
				//Loop through and remove logs at level 3
				for (Integer i=apexLogsSize-1; i>=0;i--) {
					apexLog = apexLogWrapperList[i].apexLog;
					if (apexLog.PSA_Log_Level__c == 3) {
						apexLogs.remove(i);
						removedLogsString+=apexLog;
						removedLogsString+='\n';
						rowsRemovedCount++;
						currentApexLogSize--;
						if (math.mod(rowsRemovedCount, logSplitSize) == 0) {
							removedLogsStringList.add(removedLogsString);
							removedLogsString = '';
						}
					}
					if (rowsRemovedCount >= rowsToRemove) {
						break;
					}
				}
				System.debug(LoggingLevel.ERROR, 'Current Rows Removed Count: ' + rowsRemovedCount);
				apexLogsSize = currentApexLogSize;
				//System.debug(LoggingLevel.ERROR, 'Current Apex Logs Size: '+apexLogsSize);

				//Loop through and remove logs at level 2 if needed
				if (rowsRemovedCount < rowsToRemove) {
					System.debug(LoggingLevel.ERROR, 'Still have Level 2 rows to remove: ' + (rowsToRemove - rowsRemovedCount));
					for (Integer i=apexLogsSize-1; i>=0;i--) {
						apexLog = apexLogWrapperList[i].apexLog;
						if (apexLog.PSA_Log_Level__c == 2) {
							removedLogsString+=apexLog;
							removedLogsString+='\n';
							apexLogs.remove(i);
							rowsRemovedCount++;
							currentApexLogSize--;
							if (math.mod(rowsRemovedCount, logSplitSize) == 0) {
								removedLogsStringList.add(removedLogsString);
								removedLogsString = '';
							}
						}
						if (rowsRemovedCount >= rowsToRemove) {
							break;
						}
					}
				}
				System.debug(LoggingLevel.ERROR, 'Current Rows Removed Count: ' + rowsRemovedCount);
				apexLogsSize = currentApexLogSize;
				//System.debug(LoggingLevel.ERROR, 'Current Apex Logs Size: '+apexLogsSize);

				//Loop through and remove logs at level 1 if needed
				if (rowsRemovedCount < rowsToRemove) {
					System.debug(LoggingLevel.ERROR, 'Still have Level 1 rows to remove: ' + (rowsToRemove - rowsRemovedCount));
					for (Integer i=apexLogsSize-1; i>=0;i--) {
						apexLog = apexLogWrapperList[i].apexLog;
						if (apexLog.PSA_Log_Level__c == 1) {
							removedLogsString+=apexLog;
							removedLogsString+='\n';
							apexLogs.remove(i);
							rowsRemovedCount++;
							currentApexLogSize--;
							if (math.mod(rowsRemovedCount, logSplitSize) == 0) {
								removedLogsStringList.add(removedLogsString);
								removedLogsString = '';
							}
						}
						if (rowsRemovedCount >= rowsToRemove) {
							break;
						}
					}
				}
				System.debug(LoggingLevel.ERROR, 'Current Rows Removed Count: ' + rowsRemovedCount);
				apexLogsSize = currentApexLogSize;
				System.debug(LoggingLevel.ERROR, 'Current Apex Logs Size: '+apexLogsSize);

	        	if (rowsRemovedCount > 0) {
	        		//Add final removedLogsString variable to the list
	        		removedLogsStringList.add(removedLogsString);

		        	//Email string of deleted logs for future use if needed
		        	sendDebugEmail('Apex Logging: Apex Logs Removed - ' + rowsRemovedCount + ' Total', 'see attachment for details', removedLogsStringList);
	        	}
        	}

            insert apexLogs;
            apexLogs = new List<PSA_Apex_Log__c>();
        }
    }

    /**************************************************************************************
    // Name        	: loadCustomSettingsVariables
    // Description 	: If the custom settings variables haven't been loaded, do it now
	// Author       : CLD Partners
	// Revisions    : 2015-08-21  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static void loadCustomSettingsVariables() {
    	if (customSettingsLoaded == false) {
    		//Set the default values
			errorEmailList = '';
			loggingLevelSetting = 0;
			errorLoggingEnabled = false;
			excludeBillingEventGeneration = false;
			excludeBillingRulesApplication = false;
			excludeTimecardDailyCap = false;
			excludeInvoiceSummaryLineRefresh = false;
			excludeRefreshProjectBillingBalances = false;
			excludeBillingEventRecalc = false;
    		excludeBillingEventRegenerateController = false;
    		excludeBillingEventRegenerate = false;

			PSA_Logging__c psaLogging = PSA_Logging__c.getValues('default');
			if (psaLogging != null) {
				if (psaLogging.PSA_Logging_Level__c != null) {
					loggingLevelSetting = psaLogging.PSA_Logging_Level__c;
				}
				if (psaLogging.PSA_Enable_Apex_Logging__c != null) {
					errorLoggingEnabled = psaLogging.PSA_Enable_Apex_Logging__c;
				}
				if (psaLogging.PSA_Error_Email_List__c != null) {
					errorEmailList = psaLogging.PSA_Error_Email_List__c;
				}
				if (psaLogging.PSA_No_psaBillingEventGeneration__c != null) {
					excludeBillingEventGeneration = psaLogging.PSA_No_psaBillingEventGeneration__c;
				}
				if (psaLogging.PSA_No_psaBillingRulesApplication__c != null) {
					excludeBillingRulesApplication = psaLogging.PSA_No_psaBillingRulesApplication__c;
				}
				if (psaLogging.PSA_No_psaTimecardDailyCap__c != null) {
					excludeTimecardDailyCap = psaLogging.PSA_No_psaTimecardDailyCap__c;
				}
				if (psaLogging.PSA_No_psaInvoiceSummaryLineRefresh__c != null) {
					excludeInvoiceSummaryLineRefresh = psaLogging.PSA_No_psaInvoiceSummaryLineRefresh__c;
				}
				if (psaLogging.PSA_No_psaRefreshProjectBillingBalances__c != null) {
					excludeRefreshProjectBillingBalances = psaLogging.PSA_No_psaRefreshProjectBillingBalances__c;
				}
				if (psaLogging.PSA_No_psaBillingEventRecalc__c != null) {
					excludeBillingEventRecalc = psaLogging.PSA_No_psaBillingEventRecalc__c;
				}
				if (psaLogging.PSA_No_psaBillingEventRegenerateControl__c != null) {
					excludeBillingEventRegenerateController = psaLogging.PSA_No_psaBillingEventRegenerateControl__c;
				}
				if (psaLogging.PSA_No_psaBillingEventRegenerate__c != null) {
					excludeBillingEventRegenerate = psaLogging.PSA_No_psaBillingEventRegenerate__c;
				}
			}
    	
			customSettingsLoaded = true;
    	}
    }

    /**************************************************************************************
    // Name        	: getNextBatchNumber
    // Description 	: Find the maximum batch number value and add 1 to it.
	// Author       : CLD Partners
	// Revisions    : 2015-08-04  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static Decimal getNextBatchNumber() {
		Decimal nextBatchNumber = 0;
		List<PSA_Apex_Log__c> apexLogList = 
			[select PSA_Batch_Number__c
				from PSA_Apex_Log__c
				order by PSA_Batch_Number__c desc
				limit 1
			];
		if (apexLogList != null && apexLogList.size() > 0) {
			nextBatchNumber = apexLogList[0].PSA_Batch_Number__c + 1;
		}
/*
		AggregateResult[] ar = 
			[select max(PSA_Batch_Number__c) MaxBatchNumber from PSA_Apex_Log__c];
		if (ar != null) {
			nextBatchNumber = (Decimal)ar[0].get('MaxBatchNumber');
		}
		if (nextBatchNumber == null) {
			nextBatchNumber = 0;
		}
		nextBatchNumber +=1;
*/
		return nextBatchNumber;
    }

    /**************************************************************************************
    // Name        	: getIdList
    // Description 	: Build a string of object Id values 
	// Author       : CLD Partners
	// Revisions    : 2015-06-28  Klassen  Initial version
	//				: 2015-08-04  Klassen  Added error handling and size limits
    ***************************************************************************************/
    private static String getIdList(List<SObject> objectList) {
    	Try {
	    	String idList = '';
	    	Integer counter = 0;
	    	for (SObject obj : objectList) {
	    		counter++;
	    		idList += obj.Id + ', ';
	    		if (counter > 5000) {
	    			idList += '...';
	    			break;
	    		}
	    	}
	    	if (counter > 0 && counter <= 5000) {
	    		idList = 'Id Count: ' + counter + ': ' + idList;
	    	} else if (counter > 0) {
	    		idList = 'Id Count: ' + objectList.size() + ': ' + idList;
	    	}
	    	return idList;
    	} Catch (Exception e) {
	    	return 'error building id list for sobject type: ' + objectList.getSObjectType();
    	}
    }

  /**************************************************************************************
  // Name         : sendDebugEmail
  // Description  : This method sends a debug notification via email
  // Author       : CLD Partners
  // Revisions    : 2015-08-20  Klassen  Initial Implementation
  //              : 
  ***************************************************************************************/
  public static void sendDebugEmail(String subjectText, String bodyText, List<String> attachTextList) {
      if (errorEmailList != '') {
        // Send an debug notification email 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String[] toAddresses = errorEmailList.split(',');       
        mail.setToAddresses(toAddresses);
        mail.setSubject(subjectText);
        mail.setPlainTextBody(bodyText);

		// Create the email attachment
		Blob b;
		String fileName;
		Integer counter = 0;
		List<Messaging.EmailFileattachment> efaList = new List<Messaging.EmailFileattachment>();
		for (String attachText : attachTextList) {
			if (attachText != '') {
				counter++;
				fileName = 'logs_' + counter + '_of_' + attachTextList.size() + '.doc';
				b = Blob.valueOf(attachText);
		        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
		        efa.setContentType('application/doc');
		        efa.setFileName(fileName);
		        efa.setBody(b);
		        efaList.add(efa);
			}
		}
		if (efaList.size() > 0) {
			mail.setFileAttachments(efaList);
		}

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      } else {
        System.debug(LoggingLevel.ERROR, 'No Email List values to send an debug notification to in PSA Logging Custom Setting');
      }
  }

}