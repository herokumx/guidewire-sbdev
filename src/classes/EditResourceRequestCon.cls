public with sharing class EditResourceRequestCon
{
    public ResourceRequest__c ResourceRequest {get; set;}
    
    public EditResourceRequestCon(ApexPages.StandardController controller)
    {
        ResourceRequest = (ResourceRequest__c)controller.getRecord();
        ResourceRequest.Event_Goals__c = Label.EVENT_GOALS_TEXT;
        ResourceRequest.Description__c = Label.ResourceRequest_Description_Text;
    }
    
    public PageReference saveMe()
    {
        insert ResourceRequest;
        PageReference page = new ApexPages.StandardController(ResourceRequest).view();
        return page;
    }
    

}