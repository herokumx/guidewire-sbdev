@isTest(seeAllData = True)
public class TestServiceDirectorHandler
{
    static testmethod void ServiceDirector()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserte@testorg.com');
        insert u;
        
        opportunity opp = new opportunity();
        opp.Name = 'Tesst';
        opp.StageName='Lead';
        opp.CloseDate=system.today();
        opp.CurrencyIsoCode='USD';
        opp.Amount=1000;
        opp.Type='Net New';
        opp.Services_Director__c = u.id;
        
        insert opp;       
         
         EntitySubscription entsub1 = new EntitySubscription();
         entsub1.ParentId = opp.Id;
         entsub1.SubscriberId =  opp.Services_Director__c;
             
        insert entsub1;
         
                
        //  Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
          User u1 = new User(Alias = 'standt', Email='standard1user@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standard1userte@testorg.com');
         insert u1;
         
          opp.amount = 1000;
          opp.Services_Director__c = u1.id;
          update opp;
        
                   
    }

}