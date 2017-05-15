@isTest(seeAllData=true)
private class TestProjectPreparationController {

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
        
         Project_Date_Range__c partDateRange = new Project_Date_Range__c(Start__c = Date.today().addDays(3), 
                                                                         End__c = Date.today().addDays(4),
                                                                         Note__c = 'note',
                                                                         
                                                                         Project_Participant__c = participant.Id);
        insert partDateRange ;
        
        Project_Preparation__c prep = new Project_Preparation__c(Name = 'Prep test 1',
                                              Project_Event__c = projEvent.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today().addDays(3),
                                              End__c = Date.today().addDays(4),
                                              Hours__c = 4
                                              
                                              );
        
        insert prep;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(prep);
        ApexPages.currentPage().getParameters().put('ProjectEventID', projEvent.Id);        
        ProjectPreparationController theNewController = new ProjectPreparationController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('ProjectEventID');
        ApexPages.currentPage().getParameters().put('id', prep.Id);
        ProjectPreparationController theOldController = new ProjectPreparationController (controller);
        
        theNewController.preparation.Start__c=date.today();
        theNewController.preparation.End__c=date.today()+1;
        theNewController.preparation.Hours__c=5;
        theNewController.save();
        theOldController.save();
            
//        PageReference pageRef = controller.save();
//        String next= pageref.getUrl();
//        System.assertEquals('/apex/ProjectPreparation', next);
        
    
    }
}