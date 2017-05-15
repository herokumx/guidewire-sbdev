@isTest
public class ReferenceFullfillmentRequestTest 
{
    static testmethod void AutoFollowTest()
    {
      account acc =new account();
      acc.Name = 'TestPra';
      acc.Type = 'Analyst';
      acc.Buying_Entity__c = 'No';
      acc.CurrencyIsoCode = 'USD';
      acc.Industry='Analyst';
      acc.BillingCountry = 'India';
      
      insert acc;  
        
      opportunity opp = new opportunity();
      opp.Name = 'Testprat';
      opp.AccountId = acc.Id;
      opp.CloseDate = system.today();
      opp.CurrencyIsoCode = 'USD';
      opp.Amount = 10000;
      opp.Region__c='AMER';
      opp.Type='Net New';
      opp.Product_Type__c = 'PolicyCenter';
      opp.StageName ='Qualified';
      opp.Premium_In_Scope__c = 1900;
      
      insert opp;
        
       Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
       User u = new User(Alias = 'standt', Email='userprat@testorg.com',EmailEncodingKey='UTF-8', LastName='TestPrat', 
                         LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,
                         TimeZoneSidKey='America/Los_Angeles', UserName='userprat@testorg.com');
        
        insert u;
        
       Reference_Request__c refReq = new Reference_Request__c();
        refReq.Account_Requesting__c = acc.id;
        refReq.Opportunity_Related_To__c = opp.id;
        refReq.Gw_products_tobe_discussed_on_REF_Call__c ='BillingCenter';
        
        insert refReq;
        
        Reference_Request__c refReq1 = new Reference_Request__c();
        refReq1.Account_Requesting__c = acc.id;
        refReq1.Opportunity_Related_To__c = opp.id;
        refReq1.Gw_products_tobe_discussed_on_REF_Call__c ='ClaimCenter';
        
        insert refReq1;
        
      Reference_Fulfillment__c RefFull = new Reference_Fulfillment__c();
        RefFull.Date_Reference_is_Scheduled_for__c = date.today();
        RefFull.Company_providing_Reference__c = acc.id;
        RefFull.Reference_Requests__c = refReq.Id;
        RefFull.Status__c = 'pending';
        RefFull.Person_Responsible_for_Fulfiling_Request__c = u.id;
            
        insert Reffull;
        
        Reference_Fulfillment__c RefFull1 = new Reference_Fulfillment__c();
        RefFull1.Date_Reference_is_Scheduled_for__c = date.today();
        RefFull1.Company_providing_Reference__c = acc.id;
        RefFull1.Reference_Requests__c = refReq1.Id;
        RefFull1.Status__c = 'pending';
        RefFull1.Person_Responsible_for_Fulfiling_Request__c = u.id;
            
        insert Reffull1;
        
        delete Reffull1;
        delete refReq1;
    }        

}