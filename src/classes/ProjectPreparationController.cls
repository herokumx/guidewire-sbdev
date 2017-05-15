public with sharing class ProjectPreparationController {
    public Project_Preparation__c preparation {get;set;}
    public Project_Preparation__c preparationOriginal {get;set;}
    public Project_Event__c projectEvent {get;set;}

    public ProjectPreparationController(ApexPages.StandardController controller) {
    //let's see if it is already set...if not, let's pull it from the event

        String projectEventID= ApexPages.currentPage().getParameters().get('ProjectEventID');
        if(projectEventID!= null)
        {//it is a new commitment, so let's set it up accordingly
            preparation = new Project_Preparation__c();
                
            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :projectEventID LIMIT 1];
                    
            preparation.Project_Event__c = projectEvent.Id ;
            //let's default it the current user
            preparation.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              preparation = [SELECT Id, Who__c, Hours__c, Start__c, End__c, Note__c, Project_Event__c
                                     FROM Project_Preparation__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            projectEvent = [SELECT Id from Project_Event__c
                                        WHERE Id = :preparation.Project_Event__c LIMIT 1];
        }
        preparationOriginal = preparation.clone(); // Copy

    }

  public PageReference save() {
        upsert preparation;
  
      //need to recalc event hours so save projectEvent now
       update projectEvent;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(projectEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
}