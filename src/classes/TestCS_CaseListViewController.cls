@isTest
public class TestCS_CaseListViewController {
    static User testUser;
    static User customerCommunityTestUser;
    static User partnerCommunityTestUser;
    static Account customerAcc;
    static Account partnerAcc;
    static List<Asset> parentAssetsCustomer;
    static List<Asset> parentAssetsHostedCustomer;
    static List<Asset> parentAssetsPartner;
    static Asset childAsset;
    static Product2 prod;
    static CS_Release__c release;
    static Contact contact;
    
    private static void setupCustomerTestData() {
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        contact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
        prod = CS_TestDataUtility.createProductRecord();
        release = CS_TestDataUtility.createRelease(prod);
        parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        parentAssetsHostedCustomer = CS_TestDataUtility.createParentAssetRecordHosted(customerAcc, true);
        // insert child assets for customer assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
        for (Integer i=0; i < parentAssetsHostedCustomer.size(); i++) {
            if (i < parentAssetsHostedCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsHostedCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsHostedCustomer[i], 'Implementation');
            }
        }
    }
    
    private static void setupPartnerTestData() {
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
    
    static testMethod void testCaseListViewControllerPartner() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                
                
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProduction', 'Open', 'Self');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                CS_CaseListViewController.getHasDefaultVersion(cAsset.Id,'Production');
                CS_CaseListViewController.getCurrentDevVersionStatus(cAsset.Id);
                CS_CaseListViewController.getInstallationPickval();
                CS_CaseListViewController.getNewEnvAffectedPickvals(true);
                CS_CaseListViewController.getNewSeverityPickval(true);
                CS_CaseListViewController.getAssetHosted('');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter1() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('All', 'Open', 'Self');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter2() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('All', 'All', 'Anyone');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter3() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProduction', 'Closed', 'Anyone');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter4() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProduction', 'Closed', 'Self');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter5() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProductionHosted');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProductionHosted', 'Open', 'Self');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'Hosted', '2-Major', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    static testMethod void testCaseListViewControllerCustomerCaseFilter6() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Partner');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            partnerCommunityTestUser = CS_TestDataUtility.createPartnerCommunityTestUser(cont);
            System.runAs(partnerCommunityTestUser) {
                Test.startTest();
                setupPartnerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProductionHosted');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProductionHosted', 'Open', 'Anyone');

                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = partnerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'Hosted', '1-Critical', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    
    /*
    static testMethod void testCaseListViewControllerCustomer() {
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc, 'Customer Support');
        User currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(cont);
            System.runAs(customerCommunityTestUser) {
                Test.startTest();
                setupCustomerTestData();
                User u = CS_CaseListViewController.getCurrentUser();
                String userId = CS_CaseListViewController.getUserId();
                List<String> urgencyPickvals = CS_CaseListViewController.getUrgencyPickvals();
                List<String> environmentalAffectedPickvals = CS_CaseListViewController.getEnvironmentalAffectedPickvals();
                List<String> severityPickval = CS_CaseListViewController.getSeverityPickval();
                Boolean caseCreationButtonAccess = CS_CaseListViewController.displayCaseCreationButton();
                List<String> parentAssets = CS_CaseListViewController.getParentAssets();
                List<String> organizationOnCaseCreation = CS_CaseListViewController.getOrganizationForCaseCreation();
                List<Asset> childAssets = CS_CaseListViewController.getChildAssets('TestParentAssetProduction');
                List<Case> cases = CS_CaseListViewController.getCases('TestParentAssetProduction', 'Open', 'Self');
                
                
                
                Asset cAsset = [Select Id from Asset where Name = 'TestChildAsset' limit 1];
                List<CS_Release__c> ProductVersions = CS_CaseListViewController.getProductVersions(cAsset.Id,'Production');
                // Boolean assetODC = CS_CaseListViewController.getAssetODC(cAsset.Id);
                String organizationByAsset = CS_CaseListViewController.getOrganizationByAsset(cAsset.Id);
                List<Case> assetCases = CS_CaseListViewController.getAssetCases(cAsset.Id);
                
                CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = customerCommunityTestUser.Id;
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
                Case c = new Case();
                String newCaseId = CS_CaseListViewController.saveCase(c,'OnPremise', '1-Blocker', cAsset.Id, release.Id, true, '' , '' , 'High','Defect', 'Production');
                Test.stopTest();
            }
        }
    }
    */
}