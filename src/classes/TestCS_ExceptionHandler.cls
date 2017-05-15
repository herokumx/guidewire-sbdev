@isTest
public class TestCS_ExceptionHandler {
    static testMethod void testExceptionHandler() {
        Account a = CS_TestDataUtility.createCustomerAccount();
        
        CS_ExceptionHandler.createErrorRecord('error', a.Id);
        CS_ExceptionHandler.createErrorRecordMessage('error', 'testMethod');
    }
}