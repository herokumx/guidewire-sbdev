public with sharing class SWOTController {

 public ApexPages.StandardController stdCtrl {get; set;}
 public Boolean refreshPage {get; set;}
 public Opportunity origOpportunity {get; set;}
  
  
    public SWOTController(ApexPages.StandardController controller) {
          stdCtrl=controller;
          refreshPage=false;
          
          Opportunity currentOpp = (Opportunity)stdCtrl.getRecord();
          
          
          //let's store the current SWOT values so we can check them when we try to save
          origOpportunity = [SELECT Id, SWOT_Strategy_WT__c, SWOT_Strategy_WO__c, SWOT_Weaknesses__c, SWOT_Opportunities__c, 
                                         SWOT_Threats__c, SWOT_Strategy_ST__c, SWOT_Strategy_SO__c, SWOT_Strengths__c from Opportunity where Id = :currentOpp.Id LIMIT 1];          
          
    }


    public Boolean saveIfOk()
    {
        //
          Opportunity currentOpp = (Opportunity)stdCtrl.getRecord();
           Opportunity currentOpportunityInDB = [SELECT Id, SWOT_Strategy_WT__c, SWOT_Strategy_WO__c, SWOT_Weaknesses__c, SWOT_Opportunities__c, 
                                         SWOT_Threats__c, SWOT_Strategy_ST__c, SWOT_Strategy_SO__c, SWOT_Strengths__c from Opportunity where Id = :currentOpp.Id LIMIT 1];          
        
        
          //now check the DB values versus what we started with on origOpportunity
          Boolean saveOk = (origOpportunity.SWOT_Strategy_WT__c == currentOpportunityInDB.SWOT_Strategy_WT__c &&
             origOpportunity.SWOT_Opportunities__c == currentOpportunityInDB.SWOT_Opportunities__c &&
             origOpportunity.SWOT_Strategy_WO__c == currentOpportunityInDB.SWOT_Strategy_WO__c &&
             origOpportunity.SWOT_Weaknesses__c == currentOpportunityInDB.SWOT_Weaknesses__c &&
             origOpportunity.SWOT_Threats__c == currentOpportunityInDB.SWOT_Threats__c &&
             origOpportunity.SWOT_Strategy_ST__c == currentOpportunityInDB.SWOT_Strategy_ST__c &&
             origOpportunity.SWOT_Strategy_SO__c == currentOpportunityInDB.SWOT_Strategy_SO__c &&
             origOpportunity.SWOT_Strengths__c == currentOpportunityInDB.SWOT_Strengths__c);
             
        
        if(saveOk )
        {
            stdCtrl.save(); 
            origOpportunity = [SELECT Id, SWOT_Strategy_WT__c, SWOT_Strategy_WO__c, SWOT_Weaknesses__c, SWOT_Opportunities__c, 
                                         SWOT_Threats__c, SWOT_Strategy_ST__c, SWOT_Strategy_SO__c, SWOT_Strengths__c from Opportunity where Id = :currentOpp.Id LIMIT 1]; 
        }
        else
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'The SWOT has been modified since you loaded the page.  Please copy your changes to Word, reload this page, and then merge your changes back into the latest version of the SWOT.'));      
    
        return saveOk ;
    }

    public PageReference quicksave()
     {
          refreshPage=true;
          
          Boolean result = saveIfOk();
                 
          return null;
     }

    public PageReference save()
     {
         Boolean result = saveIfOk();

          //stdCtrl.save();
          if(result) return cancel();     
          else return null;
        
        /*
        PageReference reqPage = stdCtrl.view();
        
        reqPage.setRedirect(true);
        return reqPage ;
            */
     }

    public PageReference cancel()
     {
     
        PageReference reqPage = stdCtrl.view();
        
        reqPage.setRedirect(true);
        return reqPage ;
            
     }

}