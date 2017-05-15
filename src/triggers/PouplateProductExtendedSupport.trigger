trigger PouplateProductExtendedSupport on Extended_Support__c (before insert,before update,after insert,after update) {
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
            PouplateProdESHandler.onCreation(Trigger.new);
        else if(Trigger.isUpdate && !PouplateProdESHandler.isExecuted)
            PouplateProdESHandler.onUpdation(Trigger.new,Trigger.oldMap);
    }
    else
        PouplateProdESHandler.updateProduct(Trigger.new);
}