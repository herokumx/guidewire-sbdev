@isTest(seeAllData=true)
private class TestDemoteamController
{
    static testMethod void validateController() 
    {
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
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o.Id);
        insert event;
        
        Demo_Team__c team = new Demo_Team__c(Name = 'Prep test 1',
                                              Sales_Event__c = event.Id,
                                              hours__c =10
                                              );
        
        insert team;
                        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(team);
        ApexPages.currentPage().getParameters().put('SalesEventID', event.Id);        
        DemoteamController theNewController = new DemoteamController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('SalesEventID');
        ApexPages.currentPage().getParameters().put('id', team.Id);
        DemoteamController theExistingController = new DemoteamController (controller);


//        theNewController.possibleDate.Start__c = DateTime.now().addDays(-3);
//        theNewController.possibleDate.End__c = DateTime.now().addDays(-2);
        theNewController.save();
        theExistingController.save();

    }

}