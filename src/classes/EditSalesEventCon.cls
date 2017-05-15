public with sharing class EditSalesEventCon {
    public Sales_Event__c SalesEvent {get; set;}
    
    public EditSalesEventCon(ApexPages.StandardController controller)
    {
        SalesEvent = (Sales_Event__c)controller.getRecord();
        SalesEvent.Event_Goals__c = Label.EVENT_GOALS_TEXT;
    }
    
    public pageReference saveMe()
    {
        insert SalesEvent;
        PageReference page = new ApexPages.StandardController(SalesEvent).view();
        return page;
    }
}