@isTest
private class TestPresalesCalendarRowsCon
{
    static testmethod void testdata()
    {
        test.startTest();
       
        Calendar_Row__c crow=new Calendar_Row__c();
        crow.name='test calender';
        crow.Priority__c=5.00;
        insert crow;
        
        PresalesCalendarRowsController cntrl=new PresalesCalendarRowsController();
        
        cntrl.reloadPage();
        cntrl.getListOfRows();
        
        cntrl.calendarFilter='All';
        cntrl.getListOfRows();
        
        test.stopTest();
    }    

}