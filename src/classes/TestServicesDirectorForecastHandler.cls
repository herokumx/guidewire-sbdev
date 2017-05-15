@isTest(seeAllData = true)
public class TestServicesDirectorForecastHandler 
{
    static testmethod void ForecastTest()
    {   
        Profile p = [SELECT Id FROM Profile WHERE Name='GW Inside/Sales Ops']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testingser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standusertest@testorg.com');
        insert u;
        
                
        opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500, Region__c ='EMEA', 
                                           Premium_In_Scope__c = 100);             
                                          
        insert opp; 
        
    
    }        

}