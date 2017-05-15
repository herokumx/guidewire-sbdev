@isTest
public class TestCS_CommunityContentController {
    static User testUser;
    static void setupTestData() {
        testUser = CS_TestDataUtility.createTestUser();
        
        CS_Community_Content__c content= new CS_Community_Content__c();
        content.CS_Community__c = 'Customer';
        content.CS_Content__c = 'Test Community Content';
        content.CS_Location__c = 'R1C3';
        content.CS_Popup__c = true;
        content.CS_Sort_Order__c = 1;
        content.CS_Type__c = 'Text';
        content.CS_Status__c = 'Active';
        insert content;
        
        // query just inserted content
        CS_Community_Content__c insertedContent = [Select Id, Name from CS_Community_Content__c limit 1];
        CS_Content_Access__c access = new CS_Content_Access__c();
        access.CS_Content__c = insertedContent.Id;
        access.CS_User__c = testUser.id;
        access.CS_Profile__c = 'System Administrator';
        
        insert access;
        
    }
    
    static testMethod void testCommunityContent() {
        setupTestData();
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(testUser) {
        	Test.startTest();
            List<CS_Content_Access__c> contentAccess = CS_CommunityContentController.getContentAccess('R1C3', 'Customer');
            Id currentUser = CS_CommunityContentController.getCurrentUser();
            CS_Community_Content__c content = CS_CommunityContentController.getCommunityContent('R1C3', 'Customer');
            User user = CS_CommunityContentController.getCurrentUserforContent();
            Boolean displaySabaRedirect = CS_CommunityContentController.displaySabaRedirectLink();
            
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
            	String reidrectToSabaUrl = CS_CommunityContentController.redirecttoSabaURL();
            }
            Test.stopTest();
        }
    }
}