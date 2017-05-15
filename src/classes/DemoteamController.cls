public with sharing class DemoteamController {
    public Demo_Team__c demoteam {get;set;}
    public Demo_Team__c demoteamOriginal {get;set;}
    public Sales_Event__c salesEvent {get;set;}


    public DemoteamController(ApexPages.StandardController controller) {

        //let's see if it is already set...if not, let's pull it from the event

        String salesEventID= ApexPages.currentPage().getParameters().get('SalesEventID');
        if(salesEventID!= null)
        {//it is a new commitment, so let's set it up accordingly
            demoteam = new Demo_Team__c();
                
            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :salesEventID LIMIT 1];
                    
            demoteam.Sales_Event__c = salesEvent.Id ;
            //let's default it the current user
           // preparation.Who__c = UserInfo.getUserId();
        
        }
        else
        { //it already exists, so look it up from the ID
              demoteam = [SELECT Id, Name, Hours__c, Start__c, End__c, Note__c, Sales_Event__c
                                     FROM Demo_Team__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :demoteam.Sales_Event__c LIMIT 1];
        }
        demoteamOriginal = demoteam.clone(); // Copy

    }
    
     public PageReference save() {
        upsert demoteam;
  
      //need to recalc event hours so save salesEvent now
       update salesEvent;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(salesEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }
    

}