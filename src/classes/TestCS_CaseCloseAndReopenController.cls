@isTest
public class TestCS_CaseCloseAndReopenController {
    static Account customerAcc;
    static Contact customerContact;
    static User currentUsr;
    static Product2 prod;
    static User testUser;
    static CS_Asset_Contact_Permissions__c acp;
    
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
        
        // if (parentAssetsCustomer != null && parentAssetsCustomer.size() > 0) {
             // create acp
          //   acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
         //}
        
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
        //c.CS_Contact_Asset__c = acp.Id;
        caseList.add(c);
        
		Case c2 = new Case();
        c2.AssetId = childAsset.Id;
        c2.AccountId = customerAcc.Id;
        c2.RecordTypeId = rt.Id;
        c2.Status = 'Closed by customer';
        c2.ContactId = customerContact.Id;
        c2.Severity__c = '1-Blocker';
        c2.CS_Urgency__c = 'High';
        //c2.CS_Contact_Asset__c = acp.Id;
        c2.CS_Customer_Case_Closed_Date__c = Date.today().addDays(31);
        caseList.add(c2);
        
        insert caseList;

    }
    
    static testMethod void testCaseCloseAndReopen() {
        setupTestData();
        Test.startTest();
        Case c1 = [Select Id from Case where Status != 'Closed by customer' limit 1];
        Case getCase = CS_CaseCloseAndReopenController.getCase(c1.Id);
        String closeCase = CS_CaseCloseAndReopenController.closeCase(c1.Id);
        String reopenCase = CS_CaseCloseAndReopenController.reopenCase(c1.Id);
        
        Case c2 = [Select Id from Case where Status = 'Closed by customer' limit 1];
        Boolean disableReopen = CS_CaseCloseAndReopenController.disableReopen(c2.Id);
        
        Boolean readOnlyAccess =CS_CaseCloseAndReopenController.getReadOnlyAccess(c1.Id);
        Test.stopTest();
    }
    
}