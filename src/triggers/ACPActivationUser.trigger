trigger ACPActivationUser on User (after insert, after update)
{
    //Custom setting to enable the trigger.
    ACPactivateUser__c ACP = ACPactivateUser__c.getInstance('ACPactivation');
    
    if(ACP != Null && ACP.isTriggerActive__c == True)
    {
        
        Map<ID,Id> mapUserContact = new Map<Id,Id>();
        List<User> usrLst = [Select id,name,contactId,profileId,profile.name,userType,isActive from User where Id IN: trigger.newMap.keyset() 
                             and ContactId != null and (profile.name = 'GW Customer Community' or profile.name = 'GW Partner Community') ];
                             
        // Code to Copy the User field back to the Contact 
        Set<id> ContactIds = new Set<id>();
        if(usrLst.size()>0)
        {
         for(User u: usrLst)
         {
           ContactIds.add(u.contactId);
           mapUserContact.put(u.Id,u.contactId);
         }
        }
    
         if(ACPActivationUserHandler.RunTrigger() == True)
             ACPActivationUserHandler.activateACP(mapUserContact);
     }
}