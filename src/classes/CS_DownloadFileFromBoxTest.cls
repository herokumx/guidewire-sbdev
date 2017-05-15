@isTest
private class CS_DownloadFileFromBoxTest {
	
	static testMethod void testRedirectToBox() {

        
        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';
        cBox.Access_Token__c = 'abc@xyz.com';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));

        String res = CS_DownloadFileFromBox.downloadBoxFile('abc123');

        CS_DownloadFileFromBox.sendEmailMssg('abc@xyz.com','12345');

        test.stoptest();
    }

    static testMethod void testRedirectToBoxBadRequest() {

        
        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';
        cBox.Access_Token__c = 'abc@xyz.com';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));

        String res = CS_DownloadFileFromBox.downloadBoxFile('abc123');        

        test.stoptest();
    }
	
}