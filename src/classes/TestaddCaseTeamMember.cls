@isTest
public class TestaddCaseTeamMember {
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

    static void setupTestData() {  
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
          //  acp = CS_TestDataUtility.createACP(parentAssetsCustomer[0], customerContact, 'Customer Support', true);
       // }
        
        
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
        //c.CS_Contact_Asset__c = acp.Id;

        insert c;
        
         // query case team role       
        ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Case Contact' and AccessLevel = 'Edit' limit 1];
        
        ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, testUser.Id, ctr.Id);
        
         // query profile
        Profile pf = [Select Id, Name from Profile where Name = 'System Administrator' limit 1];
        
        // insert customer setting gw profile
        
        CS_GW_Profile__c CS_Profile = new CS_GW_Profile__c();
        CS_Profile.Name = 'TestProfile';
        CS_Profile.Profile_Id_18__c = pf.Id;
        CS_Profile.CS_CTM_Search__c = true;
        insert CS_Profile;
    }
    
    static testMethod void testAddCaseTeamMember() {
        setupTestData();
        
        Test.startTest();
        CaseTeamMember insertedCTM = [Select Id, MemberId, ParentId from CaseTeamMember limit 1];
        system.debug('===ctm test=== ' + insertedCTM);
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        addCaseTeamMember controllerExt = new addCaseTeamMember(con);
        controllerExt.addRow();
        
           
        PageReference pr = controllerExt.save();
        
        Id contactId = controllerExt.getContactID(customerContact.Id);       
        CS_Asset_Contact_Permissions__c getAcp = controllerExt.getACP(customerContact.Id);

        
        Test.stopTest();
    }
    
    static testMethod void testAddCaseTeamMember2() {
        setupTestData();
        
        Test.startTest();
        CaseTeamMember insertedCTM = [Select Id, MemberId, ParentId from CaseTeamMember limit 1];
        system.debug('===ctm test=== ' + insertedCTM);
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        addCaseTeamMember controllerExt = new addCaseTeamMember(con);
        controllerExt.addRow();
        PageReference pr2 = controllerExt.save();
        Id contactId = controllerExt.getContactID(customerContact.Id);       
        CS_Asset_Contact_Permissions__c getAcp = controllerExt.getACP(customerContact.Id);
              
        ApexPages.currentPage().getParameters().put('rowIndex', '0');
        controllerExt.deleteRow(); 
        PageReference pr7 = controllerExt.save();      

        Test.stopTest();
    }
    
    static testMethod void testAddCaseTeamMember3() {
        setupTestData();
        
        Test.startTest();
        CaseTeamMember insertedCTM = [Select Id, MemberId, ParentId from CaseTeamMember limit 1];
        system.debug('===ctm test=== ' + insertedCTM);
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        addCaseTeamMember controllerExt = new addCaseTeamMember(con);
        controllerExt.addRow();
        PageReference pr2 = controllerExt.save();  
        Id contactId = controllerExt.getContactID(customerContact.Id);       
        CS_Asset_Contact_Permissions__c getAcp = controllerExt.getACP(customerContact.Id);              
       /*
        ApexPages.currentPage().getParameters().put('rowIndex', '0');
        controllerExt.deleteRow();         
         */
        ApexPages.currentPage().getParameters().put('rowNo', '0');
        controllerExt.changeUserRole(); 
       // controllerExt.addRow();
        PageReference pr3 = controllerExt.save();
        Test.stopTest();
    }
    
    static testMethod void testAddCaseTeamMember4() {
        setupTestData();
       
        CaseTeamMember insertedCTM = [Select Id, MemberId, ParentId from CaseTeamMember limit 1];
        system.debug('===ctm test=== ' + insertedCTM);
        ApexPages.StandardController con = new ApexPages.StandardController(c);
        addCaseTeamMember controllerExt = new addCaseTeamMember(con);
        controllerExt.addRow();
        PageReference pr = controllerExt.save();  
        Id contactId = controllerExt.getContactID(customerContact.Id);       
        CS_Asset_Contact_Permissions__c getAcp = controllerExt.getACP(customerContact.Id);              

        Test.startTest();
        controllerExt.addRow();
        PageReference pr2 = controllerExt.save();
        
        

        Test.stopTest();
    }
    
    static testMethod void testAddCaseTeamMember5() {
       
        
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
            Case insertedCase = [Select Id, AssetId, Asset.ParentId from Case limit 1];
            
             ApexPages.StandardController con11 = new ApexPages.StandardController(insertedCase);
            addCaseTeamMember controllerExt5 = new addCaseTeamMember(con11);
            controllerExt5.userRole = 'testRole';
            PageReference pr4 = controllerExt5.save();
            controllerExt5.getContactId(null);
            controllerExt5.getContactId(null);
            
             // query case team role       
            //ctr = [Select Id, Name from CaseTeamRole where Name = 'Customer Case Contact' and AccessLevel = 'Edit' limit 1];
            
            //ctm = CS_TestDataUtility.createCaseTeamMember(c.Id, customerCommunityTestUser.Id, ctr.Id);
            
             // query profile
            Profile pf = [Select Id, Name from Profile where Name = 'System Administrator' limit 1];
            
            // insert customer setting gw profile
            
            CS_GW_Profile__c CS_Profile = new CS_GW_Profile__c();
            CS_Profile.Name = 'TestProfile';
            CS_Profile.Profile_Id_18__c = pf.Id;
            CS_Profile.CS_CTM_Search__c = true;
            insert CS_Profile;    
            
            Test.startTest();
            List<CS_Asset_Contact_Permissions__c> acps = [Select Id, CS_Asset__c, CS_Access_Type__c, CS_Contact__c from CS_Asset_Contact_Permissions__c];
            System.debug('====acps==== ' + acps);
            CaseTeamMember insertedCTM = [Select Id, MemberId, ParentId,TeamRoleId from CaseTeamMember limit 1];
            system.debug('===ctm test=== ' + insertedCTM);
            
            ApexPages.StandardController con = new ApexPages.StandardController(insertedCase);
            addCaseTeamMember controllerExt = new addCaseTeamMember(con);
            controllerExt.addRow();
             ApexPages.StandardController con2 = new ApexPages.StandardController(insertedCase);
            addCaseTeamMember controllerExt2 = new addCaseTeamMember(con2);
            controllerExt2.addRow();
        
            //Id contactId = controllerExt.getContactID(customerContact.Id);       
            //CS_Asset_Contact_Permissions__c getAcp = controllerExt.getACP(customerContact.Id);              
           
            ApexPages.currentPage().getParameters().put('rowIndex', '0');
           // controllerExt.deleteRow();         
            PageReference pr2 = controllerExt.save();  
            
            Test.stopTest();
        }
    }
    
}