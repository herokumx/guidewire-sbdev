public without sharing class ProductHelper {
    
   // By Rakshik on 20th
   public static boolean IsExcecuted = false;
   List<Account> AccountstobeUpdated = new List<Account>();
   String productPurchased = '';
   Map<Id, String> mapOfAccountProductsPurchased = new Map<ID, String>();
    
    public void insertProductsPurchased(List<Product__c> listnewproducts)
    {
       for(Product__c product : listnewproducts)
       {
            if(product.Add_On_Module_s__c != null) {
                productPurchased = product.Products__c + ' ; ' + product.Add_On_Module_s__c;                    
            } 
            else 
            {
                productPurchased = product.Products__c;
            }
            manageaddonvalue(product);
       } 
    }

    public void updateProductsPurchased(List<Product__c> listnewproducts, Map<Id, product__c> oldMap)
    {
       for(Product__c product : listnewproducts)
       {
            Product__c oldProduct = oldMap.get(product.Id);
            productPurchased = product.Add_On_Module_s__c;
            
            if(oldProduct.Add_On_Module_s__c != productPurchased)
            {     
                manageaddonvalue(product);
            }
       }         
    }
    
    public void manageaddonvalue(Product__c product)
    {
        String getAccountProductsPurchased = '';
        for (Account a :[Select id, Products_Purchased__c from Account]) 
        {
            mapOfAccountProductsPurchased.put(a.id, a.Products_Purchased__c);
        }        
         
        If(mapOfAccountProductsPurchased.get(product.account__c) == null) 
        {
            getAccountProductsPurchased = '';
            AccountstobeUpdated.add(new Account(id=product.account__c,Products_Purchased__c= getAccountProductsPurchased + ' ; ' + productPurchased ));
        } 
        else 
        {
            getAccountProductsPurchased  = mapOfAccountProductsPurchased.get(product.account__c);
            if(productPurchased != null)
            {
                List<string> addonvalue = productPurchased.split(';');
                
                List<string> testlist = getAccountProductsPurchased.split(';');
                Set<string> testset = new Set<string>();
                for(string a1 : testlist )
                {
                    testset.add(a1.trim());
                    //System.debug('a1 ' + a1);
                }                
                
                for(string a : addonvalue)
                {
                    //System.debug('getAccountProductsPurchased '+ getAccountProductsPurchased + ', a ' + a);
                    //System.debug('getAccountProductsPurchased Index of '+ getAccountProductsPurchased.indexof(a));
                    if(!testset.contains(a.trim())) 
                    {
                        //System.debug('a ' + a);
                        testset.add(a.trim());
                        getAccountProductsPurchased += ';' + a ;
                    } 
                }
                //System.debug('testset size '+ testset.size());
                //System.debug('getAccountProductsPurchased  '+ getAccountProductsPurchased );
                AccountstobeUpdated.add(new Account(id=product.account__c,Products_Purchased__c= getAccountProductsPurchased));
            }    
        }
        if (AccountstobeUpdated.size() > 0) update AccountstobeUpdated ;
    }
    
    //By Rakshik on 20th July 2014
    public static void updateVersionRuh(Map<Id, Product__c> mapProduct, Map<Id, Product__c> mapOldProduct)
    {
        Set<Id> productIds =new Set<Id>();
        List<Extended_Support__c> lstExtendedSupport;
        for(Product__c product :mapProduct.values())
        {
            if(product.Current_Product_Version__c != mapOldProduct.get(product.Id).Current_Product_Version__c)
                productIds.add(product.Id);
        }
        
        if(!productIds.isEmpty())
        {
            lstExtendedSupport =[Select Version_RUH__c,Product__c from Extended_Support__c where Product__c IN:productIds];
            List<Extended_Support__c> lstESToUpdate =new List<Extended_Support__c>();
        
            if(!lstExtendedSupport.isEmpty())
            {
                for(Extended_Support__c extendedSupport :lstExtendedSupport)
                {
                    if(String.isNotBlank(mapProduct.get(extendedSupport.Product__c).Current_Product_Version__c))
                    {
                        extendedSupport.Version_RUH__c =mapProduct.get(extendedSupport.Product__c).Current_Product_Version__c;
                        lstESToUpdate.add(extendedSupport);
                    }
                }
                update lstESToUpdate;
            }
        }
        IsExcecuted =true;
    }
}