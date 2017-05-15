trigger RecordStageOnEvent on Sales_Event__c (before insert) {

    Sales_Event__c[] sevs = Trigger.new;
    for(Sales_Event__c sevent: sevs)
    {  
        System.Debug('RecordStageOnEvent called');

        if(sevent.Opportunity__c != null)
        {
            if(sevent.Opportunity__r.StageName != null) sevent.Stage__c = sevent.Opportunity__r.StageName;
            else 
            {
                Opportunity thisOpp = [Select Id, StageName from Opportunity where Id = : sevent.Opportunity__c LIMIT 1];
                sevent.Stage__c = thisOpp.StageName;                   
            }
            System.Debug('Setting stage to sevent.Stage__c');              
        }

    }
}