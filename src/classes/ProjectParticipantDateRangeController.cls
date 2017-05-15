public with sharing class ProjectParticipantDateRangeController {

    public Project_Date_Range__c dateRange{get;set;}
    public Project_Participant__c participant{get;set;}


    public ProjectParticipantDateRangeController(ApexPages.StandardController controller) {

        String partId = ApexPages.currentPage().getParameters().get('ProjectParticipantID');
        if(partId != null)
        {//it is a new commitment, so let's set it up accordingly
            dateRange = new Project_Date_Range__c();
                
            participant = [SELECT Id from Project_Participant__c
                                        WHERE Id = :partId LIMIT 1];
                    
            dateRange.Project_Participant__c = participant.Id ;        
        }
        else
        { //it already exists, so look it up from the ID
              dateRange = [SELECT Id,  Start__c, End__c, Note__c, Project_Participant__c
                                     FROM Project_Date_Range__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

              participant = [SELECT Id from  Project_Participant__c
                                        WHERE Id = :dateRange.Project_Participant__c LIMIT 1];
        }

    }

   public PageReference save() {
        
       try{
          upsert dateRange;
       } catch(DMLException e){
//           ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, e.getdmlMessage(0) );
//           ApexPages.addMessage(msg);
           return null;
       }     
         
      //need to recalc event hours so save salesEvent now
       update participant;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(participant).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
}