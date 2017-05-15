@isTest(seeAllData=true)
private class TestResourceRequestAssignmentController {

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
        ResourceRequest__c req = new ResourceRequest__c(Opportunity__c = o.Id);
        insert req;
        
        FeedItem post = new FeedItem();
            post.ParentId = req.Id; 
            post.Body = 'This request has been opened.';
            insert post;
        
        req.FeedAnnouncementID__c = post.Id;
        upsert req;
        
        //now add a possible date to the requ
        Resource_Role__c role = new Resource_Role__c(  Status__c='Required',
                                                       Resource_Request__c = req.Id
                                                      );                                             
                                                      
        insert role;
        
        
        Resource_Assignment__c assign = new Resource_Assignment__c(Resource_Request__c = req.Id, Resource_Role__c = role.Id);
        
        insert assign;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(role);
        ApexPages.currentPage().getParameters().put('ResReqID', req.Id);        
        ResourceRequestAssignmentController theNewController = new ResourceRequestAssignmentController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('ResReqID');
        ApexPages.currentPage().getParameters().put('id', assign.Id);
        ResourceRequestAssignmentController theExistingController = new ResourceRequestAssignmentController (controller);


//        theNewController.possibleDate.End__c = DateTime.now().addDays(-2);
        theNewController.resourceAssignment.Resource_Role__c = role.Id;
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