@isTest
private class AccountTgrHandlerTest
{
    static testMethod void testAccountTgrHandler()
    {
        List<Profile> lstProfile =[Select Id from Profile 
                                    where profile.userlicense.name = 'Partner Community'];
        List<RecordType> lstRecordType = [Select Id from RecordType where Name ='Partner'];
        
        Account objAccount = New Account(name='TestProduct',Products_Purchased__c= 'BillingCenter', billingcountry ='Austria');
        objAccount.RecordTypeId =lstRecordType[0].Id;
        insert objAccount;
        
        Contact contact = new Contact();
        contact.LastName = 'testContact';
        contact.AccountId = objAccount.Id;
        contact.Category__c = 'Billing';
        insert contact;
        
        Region__c reg = new Region__c();
        reg.country__c= 'Poland';
        reg.sub_region__c= 'Pol';
        insert reg;
        
      
        
        list<user> ulst = [select id,name from user where profileid =: lstProfile[0].id and isactive=true ];
        
        Account firstAccount = New Account(name='TestProduct',Products_Purchased__c= 'BillingCenter', billingcountry ='Poland');
        firstAccount.MPL_Sales_Rep__c = ulst[0].Id;
        firstAccount.RecordTypeId =lstRecordType[0].Id;
        insert firstAccount;
        
        objAccount.MPL_Sales_Rep__c = ulst[0].Id;
        update objAccount;
    }
    
        public static testmethod void testAccountPartnerType(){
        // create account with blank alliance and prospective partner type
        Account a = new Account(name = 'test', prospective_partner_Type__c = 'First Option', billingcountry ='Poland');
        insert a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assertequals(a.alliance_type__c , 'First Option');
        // add new option in prospective
        a.prospective_partner_Type__c = 'Second Option';
        update a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assert(a.alliance_type__c.contains('Second Option') && a.alliance_type__c.contains('First Option'));
        // add second option again
        a.prospective_partner_Type__c = 'Second Option';
        update a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assertequals(a.alliance_type__c.countmatches('Second Option'), 1);                
    }
}