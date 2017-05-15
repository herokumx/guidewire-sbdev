public class SalesEventServicesDirectorHandler
{
    public void UpdateSalesEvent(list<sales_event__c> evntlst)
    {
        set<id> oppids = new set<id>();
        
        for(sales_event__c evnt : evntlst)
          oppids.add(evnt.opportunity__c);
        
        map<id,opportunity> oppmap = new map<id,opportunity>([select id,name, services_director__c,Services_Director__r.Name,stageName from opportunity where id =: oppids]);
        
              
        for(sales_event__c evnt: evntlst)
        {
            opportunity opp = oppmap.get(evnt.opportunity__c);
                     
            if(opp.services_director__c != null)
              ServicesDirectorEmailHandler.SalesEventEmail(opp.Services_Director__c,opp.Services_Director__r.Name, evnt);
       }
    }

}