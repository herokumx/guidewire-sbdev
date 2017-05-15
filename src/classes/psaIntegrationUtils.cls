/****************************************************************************************
Name            : psaIntegrationUtils
Author          : CLD Partners
Created Date    : March 12, 2015
Description     : Contains methods to process Integrations, including logging errors
Revisions       : 3/12/15 - Initial version
				: 4/13/15 - Switched logic in the updateGWIds method to use nested for loops
******************************************************************************************/
public with sharing class psaIntegrationUtils {
	public static final String LOG_TYPE_ERROR = 'Error';
	public static final String LOG_TYPE_WARNING  = 'Warning';
	public static final String LOG_TYPE_INFORMATION  = 'Information';
	public static final String INTERGRATION_TYPE_NEW_RESOURCE  = 'Resource-New';
	public static final String INTERGRATION_TYPE_UPDATED_RESOURCE  = 'Resource-Update';
	public static final String INTERGRATION_TYPE_LOA  = 'Resource-LOA';
	public static final String INTERGRATION_TYPE_TERMINATION  = 'Resource-Termination';
	public static final String INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST  = 'Time Off Request-New';
	public static final String INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION  = 'Time Off Request-Correction';
	public static final String INTERGRATION_TYPE_BILLING_UPDATE  = 'Billing-Update';
	public static final String INTERGRATION_TYPE_EXPENSE_UPDATE  = 'Expense-Update';
	public static final String INTERGRATION_TYPE_PROJECT_REVENUE  = 'Project Revenue';
	public static List<PSA_Integration_Log__c> integrationLogsToUpdate;

	public psaIntegrationUtils(){}

	public static void logDatabaseErrors(Database.Error[] errs, Boolean writeToIntegrationLog, String referenceId, 
			String integrationType, String logCategory, String gwIntegrationId, Id targetId) {
        
        for(Database.Error err : errs) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Fields that affected this error: ' + err.getFields());

	        if (writeToIntegrationLog) {
				//Write an entry to the Integration Log
				String logMessage = err.getStatusCode() + ': ' + err.getMessage();
				writeLogEntry(referenceId, logCategory, integrationType, 
					psaIntegrationUtils.LOG_TYPE_ERROR, logMessage.left(255), String.valueOf(err.getFields()), 
					gwIntegrationId, targetId);
	        }
        }
	}

	public static void logDatabaseErrors(Database.Error[] errs, Boolean writeToIntegrationLog, String referenceId, 
			String integrationType, String logCategory, Id targetId) {
        for(Database.Error err : errs) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Fields that affected this error: ' + err.getFields());

	        if (writeToIntegrationLog) {
				//Write an entry to the Integration Log
				String logMessage = err.getStatusCode() + ': ' + err.getMessage();
				writeLogEntry(referenceId, logCategory, integrationType, 
					psaIntegrationUtils.LOG_TYPE_ERROR, logMessage.left(255), String.valueOf(err.getFields()), 
					null, targetId);
	        }
        }
	}

	public static Boolean writeLogEntry(String referenceId, String logCategory, String integrationType, 
			String logType, String message, String debugMessage, String gwIntegrationId, Id targetId) {
		Boolean successFlag = true; //assume success
		PSA_Integration_Log__c integrationLog = new PSA_Integration_Log__c();
		integrationLog.PSA_Reference_Id__c = referenceId;
		integrationLog.PSA_Integration_Type__c = integrationType;
		integrationLog.PSA_Log_Type__c = logType;
		integrationLog.PSA_Log_Category__c = logCategory;
		integrationLog.PSA_Message__c = message;
		integrationLog.PSA_Debug_Message__c = debugMessage;
		integrationLog.PSA_GW_Integration_Id__c = gwIntegrationId;
		if (logCategory == 'Resource') {
			integrationLog.PSA_Resource__c = targetId;
		}
		if (logCategory == 'User') {
			integrationLog.PSA_User__c = targetId;
		}
		if (logCategory == 'Billing Event') {
			integrationLog.PSA_Billing_Event__c = targetId;
		}
		if (logCategory == 'Expense Report') {
			integrationLog.PSA_Expense_Report__c = targetId;
		}
		if (logCategory == 'Assignment') {
			integrationLog.PSA_Assignment__c = targetId;
		}
		if (logCategory == 'Schedule') {
			integrationLog.PSA_Schedule__c = targetId;
		}
		if (logCategory == 'Schedule Exception') {
			integrationLog.PSA_Schedule_Exception__c = targetId;
		}

		insert integrationLog;
		return successFlag;
	}

	public static void updateGWIds(String updateType) {
		integrationLogsToUpdate = new List<PSA_Integration_Log__c>();
		Set<String> integrationLogReferenceIds = new Set<String>();

		List<PSA_Integration_Log__c> integrationLogs = 
			[Select Id, PSA_Reference_Id__c, PSA_GW_Integration_Id__c, LastModifiedDate 
				From PSA_Integration_Log__c
				Where PSA_Reference_Id__c != null 
				And PSA_GW_Integration_Id__c = null
				Order By LastModifiedDate Desc
				LIMIT 25000
			];
		if (integrationLogs != null && integrationLogs.size() > 0) {
			for (PSA_Integration_Log__c integrationLog : integrationLogs) {
				integrationLogReferenceIds.add(integrationLog.PSA_Reference_Id__c);
			}
		
			if (updateType == 'Resource') {
				List<PSA_Resource_Stage__c> resourceStageList = 
					[Select Id, PSA_GW_Integration_Id__c
						From PSA_Resource_Stage__c
						Where Id In :integrationLogReferenceIds
					];
				for (PSA_Resource_Stage__c resourceStage : resourceStageList) {
					for (PSA_Integration_Log__c integrationLog : integrationLogs) {
						if (integrationLog.PSA_Reference_Id__c == resourceStage.Id) {
							setGWId(integrationLog, resourceStage.PSA_GW_Integration_Id__c);
							continue;
						}
					}
				}
			}

			if (updateType == 'Expense Report') {
				List<PSA_Expense_Stage__c> expenseStageList = 
					[Select Id, PSA_GW_Integration_Id__c
						From PSA_Expense_Stage__c
						Where Id In :integrationLogReferenceIds
					];
				for (PSA_Expense_Stage__c expenseStage : expenseStageList) {
					for (PSA_Integration_Log__c integrationLog : integrationLogs) {
						if (integrationLog.PSA_Reference_Id__c == expenseStage.Id) {
							setGWId(integrationLog, expenseStage.PSA_GW_Integration_Id__c);
							continue;
						}
					}
				}
			}

			if (updateType == 'Billing Event') {
				List<PSA_Billing_Stage__c> billingStageList = 
					[Select Id, PSA_GW_Integration_Id__c
						From PSA_Billing_Stage__c
						Where Id In :integrationLogReferenceIds
					];
				//System.debug('Billing Stage List: ' + billingStageList);

				for (PSA_Billing_Stage__c billingStage : billingStageList) {
					for (PSA_Integration_Log__c integrationLog : integrationLogs) {
						if (integrationLog.PSA_Reference_Id__c == billingStage.Id) {
							setGWId(integrationLog, billingStage.PSA_GW_Integration_Id__c);
							continue;
						}
					}
				}
			}

			if (updateType == 'Assignment') {
				List<PSA_Time_Off_Stage__c> timeOffStageList = 
					[Select Id, PSA_GW_Integration_Id__c
						From PSA_Time_Off_Stage__c
						Where Id In :integrationLogReferenceIds
					];
				for (PSA_Time_Off_Stage__c timeOffStage : timeOffStageList) {
					for (PSA_Integration_Log__c integrationLog : integrationLogs) {
						if (integrationLog.PSA_Reference_Id__c == timeOffStage.Id) {
							setGWId(integrationLog, timeOffStage.PSA_GW_Integration_Id__c);
							continue;
						}
					}
				}
			}

			if (integrationLogsToUpdate != null && integrationLogs.size() > 0) {
				update integrationLogsToUpdate;
			}
		}
	}

	private static void setGWId(PSA_Integration_Log__c integrationLog, String gwId) {
		integrationLog.PSA_GW_Integration_Id__c = gwId;
		integrationLogsToUpdate.add(integrationLog);
	}

    public static void disableASMTriggers(String enabled) {
        //disable timecard ASM triggers
        appirio_core__Config_Value__c[] tcsCoreValues = [
            select Id,
                   appirio_core__Value__c,
                   appirio_core__Config_Option__c
              from appirio_core__Config_Value__c
             where appirio_core__config_Option__r.appirio_core__Group_Key__c = 'asm-triggers'
               and (appirio_core__config_Option__r.name = 'handlebillingeventitemchange'
                or appirio_core__config_Option__r.name = 'handletransactionfortimecard'
                or appirio_core__config_Option__r.name = 'handletransactionformilestone'
                or appirio_core__config_Option__r.name = 'beforeMiscellaneousAdjustmentChange'
                or appirio_core__config_Option__r.name = 'beforeMilestoneChange'
                or appirio_core__config_Option__r.name = 'afterExpenseReportChange'
                or appirio_core__config_Option__r.name = 'handleExpenseLineChange'
                or appirio_core__config_Option__r.name = 'handleExpenseReportUpdate'
                or appirio_core__config_Option__r.name = 'updateExpenseReportForExpense'
                or appirio_core__config_Option__r.name = 'beforeBudgetChange'
                or appirio_core__config_Option__r.name = 'handleTransactionForBudget'
                or appirio_core__config_Option__r.name = 'handleactualsfortransaction'
                or appirio_core__config_Option__r.name = 'handleBillingEventChange')
            order by appirio_core__config_Option__r.name
            limit 13];

        if (tcsCoreValues != null && !tcsCoreValues.isEmpty())
        {
           
          tcsCoreValues[0].appirio_core__Value__c = enabled;
          tcsCoreValues[1].appirio_core__Value__c = enabled;
          tcsCoreValues[2].appirio_core__Value__c = enabled;
          tcsCoreValues[3].appirio_core__Value__c = enabled;
          tcsCoreValues[4].appirio_core__Value__c = enabled;
          tcsCoreValues[5].appirio_core__Value__c = enabled;
          tcsCoreValues[6].appirio_core__Value__c = enabled;
          tcsCoreValues[7].appirio_core__Value__c = enabled;
          tcsCoreValues[8].appirio_core__Value__c = enabled;
          tcsCoreValues[9].appirio_core__Value__c = enabled;
          tcsCoreValues[10].appirio_core__Value__c = enabled;
          tcsCoreValues[11].appirio_core__Value__c = enabled;
          tcsCoreValues[12].appirio_core__Value__c = enabled;
          update tcsCoreValues;
        }        
    }
}