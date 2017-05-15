public class RFIRFPApprovalHandler
{
    public static boolean flag = true;
    
    public void SCSDRequested(set<id> Oppids, Map<id,Opportunity> OldMap) 
    {
        Boolean updateflag = false;
         
        List<Opportunity> OppLst = [select id,name,region__c, Services_Director__c,Services_Director__r.email,OwnerId,Owner.email,owner.name,Account.name, RFI_Approval_SC__c,RFI_Approval_SD__c,RFP_Approval_SC__c,RFP_Approval_SD__c
                                from Opportunity where Id IN: Oppids];
        
        List<opportunity> newoppLst = new list<Opportunity>();
        List<opportunity> oldOppLst = new list<Opportunity>();
      
        for(Opportunity opp : OppLst)
        {     
                
            if(opp.RFI_Approval_SC__c != OldMap.get(opp.Id).RFI_Approval_SC__c && (opp.RFI_Approval_SC__c =='Approved' || opp.RFI_Approval_SC__c =='Denied'))
             {     
                opp.RFI_Approved_Denied_SC__c = userinfo.getUserId();
                updateflag = true;
             }
            
            
            if(opp.RFI_Approval_SD__c != OldMap.get(opp.Id).RFI_Approval_SD__c && (opp.RFI_Approval_SD__c =='Approved' || opp.RFI_Approval_SD__c =='Denied'))
              {
                 opp.RFI_Approved_Denied_SD__c = userinfo.getUserId();
                   updateflag = true;
              }
            
          
             if(opp.RFP_Approval_SC__c != OldMap.get(opp.Id).RFP_Approval_SC__c && (opp.RFP_Approval_SC__c =='Approved' || opp.RFP_Approval_SC__c =='Denied'))
              {
                  opp.RFP_Approved_Denied_SC__c = userinfo.getUserId();
                    updateflag = true;
              }
            
           
             if(opp.RFP_Approval_SD__c != OldMap.get(opp.Id).RFP_Approval_SD__c && (opp.RFP_Approval_SD__c =='Approved' || opp.RFP_Approval_SD__c =='Denied'))
              {
                  opp.RFP_Approved_Denied_SD__c = userinfo.getUserId();
                    updateflag = true;
              }            
           
          newoppLst.add(opp);
            
        }
        
        if(updateFlag)
        {
          flag = false;
          update newOppLst;
          SendEmail(newoppLst, OldMap);
        }    
    }
    
     public void SendEmail(List<Opportunity> NewOpps, Map<id,Opportunity> OldOppMap)
     {
         Map<string,RFI_RFP_Emails__c> customMap = RFI_RFP_Emails__c.getAll();
         system.debug('map values :'+ customMap);
         Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
             
         for(Opportunity Opp: NewOpps)
         {
            Opportunity oldOpp = OldOppMap.get(opp.id);
             
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
             
             String[] toAdd = new String[]{};
                 
             if(opp.Services_Director__c != Null)
              {
                 string sdEmail = opp.Services_Director__r.email; 
                 system.debug('service Direc'+sdEmail);
                 toAdd.add(sdemail);                  
              }
                       
             toAdd.add(opp.Owner.email); 
             
             if(opp.Region__c =='EMEA')
             {             
             string DirectorofSC = customMap.get('EMEA - Director of SC').email__c;
             string EmeaSalesOps = customMap.get('EMEA - Sales Ops').email__c;
             toAdd.add(DirectorofSC);
             toAdd.add(EmeaSalesOps); 
             
             if(opp.RFI_Approval_SC__c == 'Approved' || opp.RFI_Approval_SD__c == 'Approved' || opp.RFP_Approval_SC__c == 'Approved' || opp.RFP_Approval_SD__c == 'Approved'
                || opp.RFI_Approval_SC__c == 'Denied' || opp.RFI_Approval_SD__c == 'Denied' || opp.RFP_Approval_SC__c == 'Denied' || opp.RFP_Approval_SD__c == 'Denied')
             {
                 string VP = customMap.get('EMEA - VP').email__c;
                 toAdd.add(VP);
             } 
             } 
             
             if(opp.Region__c =='AMER')
             {             
             string DirectorofSC = customMap.get('AMER - Director of SC').email__c;
             string EmeaSalesOps = customMap.get('AMER - Sales Ops').email__c;
             toAdd.add(DirectorofSC);
             toAdd.add(EmeaSalesOps); 
             
             if(opp.RFI_Approval_SC__c == 'Approved' || opp.RFI_Approval_SD__c == 'Approved' || opp.RFP_Approval_SC__c == 'Approved' || opp.RFP_Approval_SD__c == 'Approved'
                || opp.RFI_Approval_SC__c == 'Denied' || opp.RFI_Approval_SD__c == 'Denied' || opp.RFP_Approval_SC__c == 'Denied' || opp.RFP_Approval_SD__c == 'Denied')
             {
                 string VP = customMap.get('AMER - VP').email__c;
                 toAdd.add(VP);
             } 
             }   
             
             if(opp.Region__c =='APAC')
             {             
             string DirectorofSC = customMap.get('APAC - Director of SC').email__c;
             string EmeaSalesOps = customMap.get('APAC - Sales Ops').email__c;
             toAdd.add(DirectorofSC);
             toAdd.add(EmeaSalesOps); 
             
             if(opp.RFI_Approval_SC__c == 'Approved' || opp.RFI_Approval_SD__c == 'Approved' || opp.RFP_Approval_SC__c == 'Approved' || opp.RFP_Approval_SD__c == 'Approved'
                || opp.RFI_Approval_SC__c == 'Denied' || opp.RFI_Approval_SD__c == 'Denied' || opp.RFP_Approval_SC__c == 'Denied' || opp.RFP_Approval_SD__c == 'Denied')
             {
                 string VP = customMap.get('APAC - VP').email__c;
                 toAdd.add(VP);
             } 
             } 
             
             if((oldOpp.RFI_Approval_SC__c !=opp.RFI_Approval_SC__c) && opp.RFI_Approval_SC__c == 'Approved')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFI Approval');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been approved by Sales Consulting. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFI_Approval_SC__c !=opp.RFI_Approval_SC__c) && opp.RFI_Approval_SC__c == 'Denied')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFI Denial');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been declined by Sales Consulting. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFI_Approval_SD__c != opp.RFI_Approval_SD__c) && opp.RFI_Approval_SD__c == 'Approved')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFI Approval');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been approved by Sales Management. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFI_Approval_SD__c != opp.RFI_Approval_SD__c) &&  opp.RFI_Approval_SD__c == 'Denied')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFI Denial');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been declined by Sales Management. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFP_Approval_SC__c != opp.RFP_Approval_SC__c) && opp.RFP_Approval_SC__c == 'Approved' )
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFP Approval');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been approved by Sales Consulting. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFP_Approval_SC__c != opp.RFP_Approval_SC__c) &&  opp.RFP_Approval_SC__c == 'Denied')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFP Denial');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been declined by Sales Consulting. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFP_Approval_SD__c != opp.RFP_Approval_SD__c) && opp.RFP_Approval_SD__c == 'Approved' )
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFP Approval');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been approved by Sales Management. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
             
             if((oldOpp.RFP_Approval_SD__c != opp.RFP_Approval_SD__c) && opp.RFP_Approval_SD__c == 'Denied')
             {
             
               mail.setToAddresses(toAdd);                      
               mail.setSubject(opp.name +', RFP Denial');             
               mail.setHtmlBody('The Opportunity titled <b>'+ Opp.name +'</b> owned by <b>' +Opp.Owner.Name+'</b> from Account <b>'+opp.Account.name+'</b> has been declined by Sales Management. <br> <br> Please click on the link below to view the opportunity <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Opp.id+'">'+opp.Name+'</a> <br> <br> Thank You.' );
               
             emailMessageList.add(mail); 
             }
         }
         
         Messaging.sendEmail(emailMessageList);
     }
}