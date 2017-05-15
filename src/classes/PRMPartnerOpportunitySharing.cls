public without sharing class PRMPartnerOpportunitySharing
{
    List<OpportunityShare> oppsharerecords = new List<opportunityshare>();
    
    public void partneropportunitysharing(List<opportunity> listopportunities)
    {        
        map<string, User> mapofAccountUsers = new map<string, User>();
        for(User usr: [select user.contact.account.id, name from user where profile.userlicense.name = 'Partner Community' and user.contact.Account.name != null and isactive = true])
               mapofAccountUsers.put(usr.contact.account.id, usr);
               
 //       System.debug('mapofAccountUsers '+ mapofAccountUsers.size());
        
 //       System.debug('Here 1 ' +  listopportunities.size());
        
        //SOQL query added by Rakshik on 30th July 2014
        /*  This query should be here as we won't get parent record information through Trigger.new
            e.g.- without SOQL "opp.recordtype.name" value will be null always.
        */
        List<opportunity> lstOppty = [Select Id,recordtype.name,owner.profile.userlicense.name,PRM_Referring_Partner2__c 
                                        from Opportunity where Id IN :listopportunities];
        
        for(Opportunity opp : lstOppty )
        {   
            if(opp.recordtype.name == 'Partner Opportunity' && opp.owner.profile.userlicense.name != 'Partner Community') 
            {
                //System.debug('Here 2 ' +  opp.PRM_Referring_Partner2__c);
                if(mapofAccountUsers.size() > 0 && mapofAccountUsers.get(opp.PRM_Referring_Partner2__c) != null)
                {
                    List<user> lsuser = [select id, name from user where user.contact.accountId =:opp.PRM_Referring_Partner2__c];
                    
                    //System.debug('lsuser size '+ lsuser.size());
                    for(user u : lsuser)
                    {
                        Opportunityshare oppshare = new OpportunityShare();
                        //oppshare.UserOrGroupId = mapofAccountUsers.get(opp.PRM_Referring_Partner2__c).id;
                        oppshare.UserOrGroupId = u.id;
                        oppshare.OpportunityId = opp.id;                            
                        //oppshare.Rowcause = 'Manual';
                        oppshare.OpportunityAccessLevel = 'Edit';
                        
                        oppsharerecords.add(oppshare);
                       // System.debug('Here 4 ');
                    }
                }
            }
        }
        if(oppsharerecords.size() > 0)
        {
           // System.debug('Here 5 ');
            insert oppsharerecords;
        }
    }
}