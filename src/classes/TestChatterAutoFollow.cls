@isTest(seeallData=true)
public class TestChatterAutoFollow 
{
  static testmethod void AutoFollowTest()
  {
      account acc= new account();
      acc.Name = 'Test';
      acc.Type = 'Analyst';
      acc.Buying_Entity__c = 'No';
      acc.CurrencyIsoCode = 'USD';
      acc.Industry='Analyst';
      acc.BillingCountry = 'India';
      
      insert acc;   
      
      opportunity opp = new opportunity();
      opp.Name = 'Test1';
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
      
   /*   opportunity opp1 = new opportunity();
      opp1.Name = 'Test2';
      opp1.AccountId = acc.Id;
      opp1.CloseDate = system.today();
      opp1.CurrencyIsoCode = 'USD';
      opp1.Amount = 100;
      opp1.Type='Net New';
      opp1.Product_Type__c = 'PolicyCenter';
      opp1.StageName ='Qualified';
      opp1.Premium_In_Scope__c = 19;
       
      insert opp1;
   */   
      profile p = [select id,name from profile where name like 'System Admin%' limit 1];
   //   list<user> usrlst = [select id,name,profileId,isactive from user where profileId ='00e30000000cGt8' and isactive = true limit 3];
   
     list<user> usrlst = [select id,name,profileId,isactive from user where profileId =: p.Id and isactive = true limit 3];
      
      Chatter_Auto_Follow__c auto = new Chatter_Auto_Follow__c();
      auto.Region__c ='AMER';
      auto.Auto_Follow__c = false;
      auto.Auto_Follow_User__c = usrlst[0].id;
      
      insert auto;
      
      Chatter_Auto_Follow__c auto1 = new Chatter_Auto_Follow__c();
      auto1.Country__c='India';
      auto1.Auto_Follow__c = false;
      auto1.Auto_Follow_User__c = usrlst[1].id;      
      
      insert auto1;
      
      Chatter_Auto_Follow__c auto2 = new Chatter_Auto_Follow__c();
      auto2.Auto_Follow__c = true;
      auto2.Auto_Follow_User__c = usrlst[2].id;
      
      insert auto2;
      
      list<EntitySubscription> entlst = new list<EntitySubscription>();       
      EntitySubscription entsub = new EntitySubscription();
      entsub.ParentId = opp.Id;
      entsub.SubscriberId = opp.OwnerId;
      entlst.add(entsub); 
      
      update opp;  
      
      
      
        
  }
}