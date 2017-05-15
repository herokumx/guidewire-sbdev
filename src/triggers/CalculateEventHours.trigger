trigger CalculateEventHours on Sales_Event__c (before insert, before update) {


  Sales_Event__c[] sevs = Trigger.new;
    for(Sales_Event__c sevent: sevs)
    {  
        //calculate event hours first
//        sevent.Event_Hours__c = 0;     
        if(sevent.Event_Hours__c == null || sevent.Event_Hours__c < 0) sevent.Event_Hours__c = 0;   
        
        //now calculate total hours    
//        Integer count = sevent.Customer_Commitments__r.size();
        Integer count = 0;
        Decimal otherHours = 0;
//        if(count == null || count == 0)
//        {
//            count = 0;
            List<Customer_Commitment__c> theList = [SELECT Id, Coverage_Area__c, Event_Hours__c
                                                from Customer_Commitment__c 
                                                where Sales_Event__c = :sevent.Id];
                               
            for(Customer_Commitment__c theCommit : theList)
            {
              if(theCommit.Coverage_Area__c != 'Shadow' && theCommit.Coverage_Area__c != 'Observation')
              {
                  if(theCommit.Event_Hours__c == null)
                  {
                     count++;              
                  }
                  else if(theCommit.Event_Hours__c > 0)
                  {
                      otherHours  += theCommit.Event_Hours__c;
                  }
              }
            }        
//        }
        
        sevent.Customer_Hours__c = sevent.Event_Hours__c * count + otherHours; 
        
        if(sevent.Event_Type__c == 'RFI / RFP') 
        {
             sevent.Confirmed_Start_Date__c = sevent.RFx_Internal_Due__c;     
        }
        
    }    
}