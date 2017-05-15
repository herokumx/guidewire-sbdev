/******************************************************************************** 
Name: Test
Copyright © 2014 Guidewire
====================================================== 
====================================================== 
Purpose:
  Class
======================================================
====================================================== 
History  -------
VERSION  AUTHOR              DATE         DETAIL                 
1.0 -   Rakshik Bhan      5/15/2014   INITIAL DEVELOPMENT  
*********************************************************************************/
@isTest
public class ProductHelperTest    
{
   
    
    //Test method for ProductBeforeInsertBeforeUpdate Trigger
    testMethod static void test_ProductBeforeInsert()
    {
        Test.startTest();
        list<Account> listAccount = new list<Account>();
        list<Product__c> listProduct = new list<Product__c>();
        //insert Account (Master)
        List<RecordType> lstRecordType =[Select Id from RecordType where Name ='Partner'];
        
        Account objAccount = New Account(name='TestProduct',Products_Purchased__c= 'BillingCenter');
        objAccount.RecordTypeId =lstRecordType[0].Id;
        insert objAccount;
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name ='testOpportunity';
        opportunity.AccountId =objAccount.Id;
        opportunity.Type ='Net New';
        opportunity.PRM_Referring_Partner2__c =objAccount.Id;
        opportunity.StageName ='Working';
        opportunity.CloseDate =Date.Today();
        Database.SaveResult saveResult =Database.insert( opportunity,false);
        //System.assert(saveResult.isSuccess());
        //Test for Bulkification           
         
         Contract contract = new Contract();
         contract.AccountId =objAccount.Id;
         contract.Status ='Draft';
         contract.Invoice_Date__c =Date.today();
         saveResult =Database.insert(contract,false);
         System.assert(saveResult.isSuccess());
         
         Product__c objP = new Product__C(Account__c = objAccount.id, Add_On_Module_s__c ='Standard Reporting' );
         objP.Current_Product_Version__c = '9';
         saveResult =Database.insert(objP,false);
         System.assert(saveResult.isSuccess());
         
         Extended_Support__c ess = new Extended_Support__c(); 
        ess.Product__c = objP.id;
        ess.Contract__c = contract.Id;//[select id from contract limit 1].id;
        ess.Opportunity__c = opportunity.Id; //[select id from Opportunity limit 1].id;
        saveResult =Database.insert(ess,false);
       //  System.assert(saveResult.isSuccess());
            
           //update Product
        objP.Add_On_Module_s__c ='Rating Management' ;
        objP.Current_Product_Version__c = '1';
        ProductHelper.IsExcecuted = false;
        update objP;
        
        Test.stopTest();
        
     }
    
     
}