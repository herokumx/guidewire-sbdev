@isTest(seeAllData=true)
private class TestSalesEventController {

    static testMethod void validateController() {
        Id recordId = [Select Id from RecordType Where Name ='Partner' AND sObjectType='Account' limit 1].Id;
        system.debug('==****'+recordId);
        Account account = new Account();
        account.RecordTypeId = recordId;
        system.debug('=='+account.RecordType);
        account.Name = 'testAcc';
        account.Type = 'Other';
        account.Buying_Entity__c = 'Yes';
        account.Industry = 'Other';
        insert account;
        
        system.debug('==****'+account);
        
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
                                //      PRM_Referring_Partner2__c = account.Id,
                                        Amount=100   );
        insert o;
        
        
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = o.Id, Status__c = 'Tentative');
        insert event;
        
        Event_Possible_Date__c pDate = new Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Sales_Event__c = event.Id,
                                              Event_Hours__c = 5,
                                              Start_Date__c = Date.today().addDays(-3),
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert pDate ;
        
         Customer_Commitment__c commitment = new Customer_Commitment__c(Name = 'Customer Commitment Test 1',
                                                                       Sales_Event__c = event.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert commitment;        
        
        Preparation__c prep = new Preparation__c(Name = 'Prep test 1',
                                              Sales_Event__c = event.Id,
                                              Who__c = UserInfo.getUserId()
                                              );
        
        insert prep;
        
        Demo_Team__c team = new Demo_Team__c(Name = 'Prep test 1',
                                              Sales_Event__c = event.Id,
                                              hours__c =10
                                              );
        
        insert team;
        
        
        Sales_Event_Feedback__c salesEventFeedback = new Sales_Event_Feedback__c();
        salesEventFeedback.Sales_Event__c = event.Id;
        insert salesEventFeedback;
        
        test.startTest();
        //SalesEventController
        ApexPages.StandardController controller = new ApexPages.StandardController(event);
        //put in ID so the controller has data
        PageReference pageRef = Page.SalesEvent;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', event.Id);
        //SalesEventController objExistingController = new SalesEventController();
        SalesEventController theExistingController = new SalesEventController(controller);
        theExistingController.strdelsaleseventfeedbackId =salesEventFeedback.Id;
        theExistingController.DeleteSaleEventFeedback();
        theExistingController.getlstSalesEventFeedback();
        //theExistingController.aId =salesEventFeedback.Id;
        //SalesEventController objExistingController = new SalesEventController(controller);
        
        //reloadEvent
        
        theExistingController.thisEvent = event;        
        //cancel
        theExistingController.cancel();
        //
        theExistingController.reloadEvent();
        
        //save
        theExistingController.save();

        System.assertEquals(theExistingController.thisEvent.Status__c , 'Tentative');
        //getCustomerCommitmentsList
        System.assertEquals(theExistingController.getCustomerCommitmentsList().size(), 1);

        //getPreparationsList
        System.assertEquals(theExistingController.getPreparationsList().size(), 1);
        
        //getDemoTeamsList
        System.assertEquals(theExistingController.getDemoteamsList().size(), 1);
        
        //getAllPossibleDatesList
        System.assertEquals(theExistingController.getAllPossibleDatesList().size(), 1);

        //static selectDate(String dateID, String eventID)
        SalesEventController.selectDate('' + pDate.Id, '' + theExistingController.thisEvent.Id);
        
        //static requestReview(String eventID)
        SalesEventController.requestReview(theExistingController.thisEvent.Id,'This is a test message');

        //static deleteCommitment(String commitID, String eventID)
        SalesEventController.deleteCommitment('' + commitment.Id, '' + theExistingController.thisEvent.Id);
        
        //static deletePreparation(String prepID, String eventID)
        SalesEventController.deletePreparation('' + prep.Id, '' + theExistingController.thisEvent.Id);
        
        //static deleteDemoteam(String TeamID, String eventID)
        SalesEventController.deleteDemoTeam('' + team.Id, '' + theExistingController.thisEvent.Id);

        
        theExistingController.reloadEvent();
        //System.assertEquals(theExistingController.thisEvent.Status__c , 'Confirmed');
        System.assertEquals(theExistingController.getPreparationsList().size(), 0);
        System.assertEquals(theExistingController.getAllPossibleDatesList().size(), 1);
        theExistingController.openFeedbackPage();
        theExistingController.getIsSalesOrPresalesManager();
        theExistingController.getIsPresalesManager();
        //SalesEventController.getIdOfAnnouncmentUser();
        Test.setCurrentPageReference(new PageReference('SalesEvent')); 
        System.currentPageReference().getParameters().put('id', account.Id);
        
        Test.setCurrentPageReference(new PageReference('SalesEvent'));
        System.currentPageReference().getParameters().put('id', salesEventFeedback.Id);
        SalesEventController existingController = new SalesEventController(controller);
        //ApexPages.currentPage().getParameters().put('id', salesEventFeedback.Id);
        //SalesEventController theExistingController = new SalesEventController(controller);

//        System.assertEquals('/apex/SWOT', nextPage);
       test.stopTest();
    }
}