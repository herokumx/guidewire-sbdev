@isTest(seeAllData=true)
public class TestSalesSupportRequestController{

    
    static testMethod void validateController() {
        //create an opportunity
        
        //create an opportunity
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
        

        Sales_Support_Request__c suppRequest = new Sales_Support_Request__c(Requested_Completion_Date__c = Date.today().addDays(220),
                                                                           Type__c='Dossier',
                                                                           Opportunity__c = o.Id);
        
        insert suppRequest;

        
        Support_Request_Preparation__c prep = new Support_Request_Preparation__c(Name = 'Prep test 1',
                                              Sales_Support_Request__c = suppRequest.Id,
                                              Who__c = UserInfo.getUserId(),
                                              Start__c = Date.today(),
                                              End__c = Date.today(),
                                              Hours__c = 4
                                              );
        
        insert prep;


	//        System.assertEquals(items.get(0).event.Id, event2.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(suppRequest);
        //put in ID so the controller has data
        ApexPages.currentPage().getParameters().put('id', suppRequest.Id);
        SalesSupportRequestController theExistingController = new SalesSupportRequestController (controller);
        
        theExistingController.reloadRequest();
       
        
        SalesSupportRequestController.requestReview(suppRequest.Id, 'Please review');
        SalesSupportRequestController.deletePreparation( prep.ID, suppRequest.Id);
        SalesSupportRequestController.completeRequest( suppRequest.Id );
        
        theExistingController.getIsPresalesManager();
        theExistingController.getIsSalesOrPresalesManager();
        theExistingController.getPreparationsList();
        theExistingController.save();
        theExistingController.cancel();
        
    }
}