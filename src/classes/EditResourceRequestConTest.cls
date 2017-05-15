@isTest
 class EditResourceRequestConTest
 {
    static testMethod void testEditResourceRequestCon()
    {
        Id recordId = [Select Id from RecordType Where Name ='Partner' AND sObjectType='Account' limit 1].Id;
        
        Account account = new Account();
        account.RecordTypeId = recordId;
        account.Name = 'testAcc1';
        account.Type = 'Other';
        account.Buying_Entity__c = 'Yes';
        account.Industry = 'Other';
        insert account;
        
        Opportunity opportunity = new Opportunity(SWOT_Strengths__c='S1 Value',
                                        SWOT_Weaknesses__c='W1 Value',
                                        SWOT_Opportunities__c = 'O1 Value',
                                        SWOT_Threats__c = 'T1 Value',
                                        SWOT_Strategy_SO__c = 'SO1 Value',
                                        SWOT_Strategy_ST__c = 'ST1 Value',
                                        SWOT_Strategy_WO__c = 'WO1 Value',
                                        SWOT_Strategy_WT__c = 'WT1 Value',
                                        Name = 'Test SWOT1 Opportunity',
                                        StageName = 'Qualified',
                                        CloseDate = Date.today(),
                                        Premium_In_Scope__c = 1000,
                                        Amount=100   );
        insert opportunity;
        
        
        ResourceRequest__c Resreq = new ResourceRequest__c(Opportunity__c = opportunity.Id, Status__c = 'Tentative');
                
        ApexPages.StandardController controller = new ApexPages.StandardController(Resreq);
        EditResourceRequestCon resreqcon = new EditResourceRequestCon(controller);
        resreqcon.saveMe();
    }
}