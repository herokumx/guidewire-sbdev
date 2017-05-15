public class ResourceRequestsHandler
{
    public void ResourceRequestGroup(set<id> Reqids)
    {
     
    List<ResourceRequest__c> Reqlst = [SELECT Id, Name, Description__c, Event_Type__c,RolesAsString__c, event_goals__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Region__c ,CreatedById,CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedDate
                                      FROM ResourceRequest__c WHERE Id IN: Reqids];
      
    List<feeditem> feeditems = new list<feeditem>();
  
    Map<string, CollaborationGroup> CollGroupMap = new Map<string, CollaborationGroup>();
    List<string> groupLst = new List<string>();
    Map<String,String> regionMap = new Map<string,string>();
        
   //ResourceRequest_Chatter_Group__c is a custom setting which has the fields RegionName__c,GroupName__c.
    List<ResourceRequest_Chatter_Group__c> regionGroupLst = ResourceRequest_Chatter_Group__c.getall().values();
    
    for(ResourceRequest_Chatter_Group__c req : regionGroupLst)
    {
       groupLst.add(req.GroupName__c);
       regionMap.put(req.GroupName__c,req.RegionName__c);
    }
    
    List<CollaborationGroup> SCGroups = [SELECT Id, Name from CollaborationGroup WHERE Name IN : groupLst];
       
    for(CollaborationGroup cg: SCGroups)
    {
        if(regionMap.containskey(cg.name))
            collgroupmap.put(regionMap.get(cg.name), cg);
    }
    
    for(ResourceRequest__c req : Reqlst)
    {
        if(req.Opportunity__r.Region__c != null)
        {
           if(req.status__c == 'Pending' && collgroupmap.containsKey(req.Opportunity__r.Region__c))
           { 
               CollaborationGroup sCStaffingGroup = collgroupmap.get(req.Opportunity__r.Region__c);
                            
                FeedItem post2 = new FeedItem();
                post2.ParentId = sCStaffingGroup.Id;   // requestID; //fix this to be the right group
                post2.Body = 'New Pending Resource Request created by: '+Req.CreatedBy.Name;          
           //   post2.Body = 'New Staffing Request:\n' + Req.Opportunity__r.Name + ' - '+Req.Name +' ('+Req.Event_Type__c+')'; // \nRoles Needed: ' + Req.RolesAsString__c;
                post2.Title = Req.Opportunity__r.Name + ' - '+Req.Name +' ('+Req.Event_Type__c+')';
                post2.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + Req.ID;
                feeditems.add(post2);
          }
        }      
    }  
    insert feeditems;
    }
}