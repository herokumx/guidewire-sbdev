trigger CalculateProjectEventHours  on Project_Event__c (before insert, before update) {

    Project_Event__c[] sevs = Trigger.new;
    for(Project_Event__c sevent: sevs)
    {  
        //calculate event hours first
//        sevent.Event_Hours__c = 0;     
        if(sevent.Event_Hours__c == null || sevent.Event_Hours__c < 0) sevent.Event_Hours__c = 0;   
        
        //now calculate total hours    
//        Integer count = sevent.Customer_Commitments__r.size();
        Integer count = 0;
        Decimal otherHours = 0;
            List<Project_Participant__c> theList = [SELECT Id,  Event_Hours__c
                                                from Project_Participant__c 
                                                where Project_Event__c = :sevent.Id];
                               
            for(Project_Participant__c thePart : theList)
            {
                  if(thePart.Event_Hours__c == null)
                  {
                     count++;              
                  }
                  else if(thePart.Event_Hours__c > 0)
                  {
                      otherHours  += thePart.Event_Hours__c;
                  }
            }        
        
        sevent.Participant_Hours__c = sevent.Event_Hours__c * count + otherHours; 
        
    }

}