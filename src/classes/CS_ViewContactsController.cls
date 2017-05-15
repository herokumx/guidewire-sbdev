/*
*****************************************************************************************************************************
Class Name - CS_ViewContactsController
Class Type -  Controller
Test Class-
Purpose- View Contacts Lightning Component Controller


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan xu                                            Initial Creation
Mani G                        09/06/2016           Fixed the Query to add   CS_Access_Type__c for Defect DE591
Suchitra p                    11/02/2016           Added additional check to not display disabled contacts/users. INC0063480
*****************************************************************************************************************************
*/
public with sharing class CS_ViewContactsController {
    /*
     @AuraEnabled
    public static List<CS_Asset_Contact_Permissions__c> getcontactlist() {
    List<CS_Asset_Contact_Permissions__c> toReturn =  New List<CS_Asset_Contact_Permissions__c>([select  CS_Asset__r.Account.name,CS_Product__c,CS_Asset_Status__c, 
                        CS_Contact_Type__c, CS_Email__c, CS_First_Name__c, CS_Last_Name__c,CS_Full_Name__c, CS_Office_Phone__c,
                         CS_Product_version__c, CS_Title__c from CS_Asset_Contact_Permissions__c]);
      System.debug('QUERY Result===========' +toReturn);
    return toReturn;
  }
  */
    
    static User user {
        get {
            return [Select Id, AccountId, ContactId from User where Id = :UserInfo.getUserId()];
        }
    }
    @AuraEnabled
    public static User getCurrentUser() {
      User toReturn = [SELECT Id, CS_Profile_Name__c,FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
      system.debug('+++++++toReturn'+toReturn);
        return toReturn;
  }
    
    @AuraEnabled
    public static List<CS_Asset_Contact_Permissions__c> getcontactlist() {
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null) {
            acpList =  [select  Name, CS_Email__c, CS_Asset__r.Account.name,CS_Asset_Name__c,CS_Product__c, 
                                                            CS_Contact_Type__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c,
                                                            CS_Product_version__c, CS_Title__c, CS_Access_Type__c, CS_Asset_Status__c from CS_Asset_Contact_Permissions__c
                                                           where CS_Asset__r.cs_record_type_name__c='Parent Asset' and CS_IsActive__c=true 
                                                           and CS_Asset__r.AccountId = :user.AccountId and 
                                                           CS_Asset__r.cs_record_type_name__c='Parent Asset' and CS_IsActive__c=true AND CS_Contact__r.CS_Is_Disabled__c=:false AND CS_Contact__r.User__r.IsActive=: true]; //INC0063480 Additional filter condition to exclude disabled contact and inactive user 
        }
        
        system.debug('contact list on initial load ' +acpList.size() );
        return acpList;
    }

    @AuraEnabled
    public static List<String> getParentAssets(String organization) {
        List<String> parentAssetNames = new List<String>();

        //Id ContactId=[select contactid from user where id =:userinfo.getUserId() limit 1];

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                              CS_Contact_Type__c,CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                              CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                              from CS_Asset_Contact_Permissions__c 
                              where CS_Asset__r.AccountId = :user.AccountId
                              and CS_Asset__r.CS_Is_Active__c = true  
                              AND CS_Contact__r.CS_Is_Disabled__c=:false AND CS_Contact__r.User__r.IsActive=: true and
                               CS_Contact__c in
                               (select contactid from user where id =:userinfo.getUserId())];//INC0063480 Additional filter condition to exclude disabled contact and inactive user 
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                if (acp.CS_Access_Type__c == 'Customer Support' || acp.CS_Access_Type__c=='Customer Support (View Only)' || acp.CS_Access_Type__c == 'Partner' || acp.CS_Access_Type__c == 'General Customer' || acp.CS_Access_Type__c == 'Certified') {
                    parentAssetNames.add(acp.CS_Asset_Name__c);
                }
            }
        }
        return parentAssetNames;
    }
    @AuraEnabled
    public static List<CS_Asset_Contact_Permissions__c> getParentAssetswithId(String organization) {
        List<CS_Asset_Contact_Permissions__c> parentAssetNames = new List<CS_Asset_Contact_Permissions__c>();

        //Id ContactId=[select contactid from user where id =:userinfo.getUserId() limit 1];

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                              CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                              CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                              from CS_Asset_Contact_Permissions__c 
                              where //CS_Asset__r.AccountId = :user.AccountId and 
                              CS_Asset__r.CS_Is_Active__c = true AND CS_Contact__r.CS_Is_Disabled__c=:false AND CS_Contact__r.User__r.IsActive=: true and  CS_Contact__c in
                               (select contactid from user where id =:userinfo.getUserId())];//INC0063480 Additional filter condition to exclude disabled contact and inactive user 
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                if (acp.CS_Access_Type__c == 'Customer Support' || acp.CS_Access_Type__c=='Customer Support (View Only)' || acp.CS_Access_Type__c == 'Partner' || acp.CS_Access_Type__c == 'General Customer' || acp.CS_Access_Type__c == 'Certified') {
                    parentAssetNames.add(acp);       
                }
            }
        }
        return parentAssetNames;
    }
    @AuraEnabled
    public static List<String> getProducts() {
        Set<String> productSet = new Set<String>();
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null) {
            acpList =  [select  CS_Asset__r.Account.name,CS_Asset_Name__c,CS_Product__c,CS_Asset_Status__c, 
                        CS_Contact_Type__c, CS_Access_Type__c, CS_Email__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c,
                        CS_Product_version__c, CS_Title__c from CS_Asset_Contact_Permissions__c
                        where CS_Asset__r.AccountId = :user.AccountId and CS_Asset__r.CS_Is_Active__c = true 
                        AND CS_Contact__r.CS_Is_Disabled__c=:false AND CS_Contact__r.User__r.IsActive=: true
                        and CS_Asset__r.cs_record_type_name__c='Parent Asset' ];//INC0063480 Additional filter condition to exclude disabled contact and inactive user 
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                productSet.add(acp.CS_Asset_Name__c);
            }
        }
        system.debug('productSet=='+productSet);
        return new List<String>(productSet);
    }
    
    /*
    @AuraEnabled 
    public static List<CS_Asset_Contact_Permissions__c> getContactsByProduct(String product) {
        System.debug('Input Product==='+product);
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null && product != 'All Products') {
            acpList =  [select  CS_Asset__r.Account.name,CS_Product__c,CS_Asset_Status__c, 
                        CS_Contact_Type__c, CS_Access_Type__c, CS_Email__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c,
                        CS_Product_version__c, CS_Title__c from CS_Asset_Contact_Permissions__c
                        where CS_Asset__r.AccountId = :user.AccountId
                        and CS_Product__c = :product];
        } else if (user != null && product == 'All Products') {
            acpList =  [select  CS_Asset__r.Account.name,CS_Product__c,CS_Asset_Status__c, 
                        CS_Contact_Type__c, CS_Email__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c,
                        CS_Product_version__c, CS_Title__c from CS_Asset_Contact_Permissions__c
                        where CS_Asset__r.AccountId = :user.AccountId];
        }
        return acpList;
    }
    */
    
    @AuraEnabled
    public static List<String> getChildAssetProducts(String organization) {
        system.debug('organization==='+organization);
        List<String> childAssetProducts = new List<String>();
        List<Asset> childAssets;
        if (user != null && organization == 'All') {
            childAssets = [Select Id, Product2.Name, ParentId 
                          from Asset
                          where AccountId = :user.AccountId and cs_record_type_name__c='Child Asset'];
        } else if (user != null && organization != 'All') {
            childAssets = [Select Id, Product2.Name, ParentId 
                          from Asset
                          where Parent.Name = :organization
                          
                          and AccountId = :user.AccountId
                          and cs_record_type_name__c='Child Asset'];
        }
        system.debug('MMG Child Assets ===='+ childAssets);
        for (Asset child : childAssets) {
            childAssetProducts.add(child.Product2.Name);
        }
        return childAssetProducts;
    }
    
    @AuraEnabled
    public static List<CS_Asset_Contact_Permissions__c> getContactsByAsset(String assetId) {
        System.Debug('user' + user);
        System.Debug('assetId' + assetId);

        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String loggedInProfile = PROFILE[0].Name;
        String filterContactType = '';
        String queryString = '';
        if(loggedInProfile.toUpperCase() == 'GW PARTNER COMMUNITY')
        {
                 filterContactType = ' AND CS_Contact_Type__c!=\'Customer\'';
        }

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null && assetId!='All') {

            //INC0063480 Additional filter condition to exclude disabled contact and inactive user 
            queryString =  'select  Name, CS_Email__c, CS_Asset__r.name,CS_Asset_Name__c,CS_Asset__r.Account.name,CS_Product__c, CS_Contact_Type__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c,CS_Product_version__c, CS_Title__c, CS_Access_Type__c, CS_Asset_Status__c from CS_Asset_Contact_Permissions__c where CS_Asset__r.cs_record_type_name__c=\'Parent Asset\' and CS_IsActive__c=true  and (CS_Asset__r.name = \'' + assetId + '\' or CS_Asset__r.Id=\'' + assetId + '\') AND CS_Contact__r.CS_Is_Disabled__c=false AND CS_Contact__r.User__r.IsActive=true' + filterContactType  ;
                          
            acpList =  Database.query(queryString);
        }
        else{
            //INC0063480 Additional filter condition to exclude disabled contact and inactive user 
            queryString =  'select  Name, CS_Email__c, CS_Asset__r.name,CS_Asset_Name__c,CS_Asset__r.Account.name,CS_Product__c, CS_Contact_Type__c, CS_First_Name__c, CS_Last_Name__c, CS_Contact__r.Name, CS_Office_Phone__c, CS_Product_version__c, CS_Title__c, CS_Access_Type__c, CS_Asset_Status__c from CS_Asset_Contact_Permissions__c where CS_Asset__r.cs_record_type_name__c=\'Parent Asset\' and CS_IsActive__c=true AND CS_Contact__r.CS_Is_Disabled__c=false AND CS_Contact__r.User__r.IsActive=true' + filterContactType ;
                          
                        //and CS_Asset__r.AccountId = :user.AccountId ];
            acpList =  Database.query(queryString);         

        }
      
        return acpList;
    }
    
    /*
    @AuraEnabled
    public static String getAssetProduct(String assetId) {
        Asset a = [Select CS_Parent_Product__c from Asset where Id = :assetId];
        return a.CS_Parent_Product__c;
    }
    */
}