trigger CountReferencerequest on Reference_Request__c (After insert, After delete) {
List<id> accIdList = new List<id>();
   if(Trigger.isInsert){
        For(Reference_Request__c Req1 : Trigger.new){
            accIdList.add(Req1.Account_Requesting__c);
         }
    }
    if(Trigger.isDelete){
        For(Reference_Request__c Req1 : Trigger.old){
            accIdList.add(Req1.Account_Requesting__c);
        }
    }
    List<Account> accUpdateList = new List<Account>();
    For(Account acc : [SELECT Total_Number_of_References_Requested__c,(SELECT id FROM Reference_Request__r) FROM Account WHERE id =: accIdList]){
        acc.Total_Number_of_References_Requested__c = acc.Reference_Request__r.size();
        accUpdateList.add(acc);
    }
    try{
        update accUpdateList;
    }Catch(Exception e){
        System.debug('Exception :'+e.getMessage());
    }
}