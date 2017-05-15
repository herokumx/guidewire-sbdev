@isTest(seealldata=true)
private class TestVC_Dash1Controller 
{
    static testmethod void VC1_Dash1()
    {
       Account acc=new Account();
       acc.name='test account';
       acc.BillingCountry='US';
       insert acc; 
        
       Opportunity opp=new Opportunity();
       opp.StageName='Prospecting'; 
       opp.CloseDate=system.today();
       opp.Name='Test Opportinity'; 
       opp.AccountId=acc.id;
       opp.Amount=500;
       insert opp;
       
       
        Sales_Event__c se=new Sales_Event__c();
        se.name='test sales event';
        se.Event_Type__c='Alignment';
        se.Status__c='Not Started';
        se.Opportunity__c=opp.id;
        insert se;
        
        Sales_Event__c se1=new Sales_Event__c();
        se1.name='test sales event1';
        se1.Event_Type__c='Consultation';
        se1.Status__c='Not Started';
        se1.Opportunity__c=opp.id;
        insert se1;
        
        Test.startTest();
        VC_Dash1Controller cntrl=new VC_Dash1Controller();
        String year=cntrl.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl.reloadPage();
        cntrl.getTheFilteredList();
        
        Test.stopTest();        
    }    
    
    static testmethod void VC1_Dash2()
    {
       Account acc=new Account();
       acc.name='test account';
       acc.BillingCountry='US';
       insert acc; 
        
        Opportunity opp=new Opportunity();
       opp.StageName='Prospecting'; 
       opp.CloseDate=system.today();
       opp.Name='Test Opportinity'; 
       opp.AccountId=acc.id;
        opp.Amount=100;
       insert opp;
        
        Sales_Event__c se2=new Sales_Event__c();
        se2.name='test sales event2';
        se2.Event_Type__c='Alignment';
        se2.Status__c='Not Started';
        se2.Opportunity__c=opp.id;
        insert se2;
        
        Sales_Event__c se3=new Sales_Event__c();
        se3.name='test sales event2';
        se3.Event_Type__c='Consultation';
        se3.Status__c='Not Started';
        se3.Opportunity__c=opp.id;
        insert se3;
        
        Test.startTest();
        VC_Dash1Controller cntrl1=new VC_Dash1Controller();
        String year=cntrl1.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl1.reloadPage();
        cntrl1.getTheFilteredList();
        
        Test.stopTest();   
        
            
    }
    
    static testmethod void VC1_Dash3()
    {
       Account acc=new Account();
       acc.name='test account';
       acc.BillingCountry='US';
       insert acc; 
        
        Opportunity opp=new Opportunity();
       opp.StageName='Prospecting'; 
       opp.CloseDate=system.today();
       opp.Name='Test Opportinity'; 
       opp.AccountId=acc.id;
        opp.Amount=1000;
       insert opp;
        
        Sales_Event__c se=new Sales_Event__c();
        se.name='test sales event';
        se.Event_Type__c='Alignment';
        se.Status__c='Not Started';
        se.Opportunity__c=opp.id;
        insert se;
        
        Sales_Event__c se1=new Sales_Event__c();
        se1.name='test sales event1';
        se1.Event_Type__c='Consultation';
        se1.Status__c='Not Started';
        se1.Opportunity__c=opp.id;
        insert se1;
        
        Test.startTest();
        VC_Dash1Controller cntrl=new VC_Dash1Controller();
        String year=cntrl.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl.reloadPage();
        cntrl.getTheFilteredList();
        
        
        VC_Dash1Controller cntr2=new VC_Dash1Controller();
        String year1=cntr2.getMyRequestRange();
        system.assertEquals(year1, '2014');
        cntr2.reloadPage();
        List<VC_Dash1Controller.EventWrapper> eveWrplst=cntr2.getTheFilteredList();
        
        VC_Dash1Controller.EventWrapper evewrapper=eveWrplst[0];
        evewrapper.setResultDate(date.today());
        evewrapper.getResultDate();
        
      
        Test.stopTest();        
        
    } 

}