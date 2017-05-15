trigger UpdateAccountFullfillDate on Reference_Fulfillment__c (after insert,after update,after delete)
 {
    Set<id> accIds = new set<id>();
    if(Trigger.isInsert)
    {
        For(Reference_Fulfillment__c Req1 : Trigger.new)
        {
           if(Req1.Company_providing_Reference__c != null)
            accIds.add(Req1.Company_providing_Reference__c);
         }
    }
    if(Trigger.isUpdate)
    {
        For(Reference_Fulfillment__c Req1 : Trigger.new)
        {
           if(Req1.Company_providing_Reference__c != null )
            accIds.add(Req1.Company_providing_Reference__c);
         }
    }
    if(Trigger.isDelete)
    {
        For(Reference_Fulfillment__c Req1 : Trigger.old)
        {
             if(Req1.Company_providing_Reference__c != null)
                accIds.add(Req1.Company_providing_Reference__c);    
              }
      }
     
     system.debug('accounts :' +accids.size());

   List<account> acctoupdate = [SELECT id,name,Last_Date_a_Reference_was_fulfilled__c,(SELECT id,Date_Reference_is_Scheduled_for__c,lastmodifieddate,Company_providing_Reference__c FROM Reference_Fulfillment__r order by Date_Reference_is_Scheduled_for__c DESC ) FROM Account WHERE ID in :accIds];
        for(Account acc: AccToUpdate)
        {
            if (acc.Reference_Fulfillment__r.size()>0)
                acc.Last_Date_a_Reference_was_fulfilled__c = acc.Reference_Fulfillment__r[0].Date_reference_is_Scheduled_for__c;
            system.debug('date :'+acc.Reference_Fulfillment__r[0].Date_Reference_is_Scheduled_for__c);
            
        }
    if(!acctoupdate.isEmpty())
        Update acctoupdate;
            
}