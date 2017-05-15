@isTest(seeAllData=true)
public class CreditCardUnassignedPersonalTest 
{
    static testmethod void Unassigned()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='GW Standard Platform User'];
        
        User U = new User(Alias = 'stest', Email='testuser@testorg.com',EmailEncodingKey='UTF-8', 
                                   LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='testhariuser@testorg.com');
        
        insert U;        
        
        PSA_Card_Transaction__c CardTrans= new PSA_Card_Transaction__c();
                CardTrans.Name = 'Test';
                CardTrans.PSA_Salesforce_User__c = u.id;
                CardTrans.PSA_Merchant_Name__c = 'AMFAM MADISON 6008';
                CardTrans.PSA_Amount_in_Original_Currency__c = 1000;
                CardTrans.PSA_Merchant_Country_Code__c = 'USA'; 
                CardTrans.PSA_Charge_Type__c ='Company';
      
                insert CardTrans; 
        
        CreditCardTransUnassigned.CardTransactions();
    } 
    
    static testmethod void Personal()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='GW Standard Platform User'];
        
        User U = new User(Alias = 'stest', Email='testuser@testorg.com',EmailEncodingKey='UTF-8', 
                                   LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='testhari1user@testorg.com');
        
        insert U;        
        
        PSA_Card_Transaction__c CardTrans= new PSA_Card_Transaction__c();
                CardTrans.Name = 'Test1';
                CardTrans.PSA_Salesforce_User__c = u.id;
                CardTrans.PSA_Merchant_Name__c = 'AMFAM MADISON 6008';
                CardTrans.PSA_Amount_in_Original_Currency__c = 1000;
                CardTrans.PSA_Merchant_Country_Code__c = 'USA'; 
                CardTrans.CurrencyIsoCode ='USD';
                CardTrans.PSA_Charge_Type__c ='Itemized';
      
                insert CardTrans; 
        
        PSA_Card_Transaction_Item__c item = new PSA_Card_Transaction_Item__c();
               item.PSA_Card_Transaction__c = CardTrans.id;
               item.CurrencyIsoCode ='USD';
               item.PSA_Charge_Type__c ='Personal';
               item.PSA_Amount_in_Original_Currency__c = 200;
               item.GW_Card_Reimbursement_Amount__c = 100;
        
              insert item;
        
        PSA_Card_Transaction__c CardTrans1= new PSA_Card_Transaction__c();
                CardTrans1.Name = 'Test11';
                CardTrans1.PSA_Salesforce_User__c = u.id;
                CardTrans1.PSA_Merchant_Name__c = 'AMFAM MADISON 60081';
                CardTrans1.PSA_Amount_in_Original_Currency__c = 10001;
                CardTrans1.PSA_Merchant_Country_Code__c = 'USA'; 
                CardTrans1.PSA_Charge_Type__c ='Personal';
                CardTrans1.CurrencyIsoCode ='USD';
      
                insert CardTrans1; 
        
        CreditCardPersonal.CardTransactionItems();
    }
    
}