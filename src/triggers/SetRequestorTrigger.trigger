trigger SetRequestorTrigger on Sales_Support_Request__c (before insert, before update) {

  Sales_Support_Request__c[] ssrs = Trigger.new;
    for(Sales_Support_Request__c ssr: ssrs)
    {  
        if(ssr.Requested_For__c == null) ssr.Requested_For__c = ssr.CreatedBy.Id;
    }

}