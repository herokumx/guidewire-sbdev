trigger CPQ_Order_BillingSchedule on Order (after insert, after update) {
    CPQ_Order_BillingSchedule_Helper handler = new CPQ_Order_BillingSchedule_Helper(Trigger.isExecuting, Trigger.size);

    if(Trigger.isInsert && Trigger.isAfter){
        if (CPQ_Order_BillingSchedule_Helper.runOnce() || Test.isRunningTest()){
            handler.OnAfterInsert(Trigger.new, Trigger.newMap);
        }
    }

    if(Trigger.isUpdate && Trigger.isAfter){
        if (CPQ_Order_BillingSchedule_Helper.runOnce() || Test.isRunningTest()){
            handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
    }
}