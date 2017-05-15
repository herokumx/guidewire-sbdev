public with sharing class SalesEventFeedbackSummaryCon
{
    public String OpportunityName {get; set;}
    public String EventName {get; set;}
    public String EventGoals {get; set;}
    public Decimal EventSalesNLeadCount {get; set;}
    Decimal EventSalesNLeadYesCount = 0;
    public Decimal EventSalesNLeadScore {get; set;}
    public Decimal EventSupporterCount {get; set;}
    Decimal EventSupporterYesCount = 0;
    public Decimal EventSupporterScore {get; set;}
    public Decimal EventTotalScore {get; set;}
    public String EventComments {get; set;}
    public Decimal PrepSalesNLeadCount {get; set;}
    Decimal PrepSalesNLeadYesCount = 0;
    public Decimal PrepSalesNLeadScore {get; set;}
    public Decimal PrepSupporterCount {get;set;}
    Decimal PrepSupporterYesCount = 0;
    public Decimal PrepSupporterScore {get; set;}
    public Decimal DomainSalesNLeadCount {get; set;}
    Decimal DomainSalesNLeadYesCount = 0;
    public Decimal DomainSalesNLeadScore {get; set;}
    public Decimal DomainSupporterCount {get; set;}
    Decimal DomainSupporterYesCount = 0;
    public Decimal DomainSupporterScore {get; set;}
    public Decimal SellingSalesNLeadCount {get; set;}
    Decimal SellingSalesNLeadYesCount = 0;
    public Decimal SellingSalesNLeadScore {get; set;}
    public Decimal SellingSupporterCount {get; set;}
    Decimal SellingSupporterYesCount = 0;
    public Decimal SellingSupporterScore {get; set;}
    public String OtherComments {get; set;}
    
    public SalesEventFeedbackSummaryCon()
    {
        EventSalesNLeadCount = 0;
        EventSupporterCount = 0;
        PrepSalesNLeadCount = 0;
        PrepSupporterCount = 0;
        DomainSalesNLeadCount = 0;
        DomainSupporterCount = 0;
        SellingSalesNLeadCount = 0;
        SellingSupporterCount = 0;
        
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('Id')))
        {
            string salesEventId = ApexPages.currentPage().getParameters().get('Id');
            List<Sales_Event_Feedback_Questions__c> lstSalesEventFeedbackQue = [Select Id,Sales_Event_Feedback__r.Feedback_Role__c, Answer__c, Comment__c, Question_Section__c, Sales_Event_Feedback__r.Sales_Event__r.Event_Goals__c, 
                                                                                Sales_Event_Feedback__r.Sales_Event__r.Name, Sales_Event_Feedback__r.Sales_Event__r.Opportunity__r.Name
                                                                                from Sales_Event_Feedback_Questions__c 
                                                                                where Sales_Event_Feedback__r.Sales_Event__c =:salesEventId];
                                        
            if(!lstSalesEventFeedbackQue.isEmpty())
                initializeInfo(lstSalesEventFeedbackQue);
                
                system.debug('===='+lstSalesEventFeedbackQue.size());
        }
    }
    
    public void initializeInfo(List<Sales_Event_Feedback_Questions__c> lstSalesEventFeedbackQue)
    {
        OpportunityName = lstSalesEventFeedbackQue[0].Sales_Event_Feedback__r.Sales_Event__r.Opportunity__r.Name;
        EventName = lstSalesEventFeedbackQue[0].Sales_Event_Feedback__r.Sales_Event__r.Name;
        EventGoals = lstSalesEventFeedbackQue[0].Sales_Event_Feedback__r.Sales_Event__r.Event_Goals__c;
        EventComments = '';
        OtherComments = '';
        
        for(Sales_Event_Feedback_Questions__c salesEventFeedbackQuestions :lstSalesEventFeedbackQue)
        {
            if(salesEventFeedbackQuestions.Sales_Event_Feedback__r.Feedback_Role__c == 'Lead' || salesEventFeedbackQuestions.Sales_Event_Feedback__r.Feedback_Role__c == 'Owner')
            {
                if(salesEventFeedbackQuestions.Question_Section__c == 'Event')
                {
                    EventSalesNLeadCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        EventSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Preparation Section')
                {
                    PrepSalesNLeadCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        PrepSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Domain Expertise Section')
                {
                    DomainSalesNLeadCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        DomainSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Selling Skill Section')
                {
                    SellingSalesNLeadCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        SellingSalesNLeadYesCount++;
                    }
                }
                
                if(salesEventFeedbackQuestions.Question_Section__c == 'Event Comments' && String.isNotBlank(salesEventFeedbackQuestions.Comment__c))
                {
                    EventComments += salesEventFeedbackQuestions.Comment__c+ '<br />';
                }
                
                if(salesEventFeedbackQuestions.Question_Section__c == 'Selling Skill Comments' && String.isNotBlank(salesEventFeedbackQuestions.Comment__c))
                {
                    OtherComments += salesEventFeedbackQuestions.Comment__c+ '<br />';
                }
            }
            else if(salesEventFeedbackQuestions.Sales_Event_Feedback__r.Feedback_Role__c == 'Supporter')
            {
                if(salesEventFeedbackQuestions.Question_Section__c == 'Event')
                {
                    EventSupporterCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        EventSupporterYesCount++;
                    }
                    
                    if(String.isNotBlank(salesEventFeedbackQuestions.Comment__c))
                        EventComments += salesEventFeedbackQuestions.Comment__c+ '<br />';
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Preparation Section')
                {
                    PrepSupporterCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        PrepSupporterYesCount++;
                    }
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Domain Expertise Section')
                {
                    DomainSupporterCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        DomainSupporterYesCount++;
                    }
                }
                else if(salesEventFeedbackQuestions.Question_Section__c == 'Selling Skill Section')
                {
                    SellingSupporterCount++;
                    if(salesEventFeedbackQuestions.Answer__c == 'Yes')
                    {
                        SellingSupporterYesCount++;
                    }
                }
                
                if(salesEventFeedbackQuestions.Question_Section__c == 'Event Comments' && String.isNotBlank(salesEventFeedbackQuestions.Comment__c))
                {
                    EventComments += salesEventFeedbackQuestions.Comment__c+ '<br />';
                }
                
                if(salesEventFeedbackQuestions.Question_Section__c == 'Selling Skill Comments' && String.isNotBlank(salesEventFeedbackQuestions.Comment__c))
                {
                    OtherComments += salesEventFeedbackQuestions.Comment__c+ '<br />';
                }
            }
        }
        system.debug('****EventSalesNLeadYesCount'+EventSalesNLeadYesCount);
        system.debug('****EventSalesNLeadCount'+EventSalesNLeadCount);
        EventSalesNLeadScore = 0;
        EventSupporterScore = 0;
        PrepSalesNLeadScore = 0;
        DomainSalesNLeadScore = 0;
        SellingSalesNLeadScore = 0;
        PrepSupporterScore = 0;
        DomainSupporterScore = 0;
        SellingSupporterScore = 0;
        if(EventSalesNLeadCount > 0)
            EventSalesNLeadScore = (EventSalesNLeadYesCount / EventSalesNLeadCount).setScale(2);
        if(PrepSalesNLeadCount > 0)
            PrepSalesNLeadScore = (PrepSalesNLeadYesCount / PrepSalesNLeadCount).setScale(2);
        if(DomainSalesNLeadCount > 0)
            DomainSalesNLeadScore = (DomainSalesNLeadYesCount / DomainSalesNLeadCount).setScale(2);
        if(SellingSalesNLeadCount > 0)
            SellingSalesNLeadScore = (SellingSalesNLeadYesCount / SellingSalesNLeadCount).setScale(2);
        if(EventSupporterCount > 0)
            EventSupporterScore = (EventSupporterYesCount / EventSupporterCount).setScale(2);
        if(PrepSupporterCount > 0)
            PrepSupporterScore = (PrepSupporterYesCount / PrepSupporterCount).setScale(2);
        if(DomainSupporterCount > 0)
            DomainSupporterScore = (DomainSupporterYesCount / DomainSupporterCount).setScale(2);
        if(SellingSupporterCount > 0)
            SellingSupporterScore = (SellingSupporterYesCount / SellingSupporterCount).setScale(2);
        EventTotalScore = EventSalesNLeadScore + EventSupporterScore;
    }
}