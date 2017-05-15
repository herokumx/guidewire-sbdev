public with sharing class PresalesCalendarRowsController {

    public String calendarFilter {get;set;}


    public PresalesCalendarRowsController()
    {
        calendarFilter = 'SC - AMER';
    }

    public void reloadPage()
    {


    }  

    public List<Calendar_Row__c> getListOfRows()
    {
        List< Calendar_Row__c > retval = new List< Calendar_Row__c >();
    
        if(calendarFilter == 'All')
        {
            retval = [SELECT Name, Id, Type__c, Calendar__c, Color__c , Priority__c
                      FROM Calendar_Row__c
                      ORDER BY Calendar__c, Priority__c];
        
        }
        else
        {
            retval = [SELECT Name, Id, Type__c, Calendar__c, Color__c , Priority__c
                      FROM Calendar_Row__c
                      WHERE Calendar__c = :calendarFilter
                      ORDER BY Priority__c]; 
        }

        return retval;
    }
}