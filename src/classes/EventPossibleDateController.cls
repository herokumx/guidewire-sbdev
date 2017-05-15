public with sharing class EventPossibleDateController {
    public Event_Possible_Date__c possibleDate{get;set;}
    public Event_Possible_Date__c possibleDateOriginal {get;set;}
    public Sales_Event__c salesEvent {get;set;}

    public EventPossibleDateController(ApexPages.StandardController controller) {


        //let's see if it is already set...if not, let's pull it from the event

        String salesEventID= ApexPages.currentPage().getParameters().get('SalesEventID');
        if(salesEventID!= null)
        {//it is a new commitment, so let's set it up accordingly
            possibleDate= new Event_Possible_Date__c();
                
            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :salesEventID LIMIT 1];
                    
            possibleDate.Sales_Event__c = salesEvent.Id ;        
        }
        else
        { //it already exists, so look it up from the ID
              possibleDate = [SELECT Id, Status__c, Start_Date__c, End_Date__c, Date_is_Flexible__c,Event_Hours__c, Note__c, Sales_Event__c
                                     FROM Event_Possible_Date__c
                                     WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

            salesEvent = [SELECT Id from Sales_Event__c
                                        WHERE Id = :possibleDate.Sales_Event__c LIMIT 1];
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
      //need to recalc event hours so save salesEvent now
       update salesEvent;
  
        //return to page for the event
       PageReference reqPage = new ApexPages.StandardController(salesEvent).view();
        reqPage.setRedirect(true);
        return reqPage ;
   }

}