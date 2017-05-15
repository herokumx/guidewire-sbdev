public class UpdateApproversHandler
{
    public static boolean flag = true;
    
    public void InsertRequesters(set<id> oppids)
    {
       boolean updateflag = false; 
        
       list<opportunity> opptoupdate = new list<opportunity>();
        
       list<opportunity> opplst = [select id, InsuranceSuite_Approved__c, Insurance_Suite_Approved_PMM__c, 
                                              Data_Management_Approved__c, Data_Management_Approved_PMM__c, 
                                              Mobile_Portals_Approved__c, Mobile_Portals_Approved_PMM__c, 
                                              Standards_based_Templates_Approved__c, Standards_based_Templates_Approved_PMM__c, 
                                              Live_Approved__c, Live_Approved_PPM__c,  
                                            //  Standard_Reporting_Approved_PM__c, Standard_Reporting_Approved_PMM__c,
                                              Request_Insurance_Suite_Approval__c, Request_Data_Management_Approval__c,
                                              Request_Mobile_Portals_Approval__c, Request_Standards_based_Approval__c,
                                              Request_Live_Approval__c // Request_Standard_Reporting_Approval__c                                              
                                    from opportunity where id IN :oppids];
        
        for(opportunity opp : opplst)
        {
            if(opp.Request_Insurance_Suite_Approval__c == true)
           {
             //  opp.Requester_InsuranceSuite__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if(opp.Request_Data_Management_Approval__c == true)
           {
            //   opp.Requester_DM__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if( opp.Request_Mobile_Portals_Approval__c == true)
           {
             //  opp.Requester_MP__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if( opp.Request_Standards_based_Approval__c == true)
           {
             //  opp.Requester_SBT__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if( opp.Request_Live_Approval__c == true)
           {
            //   opp.Requester_Live__c = userinfo.getUserId();
               updateflag=true;
           }
            
       /*     if( opp.Request_Standard_Reporting_Approval__c == true)
           {
               opp.Requester_Standard_Reporting__c = userinfo.getUserId();
               updateflag=true;
           }
       */              
            opptoupdate.add(opp);
  
        }
        if(updateflag)
       {
        flag=false;
        update opptoupdate;
       }
    }
    
    
    public void ApproversMethod(map<id, Opportunity> oldmap, set<id> oppids)
    {
        boolean updateflag = false;
        
       list<opportunity> opptoupdate = new list<opportunity>();
   
       list<opportunity> opplst = [select id, InsuranceSuite_Approved__c, Insurance_Suite_Approved_PMM__c, 
                                              Data_Management_Approved__c, Data_Management_Approved_PMM__c, 
                                              Mobile_Portals_Approved__c, Mobile_Portals_Approved_PMM__c, 
                                              Standards_based_Templates_Approved__c, Standards_based_Templates_Approved_PMM__c, 
                                              Live_Approved__c, Live_Approved_PPM__c,  
                                             // Standard_Reporting_Approved_PM__c, Standard_Reporting_Approved_PMM__c,
                                              Request_Insurance_Suite_Approval__c, Request_Data_Management_Approval__c,
                                              Request_Mobile_Portals_Approval__c, Request_Standards_based_Approval__c,
                                              Request_Live_Approval__c //Request_Standard_Reporting_Approval__c                                              
                                    from opportunity where id IN :oppids];
   
       for(opportunity opp : opplst)
        {
            opportunity oldopp = oldmap.get(opp.id);
            
           if(oldopp.InsuranceSuite_Approved__c==false && opp.InsuranceSuite_Approved__c == true)
            {
            //   opp.PM_Approver_InsuranceSuite__c = userinfo.getUserId();
               opp.PM_Approval_Date_InsuranceSuite__c = date.today();
                updateflag=true;
            }  
                        
           if(oldopp.Data_Management_Approved__c==false && opp.Data_Management_Approved__c == true)
            {
            //   opp.PM_Approver_DM__c = userinfo.getUserId();
               opp.PM_Approval_Date_DM__c = date.today();
                updateflag=true;
            }
                          
           if(oldopp.Mobile_Portals_Approved__c==false && opp.Mobile_Portals_Approved__c == true)
            {
             // opp.PM_Approver_MP__c = userinfo.getUserId();
              opp.PM_Approval_Date_MP__c = date.today();
              updateflag=true;
            }   
                                    
           if(oldopp.Standards_based_Templates_Approved__c==false && opp.Standards_based_Templates_Approved__c == true)
            {
             // opp.PM_Approver_SBP__c = userinfo.getUserId();
              opp.PM_Approval_Date_SBP__c = date.today();
                updateflag=true;
            }  
                                   
           if(oldopp.Live_Approved__c==false && opp.Live_Approved__c == true)
            {
             // opp.PM_Approver_Live__c = userinfo.getUserId();
              opp.PM_Approval_Date_Live__c = date.today();
              updateflag=true;               
            } 
            
         /*   if(oldopp.Standard_Reporting_Approved_PM__c==false && opp.Standard_Reporting_Approved_PM__c==true)
            {
              opp.PM_Approver_Standard_Reporting__c = userinfo.getUserId();
              opp.PM_Approval_Date_Standard_Reporting__c = date.today();
              updateflag=true;               
            } 
         */   
                       
           if(oldopp.Insurance_Suite_Approved_PMM__c==false && opp.Insurance_Suite_Approved_PMM__c == true)
            {
           //   opp.PMM_Approver_InsuranceSuite__c = userinfo.getUserId();
              opp.PMM_Approval_Date_InsuranceSuite__c = date.today(); 
              updateflag=true;  
            } 
                                 
           if(oldopp.Data_Management_Approved_PMM__c==false && opp.Data_Management_Approved_PMM__c == true)
            {
             // opp.PMM_Approver_DM__c = userinfo.getUserId();
              opp.PMM_Approval_Date_DM__c = date.today();
              updateflag=true;
            }  
                                  
           if(oldopp.Mobile_Portals_Approved_PMM__c==false && opp.Mobile_Portals_Approved_PMM__c == true)
            {
             // opp.PMM_Approver_MP__c = userinfo.getUserId();
              opp.PMM_Approval_Date_MP__c = date.today();
              updateflag=true;
            }   
                                 
           if(oldopp.Standards_based_Templates_Approved_PMM__c==false && opp.Standards_based_Templates_Approved_PMM__c == true)
            {
              //opp.PMM_Approver_SBP__c = userinfo.getUserId();
              opp.PMM_Approval_Date_SBP__c = date.today();
                updateflag=true;
            }   
                                   
           if(oldopp.Live_Approved_PPM__c==false && opp.Live_Approved_PPM__c == true)
            {
             // opp.PMM_Approver_Live__c = userinfo.getUserId();
              opp.PMM_Approval_Date_Live__c = date.today();
               updateflag=true; 
            } 
            
       /*     if(oldopp.Standard_Reporting_Approved_PMM__c==false && opp.Standard_Reporting_Approved_PMM__c==true)
            {
              opp.PMM_Approver_Standard_Reporting__c = userinfo.getUserId();
              opp.PMM_Approval_Date_Standard_Reporting__c = date.today();
              updateflag=true;               
            }               
        */    
           if(oldopp.Request_Insurance_Suite_Approval__c == false && opp.Request_Insurance_Suite_Approval__c == true)
           {
              // opp.Requester_InsuranceSuite__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if(oldopp.Request_Data_Management_Approval__c == false && opp.Request_Data_Management_Approval__c == true)
           {
              // opp.Requester_DM__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if(oldopp.Request_Mobile_Portals_Approval__c == false && opp.Request_Mobile_Portals_Approval__c == true)
           {
              // opp.Requester_MP__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if(oldopp.Request_Standards_based_Approval__c == false && opp.Request_Standards_based_Approval__c == true)
           {
             //  opp.Requester_SBT__c = userinfo.getUserId();
               updateflag=true;
           }
            
            if(oldopp.Request_Live_Approval__c == false && opp.Request_Live_Approval__c == true)
           {
              // opp.Requester_Live__c = userinfo.getUserId();
               updateflag=true;
           }
            
      /*      if(oldopp.Request_Standard_Reporting_Approval__c == false && opp.Request_Standard_Reporting_Approval__c == true)
           {
               opp.Requester_Standard_Reporting__c = userinfo.getUserId();
               updateflag=true;
           }
       */              
            opptoupdate.add(opp);
  
        }
  
        if(updateflag)
       {
        flag=false;
        update opptoupdate;
       }
    }
}