public class FirstProductHandler 

{

    public void updateFirstProduct(List<OpportunityLineItem> opplilst)
    {
        Set<id> oppidlst=new Set<id>();
        Set<id> prodidlst=new Set<id>();
       Map<id,string> olicheckMap=new   Map<id,string>();      
       for(OpportunityLineItem oppli : opplilst)
       {
           oppidlst.add(oppli.opportunityid);
       }
        
        
      List<opportunityLineItem> olitemlst=  [select id,name,opportunityid,product2id from opportunityLineItem where opportunityid=:oppidlst];
      
        Map<id,string> oliMap=new Map<id,string>();
        
        for(OpportunityLineItem oli : olitemlst)
       {
           oliMap.put(oli.opportunityid, oli.name);
       }
       
      for(OpportunityLineItem oli : opplilst)
       {
           if(oliMap.containsKey(oli.opportunityid))
              oli.First_Product__c=false;
           else if(!olicheckMap.containsKey(oli.opportunityid))
           {
             oli.First_Product__c=true;
             olicheckMap.put(oli.opportunityid, oli.name);
           }
       }     
       
    }
    
    public void updateFirstProductOnDelete(List<OpportunityLineItem> olilst)
    {
        Set<id> oppidlst=new Set<id>();
        
        
       for(OpportunityLineItem oli : olilst)
       {
           oppidlst.add(oli.opportunityid);
       }
        
        List<AggregateResult> agrlst=[select  min(createddate) mindate,opportunityid from opportunityLineItem where opportunityid=:oppidlst group by opportunityid];
        Set<id> oppidlst1=new Set<id>();
        Set<Datetime> createDtLst=new Set<Datetime>();
        
        
        List<opportunityLineItem> olitemlst=new List<opportunityLineItem>();
        
         for(AggregateResult ag:agrlst)
      {
          oppidlst1.add((ID)ag.get('opportunityid'));
          createDtLst.add((DateTime)ag.get('mindate'));
      }
        
      
         olitemlst=[select id,name,First_Product__c,opportunity.name,product2.name from opportunityLineItem where opportunityId=:oppidlst1 and createdDate=:createDtLst];
        Map<id,string> olicheckMap=new Map<id,string>();
        
        if(olitemlst.size()>0)
        {
            for(opportunityLineItem oli:olitemlst)
            {    
                if(!olicheckMap.containsKey(oli.opportunityid))
           {
             oli.First_Product__c=true;
             olicheckMap.put(oli.opportunityid, oli.name);
           }
              
            }
            update olitemlst;
        }
        
    }    
        
     
}