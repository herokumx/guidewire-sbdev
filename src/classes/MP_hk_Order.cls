/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 * 	 This page enforces single quantity to 1 and changes the status to 'Ready to Download'
 */
global with sharing class MP_hk_Order extends ccrz.cc_hk_Order {
    global override Map<String, Object> place(Map<String, Object> inputData) {
        System.debug('MP_hk_Order Enter --------------');
        String currStep = (String) inputData.get(ccrz.cc_hk_Order.PARAM_PLACE_STEP);
        if (currStep == ccrz.cc_hk_Order.STEP_FETCH_CART_ITEMS) {
            List<ccrz__E_CartItem__c> cartItems = (List<ccrz__E_CartItem__c>) inputData.get(ccrz.cc_hk_Order.PARAM_CART_ITEMS);
            System.debug('MP_hk_Order cartItems ---------------- ' + cartItems.size());
            for (ccrz__E_CartItem__c cartItem : cartItems) {
                // enforce single quantity on orders
                cartItem.ccrz__Quantity__c = 1;
            }
        } else if (currStep == ccrz.cc_hk_Order.STEP_UPDATE_ORDER_STATUS_PRE) {
            ccrz__E_Order__c updateOrder = (ccrz__E_Order__c) inputData.get(ccrz.cc_hk_Order.PARAM_ORDER_W_STATUS);
            updateOrder.ccrz__OrderStatus__c = 'Ready to Download';// or 'Download complete'
        }
        
        return inputData;
    }
/*
    global static MP_hk_Order getInstance(Map<String, Object> inputData) {
        return super.getInstance(inputData);
    }
*/
}