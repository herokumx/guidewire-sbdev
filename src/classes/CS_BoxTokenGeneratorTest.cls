@isTest
private class CS_BoxTokenGeneratorTest {
    
    @isTest static void testConstructor() {
        // Implement test code

        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));

        CS_BoxTokenGenerator rbox = new CS_BoxTokenGenerator();

        test.stoptest();
    }
    
    @isTest static void testConnectBox() {
        // Implement test code

        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));

        CS_BoxTokenGenerator rBox = new CS_BoxTokenGenerator();

        rBox.connectBox();

        test.stoptest();
    }
    
    @isTest static void testRedirectBox() {
        // Implement test code

        CS_BoxTokens__c cBox = new CS_BoxTokens__c();
        cBox.Name = 'BoxDev';
        cBox.Refresh_Token__c = 'fahgafhgs';
        cBox.ClientId__c = 'fahgafhgs';
        cBox.ClientSecret__c = 'fahgafhgs';

        insert cBox;
        // Set mock callout class 
        test.starttest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));

        CS_BoxTokenGenerator rBox = new CS_BoxTokenGenerator();

        rBox.redirectbox();

        test.stoptest();
    }
}