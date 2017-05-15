/**************************************************************************************
// Name          : psaFileConvertZamzar
// Date          : December 8, 2015 
// Description   : Utility class to convert non image formatted files into an image format
// Author        : CLD Partners
// Revisions     : 2015-12-08 Klassen initial version
//               : 
***************************************************************************************/
global without sharing class psaFileConvertZamzar {
	public psaFileConvertZamzar() {}

	//Variables to store PSA Combine Receipts custom setting values
	private static PSA_Combine_Receipts__c customSettingCombineReceipts;
	private static String notifyEmailList;
	private static Decimal notificationThreshold;
	private static String zamzarAPIKey;
	private static String targetFormat;
	private static String baseURLTest;// = 'https://sandbox.zamzar.com/v1/';
	private static String baseURLProd;// = 'https://www.zamzar.com/v1/';
	private static Boolean testMode;
	private static Boolean sendLowCreditsEmail;

	public static String convertedFileDescription = 'Converted using Zamzar';
	public static String targetFileIdentifier = '-conv-'; //used as part of attachment name


	/**************************************************************************************
	// Name         : getBaseURL
	// Description  : Retrieve the base URL based on input parameter or custom setting 
	//					
	// Author       : CLD Partners
	// Revisions    : 2015-12-08  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static String getBaseURL() {
		loadCustomSettingsVariables();
		if (testMode) {
			return baseURLTest;
		} else {
			return baseURLProd;
		}
	}

	/**************************************************************************************
	// Name         : testAuthentication
	// Description  : Used to verify we are able to successfully authenticate to the Zamzar 
	//					file conversion service. Return false if an error
	// Author       : CLD Partners
	// Revisions    : 2015-11-15  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static Boolean testAuthentication() {
		Try {
			HttpResponse res = processGETRequest('formats/gif', false);
			return true;
		} Catch (Exception ex) {
			System.debug('Error authenticating to Zamzar service:' + ex);
			return false;
		}
	}

	/**************************************************************************************
	// Name         : processGETRequest
	// Description  : Make a GET request and return the HTTP Response results. Includes 
	//					logic to handle a redirect
	// Author       : CLD Partners
	// Revisions    : 2015-11-15  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static HTTPResponse processGETRequest(String endpointSuffix, Boolean noDebugBody) {
		HTTPResponse res;

        //Load the combine receipts custom settings values (if not already loaded)
        loadCustomSettingsVariables();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(getBaseURL() + endpointSuffix);
        System.debug('Endpoint: '+req.getEndpoint());
        req.setMethod('GET');
        Blob headerValue = Blob.valueOf(zamzarAPIKey + ':');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        Http http = new Http();
        res = http.send(req);
        System.debug('getHeader-Location: '+res.getHeader('Location'));
        System.debug('getHeaderKeys: '+res.getHeaderKeys());
        System.debug('getHeader-Location: '+res.getHeader('Location'));

		return res;
	}

	/**************************************************************************************
	// Name         : getTargetFileNames
	// Description  : This method returns a list of ZamzarTargetFile records that include
	//					the Id, Name, and file size of converted files (may be more than
	//					one target file from a source file, multi-page PDFs, for example)
	// Author       : CLD Partners
	// Revisions    : 2015-12-03  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static List<ZamzarTargetFile> getTargetFileNames(String jsonString) {
		String statusValue;
		String[] targetFileIds;
		List<ZamzarTargetFile> targetFiles = new List<ZamzarTargetFile>();
		String targetFileName;

		//Parse the Zamzar json response
		if (jsonString != null) {
			JSONParser parser = JSON.createParser(jsonString);
			while (parser.nextToken() != null) {
			    //if current token is a field name
			    if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
			        String fieldName = parser.getText();
			        System.debug('fieldName: ' + fieldName);
			        //move to token after the field name
			        parser.nextToken();
			        if(fieldName == 'status'){
			            statusValue = parser.getText();
			            System.debug('Status=' + statusValue);
				    } else if(fieldName == 'target_files'){
						if(parser.getCurrentToken() == JSONToken.START_ARRAY){
						    while(parser.nextToken() != null){
						        if(parser.getCurrentToken() == JSONToken.START_OBJECT){
						        	ZamzarTargetFile targetFile = (ZamzarTargetFile) parser.readValueAs(ZamzarTargetFile.class);
						        	System.debug('TargetFile: ' + targetFile);
					        		if (!targetFile.name.contains('.zip')) {
						        		targetFiles.add(targetFile);
					        		}
					        	} else if(parser.getCurrentToken() == JSONToken.END_ARRAY){
					            	break; 
					        	}
					    	}
					    }
					}
			    }
			} //end first while
		}

		System.debug('Target Files: ' + targetFiles);
		return targetFiles;
	}

	/**************************************************************************************
    // Name        	: loadCustomSettingsVariables
    // Description 	: If the custom settings variables haven't been loaded, do it now
    //
	// Author       : CLD Partners
	// Revisions    : 2015-12-07  Klassen  Initial version
	//				: 
    ***************************************************************************************/
    public static void loadCustomSettingsVariables() {
    	//Only set the custom settings variables if the "default" custom setting hasn't
    	// been "loaded" yet
    	if (customSettingCombineReceipts == null) {
    		//Set the default values
			notifyEmailList = '';
			notificationThreshold = 0;
			zamzarAPIKey = '';
			targetFormat = '';
			testMode = true;
			baseURLProd = '';
			baseURLTest = '';
			sendLowCreditsEmail = false;

			PSA_Combine_Receipts__c psaCombineReceipts = PSA_Combine_Receipts__c.getValues('default');
			if (psaCombineReceipts != null) {
				if (psaCombineReceipts.PSA_Notification_Threshold__c != null) {
					notificationThreshold = psaCombineReceipts.PSA_Notification_Threshold__c;
				}
				if (psaCombineReceipts.PSA_Email_Notify_List__c != null) {
					notifyEmailList = psaCombineReceipts.PSA_Email_Notify_List__c;
				}
				if (psaCombineReceipts.PSA_Zamzar_API_Key__c != null) {
					zamzarAPIKey = psaCombineReceipts.PSA_Zamzar_API_Key__c;
				}
				if (psaCombineReceipts.PSA_Target_Format__c != null) {
					targetFormat = psaCombineReceipts.PSA_Target_Format__c;
				}
				if (psaCombineReceipts.PSA_Test_Mode__c != null) {
					testMode = psaCombineReceipts.PSA_Test_Mode__c;
				}
				if (psaCombineReceipts.PSA_Zamzar_Prod_URL__c != null) {
					baseURLProd = psaCombineReceipts.PSA_Zamzar_Prod_URL__c;
				}
				if (psaCombineReceipts.PSA_Zamzar_Test_URL__c != null) {
					baseURLTest = psaCombineReceipts.PSA_Zamzar_Test_URL__c;
				}
				if (psaCombineReceipts.PSA_Send_Low_Credit_Notifications__c != null) {
					sendLowCreditsEmail = psaCombineReceipts.PSA_Send_Low_Credit_Notifications__c;
				}
			}   	
    	}
    }

	/**************************************************************************************
	// Name         : checkCredits
	// Description  : Used to check how many credits remain for Zamzar file conversions
	//					
	// Author       : CLD Partners
	// Revisions    : 2015-12-07  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	@future(callout=true)
	public static void checkCredits() {
		HttpResponse res = processGETRequest('account', false);
        Integer numberOfTestCreditsRemaining = Integer.valueOf(res.getHeader('Zamzar-Test-Credits-Remaining'));
        Integer numberOfCreditsRemaining = Integer.valueOf(res.getHeader('Zamzar-Credits-Remaining'));
        System.debug('getHeader-Test Credits Remaining: ' + numberOfTestCreditsRemaining);
        System.debug('getHeader-Credits Remaining: ' + numberOfCreditsRemaining);
        System.debug('Http Response: ' + res.getBody());
        sendNotificationOfCreditsLimit(numberOfCreditsRemaining, testMode, numberOfTestCreditsRemaining, res.getBody());
	}

	/**************************************************************************************
	// Name         : sendNotificationOfCreditsLimit
	// Description  : This method sends a notification via email if the number of zamzar
	//					file credits dips below a certain pre-defined amount as specified
	//					in the PSA Combine Receipts custom setting
	// Author       : CLD Partners
	// Revisions    : 2015-11-22  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static void sendNotificationOfCreditsLimit(Integer numberOfRemainingCredits, Boolean testSystem, 
			Integer numberOfRemainingTestCredits, String additionalEmailText) {
		Integer creditsRemainingCheck = testSystem ? numberOfRemainingTestCredits : numberOfRemainingCredits;
		loadCustomSettingsVariables();
		if (sendLowCreditsEmail == true && notifyEmailList != '' && notificationThreshold > 0 && creditsRemainingCheck < notificationThreshold) {
			String subjectText = 'Zamzar File Credits Remaining: ';
			subjectText += String.valueOf(numberOfRemainingCredits) + ' (test=' + String.valueOf(numberOfRemainingTestCredits) + ')';
			String bodyText = 'Zamzar file conversion credits are getting low: ' + numberOfRemainingCredits;
			bodyText += '     ' + additionalEmailText;
			bodyText += ' (test credits remaining: ' + numberOfRemainingTestCredits + ')';

	        // Send an debug notification email 
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

	        String[] toAddresses = notifyEmailList.split(',');       
	        mail.setToAddresses(toAddresses);
	        mail.setSubject(subjectText);
	        mail.setPlainTextBody(bodyText);

	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	/**************************************************************************************
	// Class Name   : ZamzarTargetFile
	// Description  : This class is used to serialize a section of json response for a file
	//					conversion request
	// Author       : CLD Partners
	// Revisions    : 2015-12-03  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public class ZamzarTargetFile {
		public Integer id {get; set;}
		public String name {get; set;}
		public Integer size {get; set;}
   	}
}