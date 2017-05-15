@isTest(seeAllData=true)
private class TestCustomerCommitmentController {

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
        
        Customer_Commitment__c commitment = new Customer_Commitment__c(Name = 'Customer Commitment Test 1',
                                                                       Sales_Event__c = event.Id,
                                                                       Who__c = UserInfo.getUserId()
                                                                      );
                                                                      
        insert commitment;
        
        Customer_Commitment_Date_Range__c dateRange = new Customer_Commitment_Date_Range__c(Start__c = Date.today().addDays(3), 
                                                                         End__c = Date.today().addDays(4),
                                                                         Note__c = 'note',                                                                         
                                                                         customer_commitment__c = commitment.Id);
        insert dateRange;
                
        
        ApexPages.StandardController controller = new ApexPages.StandardController(commitment);
        ApexPages.currentPage().getParameters().put('SalesEventID', event.Id);        
        CustomerCommitmentController theNewController = new CustomerCommitmentController (controller);
        //put in ID so the second controller has data
        ApexPages.currentPage().getParameters().remove('SalesEventID');
        ApexPages.currentPage().getParameters().put('id', commitment.Id);
        CustomerCommitmentController theExistingController = new CustomerCommitmentController (controller);


//        theNewController.possibleDate.Start__c = DateTime.now().addDays(-3);
//        theNewController.possibleDate.End__c = DateTime.now().addDays(-2);
        theNewController.save();
        theExistingController.save();
        theNewController.getAllDateRanges();
        theExistingController.getAllDateRanges();
        
        CustomerCommitmentController.deleteDateRange(dateRange.id,commitment.id);

        //test for new comment
        
        
//        post = [SELECT Id, CommentCount from FeedItem where Id = :post.Id LIMIT 1];
//        System.assertEquals(post.CommentCount, 2);
    
//        sc.save();
//        String nextPage = sc.save().getUrl();
//        System.assertEquals('/apex/SWOT', nextPage);
        
    
    }
}