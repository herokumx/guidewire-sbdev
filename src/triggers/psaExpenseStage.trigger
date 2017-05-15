/**************************************************************************************
// Name          : psaExpenseStage Trigger
// Date          : April 10, 2015
// Description   : psaExpenseStage Trigger
// Author        : CLD Partners
// Revisions     : 2015-04-10  Klassen  Initial version
***************************************************************************************/
trigger psaExpenseStage on PSA_Expense_Stage__c (after insert, after update) {
	psaTriggerHandlerFactory.createHandler(PSA_Expense_Stage__c.sObjectType);
}