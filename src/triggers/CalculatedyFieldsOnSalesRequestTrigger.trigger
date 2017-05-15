trigger CalculatedyFieldsOnSalesRequestTrigger on ResourceRequest__c (before insert, before update) {
    
    ResourceRequest__c[] reqs = Trigger.new;
    for(ResourceRequest__c req : reqs)
    {
        //find Roles that point to this request
        String fullText = '';
        Resource_Role__c[] roles = [Select Id, Name, Role__c, Status__c from Resource_Role__c 
                                    WHERE Resource_Request__c = :req.Id and Status__c != 'No Longer Needed'
                                    ORDER BY Role__c ASC ];   
        for(Resource_Role__c role : roles)
        {
            if(fullText != '') fullText = fullText + ', ';
            fullText = fullText + role.Role__c;
        }
        req.RolesAsString__c = fullText;
        
    }
    
}