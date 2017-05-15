@istest(seeAllData =true)
public class CaseEscalatorHandlerTest
{
    static testmethod void Escalator()
    {
        account acc= new account();
        acc.Name = 'Test';
        acc.Type = 'Analyst';
        acc.Buying_Entity__c = 'No';
        acc.CurrencyIsoCode = 'USD';
        acc.Industry='Analyst';
        acc.BillingCountry = 'India';
        
        insert acc;   
        
        String strRecordTypeId = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'Guidewire Live'].Id;
        
        Case cse = new Case();
        cse.Subject = 'guideLive';
        cse.Description='test guidewire';
        cse.Category__c ='Application Issue';
        cse.Sub_Category__c='All';
        cse.RecordTypeId = strRecordTypeId;
        cse.Status_Summary_Next_Steps__c ='Guidewire live cases org';
        cse.Customer_Account__c =acc.Id;
        cse.IsEscalated = false;
        
        insert cse;
        
        cse.IsEscalated = true;
        update cse;
        
    }

}