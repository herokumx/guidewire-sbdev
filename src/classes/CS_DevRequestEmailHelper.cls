/*
*****************************************************************************************************************************
Class Name - CS_DevRequestEmailHelper
Class Type -  Helper class for Email.
Test Class-
Purpose- 

*****************************************************************************************************************************

Name        Email              Date             Notes 
hari                           9/23/2016       created it.
*****************************************************************************************************************************
*/

public with  sharing class CS_DevRequestEmailHelper
{
    public Set < String > noDuplicates = new Set < String > ();
    private static string replyToAddress='noreply@salesforce.com';
    
        
    public void SendDevRequestEmail(set<id> ReqIds, set<id> CaseIds)
    {
         Map<id, List<CaseTeamMember>> CaseteamMap = new Map<id, List<CaseTeamMember>>();
         
          List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember> ([SELECT Id, Member.Id, Member.Email, TeamRole.Name, ParentId FROM CaseTeamMember WHERE ParentId IN: caseIds
                                                                                  AND TeamRole.Name NOT IN('Customer Case Contact','Customer Support', 'Customer Support (View Only)', 'Partner') ]);
                                                                                  
           for(CaseTeamMember tm : caseTeamMembers)
           {
             if(CaseteamMap.containsKey(tm.ParentId))
             {
                List<CaseTeamMember> tLst = CaseteamMap.get(tm.ParentId);
                tLst.add(tm);
                CaseteamMap.put(tm.ParentId, tLst);
             }   
             else
             {
                List<CaseTeamMember> tLst = new List<CaseTeamMember>();
                tLst.add(tm);
                CaseteamMap.put(tm.ParentId, tLst);
             }
           }
           
           List<CS_Request__c> reqEmailLst = [Select id,name,CS_Request_Owner__c,CS_Request_Owner__r.Name,Pgm_Request_Owner__c,CS_Request_Status__c, CS_Information_Request__c, CS_Case__c, CS_Escalation_Note__c, CS_Fix_by_Version__c, CS_Customer_Commitment__c, CS_Dev_Jira__c,
                                              CS_Next_Dev_Response__c, CS_Associated_Jira__c, Dev_Assignee__c,CS_Escalation_Request_Date__c, CS_Request_Type__c, CS_Dev_Current_Status__c, CS_Request_Reason__c, Dev_Assignee_Group__c,CS_Request_Owner__r.Email,Dev_Assignee__r.Email,
                                              Case_Owner_Email__c,Dev_Assignee__r.Name,CS_Submitted_First_Time__c,CS_Case__r.Owner.Email,CS_Case_Number__c,CS_Case__r.CaseNumber from CS_Request__c where Id IN: ReqIds ];
                                              
           OrgWideEmailAddress LstOrgAddress= [SELECT id, Address FROM OrgWideEmailAddress WHERE DisplayName ='Guidewire Community'];
           Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
           
         for(CS_Request__c Req: reqEmailLst)
         {
          if(Req.CS_Submitted_First_Time__c == true)
           {
              Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
              String[] toAddresses = new String[]{}; 
              
              if(Req.CS_Request_Owner__r.Email != null)
              {
                 toAddresses.add(Req.CS_Request_Owner__r.Email);
              }
              
              if(Req.Dev_Assignee__r.Email != null)
              {
                 toAddresses.add(Req.Dev_Assignee__r.Email);
              }
              
              if(Req.CS_Case__r.Owner.Email != null)
              {
                 toAddresses.add(Req.CS_Case__r.Owner.Email);
              }
              
              if(CaseteamMap.size() >0 && CaseteamMap.get(Req.CS_Case__c).size() >0)
              {
               for (CaseTeamMember member: CaseteamMap.get(Req.CS_Case__c))
               {
                    system.debug('member email==' + member.member.email +' Team Role==' + member.TeamRole.Name + 'Dup Check==' + noDuplicates);
                    
                    if(member.Member.Email != null && isNewAddress(member.Member.Email) )
                    {
                       if (member.TeamRole.Name == 'GW Watcher') 
                        {
                            toAddresses.add(member.Member.Email);
                        }
                        if (member.TeamRole.Name == 'Follow the Sun')
                        {
                            toAddresses.add(member.Member.Email);
                        }
                        if (member.TeamRole.Name == 'Leads')
                        {
                            toAddresses.add(member.Member.Email);
                        }
                        if (member.TeamRole.Name == 'Collaborator') 
                        {
                            toAddresses.add(member.Member.Email);
                        }
                    }
                }
               } 
               
               mail.setToAddresses(toAddresses);       
               mail.setSubject('Fields updated for the following Dev Request - '+ Req.Name);
               mail.setReplyTo(replyToAddress);
               
               if(LstOrgAddress!=null)
               {
                 mail.setOrgWideEmailAddressId(LstOrgAddress.id);
               } 
               string table ='Hello,';
                            table = table +'<br>';
                            table = table +'<br>';
                            table = table + 'There is an update for some of the fields on the below Dev Request.';
                            table = table +'<br>';
                            table = table +'<br>';
                            table = table + '<b>Request Owner :</b>' + Req.CS_Request_Owner__r.Name + '<br>';
                            table = table + '<b>Pgm Request Owner :</b>' + Req.Pgm_Request_Owner__c + '<br>';
                            table = table + '<b>Request Status :</b>' + Req.CS_Request_Status__c + '<br>';
                            table = table + '<b>Request Date :</b>' + Req.CS_Escalation_Request_Date__c +'<br>';
                            table = table + '<b>Information Request :</b>' + Req.CS_Information_Request__c +'<br>';
                            table = table + '<b>Case :</b>' + Req.CS_Case_Number__c +'<br>';
                            table = table + '<b>Case Summary :</b>' + Req.CS_Escalation_Note__c +'<br>';
                            table = table + '<b>Requested Fix Version :</b>' + Req.CS_Fix_by_Version__c +'<br>';
                            table = table + '<b>Customer Commitment :</b>' + Req.CS_Customer_Commitment__c +'<br>';
                            table = table + '<b>Dev Jira :</b>' + Req.CS_Dev_Jira__c +'<br>';
                            table = table + '<b>Associated Jira :</b>' + Req.CS_Associated_Jira__c +'<br>';
                            table = table + '<b>Request Type :</b>' + Req.CS_Request_Type__c +'<br>';
                            table = table + '<b>Request Reason :</b>' + Req.CS_Request_Reason__c +'<br>';
                            table = table + '<b>Next Response Date :</b>' + Req.CS_Next_Dev_Response__c +'<br>';
                            table = table + '<b>Dev Assignee :</b>' + Req.Dev_Assignee__r.Name +'<br>';
                            table = table + '<b>Dev Current Status :</b>' + Req.CS_Dev_Current_Status__c +'<br>';
                            table = table + '<b>Dev Assignee Group :</b>' + Req.Dev_Assignee_Group__c +'<br>';
                            table = table +'<br>';
                            table = table +'<br>';
                            table = table +'<br>';
                            table = table + 'Here is the link to the Dev Request :';
                            table = table + '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+Req.id+'"><b>'+Req.Name+'</b></a>';
                            
                      mail.setHtmlBody(Table);
                      emailMessageList.add(mail);
              }
           }
              Messaging.sendEmail(emailMessageList);
      }
      
       public Boolean isNewAddress(String inAddress) 
       {
        Boolean bool = false;
        Integer initialCount = noDuplicates.size();
        noDuplicates.add(inAddress);
        if(noDuplicates.size()>initialCount)
        {
            bool = true;
        } 
        else
        {
            bool = false;
        }
        return bool;
       }

}