@isTest
public class TestSalesEvntResRequestServicesDirector 
{
    static testmethod void SalesEvent()
    {
        opportunity opp = new opportunity();
        opp.Name = 'Tesst';
        opp.StageName='Lead';
        opp.CloseDate=system.today();
        opp.CurrencyIsoCode='USD';
        opp.Amount=1000;
        opp.Type='Net New';
        
        insert opp;
        
        opp.Services_Director__c = userinfo.getUserId();
        update opp;
        
        sales_event__c evnt = new sales_event__c();
        evnt.Name='tessst';
        evnt.Opportunity__c=opp.Id;
        evnt.Status__c='Tentative';
        evnt.Event_Type__c ='Discovery';
        evnt.Presentation_Type__c='On-site';
        
        insert evnt;
                
        ServicesdirectorEmailHandler.SaleseventEmail(opp.Services_Director__c, opp.services_director__r.Name, evnt);
        
        ResourceRequest__c req = new ResourceRequest__c();
        req.Name='tessst';
        req.Opportunity__c=opp.Id;
        req.Status__c='Tentative';
        req.Event_Type__c ='Discovery';
        req.Presentation_Type__c='On-site';
        
        insert req;
                
        ServicesdirectorEmailHandler.ResourceRequestEmail(opp.Services_Director__c, opp.services_director__r.Name, req);
        
   }
}