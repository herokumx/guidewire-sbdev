@isTest(seeAlldata = True)
public class CS_postRequestonCaseFeedHandlerTest
{
  public static testMethod void EmailTest()
  {
   Account a = CS_TestDataUtility.createCustomerAccount();
   User u = CS_TestDataUtility.createTestUser();
   Contact c = CS_TestDataUtility.createContact(a,'General Customer');
   List<Asset> astLst = CS_TestDataUtility.createParentAssetRecord(a, true);
   
   RecordType rt1 = [Select id,name,DeveloperName from RecordType where SobjectType = 'Case' and DeveloperName = 'CS_Customer_Support'];
   
   Case ca = new Case();
   ca.recordtypeId = rt1.Id;
   ca.Severity__c = '3-Major';
   ca.CS_Urgency__c ='low';
   ca.Category__c ='Data';
   ca.Subject ='Testing case';
   ca.ContactId = c.Id;
   ca.Status = 'New';
   
   insert ca;
        
  system.runAs(new User(id= userinfo.getUserId()))
  {    
     CaseTeamRole ctr = new CaseTeamRole();
        ctr.Name = 'GW Watcher111';
        ctr.AccessLevel = 'Read';
        insert ctr;
   
   CaseTeamMember ctm = CS_TestDataUtility.createCaseTeamMember(ca.id,u.id,ctr.Id);
   
   RecordType rt = [Select id,name,DeveloperName from RecordType where SobjectType = 'CS_Request__c' and DeveloperName = 'Dev_Request'];
   
   CS_Request__c req = new CS_Request__c( recordTypeId = rt.Id,
                                         Pgm_Request_Owner__c ='BillingCenter PgM',
                                         CS_Request_Status__c ='Draft',
                                         CS_Information_Request__c ='Testing',
                                         CS_Case__c = ca.Id,
                                         CS_Request_Type__c = 'Short Term Request' );
   
   insert req;
   
   req.CS_Escalation_Note__c ='Testing the case';
   req.CS_Dev_Jira__c ='TestJira';
   req.Dev_Assignee__c = U.Id;
   
   update req;
   
   }
  
 }
   
   
}