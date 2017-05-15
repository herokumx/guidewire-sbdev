/*
*****************************************************************************************************************************
Class Name - CS_CommunityContentController
Class Type -  Controller
Test Class-
Purpose- Controller class for Dynamic Content Lightning Component


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan Xu                        05/13/2016       Initial Creation

*****************************************************************************************************************************
*/
public class CS_CommunityContentController {
    @AuraEnabled
    public static List<CS_Content_Access__c> getContentAccess(String location,String community) {
        //system.debug('contentId: '+contentId);
        CS_Community_Content__c content = getCommunityContent(location,community);
        String currUserProfile = [select Id, Name from Profile where Id =: UserInfo.getProfileId() limit 1].Name;
        List<CS_Content_Access__c> caList = [Select Id, CS_Content__c, CS_Profile__c, CS_User__c from CS_Content_Access__c where CS_Content__c =: content.Id and (CS_User__c =: UserInfo.getUserId() or CS_Profile__c =: currUserProfile)];
        system.debug('caList: '+caList.size());
        return caList;
    }   

    @AuraEnabled
    public static Id getCurrentUser() {
        User user = [Select Id, AccountId,CS_Profile_Name__c, ContactId from User where Id = :UserInfo.getUserId()];
        return user.Id;
    }
 @AuraEnabled
    public static User getCurrentUserforContent() {
      User toReturn = [SELECT Id, AccountId,ContactId,CS_Profile_Name__c,FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return toReturn;
  }

    // subquery version:
    @AuraEnabled
    public static CS_Community_Content__c getCommunityContent(String location,String community) {
        system.debug('****location: '+location);
        CS_Community_Content__c ccList = [select CS_Title__c, 
                                                    CS_Location__c, 
                                                    CS_Content__c, 
                                                    CreatedById, 
                                                    CreatedDate,                                                    
                                                    CS_Popup__c,
                                                    CS_Popup_Link__c,
                                                    CS_Modal_Content__c,
                                                    Id, 
                                                    CS_Rich_Content_Title__c,
                                                    IsDeleted, 
                                                    LastModifiedById, 
                                                    LastModifiedDate, 
                                                    Name, 
                                                    OwnerId, 
                                                    CS_Sort_Order__c,
                                                    SystemModstamp, 
                                                    CS_community__c,
                                                    CS_Type__c,

                                                    (Select id,CS_content__c,name,CS_profile__c,CS_user__c from Content_Access__r) 
                                                from CS_Community_Content__c 
                                                where CS_Location__c =: location
                                                and  CS_community__c=:community
                                                and CS_Status__c = 'Active'
                                                order by CS_Sort_Order__c asc];
        return ccList;
    }
    
    @AuraEnabled
    public static String redirecttoSabaURL(){
        
        string email = '';
        string firstName = ''; 
        string lastName = '';
        
        
        List<User> usr = [Select Contact.Email,Contact.FirstName,Contact.LastName From User Where username=:userinfo.getUserName()];
    
        if(!usr.isEmpty()){
            email = usr[0].Contact.Email;
            firstName = usr[0].Contact.FirstName;
            lastName = usr[0].Contact.LastName;
        }
      
        string alg = 'HS256';
        Integer validFor = 300;
        string privateKey = 'bobsyouruncle';
        //email = 'avasamplesaba@gmail.com';
        string externalId = ''; 
        String jwt = '';
        Long tokenId;
        system.debug('enter..');
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', alg);
        header.writeStringField('typ', 'jwt');
        header.writeEndObject();
        String encodedHeader = encodingUtil.base64Encode(Blob.valueOf(header.getAsString()));
        system.debug('enter.00.');   
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        
        Long rightNow = (dateTime.now().getTime());
        validFor = 1000000;
        body.writeNumberField('iat', rightNow);
        
        tokenId = (dateTime.now().getTime());
        body.writeNumberField('jti',tokenId);
        
        body.writeStringField('name',firstName+' '+lastName);
        body.writeStringField('email', email);
        body.writeStringField('external_id',externalId);
        body.writeNumberField('exp', (rightNow + validFor));
        system.debug('enter.11.');    
        body.writeEndObject();
        
        jwt = encodedHeader + '.' + encodingUtil.base64Encode(Blob.valueOf(body.getAsString()));
        
        Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueOf(jwt),Blob.valueOf(privateKey));
        
        String finalToken = jwt  + '.' + EncodingUtil.base64Encode(signature);
        
        jwt = EncodingUtil.urlEncode(finalToken,'UTF-8');
        
        finalToken = finalToken.replace('+', '%2B');
        finalToken = finalToken.replace('=', '%3D');
        String jwCert = 'https://guidewire-partnerlearning.sabacloud.com/Saba/Web/cert/SSO?' + 'jwtCert=' + finalToken;
        //PageReference pg = new PageReference(jwCert);
        return jwCert;
    }
    
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }
    
    @AuraEnabled
    public static boolean displaySabaRedirectLink() {
        List<User> usrList = [SELECT id,name FROM user where username=:userinfo.getUserName() AND
                                (contact.CS_Business_Sales__c = true OR contact.CS_Technical_Sales__c = true)];
            
        System.debug('usrList : ' + usrList);
        if (usrList != null && !usrList.isEmpty()) {
            system.debug('Condition is true');
            return true;
        } else {
            system.debug('Condition is false');
            return false;
        }
    }

    
}