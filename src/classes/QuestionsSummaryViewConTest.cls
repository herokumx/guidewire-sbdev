@isTest
class QuestionsSummaryViewConTest
{
    static testMethod void testSalesEvQuestionsSummary()
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
        
        Feedback_Questions__c fbq = new Feedback_Questions__c();
        fbq.Question_Description__c = 'Were the goals of the events accomplished?';
        insert fbq;
        
        //Id fbqId= [Select Id from Feedback_Questions__c Where Name ='Q-0001' limit 1].Id;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions5 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions5.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions5.answer__c = 'Positive';
        salesEventFBackQuestions5.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions5.Feedback_Questions__c = fbq.Id;
        salesEventFBackQuestions5.comment__c = 'Positive';
        insert salesEventFBackQuestions5;        
        
        Feedback_Questions__c fbq2 = new Feedback_Questions__c();
        fbq2.Question_Description__c = 'Was the team well-positioned to succeed at the event?';
        insert fbq2;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions6 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions6.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions6.answer__c = 'Positive';
        salesEventFBackQuestions6.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions6.Feedback_Questions__c = fbq2.Id;
        salesEventFBackQuestions6.comment__c = 'Positive';
        insert salesEventFBackQuestions6;        
        
        Feedback_Questions__c fbq3 = new Feedback_Questions__c();
        fbq3.Question_Description__c = 'Team discussed strategy';
        insert fbq3;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions7 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions7.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions7.answer__c = 'Positive';
        salesEventFBackQuestions7.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions7.Feedback_Questions__c = fbq3.Id;
        salesEventFBackQuestions7.comment__c = 'Positive';
        insert salesEventFBackQuestions7;      
        
        Feedback_Questions__c fbq4 = new Feedback_Questions__c();
        fbq4.Question_Description__c = 'Discovery properly utilized';
        insert fbq4;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions8 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions8.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions8.answer__c = 'Positive';
        salesEventFBackQuestions8.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions8.Feedback_Questions__c = fbq4.Id;
        salesEventFBackQuestions8.comment__c = 'Positive';
        insert salesEventFBackQuestions8;   
        
        Feedback_Questions__c fbq5 = new Feedback_Questions__c();
        fbq5.Question_Description__c = 'Prospect expectation correctly set';
        insert fbq5;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions9 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions9.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions9.answer__c = 'Positive';
        salesEventFBackQuestions9.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions9.Feedback_Questions__c = fbq5.Id;
        salesEventFBackQuestions9.comment__c = 'Positive';
        insert salesEventFBackQuestions9; 
        
        Feedback_Questions__c fbq6 = new Feedback_Questions__c();
        fbq6.Question_Description__c = 'Requirement appropriately prioritized';
        insert fbq6;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions10 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions10.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions10.answer__c = 'Positive';
        salesEventFBackQuestions10.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions10.Feedback_Questions__c = fbq6.Id;
        salesEventFBackQuestions10.comment__c = 'Positive';
        insert salesEventFBackQuestions10;   
        
        Feedback_Questions__c fbq7 = new Feedback_Questions__c();
        fbq7.Question_Description__c = 'Support by other Guidewire teams';
        insert fbq7;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions11 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions11.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions11.answer__c = 'Positive';
        salesEventFBackQuestions11.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions11.Feedback_Questions__c = fbq7.Id;
        salesEventFBackQuestions11.comment__c = 'Positive';
        insert salesEventFBackQuestions11; 
        
        Feedback_Questions__c fbq8 = new Feedback_Questions__c();
        fbq8.Question_Description__c = 'Other';
        insert fbq8;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions12 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions12.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions12.answer__c = 'Positive';
        salesEventFBackQuestions12.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions12.Feedback_Questions__c = fbq8.Id;
        salesEventFBackQuestions12.comment__c = 'Positive';
        insert salesEventFBackQuestions12;          
        
        Feedback_Questions__c fbq9 = new Feedback_Questions__c();
        fbq9.Question_Description__c = 'Please elaborate if relevant.';
        insert fbq9;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions13 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions13.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions13.answer__c = 'Positive';
        salesEventFBackQuestions13.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions13.Feedback_Questions__c = fbq9.Id;
        salesEventFBackQuestions13.comment__c = 'Positive';
        insert salesEventFBackQuestions13; 
        
        Feedback_Questions__c fbq10 = new Feedback_Questions__c();
        fbq10.Question_Description__c = 'If you have additional comments or selected a value for Other in the sections above, please provide additional details here:';
        insert fbq10;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions14 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions14.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions14.answer__c = 'Positive';
        salesEventFBackQuestions14.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions14.Feedback_Questions__c = fbq10.Id;
        salesEventFBackQuestions14.comment__c = 'Positive';
        insert salesEventFBackQuestions14;                              
        
        Feedback_Questions__c fbq13 = new Feedback_Questions__c();
        fbq13.Question_Description__c = 'Did we demonstrate the appropriate level of expertise to meet or exceed the customer needs?';
        insert fbq13;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions17 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions17.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions17.answer__c = 'Positive';
        salesEventFBackQuestions17.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions17.Feedback_Questions__c = fbq13.Id;
        salesEventFBackQuestions17.comment__c = 'Positive';
        insert salesEventFBackQuestions17;      
        
        Feedback_Questions__c fbq14 = new Feedback_Questions__c();
        fbq14.Question_Description__c = 'Prospect';
        insert fbq14;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions18 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions18.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions18.answer__c = 'Positive';
        salesEventFBackQuestions18.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions18.Feedback_Questions__c = fbq14.Id;
        salesEventFBackQuestions18.comment__c = 'Positive';
        insert salesEventFBackQuestions18;   
        
