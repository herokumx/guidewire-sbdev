/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 * 	 This class retrieves the Download URL for each Order Item Product
 */
global class MP_OrderDetailCtrl {
    global String encryptedId {get;set;}
    global String extendedOrderJSON {get;set;}
    global Map<String,String> orderItemDownloadURLMap {get;set;}
    global MP_OrderDetailCtrl(){
        orderItemDownloadURLMap = new Map<String,String>();
        encryptedId = ApexPages.currentPage().getParameters().get('o');
        try{
            for(ccrz__E_OrderItem__c oi : [select Id, ccrz__Product__r.MP_DownloadURL__c from ccrz__E_OrderItem__c where ccrz__Order__r.ccrz__EncryptedId__c =: encryptedId]){
                orderItemDownloadURLMap.put(oi.Id, oi.ccrz__Product__r.MP_DownloadURL__c);
            }
            final Map<String,Object> customOrderData = new Map<String,Object>{
                'orderItemDownloadURLMap' => orderItemDownloadURLMap
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