trigger CleanUpForDelete on ResourceRequest__c (before delete) {
    
    ResourceRequest__c[] reqs = Trigger.old;
    for(ResourceRequest__c req : reqs)
    {
        //find the assignments that point to this request
        Resource_Assignment__c[] assigns = [Select Id, (Select Id from Resource_Availabilities__r) from Resource_Assignment__c
                                    WHERE Resource_Request__c = :req.Id ];   

        for(Resource_Assignment__c theAssign: assigns )
        {
            if(theAssign.Resource_Availabilities__r != null && theAssign.Resource_Availabilities__r.size() > 0)
                delete theAssign.Resource_Availabilities__r;
        }                           
    
        if(assigns != null && assigns .size() > 0)        
            delete assigns ;
        
                    
        //find the possible dates that point to this request
        Possible_Date__c[] pdates = [Select Id from Possible_Date__c where Resource_Request__c = :req.Id ]; 
        if(pdates != null && pdates.size() > 0)
            delete pdates;
    
        //find Roles that point to this request
        Resource_Role__c[] roles = [Select Id from Resource_Role__c 
                                    WHERE Resource_Request__c = :req.Id ];   

        if(roles != null && roles.size() > 0)
            delete roles;
        
    }
    
}