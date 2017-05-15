public without sharing class PRMLead
{
    
    public void AddReferringPartner(List<Lead> listleads)
    {
       List<User> user = [SELECT name, user.contact.account.id, profile.userlicense.name from user where name = :UserInfo.getname() limit 1 ];
       System.debug('User name '+ user[0].name + ', ' + user[0].contact.account.id);
       
       if(user[0].profile.userlicense.name == 'Partner Community') { 
           for(Lead lead : listleads)
           {
                lead.PRM_Referring_Partner__c = user[0].contact.account.id;
           } 
        }
   }
}