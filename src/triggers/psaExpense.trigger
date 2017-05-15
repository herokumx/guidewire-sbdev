trigger psaExpense on pse__Expense__c (before insert, after insert, before update, after update, before delete, after delete) {
    psaTriggerHandlerFactory.createHandler(pse__Expense__c.sObjectType);
}