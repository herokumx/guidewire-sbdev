/**************************************************************************************
// Name          : psaCombineExpenseReceiptsSchedulable
// Date          : September 26, 2015
// Description   : Allows for the scheduled creation of expense receipt documents
// Author        : CLD Partners 
// Revisions     : 2015-09-26  Mayfield  Initial version
//				 : 2015-12-02  Klassen   Update to use more generic code 
***************************************************************************************/
global class psaCombineExpenseReceiptsSchedulable implements Schedulable {
	
	private Set<id> billingEventIds;
	private String sessionId;
	private String sourceObjectId;
	private String sourceObjectType;

	global void execute(SchedulableContext sc) {

		//Set the Combine Receipt Progress value
        psaCombineExpenseReceipts.updateCombineReceiptProgress('Building Attachments Groups', 
        	sourceObjectId, sourceObjectType, false, false);

		//Kick off the process to combine any expense receipts
		psaCombineExpenseReceipts.createCombinedExpenseDoc(sourceObjectId, sourceObjectType, sessionId);

		//abort the job to remove it from the list of scheduled jobs
		system.abortJob(sc.getTriggerId());
	}

	/*
	public psaCombineExpenseReceiptsSchedulable (Set<id> billingEventIdsIn, String sessionIdIn) {
		billingEventIds = billingEventIdsIn;	
		sessionId = sessionIdIn;
	}
	*/

	public psaCombineExpenseReceiptsSchedulable (String sourceObjectIdIn, String sourceObjectTypeIn, 
			String sessionIdIn) {
		sourceObjectId = sourceObjectIdIn;
		sourceObjectType = sourceObjectTypeIn;
		sessionId = sessionIdIn;
	}
}