        Feedback_Questions__c fbq15 = new Feedback_Questions__c();
        fbq15.Question_Description__c = 'Industry';
        insert fbq15;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions19 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions19.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions19.answer__c = 'Positive';
        salesEventFBackQuestions19.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions19.Feedback_Questions__c = fbq15.Id;
        salesEventFBackQuestions19.comment__c = 'Positive';
        insert salesEventFBackQuestions19; 
        
        Feedback_Questions__c fbq16 = new Feedback_Questions__c();
        fbq16.Question_Description__c = 'Guidewire Customer Base';
        insert fbq16;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions110 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions110.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions110.answer__c = 'Positive';
        salesEventFBackQuestions110.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions110.Feedback_Questions__c = fbq16.Id;
        salesEventFBackQuestions110.comment__c = 'Positive';
        insert salesEventFBackQuestions110;   
        
        Feedback_Questions__c fbq17 = new Feedback_Questions__c();
        fbq17.Question_Description__c = 'Guidewire Product/Technology';
        insert fbq17;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions111 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions111.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions111.answer__c = 'Positive';
        salesEventFBackQuestions111.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions111.Feedback_Questions__c = fbq17.Id;
        salesEventFBackQuestions111.comment__c = 'Positive';
        insert salesEventFBackQuestions111; 
        
        Feedback_Questions__c fbq18 = new Feedback_Questions__c();
        fbq18.Question_Description__c = 'Other';
        insert fbq18;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions112 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions112.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions112.answer__c = 'Positive';
        salesEventFBackQuestions112.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions112.Feedback_Questions__c = fbq18.Id;
        salesEventFBackQuestions112.comment__c = 'Positive';
        insert salesEventFBackQuestions112;     
        
        Feedback_Questions__c fbq23 = new Feedback_Questions__c();
        fbq23.Question_Description__c = 'Did Guidewire team represent as both professional and humble?';
        insert fbq23;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions27 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions27.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions27.answer__c = 'Positive';
        salesEventFBackQuestions27.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions27.Feedback_Questions__c = fbq23.Id;
        salesEventFBackQuestions27.comment__c = 'Positive';
        insert salesEventFBackQuestions27;      
        
        Feedback_Questions__c fbq24 = new Feedback_Questions__c();
        fbq24.Question_Description__c = 'Connection with audience';
        insert fbq24;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions28 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions28.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions28.answer__c = 'Positive';
        salesEventFBackQuestions28.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions28.Feedback_Questions__c = fbq24.Id;
        salesEventFBackQuestions28.comment__c = 'Positive';
        insert salesEventFBackQuestions28;   
        
        Feedback_Questions__c fbq25 = new Feedback_Questions__c();
        fbq25.Question_Description__c = 'Maintained control of the event';
        insert fbq25;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions29 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions29.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions29.answer__c = 'Positive';
        salesEventFBackQuestions29.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions29.Feedback_Questions__c = fbq25.Id;
        salesEventFBackQuestions29.comment__c = 'Positive';
        insert salesEventFBackQuestions29; 
        
        Feedback_Questions__c fbq26 = new Feedback_Questions__c();
        fbq26.Question_Description__c = 'Questions and objection handling';
        insert fbq26;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions210 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions210.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions210.answer__c = 'Positive';
        salesEventFBackQuestions210.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions210.Feedback_Questions__c = fbq26.Id;
        salesEventFBackQuestions210.comment__c = 'Positive';
        insert salesEventFBackQuestions210;   
        
        Feedback_Questions__c fbq27 = new Feedback_Questions__c();
        fbq27.Question_Description__c = 'Guidewire team dynamic(internal)';
        insert fbq27;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions211 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions211.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions211.answer__c = 'Positive';
        salesEventFBackQuestions211.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions211.Feedback_Questions__c = fbq27.Id;
        salesEventFBackQuestions211.comment__c = 'Positive';
        insert salesEventFBackQuestions211; 
        
        Feedback_Questions__c fbq28 = new Feedback_Questions__c();
        fbq28.Question_Description__c = 'Other';
        insert fbq28;
                
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions212 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions212.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions212.answer__c = 'Positive';
        salesEventFBackQuestions212.Question_Section__c = 'Event Comments';
        salesEventFBackQuestions212.Feedback_Questions__c = fbq28.Id;
        salesEventFBackQuestions212.comment__c = 'Positive';
        insert salesEventFBackQuestions212;          
        
        PageReference pageRef = Page.SalesEvent;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', event.Id);
        
        QuestionsSummaryViewCon newQuestionsSummaryViewCon = new QuestionsSummaryViewCon();
                
        salesEventFeedback.Feedback_Role__c = 'Supporter';
        update salesEventFeedback;
        QuestionsSummaryViewCon secondQuestionsSummaryViewCon = new QuestionsSummaryViewCon();

        List<Sales_Event_Feedback_Questions__c> lstSalesEvFeedQues = new List<Sales_Event_Feedback_Questions__c>();
        lstSalesEvFeedQues.add(salesEventFBackQuestions1);        
        lstSalesEvFeedQues.add(salesEventFBackQuestions2);                
        lstSalesEvFeedQues.add(salesEventFBackQuestions4);        
        lstSalesEvFeedQues.add(salesEventFBackQuestions3);
        secondQuestionsSummaryViewCon.initializeUserInfo(lstSalesEvFeedQues);
        newQuestionsSummaryViewCon.initializeUserInfo(lstSalesEvFeedQues);        
        
        salesEventFeedback.Feedback_Role__c = 'Lead';
        update salesEventFeedback;
        QuestionsSummaryViewCon fourthQuestionsSummaryViewCon = new QuestionsSummaryViewCon();
        fourthQuestionsSummaryViewCon.initializeUserInfo(lstSalesEvFeedQues);        
    }
}