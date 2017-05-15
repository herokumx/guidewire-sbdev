public with sharing class QuestionsSummaryViewCon {

    public String SalesEventId { get; set; }

    public String OpportunityId { get; set; }

    public DateTime LaunchedTime { get; set; }
    public String SalesEventName { get; set; }
    public String OpportunityName { get; set; }

    public List<Sales_Event_Feedback_Questions__c> lstSalesEventFeedback { get; set; }
    
    public List<String> lstEventGoals {get; set;}
    public List<String> lstPrepQue2 {get; set;}
    public List<String> lstPrepQue1 {get; set;}
    public List<String> lstPrepQue3 {get; set;}
    public List<String> lstPrepQue4 {get; set;}
    public List<String> lstPrepQue5 {get; set;}
    public List<String> lstPrepQue6 {get; set;}
    public List<String> lstPrepQue7 {get; set;}
    public List<String> lstDomainExpertQue1 {get; set;}
    public List<String> lstDomainExpertQue2 {get; set;}
    public List<String> lstDomainExpertQue3 {get; set;}
    public List<String> lstDomainExpertQue4 {get; set;}
    public List<String> lstDomainExpertQue5 {get; set;}
    public List<String> lstDomainExpertQue6 {get; set;}
    public List<String> lstSellingSkillQue1 {get; set;}
    public List<String> lstSellingSkillQue2 {get; set;}
    public List<String> lstSellingSkillQue3 {get; set;}
    public List<String> lstSellingSkillQue4 {get; set;}
    public List<String> lstSellingSkillQue5 {get; set;}
    public List<String> lstSellingSkillQue6 {get; set;}
    public List<String> lstComment1Present {get; set;}
    public List<String> lstComment2Present {get; set;}
    public List<String> lstComment1 {get; set;}
    public List<String> lstComment2 {get; set;}
    public List<String> lstUserNames {get; set;}
    public List<String> lstFeedbackRole {get; set;}
    
    public List<CommentWrapper> lstComment1Wrapper {get; set;}
    public List<CommentWrapper> lstComment2Wrapper {get; set;}
    
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
    
    public QuestionsSummaryViewCon()
    {
        string salesEventId = ApexPages.currentPage().getParameters().get('Id');
        
        List<Sales_Event_Feedback_Questions__c> lstSalesEventFeedbackQue = [Select Id,Sales_Event_Feedback__r.Feedback_Role__c, Answer__c, Comment__c, Sales_Event_Feedback__r.Sales_Event__r.Event_Goals__c, Question_Section__c,
                                                                                Sales_Event_Feedback__r.Sales_Event__r.Name, Sales_Event_Feedback__r.Sales_Event__r.Opportunity__r.Name, CreatedBy.Name, 
                                                                                Sales_Event_Feedback__r.Sales_Event__c, Sales_Event_Feedback__r.Sales_Event__r.Opportunity__c, Feedback_Questions__r.Question_Description__c
                                                                                from Sales_Event_Feedback_Questions__c 
                                                                                where Sales_Event_Feedback__r.Sales_Event__c =:salesEventId];
    
        if(!lstSalesEventFeedbackQue.isEmpty())
        {
            initializeUserInfo(lstSalesEventFeedbackQue);
            lstSalesEventFeedback = lstSalesEventFeedbackQue;
        }
    }
    
    public void initializeUserInfo(List<Sales_Event_Feedback_Questions__c> lstSalesEventFBQue)
    {
        OpportunityName = lstSalesEventFBQue[0].Sales_Event_Feedback__r.Sales_Event__r.Opportunity__r.Name;
        SalesEventName = lstSalesEventFBQue[0].Sales_Event_Feedback__r.Sales_Event__r.Name;
        SalesEventId = lstSalesEventFBQue[0].Sales_Event_Feedback__r.Sales_Event__c;
        OpportunityId = lstSalesEventFBQue[0].Sales_Event_Feedback__r.Sales_Event__r.Opportunity__c;
        LaunchedTime = DateTime.now();
        lstUserNames = new List<String>();
        lstFeedbackRole = new List<String>();
        lstEventGoals = new List<String>();
        lstPrepQue1 = new List<String>();
        lstPrepQue2 = new List<String>();
        lstPrepQue3 = new List<String>();
        lstPrepQue4 = new List<String>();
        lstPrepQue5 = new List<String>();
        lstPrepQue6 = new List<String>();
        lstPrepQue7 = new List<String>();
        lstDomainExpertQue1 = new List<String>();
        lstDomainExpertQue2 = new List<String>();
        lstDomainExpertQue3 = new List<String>();
        lstDomainExpertQue4 = new List<String>();
        lstDomainExpertQue5 = new List<String>();
        lstDomainExpertQue6 = new List<String>();
        lstSellingSkillQue1 = new List<String>();
        lstSellingSkillQue2 = new List<String>();
        lstSellingSkillQue3 = new List<String>();
        lstSellingSkillQue4 = new List<String>();
        lstSellingSkillQue5 = new List<String>();
        lstSellingSkillQue6 = new List<String>();

        lstComment1Present = new List<String>();
        lstComment2Present = new List<String>();
        
        lstComment1Wrapper = new List<CommentWrapper>();
        lstComment2Wrapper = new List<CommentWrapper>();
        
        EventSalesNLeadCount = 0;
        EventSupporterCount = 0;
        PrepSalesNLeadCount = 0;
        PrepSupporterCount = 0;
        DomainSalesNLeadCount = 0;
        DomainSupporterCount = 0;
        SellingSalesNLeadCount = 0;
        SellingSupporterCount = 0;
    
        for(Sales_Event_Feedback_Questions__c salesEventFeedbackQue : lstSalesEventFBQue)
        {
            if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.EVENT_GOAL_QUESTION)
            {
                lstUserNames.add(salesEventFeedbackQue.CreatedBy.Name);
                lstFeedbackRole.add(salesEventFeedbackQue.Sales_Event_Feedback__r.Feedback_Role__c);
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstEventGoals.add(salesEventFeedbackQue.Answer__c);
                else
                    lstEventGoals.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_1)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue1.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue1.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_2)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue2.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue2.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_3)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue3.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue3.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_4)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue4.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue4.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_5)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue5.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue5.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_6)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue6.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue6.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.PREPARATION_QUESTION_7 && salesEventFeedbackQue.Question_Section__c == 'Preparation')
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstPrepQue7.add(salesEventFeedbackQue.Answer__c);
                else
                    lstPrepQue7.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_1)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue1.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue1.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_2)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue2.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue2.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_3)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue3.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue3.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_4)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue4.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue4.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_5)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue5.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue5.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.DOMAIN_EXPERTIES_QUESTION_6 && salesEventFeedbackQue.Question_Section__c == 'Domain Expertise')
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstDomainExpertQue6.add(salesEventFeedbackQue.Answer__c);
                else
                    lstDomainExpertQue6.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_1)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue1.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue1.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_2)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue2.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue2.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_3)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue3.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue3.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_4)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue4.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue4.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_5)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue5.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue5.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.SELLING_QUESTION_6 && salesEventFeedbackQue.Question_Section__c == 'Selling Skill')
            {
                if(String.isNotBlank(salesEventFeedbackQue.Answer__c))
                    lstSellingSkillQue6.add(salesEventFeedbackQue.Answer__c);
                else
                    lstSellingSkillQue6.add('-');
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.COMMENT_1 )
            {
                if(String.isNotBlank(salesEventFeedbackQue.Comment__c))
                {
                    lstComment1Present.add('Yes');
                    CommentWrapper newCommentWrapper = new CommentWrapper(salesEventFeedbackQue.CreatedBy.Name, salesEventFeedbackQue.Comment__c);
                    lstComment1Wrapper.add(newCommentWrapper);
                }
                else
                {
                    lstComment1Present.add('No');
                    CommentWrapper newCommentWrapper = new CommentWrapper(salesEventFeedbackQue.CreatedBy.Name, '-');
                    lstComment1Wrapper.add(newCommentWrapper);
                }
            }
            else if(salesEventFeedbackQue.Feedback_Questions__r.Question_Description__c == Label.COMMENT_2)
            {
                if(String.isNotBlank(salesEventFeedbackQue.Comment__c))
                {
                    lstComment2Present.add('Yes');
                    CommentWrapper newCommentWrapper = new CommentWrapper(salesEventFeedbackQue.CreatedBy.Name, salesEventFeedbackQue.Comment__c);
                    lstComment2Wrapper.add(newCommentWrapper);
                }
                else
                {
                    lstComment2Present.add('No');
                    CommentWrapper newCommentWrapper = new CommentWrapper(salesEventFeedbackQue.CreatedBy.Name, '-');
                    lstComment2Wrapper.add(newCommentWrapper);
                }
            }
            
            if(salesEventFeedbackQue.Sales_Event_Feedback__r.Feedback_Role__c == 'Lead' || salesEventFeedbackQue.Sales_Event_Feedback__r.Feedback_Role__c == 'Owner')
            {
                if(salesEventFeedbackQue.Question_Section__c == 'Event')
                {
                    EventSalesNLeadCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        EventSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Preparation Section')
                {
                    PrepSalesNLeadCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        PrepSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Domain Expertise Section')
                {
                    DomainSalesNLeadCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        DomainSalesNLeadYesCount++;
                    }
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Selling Skill Section')
                {
                    SellingSalesNLeadCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        SellingSalesNLeadYesCount++;
                    }
                }
            }
            else if(salesEventFeedbackQue.Sales_Event_Feedback__r.Feedback_Role__c == 'Supporter')
            {
                if(salesEventFeedbackQue.Question_Section__c == 'Event')
                {
                    EventSupporterCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        EventSupporterYesCount++;
                    }
                    
                    if(String.isNotBlank(salesEventFeedbackQue.Comment__c))
                        EventComments += salesEventFeedbackQue.Comment__c+ '<br />';
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Preparation Section')
                {
                    PrepSupporterCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        PrepSupporterYesCount++;
                    }
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Domain Expertise Section')
                {
                    DomainSupporterCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        DomainSupporterYesCount++;
                    }
                }
                else if(salesEventFeedbackQue.Question_Section__c == 'Selling Skill Section')
                {
                    SellingSupporterCount++;
                    if(salesEventFeedbackQue.Answer__c == 'Yes')
                    {
                        SellingSupporterYesCount++;
                    }
                }
            }
        }
        
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
    
    public class CommentWrapper
    {
        public string UserName {get; set;}
        public string Comment {get; set;}
        
        public CommentWrapper(string UserName, string Comment)
        {
            this.UserName = UserName;
            this.Comment = Comment;
        }
    }
}