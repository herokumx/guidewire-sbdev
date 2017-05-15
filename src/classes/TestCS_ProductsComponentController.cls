@isTest
public class TestCS_ProductsComponentController {
    static User testUser;
    static User customerCommunityTestUser;
    static Account customerAcc;
    static Account partnerAcc;
    static List<Asset> parentAssetsCustomer;
    static List<Asset> parentAssetsPartner;
    static Asset childAsset;
    static Product2 prod;
    static CS_Release__c release;
    static Contact contact;
    
    private static void setupTestCustomerData() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        contact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        // insert child assets for customer assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
        
        
    }
    
    private static void setupTestPartnerData() {
        partnerAcc = CS_TestDataUtility.createPartnerAccount();
        contact = CS_TestDataUtility.createContact(partnerAcc, 'Partner');
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        // insert child assets for partner
        for (Integer i=0; i < parentAssetsPartner.size(); i++) {
            if (i < parentAssetsPartner.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, parentAssetsPartner[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(partnerAcc, prod, parentAssetsPartner[i], 'Certification');
            }
        }
    }
    
    static testMethod void testProductController() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        System.debug('currentUsr ' + currentUsr);

        System.runAs(currentUsr) {
			customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
                Test.startTest();
                setupTestCustomerData();
                User user = CS_ProductsComponentController.user;
                String userType = CS_ProductsComponentController.getUserType();
                List<String> parentAssets = CS_ProductsComponentController.getParentAssets('All');
                List<String> childAssetProducts =  CS_ProductsComponentController.getChildAssetProducts();
                //List<String> childAssetProducts2 =  CS_ProductsComponentController.getChildAssetProducts('TestParentAssetProduction');
                List<Asset> childAssets =  CS_ProductsComponentController.getChildAssets('All', 'All');
                //List<Asset> childAssets2 = CS_ProductsComponentController.getChildAssets('TestParentAssetProduction', 'TestChildAsset');
                //List<Asset> childAssets3 = CS_ProductsComponentController.getChildAssets('All', 'TestChildAsset');
                Map<String, Boolean> accessTypeMap = CS_ProductsComponentController.getAcpAccessType();
                Map<String, Boolean> caseAccessTypeMap = CS_ProductsComponentController.getCaseCreateAccessType();
                List<String> urgencyPickvals = CS_ProductsComponentController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_ProductsComponentController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_ProductsComponentController.getSeverityPickval();
                List<String> organizationCaseCreatino = CS_ProductsComponentController.getOrganizationForCaseCreation();
                List<Asset> childAssetsByOrganization = CS_ProductsComponentController.getChildAssetsByOrganization('TestParentAsset');
                
                //Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                //List<CS_Release__c> ProductVersions = CS_ProductsComponentController.getProductVersions(cAsset.Id);
               	//Boolean assetODC = CS_ProductsComponentController.getAssetODC(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = customerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                //Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                //List<CS_Release__c> ProductVersions = CS_ProductsComponentController.getProductVersions(cAsset.Id);
               	//Boolean assetODC = CS_ProductsComponentController.getAssetODC(cAsset.Id);
                
                //Case c = new Case();
                //String newCase = CS_ProductsComponentController.saveCase(c, '1-Blocker', cAsset.Id, release.Id, true, 'High', 'Production');
				Test.stopTest();                
            }
        }
    }
    
    static testMethod void testProductControllerWithPartnerUser() {
        Account acc = CS_TestDataUtility.createPartnerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];
        System.debug('currentUsr ' + currentUsr);

        System.runAs(currentUsr) {
			User partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupTestPartnerData();
                User user = CS_ProductsComponentController.user;
                String userType = CS_ProductsComponentController.getUserType();
                List<String> parentAssets = CS_ProductsComponentController.getParentAssets('All');
                List<String> childAssetProducts =  CS_ProductsComponentController.getChildAssetProducts();
                //List<String> childAssetProducts2 =  CS_ProductsComponentController.getChildAssetProducts('TestParentAssetProduction');
                List<Asset> childAssets =  CS_ProductsComponentController.getChildAssets('All', 'All');
                List<Asset> childAssets2 = CS_ProductsComponentController.getChildAssets('TestParentAssetProduction', 'TestChildAsset');
                List<Asset> childAssets3 = CS_ProductsComponentController.getChildAssets('All', 'TestChildAsset');
                Map<String, Boolean> accessTypeMap = CS_ProductsComponentController.getAcpAccessType();
                Map<String, Boolean> caseAccessTypeMap = CS_ProductsComponentController.getCaseCreateAccessType();
                List<String> urgencyPickvals = CS_ProductsComponentController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_ProductsComponentController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_ProductsComponentController.getSeverityPickval();
                List<String> organizationCaseCreatino = CS_ProductsComponentController.getOrganizationForCaseCreation();
                List<Asset> childAssetsByOrganization = CS_ProductsComponentController.getChildAssetsByOrganization('TestParentAsset');
                

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_ProductsComponentController.getProductVersions(cAsset.Id);
               	Boolean assetODC = CS_ProductsComponentController.getAssetODC(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCase = CS_ProductsComponentController.saveCase(c, '1-Blocker', cAsset.Id, release.Id, true, 'High', 'Production');
				Test.stopTest();                
            }
        }
    }
}