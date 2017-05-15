trigger NameFromUserRole on Resource_Assignment__c (before update) {

    for(Resource_Assignment__c ra: Trigger.New)  
    {     
            
        ra.Name = ra.User__r.Name + ' - ' + ra.Resource_Role__r.Role__c;
    
    }
}