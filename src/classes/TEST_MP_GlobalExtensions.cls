@IsTest
public class TEST_MP_GlobalExtensions {

    static testMethod void testHkOrderFetchItems() {
        Map<String,Object> inputData = new Map<String,Object>();
        inputData = createInputFetchCartItems(inputData);
        MP_hk_Order orderHook = new MP_hk_Order();
        Map<String,Object> retData = orderHook.place(inputData);
        List<ccrz__E_CartItem__c> cartItems = (List<ccrz__E_CartItem__c>) retData.get(ccrz.cc_hk_Order.PARAM_CART_ITEMS);
        System.debug('cartItems.size ' + cartItems.size());
        System.assertEquals(5, cartItems.size());
        for (ccrz__E_CartItem__c cartItem : cartItems) {
            // assert single quantity on items is enforced.
            System.debug('cartItemQty ' + cartItem.ccrz__Quantity__c);
            System.assertEquals(Decimal.valueOf(1), cartItem.ccrz__Quantity__c);
        }
    }

    static testMethod void testHkOrderStatusPre() {
        Map<String,Object> inputData = new Map<String,Object>();
        inputData = createInputUpdateOrderStatusPre(inputData);
        MP_hk_Order orderHook = new MP_hk_Order();
        ccrz__E_Order__c updateOrder = (ccrz__E_Order__c) inputData.get(ccrz.cc_hk_Order.PARAM_ORDER_W_STATUS);
        String origStatus = updateOrder.ccrz__OrderStatus__c;
        Map<String,Object> retData = orderHook.place(inputData);
        updateOrder = (ccrz__E_Order__c) retData.get(ccrz.cc_hk_Order.PARAM_ORDER_W_STATUS);
        String newStatus = updateOrder.ccrz__OrderStatus__c;

        System.assertNotEquals(origStatus, newStatus);
        System.assertEquals('Ready to Download', newStatus);
    }

    private static Map<String,Object> createInputFetchCartItems(Map<String,Object> inputData) {
        inputData.put(ccrz.cc_hk_Order.PARAM_PLACE_STEP, ccrz.cc_hk_Order.STEP_FETCH_CART_ITEMS);

        List<ccrz__E_CartItem__c> cartItems = new List<ccrz__E_CartItem__c>();
        for (Integer i=0;i<5; i++) {
            ccrz__E_CartItem__c item = new ccrz__E_CartItem__c();
            item.ccrz__Quantity__c = i;
            cartItems.add(item);
            System.debug('i ' + i);
        }

        inputData.put(ccrz.cc_hk_Order.PARAM_CART_ITEMS, cartItems);

        List<ccrz__E_CartItem__c> cartItemsData = (List<ccrz__E_CartItem__c>) inputData.get(ccrz.cc_hk_Order.PARAM_CART_ITEMS);
        System.debug('inputData.cartItemsData.size ' + cartItemsData.size());

        return inputData;
    }

    private static Map<String,Object> createInputUpdateOrderStatusPre(Map<String,Object> inputData) {
        inputData.put(ccrz.cc_hk_Order.PARAM_PLACE_STEP, ccrz.cc_hk_Order.STEP_UPDATE_ORDER_STATUS_PRE);
        ccrz__E_Order__c updateOrder = new ccrz__E_Order__c();
        updateOrder.ccrz__OrderStatus__c = 'Order Submitted';
        inputData.put(ccrz.cc_hk_Order.PARAM_ORDER_W_STATUS, updateOrder);

        return inputData;
    }

    static testMethod void testApiCartExtensionPreprocess() {
        Map<String,Object> inputData = new Map<String,Object>();
        inputData = createInputPreprocess(inputData);
        MP_api_CartExtension cartExtension = new MP_api_CartExtension();
        Map<String,Object> retData = cartExtension.preprocess(inputData);
        List<ccrz__E_CartItem__c> cartItems = (List<ccrz__E_CartItem__c>) retData.get(ccrz.cc_api_CartExtension.PARAM_CARTITEMS);
        for (ccrz__E_CartItem__c cartItem : cartItems) {
            // assert single quantity on items is enforced.
            System.assertEquals(cartItem.ccrz__Quantity__c, Decimal.valueOf(1));
        }
    }

    private static Map<String,Object> createInputPreprocess(Map<String,Object> inputData) {
        List<ccrz__E_CartItem__c> cartItems = new List<ccrz__E_CartItem__c>();
        for (Integer i=0;i<5; i++) {
            ccrz__E_CartItem__c item = new ccrz__E_CartItem__c();
            item.ccrz__Quantity__c = i;
            cartItems.add(item);
        }
        inputData.put(ccrz.cc_api_CartExtension.PARAM_CARTITEMS, cartItems);

        return inputData;
    }

}