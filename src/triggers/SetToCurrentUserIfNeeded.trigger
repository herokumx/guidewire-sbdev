trigger SetToCurrentUserIfNeeded on Personal_Event__c (before insert, before update) {
    User currentUser = [SELECT Id from User where Id = :UserInfo.getUserId() LIMIT 1]; 
    Personal_Event__c[] pevents = Trigger.new;
    for(Personal_Event__c pevent: pevents)
    {
        //look at the user__c and if not set, set to current user
        if(pevent.User__c == null)
        {
            pevent.User__c = currentUser.Id;
        }
    }
}