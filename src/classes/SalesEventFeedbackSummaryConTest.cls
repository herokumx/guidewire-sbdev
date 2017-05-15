@isTest
class SalesEventFeedbackSummaryConTest
{
    static testMethod void testSalesEvFeedbackSummary()
    {
        Id recordId = [Select Id from RecordType Where Name ='Partner' AND sObjectType='Account' limit 1].Id;
        
        Account account = new Account();
        account.RecordTypeId = recordId;
        account.Name = 'testAcc';
        account.Type = 'Other';
        account.Buying_Entity__c = 'Yes';
        account.Industry = 'Other';
        insert account;
        
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
        
        Sales_Event_Feedback__c salesEventFeedback = new Sales_Event_Feedback__c();
        salesEventFeedback.Sales_Event__c = event.Id;
        salesEventFeedback.Feedback_Role__c = 'Lead';
        insert salesEventFeedback;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions.Sales_Event_Feedback__c = salesEventFeedback.Id;
        insert salesEventFBackQuestions;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions1 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions1.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions1.answer__c = 'Yes';
        salesEventFBackQuestions1.Question_Section__c = 'Event';
        insert salesEventFBackQuestions1;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions3 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions3.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions3.answer__c = 'Yes';
        salesEventFBackQuestions1.Question_Section__c = 'Preparation Section';
        insert salesEventFBackQuestions3;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions2 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions2.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions2.answer__c = 'Negative';
        insert salesEventFBackQuestions2;

        Sales_Event_Feedback_Questions__c salesEventFBackQuestions4 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions4.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions4.answer__c = 'Positive';
        salesEventFBackQuestions4.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions4.comment__c = 'Positive';
        insert salesEventFBackQuestions4;
        
        PageReference pageRef = Page.SalesEvent;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', event.Id);
        
        SalesEventFeedbackSummaryCon newSalesEventFeedbackSummaryCon = new SalesEventFeedbackSummaryCon();
                
        salesEventFeedback.Feedback_Role__c = 'Supporter';
        update salesEventFeedback;
        SalesEventFeedbackSummaryCon secondSalesEventFeedbackSummaryCon = new SalesEventFeedbackSummaryCon();
        
        List<Sales_Event_Feedback_Questions__c> lstSalesEvFeedQues = new List<Sales_Event_Feedback_Questions__c>();
        lstSalesEvFeedQues.add(salesEventFBackQuestions3);
        secondSalesEventFeedbackSummaryCon.initializeInfo(lstSalesEvFeedQues);
        newSalesEventFeedbackSummaryCon.initializeInfo(lstSalesEvFeedQues);
        
        salesEventFeedback.Feedback_Role__c = 'Lead';
        update salesEventFeedback;
        SalesEventFeedbackSummaryCon fourthSalesEventFeedbackSummaryCon = new SalesEventFeedbackSummaryCon();
        newSalesEventFeedbackSummaryCon.initializeInfo(lstSalesEvFeedQues);
    }
}