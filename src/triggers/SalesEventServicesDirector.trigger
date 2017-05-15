trigger SalesEventServicesDirector on Sales_Event__c (after insert)
{
    SalesEventServicesDirectorHandler evntHandler = new SalesEventServicesDirectorHandler();
        List<Sales_Event__c> evntLst = [select id,opportunity__c,opportunity__r.name,Name,opportunity__r.stageName, Event_Type__c,Presentation_Type__c,Location__c,Confirmed_Start_Date__c,Confirmed_End_Date__c,Event_Goals__c from Sales_Event__c where id=:Trigger.newMap.keyset()];
    evntHandler.UpdateSalesEvent(evntlst);

}