@isTest(seealldata=true)
private class TestResourceRequestsHandler 
{
    static testmethod void ChatterResource()
    {
        Opportunity opp = new Opportunity();
         opp.StageName = 'Prospecting';
         opp.CloseDate = system.today();
         opp.Name='testopp';
         opp.Amount=500;
         opp.Premium_In_Scope__c = 100;
        
         insert opp;
        
        ResourceRequest__c req = new ResourceRequest__c();
         req.Opportunity__c = opp.Id;
         req.Name='test';
        
         insert req;
    }

}