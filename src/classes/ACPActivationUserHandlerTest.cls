@isTest
public class ACPActivationUserHandlerTest
{
    static testmethod void acpActivation()
    {
       ACPactivateUser__c acpC = new ACPactivateUser__c();
       acpC.isTriggerActive__c = true;
       acpC.Name='ACPactivation';
       insert acpC;
       
       Account a = CS_TestDataUtility.createCustomerAccount();
       
       set<id> cids = new set<id>();
       Contact c = CS_TestDataUtility.createContact(a,'General Customer');
       cids.add(c.id);
       
       List<Asset> astLst = CS_TestDataUtility.createParentAssetRecord(a,true);

       Contact con = CS_TestDataUtility.createContact(a,'General Customer');    
       con.FirstName = 'Test 001';  
       update con; 
       
       CS_Asset_Contact_Permissions__c acp1 = CS_TestDataUtility.createACP(astLst[0], con,'Customer Support',false);
    
       
        Profile pfAdmin = [select Id from profile where Name = 'GW Customer Community'];
        User u = new User();
        u.FirstName=c.firstName;
        u.LastName=c.LastName;
        u.ProfileId=pfAdmin.Id;
        u.Username = 'testcommunity111@email.com';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey='UTF-8';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.Alias = 'teCus';
        U.CommunityNickname='acptest';
        u.Email = 'testcommunity@email.com';
        u.ContactId = c.Id;
        // u.PortalRole = 'Worker';
        
        Insert U;
        
        u.IsActive = true; 
        
        update u;
       
    }

}