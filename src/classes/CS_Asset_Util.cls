/*
******************************************************************************************************************************
Controller Class Name- CS_Asset_Util
Object - Asset
Purpose- Trigger Handler , Asset util Class to Process ACP and SD on Future 
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Mani G   manig@slalom.com  08/25/2016    Modified for DE433
Mani G   manig@slalom.com  08/26/2016    Modified for DE433 (Only Minor Releases Linked to Major releases  SDs will be created 
                                         for Partner Certified Asset)
Mani G   manig@slalom.com  08/27/2016   Added No_longer_with_firm__c Check on Contact Query           
Mani G   manig@slalom.com  09/07/2016   Added a Check CS_No_Customer_Contact__c on Parent Asset DE362                        
*****************************************************************************************************************************
*/
public class CS_Asset_Util {
    
    private static CS_ByPass__c bypass {
        get {
            return  CS_ByPass__c.getInstance(UserInfo.getUserId());
        }
    }
    
   // @future()
    public static void createACP(Set<Id> accountIdSet, Set<Id> assetIdSet) {

        // query asset related customer account 
        List<Account> relatedCustomerAccounts = [Select Id, IsPartner from Account where Id in :accountIdSet];
        
        // query all contacts related to account list queried previously
        List<Contact> allAccountContacts = [Select Id, AccountId,Account.ispartner,Account.RecordType.Name,Account.CS_DM_Included_in_ACP_Creation__c,CS_Access_Type__c,email,name,firstname,lastname,title,Phone
                                             from Contact where AccountId in :relatedCustomerAccounts and RecordType.Name = 'Support' and No_longer_with_firm__c=false];
        System.debug('Contact Data==' +allAccountContacts);
        // create a map to map from account Id to contacts
        Map<Id, List<Contact>> accountToContactMap = new Map<Id, List<Contact>>();
        for (Contact c : allAccountContacts) {
           
		   // Rohit : Updated code to bypass partner check and create ACP as General Partner for all the partners related to the Account.
		    if(c.Account.RecordType.Name =='Customer' || (c.Account.CS_DM_Included_in_ACP_Creation__c != null && c.Account.CS_DM_Included_in_ACP_Creation__c)){
                if (!accountToContactMap.containsKey(c.AccountId)) {
                    accountToContactMap.put(c.AccountId, new List<Contact>());
                }
                    accountToContactMap.get(c.AccountId).add(c);
            }
			//CS_DM_Included_in_ACP_Creation__c
		   
		   // ACP creation not required for Partners.
		   /*
            else if(c.account.ispartner == True && c.CS_Access_Type__c =='Certified'){
                if (!accountToContactMap.containsKey(c.AccountId)) {
                    accountToContactMap.put(c.AccountId, new List<Contact>());
                }
                    accountToContactMap.get(c.AccountId).add(c);
            }*/
        }

        //query asset
        // Rohit: Updated Quesry to exclude -- and product2id !=null
        List<Asset> assets = [Select Id,status, Product2Id,product2.Product__c,CS_Account_Name__c, CS_Product__c, CS_Product_Version__c, Account.IsPartner,Account.Name,Account.RecordType.Name 
                                from Asset 
                                where Id in :assetIdSet and CS_No_Customer_Contact__c=false];
                                
        System.debug('Cassets' +assets);                        
        List<CS_Asset_Contact_Permissions__c> acpList = new List<CS_Asset_Contact_Permissions__c>();
        system.debug('Assets==' + assets);
        for (Asset a : assets) {            
            if(accountToContactMap.get(a.AccountId) != null){
                for (Contact c : accountToContactMap.get(a.AccountId)) {
                    CS_Asset_Contact_Permissions__c ac = new CS_Asset_Contact_Permissions__c();
                    if(a.status=='Prospect'){
                        ac.CS_Access_Type__c = 'Prospect';  
                    }
                    else{
                    ac.CS_Access_Type__c = c.CS_Access_Type__c;
                    }
                    ac.CS_Asset__c = a.Id;
                    ac.CS_Contact__c=c.Id;
                    ac.Name=c.name;
                    acpList.add(ac);
                }
            }
        }

        Set<Id> insertedACPIds = new Set<Id>();
        if (acpList != null && !acpList.isEmpty()) {
                try {
                    Database.SaveResult[] srList = Database.insert(acpList, false);
                    for(Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            insertedACPIds.add(sr.getId());                        
                        } else {
                            for (Database.Error err : sr.getErrors()) {
                                System.debug('The following Erro has occured ' + err.getStatusCode() + ': ' + err.getMessage());
                                 CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting ACP'+ err.getMessage(),'CS_Asset_Util.createACP ');
                            }
                        }
                    }
                } catch(DmlException e) {
                    System.debug('DML Exception on ACP Creation' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting ACP'+ e.getMessage(),'CS_Asset_Util.createACP ');
                }
            }
    }


