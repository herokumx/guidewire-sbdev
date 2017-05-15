@isTest
public class TestUTL_CS_CaseTeamMemberUtility {
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static CaseTeamRole ctr;
    static CS_Asset_Contact_Permissions__c acp;
    
    static void setupTestData() {
        // query current test user
        currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];       
        
        // insert bypass custom setting to disable validation rule
        /*
        CS_ByPass__c byPassTrigger = new CS_ByPass__c();
        byPassTrigger.Name = 'CS_Disable_Trigger__c';
        byPassTrigger.CS_Disable_Trigger__c = true;
        byPassTrigger.SetupOwnerId = currentUsr.Id;
        insert byPassTrigger;
        */
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
        
        //ctr = CS_TestDataUtility.createCaseTeamRole('Customer Support', 'Edit');
          ctr = [Select Id, Name, AccessLevel from CaseTeamRole where Name = 'Customer Support' limit 1];  
    }
    
    static testMethod void testCreateCaseTeamMember() {
        setupTestData();
        System.runAs(currentUsr) {
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            
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
            c.CS_Contact_Asset__c = acp.Id; 
            caseList.add(c);
            insert caseList;
            
            Set<String> accessTypes = new Set<String>();
            accessTypes.add('Customer Support');
            
            List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, Name, CS_Contact__c,CS_Asset__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
            
            Test.startTest();
            UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(caseList, accessTypes, acpList);
            Test.stopTest();
        }
    }
    
    static testMethod void testUpdateCaseTeamMember() {
        setupTestData();
        System.runAs(currentUsr) {
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            
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
            c.CS_Contact_Asset__c = acp.Id; 
            caseList.add(c);
            insert caseList;
            
            Set<String> accessTypes = new Set<String>();
            accessTypes.add('Customer Support');
            
            List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, Name, CS_Contact__c,CS_Asset__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
            
            // query just inserted case
            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [Select Id from Case];
            for (Case ca : cases) {
                caseIds.add(ca.Id);
            }
            
            List<User> usrs = [Select Id from User];
            Set<Id> userIds = new Set<Id>();
            for (User u : usrs) {
                userIds.add(u.Id);
            }
            
            Test.startTest();
            UTL_CS_CaseTeamMemberUtility.updateCaseTeamMember(caseIds, userIds, accessTypes);
            Test.stopTest();
        }
    }
    
    static testMethod void testCreateCaseTeamMember2() {
        setupTestData();
        System.runAs(currentUsr) {
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            
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
            c.CS_Contact_Asset__c = acp.Id; 
            caseList.add(c);
            insert caseList;
            
            Set<String> accessTypes = new Set<String>();
            accessTypes.add('Customer Support');
            
            List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, Name, CS_Contact__c,CS_Asset__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
            
            // query just inserted case
            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [Select Id from Case];
            for (Case ca : cases) {
                caseIds.add(ca.Id);
            }
            
            List<User> usrs = [Select Id from User];
            Set<Id> userIds = new Set<Id>();
            for (User u : usrs) {
                userIds.add(u.Id);
            }
            
            Test.startTest();
            UTL_CS_CaseTeamMemberUtility.CreateCaseTeamMember(caseIds, userIds, accessTypes);
            Test.stopTest();
        }
    }
    
    static testMethod void testDeleteCaseTeamMember() {
        setupTestData();
        System.runAs(currentUsr) {
            User customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            
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
            c.CS_Contact_Asset__c = acp.Id; 
            caseList.add(c);
            insert caseList;
            
            Set<String> accessTypes = new Set<String>();
            accessTypes.add('Customer Support');
            
            List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, Name, CS_Contact__c,CS_Asset__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c];
            
            // query just inserted case
            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [Select Id from Case];
            for (Case ca : cases) {
                caseIds.add(ca.Id);
            }
            
            List<User> usrs = [Select Id from User];
            Set<Id> userIds = new Set<Id>();
            for (User u : usrs) {
                userIds.add(u.Id);
            }
            
            Test.startTest();
            UTL_CS_CaseTeamMemberUtility.deleteCaseTeamMember(caseIds, userIds);
            Test.stopTest();
        }
    }
}