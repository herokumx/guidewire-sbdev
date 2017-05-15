/* =================================================================================================
*   Version     Date                   Comment
* =================================================================================================
*   1.0         03-Apr-2017           Test class for CPQ_OrderActivationUtility.
**/
@isTest
private class CPQ_OrderActivationUtilityTest {

    /**
    * Test method to check deactivate related Orders when Order status is updayed to 'Activated'
    */
    @isTest static void testToDeactivateRelatedOrders() {
        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, true);

        Product2 prod2Obj = CPQ_TestDataUtility.productTestData(true);

        PricebookEntry pbEntryObj = CPQ_TestDataUtility.pbEntryTestData(prod2Obj.Id, true);

        SBQQ__Quote__c quoteObj = CPQ_TestDataUtility.quoteTestData(oppWithContract.Id, true);

        oppWithContract.SBQQ__PrimaryQuote__c = quoteObj.Id;
        update oppWithContract;

        List<Order> lstOrder = CPQ_TestDataUtility.orderTestData(accObj.Id,oppWithContract.Id, true);

        OrderItem orderItemObj = CPQ_TestDataUtility.orderItemTestData(lstOrder[0].Id, pbEntryObj.Id, true);

        Order testOrder = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id,oppWithContract.Id, true);

        OrderItem orderItemObjForTestOrder = CPQ_TestDataUtility.orderItemTestData(testOrder.Id, pbEntryObj.Id, true);

        System.Test.startTest();
            testOrder.Status = 'Activated';
            update testOrder;
            lstOrder[0].Status = 'Activated';
            update lstOrder[0];
        System.Test.stopTest();

        List<Order> lstOrderStatusDeactivated = [SELECT Id
                                                      , Status
                                                      FROM Order WHERE Status = 'Deactivated'];
        List<Order> lstOrderStatusDraft = [SELECT Id
                                                , Status
                                                FROM Order WHERE Status = 'Draft'];

        System.assertEquals(1,lstOrderStatusDeactivated.size());
        System.assertEquals(testOrder.Id,lstOrderStatusDeactivated[0].Id);
        System.assertEquals(3,lstOrderStatusDraft.size());
    }
}