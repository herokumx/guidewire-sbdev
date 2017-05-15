@isTest
public class TestCS_DisplayMilestoneCtrl {
	static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    static Entitlement ent;
    static CS_Milestone_Business_Hours__c mbh;
    
    static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
            // acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        
        List<Case> caseList = new List<Case>();
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '1-Blocker';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        caseList.add(c);
        insert caseList;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
 		
    }
    
    static testMethod void testDisplayMilestoneCtrl() {
        setupTestData();
        Test.startTest();
        Entitlement insertedEntitlement = [Select Id from Entitlement limit 1];
        ApexPages.StandardController con = new ApexPages.StandardController(insertedEntitlement);
        CS_DisplayMilestoneCtrl controllerExt = new CS_DisplayMilestoneCtrl(con);
        controllerExt.getdisplayMilestone();
        Test.stopTest();
    }
}