/**************************************************************************************
// Name          : psaBillingHistorySchedulable
// Date          : February 19, 2016
// Description   : Allows for the scheduled linking of current billing events to prior billing events
// Author        : CLD Partners 
// Revisions     : 2016-02-19  Klassen  Initial version
//				 : 2016-03-08  Klassen  Added error handling/email notification
***************************************************************************************/
global class psaBillingHistorySchedulable implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		Try {
			//Kick off the process to link current billing events to prior billing events if applicable
			psaBillingHistory.linkNewBEtoPriorBE();
		} catch (Exception e) {
			System.debug('Billing History Schedulable class failed ' + e.getLineNumber() + ' : ' + e.getMessage());
			psaBillingHistory.sendEmailNotification('Billing History Schedulable class failed', 
				e.getStackTraceString() + ' : ' + e.getLineNumber() + ' : ' + e.getMessage());
  		}

		//abort the job to remove it from the list of scheduled jobs
		system.abortJob(sc.getTriggerId());
	}
}