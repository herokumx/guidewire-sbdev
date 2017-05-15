public with sharing class CS_BoxTokenGenerator{
    
    static String clientid;
    static String clientSecret;

    static{

        CS_BoxTokens__c bkToken = CS_BoxTokens__c.getValues('BoxDev');        
        clientid = bkToken.ClientId__c;
        clientSecret = bkToken.ClientSecret__c;
    }

/*

    public PageReference downloadFile() {
    
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    string endPointValue = 'https://api.box.com/2.0/files/';
    endPointValue=endPointValue+'73858631305'+'/content';
//endPointValue=endPointValue+'11039263987';
    req.setEndpoint(endPointValue);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer '+this.accessToken);
    HttpResponse res = h.send(req);
    system.debug('res'+res);
    system.debug('pANY'+res.getBody());
    system.debug('pANY'+res.getHeader('Location'));
        pageReference pr = new pageReference(res.getHeader('Location'));
        return pr;
    }
*/ 
    private string codeFromBox; 

    String redirectURI = 'https://guidewire--c.na29.visual.force.com/apex/CS_BoxTokenGenerator';
    //String loginUri = 'https://account.box.com/api/oauth2/authorize'; 
    String header = '';
    String endpoint = '';
  
    public String accessToken {get; set;}
    
    public String refreshToken {get; set;}
    

   

    public CS_BoxTokenGenerator(){
        this(false);
    }  

    public CS_BoxTokenGenerator(boolean flag){
        if(flag == false )
        {
        if(System.currentPageReference().getParameters().get('code') != null ){
            codeFromBox = System.currentPageReference().getParameters().get('code'); 
        }
        system.debug(codeFromBox);
        
            if((codeFromBox == '' || codeFromBox == null) ){ 
                system.debug('iff');
                PageReference pr = new PageReference('https://www.box.com/api/oauth2/authorize?' + 'response_type=code' + '&client_id=' + clientid + '&redirect_uri=' + redirectURI); 
            }else{
                system.debug('elsee');
                redirectbox();
            }
        }
    }
    

    public PageReference connectBox(){
        /*
        CS_BoxTokens__c bkToken = CS_BoxTokens__c.getValues('BoxDev');
        String refreshToken = bkToken.Refresh_Token__c;
        String clientid = bkToken.ClientId__c;
        String clientSecret = bkToken.ClientSecret__c;
        */
        system.debug('clientid:::::::'+clientid);

        if(codeFromBox == '' || codeFromBox == null){ 
            system.debug('iff');  

        Http h = new Http(); 
        HttpRequest req = new HttpRequest(); 
        //  login uri for box = https://account.box.com/api/oauth2/authorize
        string endPointValue = 'https://account.box.com/api/oauth2/authorize'; 
        req.setEndpoint(endPointValue);
        req.setBody('client_id=' +EncodingUtil.urlEncode(clientid, 'UTF-8')
                    + '&redirect_uri=' + EncodingUtil.urlEncode(redirectURI, 'UTF-8')
                    + '&response_type=code'); 
        req.setMethod('POST'); 
       
            PageReference pr = new PageReference('https://www.box.com/api/oauth2/authorize?' + 'response_type=code' + '&client_id=' + clientid + '&redirect_uri=' + redirectURI); 
            return pr; 
        }
        return null;
    }
/*
    public void tokenrefresh(){

        Http h = new Http(); 
        HttpRequest req = new HttpRequest(); 
        string endPointValue = 'https://api.box.com/oauth2/token'; 
        req.setEndpoint(endPointValue);    
        req.setBody('Content-Type=' + EncodingUtil.urlEncode('application/x-www-form-urlencoded', 'UTF-8') + '&charset=' + EncodingUtil.urlEncode('UTF-8', 'UTF-8') 
                    + '&refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8') + 
                    + '&client_id=' + EncodingUtil.urlEncode(clientid, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') 
                    + '&grant_type=' + EncodingUtil.urlEncode('refresh_token', 'UTF-8')); 
        req.setMethod('POST'); 
        system.debug('red..');
        HttpResponse response = h.send(req);
        if (response.getStatus() == 'OK') {
            BoxGenericJsonObject authResponse = new BoxGenericJsonObject(response.getBody());
            this.setnAccessToken(authResponse.getValue('access_token'));             
         
        } else {
            system.debug('BoxApiConnection unable to use refresh token to generate new access token: ' + response.toString());
        }        
        system.debug('accessToken..'+naccessToken);
        
        //return new PageReference('https://guidewire--gforcedev--c.cs19.visual.force.com/apex/TestDownloadPage?acc='+this.accessToken);
        //header = string.valueOf(mapReqBody.get('token_type')) + ' ' + string.valueOf(mapReqBody.get('access_token'));
        
    }

*/
    
    public void redirectbox(){

        system.debug('clientid:::::::'+clientid);
        system.debug('codeFromBox:::::::'+codeFromBox);
        system.debug('clientSecret:::::::'+clientSecret);
        system.debug('redirectURI:::::::'+redirectURI);      
        if(codeFromBox == null) codeFromBox = '';


        Http h = new Http(); 
        HttpRequest req = new HttpRequest(); 
        string endPointValue = 'https://api.box.com/oauth2/token'; 
        req.setEndpoint(endPointValue);    
        req.setBody('Content-Type=' + EncodingUtil.urlEncode('application/x-www-form-urlencoded', 'UTF-8') + '&charset=' + EncodingUtil.urlEncode('UTF-8', 'UTF-8') 
                    + '&grant_type=' + EncodingUtil.urlEncode('authorization_code', 'UTF-8') + '&code=' + EncodingUtil.urlEncode(codeFromBox, 'UTF-8') 
                    + '&client_id=' + EncodingUtil.urlEncode(clientid, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') 
                    + '&redirect_uri=' + EncodingUtil.urlEncode(redirectURI, 'UTF-8')); req.setMethod('POST'); 
        system.debug('red..');
        HttpResponse response = h.send(req);
        if (response.getStatus() == 'OK') {
            JSONParser parser = JSON.createParser(response.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                        String fieldName = parser.getText();
                        parser.nextToken();
                        if(fieldName == 'access_token') {                           
                            this.setAccessToken(parser.getText());
                            
                        }if(fieldName == 'refresh_token') {                            
                            this.setRefreshToken(parser.getText());
                        }
                    } 
            } 
        } else {
            system.debug('BoxApiConnection unable to use refresh token to generate new access token: ' + response.toString());
        }        
        system.debug('accessToken..'+accessToken);
        system.debug('refreshToken..'+refreshToken);        
        
    }


    public String getAccessToken() {        
        return this.accessToken;
    }

     public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String getRefreshToken() {
        return this.refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }
/*
    public String getnAccessToken() {        
        return this.naccessToken;
    }

     public void setnAccessToken(String naccessToken) {
        this.naccessToken = naccessToken;
    }

     public String getAccessToken1() {        
        return this.accessToken1;
    }

     public void setAccessToken1(String accessToken1) {
        this.accessToken1 = accessToken1;
    }

    
     
    public string getHTTPResponse(String endpoint, String header, String method){
        HttpRequest req = new HttpRequest();  
        req.setMethod(method);
        req.setEndpoint(endpoint);
        if(header != ''){
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', header);
        }
        Http httpReq = new Http();  
        HTTPResponse res = httpReq.send(req);
        //system.debug(res);

        return res.getBody();
    } 
    */

}