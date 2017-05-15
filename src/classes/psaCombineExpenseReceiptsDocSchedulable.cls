/**************************************************************************************
// Name          : psaCombineExpenseReceiptsDocSchedulable
// Date          : December 02, 2015 
// Description   : Used to check the status of a file convert batch -- use scheduled
//					job to handle callouts to Zamzar
// Author        : CLD Partners
// Revisions     : 2015-12-02  Klassen  Initial version
//				 : 
***************************************************************************************/
global class psaCombineExpenseReceiptsDocSchedulable implements Schedulable {
	
	private Decimal batchNumber;
	private String sourceObjectId;
	private String sourceObjectType;
	private Integer attemptCount;

	global void execute(SchedulableContext sc) {
		//Only run the code if this is not being executed from a test
		if (!Test.isRunningTest()) {
			//Check the remaining Zamzar file convesion credits -- send email of below a 
			// certain threshold set in the PSA Combine Receipts custom setting
			psaFileConvertZamzar.checkCredits();

			//Check the status of any file conversion jobs -- may execute one or more callouts
			// to the Zamzar file conversion service
			psaFileConvert.checkJobsByBatch(batchNumber, sourceObjectId, sourceObjectType, attemptCount);
		}

		//abort the job to remove it from the list of scheduled jobs
		system.abortJob(sc.getTriggerId());
	}
	
	public psaCombineExpenseReceiptsDocSchedulable (Decimal batchNumberIn, String sourceObjectIdIn, 
			String sourceObjectTypeIn, Integer attemptCountIn) {
		batchNumber = batchNumberIn;	
		sourceObjectId = sourceObjectIdIn;
		sourceObjectType = sourceObjectTypeIn;
		attemptCount = attemptCountIn;
	}
}