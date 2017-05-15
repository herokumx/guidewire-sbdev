@isTest
public class TestCS_CaseTeamController {
	static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static User customerCommunityTestUser;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    static ContentVersion contentVersion;
    static ContentDocumentLink cdl;
    static List<GW_Common_Settings__c> commonSettings;
    static Entitlement ent;
    static CS_Milestone_Business_Hours__c mbh;
    static CaseTeamRole ctr;
    static CaseTeamMember ctm;
    static Case c = new Case();
    
    static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        testUser = CS_TestDataUtility.createServiceTestUser();
        
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
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
        
        // if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
           //  acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       // query acp
       acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
       
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        
         //quey case
        Case insertedCase = [Select Id from Case limit 1];
        
        // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Case Contact' and AccessLevel = 'Edit' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(insertedcase.Id, testUser.Id, ctr.Id);
    }
    
    static testMethod void testCaseTeamController() {
        setupTestData();
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        CS_CaseTeamController controllerExt = new CS_CaseTeamController(con);
        List<CaseTeamMember> ctmList = controllerExt.getMembers();
        Test.stopTest();
    }
    
}