@isTest(seeAllData=true)
private class TestEventPossibleDateController {

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
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o.Id);
        insert event;
        
        Event_Possible_Date__c pDate = new Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Sales_Event__c = event.Id,
                                              Event_Hours__c = 5,
                                              Start_Date__c = Date.today().addDays(-3),
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert pDate ;
                        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(pDate);
        ApexPages.currentPage().getParameters().put('SalesEventID', event.Id);        
        EventPossibleDateController theNewController = new EventPossibleDateController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('SalesEventID');
        ApexPages.currentPage().getParameters().put('id', pDate.Id);
        EventPossibleDateController theExistingController = new EventPossibleDateController (controller);


        theNewController.possibleDate.Start_Date__c = Date.today().addDays(-3);
        theNewController.possibleDate.End_Date__c = Date.today().addDays(-2);
        theNewController.possibleDate.Event_Hours__c = 4;

        theNewController.save();
        theExistingController.save();

        //test for new comment
        
        
//        post = [SELECT Id, CommentCount from FeedItem where Id = :post.Id LIMIT 1];
//        System.assertEquals(post.CommentCount, 2);
    
//        sc.save();
//        String nextPage = sc.save().getUrl();
//        System.assertEquals('/apex/SWOT', nextPage);
           
    }
}