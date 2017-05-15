@isTest(SeeAllData=false)
public class Test_CaseMilestoneCalculationHostedAsset {
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
        List<Asset> parentAssetsCustomer = CS_TestDataUtility.createParentAssetRecordHosted(customerAcc, true);
            
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
            // acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         // }
        
         mbh = CS_TestDataUtility.createMileStoneBusinessHours('3sh','Initial Response (3S)','Hosted Standard', 1, '3–Minor');
         mbh = CS_TestDataUtility.createMileStoneBusinessHours('4s','Initial Response (4S)','Hosted Standard', 1, '3-Major');
         mbh = CS_TestDataUtility.createMileStoneBusinessHours('3sd','Initial Response (3S)','Default', 1, '3-Major');
         mbh = CS_TestDataUtility.createMileStoneBusinessHours('4sd','Initial Response (4S)','Default', 1, '4-Minor');
         
         //query MileStone
        // CaseMileStone cms = [Select Id, MilestoneType.Name from CaseMileStone limit 1];
        
        //query entitlement
        // Entitlement insertedEnt = [Select Id, Name from Entitlement limit 1];
        
        List<CS_Milestone_Business_Hours__c> mbhListToInsert = new List<CS_Milestone_Business_Hours__c>();
        CS_Milestone_Business_Hours__c mbh1 = new CS_Milestone_Business_Hours__c();
        mbh1.Name = 'TestMBH1';
        mbh1.CS_Business_Days__c = 5;
        mbh1.CS_Entitlement_Process_Name__c = 'Hosted Standard';
        mbh1.CS_Severity__c = '3-Major';
        mbh1.CS_Milestone_Name__c = 'Initial Response (3S)';
        mbhListToInsert.add(mbh1);
        
        // List<CS_Milestone_Business_Hours__c> mbhListToInsert = new List<CS_Milestone_Business_Hours__c>();
        // CS_Milestone_Business_Hours__c mbh3 = new CS_Milestone_Business_Hours__c();
        // mbh3.Name = 'TestMBH3';
        // mbh3.CS_Entitlement_Process_Name__c = 'Default';
        // mbh3.CS_Business_Days__c = 5;
        // mbh3.CS_Severity__c = '3-Major';
        // mbh3.CS_Milestone_Name__c = 'Initial Response (3S)';
        // mbhListToInsert.add(mbh3);
        
        CS_Milestone_Business_Hours__c mbh2 = new CS_Milestone_Business_Hours__c();
        mbh2.Name = 'TestMBH2';
        mbh2.CS_Entitlement_Process_Name__c = 'Hosted Standard';
        mbh2.CS_Business_Days__c = 10;
        mbhListToInsert.add(mbh2);
        
         
        
        insert mbhListToInsert;
        
        // Support_Business_Hours__c bizHrs = [SELECT Business_Hours_End_mm__c,Business_Hours_End__c,Business_Hours_Start_mm__c,Business_Hours_Start__c,Type_of_support__c FROM Support_Business_Hours__c where Type_of_support__c = 'Hosted Asset' ];
        
        Support_Business_Hours__c sbh = new Support_Business_Hours__c();
        sbh.Business_Hours_End_mm__c = 0;
        sbh.Business_Hours_End__c = 17;
        sbh.Business_Hours_Start_mm__c = 0;
        sbh.Business_Hours_Start__c = 8;
        sbh.Type_of_support__c = 'Hosted Asset';
        sbh.Name = 'Hosted Asset';
        
        insert sbh;
        
