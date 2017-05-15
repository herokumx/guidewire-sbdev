@isTest(seeAllData=true)
private class TestSalesEventFBackOverrideExt
{
    static testMethod void SalesEventTest() {
        Id recordId = [Select Id from RecordType Where Name ='Partner' AND sObjectType='Account' limit 1].Id;
        system.debug('==****'+recordId);
        Account account = new Account();
        account.RecordTypeId = recordId;
        system.debug('=='+account.RecordType);
        account.Name = 'testAcc';
        account.Type = 'Other';
        account.Buying_Entity__c = 'Yes';
        account.Industry = 'Other';
        insert account;
        
        system.debug('==****'+account);
        
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
        insert salesEventFeedback;
        
        Feedback_Questions__c feedbackQuestions = new Feedback_Questions__c();
        feedbackQuestions.Active__c = 'true';
        feedbackQuestions.Question_Section__c ='Preparation';
        insert feedbackQuestions;
        
        Feedback_Questions__c feedbackQuestions1 = new Feedback_Questions__c();
        feedbackQuestions1.Active__c = 'true';
        feedbackQuestions1.Question_Section__c ='Preparation';
        insert feedbackQuestions1;

        Feedback_Questions__c feedbackQuestions2 = new Feedback_Questions__c();
        feedbackQuestions2.Active__c = 'true';
        feedbackQuestions2.Question_Section__c ='Preparation';
        insert feedbackQuestions2;

        Feedback_Questions__c feedbackQuestions3 = new Feedback_Questions__c();
        feedbackQuestions3.Active__c = 'true';
        feedbackQuestions3.Question_Section__c  ='Event';
        insert feedbackQuestions3;

        Feedback_Questions__c feedbackQuestions4 = new Feedback_Questions__c();
        feedbackQuestions4.Active__c = 'true';
        feedbackQuestions4.Question_Section__c ='Event Comments';
        insert feedbackQuestions4;
        
        List<Sales_Event_Feedback_Questions__c> salesEventFBackQuestionList = new List<Sales_Event_Feedback_Questions__c>();
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = 'Not Applicable', Question_Section__c = 'Preparation'));
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = 'Neutral', Question_Section__c = 'Event'));
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = 'Negative', Question_Section__c = 'Preparation Section'));
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = 'Positive', Question_Section__c = 'Domain Expertise'));
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = null, Question_Section__c = 'Selling Skil'));
        salesEventFBackQuestionList.add( new Sales_Event_Feedback_Questions__c( Feedback_Questions__c = feedbackQuestions.Id, Sales_Event_Feedback__c = salesEventFeedback.Id, Answer__c = '', Question_Section__c = 'Event Comments'));
        
        insert salesEventFBackQuestionList;
        
        ApexPages.currentPage().getParameters().put('SalesEventId', event.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(salesEventFeedback);
        SalesEventFeedBackOverrideExtension objSalesEventFBackExNew = new SalesEventFeedBackOverrideExtension(controller);
        objSalesEventFBackExNew.updateAnswer();
        objSalesEventFBackExNew.getEventaccom();
        objSalesEventFBackExNew.getQuestions();
        objSalesEventFBackExNew.getEventFeedback();
        objSalesEventFBackExNew.getPresentation();
        objSalesEventFBackExNew.getPreparationSection();
        objSalesEventFBackExNew.getDomainExpSection();
        objSalesEventFBackExNew.getDomain();
        objSalesEventFBackExNew.getSkillSec();
        objSalesEventFBackExNew.getSelling();
        objSalesEventFBackExNew.getComments();
        objSalesEventFBackExNew.getAnswers();
        objSalesEventFBackExNew.feedbacksave();
        
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions.Feedback_Questions__c =feedbackQuestions.Id;
        insert salesEventFBackQuestions;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions1 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions1.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions1.answer__c = 'Not Applicable';
        salesEventFBackQuestions1.Feedback_Questions__c =feedbackQuestions1.Id;
        insert salesEventFBackQuestions1;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions3 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions3.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions3.answer__c = 'Neutral';
        salesEventFBackQuestions3.Feedback_Questions__c =feedbackQuestions2.Id;
        insert salesEventFBackQuestions3;
        
        Sales_Event_Feedback_Questions__c salesEventFBackQuestions2 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions2.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions2.answer__c = 'Negative';
        salesEventFBackQuestions2.Feedback_Questions__c =feedbackQuestions3.Id;
        insert salesEventFBackQuestions2;

        Sales_Event_Feedback_Questions__c salesEventFBackQuestions4 = new Sales_Event_Feedback_Questions__c();
        salesEventFBackQuestions4.Sales_Event_Feedback__c = salesEventFeedback.Id;
        salesEventFBackQuestions4.answer__c = 'Positive';
        salesEventFBackQuestions4.Feedback_Questions__c =feedbackQuestions4.Id;
        insert salesEventFBackQuestions4;
                
        //objSalesEventFBackExNew.questionSectionMap.put('Preparation', salesEventFBackQuestions);
        //objSalesEventFBackExNew.questionSectionMap.put('Preparation', salesEventFBackQuestions);
        //objSalesEventFBackExNew.questionSectionMap.put('Preparation', salesEventFBackQuestions);
        
        SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper objFeedbackQuestionsWrapper = new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(feedbackQuestions, salesEventFBackQuestions);
        SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper objFeedbackQuestionsWrapper1 = new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(feedbackQuestions, salesEventFBackQuestions1);
        SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper objFeedbackQuestionsWrapper2 = new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(feedbackQuestions, salesEventFBackQuestions2);
        SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper objFeedbackQuestionsWrapper3 = new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(feedbackQuestions, salesEventFBackQuestions3);
        SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper objFeedbackQuestionsWrapper4 = new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(feedbackQuestions, salesEventFBackQuestions4);
        //new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(null, new Sales_Event_Feedback_Questions__c( answer__c = 'Not Applicable'));
        //new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(null, new Sales_Event_Feedback_Questions__c( answer__c = 'Neutral'));
        //new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(null, new Sales_Event_Feedback_Questions__c( answer__c = 'Negative'));
        //new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(null, new Sales_Event_Feedback_Questions__c( answer__c = 'Positive'));
        
        List<SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper> lst = new List<SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper>();
        
        lst.add(objFeedbackQuestionsWrapper);
        lst.add(objFeedbackQuestionsWrapper1);
        lst.add(objFeedbackQuestionsWrapper2);
        lst.add(objFeedbackQuestionsWrapper3);
        lst.add(objFeedbackQuestionsWrapper4);
        lst.add(new SalesEventFeedBackOverrideExtension.feedbackQuestionsWrapper(null, null));
        SalesEventFeedBackOverrideExtension objSalesEventFBackExNew1 = new SalesEventFeedBackOverrideExtension(controller);
        objSalesEventFBackExNew1.questionSectionMap.put('Preparation', lst);
        objSalesEventFBackExNew1.questionSectionMap.put('Event', lst);
        objSalesEventFBackExNew1.questionSectionMap.put('Event Comments', lst);
        objSalesEventFBackExNew1.feedbacksave();
        objSalesEventFBackExNew1.getQuestions()[0].answer.answer__c='No';
        map<id,Sales_Event_Feedback_Questions__c> mapQuestionAnswer1 =new map<id,Sales_Event_Feedback_Questions__c>();
        mapQuestionAnswer1.put(salesEventFBackQuestions.Feedback_Questions__c,salesEventFBackQuestions);
        mapQuestionAnswer1.put(salesEventFBackQuestions1.Feedback_Questions__c,salesEventFBackQuestions1);
        mapQuestionAnswer1.put(salesEventFBackQuestions2.Feedback_Questions__c,salesEventFBackQuestions2);
        mapQuestionAnswer1.put(salesEventFBackQuestions3.Feedback_Questions__c,salesEventFBackQuestions3);
        mapQuestionAnswer1.put(salesEventFBackQuestions4.Feedback_Questions__c,salesEventFBackQuestions4);
        
        objSalesEventFBackExNew1.mapQuestionAnswer =mapQuestionAnswer1;
        objSalesEventFBackExNew1.mapQuestionAnswer.put(salesEventFBackQuestions.Feedback_Questions__c,salesEventFBackQuestions);
        objSalesEventFBackExNew1.mapQuestionAnswer.put(salesEventFBackQuestions1.Feedback_Questions__c,salesEventFBackQuestions1);
        objSalesEventFBackExNew1.mapQuestionAnswer.put(salesEventFBackQuestions2.Feedback_Questions__c,salesEventFBackQuestions2);
        objSalesEventFBackExNew1.mapQuestionAnswer.put(salesEventFBackQuestions3.Feedback_Questions__c,salesEventFBackQuestions3);
        objSalesEventFBackExNew1.mapQuestionAnswer.put(salesEventFBackQuestions4.Feedback_Questions__c,salesEventFBackQuestions4);
        //objSalesEventFBackExNew.feedbacksave();
        
        //objSalesEventFBackExNew1.getQuestions()[0].answer.answer__c='No';
        //objSalesEventFBackExNew1.feedbacksave();
        
        //objSalesEventFBackExNew1.getEventFeedback()[0].answer.answer__c='';
        //objSalesEventFBackExNew1.feedbacksave();
        
        //objSalesEventFBackExNew1.getComments()[0].answer.answer__c='Test';
        //objSalesEventFBackExNew1.feedbacksave();
        
        objSalesEventFBackExNew1.getEventFeedback()[0].answer.answer__c='No';
        objSalesEventFBackExNew1.getEventFeedback()[0].answer.comment__c='No';
        objSalesEventFBackExNew1.getPreparationSection()[0].answer.answer__c='No';
        objSalesEventFBackExNew1.feedbacksave();
        
        objSalesEventFBackExNew1.getPreparationSection()[0].answer.answer__c='Yes';
        String thousandChar ='qwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnm';
        thousandChar +='qwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnm';
        thousandChar +='qwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnm';
        thousandChar +='qwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnmqwertyuioplkjhgfdsazxcvbnm';
        objSalesEventFBackExNew1.getEventFeedback()[0].answer.comment__c=thousandChar;
        objSalesEventFBackExNew1.feedbacksave();
        
        objSalesEventFBackExNew1.getEventFeedback()[0].answer.comment__c= 'test';
        objSalesEventFBackExNew1.getComments()[0].answer.comment__c= thousandChar;
        objSalesEventFBackExNew1.feedbacksave();
        
        objSalesEventFBackExNew1.getEventFeedback()[0].answer.comment__c= 'test';
        objSalesEventFBackExNew1.getComments()[0].answer.comment__c= 'test';
        objSalesEventFBackExNew1.feedbacksave();
    } 
}