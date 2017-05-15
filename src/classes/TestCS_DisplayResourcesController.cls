@isTest
public class TestCS_DisplayResourcesController {
	static Account customerAcc;
    static Account partnerAcc;
    static Product2 prod;
    static ContentVersion contentVersion;
    static ContentDocumentLink cdl;
    static CS_Release__c release;
    static Contact contact;
    static List<Asset> parentAssetsCustomer;
    static User customerCommunityTestUser;
    static List<GW_Common_Settings__c> commonSettings;
    static CS_Software_Downloads__c softwareDownload;
    static CS_Product_Documentation__c productDocumentation;
    
    private static void setupCustomerTestData() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        contact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        prod = CS_TestDataUtility.createProductRecord();
        parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        release = CS_TestDataUtility.createRelease(prod);
        // insert child assets for customer assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        cdl = CS_TestDataUtility.createContentDocumentLink(cv.ContentDocumentId, release.Id);
        Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
        softwareDownload = CS_TestDataUtility.createSoftwareDownload(cAsset, release);
		productDocumentation = CS_TestDataUtility.createProductDocumentations(release);
    }
    
    static testMethod void testDisplayResourceControllerCustomer() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
		

      
        System.runAs(currentUsr) {
            
			customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            setupCustomerTestData();
            System.runAs(customerCommunityTestUser) {
                
                Test.startTest();
              
                User usr = CS_DisplayResourcesController.getCurrentUser();
                String userType = CS_DisplayResourcesController.getUserType();

                List<Map<String, String>> productResources = CS_DisplayResourcesController.getProductResources('BillingCenter Group', 'TestProduct', '8.1', 'None');
                Test.stopTest();
            }
        }
    }
    static testMethod void testCreateCaseCaseCreateController() {

        test.starttest();

         List<Case> cas = CS_CaseCreateController.getCaselist();
         Account a = CS_TestDataUtility.createCustomerAccount();
         Contact c = CS_TestDataUtility.createContact(a,'General Customer');
          RecordType rt1 = [Select id,name,DeveloperName from RecordType where SobjectType = 'Case' and DeveloperName = 'CS_Customer_Support'];
         Case ca = new Case();
        ca.recordtypeId = rt1.Id;
        ca.Severity__c = '3-Major';
        ca.CS_Urgency__c ='low';
        ca.Category__c ='Data';
        ca.Subject ='Testing case';
        ca.ContactId = c.Id;
        ca.Status = 'New';

        CS_CaseCreateController.getCaseupdatedlist(ca);

        test.stoptest();
    }

    static testMethod void testRedirectToBox() {

        
        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';
        cBox.Access_Token__c = 'abc@xyz.com';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));

        String res = CS_DisplayResourcesController.redirectToBox('abc123');

        CS_DisplayResourcesController.sendEmailMssg('abc@xyz.com','12345'); 

        test.stoptest();
    }

    static testMethod void testRedirectToBoxBadRequest() {

        
        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';
        cBox.Access_Token__c = 'abc@xyz.com';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));

        String res = CS_DisplayResourcesController.redirectToBox('abc123');       

        test.stoptest();
    }
/*
    static testMethod void testCreateCaseCaseCreateController() {
        Test.startTest();
        Account a = CS_TestDataUtility.createCustomerAccount();
        Contact c = CS_TestDataUtility.createContact(a, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        
        Product2 pd = new Product2();
        pd.Name='TestProduct1'; 
        pd.ProductCode='TEPD1';
        pd.Product_Group_Name__c = 'BillingCenter Group';
        insert pd;
        
         release = new CS_Release__c();
         release.CS_Product__c = pd.Id;
         release.CS_IsActive__c = true;
         release.CS_Major_Release_version__c = '8';
         release.CS_Minor_Release_Version__c ='1';
         insert release;
        
        Asset parentAsset = new Asset();
        parentAsset.Name='TestParentAssetProspect1'; 
                                     parentAsset.AccountId=a.Id; 
                                     parentAsset.CS_Support_Group__c='Billing System';
                                     parentAsset.Status = 'Prospect';
                                     parentAsset.CS_Is_Active__c = true;
        insert parentAsset;
        
        Asset childAst = CS_TestDataUtility.createChildAssetWithRelease(a,pd,parentAsset,release,'active');
        
       Case cs = CS_TestDataUtility.createCaseCS(a,childAst,c);     

      
        System.runAs(currentUsr) {
            
            customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(c);
            setupCustomerTestData();
            System.runAs(customerCommunityTestUser) {
                
                
              
                List<Case> ca = CS_CaseCreateController.getCaselist();
                CS_CaseCreateController.getCaseupdatedlist(cs);
               
                
            }
        }
        Test.stopTest();
    }
    */
    
}