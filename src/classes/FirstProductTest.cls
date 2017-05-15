@isTest(Seealldata=true)
private class FirstProductTest
{
    static testmethod void testFirstproduct()
    {
        
       Opportunity opp=new Opportunity();
       opp.StageName='Prospecting';
       opp.CloseDate=system.today();
       opp.Name='Test Opportinity'; 
       opp.amount=500;
       insert opp;
      
        Product2 prod=new Product2();
        prod.name='test prod';
        insert prod;
        
        Product2 prod1=new Product2();
        prod1.name='test prod1';
        insert prod1;

        PriceBook2 pb1=new PriceBook2();
        pb1.name='test pricebook1';
        insert pb1;
        
        PriceBook2 pb=[select id,name from pricebook2 where isstandard=true];
        
        PricebookEntry pe=new PricebookEntry();
        pe.Product2Id=prod.id;
        pe.Pricebook2Id=pb.Id;
        pe.UnitPrice=5;
        pe.IsActive=true;
        insert pe;
        
        PricebookEntry pe0=new PricebookEntry();
        pe0.Product2Id=prod1.id;
        pe0.Pricebook2Id=pb.Id;
        pe0.UnitPrice=5;
        pe0.IsActive=true;
        insert pe0; 

        
        PricebookEntry pe1=new PricebookEntry();
        pe1.Product2Id=prod.id;
        pe1.Pricebook2Id=pb1.Id;
        pe1.UnitPrice=5;
        pe1.IsActive=true;
        insert pe1;
        
        PricebookEntry pe2=new PricebookEntry();
        pe2.Product2Id=prod1.id;
        pe2.Pricebook2Id=pb1.Id;
        pe2.UnitPrice=5;
        pe2.IsActive=true;
        insert pe2;
        Test.startTest();
        
       OpportunityLineItem oli=new OpportunityLineItem();
       //oli.name='test Opportunity Product';
       oli.OpportunityId=opp.id;
       oli.PricebookEntryId=pe1.id;
       oli.Quantity=2; 
       oli.UnitPrice=4; 
       insert oli; 
        
       OpportunityLineItem oli1=new OpportunityLineItem();
       //oli.name='test Opportunity Product';
       oli1.OpportunityId=opp.id;
       oli1.PricebookEntryId=pe2.id;
       oli1.Quantity=2; 
       oli1.UnitPrice=4; 
       insert oli1;
        
       delete oli;  
        
       Test.stopTest();         
    }
}