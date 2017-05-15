@isTest
class EditSalesEventConTest
{
    static testMethod void testEditSalesEventCon()
    {
        Id recordId = [Select Id from RecordType Where Name ='Partner' AND sObjectType='Account' limit 1].Id;
        
        Account account = new Account();
        account.RecordTypeId = recordId;
        account.Name = 'testAcc';
        account.Type = 'Other';
        account.Buying_Entity__c = 'Yes';
        account.Industry = 'Other';
        insert account;
        
        Opportunity opportunity = new Opportunity(SWOT_Strengths__c='S Value',
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
        insert opportunity;
        
        
        Sales_Event__c event = new Sales_Event__c(Opportunity__c = opportunity.Id, Status__c = 'Tentative');
        //insert event;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(event);
        EditSalesEventCon newEditSalesEventCon = new EditSalesEventCon(controller);
        newEditSalesEventCon.saveMe();
    }
}