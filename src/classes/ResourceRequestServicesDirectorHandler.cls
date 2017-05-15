public class ResourceRequestServicesDirectorHandler
{
    public void UpdateResourceRequest(list<ResourceRequest__c> reqlst)
    {
        set<id> oppids= new set<id>();
        
        for(ResourceRequest__c req: reqlst)
          oppids.add(req.opportunity__c);
        
        map<id,opportunity> oppmap = new map<id,opportunity>([select id,name,services_director__c, services_director__r.Name, stageName 
                                                              from opportunity where id=: oppids]);
        
        for(ResourceRequest__c req: reqlst)
        {
            opportunity opp = oppmap.get(req.Opportunity__c);
            
            if(opp.services_director__c != null)
               ServicesDirectorEmailHandler.ResourceRequestEmail(opp.Services_Director__c,opp.Services_Director__r.Name, req);
         }
    }

}