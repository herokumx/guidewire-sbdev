@isTest
public class TestCS_Caseclose_Util {
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
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours();
    }
    
    static testMethod void testCloseSTR() {
        setupTestData();
        
        Test.startTest();
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
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
        caseList.add(c);
        insert caseList;
        
        //query case
        Case insertedCase = [Select Id from Case limit 1];
        
        CS_Request__c rq = new CS_Request__c();
        rq.CS_Case__c = insertedCase.Id;
        insert rq;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
        
        List<Case> cList = [Select Id from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
       
        CS_Caseclose_Util.CloseSTR(caseIds);
        Test.stopTest();
    }
    
    static testMethod void testCloseCMS() {
        setupTestData();
        
        Test.startTest();
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
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

        caseList.add(c);
        insert caseList;
        
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
        
        //query case
        Integer Before_Milesttone =0;
        Integer After_Milestone;
        Case insertedCase = [Select Id,Status from Case limit 1];
        InsertedCase.Status='Closed';
        Update InsertedCase;
        List<CaseMileStone> cmsList = [Select id from CaseMileStone where CaseId =:InsertedCase.id ];
        //System.assertEquals(Before_Milesttone,After_Milestone,'Case Milestone Not Closed');
        /*
        CS_Request__c rq = new CS_Request__c();
        rq.CS_Case__c = insertedCase.Id;
        insert rq;
 
        List<Case> cList = [Select Id from Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case ca : cList) {
            caseIds.add(ca.Id);
        }
        
        CS_Caseclose_Util.CloseCMS(caseIds);
        */
        Test.stopTest();
    }
    
    static testMethod void testCloseRestorationMS() {
        setupTestData();
        testUser = CS_TestDataUtility.createTestUser();
        System.runAs(testUser) {
             Test.startTest();
           // Map<Id, Case> cIds = new Map<Id, Case>([select id from case]);
            //CS_Caseclose_Util.CloseRestorationMS(cIds.keySet());
            
            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
			
            System.debug('++++++childAsset ' + childAsset.Id);
            ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
            System.debug('++++ent assetId ' + ent.AssetId + 'entitlement Id ' + ent.Id);
            
            List<Case> caseList = new List<Case>();
            Case c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.Severity__c = '2-Blocker';
            c.CS_Urgency__c = 'High';
            caseList.add(c);
            insert caseList;
            
            List<Case> caseListToUpdate1 = new List<Case>();
            List<Case> cList1 = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case];
            Set<Id> caseIds = new Set<Id>();
            for (Case ca : cList1) {
                System.debug('+++++case assetId ' + ca.AssetId + ' | case entitle Id ' + ca.EntitlementId + ' | case businesshours ' + ca.BusinessHoursId);
                caseIds.add(ca.Id);
                ca.Severity__c = '1-Blocker';
                ca.CS_Severity_Change_Reason__c = 'Other';
				//ca.CS_Restoration_Milestone_Completed__c = true;
                caseListToUpdate1.add(ca);
                
            }
            update caseListToUpdate1;
            
            List<Case> caseListToUpdate2 = new List<Case>();
            List<Case> cList2 = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case];
            Set<Id> caseIds2 = new Set<Id>();
            for (Case ca : cList2) {
                System.debug('+++++case assetId ' + ca.AssetId + ' | case entitle Id ' + ca.EntitlementId + ' | case businesshours ' + ca.BusinessHoursId);
                caseIds2.add(ca.Id);
				ca.CS_Restoration_Milestone_Completed__c = true;
                caseListToUpdate2.add(ca);
                
            }
            update caseListToUpdate2;
            
            
            Map<Id, Case> updateCases = new Map<Id, Case> ([Select Id from Case where CS_Restoration_Milestone_Completed__c = true]);
            
            List<CaseMileStone> cmsList = [select MilestoneType.name,ActualElapsedTimeInDays, ActualElapsedTimeInHrs, ActualElapsedTimeInMins, BusinessHoursId, CaseId, CompletionDate, CreatedById, CreatedDate, ElapsedTimeInDays, ElapsedTimeInHrs, ElapsedTimeInMins, Id, IsCompleted, IsDeleted, IsViolated, LastModifiedById, LastModifiedDate, MilestoneTypeId, StartDate, StoppedTimeInDays, StoppedTimeInHrs, StoppedTimeInMins, SystemModstamp, TargetDate, TargetResponseInDays, TargetResponseInHrs, TargetResponseInMins, TimeRemainingInMins, TimeSinceTargetInMins from CaseMilestone
 where caseId in :caseIds and MilestoneType.name like '%Restoration%'];
            System.debug('cmsList ' + cmsList);
           CS_Caseclose_Util.CloseRestorationMS(caseIds2);
           Test.stopTest();
            
        }
    }
    
}