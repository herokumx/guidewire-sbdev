public with sharing class ProjectEventPossibleDateController {

    public Project_Event_Possible_Date__c possibleDate{get;set;}
    public Project_Event_Possible_Date__c possibleDateOriginal {get;set;}
    public Project_Event__c projectEvent {get;set;}


    public ProjectEventPossibleDateController(ApexPages.StandardController controller) {
  //let's see if it is already set...if not, let's pull it from the event

        String projectEventID= ApexPages.currentPage().getParameters().get('ProjectEventID');
        if(projectEventID!= null)
        {//it is a new commitment, so let's set it up accordingly
            possibleDate= new Project_Event_Possible_Date__c();
                
            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :projectEventID LIMIT 1];
                    
            possibleDate.Project_Event__c = projectEvent.Id ;        
        }
        else
        { //it already exists, so look it up from the ID
              possibleDate = [SELECT Id, Status__c, Start_Date__c, End_Date__c, Event_Hours__c, Note__c, Project_Event__c
                                     FROM Project_Event_Possible_Date__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :possibleDate.Project_Event__c LIMIT 1];
        }
        possibleDateOriginal = possibleDate.clone(); // Copy
    }
    
  public PageReference save() {
       try{
     
          upsert possibleDate;
       } catch(DMLException e){
//           ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, e.getdmlMessage(0) );
//           ApexPages.addMessage(msg);
           return null;
       }       
      //need to recalc event hours so save projectEvent now
       update projectEvent;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(projectEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
}