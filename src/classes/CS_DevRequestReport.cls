/*
    *****************************************************************************************************************************
    Class Name - CS_DevRequestReport
    Class Type - Class to support VF Page CS_DevRequestReport 
    Test Class- CS_DevRequestReportTes
    Purpose- 
    
    *****************************************************************************************************************************
    
    Name        Email              Date             Notes 
    Suchitra                                        Initial Creation
    
    *****************************************************************************************************************************
 */

public class CS_DevRequestReport{

    public PageReference sendDates() {
        return null;
      }   
    public Date endDate { get; set; }
    public Date startDate { get; set; }

  
    public PageReference processRequests() {
        
        return null;
    }
     
    public List<wrapCasewithDevRequest> caseList{
            
                get {
                
                if (startDate != Null && endDate != Null){
                List<wrapCasewithDevRequest> lstWrapCase = new List<wrapCasewithDevRequest>();
                if (caseList== null) {
                String[] ownerTeamlist = new String[]{'Enablement Queue','Enablement-CE','Enablement-SE'};
                //Get the list of cases. 
                List<case> caseData = [Select  
                                            ID, 
                                            CaseNumber,
                                            Owner.Id,
                                            LastModifiedDate, 
                                            Owner.Name, 
                                            CS_Support_Group__c,
                                            Severity__c,
                                            Contact.Id,
                                            CS_Owner_Team__c,
                                            Contact.Name,
                                            Subject, 
                                            OwnerID, 
                                            Asset.ParentID,
                                            Asset.ID, 
                                            Asset.Name,
                                            Asset.Product2.Name,
                                            CreatedDate,
                                            ClosedDate,
                                            Status,
                                            CS_Disposition__c,
                                            CS_Platform_Issue__c,
                                            Working_Days__c,
                                            CS_Associated_Jira__c,
                                            Contact.Account.Name, 
                                            Contact.Account.RecordType.Name,
                                            Asset.Parent.Name, 
                                            Asset.Parent.Product2.Name, 
                                            Asset.CS_Primary_Supp_Partner__r.email, 
                                            Asset.CS_Primary_Supp_Partner__r.CS_User_Team__c,
                                            Asset.CS_Primary_Supp_Partner__r.Name,  
                                            Asset.CS_Pri_Supp_Org__c,
                    (SELECT Id,RecordType.Name,CreatedDate FROM Requests__r Where RecordType.Name ='Dev Request' OR RecordType.Name ='Enablement Request') FROM CASE WHERE ((ClosedDate >=:startDate OR ClosedDate =NULL) AND CreatedDate<=:endDate) AND (RecordType.Name=:'Customer Support' AND CS_ODC__c =:false ) AND  CS_Owner_Team__c in:ownerTeamlist AND CS_Submitted_as_KB_Article__c=:false ORDER BY CreatedDate ASC LIMIT 10000];
                    for (case caseRec:caseData){
                                  
                    
                     List<CS_Request__c> csRequestList = caseRec.Requests__r;
                     integer csDevRequestSize = 0;
                     integer csEnableRequestSize = 0;
                     
                     //If the Case has case team members, parse through and build the tags. 
                     if (csRequestList != NULL){
                         for (CS_Request__c csReq:csRequestList )
                          if (csReq.RecordType.Name == 'Dev Request'){
                             if (csReq.CreatedDate>=startDate && csReq.CreatedDate<=endDate)
                             {
                             csDevRequestSize ++;
                             }
                         }
                         else if (csReq.RecordType.Name == 'Enablement Request'){
                             csEnableRequestSize ++;
                         }
                      }
                      String closedateFormated = '';
                      boolean isEnablementReq = false; 
                      if (csEnableRequestSize >0){
                          isEnablementReq = true;
                      }
                      if ( caseRec.ClosedDate != NULL){
                          closedateFormated = caseRec.ClosedDate.format();
                      }
                      boolean isPartnerOrganization = false;
                      if (caseRec.Asset.CS_Primary_Supp_Partner__r != NULL){
                          if (!caseRec.Asset.CS_Primary_Supp_Partner__r.email.contains('guidewire.com')){
                          isPartnerOrganization =true;}
                      }
                     
                      wrapCasewithDevRequest wrapCase1 = new wrapCasewithDevRequest(caseRec,csDevRequestSize,isEnablementReq, caseRec.CreatedDate.format(),closedateFormated,isPartnerOrganization );
                      lstWrapCase.add(wrapCase1);
                   
                }
               }
           return lstWrapCase ;
        }
        return null;
        }
        set;
    }
      

         public class wrapCasewithDevRequest {
    
            public case caseRecord {get; set;}
            public integer countDevReq {get;set;}
            public boolean isEnableReq  {get;set;}
            public String createdDateFormated{get;set;}
            public String caseClosedDateFormated{get;set;}
            public boolean isPartnerCase  {get;set;}
     
            public wrapCasewithDevRequest (Case caseRecord, integer countDevReq, boolean countEnableReq,String createdDateFormated, String caseClosedDateFormated, boolean isPartnerCase) {
                this.caseRecord = caseRecord;
                this.countDevReq = countDevReq;
                this.isEnableReq = countEnableReq;
                
                this.createdDateFormated = createdDateFormated;
                this.caseClosedDateFormated= caseClosedDateFormated;
                this.isPartnerCase = isPartnerCase;
               
            }
        }
       
    }