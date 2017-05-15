trigger RecordStageOnSupportRequest on Sales_Support_Request__c (before insert) {

    Sales_Support_Request__c[] ssrs = Trigger.new;
    for(Sales_Support_Request__c ssr: ssrs)
    {  
        System.Debug('RecordStageOnSupportRequest called');

        if(ssr.Opportunity__c != null)
        {
            if(ssr.Opportunity__r.StageName != null) ssr.Stage__c = ssr.Opportunity__r.StageName;
            else 
            {
                Opportunity thisOpp = [Select Id, StageName from Opportunity where Id = : ssr.Opportunity__c LIMIT 1];
                ssr.Stage__c = thisOpp.StageName;                   
            }
            System.Debug('Setting stage to: ' + ssr.Stage__c);              
        }

    }
}