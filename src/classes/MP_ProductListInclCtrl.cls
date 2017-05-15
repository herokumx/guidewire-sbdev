/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 * 	This class checks the current users pricelist items. It helps to add a message if a Category search returns no results.
 */
global with sharing class MP_ProductListInclCtrl {
	global String extendedProdJSON {get;set;}
    global String categoryId {get;set;}
    global Boolean reviewAccess {get;set;}
    global MP_ProductListInclCtrl() {
        categoryId = ApexPages.currentPage().getParameters().get('categoryId');
        try{
            User u = [select Id, Contact.Account.Recordtype.Name, Contact.Account.ccrz__E_AccountGroup__c, Contact.Account.Alliance_Type__c, ContactId from User where Id =: UserInfo.getUserId()];
            Set<Id> priceListIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            if(UserInfo.getUserType() == 'Guest'){
                for(ccrz__E_AccountGroupPriceList__c agpl : [select id, ccrz__Pricelist__c 
                                                                 from ccrz__E_AccountGroupPriceList__c 
                                                                 where ccrz__Enable__c = true and ccrz__AccountGroup__r.Name =: 'Anonymous']){
                     priceListIds.add(agpl.ccrz__Pricelist__c);                                                
                }
            }
            else{
                for(ccrz__E_AccountGroupPriceList__c agpl : [select id, ccrz__Pricelist__c 
                                                                 from ccrz__E_AccountGroupPriceList__c 
                                                                 where ccrz__Enable__c = true and ccrz__AccountGroup__c =: u.Contact.Account.ccrz__E_AccountGroup__c]){
                     priceListIds.add(agpl.ccrz__Pricelist__c);                                                
                }
            }
            
            for(ccrz__E_PriceListItem__c pli : [select id, ccrz__Product__c from ccrz__E_PriceListItem__c where ccrz__Pricelist__c IN: priceListIds]){
            	productIds.add(pli.ccrz__Product__c);
            }
            
            List<ccrz__E_ProductCategory__c> product = [SELECT Id FROM ccrz__E_ProductCategory__c WHERE ccrz__Category__c = :categoryId and ccrz__Product__c IN: productIds];
            final Map<String,Object> customProdData = new Map<String,Object>{
                'productSize'=>product.size()
            };   
            extendedProdJSON = JSON.serialize(new Map<String,Object>{
                 'extProdData' => customProdData
            });
        }
        catch(Exception e){
            extendedProdJSON = '';
        }

    }

}