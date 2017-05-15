/**************************************************************************************
// Name          : psaWorkdayTimeOffIntegration
// Date          : April 11, 2015
// Description   : Contains methods related to the Workday Time Offintegration including 
//					creating Time Off Assignments and Schedules and Timecards as well as
//					updating Schedule Exceptions for existing assignments
// Author        : CLD Partners
// Revisions     : 2015-04-10  Klassen  Initial version
//				 : 2015-05-27  Klassen	Updated Assignment create logic to exclude any
//					PSA Rate Set logic from running and setting the Bill Rate
***************************************************************************************/
public with sharing class psaWorkdayTimeOffIntegration {
	public psaWorkdayTimeOffIntegration() {}


    /**************************************************************************************
    // Name        	: processTimeOffRequests
    // Description 	: Process new Time Off Stage records
	// Author       : CLD Partners
	// Revisions    : 2015-04-11  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static void processTimeOffRequests(Set<Id> timeOffStageIds) {
		Map<String, Contact> resourceMap;
		Map<Id, Contact> resourceIdMap;
		Map<Id, PSA_Time_Off_Stage__c> timeOffStageMap;
		Map<String, List<pse__Assignment__c>> nonTimeOffAssignmentMap = new Map<String, List<pse__Assignment__c>>();
		Map<Id, List<pse__Schedule_Exception__c>> nonTimeOffScheduleExceptionMap = new Map<Id, List<pse__Schedule_Exception__c>>();
		Set<String> workerIds = new Set<String>();
		List<pse__Schedule__c> schedulesToAdd = new List<pse__Schedule__c>();
		List<pse__Assignment__c> assignmentsToAdd = new List<pse__Assignment__c>();
		List<pse__Schedule_Exception__c> scheduleExceptionsToAdd = new List<pse__Schedule_Exception__c>();
		List<pse__Schedule_Exception__c> scheduleExceptionsToUpdate = new List<pse__Schedule_Exception__c>();
		List<pse__Schedule_Exception__c> scheduleExceptionsToRemove = new List<pse__Schedule_Exception__c>();
		List<pse__Timecard_Header__c> timecardsToAdd = new List<pse__Timecard_Header__c>();
//		Map<Id, List<pse__Timecard_Header__c>> timeOffTimecardMap = new Map<Id, List<pse__Timecard_Header__c>>();
//		List<pse__Timecard_Header__c> timecardsToUpdate = new List<pse__Timecard_Header__c>();

		//Get the map and list of Stage records
		timeOffStageMap = new Map<Id, PSA_Time_Off_Stage__c>(
			[Select Id, PSA_GW_Integration_Id__c, PSA_Hours__c, PSA_Processed__c, PSA_Processed_Date__c, 
					PSA_Request_Type__c, PSA_Time_Off_Date__c, PSA_Worker_Id__c
				From PSA_Time_Off_Stage__c
				Where Id In :timeOffStageIds
				And PSA_Hours__c != 0 
			]);
//				And PSA_Time_Off_Date__c >= :Date.today()
		List<PSA_Time_Off_Stage__c> timeOffStageList = timeOffStageMap.values();

		//*** BEGIN Populate Maps
		for (PSA_Time_Off_Stage__c timeOffStage : timeOffStageList) {
			workerIds.add(timeOffStage.PSA_Worker_Id__c);
			timeOffStage.PSA_Processed__c = true;
			timeOffStage.PSA_Processed_Date__c = DateTime.now();			
		}
		//All applicable resources (Contacts)
		resourceMap = new Map<String, Contact>();
		resourceIdMap = new Map<Id, Contact>();
		List<Contact> resourceList = 
			[Select Id, Name, PSA_Worker_Id__c, pse__Default_Cost_Rate__c, CurrencyISOCode 
				From Contact
				Where PSA_Worker_Id__c In :workerIds
			];
		for (Contact resource : resourceList) {
			resourceMap.put(resource.PSA_Worker_Id__c, resource);
			resourceIdMap.put(resource.Id, resource);
		}

		//*** May be used in a future phase, but not part of initial implementation
		/*
		//BEGIN All applicable Time Off timecards, sorted by Resource
		List<pse__Timecard_Header__c> timeOffTimecards = 
			[Select Id, pse__Resource__c, pse__Project__c, pse__Start_Date__c, pse__End_Date__c, 
					pse__Monday_Hours__c, pse__Tuesday_Hours__c, pse__Wednesday_Hours__c, 
					pse__Thursday_Hours__c, pse__Friday_Hours__c, pse__Saturday_Hours__c, 
					pse__Sunday_Hours__c 
				From pse__Timecard_Header__c
				Where pse__Resource__c In :resourceIdMap.keySet()
				And pse__Project__r.Name = 'Time Off' 
				And pse__Status__c = 'Saved' 
				order by pse__Resource__c
			];
		System.debug('timeOffTimecards: ' + timeOffTimecards);
		Id previousResource;
		List<pse__Timecard_Header__c> resourceTimeOffTimecards = new List<pse__Timecard_Header__c>();
		for (pse__Timecard_Header__c timecard : timeOffTimecards) {
			if (previousResource != null && previousResource != timecard.pse__Resource__c) {
				timeOffTimecardMap.put(previousResource, resourceTimeOffTimecards);
				resourceTimeOffTimecards = new List<pse__Timecard_Header__c>();
			}
			resourceTimeOffTimecards.add(timecard);
			previousResource = timecard.pse__Resource__c;
		}
		if (resourceTimeOffTimecards.size() > 0) {
			timeOffTimecardMap.put(previousResource, resourceTimeOffTimecards);		
		}
		System.debug('timeOffTimecardMap:' + timeOffTimecardMap);
		//END All applicable Time Off timecards, sorted by Resource
		*/

		//BEGIN All applicable non-time off assignments, sorted by Resource
		Set<Id> nonTimeOffScheduleIds = new Set<Id>();
		List<pse__Assignment__c> nonTimeOffAssignments = 
			[Select Id, pse__Resource__c, pse__Project__c, pse__Resource__r.PSA_Worker_Id__c, 
					pse__Schedule__c, pse__Start_Date__c, pse__End_Date__c, 
					pse__Schedule__r.pse__Monday_Hours__c, pse__Schedule__r.pse__Tuesday_Hours__c, 
					pse__Schedule__r.pse__Wednesday_Hours__c, pse__Schedule__r.pse__Thursday_Hours__c, 
					pse__Schedule__r.pse__Friday_Hours__c, pse__Schedule__r.pse__Saturday_Hours__c, 
					pse__Schedule__r.pse__Sunday_Hours__c
				From pse__Assignment__c
				Where pse__Resource__c In :resourceIdMap.keySet()
				And pse__Project__r.Name != 'Time Off' 
				order by pse__Resource__c
			];
		String previousResourceWorkerId;
		List<pse__Assignment__c> resourceAssignments = new List<pse__Assignment__c>();
		for (pse__Assignment__c assignment : nonTimeOffAssignments) {
			if (previousResourceWorkerId != null && previousResourceWorkerId != assignment.pse__Resource__r.PSA_Worker_Id__c) {
				nonTimeOffAssignmentMap.put(previousResourceWorkerId, resourceAssignments);
				resourceAssignments = new List<pse__Assignment__c>();
			}
			nonTimeOffScheduleIds.add(assignment.pse__Schedule__c);
			resourceAssignments.add(assignment);
			previousResourceWorkerId = assignment.pse__Resource__r.PSA_Worker_Id__c;
		}
		if (resourceAssignments.size() > 0) {
			nonTimeOffAssignmentMap.put(previousResourceWorkerId, resourceAssignments);		
		}
		System.debug('nonTimeOffAssignmentMap:'+nonTimeOffAssignmentMap);
		//END All applicable non-time off assignments, sorted by Resource

		//BEGIN All applicable non-time off schedule Exceptions, sorted by Schedule Id
		List<pse__Schedule_Exception__c> nonTimeOffScheduleExceptions = 
			[Select Id, pse__Schedule__c, pse__Date__c, pse__End_Date__c, pse__Exception_Hours__c, 
					PSA_Time_Off_Update__c, PSA_Time_Off_Stage__c, pse__Monday_Hours__c, 
					pse__Tuesday_Hours__c, pse__Wednesday_Hours__c, pse__Thursday_Hours__c, 
					pse__Friday_Hours__c, pse__Saturday_Hours__c, pse__Sunday_Hours__c 					  
				From pse__Schedule_Exception__c
				Where pse__Schedule__c In :nonTimeOffScheduleIds
				And PSA_Time_Off_Schedule__c != null 
				Order By pse__Schedule__c
			];
		Id previousScheduleId;
		List<pse__Schedule_Exception__c> scheduleScheduleExceptions = new List<pse__Schedule_Exception__c>();
		for (pse__Schedule_Exception__c scheduleException : nonTimeOffScheduleExceptions) {
			if (previousScheduleId != null && previousScheduleId != scheduleException.pse__Schedule__c) {
				nonTimeOffScheduleExceptionMap.put(previousScheduleId, scheduleScheduleExceptions);
				scheduleScheduleExceptions = new List<pse__Schedule_Exception__c>();
			}
			scheduleScheduleExceptions.add(scheduleException);
			previousScheduleId = scheduleException.pse__Schedule__c;
		}
		if (scheduleScheduleExceptions.size() > 0) {
			nonTimeOffScheduleExceptionMap.put(previousScheduleId, scheduleScheduleExceptions);		
		}
		//END All applicable non-time off schedule Exceptions, sorted by Schedule Id

		//*** END Populate Maps

		//*** BEGIN Create Time Off Schedules
		pse__Schedule__c newSchedule;
		for (PSA_Time_Off_Stage__c timeOffStage : timeOffStageList) {
			//Create assignment/schedule/timecard and possibly schedule exceptions
			newSchedule = createTimeOffSchedule(timeOffStage.PSA_Time_Off_Date__c, 
					timeOffStage.PSA_Time_Off_Date__c, timeOffStage.PSA_Hours__c, 
					timeOffStage.Id, timeOffStage.PSA_GW_Integration_Id__c);
			if (newSchedule != null) {
				schedulesToAdd.add(newSchedule);
			} else {
	       		//write integration log entry - error b/c no schedule was created
				String integrationType;
				if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
				else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }
				String logMessage = 'Unable to create a schedule';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, null);					
			}
		}
		//*** END Create Time Off Schedules

		//*** BEGIN DML operations for Schedules
		pse__Schedule__c schedule;		
		Database.SaveResult[] srList;
		Database.DeleteResult[] drList;
		Database.SaveResult sr;
		Database.DeleteResult dr;

		//New Time Off Schedules 
		srList = Database.Insert(schedulesToAdd, false);
		for (Integer i = 0; i< schedulesToAdd.size(); i++) {
			sr = srList[i];
    		schedule = schedulesToAdd[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(schedule.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			if (sr.isSuccess() == true) {
				System.debug('Successfully Inserted Schedule.  Sched. Id: ' + schedule.Id + ' - TimeOffStageId:' + schedule.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully inserted schedule';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, schedule.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'Schedule', timeOffStage.PSA_GW_Integration_Id__c, schedule.Id);
			}
		}

		//Once the Schedules have been created, loop through them to create the Time off Schedule Exceptions, Assignments, 
		// and non-Time Off Schedule Exceptions
		pse__Schedule_Exception__c newScheduleException;
		for (pse__Schedule__c scheduleToAdd : schedulesToAdd) {
			//Create schedule exceptions
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleToAdd.PSA_Time_Off_Stage__c);			
			newScheduleException = createScheduleException(timeOffStage.PSA_Time_Off_Date__c, timeOffStage.PSA_Hours__c, 
					scheduleToAdd.Id, timeOffStage.Id, timeOffStage.PSA_GW_Integration_Id__c, null);
			if (newScheduleException != null) {
				scheduleExceptionsToAdd.add(newScheduleException);
			} else {
	       		//write integration log entry - error b/c no schedule was created
				String integrationType;
				if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
				else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }
				String logMessage = 'Unable to create a schedule exception';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule Exception', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, null);					
			}
		}

		pse__Assignment__c newAssignment;
		for (pse__Schedule__c scheduleToAdd : schedulesToAdd) {
			//Create assignments
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleToAdd.PSA_Time_Off_Stage__c);			
			newAssignment = createTimeOffAssignment(scheduleToAdd, resourceMap, timeOffStage);
			if (newAssignment != null) {
				assignmentsToAdd.add(newAssignment);
			} else {
	       		//write integration log entry - error b/c no schedule was created
				String integrationType;
				if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
				else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }
				String logMessage = 'Unable to create an assignment';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Assignment', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, null);					
			}
		}

		//Create or Delete any schedule exceptions for related non-time off assignments/schedules
		List<pse__Schedule_Exception__c> newScheduleExceptions;
		for (pse__Schedule__c scheduleToAdd : schedulesToAdd) {
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleToAdd.PSA_Time_Off_Stage__c);			
			newScheduleExceptions = processScheduleExceptionsForNonTimeOffAssignments(timeOffStage, 
				nonTimeOffAssignmentMap, nonTimeOffScheduleExceptionMap, scheduleToAdd.Id);
			if (newScheduleExceptions.size() > 0) {
				for (pse__Schedule_Exception__c scheduleException : newScheduleExceptions) {
					if (scheduleException.PSA_Time_Off_Update__c == 'delete') {
						scheduleExceptionsToRemove.add(scheduleException);
					} else if (scheduleException.PSA_Time_Off_Update__c == 'add') {
						scheduleExceptionsToAdd.add(scheduleException);
					} else { 
						scheduleExceptionsToUpdate.add(scheduleException);
					}
				}
			}
		}

		//*** BEGIN Schedule Exception and Assignment DML operations
		//DML for New Schedule Exceptions, including the ones for the Time Off Stage record
		pse__Schedule_Exception__c scheduleException;
		srList.clear();
		srList = Database.Insert(scheduleExceptionsToAdd, false);
		for (Integer i = 0; i< scheduleExceptionsToAdd.size(); i++) {
			sr = srList[i];
    		scheduleException = scheduleExceptionsToAdd[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleException.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			if (sr.isSuccess() == true) {
			
				System.debug('Successfully Inserted Schedule Exception.  Sched. Exc. Id: ' + scheduleException.Id + ' - TimeOffStageId:' + scheduleException.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully inserted schedule exception';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule Exception', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, scheduleException.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'Schedule Exception', timeOffStage.PSA_GW_Integration_Id__c, null);
			}
		}
		srList.clear();
		srList = Database.Update(scheduleExceptionsToUpdate, false);
		for (Integer i = 0; i< scheduleExceptionsToUpdate.size(); i++) {
			sr = srList[i];
    		scheduleException = scheduleExceptionsToUpdate[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleException.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			if (sr.isSuccess() == true) {
				System.debug('Successfully Updated Schedule Exception.  Sched. Exc. Id: ' + scheduleException.Id + ' - TimeOffStageId:' + scheduleException.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully updated schedule exception';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule Exception', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, scheduleException.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'Schedule Exception', timeOffStage.PSA_GW_Integration_Id__c, null);
			}
		}

		//drList.clear();
		drList = Database.Delete(scheduleExceptionsToRemove, false);
		for (Integer i = 0; i< scheduleExceptionsToRemove.size(); i++) {
			dr = drList[i];
    		scheduleException = scheduleExceptionsToRemove[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(scheduleException.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }
			if (dr.isSuccess() == true) {
				System.debug('Successfully Deleted Schedule Exception.  Sched. Exc. Id: ' + scheduleException.Id + ' - TimeOffStageId:' + scheduleException.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully deleted schedule exception: ' + scheduleException.Id;
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Schedule Exception', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, null);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(dr.getErrors(), true, timeOffStage.Id, integrationType, 'Schedule Exception', timeOffStage.PSA_GW_Integration_Id__c, null);
			}
		}

		//DML for New Time Off Assignments 
		pse__Assignment__c assignment;
		srList.clear();
		srList = Database.Insert(assignmentsToAdd, false);
		for (Integer i = 0; i< assignmentsToAdd.size(); i++) {
			sr = srList[i];
    		assignment = assignmentsToAdd[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(assignment.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			//if (sr.isSuccess() == true) {
		/*	if(false){
				System.debug('Successfully Inserted Assignment.  Assign. Id: ' + assignment.Id + ' - TimeOffStageId:' + assignment.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully inserted assignment';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Assignment', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, assignment.Id);
			} else {*/
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'Assignment', timeOffStage.PSA_GW_Integration_Id__c, null);
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'Assignment', timeOffStage.PSA_GW_Integration_Id__c, null);
			//}
		}
		//*** END Schedule Exception and Assignment DML operations

		//Once the Assignments have been created, loop through them to create the Timecards
		Boolean timecardExists = false;
		pse__Timecard_Header__c newTimecard;
		for (pse__Assignment__c assignmentToAdd : assignmentsToAdd) {
			//Create timecards
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(assignmentToAdd.PSA_Time_Off_Stage__c);

			//*** May be used in a future phase, but not part of initial implementation due to complexity
			/*
			//TODO: check if timecard already exists.  If so, then update the existing one, otherwise, create a new one
			newTimecard = getExistingTimecard(timeOffStage.PSA_Worker_Id__c, resourceMap, timeOffTimecardMap, timeOffStage);
			if (newTimecard == null) {
				timecardExists = false;
			} else {
				timecardExists = true;
			}
			*/

			newTimecard = createTimeOffTimecard(assignmentToAdd, resourceMap, timeOffStage, null);
			if (newTimecard != null && timecardExists == false) {
				timecardsToAdd.add(newTimecard);
//			} else if (newTimecard != null) {
//				timecardsToUpdate.add(newTimecard);
			} else {
	       		//write integration log entry - error b/c no schedule was created
				String integrationType;
				if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
				else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }
				String logMessage = 'Unable to create a timecard';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Timecard', integrationType, 
						psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, null);					
			}
		}

		//*** BEGIN Timecards DML operations
		pse__Timecard_Header__c timecard;
		srList.clear();
		srList = Database.Insert(timecardsToAdd, false);
		for (Integer i = 0; i< timecardsToAdd.size(); i++) {
			sr = srList[i];
    		timecard = timecardsToAdd[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(timecard.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			if (sr.isSuccess() == true) {
				System.debug('Successfully Inserted timecard.  Timecard Id: ' + timecard.Id + ' - TimeOffStageId:' + timecard.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully inserted timecard';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'timecard', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, timecard.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'timecard', timeOffStage.PSA_GW_Integration_Id__c, null);
			}
		}

		//*** May be used in a future phase, but not part of initial implementation due to complexity
		/*
		//Update existing timecards
		srList.clear();
		srList = Database.Update(timecardsToUpdate, false);
		for (Integer i = 0; i< timecardsToUpdate.size(); i++) {
			sr = srList[i];
    		timecard = timecardsToUpdate[i];
			PSA_Time_Off_Stage__c timeOffStage = timeOffStageMap.get(timecard.PSA_Time_Off_Stage__c);			
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			if (sr.isSuccess() == true) {
				System.debug('Successfully updated timecard.  Timecard Id: ' + timecard.Id + ' - TimeOffStageId:' + timecard.PSA_Time_Off_Stage__c);

				//Write an entry to the Integration Log
				String logMessage = 'Successfully updated timecard';
				psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'timecard', integrationType, 
					psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, timeOffStage.PSA_GW_Integration_Id__c, timecard.Id);
			} else {
				// Operation failed, so get all errors
				psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, timeOffStage.Id, integrationType, 'timecard', null);
			}
		}
		*/
		//*** END Timecards DML operations

		//*** Possibly implement in future phase
		//Remove any newly added schedules/schedule exceptions/assignments/non-time off schedule exceptions
		// for any time off stage records that failed at any point
		//TODO

		//BEGIN Integration Log Update
		//	Update the gw integration id in the integration log where applicable
		//psaIntegrationUtils.updateGWIds('Time Off');
		//END update the reference id and gw integration id in the integration log where applicable


		//Update the Processed and Processed Date fields
		update timeOffStageList;


		//*** END DML operations
    }

    /**************************************************************************************
    // Name        	: getExistingTimecard
    // Description 	: Search for a timecard that includes the Time Off date
	// Author       : CLD Partners
	// Revisions    : 2015-04-14  Klassen  Initial version
	//				: 2015-04-17  Klassen  Deferred to a later phase
	//					This method won't be included in initial implementation due to the complexlity
    //					of handling updates to existing timecards
    ***************************************************************************************/
/*
    private static pse__Timecard_Header__c getExistingTimecard(String workerId, Map<String, Contact> resourceMap, 
    		Map<Id, List<pse__Timecard_Header__c>> timeOffTimecardMap, PSA_Time_Off_Stage__c timeOffStage) {
       	if (resourceMap != null || timeOffTimecardMap != null) {
       		Contact resource = resourceMap.get(workerId);
       		if (resource != null) {
       			//Check for a Time Off timecard for the relevant resource
       			List<pse__Timecard_Header__c> timecardHeaders = timeOffTimecardMap.get(resource.Id);
       			if (timecardHeaders != null) {
       				for (pse__Timecard_Header__c timecard : timecardHeaders) {
		       			//check for a Time Off Timecard for the relevant week
		       			Date timecardDate = timeOffStage.PSA_Time_Off_Date__c;
		       			Date weekStartDate = psaUtils.getTimecardWeekStartDate(timecardDate);
						Date weekEndDate = weekStartDate.addDays(6);
						if (timecardDate >= weekStartDate && timecardDate <= weekEndDate) {
							System.debug('Found timecard: ' + timecard);
							return timecard;
						}
       				}
       			}
       		}
   		}
    	return null;
    }
*/

	/**************************************************************************************
    // Name        	: createTimeOffSchedule
    // Description 	: create the schedule record for a range of dates
	// Author       : CLD Partners
	// Revisions    : 2015-04-14  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Schedule__c createTimeOffSchedule(Date startDate, Date endDate, 
    		Decimal hoursPerDay, Id startDateStageId, String stageGWId) {
    	pse__Schedule__c schedule = new pse__Schedule__c();
		try {

			schedule.PSA_Time_Off_Stage__c = startDateStageId;
			schedule.pse__Start_Date__c = startDate;
			schedule.pse__End_Date__c = endDate;
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType;
			if (hoursPerDay > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			psaIntegrationUtils.writeLogEntry(startDateStageId, 'Schedule', integrationType, 
				psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
				stageGWId, null);
			return null;			
		}

    	return schedule;
    }

	/**************************************************************************************
    // Name        	: createTimeOffScheduleException
    // Description 	: create a schedule exception record for a a specific schedule/date
	// Author       : CLD Partners
	// Revisions    : 2015-04-14  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Schedule_Exception__c createScheduleException(Date exceptionDate,  
    		Decimal hours, Id scheduleId, Id timeOffStageId, String timeOffStageGWId, 
    		Id timeOffScheduleId) {
    	pse__Schedule_Exception__c scheduleException = new pse__Schedule_Exception__c();
		try {
			scheduleException.pse__Schedule__c = scheduleId;
			scheduleException.pse__Date__c = exceptionDate;
			scheduleException.pse__End_Date__c = exceptionDate;
			scheduleException.PSA_Time_Off_Stage__c = timeOffStageId;
			scheduleException.PSA_Time_Off_Schedule__c = timeOffScheduleId;

			Datetime dt = datetime.newInstance(exceptionDate.year(), exceptionDate.month(), exceptionDate.day());
			String dayOfWeek = dt.format('EEEE');

			if (dayOfWeek == 'Monday') {
				scheduleException.pse__Monday_Hours__c = hours;
			} else if (dayOfWeek == 'Tuesday') {
				scheduleException.pse__Tuesday_Hours__c = hours;
			} else if (dayOfWeek == 'Wednesday') {
				scheduleException.pse__Wednesday_Hours__c = hours;
			} else if (dayOfWeek == 'Thursday') {
				scheduleException.pse__Thursday_Hours__c = hours;
			} else if (dayOfWeek == 'Friday') {
				scheduleException.pse__Friday_Hours__c = hours;
			} else if (dayOfWeek == 'Saturday') {
				scheduleException.pse__Saturday_Hours__c = hours;
			} else if (dayOfWeek == 'Sunday') {
				scheduleException.pse__Sunday_Hours__c = hours;
			}

/*
			//Commented out code has not been removed in case it is helpful for a future phase
//			Date weekStart = timeOffStage.PSA_Time_Off_Date__c.toStartOfWeek();
//			System.debug('weekStart: ' + weekStart);
			list<boolean> days = new list<boolean>();
			for(integer i = 0; i < 7; i++)
			{
			  days.add(weekStart.addDays(i) >= startdate && weekStart.addDays(i) <= enddate);
			}
*/
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType;
			if (hours > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			psaIntegrationUtils.writeLogEntry(timeOffStageId, 'Schedule Exception', integrationType, 
				psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
				timeOffStageGWId, null);
			return null;			
		}

    	return scheduleException;
    }

	/**************************************************************************************
    // Name        	: createTimeOffAssignment
    // Description 	: create the assignment record for the Time Off Request stage record
	// Author       : CLD Partners
	// Revisions    : 2015-04-13  Klassen  Initial version
	//			    : 2015-05-27  Klassen  Updated Assignment create logic to exclude any
	//					PSA Rate Set logic from running and setting the Bill Rate
    ***************************************************************************************/
    private static pse__Assignment__c createTimeOffAssignment(pse__Schedule__c schedule, 
    		Map<String, Contact> resourceMap, PSA_Time_Off_Stage__c timeOffStage) {
    	pse__Assignment__c assignment = new pse__Assignment__c();
    	Contact resource = resourceMap.get(timeOffStage.PSA_Worker_Id__c);
		try {
			assignment.Name = 'Time Off - ' + resource.Name + ' - ' + DateTime.Now().format('YYYY-MM-DD');
			assignment.PSA_Time_Off_Stage__c = schedule.PSA_Time_Off_Stage__c;
			assignment.pse__Schedule__c = schedule.Id;
			assignment.pse__Project__c = [Select Id from pse__Proj__c Where Name = 'Time Off'].Id;
			assignment.pse__Resource__c = resource.Id;
			assignment.pse__Bill_Rate__c = 0;
			assignment.PSA_Override_Bill_Rate__c = true;
			assignment.pse__Use_Resource_Currency_For_Resource_Cost__c = true;
			assignment.pse__Use_Resource_Default_Cost_Rate__c = true;
			//assignment.pse__Cost_Rate_Amount__c = resource.pse__Default_Cost_Rate__c;
			assignment.pse__Status__c = 'Scheduled';
			assignment.PSA_Notify_Assignee__c = false;
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Assignment', integrationType, 
				psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
				timeOffStage.PSA_GW_Integration_Id__c, null);
			return null;			
		}

    	return assignment;
    }

	/**************************************************************************************
    // Name        	: createTimeOffTimecard
    // Description 	: create a timecard for the Time Off Request stage record
	// Author       : CLD Partners
	// Revisions    : 2015-04-14  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Timecard_Header__c createTimeOffTimecard(pse__Assignment__c assignment, 
    		Map<String, Contact> resourceMap, PSA_Time_Off_Stage__c timeOffStage, pse__Timecard_Header__c timecard) {
    	Contact resource = resourceMap.get(timeOffStage.PSA_Worker_Id__c);
		try {
	    	if (timecard == null) {
	    		timecard = new pse__Timecard_Header__c();
				timecard.pse__Assignment__c = assignment.Id;
				timecard.pse__Project__c = assignment.pse__Project__c;
				timecard.pse__Resource__c = resource.Id;
				timecard.pse__Status__c = 'Saved';
				timecard.pse__Start_Date__c = psaUtils.getTimecardWeekStartDate(timeOffStage.PSA_Time_Off_Date__c);
				timecard.pse__End_Date__c = timecard.pse__Start_Date__c.addDays(6);
				
				timecard.pse__Monday_Hours__c = 0;
				timecard.pse__Tuesday_Hours__c = 0;
				timecard.pse__Wednesday_Hours__c = 0;
				timecard.pse__Thursday_Hours__c = 0;
				timecard.pse__Friday_Hours__c = 0;
				timecard.pse__Saturday_Hours__c = 0;
				timecard.pse__Sunday_Hours__c = 0;

				System.debug('Start Date: ' + timecard.pse__Start_Date__c + ' End Date: ' + timecard.pse__End_Date__c);
	    	}

			timecard.PSA_Time_Off_Stage__c = timeOffStage.Id;

			Datetime dt = datetime.newInstance(timeOffStage.PSA_Time_Off_Date__c.year(), timeOffStage.PSA_Time_Off_Date__c.month(), timeOffStage.PSA_Time_Off_Date__c.day());
			String dayOfWeek = dt.format('EEEE');

			if (dayOfWeek == 'Monday') {
				timecard.pse__Monday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Tuesday') {
				timecard.pse__Tuesday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Wednesday') {
				timecard.pse__Wednesday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Thursday') {
				timecard.pse__Thursday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Friday') {
				timecard.pse__Friday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Saturday') {
				timecard.pse__Saturday_Hours__c += timeOffStage.PSA_Hours__c;
			} else if (dayOfWeek == 'Sunday') {
				timecard.pse__Sunday_Hours__c += timeOffStage.PSA_Hours__c;
			}
	   	} catch (Exception e) {
			//Write an entry to the Integration Log
			String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
			String integrationType;
			if (timeOffStage.PSA_Hours__c > 0) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_TIME_OFF_REQUEST; }
			else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_TIME_OFF_REQUEST_CORRECTION; }

			psaIntegrationUtils.writeLogEntry(timeOffStage.Id, 'Timecard', integrationType, 
				psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
				timeOffStage.PSA_GW_Integration_Id__c, null);
			return null;			
		}

    	return timecard;
    }

	/**************************************************************************************
    // Name        	: processScheduleExceptionsForNonTimeOffAssignments
    // Description 	: Populate a list of Schedule Exceptions that will be either Created, 
    //					Updated, or Deleted for Non-Time Off assignments that have 
    //					overlapping dates. Any hours over the regular scheduled hours will
    //					be ignored.
	// Author       : CLD Partners
	// Revisions    : 2015-04-17  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static List<pse__Schedule_Exception__c> processScheduleExceptionsForNonTimeOffAssignments(
    		PSA_Time_Off_Stage__c timeOffStage, Map<String, List<pse__Assignment__c>> nonTimeOffAssignmentMap, 
    		Map<Id, List<pse__Schedule_Exception__c>> nonTimeOffScheduleExceptionMap, Id timeOffScheduleId) {
    	List<pse__Schedule_Exception__c> scheduleExceptionsToProcess = new List<pse__Schedule_Exception__c>();
    	List<pse__Schedule_Exception__c> existingScheduleExceptions;
    	pse__Schedule_Exception__c foundScheduleException;
    	Decimal exceptionHours;

    	//System.debug('timeoff stage:'+timeOffStage);
    	//System.debug('nonTimeOffAssignmentsMap:'+nonTimeOffAssignmentMap);
    	//System.debug('nonTimeOffScheduleExceptionMap:'+nonTimeOffScheduleExceptionMap);
    	//System.debug('Schedule Id:'+ timeOffScheduleId);

    	List<pse__Assignment__c> nonTimeOffAssignments = nonTimeOffAssignmentMap.get(timeOffStage.PSA_Worker_Id__c);
    	if (nonTimeOffAssignments != null && nonTimeOffAssignments.size() > 0) {
    		for (pse__Assignment__c assignment : nonTimeOffAssignments) {
    			//Initialize the "found" schedule exception variable
    			foundScheduleException = null;
    			
    			//Check if the Time Off Request falls within the Start and End Date of the Assignment
    			if (timeOffStage.PSA_Time_Off_Date__c >= assignment.pse__Start_Date__c && timeOffStage.PSA_Time_Off_Date__c <= assignment.pse__End_Date__c) {
    				//Check if there are any existing schedule Exceptions.  
    				existingScheduleExceptions = nonTimeOffScheduleExceptionMap.get(assignment.pse__Schedule__c);
    				if (existingScheduleExceptions != null && existingScheduleExceptions.size() > 0) {
    					//Loop through each schedule exception process any existing ones
    					for (pse__Schedule_Exception__c scheduleException : existingScheduleExceptions) {
    						if (timeOffStage.PSA_Time_Off_Date__c == scheduleException.pse__Date__c) {
    							foundScheduleException = scheduleException;  							
    						}
    					}
    				}
    			}

				//If not found and Time Off Hours > 0, add it to the list of schedule exceptions to process... will get created
				if (timeOffStage.PSA_Hours__c > 0 && foundScheduleException == null) {
					//Determine the number of hours for the schedule exception
					exceptionHours = getNewScheduleExceptionHours(assignment, timeOffStage);

					//Create a schedule exception
					pse__Schedule_Exception__c scheduleException = createScheduleException(timeOffStage.PSA_Time_Off_Date__c, exceptionHours, 
							assignment.pse__Schedule__c, timeOffStage.Id, timeOffStage.PSA_GW_Integration_Id__c, timeOffScheduleId);
					scheduleException.PSA_Time_Off_Update__c = 'add';
					scheduleExceptionsToProcess.add(scheduleException);
				}

				//If a schedule exception was found add it to the list of schedule exceptions to update or delete
				if (foundScheduleException != null) {
					foundScheduleException = updateExistingScheduleExceptionHours(assignment, timeOffStage, foundScheduleException);
					scheduleExceptionsToProcess.add(foundScheduleException);
				}
    		}

    	}

    	//System.debug('scheduleExceptionsToProcess:'+scheduleExceptionsToProcess);
    	return scheduleExceptionsToProcess;
    }

	/**************************************************************************************
    // Name        	: getNewScheduleExceptionHours
    // Description 	: Determine the number of hours for a specific Schedule exception based
    //				:  on the assignment's scheduled hours.  Don't allow the Schedule
    //					Exception to be negative for any specific day.
	// Author       : CLD Partners
	// Revisions    : 2015-04-20  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static Decimal getNewScheduleExceptionHours(pse__Assignment__c assignment, 
    		PSA_Time_Off_Stage__c timeOffStage) {
		Decimal exceptionHours = timeOffStage.PSA_Hours__c;

		Datetime dt = datetime.newInstance(timeOffStage.PSA_Time_Off_Date__c.year(), 
				timeOffStage.PSA_Time_Off_Date__c.month(), 
				timeOffStage.PSA_Time_Off_Date__c.day());
		String dayOfWeek = dt.format('EEEE');
		if (dayOfWeek == 'Monday') {
			if (assignment.pse__Schedule__r.pse__Monday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Monday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Tuesday') {
			if (assignment.pse__Schedule__r.pse__Tuesday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Tuesday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Wednesday') {
			if (assignment.pse__Schedule__r.pse__Wednesday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Wednesday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Thursday') {
			if (assignment.pse__Schedule__r.pse__Thursday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Thursday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Friday') {
			if (assignment.pse__Schedule__r.pse__Friday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Friday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Saturday') {
			if (assignment.pse__Schedule__r.pse__Saturday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Saturday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		} else if (dayOfWeek == 'Sunday') {
			if (assignment.pse__Schedule__r.pse__Sunday_Hours__c > exceptionHours) {
				exceptionHours = assignment.pse__Schedule__r.pse__Sunday_Hours__c - exceptionHours;
			} else {
				exceptionHours = 0;
			}
		}

		return exceptionHours;
	}

	/**************************************************************************************
    // Name        	: updateExistingScheduleExceptionHours
    // Description 	: Update the correct day/hours for a specific Schedule exception based
    //				:  on an existing Schedule Exception.  Don't allow the Schedule Exception
    //					to be over the regularly scheduled hours or less than zero.
	// Author       : CLD Partners
	// Revisions    : 2015-04-20  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    private static pse__Schedule_Exception__c updateExistingScheduleExceptionHours( 
    		pse__Assignment__c assignment, PSA_Time_Off_Stage__c timeOffStage, 
    		pse__Schedule_Exception__c scheduleException) {
    	
    	Decimal exceptionHours;
    	Decimal defaultExceptionHours = scheduleException.pse__Exception_Hours__c;
		Datetime dt = datetime.newInstance(timeOffStage.PSA_Time_Off_Date__c.year(), 
				timeOffStage.PSA_Time_Off_Date__c.month(), 
				timeOffStage.PSA_Time_Off_Date__c.day());
		String dayOfWeek = dt.format('EEEE');

		//Find the applicable day of the week and set the sched. excep. hours 
		// If the schedule hours > the exception hours, set the sched. excep. hours, 
		// else set the sched. excep. hours to zero... will allow the sched. excep.
		// to be deleted
		scheduleException.PSA_Time_Off_Update__c = 'update';
		if (dayOfWeek == 'Monday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Monday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Monday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Monday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Monday_Hours__c = exceptionHours;
			} else {
				scheduleException.pse__Monday_Hours__c = assignment.pse__Schedule__r.pse__Monday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Tuesday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Tuesday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Tuesday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Tuesday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Tuesday_Hours__c = assignment.pse__Schedule__r.pse__Tuesday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Tuesday_Hours__c = assignment.pse__Schedule__r.pse__Tuesday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Wednesday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Wednesday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Wednesday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Wednesday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Wednesday_Hours__c = assignment.pse__Schedule__r.pse__Wednesday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Wednesday_Hours__c = assignment.pse__Schedule__r.pse__Wednesday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Thursday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Thursday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Thursday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Thursday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Thursday_Hours__c = assignment.pse__Schedule__r.pse__Thursday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Thursday_Hours__c = assignment.pse__Schedule__r.pse__Thursday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Friday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Friday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Friday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Friday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Friday_Hours__c = assignment.pse__Schedule__r.pse__Friday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Friday_Hours__c = assignment.pse__Schedule__r.pse__Friday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Saturday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Saturday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Saturday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Saturday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Saturday_Hours__c = assignment.pse__Schedule__r.pse__Saturday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Saturday_Hours__c = assignment.pse__Schedule__r.pse__Saturday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		} else if (dayOfWeek == 'Sunday') {
			if (defaultExceptionHours > 0 && scheduleException.pse__Sunday_Hours__c == 0) {
				exceptionHours = defaultExceptionHours - timeOffStage.PSA_Hours__c;
			} else {
				exceptionHours = scheduleException.pse__Sunday_Hours__c - timeOffStage.PSA_Hours__c;
			}

			if (assignment.pse__Schedule__r.pse__Sunday_Hours__c > exceptionHours) {
				if (exceptionHours < 0) { exceptionHours = 0; } //Don't allow negative hours on a Schedule Exception
				scheduleException.pse__Sunday_Hours__c = assignment.pse__Schedule__r.pse__Sunday_Hours__c - exceptionHours;
			} else {
				scheduleException.pse__Sunday_Hours__c = assignment.pse__Schedule__r.pse__Sunday_Hours__c;
				scheduleException.PSA_Time_Off_Update__c = 'delete';
			}
		}

		scheduleException.PSA_Time_Off_Stage__c = timeOffStage.Id;
		return scheduleException;
	}

	/**************************************************************************************
    // Name        	: scheduleTimeOffStageJob
    // Description 	: Create a scheduled job to process Time Off Stage records in a batch
    //				:  POSSIBLY TO BE IMPLEMENTED IN A FUTURE PHASE ("1.x")
	// Author       : CLD Partners
	// Revisions    : 2015-04-14  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    /*
    private static void scheduleTimeOffStageJob() {
    	String jobNameFilter = 'PSA Time Off Stage - 1 Time%';
    	List<CronJobDetail> cronJobDetails = [
		    Select Id, JobType, Name 
		    	From CronJobDetail
		    	Where Name Like :jobNameFilter
    	];
    	if (cronJobDetails == null && cronJobDetails.size() == 0) {
    		//Schedule a job to run to process TOR records
			String hour = String.valueOf(Datetime.now().hour());
			String min = String.valueOf(Datetime.now().minute() + 10); 
			String ss = String.valueOf(Datetime.now().second());

			//parse to cron expression
			String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

			psaResourceStageSchedulable s = new psaResourceStageSchedulable(); 
			System.schedule('PSA Time Off Stage - 1 Time: ' + String.valueOf(Datetime.now()), nextFireTime, s);
    	}
    }	
	*/


}