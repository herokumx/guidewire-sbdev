public class ChatterAutoFollowHandler
{
    public static void AutoFollow(list<opportunity> opplst, set<id> oppids)
    {
        
        map<string,List<id>> RegionMap = new map<string,List<id>>();
        map<string,List<id>> CountryMap = new map<string,List<id>>();
        set<id> followupUsrLst = new set<id>();
        set<id> OwnerIds = new set<id>();
        
        boolean autofollowflag = false;
        
        list<EntitySubscription> entlst = new list<EntitySubscription>();
        map<id,set<id>> entSubMap = new Map<id,set<id>>();        
               
        List<Chatter_Auto_Follow__c> AutoFollowLst = [Select id,Auto_Follow__c,Auto_Follow_User__c from Chatter_Auto_Follow__c 
                                                            where Auto_Follow__c=true and auto_Follow_User__r.isactive=true ];
        for(Chatter_Auto_Follow__c auto: AutoFollowLst)
        {
            followupUsrLst.add(auto.Auto_Follow_User__c);
            autofollowFlag=true;
        }
        
        List<Chatter_Auto_Follow__c> regionLst = [Select id,Auto_Follow_User__c,Region__c from Chatter_Auto_Follow__c 
                                                   where Auto_Follow__c=false and region__c !=null and auto_Follow_User__r.isactive=true];
        for(Chatter_Auto_Follow__c auto: regionLst)
        {
            if(regionMap.containsKey(auto.Region__c))
            {
                List<id> regUsrLst2 = regionmap.get(auto.Region__c);
                regUsrLst2.add(auto.Auto_Follow_User__c);
                regionMap.put(auto.Region__c,regUsrLst2);
            }
            else
            {
                List<id> regUsrLst1 = new List<id>();
                regUsrLst1.add(auto.Auto_Follow_User__c);
                regionMap.put(auto.Region__c,regUsrLst1);               
            }
        }        
        
        List<Chatter_Auto_Follow__c> countryLst = [Select id,Auto_Follow_User__c,Country__c from Chatter_Auto_Follow__c 
                                                       where Auto_Follow__c=false and Country__c !=null and auto_Follow_User__r.isactive=true]; 
        for(Chatter_Auto_Follow__c auto: countryLst)
        {
            if(countryMap.containsKey(auto.Country__c))
            {
                List<id> cntUsrLst2 = countryMap.get(auto.Country__c);
                cntUsrLst2.add(auto.Auto_Follow_User__c);
                countryMap.put(auto.Country__c, cntUsrLst2);
            }
            else
            {
                List<id> cntUsrLst1 = new List<id>();
                cntUsrLst1.add(auto.Auto_Follow_User__c);
                countryMap.put(auto.Country__c, cntUsrLst1);
            }
         }
        
     // List<EntitySubscription> entSubLst = [select id,ParentId,SubscriberId from EntitySubscription where ParentId =: oppids];
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
        	       
            Set<id> entSubIdLst = new Set<id>();
            if(entSubMap != null && entSubMap.containsKey(opp.id))
                entSubIdLst = entSubMap.get(opp.Id);
               
           
            if(!entSubIdLst.contains(opp.OwnerId))
            {
            	if(opp.owner.isactive)
            	{
                EntitySubscription entsub = new EntitySubscription();
                entsub.ParentId = opp.Id;
                entsub.SubscriberId = opp.ownerid;
                entlst.add(entsub);
                ownerids.add(opp.OwnerId);
            	}
            }
                     
            if(autofollowFlag && !entSubIdlst.containsAll(followupUsrLst))
            {
               for(Id usrId : followupUsrLst)
                {
                    if(!ownerids.contains(usrId))
                    {
                    EntitySubscription entsub = new EntitySubscription();
                    entsub.ParentId = opp.Id;
                    entsub.SubscriberId = usrId;
                    entlst.add(entsub); 
                    }
                }          
             }
            
             else if(regionMap != Null && regionMap.containsKey(opp.Region__c))
             {
                List<id> usrLst = regionMap.get(opp.region__c);
                if(!entSubIdlst.containsAll(usrLst))
                {
                   for(id usrid : usrLst ) 
                   {
                       if(!ownerids.contains(usrId))
                      {
                      EntitySubscription entsub = new EntitySubscription();
                      entsub.ParentId = opp.Id;
                      entsub.SubscriberId = usrid;
                      entlst.add(entsub);
                      }
                    }
                 }   
               }
            
               else if(countryMap != Null && countryMap.containsKey(opp.Country__c))
               {
                  List<id> usrLst1 = countryMap.get(opp.Country__c);
                  if(!entSubIdlst.containsAll(usrLst1))
                  {
                     for(id usrid : usrLst1 ) 
                     {
                         if(!ownerids.contains(usrId))
                        { 
                        EntitySubscription entsub = new EntitySubscription();
                        entsub.ParentId = opp.Id;
                        entsub.SubscriberId = usrid;
                        entlst.add(entsub);
                      }
                     }
                   }   
                }    
        	   
         }
        
         insert entlst;
    }
}

/*
        for(opportunity opp: opplst)
        {
           if(opp.OwnerId != null)
            {
                EntitySubscription entsub = new EntitySubscription();
                entsub.ParentId = opp.Id;
                entsub.SubscriberId = opp.ownerid;
                entlst.add(entsub);                
            }
            
            if(autofollowFlag)
            {
               for(Id usrId : followupUsrLst)
                {
                    EntitySubscription entsub = new EntitySubscription();
                    entsub.ParentId = opp.Id;
                    entsub.SubscriberId = usrId;
                    entlst.add(entsub); 
                }          
             }
            
             else if(regionMap != Null && regionMap.containsKey(opp.Region__c))
             {
                List<id> usrLst = regionMap.get(opp.region__c);
                 for(id usrid : usrLst ) 
                   {
                      EntitySubscription entsub = new EntitySubscription();
                      entsub.ParentId = opp.Id;
                      entsub.SubscriberId = usrid;
                      entlst.add(entsub); 
                   }   
               }
            
               else if(countryMap != Null && countryMap.containsKey(opp.account.billingcountry))
               {
                  List<id> usrLst1 = countryMap.get(opp.account.billingcountry);
                    for(id usrid : usrLst1 ) 
                     {
                        EntitySubscription entsub = new EntitySubscription();
                        entsub.ParentId = opp.Id;
                        entsub.SubscriberId = usrid;
                        entlst.add(entsub); 
                     }
                 }                    
         }
        
         database.insert(entlst,false);        
     }
}
*/