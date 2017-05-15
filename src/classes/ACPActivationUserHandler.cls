public without sharing class ACPActivationUserHandler
{
    public static boolean allow = true;
    
    public static void stopTrigger()
    {
       allow = false; 
    }
    
    public static boolean RunTrigger()
    {
      return allow;    
    }
    
    @future
    public static void activateACP(Map<Id,Id> mapUser)
    {
       Map<Id, User> mapUserQ = new Map<Id, User>([Select ID, IsActive from User Where Id in:mapUser.keyset()]);
       List<CS_Asset_Contact_Permissions__c> acpLst =[Select id,name,CS_Access_Type__c,CS_Asset__c,CS_IsActive__c,CS_Contact__c, CS_Contact__r.User__r.IsActive ,CS_RightNow_ID__c from CS_Asset_Contact_Permissions__c where CS_Contact__c IN: mapUser.Values()];
       List<CS_Asset_Contact_Permissions__c> updateacpLst = new List<CS_Asset_Contact_Permissions__c>();
       List<Contact> contactList = new List<Contact>();
       
       if(acpLst.size() >0)
       {
           for(CS_Asset_Contact_Permissions__c acp : acpLst)
            {
               if (acp.CS_Contact__r.User__r.IsActive){
               acp.CS_IsActive__c = true;
               } else {
                   acp.CS_IsActive__c = false;
               }
               updateacpLst.add(acp);
               
             }
        }
        
       if (mapUser != NULL){
       
        if (mapUser.size() >0)
        { 
            for (Id usr:mapUser.keySet()){
            Contact c = new Contact();
            c.ID = mapUser.get(usr);
            c.User__c = usr;
            if (!mapUserQ.get(usr).IsActive)
            {
                c.CS_Is_Disabled__c = true;
                c.No_longer_with_firm__c = true; 
                c.Do_Not_Contact__c = true;
            } else {
                c.CS_Is_Disabled__c = false;
                 c.No_longer_with_firm__c = false; 
                c.Do_Not_Contact__c = false;
            }
            contactList.add(c);
            }
        }
       
       }
       
       
       ACPActivationUserHandler.stopTrigger();
       if (updateacpLst.size() > 0 ){
       Update updateacpLst; 
       }
       if (contactList.size() > 0){
        update contactList;
       }
    }
}