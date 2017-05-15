@isTest
public class TestCS_CaseCustomEmailController {
	static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static User testUser2;
    static CS_Asset_Contact_Permissions__c acp;
    static CaseTeamRole ctr;
    static CaseTeamMember ctm;
    static Case c;
    static User customerUser;

    static void setupTestData() {  
        testUser = CS_TestDataUtility.createTestUser();
        customerUser = CS_TestDataUtility.createServiceTestUser();
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
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];

        c = new Case();
        c.AssetId = childAsset.Id;
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        c.CS_Carbon_Copy_Email_1__c = 'carbonCopy1@gmail.com';
        c.CS_Carbon_Copy_Email_2__c = 'carbonCopy2@gmail.com';
        c.CS_Carbon_Copy_Email_3__c = 'carbonCopy3@gmail.com';
        c.CS_Carbon_Copy_Email_4__c = 'carbonCopy4@gmail.com';
        c.CS_Carbon_Copy_Email_5__c = 'carbonCopy5@gmail.com';
        c.CS_Carbon_Copy_Email_6__c = 'carbonCopy6@gmail.com';
        c.CS_Carbon_Copy_Email_7__c = 'carbonCopy7@gmail.com';
        c.CS_Carbon_Copy_Email_8__c = 'carbonCopy8@gmail.com';
        c.CS_Carbon_Copy_Email_9__c = 'carbonCopy9@gmail.com';
        c.CS_Carbon_Copy_Email_10__c = 'carbonCopy10@gmail.com';
        insert c;
        
         // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Case Contact' and AccessLevel = 'Edit' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, testUser.Id, ctr.Id);
        
        EntitySubscription es = new EntitySubscription();
        es.ParentId = c.Id;
        es.SubscriberId = customerUser.Id;
        insert es;
        
    }
    
    static void setupTestData2() {
        testUser = CS_TestDataUtility.createTestUser();
        customerUser = CS_TestDataUtility.createServiceTestUser();
        prod = CS_TestDataUtility.createProductRecord();
        customerAcc = CS_TestDataUtility.createCustomerAccount();
        customerContact = CS_TestDataUtility.createContact(customerAcc, 'General Customer');
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
         //   acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
        //}
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];

        c = new Case();
        c.AssetId = childAsset.Id;
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        c.CS_Carbon_Copy_Email_1__c = 'carbonCopy1@gmail.com';
        c.CS_Carbon_Copy_Email_2__c = 'carbonCopy2@gmail.com';
        c.CS_Carbon_Copy_Email_3__c = 'carbonCopy3@gmail.com';
        c.CS_Carbon_Copy_Email_4__c = 'carbonCopy4@gmail.com';
        c.CS_Carbon_Copy_Email_5__c = 'carbonCopy5@gmail.com';
        c.CS_Carbon_Copy_Email_6__c = 'carbonCopy6@gmail.com';
        c.CS_Carbon_Copy_Email_7__c = 'carbonCopy7@gmail.com';
        c.CS_Carbon_Copy_Email_8__c = 'carbonCopy8@gmail.com';
        c.CS_Carbon_Copy_Email_9__c = 'carbonCopy9@gmail.com';
        c.CS_Carbon_Copy_Email_10__c = 'carbonCopy10@gmail.com';
        insert c;
        
         // query case team role       
        //ctr = [Select Id, Name from CaseTeamRole where Name = 'Follow the Sun' limit 1];
        //ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, customerUser.Id, ctr.Id);

        EntitySubscription es = new EntitySubscription();
        es.ParentId = c.Id;
        es.SubscriberId = testUser.Id;
        insert es;
        
    }
    
    static testMethod void testCaseCustomEmailController() {
        setupTestData();
        
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        CS_CaseCustomEmailController controllerExt = new CS_CaseCustomEmailController(con);
   
        Test.stopTest();
    }
    
    static testMethod void testCaseCustomEmailController2() {
        setupTestData2();

        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        CS_CaseCustomEmailController controllerExt = new CS_CaseCustomEmailController(con);
   
        Test.stopTest();
    }
    
}