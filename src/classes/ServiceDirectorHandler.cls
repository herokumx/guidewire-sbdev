public class ServiceDirectorHandler 
{
    public static void UpdateServiceDirector( list<opportunity> opplst)
    {
        list<EntitySubscription> newEntlst = new list<EntitySubscription>();
        set<id> serDirs = new set<id>();        
        for(opportunity opp: opplst)
        {
            if(opp.Services_Director__c != null )
            {
               serDirs.add(opp.Services_Director__c);
            }
        }
        Map<id, List<EntitySubscription>> DirEntSubMap = new Map<id, List<EntitySubscription>>();
        list<EntitySubscription> entlst = [select id,ParentId,SubscriberId from EntitySubscription where SubscriberId =: serDirs ];

        for(EntitySubscription  ent : entlst)
        {
          if(DirEntSubMap.containsKey(ent.SubscriberId))
          {
           list<EntitySubscription> DirLst = DirEntSubMap.get(ent.SubscriberId);
           DirLst.add(ent);
           DirEntSubMap.put(ent.SubscriberId, DirLst);
         }   
        else
        {
          list<EntitySubscription> DirLst = new list<EntitySubscription>();
           DirLst.add(ent);
           DirEntSubMap.put(ent.SubscriberId, DirLst);
        }          
     }

        for(opportunity opp: opplst)
        {
            if(opp.Services_Director__c != null) 
            {
              if(DirEntSubMap.get(opp.Services_Director__c).size() < 500)
              {
                EntitySubscription entsub = new EntitySubscription();
                entsub.ParentId = opp.Id;
                entsub.SubscriberId = opp.Services_Director__c;
                newEntlst.add(entsub);
              }
            }
        }
    insert newEntlst;
  }
            
    public static void UpdateServiceDirector1(set<id> oppids, list<opportunity> opplst, map<id,Opportunity> oldmap )
    {
        list<EntitySubscription> newEntlst = new list<EntitySubscription>();

        set<id> serDirs = new set<id>();        
        for(opportunity opp: opplst)
        {
            if(opp.Services_Director__c != null )
            {
               serDirs.add(opp.Services_Director__c);
            }
        }
        Map<id, List<EntitySubscription>> DirEntSubMap = new Map<id, List<EntitySubscription>>();
        list<EntitySubscription> entlst = [select id,ParentId,SubscriberId from EntitySubscription where SubscriberId =: serDirs ];
        
        for(EntitySubscription  ent : entlst)
        {
          if(DirEntSubMap.containsKey(ent.SubscriberId))
          {
           list<EntitySubscription> DirLst = DirEntSubMap.get(ent.SubscriberId);
           DirLst.add(ent);
           DirEntSubMap.put(ent.SubscriberId, DirLst);
         }   
        else
        {
          list<EntitySubscription> DirLst = new list<EntitySubscription>();
           DirLst.add(ent);
           DirEntSubMap.put(ent.SubscriberId, DirLst);
        }          
       }        

        Map<id,set<id>> entSubMap = new Map<id,set<id>>();    
        List<EntitySubscription> entSubLst = [select id,ParentId,SubscriberId from EntitySubscription where ParentId =: oppids];
        for(EntitySubscription  ent : entSubLst)
        {
        if(entSubMap.containsKey(ent.ParentId))
        {
          set<id> entSubidLst2 = entSubMap.get(ent.ParentId);
          entSubidLst2.add(ent.SubscriberId);
          entSubMap.put(ent.ParentId,entSubidLst2);
        }   
        else
        {
          set<id> entSubidLst1 = new set<id>();
          entSubidLst1.add(ent.SubscriberId);
          entSubMap.put(ent.ParentId,entSubidLst1);
        }
        }
        
          
        for(opportunity opp: opplst)
        {
            if(opp.Services_Director__c != null)
            {
             if(!DirEntSubMap.isempty() && DirEntSubMap.get(opp.Services_Director__c).size() < 500 )
             {
                opportunity oldopp = oldMap.get(opp.id);
                Set<id> entSubIdlst = entSubMap.get(opp.id);           
           
              if(oldopp.Services_Director__c != opp.Services_Director__c && (entSubIdlst==null || !entSubIdlst.contains(opp.Services_Director__c)))
                                 
                {
                      EntitySubscription entsub = new EntitySubscription();
                      entsub.ParentId = opp.Id;
                      entsub.SubscriberId = opp.Services_Director__c;
                      newEntlst.add(entsub);
                }
             }
            }
         }
        insert newEntlst;
        
    }
    
}