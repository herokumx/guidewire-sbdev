@isTest
public class TestCS_CraController {
    static User partnerCommunityTestUser;
    static testMethod void testCraController() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
			partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                CS_CraController.getAccountUrl();
            }
        }
    } 
    
    static testMethod void testCraController2() {
       
        CS_CraController.getAccountUrl();
        
    }
}