        //query asset
        Asset childAsset = [Select Id, CS_Is_Active__c from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
        
        acp = [Select Id from CS_Asset_Contact_Permissions__c limit 1];
        // query case record type
        RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
        
        // create entitlement
        ent = CS_TestDataUtility.createEntitlement(childAsset, customerAcc,'Hosted Standard');
        system.debug('%%%%%%%% Entitlement Business Hours Id:  ' + ent.BusinessHoursId);
        CS_ByPass__c byPass = new CS_ByPass__c();
                byPass.Name = 'CS_Disable_ValidationRule__c';
                byPass.SetupOwnerId = Userinfo.getUserId();
                byPass.CS_Disable_ValidationRule__c = true;
                byPass.CS_Disable_Trigger__c = true;
                insert byPass;
        
        List<Case> caseList = new List<Case>();
        
        ent = [SELECT Id,BusinessHoursId,SlaProcessId from Entitlement LIMIT 1 ];
        
        for(Integer i = 0; i < 1 ; i ++){
            Case c = new Case();
            c.AssetId = childAsset.Id;
        c.Subject = 'This is a test for ' + i;
        c.AccountId = customerAcc.Id;
        c.RecordTypeId = rt.Id;
        c.ContactId = customerContact.Id;
        c.Severity__c = '3-Major';
        c.CS_Urgency__c = 'High';
        c.CS_Contact_Asset__c = acp.Id;
        c.EntitlementId = ent.Id;
        c.Entitlement = ent;
        // c.Entitlement.BusinessHoursId = ent.BusinessHoursId;
        // c.Entitlement.SlaProcess = ent.SlaProcess;
        c.BusinessHoursId = ent.BusinessHoursId;
        caseList.add(c);
        
        }
        
        // Integer duration = getDuration(c.Entitlement.SlaProcess.Name, 
                                            // mt.Name, c.Severity__c);
        
        insert caseList;
        
        for(case ca : caseList){
                system.debug('############### Entitlement is  : ' + ca.EntitlementId + '   ::  ' + ca.Entitlement.BusinessHoursId);
        }
        
        Integer i = 0;
        Integer j = 0;
        
        
        for(case ca : caseList){
                system.debug('###### Current created Date : ' + ca.createdDate);
                Test.setCreatedDate(ca.Id, system.Now().addHours(i).addDays(j - 1));
                
                
                i = i - 6;
                j = j - 1;
        }
        
        caseList = [SELECT Subject,AccountId,RecordTypeId,ContactId,Severity__c,CS_Urgency__c,CS_Contact_Asset__c,EntitlementId,BusinessHoursId,CreatedDate from Case];
        
        for(case ca : caseList){
                system.debug('###### Changed created Date : ' + ca.createdDate + '      ######system.Now().addHours(i) ' + system.Now().addHours(i));
        }
        
        
        
        
    }
    
    static testMethod void testcalculateMilestoneTriggerTime() {
         setupTestData();
         Test.startTest();
        
       
        
        List<Case> caseList = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case];
        // Case c = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case limit 1];
        
        for(Case c : caseList){
            // CaseMileStone cms = [Select MileStoneTypeId from CaseMileStone where CaseId=: c.Id limit 1];
        string myMilestoneTypeId = '';
        
        system.debug('############### Entitlement is  : ' + c.EntitlementId );
        // if(cms == null)
            myMilestoneTypeId = '55734000000PDVvAAO';
        // else
            // myMilestoneTypeId = cms.MileStoneTypeId;
        
            CS_CaseMilestoneCalculationHostedAsset cmsCalculation = new CS_CaseMilestoneCalculationHostedAsset();
            cmsCalculation.calculateMilestoneTriggerTime(c.Id, myMilestoneTypeId);
        }
        
        Test.stopTest();
    }
    
    static testMethod void testCustomMilestoneCalculation() {
       setupTestData();
        
       Test.startTest();
       
        
        
        Case c = [Select Id, AssetId, EntitlementId, BusinessHoursId, CS_Restoration_Milestone_Completed__c from Case limit 1];
        List<CaseMileStone> cms = [Select MileStoneTypeId from CaseMileStone where CaseId=: c.Id];
        
        system.debug('############## RP Start Debug' + cms);
        
        // CaseMileStone cms = [Select MileStoneTypeId from CaseMileStone where CaseId=: c.Id limit 1];
        string myMilestoneTypeId = '';
        
        // if(cms != null || cms.size() > 0)
            // myMilestoneTypeId = cms.get(0).MileStoneTypeId;
        // else
            myMilestoneTypeId = '55734000000PDVvAAO';
            
        
        
        CS_CaseMilestoneCalculationHostedAsset cmsCalculation = new CS_CaseMilestoneCalculationHostedAsset();
        cmsCalculation.customMilestoneCalculation(c.Id, myMilestoneTypeId, true);
        Test.stopTest();
    }
}