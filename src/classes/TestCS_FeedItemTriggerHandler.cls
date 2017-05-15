@isTest			
public class TestCS_FeedItemTriggerHandler {
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
    static  Case insertedCase;
    
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
            // acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours2();
        
         acp = [Select Id from CS_Asset_Contact_Permissions__c where CS_Access_Type__c = 'Customer Support' limit 1];
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement2(childAsset, customerAcc);
		
        // query profile
        List<Profile> pfs = [Select Id, Name from Profile where Name in ('GW Customer Community', 'GW Services')];
        
        // insert customer setting gw profile
        
        CS_Profile_Id__c CS_Profile = new CS_Profile_Id__c();
        for (Profile p : pfs) {
            if (p.Name == 'GW Customer Community') {
                CS_Profile.CS_Customer_Profile_18__c = p.Id;
            } else if (p.Name == 'GW Services') {
                CS_Profile.CS_Service_Profile_18__c = p.Id;
            }
            
        }
        insert CS_Profile;
        
         //quey case
        insertedCase = [Select Id from Case limit 1];
        
        // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Support' and AccessLevel = 'Edit' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(insertedcase.Id, testUser.Id, ctr.Id);
       
		        
    }
    
    static void setupTestData2() {
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
        
         //if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
           //  acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
        commonSettings = CS_TestDataUtility.createGWCommentSettings();
        
        mbh = CS_TestDataUtility.createMileStoneBusinessHours2();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c where CS_Access_Type__c = 'Customer Support' limit 1];
        
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
       
        Case c = new Case();
        c.AssetId = childAsset.Id;
        
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        insert c;
        
        ent = CS_TestDataUtility.createEntitlement2(childAsset, customerAcc);
		
        // query profile
        List<Profile> pfs = [Select Id, Name from Profile where Name in ('GW Customer Community', 'GW Services')];
        
        // insert customer setting gw profile
        
        CS_Profile_Id__c CS_Profile = new CS_Profile_Id__c();
        for (Profile p : pfs) {
            if (p.Name == 'GW Customer Community') {
                CS_Profile.CS_Customer_Profile_18__c = p.Id;
            } else if (p.Name == 'GW Services') {
                CS_Profile.CS_Service_Profile_18__c = p.Id;
            }
            
        }
        insert CS_Profile;
        
         //quey case
        insertedCase = [Select Id from Case limit 1];
        
        // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'GW Watcher' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(insertedcase.Id, testUser.Id, ctr.Id);
        
        EntitySubscription es = new EntitySubscription();
        es.ParentId = insertedCase.Id;
        es.SubscriberId = testUser.Id;
        insert es;
		        
    }
    
    static testMethod void testFeedItemInsert() {
        setupTestData();
        
        System.runAs(testUser) {
			 Test.startTest();
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId = ca.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'ContentPost';
            fi.Visibility = 'AllUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Test.stopTest();
            
        }
        
    }
    
    static testMethod void testFeedItemInsert2() {
        setupTestData();
        System.runAs(testUser) {
            
            Test.startTest();
            
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId = ca.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'TextPost';
            fi.Visibility = 'AllUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Test.stopTest();
            
         }
        
    }
    
    static testMethod void testFeedItemInsert3() {
        	setupTestData();
            System.runAs(testUser) {
                Test.startTest();

                //quey case
                Case ca = [Select Id from Case limit 1];
            
            
                contentVersion = CS_TestDataUtility.createContentDocument();
                ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
                cdl = CS_TestDataUtility.createUploadDocument(ca);
            
                FeedItem fi = new FeedItem();
                fi.ParentId = ca.Id;
                fi.Body = 'TestFeedItem';
                fi.Type = 'ContentPost';
                fi.Visibility = 'InternalUsers';
                fi.RelatedRecordId = cv.Id;
                insert fi;
                
                Test.stopTest();
            
         }
        
    }
    
    static testMethod void testFeedItemBatchContext() {
        setupTestData();
        CS_ByPass__c byPass = CS_TestDataUtility.createByPass(testUser);
        System.runAs(testUser) {
            Test.startTest();
            
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId = ca.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'ContentPost';
            fi.Visibility = 'InternalUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Test.stopTest();
            
         }
    }
    
    static testMethod void testFeedItemDeleteWithAdminUser() {
        setupTestData();
        User adminUser = CS_TestDataUtility.createTestUser();
        System.runAs(adminUser) {
            Test.startTest();
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId = ca.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'TextPost';
            fi.Visibility = 'AllUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Id ii = UserInfo.getUserId();
            
            FeedItem insertedFI = [Select Id from FeedItem where createdDate >= today limit 1];
            Delete insertedFI;
            
            Test.stopTest();
            
        }
    }
    
    static testMethod void testFeedItemInsertWithAdminUser() {
        setupTestData();
        User adminUser = CS_TestDataUtility.createTestUser();
        System.runAs(adminUser) {
            Test.startTest();
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId = ca.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'TextPost';
            fi.Visibility = 'AllUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            Test.stopTest();
        }
    }
    
     static testMethod void testFeedItemEmail() {
        setupTestData2();
        //CS_ByPass__c byPass = CS_TestDataUtility.createByPass(testUser);
        System.runAs(testUser) {
           Test.startTest();
            CaseTeamMember ctmTest = [Select Id, ParentId, MemberId from CaseTeamMember limit 1];
            System.debug('ctmTest ===' + ctmTest);
            
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId =  insertedCase.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'TextPost';
            fi.Visibility = 'InternalUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Test.stopTest();
            
         }
    
    }
    
     static testMethod void testFeedItemEmail2() {
        setupTestData2();
        //CS_ByPass__c byPass = CS_TestDataUtility.createByPass(testUser);
        System.runAs(testUser) {
           Test.startTest();
            CaseTeamMember ctmTest = [Select Id, ParentId, MemberId from CaseTeamMember limit 1];
            System.debug('ctmTest ===' + ctmTest);
            
            //quey case
            Case ca = [Select Id from Case limit 1];
            
            
            contentVersion = CS_TestDataUtility.createContentDocument();
            ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
            cdl = CS_TestDataUtility.createUploadDocument(ca);
            
            FeedItem fi = new FeedItem();
            fi.ParentId =  insertedCase.Id;
            fi.Body = 'TestFeedItem';
            fi.Type = 'TextPost';
            fi.Visibility = 'AllUsers';
            fi.RelatedRecordId = cv.Id;
            insert fi;
            
            Test.stopTest();
            
         }
     }
}