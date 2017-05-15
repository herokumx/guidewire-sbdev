@isTest(seeAllData=true)
private class TestProjectEventController {

static testMethod void validateController() {
        
        Project__c proj = new Project__c(Name='Test Project',
                                      Status__c='Active',
                                      Description__c='Description');
        
        insert proj;        
        
        Project_Event__c projEvent = new Project_Event__c(Name='Test Project',
                                              Status__c='Tentative',
                                              Project__c = proj.Id);
        
        insert projEvent;
        
        
        Project_Event_Possible_Date__c pDate = new Project_Event_Possible_Date__c (Name = 'Possible date test 1',
                                              Project_Event__c = projEvent.Id,
                                              Event_Hours__c = 5,
                                              Start_Date__c = Date.today().addDays(-3),
                                              End_Date__c = Date.today().addDays(-2)
                                              );
        
        insert pDate ;
        
         Project_Participant__c participant = new Project_Participant__c(Name = 'Customer Commitment Test 1',
                                                                       Project_Event__c = projEvent.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert participant ;        
        
        Project_Preparation__c prep = new Project_Preparation__c(Name = 'Prep test 1',
                                              Project_Event__c = projEvent.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(3),
                                              End__c = Date.today().addDays(4),
                                              Hours__c = 4
                                              
                                              );
        
        insert prep;
        
        //SalesEventController
        ApexPages.StandardController controller = new ApexPages.StandardController(projEvent);
        //put in ID so the controller has data
        ApexPages.currentPage().getParameters().put('id', projEvent.Id);
        ProjectEventController theExistingController = new ProjectEventController (controller);

        
        
        //reloadEvent
        
        theExistingController.thisEvent.Status__c = 'Canceled';        
        //cancel
        //
        theExistingController.reloadEvent();
        //save
//        theExistingController.save();

        System.assertEquals(theExistingController.thisEvent.Status__c , 'Tentative');
        //getCustomerCommitmentsList
        System.assertEquals(theExistingController.getProjectParticipantsList().size(), 1);
        //getPreparationsList
        System.assertEquals(theExistingController.getProjectPreparationsList().size(), 1);

        //getAllPossibleDatesList
        System.assertEquals(theExistingController.getAllPossibleDatesList().size(), 1);

        //static selectDate(String dateID, String eventID)
        ProjectEventController.selectDate('' + pDate.Id, '' + theExistingController.thisEvent.Id);
        
        //static requestReview(String eventID)
        ProjectEventController.requestReview(theExistingController.thisEvent.Id,'This is a test message');

        //static deleteCommitment(String commitID, String eventID)
        ProjectEventController.deleteParticipant('' + participant.Id, '' + theExistingController.thisEvent.Id);
        
        //static deletePreparation(String prepID, String eventID)
        ProjectEventController.deletePreparation('' + prep.Id, '' + theExistingController.thisEvent.Id);

        
        theExistingController.reloadEvent();
        System.assertEquals(theExistingController.thisEvent.Status__c , 'Confirmed');
        System.assertEquals(theExistingController.getProjectPreparationsList().size(), 0);
        System.assertEquals(theExistingController.getAllPossibleDatesList().size(), 1);


       
        

//        System.assertEquals('/apex/SWOT', nextPage);
       
    }
}