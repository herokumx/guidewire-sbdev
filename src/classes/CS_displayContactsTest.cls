@isTest(seeAllData = true)
public class CS_displayContactsTest 
{
    static testMethod void validateController()
    {
       pw_cc__State__c stat = [select id,name,pw_cc__Country__c,pw_cc__Country__r.name,pw_cc__IsoCode__c from pw_cc__State__c 
                                where Name like 'California%' limit 1];
       Recordtype Reqtype = [select id,name,DeveloperName from Recordtype where SObjectType ='Community_Access_Request__c' and 
                             DeveloperName ='New_Account_Request' limit 1];
       Recordtype Contype = [select id,name,DeveloperName from Recordtype where SObjectType ='Contact' and 
                             DeveloperName ='Support' limit 1];
       Recordtype Acctype = [select id,name,DeveloperName from Recordtype where SObjectType ='Account' and 
                             DeveloperName ='Customer' limit 1];
        
      Account acc= new account();
       acc.Name = 'Test4567';
       acc.Type = 'Analyst';
       acc.Buying_Entity__c = 'No';
       acc.CurrencyIsoCode = 'USD';
       acc.Industry='Analyst';
       acc.BillingCountry = 'India1';
       acc.Record_Status__c ='Active';
       acc.RecordTypeId = Acctype.Id;
        
      insert acc;  
       
       Community_Access_Request__c AcReq = new Community_Access_Request__c();
        acReq.Account__c = acc.Id;
        acReq.First_Name__c ='hari1';
        acReq.Last_Name__c = 'test1';
        acReq.Title__c ='Developer';
        acReq.Email__c ='hari@gmail.com';
        acReq.Phone__c = '2346785640';
        acReq.Mailing_State__c = stat.Id;
        acReq.Mailing_Country__c = stat.pw_cc__Country__c;
        acReq.Data_Management__c = true;
        acReq.Data_Management_Access__c ='Customer Support';
        acReq.RecordTypeId = Reqtype.Id;
        
        insert AcReq;
        
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.firstname = 'test1';
        con.LastName ='har';
        con.Email = 'hari@gmail.com';
        con.CS_Access_Type__c ='Customer Support';
        con.RecordTypeId = conType.Id;  
        
        insert con;
        
        
        PageReference pref = Page.CS_ContactsDisplay;
        pref.getParameters().put('id', acReq.id);
        Test.setCurrentPage(pref);

       ApexPages.StandardController sc = new ApexPages.StandardController(acReq);

       CS_displayContacts disCon = new CS_displayContacts(sc);
       PageReference result = disCon.ContactsList();
       PageReference result1 = disCon.viewCon(); 
        
      // System.assertNotEquals(null,result);
      // System.assertNotEquals(null,result1);
    }
}