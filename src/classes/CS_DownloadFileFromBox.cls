global class CS_DownloadFileFromBox {


    //Method which gets invoked from the button. 
    webservice static String downloadBoxFile(string boxFileId){ 

    	CS_BoxTokens__c bkToken = CS_BoxTokens__c.getValues('BoxDev');
    	List<CS_Release__c> relList;
    	String relId = '';
        
        try{        	
	      
	        String refreshToken = bkToken.Refresh_Token__c;
	        String clientid = bkToken.ClientId__c;
	        String clientSecret = bkToken.ClientSecret__c;
	        String accestkn = '';
	        String refreshtkn = '';
	        String exceptionMessage = '';

	        relList = [Select Id from CS_Release__c Where CS_Box_File_Id__c =:boxFileId];

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

	            system.debug('accestkn..'+accestkn);   

		        h = new Http();
		        HttpRequest req = new HttpRequest();
		        string endPointValue = 'https://api.box.com/2.0/files/';		       
		        endPointValue=endPointValue + boxFileId +'/content';
		        req.setEndpoint(endPointValue);
		        req.setMethod('GET');
		        req.setHeader('Authorization', 'Bearer '+accestkn);
		        HttpResponse res = h.send(req);       
		        system.debug('loc..'+res.getHeader('Location')); 
		        String errorMessage='';

		        if(String.isNotBlank(refreshtkn)){
                    bkToken.Refresh_Token__c = refreshtkn;
                    update bkToken;
                }  

		        if (res.getStatus() == 'Found') {	
		        		        	       

			        CS_Software_Download_Metrics__c softDownload = new CS_Software_Download_Metrics__c();		            

		            softDownload.CS_Download_Date_Time__c = System.Now();
		            softDownload.CS_Downloaded_By__c = UserInfo.getUserId();
		            softDownload.CS_Download_File__c = boxFileId;
		            if(relList != null && relList.size()>0){
		                softDownload.CS_Download_Release__c = relList[0].Id;
		            }
		            system.debug('softDownload..'+softDownload); 
		            insert softDownload; 
	        	}
	        	String successMessage='';	        	

		        return res.getHeader('Location'); 

		        } else {
		        	sendEmailMssg(bkToken.Access_Token__c, relId);
		            return relId;
		        } 
	        
	                   
        }catch(Exception e){
            system.debug('Call to BOX failed from Release page - '+e.getMessage());

            sendEmailMssg(bkToken.Access_Token__c, relId);
            return relId;
        }        
    }

    public static void sendEmailMssg(String emailId, String releaseId){

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {emailId};
        mail.setToAddresses(toAddresses);                  
        mail.setSubject(' Software download failed from Release record for file - '+releaseId);                
        mail.setPlainTextBody('Software download failed from Release record for user ' + UserInfo.getUserId() + ' , please check that refresh token exists in custom setting Box Token');            
        mail.setUseSignature(false);
        mail.saveAsActivity = false;
        mail.setCharset('UTF-8');
             
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
            mail
        }); 
    }
}