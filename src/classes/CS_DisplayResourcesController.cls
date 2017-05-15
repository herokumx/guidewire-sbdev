/*
*****************************************************************************************************************************
Class Name - CS_DisplayResourcesController
Class Type -  Controller
Test Class-
Purpose- Display Resource Lightning Component Controller


*****************************************************************************************************************************

Name        Email         Date             Notes 
Shan xu                                    Initial Creation
ManiG                     08/30/2016       Added  CS_Major_Release_version__c to Query to Sort by Descending 
Shan Xu                   09/25/2016       Fix for DE1153
Mani                      10/24/2016       Fixed for DE1382         
*****************************************************************************************************************************
*/
public with sharing class CS_DisplayResourcesController {

    @AuraEnabled
    public static String getUserType() {
        String userType = UserInfo.getUserType();
        System.debug('userType ' + userType);
        return userType;
    }
   
   
     @AuraEnabled
    public static User getCurrentUser() {
      User toReturn = [SELECT Id, CS_Profile_Name__c,FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return toReturn;
  }
    
  
    @AuraEnabled
    public static List<Map<String, String>> getProductResources (String productGroup, String product, String version, String language) {
        
        // get current user 
        User user = [Select Id, AccountId, ContactId from User where Id = :UserInfo.getUserId()];
        // get current user type:
        String userType = UserInfo.getUserType();
        System.debug('userType ' + userType);
        //Map<Id, Asset> assetsMap = new Map<Id, Asset>([Select Id, CS_Product__c from Asset where ContactId = :user.ContactId]);
        
        Set<Id> assetIds = new Set<Id>();
        //get customer account's assets
        /* commented for DE1382 */
        Map<Id, Asset> assetsMap = new Map<Id, Asset>([Select Id, CS_Product__c from Asset /*where AccountId = :user.AccountId*/]);
        
        Set<Id> customerAssetIds = new Set<Id>();
        /* commented for DE1382 */
        List<Asset> assets = [Select Id, Status, CS_Product__c from Asset  /* where AccountId = :user.AccountId*/];
        for (Asset a : assets) {
            if (a.Status == 'Production' || a.Status == 'Implementation' || a.Status =='Prospect') {
                
                customerAssetIds.add(a.Id);
            }
        }
        
        // get partner assets by ACP
        List<CS_Asset_Contact_Permissions__c> partnerAssets = [Select Id, CS_Asset__c, CS_Asset_Name__c, CS_Asset_Status__c, CS_Product__c, CS_Contact_Type__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c where CS_Contact__c = :user.ContactId and CS_Access_Type__c = 'Certified'];
        Set<Id> parentAssetIds = new Set<Id>();
        for (CS_Asset_Contact_Permissions__c acp: partnerAssets) {
            parentAssetIds.add(acp.CS_Asset__c);
        }
        // query child assets
        Map<Id, Asset> partnerChildAssets = new Map<Id, Asset>([Select Id from Asset where ParentId in :parentAssetIds]);
        
        if (userType == 'PowerCustomerSuccess') {
             //assetIds = assetsMap.keySet();
             assetIds.addAll(customerAssetIds);
        }
        
        if (userType == 'PowerPartner') {
            assetIds = partnerChildAssets.keySet();
        }
        System.debug('assetIds ' + assetIds);
        System.debug('productGroup ' + productGroup + ' | product ' + product + ' | version ' + version + ' | language ' + language);
        // Added  by Mani CS_Major_Release_version__c to Query to Sort by Descending 
        String queryString = 'Select Id, CS_Box_File_Id__c, Name,CS_Major_Release_version__c, (Select Id, Name, CS_Release__c from Software_Downloads__r where CS_Asset__c in :assetIds), (Select Id, Name, CS_External_Url__c, CS_Type__c, CS_DocumentId__c from Product_Documentation__r) from CS_Release__c';
        queryString += ' WHERE ((CS_Release_Type__c =\'Gold Master\' and CS_IsActive__c=False) or (CS_Release_Type__c!=\'Gold Master\' and CS_IsActive__c=true))';
        if (productGroup != 'None' && productGroup != null) {
            queryString += ' AND CS_Product__r.Product_Group_Name__c = \'' + productGroup + '\'';
        }
        if (product != 'None' && product != null && productGroup != 'None' && productGroup != null) {
            queryString += ' AND CS_Product__r.Name = \'' + product + '\'';
        } else if (product != 'None' && product != null && (productGroup == 'None' || productGroup == null)) {
            queryString += ' AND CS_Product__r.Name = \'' + product + '\'';
        }
        if (version != 'None' && version != null) {
            queryString += ' AND CS_Version__c = \'' + version + '\''; 
        }
        if (language != 'None' && language != null) {
            queryString += ' AND CS_Localization__c = \'' + language +'\'';
        }

        queryString += ' Order by CS_Major_Release_version__c Desc ';
        System.debug('========queryString==== ' + queryString);
        List<CS_Release__c> releases = Database.query(queryString);
    
        Set<Id> linkedEntityIds = new Set<Id>();
        for (CS_Release__c r : releases) {
            System.debug('===========softwareDownloads===== ' + r.Software_Downloads__r);
            for (CS_Software_Downloads__c sd : r.Software_Downloads__r) {
                linkedEntityIds.add(sd.CS_Release__c);
            }
            for (CS_Product_Documentation__c pd : r.Product_Documentation__r) {
                linkedEntityIds.add(pd.Id);
            }
        }
    
        System.debug('====linkedEntityIds===' + linkedEntityIds.size());
        // Modified by Mani G on 08/18/2016 - added Map to avoid nested for loops
        Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
        if (linkedEntityIds != null && !linkedEntityIds.isEmpty()) {
            for(ContentDocumentLink cdl : [Select ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.Description, LinkedEntityId 
                                            from ContentDocumentLink 
                                           where LinkedEntityId in :linkedEntityIds]){
                cdlMap.put(cdl.LinkedEntityId, cdl);
            }
        }
        System.debug('=====cdlMap===== ' + cdlMap);
        List<Map<String, String>> resources = new List<Map<String,String>>();
        for (CS_Release__c r : releases) {
            Map<String, String> releaseMap = new Map<String, String>();
            if (r.Software_Downloads__r.size() > 0 || r.Product_Documentation__r.size()>0) {
                releaseMap.put('name', r.Name);
                
                // mapping software link to release
                for (CS_Software_Downloads__c sd : r.Software_Downloads__r) {
                    // Modified by Mani G on 08/18/2016 - added Map to avoid nested for loops
                    
                    releaseMap.put('boxLink', r.CS_Box_File_Id__c);
                    
                }
            
                 // mapping product documentation link to release
                for (CS_Product_Documentation__c pd : r.Product_Documentation__r) {
                    if (pd.CS_Type__c == 'Release Notes') {
                        releaseMap.put('releaseNotesExternalUrl', pd.CS_External_Url__c);
                   } else if (pd.CS_Type__c == 'Documentation') {
                         releaseMap.put('documentationExternalUrl', pd.CS_External_Url__c);
                    }
                    if (pd.CS_Type__c == 'Release Notes') {
                        releaseMap.put('releaseNotesDocumentId', pd.CS_DocumentId__c);
                    } else if (pd.CS_Type__c == 'Documentation') {
                        releaseMap.put('documentationDocumentId', pd.CS_DocumentId__c);
                    }
                    // Modified by Mani G on 08/18/2016 - added Map to avoid nested for loops
                    if (cdlMap.containsKey(pd.Id)){
                        if (pd.CS_Type__c == 'Release Notes') {
                            releaseMap.put('releaseNotesLink', cdlMap.get(pd.Id).ContentDocument.LatestPublishedVersionId); 
                        } else if (pd.CS_Type__c == 'Documentation') {
                            releaseMap.put('documentationLink', cdlMap.get(pd.Id).ContentDocument.LatestPublishedVersionId);  
                        }
                    }
                    else {
                        if (pd.CS_Type__c == 'Release Notes') {
                            releaseMap.put('releaseNotesLink', null);
                        } else if (pd.CS_Type__c == 'Documentation') {
                            releaseMap.put('documentationLink', null);
                        }
                    }
                }
                resources.add(releaseMap);
            }
            //System.debug('======resources======' + resources);
        
        } 
        
        return resources;
    }

    // outh with box
    @AuraEnabled
    public static String redirectToBox(String boxlink){

        CS_BoxTokens__c bkToken = CS_BoxTokens__c.getValues('BoxDev');
        List<CS_Release__c> relList;
        String relId = '';

        //String refreshToken = 'TBMGASKlwGMDOIqLPB6sh2vFn0Ywd3WYQVWmvxTp6DkBuzxGxQT4mMaHDtUVevz2';
        //String clientid = '4n9xhtn2uy2i9fxfavr9xqss0a0non1o';
        //String clientSecret = '8Fu9EOVuMbmnOWhSRs1mabqLjYzcwiI0';

        try{
            String refreshToken = bkToken.Refresh_Token__c;
            String clientid = bkToken.ClientId__c;
            String clientSecret = bkToken.ClientSecret__c;
            String accestkn = '';
            String refreshtkn = '';

            relList = [Select Id from CS_Release__c Where CS_Box_File_Id__c =:boxlink];
            
            if(relList!=null && relList.size()>0){
                relId = relList[0].Id;
            }

            Http h = new Http(); 
            HttpRequest request = new HttpRequest(); 
            string endPointURL = 'https://api.box.com/oauth2/token'; 
            request.setEndpoint(endPointURL);    
            request.setBody('Content-Type=' + EncodingUtil.urlEncode('application/x-www-form-urlencoded', 'UTF-8') + '&charset=' + EncodingUtil.urlEncode('UTF-8', 'UTF-8') 
                        + '&refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8') + 
                        + '&client_id=' + EncodingUtil.urlEncode(clientid, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') 
                        + '&grant_type=' + EncodingUtil.urlEncode('refresh_token', 'UTF-8')); 
            request.setMethod('POST'); 
            
            HttpResponse response = h.send(request);
            system.debug('body..'+response.getBody());  
          
            if (response.getStatus() == 'OK') {
                JSONParser parser = JSON.createParser(response.getBody());
                    while (parser.nextToken() != null) {
                        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                            String fieldName = parser.getText();
                            parser.nextToken();
                            if(fieldName == 'access_token') {
                                accestkn= parser.getText();
                            }if(fieldName == 'refresh_token') { 
                                refreshtkn= parser.getText();
                            }
                        } 
                } 
                

                h = new Http();
                HttpRequest req = new HttpRequest();
                string endPointValue = 'https://api.box.com/2.0/files/';
                //endPointValue=endPointValue+'73858631305'+'/content';
                endPointValue=endPointValue + boxlink +'/content';
                req.setEndpoint(endPointValue);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer '+accestkn);
                HttpResponse res = h.send(req);       
                system.debug('loc..'+res.getHeader('Location')); 

                if(String.isNotBlank(refreshtkn)){
                    bkToken.Refresh_Token__c = refreshtkn;
                    update bkToken;
                }           


                if (res.getStatus() == 'Found') {   

                    CS_Software_Download_Metrics__c softDownload = new CS_Software_Download_Metrics__c();                

                    softDownload.CS_Download_Date_Time__c = System.Now();
                    softDownload.CS_Downloaded_By__c = UserInfo.getUserId();
                    softDownload.CS_Download_File__c = boxlink;
                    if(relList != null && relList.size()>0){
                        softDownload.CS_Download_Release__c = relList[0].Id;
                    }
                    system.debug('softDownload..'+softDownload); 
                    insert softDownload;                            
                }
              
                return res.getHeader('Location');

            }else {
                    sendEmailMssg(bkToken.Access_Token__c, relId);
                    return 'ErrorDownloadingFile';  
            }  
        }catch (Exception ex){
       
            system.debug('BoxApiConnection unable to use refresh token to generate new access token from community: ' + ex.getMessage());
            // Send Email
            
            sendEmailMssg(bkToken.Access_Token__c, relId);
            return 'ErrorDownloadingFile';        
        }                  
    }

    
    public static void sendEmailMssg(String emailId, String releaseId){

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {emailId};
        mail.setToAddresses(toAddresses);                  
        mail.setSubject(' Software download failed for file from community - '+releaseId);                
        mail.setPlainTextBody('Software download failed from community for user ' + UserInfo.getUserId() + ' , please check that refresh token exists in custom setting Box Token');            
        mail.setUseSignature(false);
        mail.saveAsActivity = false;
        mail.setCharset('UTF-8');
             
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
            mail
        }); 
    }
}