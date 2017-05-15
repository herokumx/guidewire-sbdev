@isTest
private class TestPresalesCalendarEventsController
{
    static testmethod void testdata()
    {
        test.startTest();
        
        Presales_Calendar_Event__c prce = new Presales_Calendar_Event__c();
          prce.Label__c='test events';
        prce.Start_Date__c=date.today();
        prce.End_Date__c=date.today()+1;
        
         insert prce;
        
        PresalesCalendarEventsController pcec = new PresalesCalendarEventsController();
         pcec.reloadPage();
         pcec.getListOfEvents();
        
         pcec.eventFilter='Future';
        pcec.eventRegion='All';
        pcec.getListOfEvents();
        
        pcec.eventFilter='test';
        pcec.eventRegion='tes';
        pcec.getListOfEvents();
        
        pcec.eventFilter='Future';
        pcec.eventRegion='tes';
        pcec.getListOfEvents();
        
        pcec.eventFilter='test';
        pcec.eventRegion='All';
        pcec.getListOfEvents();
         
        test.stopTest();
        
    }

}