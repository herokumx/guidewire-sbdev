@isTest
public class TestCS_ACP_Deactivate_Prospect {
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    //static CS_Asset_Contact_Permissions__c acp;
	static String CRON_EXP = '0 0 0 15 9 ? 2022';
    
    static void setupTestData() {
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'General Customer');
        // insert parent asset for customer account
        Asset parentAsset1 = new Asset();
        parentAsset1.Name = 'TestParentAsset';
        parentAsset1.AccountId = customerAcc.Id;
        parentAsset1.UsageEndDate = Date.today();
        parentAsset1.Product2Id = prod.Id;
		insert parentAsset1;
        
        Asset insertedAsset = [Select Id from Asset limit 1];
            
        if (insertedAsset != null) {
            // create acp
            CS_Asset_Contact_Permissions__c acp = new CS_Asset_Contact_Permissions__c();
            acp.CS_Contact__c=customerContact.Id;
            acp.CS_Asset__c=insertedAsset.Id;
            acp.CS_Access_Type__c = 'Prospect';
            acp.CS_Evaluation_End_Date__c = Date.today();
        }
    }
    
    static testmethod void test() {
        setupTestData();
        Test.startTest();
        String jobId = System.schedule('TestDeactivateACP', CRON_EXP, new CS_ACP_Deactivate_Prospect());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
		Test.stopTest();
    }

}