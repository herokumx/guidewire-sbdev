@isTest

private class TestTeamAddressesController 
{
    static testmethod void ValidateTeamAddresses()
    {
        profile p = [select id from Profile where name='standard user'];
        
       user u = new user();
        u.LastName='yara';
        u.username='yara@testorg.com';
        u.Email='yara@gmail.com';
        u.Alias='hari';
        u.CommunityNickname='boss';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='UTF-8';
        u.ProfileId=p.id;
        u.LanguageLocaleKey='en_US';
        
        
       insert u;
        
        TeamAddressesController tac = new TeamAddressesController();
        tac.getFullTeamAddresses();
    }

}