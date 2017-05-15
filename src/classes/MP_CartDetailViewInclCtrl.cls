/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 * 	This class adds the Date Added attribute on the My Cart Page
 */
global class MP_CartDetailViewInclCtrl {
    
    global String encryptedId {get;set;}
    global String extendedOrderJSON {get;set;}
    global Map<String,String> cartItemDateAddedMap {get;set;}
    global integer itemNumber {get;set;}
    global MP_CartDetailViewInclCtrl(){
        cartItemDateAddedMap = new Map<String,String>();
        encryptedId = ApexPages.currentPage().getParameters().get('cartID');
        itemNumber = 0;
        try{
            for(ccrz__E_CartItem__c ci : [select Id, CreatedDate from ccrz__E_CartItem__c where ccrz__Cart__r.ccrz__EncryptedId__c =: encryptedId]){
                cartItemDateAddedMap.put(ci.Id, String.valueOf(ci.CreatedDate.format('MM/dd/yyyy')));
                itemNumber++;
            }
            system.debug('cartItemDateAddedMap: '+cartItemDateAddedMap);
            final Map<String,Object> customOrderData = new Map<String,Object>{
                'cartItemDateAddedMap' => cartItemDateAddedMap
            }; 

            extendedOrderJSON = JSON.serialize(new Map<String,Object>{
                 'extOrderData' => customOrderData
            });
            system.debug('extendedOrderJSON: '+extendedOrderJSON);
        }
        catch(Exception e){
 			System.debug('Error: '+e.getMessage());
        }
    }
}