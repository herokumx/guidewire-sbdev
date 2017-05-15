trigger CountReferenceFullfillment on Reference_Fulfillment__c (After insert,Before update,After delete) {
List<id> accIdList = new List<id>();
   if(Trigger.isInsert){
        For(Reference_Fulfillment__c Reffullfill : Trigger.new){
            accIdList.add(Reffullfill.Company_providing_Reference__c);
         }
    }
    if(Trigger.isUpdate){
        For(Reference_Fulfillment__c Reffullfill : Trigger.new){
            accIdList.add(Reffullfill.Company_providing_Reference__c);
         }
    }

    if(Trigger.isDelete){
        For(Reference_Fulfillment__c Reffullfill : Trigger.old){
            accIdList.add(Reffullfill.Company_providing_Reference__c);
        }
    }
    List<Account> accUpdateList = new List<Account>();
    For(Account acc : [SELECT Total_Number_of_References_Fulfilled__c,(SELECT id,Status__c FROM Reference_Fulfillment__r Where Status__c ='Completed') FROM Account WHERE id =: accIdList]){
        acc.Total_Number_of_References_Fulfilled__c = acc.Reference_Fulfillment__r.size();
        accUpdateList.add(acc);
    }
    try{
        update accUpdateList;
    }Catch(Exception e){
        System.debug('Exception :'+e.getMessage());
    }
}