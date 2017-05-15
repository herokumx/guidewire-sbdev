@istest
private class TestUpdateApproversHandler 
{
    static testmethod void ApproversTest()
    {
       
        opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500,
                                           Premium_In_Scope__c = 100,
                                          InsuranceSuite_Approved__c = false, Insurance_Suite_Approved_PMM__c = false, 
                                          Data_Management_Approved__c = false, Data_Management_Approved_PMM__c = false,
                                          Mobile_Portals_Approved__c = false, Mobile_Portals_Approved_PMM__c = false,
                                          Standards_based_Templates_Approved__c = false, Standards_based_Templates_Approved_PMM__c = false,
                                          Live_Approved__c = false, Live_Approved_PPM__c = false,
                                         // Standard_Reporting_Approved_PM__c = false, Standard_Reporting_Approved_PMM__c = false, 
                                          Request_Live_Approval__c = false, Request_Insurance_Suite_Approval__c = false,
                                          Request_Data_Management_Approval__c = false, Request_Mobile_Portals_Approval__c = false,
                                          Request_Standards_based_Approval__c = false); //Request_Standard_Reporting_Approval__c=false);
                                          
        
        insert opp;
        
        opp.InsuranceSuite_Approved__c = true;
        opp.Insurance_Suite_Approved_PMM__c = true; 
        opp.Data_Management_Approved__c = true;
        opp.Data_Management_Approved_PMM__c = true;
        opp.Mobile_Portals_Approved__c = true;
        opp.Mobile_Portals_Approved_PMM__c = true;
        opp.Standards_based_Templates_Approved__c = true;
        opp.Standards_based_Templates_Approved_PMM__c = true;
        opp.Live_Approved__c = true;
        opp.Live_Approved_PPM__c = true;
      //  opp.Standard_Reporting_Approved_PM__c = true;
     //   opp.Standard_Reporting_Approved_PMM__c = true;
        opp.Request_Live_Approval__c = true;
        opp.Request_Insurance_Suite_Approval__c = true;
        opp.Request_Data_Management_Approval__c = true;
        opp.Request_Mobile_Portals_Approval__c = true;
        opp.Request_Standards_based_Approval__c = true;
      //  opp.Request_Standard_Reporting_Approval__c=true;
      
              
        update opp;
      }        
    }