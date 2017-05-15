@isTest()
public class CS_TestDataUtility {
    
    public static User createTestUser() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*10000));
        String uniqueName = orgId + dateString + randomInt;
        Profile pfAdmin = [select Id from profile where Name = 'System Administrator'];      
        
        User u = new User();
        u.FirstName='Admin1';
        u.LastName='Test';
        u.ProfileId=pfAdmin.Id;
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey='UTF-8';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.Alias = 'alias';
        u.Email = 'testadmin@email.com';
        //u.UserRoleId = role.Id;
        
        insert u;
        
        return u;
    }
    public static User createServiceTestUser() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*10000));
        String uniqueName = orgId + dateString + randomInt;
        Profile pfAdmin = [select Id from profile where Name = 'GW Services'];
        //UserRole role = [Select Id from UserRole where name ='GForce Customer User' limit 1];
        User u = new User();
        u.FirstName='Service1';
        u.LastName='Test';
        u.ProfileId=pfAdmin.Id;
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey='UTF-8';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.Alias = 'alias';
        u.Email = 'testService@email.com';
        u.PortalRole = 'Worker';
        //u.UserRoleId = role.Id;
        
        insert u;
        
        return u;
    }

    public static User createCustomerCommunityTestUser(Contact contact) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*10000));
        String uniqueName = orgId + dateString + randomInt;
        RecordType rt = [Select Id, Name from RecordType where Name = 'Customer' and sObjectType = 'Account' limit 1];
       /*
        Account acc = new Account(Name='TestCustomerAccount',
                                 RecordTypeId = rt.Id,
                                 CS_Account_Short_Name__c = 'TCA');
        insert acc;
        */

        Profile pfAdmin = [select Id from profile where Name = 'GW Customer Community' and UserType='PowerCustomerSuccess'];
        //contact newcts=[Select Account.name from Contact where id =:contact.id];
        //system.debug('+++++++++Account++++++++++'+newcts.Account.name.);

        //UserRole role = [Select Id, PortalType,name, PortalAccountId From UserRole where PortalType =:'CustomerPortal' and Name = 'ABC Company (RNT test) Customer User' limit 1];
        //System.debug('role+++++++ ' + role);
        User u = new User();
        u.FirstName='Test';
        u.LastName='Contact';
        u.ProfileId=pfAdmin.Id;
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey='UTF-8';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.Alias = 'CusComm';
        u.Email = 'testcommunity@email.com';
        u.ContactId = contact.Id;
        //u.UserRoleId = role.Id;
        u.PortalRole = 'Worker';
      
        
        insert u;
        
        return u;
    }
    
    public static User createPartnerCommunityTestUser(Contact contact) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*10000));
        String uniqueName = orgId + dateString + randomInt;
        Profile pfAdmin = [select Id from profile where Name = 'GW Partner Community' and UserType='PowerPartner'];
        UserRole role = [Select Id, PortalType, PortalAccountId From UserRole where PortalType =:'CustomerPortal' limit 1];

        User u = new User();
        u.FirstName='Test';
        u.LastName='Contact';
        u.ProfileId=pfAdmin.Id;
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey='UTF-8';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.Alias = 'CusComm';
        u.Email = 'testcommunity@email.com';
        u.ContactId = contact.Id;
        //u.UserRoleId = role.Id;
        u.PortalRole = 'Worker';
      
        
        insert u;
        
        return u;
    }
    
    public static Account createCustomerAccount() {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Customer' and sObjectType = 'Account' limit 1];
        Account acc = new Account(Name='TestCustomerAccount',
                                 RecordTypeId = rt.Id,
                                 CS_Account_Short_Name__c = 'TCA');
        insert acc;

        return acc;
    }
    
    public static Account createPartnerAccount() {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Partner' and sObjectType = 'Account' limit 1];
        Account acc = new Account(Name='TestPartnerAccount',
                                 RecordTypeId = rt.Id,
                                 CS_Account_Short_Name__c = 'TPA');
        insert acc;

        return acc;
    }
    
    public static Account createProspectAccount() {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Prospect' and sObjectType = 'Account' limit 1];
        Account acc = new Account(Name='TestProspectAccount',
                                 RecordTypeId = rt.Id,
                                 CS_Account_Short_Name__c='TProsAc');
        insert acc;

        return acc;
    }

    public static Contact createContact(Account acc, String accessType) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Support' and sObjectType = 'Contact' limit 1];

        Contact con = new Contact(FirstName='Test', 
                                  LastName='Contact', 
                                  AccountId = acc.Id,
                                  RecordTypeId = rt.Id, 
                                  No_longer_with_firm__c = false,
                                  CS_Access_Type__c = accessType,
                                  Email = 'testContact@gmail.com');
        insert con;

        return con;
    }
    
     public static Contact createProspectContact(Account acc) {
        RecordType rt = [Select Id, Name from RecordType where DeveloperName = 'Business_Contact' and sObjectType = 'Contact' limit 1];

        Contact con = new Contact(FirstName='Test', 
                                  LastName='Contact', 
                                  AccountId = acc.Id,
                                  RecordTypeId = rt.Id, 
                                  No_longer_with_firm__c = false,
                                  //CS_Access_Type__c = accessType,
                                  Email = 'testContact@gmail.com');
        insert con;

        return con;
    }
    public static List<Asset> createParentAssetRecord(Account acc, Boolean isActive) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Parent Asset' limit 1];
        
        List<Asset> assets = new List<Asset>();
        Asset parentAssetProspect = new Asset(Name='TestParentAssetProspect', 
                                      AccountId=acc.Id, 
                                      CS_Support_Group__c='Billing System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Prospect',
                                      CS_Is_Active__c = isActive);
        assets.add(parentAssetProspect);
        
        Asset parentAssetImplementation = new Asset(Name='TestParentAssetImplementation', 
                                      AccountId=acc.Id, 
                                      CS_Support_Group__c='Claim System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Implementation',
                                      CS_Is_Active__c = isActive);
        assets.add(parentAssetImplementation);
        
         Asset parentAssetProduction = new Asset(Name='TestParentAssetProduction', 
                                      AccountId=acc.Id, 
                                      CS_Support_Group__c='Policy System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Production',
                                      CS_Is_Active__c = isActive
                                      );
        assets.add(parentAssetProduction);
        
        insert assets;

        return assets;
    } 
    
     public static List<Asset> createParentAssetRecordHosted(Account acc, Boolean isActive) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Parent Asset' limit 1];
        
        List<Asset> assets = new List<Asset>();
        Asset parentAssetProspect = new Asset(Name='TestParentAssetProspectHosted', 
                                      AccountId=acc.Id, 
                                      CS_Support_Group__c='Billing System',
                                      is_Hosted__c = true,
                                      RecordTypeId = rt.Id,
                                      Status = 'Prospect',
                                      CS_Is_Active__c = isActive);
        assets.add(parentAssetProspect);
        
        Asset parentAssetImplementation = new Asset(Name='TestParentAssetImplementationHosted', 
                                      AccountId=acc.Id, 
                                      is_Hosted__c = true,
                                      CS_Support_Group__c='Claim System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Implementation',
                                      CS_Is_Active__c = isActive);
        assets.add(parentAssetImplementation);
        
         Asset parentAssetProduction = new Asset(Name='TestParentAssetProductionHosted', 
                                      AccountId=acc.Id, 
                                      is_Hosted__c = true,
                                      CS_Support_Group__c='Policy System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Production',
                                      CS_Is_Active__c = isActive);
        assets.add(parentAssetProduction);
        
        insert assets;

        return assets;
    } 
    
    public static Asset createParentAsset(Account acc, Boolean isActive) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Parent Asset' limit 1];
        Asset parentAssetImplementation = new Asset(Name='TestParentAssetImplementation', 
                                      AccountId=acc.Id, 
                                      CS_Support_Group__c='Claim System',
                                      RecordTypeId = rt.Id,
                                      Status = 'Implementation',
                                      CS_Is_Active__c = isActive);
        insert parentAssetImplementation;
        return parentAssetImplementation;
    }
    
    public static Asset createChildAssetRecord(Account acc, Product2 prod, Asset asst, String status) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Child Asset' limit 1];
        Asset childAsset = new Asset(Name='TestChildAsset', 
                                     AccountId=acc.Id, 
                                     Product2Id=prod.Id, 
                                     ParentId=asst.Id,
                                     Status = status,
                                     RecordTypeId = rt.Id);
        insert childAsset;
        
        return childAsset;
    }
    
    public static Asset createChildAssetRecord(Account acc, Product2 prod, Asset asst, String status, Contact contact) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Child Asset' limit 1];
        Asset childAsset = new Asset(Name='TestChildAsset', 
                                     AccountId=acc.Id, 
                                     Product2Id=prod.Id, 
                                     ParentId=asst.Id,
                                     Status = status,
                                     RecordTypeId = rt.Id,
                                     ContactId = contact.Id);
        insert childAsset;
        
        return childAsset;
    }
    
    public static Asset createChildAssetWithRelease(Account acc, Product2 prod, Asset asst, CS_Release__c release, String status) {
        RecordType rt = [Select Id, Name from RecordType where Name = 'Child Asset' limit 1];
        Asset childAsset = new Asset();
        childAsset.Name = 'TestChildAssetWithRelease';
        childAsset.Status = status;
        childAsset.AccountId = acc.Id;
        childAsset.Product2Id = prod.Id;
        childAsset.RecordTypeId = rt.Id;
        childAsset.CS_Product_Version__c = release.Id;
        
        insert childAsset;
        
        return childAsset;
    }

    public static CS_Asset_Contact_Permissions__c createACP(Asset asst, Contact con) {
        CS_Asset_Contact_Permissions__c acp = new CS_Asset_Contact_Permissions__c(CS_Contact__c=con.Id, CS_Asset__c=asst.Id, CS_Access_Type__c = 'Customer Support');
        insert acp;

        return acp;
    }

    public static Product2 createProductRecord() {
        Product2 pd = new Product2(Name='TestProduct', ProductCode='TEPD', Product_Group_Name__c = 'BillingCenter Group');
        insert pd;

        return pd;
    }

    public static PriceBook2 createPriceBook() {
        PriceBook2 pc = new priceBook2(Name='Standard PriceBoook', IsActive = true);
        insert pc;

        return pc;
    }

    public static PriceBookEntry createPriceBookEntry(Product2 prod, PriceBook2 pb) {
        Id standardPricebookId = Test.getStandardPricebookId();
        PriceBookEntry pbe = new PriceBookEntry(PriceBook2Id=standardPricebookId, Product2Id=prod.Id, UnitPrice = 100.0, IsActive=true);
        insert pbe;

        return pbe;
    }

    
    public static ServiceContract createServiceContract(Account acc) {
        Id standardPricebookId = Test.getStandardPricebookId();
        ServiceContract sc = new ServiceContract(Name='TestServiceContract', AccountId=acc.Id, Pricebook2Id=standardPricebookId);
        insert sc;

        return sc;
    }

    public static ContractLineItem createServiceContractLineItem(ServiceContract sc, PricebookEntry pbe) {
        ContractLineItem lineItem = new ContractLineItem (ServiceContractId=sc.Id, PricebookEntryId=pbe.Id, Quantity=1, UnitPrice=100.0);
        insert lineItem;

        return lineItem;
    }
    
    public static CS_Release__c createRelease(Product2 prod) {
        RecordType rt = [Select Id, Name from RecordType where sobjecttype = 'CS_Release__c' and Name = 'Standard Products' limit 1];
        CS_Release__c release = new CS_Release__c(CS_Product__c = prod.Id,
                                                 CS_IsActive__c = true,
                                                 CS_Major_Release_version__c = '8',
                                                 CS_Minor_Release_Version__c ='1',
                                                 RecordTypeId = rt.Id);
        insert release;
        
        return release;
    }
    
    public static ContentVersion createContentDocument() {
        
        // create content version and link to content document just created 
        ContentVersion cont1 = new ContentVersion();
        cont1.Title = 'cont1';
        cont1.PathOnClient = 'cont1_' + Datetime.now() + '.docx';
        cont1.VersionData = Blob.valueOf('cont1_' + Datetime.now() + '.docx');
        
        insert cont1;
        
        return cont1;
    }
    
    public static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id linkedEntityId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = linkedEntityId;
        cdl.Visibility = 'AllUsers';
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType = 'V';
        
        insert cdl;
        return cdl;
    }
    
    public static List<GW_Common_Settings__c> createGWCommentSettings() {
        List<GW_Common_Settings__c> commonSettings = new List<GW_Common_Settings__c>();
        GW_Common_Settings__c commonSetting1 = new GW_Common_Settings__c();
        //List<GW_Common_Settings__c>  GWcommon=  new List<GW_Common_Settings__c>([ Select name,Boolean_Value__c from GW_Common_Settings__c where name='EnableContentVersionTrigger' ]);
        
        //if(GWcommon.size()==0){
            commonSetting1.Name = 'EnableContentVersionTrigger';
            commonSetting1.Boolean_Value__c = false;
            commonSettings.add(commonSetting1);        
            insert commonSettings;
            return commonSettings;
      /*  }
        else{

            return GWcommon;
        }
        */
        
    }
    
    public static CS_Asset_Contact_Permissions__c createAcp(Asset a, Contact con, String accessType, Boolean isActive) {
        CS_Asset_Contact_Permissions__c acp = new CS_Asset_Contact_Permissions__c();
        acp.CS_Asset__c = a.Id;
        acp.CS_Access_Type__c = accessType;
        acp.CS_Contact__c = con.Id;
        acp.CS_IsActive__c = isActive;
        
        insert acp;
        return acp;
    }
    
    public static CS_ByPass__c createByPass(User user) {
        CS_ByPass__c byPass = new CS_ByPass__c();
        byPass.SetupOwnerId = user.Id;
        byPass.CS_Batch_Context__c = true;
        
        insert byPass;
        return byPass;
    }
    
    public static Product2 createSkuProduct() {
        // query Sku recordType
        RecordType skuRecordType = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'SKU' and SobjectType = 'Product2' limit 1];
        Product2 skuProduct = new Product2();
        skuProduct.RecordTypeId = skuRecordType.Id;
        skuProduct.Name = 'TestSkuProduct1';
        skuProduct.SKU_ID__c = 'TSTSKU-001';
        skuProduct.SKU_Name__c='TestSkuProduct1';
        
        insert skuProduct;
        return skuProduct;
    }
    
    public static Product2 createSkuProduct2(Product2 prod) {
        // query Sku recordType
        RecordType skuRecordType = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'SKU' and SobjectType = 'Product2' limit 1];
        Product2 skuProduct = new Product2();
        skuProduct.RecordTypeId = skuRecordType.Id;
        skuProduct.Name = 'TestSkuProduct2';
        skuProduct.Product__c = prod.Id;
        skuProduct.SKU_ID__c = 'TSTSKU-002';
        skuProduct.SKU_Name__c='TestSkuProduct2';
        
        insert skuProduct;
        return skuProduct;
    }

    public static Product2 createSkuProduct2A(Product2 prod,String prdName,String SerialNumber) {
        // query Sku recordType
        RecordType skuRecordType = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'SKU' and SobjectType = 'Product2' limit 1];
        Product2 skuProduct = new Product2();
        skuProduct.RecordTypeId = skuRecordType.Id;
        skuProduct.Name = prdName;
        skuProduct.Product__c = prod.Id;
        skuProduct.SKU_Name__c = prdName;
        skuProduct.CS_Serial_Number__c=SerialNumber;
        
        insert skuProduct;
        return skuProduct;
    }
    
    public static Product2 createMaintenanceProduct() {
        // query Sku recordType
        RecordType skuRecordType = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'SKU' and SobjectType = 'Product2' limit 1];
        Product2 maintenanceProduct = new Product2();
        maintenanceProduct.RecordTypeId = skuRecordType.Id;
        maintenanceProduct.Name = 'TestMaintenanceProduct';
        maintenanceProduct.ProductCode = 'TSTMTN';
        maintenanceProduct.CS_Support_Type__c = 'Gold';
        maintenanceProduct.SKU_Name__c='TestMaintenanceProduct';
        insert maintenanceProduct;
        return maintenanceProduct;
    }
    
    public static Product2 createEntitledProduct() {
        // query entitled recordtype
        RecordType entitledRecordType = [Select Id, Name, DeveloperName from RecordType where Name = 'Entitled Product' and SobjectType = 'Product2' limit 1];
        Product2 entitledProduct = new Product2();
        entitledProduct.RecordTypeId = entitledRecordType.Id;
        entitledProduct.Name = 'TestEntitledProduct';
        entitledProduct.ProductCode = 'ENTPROD-001';
        
        insert entitledProduct;
        return entitledProduct;
    }
    
    public static Product2 createStandardProduct() {
        // query standard recordtype
        RecordType standardRecordType = [Select Id, Name, DeveloperName from RecordType where Name = 'Standard Products' and SobjectType = 'Product2' limit 1];
        Product2 standardProduct = new Product2();
        standardProduct.RecordTypeId = standardRecordType.Id;
        standardProduct.Name = 'TestStandardProduct';
        standardProduct.ProductCode = 'STDPROD-001';
        
        insert standardProduct;
        return standardProduct;
    }
    
    public static CS_Customer_Support__c createNumberOfSoluttionOwnerCustomSettings() {
        CS_Customer_Support__c cs = new CS_Customer_Support__c();
        cs.Name = 'Gold';
        cs.CS_Number_Of_Solution_Owners__c = 5;
        
        insert cs;
        return cs;
    }
    
    public static CS_Product_Relation__c createSkuEntitledProductRelations(Product2 skuProd, Product2 entitledProd) {
        CS_Product_Relation__c skuEntitledRelation = new CS_Product_Relation__c();
        skuEntitledRelation.CS_Source_Product__c = skuProd.Id;
        skuEntitledRelation.CS_Target_Product__c = entitledProd.Id;
        skuEntitledRelation.CS_Create_Asset__c = true;
        skuEntitledRelation.CS_Support_Group_Name__c = 'Billing System';
        
        insert skuEntitledRelation;
        return skuEntitledRelation;
    }
    
    public static CS_Product_Relation__c createStandardEntitledProductRelations(Product2 standardProd, Product2 entitledProd) {
        CS_Product_Relation__c standardToEntitledRelation = new CS_Product_Relation__c();
        standardToEntitledRelation.CS_Source_Product__c = standardProd.Id;
        standardToEntitledRelation.CS_Target_Product__c = entitledProd.Id;
        standardToEntitledRelation.CS_Create_Asset__c = true;
        standardToEntitledRelation.CS_Support_Group_Name__c = 'Policy System';
        
        insert standardToEntitledRelation;
        return standardToEntitledRelation;
    }
    
    public static CS_Product_Relation__c createStandardToStandardProductRelations(Product2 sourceStandardProd, Product2 targetStandardProd) {
        CS_Product_Relation__c standardToStandardRelation = new CS_Product_Relation__c();
        standardToStandardRelation.CS_Source_Product__c = sourceStandardProd.Id;
        standardToStandardRelation.CS_Target_Product__c = targetStandardProd.Id;
        standardToStandardRelation.CS_Create_Asset__c = true;
        standardToStandardRelation.CS_Support_Group_Name__c = 'Claim System';
        
        insert standardToStandardRelation;
        return standardToStandardRelation;
    }
    
    public static CS_Software_Downloads__c createSoftwareDownload(Asset asset, CS_Release__c release) {
        CS_Software_Downloads__c sd = new CS_Software_Downloads__c();
        sd.CS_Asset__c = asset.Id;
        sd.CS_Release__c = release.Id;
        
        insert sd;
        return sd;
    }
    
    public static CS_Product_Documentation__c createProductDocumentations(CS_Release__c release) {
        CS_Product_Documentation__c pd = new CS_Product_Documentation__c();
        pd.CS_Release_Version__c = release.Id;
        
        insert pd;
        return pd;
    }
    
    public static Case createCase(Account acc, Asset asst) {
        Case c = new Case();
        c.AccountId = acc.Id;
        c.AssetId = asst.Id;
        
        insert c;
        return c;
    }
    
    public static CaseTeamRole createCaseTeamRole(String roleName, String accessLevel) {
        CaseTeamRole ctr = new CaseTeamRole();
        ctr.Name = roleName;
        ctr.AccessLevel = accessLevel;
        
        insert ctr;
        return ctr;
    }
    
    public static CaseTeamMember createCaseTeamMember (Id parentId, Id memberId, Id roleId) {
        CaseTeamMember ctm = new CaseTeamMember();
        ctm.ParentId = parentId;
        ctm.MemberId = memberId;
        ctm.TeamRoleId = roleId;
        
        insert ctm;
        return ctm;
    }
    
    public static Entitlement createEntitlement(Asset asset, Account acc) {
        
        //query BusinessHours
        BusinessHours bh = [Select Id, Name from BusinessHours limit 1];
        
        // query slaProcess
        SlaProcess sla = [Select Id, name, BusinessHoursId from SlaProcess where name = 'Non-Standard-Berkley' and IsActive=true limit 1];
        
        Entitlement ent = new Entitlement();
        ent.AccountId = acc.Id;
        ent.Name = 'TestEntitlement';
        ent.AssetId = asset.Id;
        ent.BusinessHoursId = bh.Id;
        ent.SlaProcessId = sla.Id;
        
        insert ent;
        return ent;
    }
    
    
     public static Entitlement createEntitlement2(Asset asset, Account acc) {
        
        //query BusinessHours
        BusinessHours bh = [Select Id, Name from BusinessHours limit 1];
        
        // query slaProcess
        SlaProcess sla = [Select Id, name, BusinessHoursId from SlaProcess where name = 'Non-Standard-Catlin' and IsActive=true limit 1];
        
        Entitlement ent = new Entitlement();
        ent.AccountId = acc.Id;
        ent.Name = 'TestEntitlement';
        ent.AssetId = asset.Id;
        ent.BusinessHoursId = bh.Id;
        ent.SlaProcessId = sla.Id;
        
        insert ent;
        return ent;
    }
    
     public static Entitlement createEntitlement(Asset asset, Account acc, String slaProcessName) {
        
        //query BusinessHours
        BusinessHours bh = [Select Id, Name from BusinessHours limit 1];
        
        // query slaProcess
        SlaProcess sla = [Select Id, name, BusinessHoursId from SlaProcess where name = :slaProcessname and IsActive=true limit 1];
        
        Entitlement ent = new Entitlement();
        ent.AccountId = acc.Id;
        ent.Name = 'TestEntitlement';
        ent.AssetId = asset.Id;
        ent.BusinessHoursId = bh.Id;
        ent.SlaProcessId = sla.Id;
        
        insert ent;
        return ent;
    }
    
    public static CS_Milestone_Business_Hours__c createMileStoneBusinessHours() {
        CS_Milestone_Business_Hours__c mbh = new CS_Milestone_Business_Hours__c();
        mbh.Name = 'CM-BH-15';
        mbh.CS_Milestone_Name__c = 'Restoration (1S)';
        mbh.CS_Entitlement_Process_Name__c = 'Non-Standard-Berkley';
        mbh.CS_Business_Days__c = 10;
        mbh.CS_Severity__c = '1-Blocker';
        
        insert mbh;
        return mbh;
    }
    
    public static CS_Milestone_Business_Hours__c createMileStoneBusinessHours(String mbhName, String milestoneName, String slaProcessName, Double businessDays, String severity) {
        CS_Milestone_Business_Hours__c mbh = new CS_Milestone_Business_Hours__c();
        mbh.Name = mbhName;
        mbh.CS_Milestone_Name__c = milestoneName;
        mbh.CS_Entitlement_Process_Name__c = slaProcessName;
        mbh.CS_Business_Days__c = businessDays;
        mbh.CS_Severity__c = severity;
        
        insert mbh;
        return mbh;
    }
    
    //createMileStoneBusinessHours('3s','Initial Response (3S)','Hosted Standard', 1, '3–Minor');
    
     public static CS_Milestone_Business_Hours__c createMileStoneBusinessHours2() {
        CS_Milestone_Business_Hours__c mbh = new CS_Milestone_Business_Hours__c();
        mbh.Name = 'CM-BH-23';
        mbh.CS_Milestone_Name__c = 'Initial Response (3S)';
        mbh.CS_Entitlement_Process_Name__c = 'Non-Standard-Catlin';
        mbh.CS_Business_Days__c = 1;
        mbh.CS_Severity__c = '3-Major';
        
        insert mbh;
        return mbh;
    }

    public static CaseComment createCaseComment(Case c, String commentBody, Boolean flag){
        CaseComment comm = new CaseComment();
        comm.parentid = c.Id;
        comm.CommentBody = commentBody;
        comm.isPublished = flag;
        insert comm;
        return comm;
    }

    public static Case createCaseCS(Account acc, Asset asst, Contact con) {
        Map<String,String> mapOfRecordType = GWUtilities.getRecordTypeId('Case');
        Case c = new Case();
        c.AccountId = acc.Id;
        c.AssetId = asst.Id;
        c.Contactid = con.Id;
        c.Severity__c = '2-Critical';
        c.CS_Urgency__c = 'None';
        c.Environment_Affected__c = 'Implementation';
        c.Status = 'New';
        c.Category__c = 'Bulletin';
        c.subject = 'test';
        c.RecordTypeId = mapOfRecordType.get('CS_Customer_Support');
        insert c;
        return c;
    }
    
     public static ContentDocumentLink createUploadDocument(Case c){
    
        ContentVersion content=new ContentVersion(); 
            content.Title='Header_Picture1'; 
            content.PathOnClient='/' + content.Title + '.jpg'; 
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            content.VersionData=bodyBlob; 
            //content.LinkedEntityId=sub.id;
            content.origin = 'H'; 
            System.Debug('The content is' + content);
        insert content;

        ContentDocumentLink contentlink=new ContentDocumentLink();
            
            contentlink.LinkedEntityId=c.id;
            contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
            contentlink.ShareType = 'V';
            
        insert contentlink;

        return contentlink;

    }

 
     public  static  void  createACPactivateUser(){
        //It's not a custom setting but we need this default record so creating a default record in DealReg_Approver__c object. 
        ACPactivateUser__c testACPactivate = new ACPactivateUser__c();
        testACPactivate.Name ='ACP-DA-1';
        testACPactivate.isTriggerActive__c = True;
        
        try{ insert testACPactivate; }catch( Exception e ){ System.assert( false, 'Failed while inserting ACP Activation User'+e.getMessage() ); } 
        //return testACPactivate;
    }
    
    public static pw_cc__CountryObject__c createPostalCountry(string isoCode1, string isoCode2){
           
             
            pw_cc__CountryObject__c pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = isoCode1,
            pw_cc__IsoCode_2__c = isoCode2
            );
            
            try{ 
            
            insert pcc;
            return pcc;
            }
            catch( Exception e ){ 
            
            System.assert( false, 'Failed while inserting pw_cc__CountryObject__c'+e.getMessage() ); 
            return null;
            } 
    }
    
    public static pw_cc__State__c createPostalState(pw_cc__CountryObject__c pcc){
    
            pw_cc__State__c pcs ;
            pcs = new pw_cc__State__c(
                pw_cc__Country__c = pcc.id,
                pw_cc__IsoCode__c = 'VA');
            try{
            insert pcs;
            return pcs;
            
            }catch (exception ex){
            System.assert( false, 'Failed while inserting pw_cc__State__c'+ex.getMessage() );
                return null;
            }
    
    }
    public static Community_Access_Request__c createCommunityAccessRequest(Account acc, contact cnt, String recordTypeName, pw_cc__CountryObject__c pcc, pw_cc__State__c pcs){
    
            
        Map<String,String> mapOfRecordType = GWUtilities.getRecordTypeId('Community_Access_Request__c');
        Community_Access_Request__c caReq = new Community_Access_Request__c();
        caReq.RecordTypeId = mapOfRecordType.get(recordTypeName);
        caReq.Access_Type__c = 'Production';
        if (cnt != null){
        caReq.Contact__c = cnt.Id;
        }
            
        if (recordTypeName != 'Disable_Account_Request')
        {
            careq.Account__c = acc.Id;
            caReq.First_Name__c ='test1';
            caReq.Last_Name__c ='Cartest';
            caReq.Title__c ='Developer';
            caReq.Email__c ='haritest@gmail.com';
            caReq.Phone__c = '3456728906';
            caReq.Mailing_Street__c ='Farwell stree';
            caReq.Mailing_City__c ='Foster city';
            caReq.Mailing_State__c = pcs.Id;
            caReq.Mailing_Country__c = pcs.pw_cc__Country__c;
            caReq.Mailing_Zip_Postal_Code__c ='97685';
            caReq.BillingCenter_Support_Group__c ='Billing System';
            caReq.ClaimCenter_support_group__c ='Claim System';
            caReq.BillingCenter_Access_type__c = 'General Customer';
            caReq.ClaimCenter_Access_type__c = 'Customer Support';
            caReq.Authorize_Change__c = true;
        } 
        else {
            caReq.Disable_Account__c = true; 
        
        }
        try{
        insert caReq;
        return caReq;
        }
        catch( Exception e ){ 
        System.assert( false, 'Failed while inserting Community Access Request'+e.getMessage() ); 
        return null;
        } 
        
        }

}