trigger NotifyChatterGroupOfNewRequest on Sales_Support_Request__c (after insert) {

  Sales_Support_Request__c[] ssrs = Trigger.new;
    for(Sales_Support_Request__c ssr: ssrs)
    {  
        
        //determing string to announce
        String postString = null;
        String forName = '';
        if(ssr.Account__c != null)
        {
            String thisName = ssr.Account__r.Name;
            if(thisName == null)
            {
                Account thisAccount = [SELECT Id, Name from Account where Id = :ssr.Account__c LIMIT 1];
                thisName = thisAccount.Name;
            }
            postString = 'New Support Request:\n' + ssr.Type__c + ' for Account: ' + thisName;
            forName = 'Account: ' + thisName;
        }
        else if(ssr.Opportunity__c != null)
        {
            String thisName = ssr.Opportunity__r.Name;
            if(thisName == null)
            {
                Opportunity thisOpportunity = [SELECT Id, Name from Opportunity where Id = :ssr.Opportunity__c LIMIT 1];
                thisName = thisOpportunity.Name;
            }
            postString = 'New Support Request:\n' + ssr.Type__c + ' for Opportunity: ' + thisName;        
            forName = 'Opportunity: ' + thisName;
        }
        else if(ssr.Campaign__c != null)
        {
            String thisName = ssr.Campaign__r.Name;
            if(thisName == null)
            {
                Campaign thisCampaign = [SELECT Id, Name from Campaign where Id = :ssr.Campaign__c LIMIT 1];
                thisName = thisCampaign.Name;
            }
            postString = 'New Support Request:\n' + ssr.Type__c + ' for Campaign: ' + thisName ;       
            forName = 'Campaign: ' + thisName;
        }
        
        if(postString != null)
        {
            //let's see determine the due date string
            if(ssr.Requested_Completion_Date__c != null)
            {
                postString += '\nNeeded by: ' + ssr.Requested_Completion_Date__c;
            }
            else
            {
                postString += '\nNo due date specified.';            
            }
        }


        if(postString != null)
        {
            String staffingChatterGroupName = 'VC Staffing';
            CollaborationGroup staffingGroup = [SELECT Id, Name from CollaborationGroup WHERE Name = :staffingChatterGroupName LIMIT 1];
            FeedItem post2 = new FeedItem();
            post2.ParentId = staffingGroup.Id;   
            post2.Body = postString;
            post2.Title = forName +' ('+ssr.Type__c+')';
            post2.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + ssr.Id;
    
            insert post2;                
        }        

    
//        if(ssr.Requested_For__c == null) ssr.Requested_For__c = ssr.CreatedBy.Id;
    }

}