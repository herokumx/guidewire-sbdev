/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 *   This page enforces single quantity to 1 and determines if the current user can see the Checkout button
 */
global with sharing class MP_api_CartExtension extends ccrz.cc_api_CartExtension {
    global override Map<String,Object> preprocess( Map<String,Object> inputData ) {
        List<ccrz__E_CartItem__c> cartItems = (List<ccrz__E_CartItem__c>) inputData.get(ccrz.cc_api_CartExtension.PARAM_CARTITEMS);
        for (ccrz__E_CartItem__c cartItem : cartItems) {
            // enforce single quantity on orders
            cartItem.ccrz__Quantity__c = 1;
        }
        return inputData;
    }
    global override boolean allowCheckout(Map<String,Object> inputData){
        User u = [select Id, Contact.Account.Recordtype.Name, Contact.Account.Alliance_Type__c, ContactId, Contact.MP_Certified__c from User where Id =: ccrz.cc_CallContext.currUserId];
        
      //  Integer i = [select count() from CS_Asset_Contact_Permissions__c Where CS_Contact__c =:u.ContactId  and CS_Access_Type__c ='Certified'];
       
        Boolean returnVal = false;
        if(u.Contact.Account.Recordtype.Name == 'Customer'){
            returnVal = true;
        }
        else if(u.Contact.Account.Recordtype.Name == 'Partner'){
            if(u.Contact.Account.Alliance_Type__c == 'PartnerConnect - Solution'){
                returnVal = false;
            }
            else if(u.Contact.Account.Alliance_Type__c == 'PartnerConnect - Consulting'){
              //  if(i>0 || u.Contact.MP_Certified__c == true){
                  if(u.Contact.MP_Certified__c == true){
                    returnVal = true;
                }else{
                    returnVal = false;
                }
            }
        }
        return returnVal;
    }
}