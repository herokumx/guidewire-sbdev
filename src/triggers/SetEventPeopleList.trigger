trigger SetEventPeopleList on Sales_Event__c (before update) {

    Sales_Event__c[] sevs = Trigger.new;
//    for(Sales_Event__c sevent: sevs)
//    {  
        //let's query and get the all the data we need

        System.Debug('SetEventPeopleList called');

       List<Sales_Event__c> theseEvents =  [SELECT Id, Name, Confirmed_End_Date__c, Confirmed_Start_Date__c, Description__c, Event_Type__c, Presentation_Type__c, Location__c, Status__c, Opportunity__c,  Opportunity__r.Name, Opportunity__r.Owner.Name, Opportunity__r.Region__c, Opportunity__r.Product_Type__c, 
                                    (SELECT Id , Who__r.Name, Description__c, Coverage_Area__c, Sales_Event__c FROM Customer_Commitments__r ),
                                    (SELECT Id, Start__c, End__c, Who__r.Name, Note__c FROM Preparations__r)
                                    FROM Sales_Event__c  
//                                    WHERE Id = :sevent.Id];     
                                    WHERE Id = :sevs];     
       for(Sales_Event__c thisEvent: theseEvents)
       {
    //   Sales_Event__c thisEvent = sevent;
                    
       //let's walk through all of the commitments and build a list of names.  and look for the lead(s)
       Set<String> contributors = new Set<String>();  // PEOPLE that are in commitments that are not just shadow or observation (or both)
       Set<String> leads = new Set<String>();
       Set<String> observe = new Set<String>();
       Set<String> prep = new Set<String>();
       Set<String> shadow = new Set<String>();
       
       System.Debug('%%%%% Total Commitments: ' + thisEvent.Customer_commitments__r.size());
       for(Customer_Commitment__c thisCommitment : thisEvent.Customer_commitments__r)
       {
           //if the commitment is not just obs, shadow      
           if(thisCommitment.Coverage_Area__c != 'Observation' && 
              thisCommitment.Coverage_Area__c != 'Shadow' && 
              thisCommitment.Coverage_Area__c != 'Observation;Shadow')
           {
               System.Debug('%%%%% Adding to everyone: ' + thisCommitment.Who__r.Name);
               contributors.add(thisCommitment.Who__r.Name);
           }
           if(thisCommitment.Coverage_Area__c != null && thisCommitment.Coverage_Area__c.contains('Lead')) 
           {
               leads.add(thisCommitment.Who__r.Name);               
               System.Debug('%%%%% Adding to leads: ' + thisCommitment.Who__r.Name);
           }
           if(thisCommitment.Coverage_Area__c != null && thisCommitment.Coverage_Area__c.contains('Observation'))
           {
                observe.add(thisCommitment.Who__r.Name); 
           }
           if(thisCommitment.Coverage_Area__c != null && thisCommitment.Coverage_Area__c.contains('Shadow'))
           {
                shadow.add(thisCommitment.Who__r.Name); 
           }
       }
     
       System.Debug('%%%%% Total Preparations: ' + thisEvent.Preparations__r.size());
       for(Preparation__c thisPrep : thisEvent.Preparations__r)
       {
           System.Debug('%%%%% Adding to everyone: ' + thisPrep.Who__r.Name);
           if(!contributors.contains(thisPrep.Who__r.Name))
           {
               prep.add(thisPrep.Who__r.Name);                  
           }
       }  
       
       //now, let's build this value
       
       String thisResult = '';
       
       //remove the leads for the list of everyone
       contributors.removeAll(leads);
       List<String> everyoneList = new List<String>();
       everyoneList.addAll(contributors);
       everyoneList.sort();
       
       List<String> leadList = new List<String>();
       leadList.addAll(leads);
       leadList.sort();

       List<String> prepList = new List<String>();
       prepList.addAll(prep);
       prepList.sort();

       List<String> observerList = new List<String>();
       observerList.addAll(observe);
       observerList.sort();

       List<String> shadowList = new List<String>();
       shadowList.addAll(shadow);
       shadowList.sort();

       System.Debug('%%%%% list of leads: ' + leadList.size());

       for(String thisLead : leadList)
       {
           System.Debug('%%%%% Processing: ' + thisLead);
           if(thisResult != '') thisResult += ',';
           thisResult +=  thisLead + '*';
           System.Debug('%%%%% thisResult is now: ' + thisResult);
       }

       System.Debug('%%%%% list of everyone: ' + everyoneList.size());

       for(String thisPerson : everyoneList)
       {
           System.Debug('%%%%% Processing: ' + thisPerson);
           if(thisResult != '') thisResult += ',';
           thisResult += thisPerson;
           System.Debug('%%%%% thisResult is now: ' + thisResult);
       }

        if(prepList.size() > 0)
        {
            if(thisResult != '') thisResult += ';';
            thisResult += ' PREP ONLY:';
        }


       for(String thisPerson : prepList)
       {
           System.Debug('%%%%% Processing: ' + thisPerson);
           if(thisResult != '' && !thisResult.endsWith(':')) thisResult += ',';
           thisResult += thisPerson;
           System.Debug('%%%%% thisResult is now: ' + thisResult);
       }

        if(shadowList.size() > 0)
        {
            if(thisResult != '') thisResult += ';';
            thisResult += ' SHADOWS:';
        }
       for(String thisPerson : shadowList)
       {
           System.Debug('%%%%% Processing: ' + thisPerson);
           if(thisResult != '' && !thisResult.endsWith(':')) thisResult += ',';
           thisResult += thisPerson;
           System.Debug('%%%%% thisResult is now: ' + thisResult);
       }

        if(observerList.size() > 0)
        {
            if(thisResult != '') thisResult += ';';
            thisResult += ' OBSERVERS:';
        }
       for(String thisPerson : observerList)
       {
           System.Debug('%%%%% Processing: ' + thisPerson);
           if(thisResult != '' && !thisResult.endsWith(':')) thisResult += ',';
           thisResult += thisPerson;
           System.Debug('%%%%% thisResult is now: ' + thisResult);
       }

       //need to find the instance to update it
       for(Sales_Event__c theSev : sevs)
       {
        	if(theSev.Id == thisEvent.ID)
            {
             	theSev.List_Of_People__c = thisResult;
                break;
            }
       }
//       thisEvent.List_Of_People__c = thisResult;
                   
    }

}