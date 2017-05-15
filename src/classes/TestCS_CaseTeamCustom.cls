@isTest
private class TestCS_CaseTeamCustom {
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
    static User customerCommunityTestUser;

    static testMethod void TestCS_CaseTeamCustom() {
		currentUsr = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()];

        System.runAs(currentUsr) {
            customerAcc = CS_TestDataUtility.createCustomerAccount();
        	customerContact = CS_TestDataUtility.createContact(customerAcc, 'Customer Support');
            prod = CS_TestDataUtility.createProductRecord();
            customerCommunityTestUser = CS_TestDataUtility.createCustomerCommunityTestUser(customerContact);
            // insert parent asset for customer account
            Asset parentAssetsCustomer = CS_TestDataUtility.createParentAsset(customerAcc, true);
                
            // insert child assets
            
            CS_TestDataUtility.createChildAssetRecord(customerAcc, prod, parentAssetsCustomer, 'Implementation');
            
            //query asset
            Asset childAsset = [Select Id, CS_Is_Active__c, ParentId from Asset where CS_Record_Type_Name__c = 'Child Asset' and ParentId != null limit 1];
            System.debug('=====childAssetId ==== ' + childAsset.Id + ' |===parentId ==== ' + childAsset.ParentId);
            // query case record type
            RecordType rt = [Select Name, developername from RecordType where sobjecttype = 'Case' and Name = 'Customer Support'];
    
            c = new Case();
            c.AssetId = childAsset.Id;
            c.AccountId = customerAcc.Id;
            c.RecordTypeId = rt.Id;
            c.ContactId = customerContact.Id;
            c.Severity__c = '3-Major';
            c.CS_Urgency__c = 'High';
            //c.CS_Contact_Asset__c = acp.Id;
    
            insert c;
            
            Test.startTest();
            
            ApexPages.StandardController con = new ApexPages.StandardController(c);
            CS_CaseTeamCustom controllerExt = new CS_CaseTeamCustom(con);
            
            List<CaseTeamMember> caseTeamMembers = controllerExt.getCaseContacts();
            Map<Id, String> userMap = controllerExt.getUserMap();
            
            Test.stopTest();
        }

    }
}