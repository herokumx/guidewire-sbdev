@isTest(seeAllData=true)
private class TestPresalesMetricsController {

    static testMethod void validateController() {
        Opportunity o = new Opportunity(SWOT_Strengths__c='S Value',
                                        SWOT_Weaknesses__c='W Value',
                                        SWOT_Opportunities__c = 'O Value',
                                        SWOT_Threats__c = 'T Value',
                                        SWOT_Strategy_SO__c = 'SO Value',
                                        SWOT_Strategy_ST__c = 'ST Value',
                                        SWOT_Strategy_WO__c = 'WO Value',
                                        SWOT_Strategy_WT__c = 'WT Value',
                                        Name = 'Test SWOT Opportunity',
                                        StageName = 'Qualified',
                                        CloseDate = Date.today(),
                                        Premium_In_Scope__c = 1000,
                                        Amount=100   );
    
        insert o;
        
        
        //create an event for the current user
        
        Sales_Event__c event1 = new Sales_Event__c(Name='Test Event 1',
                                                   Opportunity__c = o.Id,
                                                   Confirmed_Start_Date__c = Date.today(),
                                                   Confirmed_End_Date__c = Date.today().addDays(1),
                                                   Event_Hours__c = 8,
                                                   Event_Type__c = 'Demonstration',
                                                   Status__c = 'Confirmed');
                                                   
        

        insert event1;

        Sales_Event__c event2 = new Sales_Event__c(Name='Test Event 1',
                                                   Opportunity__c = o.Id,
                                                   RFx_Internal_Due__c = Date.today(),
                                                   Event_Hours__c = 8,
                                                   Event_Type__c = 'RFI / RFP',
                                                   Status__c = 'Confirmed');
                                                   
        

        insert event2;
                
                
        PresalesMetricsController pmc = new PresalesMetricsController();
        //this might be called by constructer, but let's call it anyway
        pmc.reloadPage();
        
        
         
    }
}