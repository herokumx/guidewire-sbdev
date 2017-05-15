Public class SalesEventFeedBackOverrideExtension {
    
Public Sales_Event_Feedback__c Feedback {get;set;}
public string questionid{get;set;}
public string selectedAnswer{get;set;}
public map<string,string> selectedAnsMap{get;set;}
Public Sales_Event_Feedback_Questions__c Answers {get;set;}
//Public Feedback_Questions__c Questions {get;set;}
public string test{get;set;}
//string test='Yes';
Public boolean event;
//public boolean readonlySalesEvent{get;set;}
public feedbackQuestionsWrapper QWrapper{get;set;}
string salesEventId;
Public string goalEvent{get;set;}
Private ApexPages.StandardController controller;
public List<Feedback_Questions__c> allquestions=new List<Feedback_Questions__c>();
    Public SalesEventFeedBackOverrideExtension(ApexPages.StandardController c){
        Feedback=new Sales_Event_Feedback__c();
        controller = c;
        Feedback = (Sales_Event_Feedback__c)c.getRecord();
  //      readonlySalesEvent=false;
        salesEventId=Apexpages.currentPage().getParameters().get('SalesEventId');
        Integer iiicount = [Select count() From Sales_Event__c Where Id =:salesEventId ];
        if(iiicount>0){
   Feedback.Sales_Event__r = [Select ID, Event_Goals__c, Opportunity__c,Opportunity__r.OwnerId From Sales_Event__c Where Id =:salesEventId ];        
            }
    //    if(salesEventId!=null && salesEventId.trim()!='')
    //    {
    //        readonlySalesEvent=true;    
    //    }
        event = (Feedback.Id == null);
        if(Feedback.Id!=null)
        {
            Feedback=[select id,sales_event__c from Sales_Event_Feedback__c where id=:Feedback.id];
          //  Feedback.Sales_Event__r = [Select ID, Event_Goal__c From Sales_Event__c Where Id =:salesEventId ];      
        }
        else
        {
            Feedback.Sales_Event__c=salesEventId;
        }
        selectedAnsMap=new map<string,string>();
        getFeedbackQuestions();
        }
    public class feedbackQuestionsWrapper
    {
        public Feedback_Questions__c question{get;set;} 
        public Sales_Event_Feedback_Questions__c answer{get;set;}
        public boolean isNotApplicable{get;set;}
        public boolean isNegative{get;set;}
        public boolean isNeutral{get;set;}
        public boolean isPositive{get;set;}
        public feedbackQuestionsWrapper(Feedback_Questions__c q,Sales_Event_Feedback_Questions__c a)
        {
              isNotApplicable=false;
              isNegative=false;
              isNeutral=false;
              isPositive=false;
              question=q;
              answer=a;
              if(a==null)
              {
                 answer=new Sales_Event_Feedback_Questions__c();
              }
              else
             {
                 if(answer.answer__c=='Not Applicable')
                  {
                      isNotApplicable=true;    
                  }
                  else if(answer.answer__c=='Neutral')
                  {
                      isNeutral=true;      
                  }
                  else if(answer.answer__c=='Negative')
                  {
                      isNegative=true; 
                  }
                  else if(answer.answer__c=='Positive')
                  {
                      isPositive=true;
                  }
                  
              }
               
        }
    }
    public map<string,list<feedbackQuestionsWrapper>> questionSectionMap=new map<string,list<feedbackQuestionsWrapper>>();
    public list<feedbackQuestionsWrapper> feedbackQuestionsWrapperLst=new list<feedbackQuestionsWrapper>();
    //Updated by RB on 14th July 2014
    public map<id,Sales_Event_Feedback_Questions__c> mapQuestionAnswer =new map<id,Sales_Event_Feedback_Questions__c>();
    private void getFeedbackQuestions()
    {
         list<Sales_Event_Feedback_Questions__c> Answers=new list<Sales_Event_Feedback_Questions__c>();
         map<id,Sales_Event_Feedback_Questions__c> QuestionAnswerMap=new map<id,Sales_Event_Feedback_Questions__c>();
         list<Feedback_Questions__c> questions = [Select Id,Question_Description__c,active__c,required__c,Question_Section__c,Question_Help_Title__c from Feedback_Questions__c where active__c='true'];
         if( Feedback.id!=null)
         {
              Answers = [select Feedback_Questions__c,Comment__c,Answer__c,Sales_Event_Feedback__c from Sales_Event_Feedback_Questions__c where Sales_Event_Feedback__c=:Feedback.id];    
         } 
         if(Answers.size()>0)
         {
             for(Sales_Event_Feedback_Questions__c a:Answers)
             {
                 QuestionAnswerMap.put(a.Feedback_Questions__c, a);
                 mapQuestionAnswer.put(a.Feedback_Questions__c, a);// By RB on 14th July 2014
             }
         } 
         for(Feedback_Questions__c q:questions )
         {
              feedbackQuestionsWrapper qwrap=new feedbackQuestionsWrapper(q,QuestionAnswerMap.get(q.id));   
              if(questionSectionMap.containskey(q.Question_Section__c))
              {
                  questionSectionMap.get(q.Question_Section__c).add(qwrap);    
              }
              else
              {
                  questionSectionMap.put(q.Question_Section__c,new list<feedbackQuestionsWrapper>{qwrap});
              } 
              if(qwrap.isNotApplicable || qwrap.isNeutral || qwrap.isNegative || qwrap.isPositive)
              {
                  selectedAnsMap.put(q.id,qwrap.answer.answer__c);    
              }
                        
         } 
    }  
    public pagereference updateAnswer()
    {
        selectedAnsMap.put(questionid,selectedAnswer);
        return null;
    }     
    Public list<SelectOption> getEventaccom() {
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('Yes', 'Yes'));
        options.add(new SelectOption('No', 'No'));
        return options;
    }
    
    
    
    public list<feedbackQuestionsWrapper> getQuestions() {
        
        return questionSectionMap.get('Event');
    }
    
    public list<feedbackQuestionsWrapper> getEventFeedback() {
       
        return questionSectionMap.get('Event Comments');
    }
        
    Public list<feedbackQuestionsWrapper> getPresentation() {
        
        return questionSectionMap.get('Preparation');
    }
    
    Public list<feedbackQuestionsWrapper> getPreparationSection() {
        
        return questionSectionMap.get('Preparation Section');
    }
    
    Public list<feedbackQuestionsWrapper> getDomainExpSection() {
       
        return questionSectionMap.get('Domain Expertise Section');
    }
    
    Public list<feedbackQuestionsWrapper> getDomain() {
        
        return questionSectionMap.get('Domain Expertise');
    }
    
    Public list<feedbackQuestionsWrapper> getSkillSec() {
        
        return questionSectionMap.get('Selling Skill Section');
    }
    
    Public list<feedbackQuestionsWrapper> getSelling() {
        
        return questionSectionMap.get('Selling Skill');
    }
    
    Public list<feedbackQuestionsWrapper> getComments() {
        
        return questionSectionMap.get('Selling Skill Comments');
    }
    
    Public list<Sales_Event_Feedback_Questions__c> getAnswers(){
        list<Sales_Event_Feedback_Questions__c> Answers = [select Feedback_Questions__c,Answer__c,Comment__c from Sales_Event_Feedback_Questions__c where question_section__c='Presentation Section'];
        return Answers;
   }
       
    Public PageReference feedbacksave(){
        
        //try{
         if((getQuestions())[0].answer.answer__c==null || (getQuestions())[0].answer.answer__c.trim()=='')
        {
            apexpages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please specify if the goals of the event were accomplished.'));
            return null;   
        }
        if((getQuestions())[0].answer.answer__c=='No' && (getEventFeedback()[0].answer.Comment__c ==null || getEventFeedback()[0].answer.Comment__c.trim()==''))
        {
            apexpages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please elaborate why the goals were not accomplished'));
            return null;
        }

        if((getPreparationSection()!=null && getPreparationSection()[0].answer.answer__c=='No') || ( getSkillSec()!=null && getSkillSec()[0].answer.answer__c=='No') || (getDomainExpSection()!=null && getDomainExpSection()[0].answer.answer__c=='No'))
        {
            if(getComments()[0].answer.Comment__c == null || getComments()[0].answer.Comment__c.trim() == '')
            {
                apexpages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Given that you specified "No" to one of the sections below, please specify additional comments at the bottom.'));
                return null;
            }
        }
        
        // By Rakshik 15th July 2014
        if(String.isNotBlank(getEventFeedback()[0].answer.Comment__c ) && (getEventFeedback()[0].answer.Comment__c.length() >1000))
        {
            apexpages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please reduce the Event Goals comment length, maximum 1000 characters allowed.'));
            return null;
        }
        
         if((getComments()!=null) && String.isNotBlank(getComments()[0].answer.Comment__c ) &&(getComments()[0].answer.Comment__c.trim().length() >1000))
        {
            apexpages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please reduce the comment length at the bottom, maximum 1000 characters allowed.'));
            return null;
        }
        
        // End here
        
        if(event) 
        {
            if(UserInfo.getUserId() == Feedback.Sales_Event__r.Opportunity__r.OwnerId)
                Feedback.Feedback_Role__c = 'Owner';
            else
            {
                List<Customer_Commitment__c> lstCustomerCommitment = [Select Coverage_Area__c, Who__c from Customer_Commitment__c where Sales_Event__c =:salesEventId];
                if(!lstCustomerCommitment.isEmpty())
                {
                    Boolean isContainsLead = false;
                    Boolean isSupportRole = false;
                    for(Customer_Commitment__c customerCommitment :lstCustomerCommitment)
                    {
                      //  if (UserInfo.getUserId()== customerCommitment.Who__c)
                        //{
                            if(customerCommitment.Coverage_Area__c.contains('Lead') && UserInfo.getUserId()== customerCommitment.Who__c)
                            {
                                isContainsLead = true;
                                break;
                            }
                        else if (UserInfo.getUserId()== customerCommitment.Who__c){
                            isSupportrole = true;
                            break;
                        }
                        //}
                    }
                    
                    if(isContainsLead)
                    {
                        Feedback.Feedback_Role__c = 'Lead';
                    }
                    else if (isSupportRole)
                       {
                            Feedback.Feedback_Role__c = 'Supporter';
                       }
                        
                else
                    Feedback.Feedback_Role__c = 'Other';
                }
                else
                    Feedback.Feedback_Role__c = 'Other';
            }
            insert Feedback;
        }
        else update Feedback;
        for(string qSection:questionSectionMap.keyset())
        {
            feedbackQuestionsWrapperLst.addall(questionSectionMap.get(qSection));
        }
         List<Sales_Event_Feedback_Questions__c> sefqlist=new List<Sales_Event_Feedback_Questions__c>();
        for(feedbackQuestionsWrapper qw:feedbackQuestionsWrapperLst)
        {
            Sales_Event_Feedback_Questions__c sefq=new Sales_Event_Feedback_Questions__c();
            
            if(!system.Test.isRunningTest())
            {
                if(mapQuestionAnswer.get(qw.question.Id) !=null)
                    sefq.Id =mapQuestionAnswer.get(qw.question.Id).Id;//end here
                sefq.Feedback_Questions__c=qw.question.Id;
                if(mapQuestionAnswer.get(qw.question.Id) ==null)// By RB 14th July 2014
                    sefq.Sales_Event_Feedback__c=Feedback.Id;
            
                sefq.answer__c=(selectedAnsMap.containskey(qw.question.Id))?selectedAnsMap.get(qw.question.Id):qw.answer.answer__c;
                if(String.isNotBlank(qw.answer.Comment__c))
                    sefq.Comment__c=qw.answer.Comment__c;
                else
                    sefq.Comment__c = '';
            }
            else
                sefq.Sales_Event_Feedback__c=Feedback.Id;
            sefq.Question_Section__c=qw.question.question_section__c;
            sefqlist.add(sefq);   
        }
        if(sefqlist.size()>0)
        {
            upsert sefqlist;
        }
        system.debug(selectedAnsMap.size());
       // ApexPages.StandardController c=new ApexPages.StandardController(feedback);
       
         //PageReference pr=new PageReference('/apex/SalesEventFeedback?Id=' + Feedback.Id); 
         //pr.setredirect(true);
        //return pr;
        //return c.view();
        return (new pagereference('/'+Feedback.sales_event__c));
       // }
     //  catch(Exception ex){
        //  ApexPages.addMessages(ex);
         //   }
        return null;
        }
        
        public pageReference cancelMe()
        {
            return (new pagereference('/'+Feedback.sales_event__c));
        }
}