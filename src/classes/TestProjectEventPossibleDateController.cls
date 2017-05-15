@isTest(seeAllData=true)
private class TestProjectEventPossibleDateController {

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
        
        
                        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(pDate);
        ApexPages.currentPage().getParameters().put('ProjectEventID', projEvent.Id);        
        ProjectEventPossibleDateController theNewController = new ProjectEventPossibleDateController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('ProjectEventID');
        ApexPages.currentPage().getParameters().put('id', pDate.Id);
        ProjectEventPossibleDateController theExistingController = new ProjectEventPossibleDateController (controller);


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