@isTest
public class TestCS_CaseMilestoneCalculation {
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
          //   acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours();
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        
        // create entitlement
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc);
        
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
        
        //query MileStone
        CaseMileStone cms = [Select Id, MilestoneType.Name from CaseMileStone limit 1];
        
        //query entitlement
        Entitlement insertedEnt = [Select Id, Name from Entitlement limit 1];
        
        List<CS_Milestone_Business_Hours__c> mbhListToInsert = new List<CS_Milestone_Business_Hours__c>();
        CS_Milestone_Business_Hours__c mbh1 = new CS_Milestone_Business_Hours__c();
        mbh1.Name = 'TestMBH1';
        mbh1.CS_Entitlement_Process_Name__c = insertedEnt.Name;
        mbh1.CS_Severity__c = '1-Blocker';
        mbh1.CS_Milestone_Name__c = cms.MilestoneType.Name;
        mbhListToInsert.add(mbh1);
        
        CS_Milestone_Business_Hours__c mbh2 = new CS_Milestone_Business_Hours__c();
        mbh2.Name = 'TestMBH2';
        mbh2.CS_Entitlement_Process_Name__c = 'Default';
        mbh2.CS_Business_Days__c = 10;
        mbhListToInsert.add(mbh2);
        
		insert mbhListToInsert;
    }
    
    static testMethod void testcalculateMilestoneTriggerTime() {
        setupTestData();
        Test.startTest();
        CaseMileStone cms = [Select MileStoneTypeId from CaseMileStone limit 1];
        
        Case c = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case limit 1];
           
        CS_CaseMilestoneCalculation cmsCalculation = new CS_CaseMilestoneCalculation();
        cmsCalculation.calculateMilestoneTriggerTime(c.Id, cms.MilestoneTypeId);
        Test.stopTest();
    }
    
    static testMethod void testCustomMilestoneCalculation() {
        setupTestData();
        Test.startTest();
        CaseMileStone cms = [Select MileStoneTypeId from CaseMileStone limit 1];
        
        Case c = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case limit 1];
           
        CS_CaseMilestoneCalculation cmsCalculation = new CS_CaseMilestoneCalculation();
        cmsCalculation.customMilestoneCalculation(c.Id, cms.MilestoneTypeId, true);
        Test.stopTest();
    }
}