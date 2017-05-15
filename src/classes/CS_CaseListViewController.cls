/*
******************************************************************************************************************************
Controller Class Name- CS_CaseListViewController
Object - Case
Purpose- Controller  Class Case  List View  Lighnting  Component
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Shan xu  shanx@slalom.com   09/12/2016   Fixed for DE741 Changed the Filter from Submitted by to Case Contact
Mani G   manig@slalom.com   09/12/2016   Fixed for DE701 Changed the Filter from Submitted by to Case Contact
Shan Xu  shanx@slalom.com   09/14/2016   Fixed for DE835 Fix filter issue
Shan Xu  shanx@slalom.com   09/16/2016   Fixed for DE987 Fix filter issue
Mani G   manig@slalom.com   09/27/2016   Fixed for DEXXX Added condition to prevent display  Gold Master on 
                                         Version Picklist on case Creation
Mani                        10/24/2016       Fixed for DE1382   
Suchitra                    01/18/2017   DE25/INC0065567 - GPS 
                                         Added new Methods to GetHosted Value for Selected Organization 
                                         Changes to getProductVersion Method. 
                                                                                              
*****************************************************************************************************************************
*/
public with sharing class CS_CaseListViewController {
    static User user {
        get {
            return [Select Id, AccountId, ContactId, UserType from User where Id = :UserInfo.getUserId()];
        }
    }
    
    @AuraEnabled
    public static String getUserId() {
        String userId;
        if (user != null) {
            userId =  user.Id;
        }
        return userId;
    }
    /*
    @AuraEnabled
    public User getUser() {
        return [Select Id, AccountId, ContactId from User where Id = :UserInfo.getUserId()];
    }
    */
    @AuraEnabled
    public static User getCurrentUser() {
      User toReturn = [SELECT Id, CS_Profile_Name__c,FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
      system.debug('+++++++toReturn'+toReturn);
        return toReturn;
  }
    /*
    @AuraEnabled
    public static List<String> getProductNames() {
        Set<String> productNames = new Set<String>();
        if (user != null) {
            List<CS_Asset_Contact_Permissions__c> acpList = [Select id,CS_Asset__c, CS_Access_Type__c, CS_Contact__c, CS_Product__c, CS_Product_Version__c, CS_Asset_Status__c 
                                                            from CS_Asset_Contact_Permissions__c
                                                            where CS_Contact__c = :user.ContactId and (CS_Asset_Status__c!='Prospect' or  CS_Asset_Status__c!='Certification') ];
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                productNames.add(acp.CS_Product__c);
            }
        }
        return new List<String>(productNames);
    }
    
    @AuraEnabled
    public static List<Case> getAllProductCases() {
        List<Case> caseList; 
        if (user != null) {
            caseList = [Select id,CaseNumber,Severity__c,CS_Submitted_by__c,subject, Environment_Affected__c, Status, CreatedDate, Owner.Name, CS_Owner_Org_Id__c, Asset.Name, CS_Parent_Asset_Name__c, Asset.Parent.Name, Asset.Parent.Id, IsEscalated, CS_Standard_Product__c, CS_Customer_Reference_Number__c
                                  from Case 
                                  where (Status != 'Closed' AND Status != 'Closed by customer') AND 
                                  CreatedById = :user.Id AND
                                 ( CS_Contact_Asset__r.CS_Asset_Status__c != 'Prospect' Or CS_Contact_Asset__r.CS_Asset_Status__c != 'Certification')
                                  AND CS_Contact_Asset__r.CS_Access_Type__c in (:Label.Customer_Support, :Label.Customer_Support_View_Only, :Label.Partner) 
                                  order by CaseNumber desc];
            System.debug('all cases ' + caseList);
        }
        return caseList;
    }
    
    @AuraEnabled
    public static List<Case> getCasesByProduct(String productName) {
        System.debug('productName ' + productName);
        List<Case> caseList;
        if (productName != 'All Products') {
            caseList = [Select id,CaseNumber,Severity__c,CS_Submitted_by__c, subject,Environment_Affected__c, Status, CreatedDate, Owner.Name, CS_Owner_Org_Id__c, Asset.Name, CS_Parent_Asset_Name__c, Asset.Parent.Name, IsEscalated, CS_Customer_Reference_Number__c, CS_Standard_Product__c
                        from Case 
                        where Asset.Product2.Product__r.Name = :productName order by CaseNumber desc];
        } else {
            caseList = [Select id,subject,CS_Submitted_by__c,CaseNumber, Environment_Affected__c, Status, CreatedDate, Owner.Name, CS_Owner_Org_Id__c, Asset.Name, CS_Parent_Asset_Name__c, Asset.Parent.Name, IsEscalated, CS_Standard_Product__c, CS_Customer_Reference_Number__c
                        from Case order by CaseNumber desc];
        }
        System.debug('get case by product ' + caseList);
        return caseList;
    }
*/
    
    @AuraEnabled
    public static List<CS_Release__c> getProductVersions(String assetId, String selectEnvironmentAffected) {
        Set<Id> productIds = new Set<Id>();
        system.debug('########## Asset Id is : ' + assetId);
        List<Asset> assets = [select Id, CS_Cur_Dev_Version__c,CS_Product_Version__c,status,Product2Id from Asset where Id = :assetId];
        for (Asset a : assets) {
            productIds.add(a.Product2Id);
        }
       
        
        System.debug('selectEnvironmentAffected --'+selectEnvironmentAffected);       
        List<CS_Release__c> releases = [Select Id,CS_Major_Release_version__c,CS_Minor_Release_version__c, CS_Version__c, CS_Patch_Version__c, CS_Product__c, CS_Release_Type__c, CS_Product__r.Product_Source__c,
                                        CS_Additional_Version_Code__c 
                                        from CS_Release__c 
                                        where CS_Product__c in :productIds 
                                        and CS_Release_Type__c !=  'Gold Master'
                                        order by CS_Major_Release_version__c desc, CS_Minor_Release_version__c desc, CS_Maintenance_Release_Version__c desc, CS_Patch_version__c desc];
        Map<String, CS_Release__c> mapRelease = new Map<String, CS_Release__c>();
        for (CS_Release__c relRecord:releases){
            
            String version = '';
            if (relRecord.CS_Patch_Version__c != null){
                version = relRecord.CS_Version__c +   relRecord.CS_Patch_Version__c;
            }
            else {
                version = relRecord.CS_Version__c;
            }
            
            mapRelease.put(version,relRecord);
            System.debug('::relRec version ' + version + '::::::::: Rel Record  ' + relRecord );
            
        }
        //RP: Populate default version
        for(CS_Release__c rel : mapRelease.values() ){
            if(assets.size() >0 && assets[0].CS_Product_Version__c != null)
                if(rel.Id == assets[0].CS_Product_Version__c){
                        system.debug('The production default version is ' + rel.CS_Version__c);
                        releases.set(0,rel);
                }
                
        }
        
        if (assets.size() >0 && (selectEnvironmentAffected == 'Implementation' || selectEnvironmentAffected == 'Other')){
         
         if (assets[0].CS_Cur_Dev_Version__c != null){
                System.debug('::relRec2' + assets[0].CS_Cur_Dev_Version__c);
                CS_Release__c relRec = mapRelease.get(assets[0].CS_Cur_Dev_Version__c);
                if (relRec != null){
                System.debug('::relRec3' + relRec );
                releases.set(0,relRec);
                }
            }
           
        }
        
        system.debug(releases);
        
        return releases;
    }
    
    @AuraEnabled
    public static boolean getHasDefaultVersion(String assetId,string selectEnvironmentAffected){
    Set<Id> productIds = new Set<Id>();
    boolean hasDefaultVersion = false;
    system.debug('######### Entering hasDefaultVersion Method #########');
    List<Asset> assets = [select Id, CS_Cur_Dev_Version__c,CS_Product_Version__c,status,Product2Id from Asset where Id = :assetId];
    
    system.debug('######### assets[0].CS_Product_Version__c ######### ' + assets[0].CS_Product_Version__c + 'END' );
        for (Asset a : assets) {
            if(a.CS_Product_Version__c != null && selectEnvironmentAffected == 'Production'){
                hasDefaultVersion = true;
            }
            // if(a.CS_Cur_Dev_Version__c != null && (selectEnvironmentAffected == 'Implementation' || selectEnvironmentAffected == 'UAT'))
                // hasDefaultVersion = true;
        }
       
        
        return hasDefaultVersion;
    
    }
    //DE25/INC0065567 - GPS 
    @AuraEnabled
    public static boolean getCurrentDevVersionStatus(String assetId) {
        
        boolean currentDevVersionExists = false;
          Set<Id> productIds = new Set<Id>();
        List<Asset> assets = [select Id, CS_Cur_Dev_Version__c, Product2Id from Asset where Id = :assetId];
        for (Asset a : assets) {
            productIds.add(a.Product2Id);
        }
            
        List<CS_Release__c> releases = [Select Id,CS_Major_Release_version__c,CS_Minor_Release_version__c, CS_Version__c, CS_Patch_Version__c, CS_Product__c, CS_Release_Type__c, CS_Product__r.Product_Source__c,
                                        CS_Additional_Version_Code__c 
                                        from CS_Release__c 
                                        where CS_Product__c in :productIds 
                                        and CS_Release_Type__c !=  'Gold Master'
                                        order by CS_Major_Release_version__c desc, CS_Minor_Release_version__c desc, CS_Maintenance_Release_Version__c desc, CS_Patch_version__c desc];
        Map<String, CS_Release__c> mapRelease = new Map<String, CS_Release__c>();
        for (CS_Release__c relRecord:releases){
            
            String version = '';
            if (relRecord.CS_Patch_Version__c != null){
                version = relRecord.CS_Version__c +   relRecord.CS_Patch_Version__c;
            }
            else {
                version = relRecord.CS_Version__c;
            }
            
            mapRelease.put(version,relRecord);
            System.debug('::relRec version ' + version  );
            
        }
        
         
         if (assets[0].CS_Cur_Dev_Version__c != null){
                System.debug('::relRec2' + assets[0].CS_Cur_Dev_Version__c);
                CS_Release__c relRec = mapRelease.get(assets[0].CS_Cur_Dev_Version__c);
                if (relRec != null){
                currentDevVersionExists = true;
                }
            }
           
        return currentDevVersionExists ;
    }
    
    //RP: Get installation picklist values
    @AuraEnabled
    public static List<String> getInstallationPickval() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Asset_Type__c.getDescribe();

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
    
    //RP: Refresh Severity PickVals based on Hosted
    @AuraEnabled
    public static List<String> getNewSeverityPickval(boolean isHosted) {
        List<Case_Severities__c> csList = new List<Case_Severities__c>();
    if(isHosted){
        csList = [Select Installation__c,values__c from Case_Severities__c where Installation__c = 'Hosted' and Field_Name__c = 'Severity'  ORDER by values__c];
    } else {
        csList = [Select Installation__c,values__c from Case_Severities__c where Installation__c = 'OnPremise' and Field_Name__c = 'Severity' ORDER by values__c];
    }
            
        
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Severity__c.getDescribe();

        // List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Case_Severities__c f: csList) {
            options.add(f.values__c);
        }       
        return options;
    }
    
     //RP: Refresh Severity PickVals based on Hosted
    @AuraEnabled
    public static List<String> getNewEnvAffectedPickvals(boolean isHosted) {
        List<Case_Severities__c> csList = new List<Case_Severities__c>();
    if(isHosted){
        csList = [Select Installation__c,values__c from Case_Severities__c where Installation__c = 'Hosted' and Field_Name__c = 'Environment' ORDER by values__c desc];
    } else {
        csList = [Select Installation__c,values__c from Case_Severities__c where Installation__c = 'OnPremise' and Field_Name__c = 'Environment' ORDER by values__c];
    }
            
        
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Severity__c.getDescribe();

        // List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Case_Severities__c f: csList) {
            options.add(f.values__c);
        }       
        return options;
    }
    
    
    /*
    @AuraEnabled
    public static List<CS_Asset_Contact_Permissions__c> getSecondaryContactLookup(String acpId) {
        CS_Asset_Contact_Permissions__c acp = [Select Id, CS_Contact__r.Name, CS_Contact__c, CS_Product__c from CS_Asset_Contact_Permissions__c where Id = :acpId];
        List<CS_Asset_Contact_Permissions__c> otherACPs;
        if (acp != null) {
            otherACPs = [Select Id,CS_Contact__r.Name, CS_Contact__c, CS_Product__c from CS_Asset_Contact_Permissions__c where CS_Product__c = :acp.CS_Product__c];
        }
        
        return otherACPs;
    }
    
    
    @AuraEnabled
    public static Boolean getAssetODC() {
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null) {
            acpList = [Select Id, CS_Asset__r.CS_ODC_Status__c from CS_Asset_Contact_Permissions__c where CS_Asset__r.CS_ODC_Status__c = 'Active' and CS_Contact__c = :user.ContactId];
        }
        if (acpList != null && !acpList.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
*/
//Fixed for DE701
    @AuraEnabled
    public static Boolean getAssetODC(String assetId) {
        List<Asset> assets = [Select Id, CS_ODC_Status__c,CS_RCS_Active_Customer__c from Asset 
                              where Id = :assetId  and (CS_ODC_Status__c = 'Active' or  CS_RCS_Active_Customer__c=true)];
        if (assets != null && assets.size() > 0) {
            return true;
        } else {
            return false;
        }
    }
    //RP: Added installation in the parameters
    @AuraEnabled
    public static String saveCase(Case c, String installation, String severity, String assetId, String release, Boolean odc, String category, String subCategory, String urgency, String caseType, String environmentAffected) {
        // get recordtype Id:
        Id recordTypeId = [Select Id, Name from RecordType where Name = 'Customer Support'].Id;
        c.RecordTypeId = recordTypeId;
        if (severity != null && severity != '') {
            c.Severity__c = severity;
        }if (installation != null && installation != '') {
            c.Asset_Type__c = installation;
        } if (assetId != null && assetId != '') {
            c.AssetId = assetId;
        } if (release != null && assetId != '') {
            c.CS_Product_Version__c = release;
        }
        if (odc != null) {
            c.CS_ODC__c = odc;
        }
        if (category != null && category != '') {
            c.Category__c = category;
        }
        if (subCategory != null && subCategory != '') {
            c.Sub_Category__c = subCategory;
        }
        if (urgency != null && urgency != '') {
            c.CS_Urgency__c = urgency;
        }
        //GPS - DE25/INC0065567
        if (caseType != null && caseType != '') {
            c.Case_Type__c = caseType;
        } else {
            if(installation == 'Hosted')
                c.Case_Type__c = 'Defect';
           else
                c.Case_Type__c = 'Not Applicable';
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
    
    @AuraEnabled
    public static boolean displayCaseCreationButton() {
        String userType = UserInfo.getUserType();
        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null) {
            acpList = [Select Id, CS_Access_Type__c 
                       from CS_Asset_Contact_Permissions__c 
                       where CS_Contact__c = :user.ContactId 
                       and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner')];
        }
        System.debug('user type ' + userType + ' |acpList ' + acpList);
        if ((userType == 'PowerCustomerSuccess' || userType == 'PowerPartner')&& acpList != null && !acpList.isEmpty()) {
            system.debug('Condition is true');
            return true;
        } else {
            system.debug('Condition is false');
            return false;
        }
        
    }
    
    /*
    @AuraEnabled
    public static List<String> getSubCategoryPickvals() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Sub_Category__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }       
        return options;
    }
    */
    
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
    public static List<String> getCategoryPickvals() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Case.Category__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }       
        return options;
    }

        
    @AuraEnabled
    public static List<Case> getAssetCases(String assetId) {
        System.debug('user ' + user + ' |assetId ' + assetId);
        List<Case> caseList; 
        if (user != null && user.UserType != 'PowerPartner' ) {
            caseList = [Select id, CaseNumber,Severity__c, Contact.Name, subject, CS_Standard_Product__c, Environment_Affected__c, Status, CreatedDate, Owner.Name, Asset.Name, CS_Submitted_by__c, Asset.Parent.Name, CS_Parent_Asset_Name__c,CS_Customer_Reference_Number__c, IsEscalated,CS_Associated_Jira__c
                        from Case 

                        where //  AccountId = :user.AccountId  and  /* commented for DE1382 */
                         AssetId = :assetId AND Contactid = :user.ContactId order by CaseNumber desc];
        } else if (user != null && user.UserType == 'PowerPartner' ) {
            caseList = [Select id,CaseNumber,Severity__c, Contact.Name, subject, CS_Standard_Product__c, Environment_Affected__c, Status, CreatedDate, Owner.Name, Asset.Name, CS_Submitted_by__c, Asset.Parent.Name,CS_Parent_Asset_Name__c,CS_Customer_Reference_Number__c, IsEscalated,CS_Associated_Jira__c
                        from Case 
                        where AssetId = :assetId AND Contactid = :user.ContactId order by CaseNumber desc];
        }
        System.debug('asset related cases ' + caseList);
        return caseList;
    }
    
    
    @AuraEnabled 
    public static List<Case> getCases(String organization, String status, String submittedBy) {
        System.debug('========organization ' + organization + ' | status ' + status + ' | submittedBy ' + submittedBy + ' |user ' + user);
        List<Case> caseList;

        String queryString = 'Select id, CaseNumber,Severity__c, Contact.Name,subject, CS_Standard_Product__c, Environment_Affected__c, Status, CreatedDate, Owner.Name, Asset.Name, CS_Submitted_by__c, Asset.Parent.Name,CS_Parent_Asset_Name__c,CS_Customer_Reference_Number__c, IsEscalated,CS_Associated_Jira__c,Case_Type__c,GW_Status__c,Priority_Score__c,Requested_Release_Date__c from Case';
        //queryString += ' where ( CS_Contact_Asset__r.CS_Asset_Status__c != \'Prospect\' Or CS_Contact_Asset__r.CS_Asset_Status__c != \'Certification\')';
        //queryString +=' AND CS_Contact_Asset__r.CS_Access_Type__c in (\'' + Label.Customer_Support + '\', \'' + Label.Customer_Support_View_Only + '\', \'' + Label.Partner+ '\')';

        if (organization == 'All' && status == 'Open' && submittedBy == 'Self' && user != null) {
            queryString += ' Where Status != \'Closed\' AND Status != \'Closed by customer\' AND Status != \'Verified\'';
            queryString += ' AND ContactId = \'' + user.ContactId + '\'';
        } else if (organization != 'All' && status == 'Open' && submittedBy == 'Self' && user != null) {
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
            queryString += ' AND Status != \'Closed\' AND Status != \'Closed by customer\' AND Status != \'Verified\'';
            queryString += ' AND ContactId = \'' + user.ContactId + '\'';
        } else if (organization == 'All' && status == 'Closed' && submittedBy == 'Self' && user != null) {
            queryString += ' Where (Status = \'Closed\' OR Status = \'Closed by customer\' OR Status = \'Verified\')';
            queryString += ' AND ContactId = \'' + user.ContactId + '\'';
        } else if (organization != 'All' && status == 'Closed' && submittedBy == 'Self' && user != null) {
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
            queryString += ' AND (Status = \'Closed\' OR Status = \'Closed by customer\' OR Status = \'Verified\')';
            queryString += ' AND ContactId = \'' + user.ContactId + '\'';
        } else if (organization == 'All' && status == 'Open' && submittedBy == 'Anyone' && user != null) {
            //Fixed for DE987 
            queryString += ' Where Status != \'Closed\' AND Status != \'Closed by customer\' AND Status != \'Verified\'';
        } else if (organization != 'All' && status == 'Open' && submittedBy == 'Anyone' && user != null) {
            //Fixed for DE987 
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
            queryString += ' AND Status != \'Closed\' AND Status != \'Closed by customer\' AND Status != \'Verified\'';
        } else if (organization == 'All' && status == 'Closed' && submittedBy == 'Anyone' && user != null) {
            queryString += ' Where (Status = \'Closed\' OR Status = \'Closed by customer\' OR Status = \'Verified\')';
        } else if (organization != 'All' && status == 'Closed' && submittedBy == 'Anyone' && user != null) {
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
            queryString += ' AND (Status = \'Closed\' OR Status = \'Closed by customer\' OR Status = \'Verified\')';
        } else if (organization == 'All' && status == 'All' && submittedBy == 'Self' && user != null) {
            queryString += ' Where ContactId = \'' + user.ContactId + '\'';
        } else if (organization != 'All' && status == 'All' && submittedBy == 'Self' && user != null) {
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
            queryString += ' AND ContactId = \'' + user.ContactId + '\'';
        } else if (organization == 'All' && status == 'All' && submittedBy == 'Anyone' && user != null) {
            queryString += '';
        } else if (organization != 'All' && status == 'All' && submittedBy == 'Anyone' && user != null) {
            queryString += ' Where Asset.Parent.Name = \'' + organization + '\'';
        }
        
        /*
         commented for DE1382
        if (user.UserType != 'PowerPartner' && organization == 'All' && status == 'All' && submittedBy == 'Anyone') {
            queryString += ' Where AccountId = \'' + user.AccountId + '\'';
        } else if (user.UserType != 'PowerPartner') {
            queryString += ' AND AccountId = \'' + user.AccountId + '\'';
        }
       */
        queryString +=  ' order by CaseNumber desc';
        
        System.debug(':::Cases Query' + queryString);
        caseList = Database.query(queryString);

        return caseList;
    }
    
    @AuraEnabled
    public static List<String> getParentAssets() {
        List<String> parentAssetNames = new List<String>();

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null && user.UserType !='PowerPartner' ) {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                       CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                       CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                       from CS_Asset_Contact_Permissions__c 
                       where //CS_Asset__r.AccountId = :user.AccountId  and /* commented for DE1382 */
                           CS_Asset__r.CS_Not_in_Use__c = false 
                       and CS_Asset__r.CS_Is_Active__c = true 
                       and CS_Asset_Status__c != 'Prospect'
                       and  CS_Contact__c in (select contactid from user where id =:userinfo.getUserId())
                       and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner' OR CS_Access_Type__c = 'General Customer' OR CS_Access_Type__c = 'Customer Support (View Only)')];
        } else if (user != null && user.UserType == 'PowerPartner') {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                       CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                       CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                       from CS_Asset_Contact_Permissions__c 
                       where CS_Asset__r.CS_Is_Active__c = true 
                       and CS_Asset__r.CS_Not_in_Use__c = false 
                       and CS_Asset_Status__c != 'Prospect'
                       and  CS_Contact__c in (select contactid from user where id =:userinfo.getUserId())
                       and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner' OR CS_Access_Type__c = 'General Customer' OR CS_Access_Type__c = 'Customer Support (View Only)')];
        }
        if (acpList != null && !acpList.isEmpty()) {
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                parentAssetNames.add(acp.CS_Asset_Name__c);
            }
        }
        system.debug('parentAssetNames===='+parentAssetNames);
        return parentAssetNames;
    }
    
    @AuraEnabled
    public static List<String> getOrganizationForCaseCreation() {
        List<String> parentAssetNames = new List<String>();

        List<CS_Asset_Contact_Permissions__c> acpList;
        if (user != null && user.UserType != 'PowerPartner') {
            acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                       CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                       CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                       from CS_Asset_Contact_Permissions__c 
                       where //CS_Asset__r.AccountId = :user.AccountId and /* commented for DE1382 */
                        CS_Asset__r.CS_Not_in_Use__c = false 
                       and CS_Asset__r.CS_Is_Active__c = true and CS_Contact__c = :user.ContactId
                       and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner')];
        } else if (user != null && user.UserType == 'PowerPartner') {
             acpList = [Select Id, CS_Asset__c, CS_Release_Version__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c,
                        CS_Contact_Type__c, CS_Access_Type__c, CS_Asset__r.CS_Product_Version__r.CS_Version__c,
                        CS_Asset__r.CS_Product_Family__c, CS_Asset__r.CS_Parent_Product__c, CS_Asset__r.Status 
                        from CS_Asset_Contact_Permissions__c 
                        where CS_Asset__r.CS_Is_Active__c = true and CS_Contact__c = :user.ContactId
                        and CS_Asset__r.CS_Not_in_Use__c = false 
                        and (CS_Access_Type__c = 'Customer Support' OR CS_Access_Type__c = 'Partner' )];
        }
        if (acpList != null && !acpList.isEmpty()) {
            for (CS_Asset_Contact_Permissions__c acp : acpList) {
                parentAssetNames.add(acp.CS_Asset_Name__c);
            }
        }
    
        system.debug('parentAssetNames===='+parentAssetNames);
        return parentAssetNames;
    }
    
    @AuraEnabled
    public static List<Asset> getChildAssets(String organization) {
        List<Asset> childAssets;
        if (user != null) {
            childAssets = [Select Id, Parent.Name, Name, ParentId,CS_SaaS_Url__c, Product2Id,CS_Product_Set_Name__c,CS_Support_Group__c, Product2.Name, Status 
                           from Asset 
                           where //AccountId = :user.AccountId and /* commented for DE1382 */
                           Parent.Name = :organization 
                           and cs_record_type_name__c = 'Child Asset' and CS_Hide_On_Case__c = false];
        }
        system.debug('======childAssets=====' + childAssets);
        return childAssets;
    }
    
     
     @AuraEnabled
    public static String getOrganizationByAsset(String assetId) {
        System.debug('====asset Id===== ' + assetId);
        Asset a = [Select Id, ParentId, Parent.Name from Asset where Id = :assetId];
        return a.Parent.Name;
    }
    //GPS - DE25/INC0065567 New Method returns boolean true if the Organization is hosted. 
    @AuraEnabled
        public static Boolean getAssetHosted(String organization) {
        System.Debug('::' + organization);
        List<Asset> assets = [Select Id from Asset 
                              where Name = :organization AND Is_Hosted__c = true];
        System.Debug('::assets ' +  assets );
        
        if (assets != null && assets.size() > 0) {
            return true;
        } else {
            return false;
        }
    }
}