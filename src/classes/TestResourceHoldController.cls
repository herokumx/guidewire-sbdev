@isTest(seeAllData=true)
private class TestResourceHoldController
{
    static testmethod void ValidateResourceHoldController()
    {
       Opportunity opp = new Opportunity (StageName='Prospecting', 
                                         CloseDate=system.today(),
                                         Name='Test Opportinity',
                                         Premium_In_Scope__c =1000.00,
                                         Amount=2000.00);
       
       insert opp;
        
        ResourceRequest__c resreq = new ResourceRequest__c(name='test001',
                                                           Event_Hours__c=4,
                                                          Opportunity__c= opp.Id);
        
        insert resreq;
        
        Resource_Hold__c resourceHold = new Resource_Hold__c(name='test1',
                                                     Resource_Request__c= resreq.id,
                                                     Who__c = UserInfo.getUserId() );
        
        insert resourceHold;
        
        Resource_Role__c resro = new Resource_Role__c(note__c='test2',
                                                     Resource_Request__c= resreq.id);
        
        insert resro;
        
        Resource_Assignment__c resass = new Resource_Assignment__c(name='har', 
                                                                   note__c='test2',
                                                                  Resource_Request__c= resreq.id,
                                                                  Resource_Role__c= resro.id);
        
        insert resass;
        
        Possible_Date__c poda = new Possible_Date__c(name='test',
                                                     Resource_Request__c= resreq.id,
                                                    end_date__c=date.today()+1,
                                                    start_date__c=date.today(),
                                                    event_hours__c=5);
        insert poda;
                                                    
        
        Resource_Availability__c resava = new Resource_Availability__c(name='test3',
                                                                      Resource_Assignment__c=resass.id,
                                                                      Possible_Date__c=poda.id);
        
        insert resava;
        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(resourceHold);
        ApexPages.currentPage().getParameters().put('ResReqID', resreq.Id);  
        
        ResourceHoldController theNewController = new ResourceHoldController (controller);
        
        ApexPages.currentPage().getParameters().remove('ResReqID');
        
        ApexPages.currentPage().getParameters().put('id', resourcehold.Id);
        
        ResourceHoldController theOldController = new ResourceHoldController (controller);
        
        theNewController.resourceHold.Resource_Request__c= resreq.id;
        
        
         theNewController.save();
         theOldController.save();        
                
           
    }

}