    //@future()
    public static void createSoftwareDownloads(Set<Id> assetIdSet) {
        System.debug('assetIdSet ' + assetIdSet);
        Map<String, List<String>> productToVersionMap = new Map<String, List<String>>();
        Map<Id, Id> productToParentMap = new Map<Id, Id>();
        Map<Id, Id> assetProductToParentMap = new Map<Id, Id>();

        Set<Id> parentproductIds = new Set<Id>();
        Set<Id> versionIds = new Set<Id>();
        Set<Id> assetProductVersionIds = new Set<Id>();

         Map<Id,String> AssetReleaseMap= new Map<Id,String>();
         Map<Id,CS_Release__c> RelMap=new Map<Id,CS_Release__c>();


    
            String queryString = 'Select Id,status, Product2Id,product2.Product__c, CS_product_version__r.CS_Major_Release_version__c,CS_Product_Version__c, Account.IsPartner,Account.Name,Account.RecordType.Name from Asset where';
            if(bypass.CS_Use_Standard_Product__c == TRUE){
                
                queryString += ' Id in :assetIdSet';
            }else{
                
                queryString += ' Id in :assetIdSet and product2id!=null';
            }
            system.debug('++++++++++Query+++++++++'+queryString);
            List<Asset> assets = Database.query(queryString);
            
            for (Asset a : assets) {

                
                
            // Customer Implementation and Production   Asset
            if (a.Account.RecordType.Name == 'Customer' && a.Product2Id != null && a.status !='Prospect') {
                    parentproductIds.add(a.product2Id);
                    productToParentMap.put(a.Product2Id, a.Product2Id);
                    
            }
            // Prospect  Evaluation Asset
            //if ( a.Account.RecordType.Name == 'Prospect' && a.CS_Product_Version__c != null) {
            if (  a.CS_Product_Version__c != null && (a.Account.RecordType.Name == 'Prospect'  || a.status== 'Prospect' )) {
                assetProductVersionIds.add(a.CS_Product_Version__c);
                assetProductToParentMap.put(a.Product2Id, a.CS_Product_Version__c);
            }
            // Partner Certified Asset old Logic 
            /*
            if (a.Account.RecordType.Name == 'Partner' && a.CS_Product_Version__c != null  && a.status=='Certification'){
                assetProductVersionIds.add(a.CS_Product_Version__c);
                assetProductToParentMap.put(a.Product2Id, a.CS_Product_Version__c);
            }
            */
            // Partner Certified Asset New  Logic  Reference DE433
            
            if (a.Account.RecordType.Name == 'Partner' && a.CS_Product_Version__c != null  && a.status=='Certification'){
                parentproductIds.add(a.product2Id);
                productToParentMap.put(a.Product2Id, a.Product2Id);
                AssetReleaseMap.put(a.id,a.CS_product_version__r.CS_Major_Release_version__c);
            }
            

        }

        if(AssetReleaseMap!=null && !AssetReleaseMap.isEmpty()){        
                    RelMap= New Map<Id,CS_Release__c>(
                                                  [Select id,CS_Product__c from CS_Release__c where CS_Product__c in 
                                                   (Select product2id from Asset where Id in :AssetReleaseMap.keyset() )
                                                    and CS_Major_Release_version__c in :AssetReleaseMap.values()]);                                             
            }
            system.debug('++++++++'+RelMap+'++++++++');

        // get all products that are associated with the assets (for customer only)
        List<Product2> products = [Select Id, Name, (Select CS_Product__c, CS_Major_Release_version__c,CS_Product_Version__c 
                                    from Product_Version__r where CS_IsActive__c=true) from Product2 
                                    where Id in :parentproductIds];
        //System.debug('parentproductIds' + parentproductIds + ' | products ' + products + ' | assetProductVersionIds ' + assetProductVersionIds);
        // add product version Ids to the set
        for (Product2 p : products) {
            if(!productToVersionMap.containsKey(p.Id)) {
                productToVersionMap.put(p.Id, new List<String>());
            }
            for (CS_Release__c pv : p.Product_Version__r) {
                versionIds.add(pv.Id);
                if(RelMap!=null & !RelMap.isEmpty()){  
                    if(RelMap.get(pv.id)!=null)productToVersionMap.get(p.Id).add(pv.Id);                                                        
                }
                else{
                    productToVersionMap.get(p.Id).add(pv.Id);
                }


            }
        }

        System.debug('Passed Version Ids===='+versionIds + 'assets ' + assets);
        Set<Id> contentDocumentIds = new Set<Id>();

        Map<Id, ContentDocumentLink> versionDocumentsMap = new Map<Id, ContentDocumentLink>();
        // query content document based on related product versions
        List<ContentDocumentLink> contentDocumentLinks;
        if (assetProductVersionIds != null && !assetProductVersionIds.isEmpty()) {
            contentDocumentLinks = [Select Id, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType, LinkedEntityId, ContentDocumentId 
                                                            from ContentDocumentLink 
                                                            where LinkedEntityId in :assetProductVersionIds];
        } else if (versionIds != null && !versionIds.isEmpty()) {
            contentDocumentLinks = [Select Id, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType, LinkedEntityId, ContentDocumentId 
                                                            from ContentDocumentLink 
                                                            where LinkedEntityId in :versionIds];
        }

        system.debug('File Access ==='+contentDocumentLinks);
        if (contentDocumentLinks != null && !contentDocumentLinks.isEmpty()) {
            // add content document ids to set
            for(ContentDocumentLink cdl : contentDocumentLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
                versionDocumentsMap.put(cdl.LinkedEntityId, cdl);
            }

            System.debug('versionDocumentsMap ' + versionDocumentsMap);
            System.debug('contentDocumentIds ' + contentDocumentIds);

            // query related content documents based on contentDocumentIds set
            List<ContentDocument> contentDocuments = [Select Id, Title, FileExtension, LatestPublishedVersionId, FileType from ContentDocument where Id in :contentDocumentIds];

            List<CS_Software_Downloads__c> newSoftwareDownloadList = new List<CS_Software_Downloads__c>();
            System.debug('contentDocuments ' + contentDocuments);
            CS_Software_Downloads__c sd;
                system.debug('assets ' + assets);
                for (Asset a : assets) {
                    System.debug('productToParentMap ' + productToParentMap + '********' + productToVersionMap.get(productToParentMap.get(a.Product2Id)));

                    if (productToVersionMap.get(productToParentMap.get(a.Product2Id)) != null) {
                        for (String verId : productToVersionMap.get(productToParentMap.get(a.Product2Id))) {
                            sd = new CS_Software_Downloads__c();
                            sd.CS_Asset__c = a.Id;
                            // added by Shan on 6/16
                            sd.CS_Release__c = verId;
                            if (versionDocumentsMap.get(verId)  != null) {
                                sd.CS_File_Type__c = (String)versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileType');
                                sd.CS_FileExtension__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileExtension');
                                sd.CS_File_Id__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('LatestPublishedVersionId');
                                sd.Name = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Title');
                                sd.CS_Document_Id__c=(String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Id');
                            }
                            newSoftwareDownloadList.add(sd);
                        }
                    }

                    if (assetProductToParentMap.values() != null) {
                        System.debug('assetProductToParentMap ' + assetProductToParentMap);
                        for (String verId : assetProductToParentMap.values()) {
                            sd = new CS_Software_Downloads__c();
                            sd.CS_Asset__c = a.Id;
                            // added by Shan on 6/16
                            sd.CS_Release__c = verId;
                            if (versionDocumentsMap.get(verId)  != null) {
                                sd.CS_File_Type__c = (String)versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileType');
                                sd.CS_FileExtension__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileExtension');
                                sd.CS_File_Id__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('LatestPublishedVersionId');
                                sd.Name = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Title');
                                sd.CS_Document_Id__c=(String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Id');

                            }
                            newSoftwareDownloadList.add(sd);
                        }
                    }
                }

                System.debug('productToVersionMap ' + productToVersionMap +' | newSoftwareDownloadList ' + newSoftwareDownloadList.size());
            
        
             Set<Id> insertedSoftwareDownloadIds = new Set<Id>();
            //insert newSoftwareDownloadList;
            if (newSoftwareDownloadList != null && !newSoftwareDownloadList.isEmpty()) {
                try {
                    Database.SaveResult[] srList = Database.insert(newSoftwareDownloadList, false);
                    for(Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            insertedSoftwareDownloadIds.add(sr.getId());
                            System.debug(' Sucess =====insertedSoftwareDownloadIds ' + insertedSoftwareDownloadIds);

                        } else {
                            for (Database.Error err : sr.getErrors()) {
                                System.debug('The following Erro has occured ' + err.getStatusCode() + ': ' + err.getMessage());
                                 CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting SoftwareDownload Record'+ err.getMessage(),'CS_Asset_Util.createSoftwareDownloads ');
                            }
                        }
                    }
                } catch(DmlException e) {
                    System.debug('DML Exception on Software_Downloads__c' + e.getMessage());
                     CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting SoftwareDownload Record'+ e.getMessage(),'CS_Asset_Util.createSoftwareDownloads ');
                }
            }
           
        }

        
    }
        //@future()
        public  static void deactivateProspectACP(Set<Id> assetIdSet) {
            system.debug('====assetIdSet====' +assetIdSet);
            List<Asset> AssetforUpdate= New List<Asset>();
            //List<Asset> AsstUpdate= new List<Asset>([Select id,CS_Is_Active__c from asset where id in:assetIdSet]);
 
            for(Asset Ast:[Select id,CS_Is_Active__c from asset where id in:assetIdSet] ){

                Asset AstUpdate= New Asset(id=Ast.id,CS_Is_Active__c=false);
                AssetforUpdate.add(AstUpdate);
            }

            if (AssetforUpdate != null && !AssetforUpdate.isEmpty()) {
                try {
                    update AssetforUpdate;                 
                } catch(DmlException e) {
                    System.debug('DML Exception on While deactivating  Asset ACP' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While deactivating ProspectACP'+ e.getMessage(),'CS_Asset_Util.deactivateProspectACP ');
                    
                }
            }
           
            List<CS_Asset_Contact_Permissions__c> Prospect_ACP =New List<CS_Asset_Contact_Permissions__c>();
            List<CS_Asset_Contact_Permissions__c> Prospect_ACP2Update= New List<CS_Asset_Contact_Permissions__c>([select id,CS_ISActive__c 
                                                             from CS_Asset_Contact_Permissions__c where CS_Asset__c in:assetIdSet and CS_ISActive__c=true ]);
            for(CS_Asset_Contact_Permissions__c ac: Prospect_ACP2Update ){

                 CS_Asset_Contact_Permissions__c  newAcp= New CS_Asset_Contact_Permissions__c(id=ac.id,CS_ISActive__c=false);
                 Prospect_ACP.add(newAcp);
            }

            if (Prospect_ACP != null && !Prospect_ACP.isEmpty()) {
                try {
                    update Prospect_ACP; 
                } catch(DmlException e) {
                    System.debug('DML Exception on Software_Downloads__c' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While deactivating ProspectACP'+ e.getMessage(),'CS_Asset_Util.deactivateProspectACP ');
                     
                }
            }
            

        }
        //@future()
        public  static void ActivateProspectACP(Set<Id> assetIdSet) {
            system.debug('====assetIdSet====' +assetIdSet);
            List<Asset> AssetforUpdate= New List<Asset>();
            //List<Asset> AsstUpdate= new List<Asset>([Select id,CS_Is_Active__c from asset where id in:assetIdSet]);
 
            for(Asset Ast:[Select id,CS_Is_Active__c from asset where id in:assetIdSet] ){

                Asset AstUpdate= New Asset(id=Ast.id,CS_Is_Active__c=true);
                AssetforUpdate.add(AstUpdate);
            }
            
            if (AssetforUpdate != null && !AssetforUpdate.isEmpty()) {
                try {
                    update AssetforUpdate;
                } catch(DmlException e) {
                    System.debug('DML Exception on Activating ACP' + e.getMessage());
                     CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Activating ProspectACP'+ e.getMessage(),'CS_Asset_Util.ActivateProspectACP ');
                }
            }
            List<CS_Asset_Contact_Permissions__c> Prospect_ACP =New List<CS_Asset_Contact_Permissions__c>();
            List<CS_Asset_Contact_Permissions__c> Prospect_ACP2Update= New List<CS_Asset_Contact_Permissions__c>([select id,CS_ISActive__c 
                                                             from CS_Asset_Contact_Permissions__c where CS_Asset__c in:assetIdSet and  CS_ISActive__c=false ]);
            for(CS_Asset_Contact_Permissions__c ac: Prospect_ACP2Update ){

                 CS_Asset_Contact_Permissions__c  newAcp= New CS_Asset_Contact_Permissions__c(id=ac.id,CS_ISActive__c=true);
                 Prospect_ACP.add(newAcp);
            }

            if (Prospect_ACP != null && !Prospect_ACP.isEmpty()) {
                try {
                    update Prospect_ACP; 
                } catch(DmlException e) {
                    System.debug('DML Exception on Activating Prospect ACP' + e.getMessage());
                     CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Activating ProspectACP'+ e.getMessage(),'CS_Asset_Util.ActivateProspectACP ');
                }
            }


        }


        
}