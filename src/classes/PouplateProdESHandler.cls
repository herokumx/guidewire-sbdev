public without sharing class PouplateProdESHandler
{
    public static boolean isExecuted =false;
    
    public static void onCreation(List<Extended_Support__c> lstExtendedSupport)
    {
        Set<Id> setProductIds =new Set<Id>();
        Map<Id, Product__c> mapProduct;
        
        for(Extended_Support__c extendedSupport :lstExtendedSupport)
            setProductIds.add(extendedSupport.product__c);
        
        updateVersionRuh(setProductIds, lstExtendedSupport);
    }
    
    public static void onUpdation(List<Extended_Support__c> lstExtendedSupport, Map<Id,Extended_Support__c> mapOldExtendedSupport)
    {
        Map<Id,Extended_Support__c> mapExtendedSupport =new Map<Id,Extended_Support__c>([Select Version_RUH__c,Product__r.Current_Product_Version__c from Extended_Support__c where Id =:lstExtendedSupport]);
        Set<Id> setProductIds =new Set<Id>();
        
        for(Extended_Support__c extendedSupport :lstExtendedSupport)
        {
            if(extendedSupport.product__c != mapOldExtendedSupport.get(extendedSupport.Id).product__c)
                setProductIds.add(extendedSupport.product__c);
        }
        
        updateVersionRuh(setProductIds, lstExtendedSupport);
        isExecuted =true;
    }
    
    static void updateVersionRuh(Set<Id> setProductIds, List<Extended_Support__c> lstExtSupport)
    {
        Map<Id, Product__c> mapProduct;
        
        if(!setProductIds.isEmpty())
        {
            mapProduct =new Map<Id, Product__c>([Select Current_Product_Version__c from Product__c where Id IN:setProductIds]);
        }
        
        if(mapProduct != null && mapProduct.size() >0)
        {
            for(Extended_Support__c extendedSupport :lstExtSupport)
            {
                extendedSupport.Version_RUH__c =mapProduct.get(extendedSupport.product__c).Current_Product_Version__c;
            }
        }
    }
    
    public static void updateProduct(List<Extended_Support__c> lstExtSupport)
    {
        Map<id,id> mapProductIdExtendedSupport = new Map<id,id>();
        for(Extended_Support__c ess :lstExtSupport)
        {
            mapProductIdExtendedSupport.put(ess.Product__c,ess.id);
        }
        List<Product__c> lstProduct = [Select Id,name,Extended_Support__c from Product__c where id =:mapProductIdExtendedSupport.keyset()];
        for(Product__c ppp:lstProduct)
        {
            ppp.Extended_Support__c = mapProductIdExtendedSupport.get(ppp.id);
        }
        update lstProduct ;
    }
}