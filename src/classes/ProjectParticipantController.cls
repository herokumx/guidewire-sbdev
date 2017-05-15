public with sharing class ProjectParticipantController {

   public Project_Participant__c participant{get;set;}
    public Project_Participant__c participantOriginal {get;set;}
    public Project_Event__c projectEvent{get;set;}
    public Boolean isNew {get;set;}

    public ProjectParticipantController(ApexPages.StandardController controller) {
     //let's set the resource request on the object here
        //let's see if it is already set...if not, let's pull it from the request
        isNew = false;
        String projectEventID= ApexPages.currentPage().getParameters().get('ProjectEventID');
        if(projectEventID!= null)
        {//it is a new participant, so let's set it up accordingly
            isNew = true;
            participant= new Project_Participant__c();
                
            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :projectEventID LIMIT 1];
                    
            participant.Project_Event__c = projectEvent.Id ;
            //let's default it the current user
            participant.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              participant = [SELECT Id, Name, Who__c, Description__c, Event_Hours__c, Project_Event__c,
                                      (SELECT Start__c, End__C, Note__C from Date_Ranges__r)
                                     FROM Project_Participant__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :participant.Project_Event__c LIMIT 1];
        }
        participantOriginal = participant.clone(); // Copy
    }

 public List<Project_Date_Range__c> getAllDateRanges()
   {
       List<Project_Date_Range__c> drs = [SELECT Start__c, End__C, Note__C, Project_Participant__c from Project_Date_Range__c where Project_Participant__c = :participant.Id];
        return drs;
   }
    
        
   public PageReference save() {
        upsert participant;
        //return to page for resource request
  
      //need to recalc event hours so save projectEvent now
       update projectEvent;
  
       PageReference reqPage = new ApexPages.StandardController(projectEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
    
    @RemoteAction
    public static String deleteDateRange(String rangeID, String commitID)
    {
       Project_Date_Range__c toDelete = [SELECT Id FROM Project_Date_Range__c where Id = :rangeID];
        if(toDelete != null)
        {
            delete toDelete;  

        }

        return 'success';
    }
}