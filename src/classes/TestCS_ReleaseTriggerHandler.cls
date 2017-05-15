@isTest
public class TestCS_ReleaseTriggerHandler {
    private static void setupTestData() {
        List<GW_Common_Settings__c> commonSettings = CS_TestDataUtility.createGWCommentSettings();
        Account customerAcc = CS_TestDataUtility.createCustomerAccount();
        Account partnerAcc = CS_TestDataUtility.createPartnerAccount();
        Product2 prod = CS_TestDataUtility.createProductRecord();
        
        RecordType rt = [Select Id, Name from RecordType where sobjecttype = 'CS_Release__c' and Name = 'Standard Products' limit 1];
        CS_Release__c release = new CS_Release__c(CS_Product__c = prod.Id,
                                                 CS_IsActive__c = false,
                                                 CS_Major_Release_version__c = '8',
                                                 CS_Minor_Release_Version__c ='1',
                                                 RecordTypeId = rt.Id);
        insert release;
        
        ContentVersion contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        ContentDocumentLink cdl = CS_TestDataUtility.createContentDocumentLink(cv.ContentDocumentId, release.Id);
        
        // insert parent asset for customer account
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecord(customerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsCustomer.size(); i++) {
            if (i < parentAssetsCustomer.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer[i], 'Implementation');
            }
        }
        
        // insert parent asset for partner account
        List<Asset> parentAssetsPartner = CS_TestDataUtility.createParentAssetRecord(partnerAcc, true);
        
        // insert child assets
        for (Integer i=0; i < parentAssetsPartner.size(); i++) {
            if (i < parentAssetsPartner.size() - 1) {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Prospect');
            } else {
                CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsPartner[i], 'Certification');
            }
        }
    }
    
    static testMethod void testReleaseTriggerHandler() {
        setupTestData();
        Test.startTest();
        // query the inserted release
        CS_Release__c insertedRelease = [Select Id, CS_Major_Release_version__c from CS_Release__c limit 1];
        insertedRelease.CS_IsActive__c = true;
        update insertedRelease;
        Test.stopTest();
    }
}