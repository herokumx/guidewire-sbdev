trigger CS_CreateContactACP on Community_Access_Request__c (after update) 
{
    CS_CreateContactACPHandler acp = new CS_CreateContactACPHandler();
    
    if(CS_CreateContactACPHandler.flag)
    {
        acp.ContactACP(trigger.new, trigger.oldMap,trigger.newMap.keySet());
    }
}