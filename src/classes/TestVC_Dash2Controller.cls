@isTest(seealldata=true)
private class TestVC_Dash2Controller
{ 
    static testmethod void vcdash2Test()
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
        opp.Amount=400;
       insert opp;
        
      /* CollaborationGroup cgp = new CollaborationGroup();
        cgp.Name='VC Staffing';
        cgp.CollaborationType='public';        
        insert cgp;
       */
       
        Sales_Support_Request__c ssr=new Sales_Support_Request__c();
        // ssr.name='test support req';
        ssr.Type__c='Dossier';
        ssr.Status__c='Not Started';
        ssr.Requested_Completion_Date__c=date.newinstance(2014, 2, 24);
        ssr.Opportunity__c=opp.id;
        insert ssr;
        
        Sales_Support_Request__c ssr1=new Sales_Support_Request__c();
       // ssr1.name='test support req';
        ssr1.Type__c='Dossier';
        ssr1.Status__c='Not Started';
        ssr1.Requested_Completion_Date__c=date.newinstance(2014, 1, 24);
        ssr1.Opportunity__c=opp.id;
        insert ssr1;
        
        Test.startTest();
        VC_Dash2Controller cntrl=new VC_Dash2Controller();
        String year=cntrl.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl.reloadPage();
        cntrl.getTheFilteredList();
        
        Test.stopTest();        
    }    
    
    static testmethod void vcdash2Test1()
    {
       Account acc=new Account();
       acc.name='test account';
       acc.BillingCountry='US';
       insert acc; 
        
        Sales_Support_Request__c ssr=new Sales_Support_Request__c();
        //ssr.name='test support req';
        ssr.Type__c='Dossier';
        ssr.Status__c='Completed';
        ssr.Actual_Completion_Date__c=date.newinstance(2014, 2, 24);
        ssr.Account__c=acc.id;
        //ssr.Opportunity__c=opp.id;
        insert ssr;
        
        Sales_Support_Request__c ssr1=new Sales_Support_Request__c();
        //ssr1.name='test support req';
        ssr1.Type__c='Dossier';
        ssr1.Status__c='Completed';
        ssr1.Actual_Completion_Date__c=date.newinstance(2014, 1, 24);
        ssr1.Account__c=acc.id;
        //ssr.Opportunity__c=opp.id;
        insert ssr1;
        
        Test.startTest();
        VC_Dash2Controller cntrl=new VC_Dash2Controller();
        String year=cntrl.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl.reloadPage();
        cntrl.getTheFilteredList();
        
        Test.stopTest();        
    }    
  
    static testmethod void vcdash2Test2()
    {
       Account acc=new Account();
       acc.name='test account';
       acc.BillingCountry='US';
       insert acc; 
        
        Sales_Support_Request__c ssr=new Sales_Support_Request__c();
        //ssr.name='test support req';
        ssr.Type__c='Dossier';
        ssr.Status__c='In Progress';
        ssr.Target_Completion_Date__c=date.newinstance(2014, 2, 24);
        ssr.Account__c=acc.id;
        //ssr.Opportunity__c=opp.id;
        insert ssr;
        
        Sales_Support_Request__c ssr1=new Sales_Support_Request__c();
        //ssr1.name='test support req';
        ssr1.Type__c='Dossier';
        ssr1.Status__c='In Progress';
        ssr1.Target_Completion_Date__c=date.newinstance(2014, 1, 24);
        ssr1.Account__c=acc.id;
        //ssr.Opportunity__c=opp.id;
        insert ssr1;
        
        Test.startTest();
        VC_Dash2Controller cntrl=new VC_Dash2Controller();
        String year=cntrl.getMyRequestRange();
        system.assertEquals(year, '2014');
        cntrl.reloadPage();
        List<VC_Dash2Controller.RequestWrapper> reqWrplst=cntrl.getTheFilteredList();
        VC_Dash2Controller.RequestWrapper reqwrapper=reqWrplst[0];
        reqwrapper.getRequestDateAsString();
        reqwrapper.setResultDate(date.today());
        reqwrapper.getResultDate();
      
        Test.stopTest();        
    }    
    
}