/* =================================================================================================
*   Version     Date                   Comment
* =================================================================================================
*   1.0         03-Apr-2017           Order Utility class for updating related orders status to
*                                       Deacivated.
**/

public with sharing class CPQ_OrderActivationUtility{
    //Check if Order status is updated
    public static void updateRelatedOrderStatus(List<Order> pLstOfOrders, Map<Id,Order> pOldMap) {
        List<Order> lstOfOrderStatusActivated = new List<Order>();

        for(Order objNewOrder : pLstOfOrders) {

            if (!String.isBlank(objNewOrder.Status) && !String.isBlank(pOldMap.get(objNewOrder.Id).Status)) {
                if(!objNewOrder.Status.equalsIgnoreCase(pOldMap.get(objNewOrder.Id).Status)) {
                    if(objNewOrder.Status.equalsIgnoreCase(Label.CPQ_Order_Status_Activated)) {
                        lstOfOrderStatusActivated.add(objNewOrder);
                    }
                }
            }
        }

        if(!lstOfOrderStatusActivated.isEmpty()) {
            orderStatusChangeOnUpdate(lstOfOrderStatusActivated);
        }
    }

    // method to update related Order whose status is Activated
    public static void orderStatusChangeOnUpdate(List<Order> lstOrder) {
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();

        // get Opportunity realted otrders
        if(!lstOrder.isEmpty()) {
            for (Order orderObj: lstOrder) {
                if (orderObj.OpportunityId != null) {
                    oppIdSet.add(orderObj.OpportunityId);
                    orderIdSet.add(orderObj.Id);
                }
            }
        }

        if(oppIdSet.size() > 0) {
            List<Opportunity> lstOppWithOrders = new List<Opportunity>();
            List<Order> lstOrders_ToUpdate = new List<Order>();

            lstOppWithOrders = [SELECT Id
                                     , Name
                                     , (SELECT Id
                                             , Status
                                             FROM Orders)
                                    FROM Opportunity
                                    WHERE Id IN : oppIdSet];

            if (!lstOppWithOrders.isEmpty()) {
                for (Opportunity OppObj : lstOppWithOrders) {
                    if(OppObj.Orders != NULL) {
                        for (Order orderObj : OppObj.Orders) {
                            if(!orderIdSet.contains(orderObj.Id)) {
                                if (Label.CPQ_Order_Status_Activated.equalsIgnoreCase(orderObj.Status)) {
                                    orderObj.Status = Label.CPQ_Order_Status_Deactivated;
                                    lstOrders_ToUpdate.add(orderObj);
                                }
                            }
                        }
                    }
                }
            }

            try {
                if (!lstOrders_ToUpdate.isEmpty()) {
                    update lstOrders_ToUpdate;
                }
            }catch(DmlException e) {
                return;
            }
        }
    }
}