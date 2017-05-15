trigger psaExpenseReport on pse__Expense_Report__c (before insert, after insert, before update, after update, before delete) {
    psaTriggerHandlerFactory.createHandler(pse__Expense_Report__c.sObjectType);
}