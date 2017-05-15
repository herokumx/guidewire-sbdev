public with sharing class PresalesCalendarEventsController {

    public String eventFilter {get;set;}
    public String eventLimit {get;set;}
    public String eventRegion {get;set;}


    public PresalesCalendarEventsController()
    {
        eventFilter = 'Future';
        eventRegion = 'All';
    }
 
    public void reloadPage()
    {


    }  
    
    public List<Presales_Calendar_Event__c> getListOfEvents()
    {
        List<Presales_Calendar_Event__c> retval = new List<Presales_Calendar_Event__c>();
        
        if(eventFilter == 'Future')
        {
            if(eventRegion == 'All')
            {
                retval =  [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales__c, Sales_Consulting__c, Value_Consulting__c, Region__c
                          FROM Presales_Calendar_Event__c
                          WHERE End_Date__c >= :Date.Today()
                          ORDER BY Start_Date__c];
            }
            else
            {
                 retval = [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales__c, Sales_Consulting__c, Value_Consulting__c, Region__c
                          FROM Presales_Calendar_Event__c
                          WHERE End_Date__c >= :Date.Today() AND Region__c includes (:eventRegion)
                          ORDER BY Start_Date__c];
               
            }
        }
        else
        {
            if(eventRegion == 'All')
            {
                retval =  [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales__c, Sales_Consulting__c, Value_Consulting__c, Region__c
                          FROM Presales_Calendar_Event__c
                          WHERE End_Date__c < :Date.Today()
                          ORDER BY Start_Date__c DESC];
            }
            else
            {
                 retval = [SELECT Id, Label__c, Start_Date__c, End_Date__c, Sales__c, Sales_Consulting__c, Value_Consulting__c, Region__c
                          FROM Presales_Calendar_Event__c
                          WHERE End_Date__c < :Date.Today() AND Region__c includes (:eventRegion)
                          ORDER BY Start_Date__c DESC];
               
            }
        
        }
        
    
        return retval;
    }
    
}