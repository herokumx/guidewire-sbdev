@isTest
public class CPQ_SalesOrderCreationNotificationTest {

    public static testMethod void notifyRevTeamSuccessTest() {

        Account accObj = CPQ_TestDataUtility.accountTestData(true);

        ServiceContract serviceContrObj = CPQ_TestDataUtility.serviceContractTestData(accObj.Id, true);

        Opportunity oppObj = CPQ_TestDataUtility.opportunityForContTestData(accObj.Id, true);

        Contract contractObj = CPQ_TestDataUtility.contractTesData(accObj.Id, oppObj.Id, true);

        Opportunity oppWithContract = CPQ_TestDataUtility.opportunityTestData(accObj.Id, contractObj.Id, false);
        oppWithContract.Service_Contract__c = serviceContrObj.Id;
        insert oppWithContract;

        Order order = CPQ_TestDataUtility.singleOrderUpdate(accObj.Id, oppWithContract.Id, true);

        String resultString;
        Test.startTest();
            resultString = CPQ_SalesOrderCreationNotification.notifyRevTeam(order.ID);
        Test.stopTest();

        System.assert(resultString == CPQ_SalesOrderCreationNotification.SUCCESS);
    }

    public static testMethod void notifyRevTeamErrorTest() {
        String resultString;
        Test.startTest();
            resultString = CPQ_SalesOrderCreationNotification.notifyRevTeam(null);
        Test.stopTest();

        System.assert(resultString == CPQ_SalesOrderCreationNotification.ERROR_IN_DATA);
    }

    public static testMethod void notifyRevTeamNotFoundTest() {
        String resultString;
        Test.startTest();
            resultString = CPQ_SalesOrderCreationNotification.notifyRevTeam('8014C000000S5eb');
        Test.stopTest();

        System.assert(resultString == CPQ_SalesOrderCreationNotification.ORDER_NOT_FOUND);
    }
}