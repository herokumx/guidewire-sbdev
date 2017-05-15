@isTest(seealldata=true) 
Public Class TestPouplateProdESHandler{
static testMethod void myTest(){
Account acc = new Account();
acc.Name = 'Test1';
insert acc;
Product__c ppp = new Product__c();
//ppp.Name = 'Product1';
ppp.Account__c = acc.id;
ppp.Current_Product_Version__c ='3';
insert ppp;

Product__c product = new Product__c();
product.Account__c = acc.id;
product.Current_Product_Version__c ='7';
insert product;

Extended_Support__c ess = new Extended_Support__c(); 
ess.Product__c = ppp.id;
ess.Contract__c = [select id from contract limit 1].id;
ess.Opportunity__c = [select id from Opportunity limit 1].id;
insert ess;

ess.product__c =product.Id;
update ess;

}
}