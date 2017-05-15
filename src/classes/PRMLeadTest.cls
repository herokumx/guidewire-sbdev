@isTest
class PRMLeadTest
{
   
    
     static testMethod void testPRMLead()
    {
        
        
       List<Profile> lstProfile =[Select Id from Profile
                                    where profile.userlicense.name = 'Partner Community'];
       
       list<UserRole> lsturole = [select id from UserRole where name='Mitchell Partner Test Account Partner User'];  
        
       
               
        List<RecordType> lstRecordType = [Select Id from RecordType where Name ='Partner'];
        List<RecordType> lstPartnerOpptyRT = [Select Id from RecordType where Name ='Master Lead'];
       
        Account objAccount = New Account(name='TestProduct',Products_Purchased__c= 'BillingCenter');
        objAccount.RecordTypeId =lstRecordType[0].Id;
        insert objAccount; 
        
         
       
        Contact contact = new Contact();
        contact.LastName = 'testContact';
        contact.AccountId = objAccount.Id;
        contact.Category__c = 'Billing';
        insert contact;
       
    /*    User user = new User(alias = 'standt', email='stauserNw@testorg.com',
        emailencodingkey='UTF-8',state='gh', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = lstProfile[0].Id,  userroleid=lsturole[0].id, portalrole='manager',  
        timezonesidkey='America/Los_Angeles', username='stanuser@testRaksorg.com',
        ContactId = contact.Id );   


       
       User usr=[select id,name from user where id=:userinfo.getUserId()];
        system.runAs(usr)
        {
          
          insert user;
            objaccount.OwnerId = user.id;
           update objaccount;
            
        }  

  */
        
      //  list<user> ulst = [select id,name from user where profileid =: lstProfile[0].id and isactive=true ]; 
        
        list<user> ulst = [select id,name from user where profile.userlicense.name = 'Partner Community' and isactive=true ];
        
        
        system.runAs(ulst[0])
        {
            

            Lead lead = new Lead();
            lead.LastName = 'testLast';
            lead.Company = 'testCompany';
            lead.Industry = 'TPA';
            lead.Status = 'Open';
            lead.LeadSource = 'Direct Mail';
            lead.PRM_Partner_Account_Exec__c = 'testA';
            lead.PRM_Partner_Account_Exec_s_Email__c = 'partner@TEST1.COM';
            //lead.CurrencyIsoCode = 'USD - U.S. Dollar';
            insert lead;
        } 
    }  
        
}