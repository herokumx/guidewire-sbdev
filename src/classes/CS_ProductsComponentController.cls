/*
*****************************************************************************************************************************
Class Name - CS_ProductsComponentController
Class Type -  Controller
Test Class-
Purpose- Controller class for Products Lightning Component


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan Xu                        05/13/2016       Initial Creation
Mani                           10/21/2016       Fixed for DE1382
*****************************************************************************************************************************
*/
public class CS_ProductsComponentController {
    public static User user {
        get {
            return [Select Id, AccountId,usertype, ContactId from User where Id = :UserInfo.getUserId()];
        }
    }

    @AuraEnabled
    public static List<String> getParentAssets(String organization) {
        List<String> parentAssetNames = new List<String>();

        //Id ContactId=[select contactid from user where id =:userinfo.getUserId() limit 1];

        List<CS_Asset_Contact_Permissions__c> acpList;
        System.debug('====user=== ' + user);
        if (user != null && user.UserType == 'PowerPartner') {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                              CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                              CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                              from CS_Asset_Contact_Permissions__c 
                              where CS_Asset__r.CS_Is_Active__c = true 
                              and CS_Asset__r.CS_Not_in_Use__c = false
                              and  CS_Contact__c in
                               (select contactid from user where id =:userinfo.getUserId())];
            
        } else if ( user != null && user.UserType != 'PowerPartner') {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                              CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                              CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                              from CS_Asset_Contact_Permissions__c 
                              where //CS_Asset__r.AccountId = :user.AccountId  and /* commented for DE1382 */
                              CS_Asset__r.CS_Not_in_Use__c = false 
                              and  CS_Asset__r.CS_Is_Active__c = true and  CS_Contact__c in
                               (select contactid from user where id =:userinfo.getUserId())];
        }
        for (CS_Asset_Contact_Permissions__c acp : acpList) {
            if (acp.CS_Access_Type__c == 'Customer Support' || acp.CS_Access_Type__c=='Customer Support (View Only)' || acp.CS_Access_Type__c == 'Partner' || acp.CS_Access_Type__c == 'General Customer' || acp.CS_Access_Type__c == 'Certified') {
                parentAssetNames.add(acp.CS_Asset_Name__c);
            }
        }
        system.debug('parentAssetNames===='+parentAssetNames);
        return parentAssetNames;
    }
    
    
    @AuraEnabled
    public static List<String> getChildAssetProductsByOrganization(String organization) {
        system.debug('organization==='+organization);
        List<String> childAssetProducts = new List<String>();
        String queryString;
        List<Asset> childAssets;
        if (user != null && Organization == 'All' ) {
            queryString = 'Select Id, Name, Product2.Name, ParentId from Asset where cs_record_type_name__c= \'Child Asset\' and CS_Not_in_Use__c = false';
            if (user.UserType != 'PowerPartner' ) {
                    //queryString += ' and AccountId = \''+user.AccountId +'\' '; /* commented for DE1382 */
                } 
        } else if (user != null && organization != 'All') {
            queryString = 'Select Id, Name, Product2.Name, ParentId from Asset where Parent.Name = :organization and cs_record_type_name__c= \'Child Asset\' and CS_Not_in_Use__c = false';
            if (user.UserType != 'PowerPartner') {
                //queryString += ' and AccountId = \''+user.AccountId +'\' '; /* commented for DE1382 */
            }
        }
        childAssets = Database.query(queryString);
        system.debug('MMG Child Assets ===='+ childAssets);
        for (Asset child : childAssets) {
            childAssetProducts.add(child.Name);
        }
        return childAssetProducts;
    }

    @AuraEnabled 
    public static List<String> getChildAssetProducts() {
        List<String> childAssetProducts = new List<String>();
        String queryString;
        List<Asset> childAssets;
         queryString = 'Select Id, Name, Product2.Name, ParentId from Asset where cs_record_type_name__c= \'Child Asset\' and CS_Not_in_Use__c = false';
        if (user.UserType != 'PowerPartner' ) {
           // queryString += ' and AccountId = \''+user.AccountId +'\' '; /* commented for DE1382 */
        } else  if (user.UserType != 'PowerPartner') {
            //queryString += ' and AccountId = \''+user.AccountId +'\' '; /* commented for DE1382 */
        }
        childAssets = Database.query(queryString);
        for (Asset child : childAssets) {
            childAssetProducts.add(child.Name);
        }
        return childAssetProducts;
    }
    
    @AuraEnabled
    public static List<Asset> getChildAssets(String organization, String product) {
        system.debug('organization==='+organization);
        List<Asset> childAssets;
        String queryString;
        if (user != null && user.UserType != 'PowerPartner') {
            /* commented for DE1382 */
            //queryString = 'Select Id, Parent.Name,Name, CS_Version__c, ParentId,CS_SaaS_Url__c,CS_No_Downloadable__c, CS_Saas_Documentation_Url__c, CS_Saas_Case_Url__c, Product2Id,CS_Product_Set_Name__c,CS_Support_Group__c, Product2.Name, Status from Asset where AccountId =\'' + user.AccountId + '\' and cs_record_type_name__c = \'Child Asset\' and CS_Not_in_Use__c = false';
            queryString = 'Select Id, Parent.Name,Name, CS_Version__c, ParentId,CS_SaaS_Url__c,CS_No_Downloadable__c, CS_Saas_Documentation_Url__c, CS_Saas_Case_Url__c, Product2Id,CS_Product_Set_Name__c,CS_Support_Group__c, Product2.Name, Status from Asset where cs_record_type_name__c = \'Child Asset\' and CS_Not_in_Use__c = false';
            if (organization != 'All' && product != 'All') {
                queryString += ' and Parent.Name = \'' + organization + '\' and Name = \'' + product + '\'';
            } else if (organization == 'All' && product != 'All') {
                 queryString += ' and Name = \'' + product + '\'';
            } else if (organization == 'All' && product == 'All') {
                queryString += '';
            } else if (organization != 'All' && product == 'All') {
                queryString += ' and Parent.Name = \'' + organization + '\'';
            }
            querystring+=' order by  Name';
            
            System.debug('query String ' + queryString);
            childAssets = Database.query(queryString);
        }
        

        if(user!=null && user.userType=='PowerPartner'){

             queryString = 'Select Id, Parent.Name,Name, CS_Version__c, ParentId,CS_SaaS_Url__c, CS_Saas_Documentation_Url__c, CS_Saas_Case_Url__c, CS_No_Downloadable__c, Product2Id,CS_Product_Set_Name__c,CS_Support_Group__c, Product2.Name, Status from Asset where cs_record_type_name__c = \'Child Asset\' and CS_Not_in_Use__c = false';
            if (organization != 'All' && product != 'All') {
                queryString += ' and Parent.Name = \'' + organization + '\' and Name = \'' + product + '\'';
            } else if (organization == 'All' && product != 'All') {
                 queryString += ' and Name = \'' + product + '\'';
            } else if (organization == 'All' && product == 'All') {
                queryString += '';
            } else if (organization != 'All' && product == 'All') {
                queryString += ' and Parent.Name = \'' + organization + '\'';
            }
            queryString+=' and Parentid in (Select CS_Asset__c from CS_Asset_Contact_Permissions__c where CS_Contact__c=\''+user.ContactId +'\' and CS_Access_Type__c in (\'Partner\', \'Certified\') and CS_IsActive__c=True)';
            queryString+=' order by  Name';

            childAssets = Database.query(queryString);

        }

        System.debug('querystring_Partner==='+queryString);
        system.debug('Child Assets====' +childAssets);
        return childAssets;
    }
    
    @AuraEnabled
    public static String getUserType() {
        String userType = UserInfo.getUserType();
        System.debug('userType ' + userType);
        return userType;
    }
    
    @AuraEnabled
    public static Map<String, Boolean> getAcpAccessType() {
        Map<String, Boolean> accessToCaseMap = new Map<String, Boolean>();
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                       CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                       CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                       from CS_Asset_Contact_Permissions__c 
                       where //CS_Asset__r.AccountId = :user.AccountId and  /* commented for DE1382 */
                       CS_Asset__r.CS_Is_Active__c = true 
                       and CS_Asset__r.Status not in ('Certification', 'Prospect')
                       and  CS_Contact__c in
                       (select contactid from user where id =:userinfo.getUserId())];
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                if (acp.CS_Access_Type__c == 'Customer Support' || acp.CS_Access_Type__c=='Customer Support (View Only)' || acp.CS_Access_Type__c == 'Partner' ) {
                    accessToCaseMap.put(acp.CS_Asset__c, true);
                } else {
                    accessToCaseMap.put(acp.CS_Asset__c, false);
                }
            }
        }
        return accessToCaseMap;
    }

     @AuraEnabled
    public static Map<String, Boolean> getCaseCreateAccessType() {
        Map<String, Boolean> accessToCaseMap = new Map<String, Boolean>();
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                              CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                              CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                              from CS_Asset_Contact_Permissions__c 
                              where //CS_Asset__r.AccountId = :user.AccountId and  /* commented for DE1382 */
                              CS_Asset__r.CS_Is_Active__c = true and  CS_Contact__c in
                               (select contactid from user where id =:userinfo.getUserId())];
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                if (acp.CS_Access_Type__c == 'Customer Support' || acp.CS_Access_Type__c == 'Partner') {
                    accessToCaseMap.put(acp.CS_Asset__c, true);
                } else {
                    accessToCaseMap.put(acp.CS_Asset__c, false);
                }
            }
        }
        system.debug('accessToCaseMap=='+accessToCaseMap);
        return accessToCaseMap;
    }
    
    @AuraEnabled
    public static List<String> getUrgencyPickvals() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.CS_Urgency__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }       
        return options;
    }
    
    @AuraEnabled
    public static List<String> getEnvironmentalAffectedPickvals() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Environment_Affected__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }       
        return options;
    }
    
    @AuraEnabled
    public static List<String> getSeverityPickval() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Severity__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }       
        return options;
    }
    
    @AuraEnabled
    public static List<String> getOrganizationForCaseCreation() {
        List<String> parentAssetNames = new List<String>();

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                       CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                       CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                       from CS_Asset_Contact_Permissions__c 
                       where //CS_Asset__r.AccountId = :user.AccountId and  /* commented for DE1382 */
                       CS_Asset__r.CS_Is_Active__c = true 
                       and CS_Asset__r.CS_Not_in_Use__c = false       
                       and CS_Contact__c = :user.ContactId
                       and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner')];
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                parentAssetNames.add(acp.CS_Asset_Name__c);
            }
        }
        system.debug('parentAssetNames===='+parentAssetNames);
        return parentAssetNames;
    }
    
    @AuraEnabled
    public static List<Asset> getChildAssetsByOrganization(String organization) {
        List<Asset> childAssets;
        if (user != null) {
            childAssets = [Select Id, Parent.Name, Name, ParentId,CS_SaaS_Url__c, CS_Saas_Case_Url__c, CS_Saas_Documentation_Url__c, Product2Id,CS_Product_Set_Name__c,CS_Support_Group__c, Product2.Name, Status 
                           from Asset 
                           where //AccountId = :user.AccountId and  /* commented for DE1382 */
                           Parent.Name = :organization 
                           and cs_record_type_name__c = 'Child Asset' and CS_Hide_On_Case__c = false];
        }
        system.debug('======childAssets=====' + childAssets);
        return childAssets;
    }
   
    @AuraEnabled
    public static List<CS_Release__c> getProductVersions(String assetId) {
        Set<Id> productIds = new Set<Id>();
        List<Asset> assets = [select Id, Product2Id from Asset where Id = :assetId];
        for (Asset a : assets) {
            productIds.add(a.Product2Id);
        }
        
        System.debug('PRODUCT ID --'+productIds);       
        List<CS_Release__c> releases = [Select Id, CS_Version__c, CS_Patch_Version__c, CS_Release_Type__c, CS_Product__c, CS_Product__r.Product_Source__c,
                                        CS_Additional_Version_Code__c
                                        from CS_Release__c 
                                        where CS_Product__c in :productIds order by CS_Major_Release_version__c desc];

        System.debug('releases ' + releases);
        return releases;
    }
    
    @AuraEnabled
    public static Boolean getAssetODC(String assetId) {
        List<Asset> assets = [Select Id, CS_ODC_Status__c from Asset where CS_ODC_Status__c = 'Active' and Id = :assetId];
        if (assets != null && assets.size() > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    @AuraEnabled
    public static String saveCase(Case c, String severity, String assetId, String release, Boolean odc, String urgency, String environmentAffected) {
        // get recordtype Id:
        Id recordTypeId = [Select Id, Name from RecordType where Name = 'Customer Support'].Id;
        c.RecordTypeId = recordTypeId;
        if (severity != null && severity != '') {
            c.Severity__c = severity;
        } if (assetId != null && assetId != '') {
            c.AssetId = assetId;
        } if (release != null && assetId != '') {
            c.CS_Product_Version__c = release;
        }
        if (odc != null) {
            c.CS_ODC__c = odc;
        }
        if (urgency != null && urgency != '') {
            c.CS_Urgency__c = urgency;
        }

        if (environmentAffected != null && environmentAffected != '') {
            c.Environment_Affected__c = environmentAffected;
        }
        Database.UpsertResult sr = Database.upsert(c);
        System.debug('sr ' + sr);
        String newCaseId;
        if (sr.isSuccess() == true) {
            newCaseId = sr.getId();
        }
        return newCaseId;
    }
    
}