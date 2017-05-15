/**************************************************************************************
// Name          : psaZamzarMock
// Date          : March 04, 2016
// Description   : Needed to allow test coverage for the Zamzar web service -- returns 
//					sample web responses to test webservice calls -- since there are 
//					multiple responses that need to be tested, it relies on the web 
//					service requests being called in a specific order
// Author        : CLD Partners
// Revisions     : 2016-03-04  Klassen  Initial version
//				 : 
***************************************************************************************/
@isTest
global class psaZamzarMock implements HttpCalloutMock {

	//For handling multiple callout cases
    //We will use a List of responses and this static index variable to keep
    //track of which response we need to send back.
    public static Integer TEST_CALLOUT_INDEX = 0;

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Zamzar-Credits-Remaining', '3');
        res.setHeader('Zamzar-Test-Credits-Remaining', '3');
        res.setBody(getResponseString());
        res.setStatusCode(200);

		//Increment Callout Index for multiple callout processing in a single unit test.
        TEST_CALLOUT_INDEX++;

        return res;
    }

    public static String getResponseString() {
    	if (TEST_CALLOUT_INDEX==0) {
            System.debug('Zamzar Mock Index=0');
	    	return '{"id" : 15, "key" : "55de648435099e8548b371e040fed74563db45e0", "status" : "initialising", "sandbox" : true, "created_at" : "2016-02-01T13:41:00Z", "finished_at" : null, "source_file" : {"id":2,"name":"test.pdf","size":90571}, "target_files" : [], "target_format" : "png", "credit_cost" : 1}';
        } else if (TEST_CALLOUT_INDEX==1) {
            System.debug('Zamzar Mock Index=1');
    		return '{"test_credits_remaining" : 3, "credits_remaining" : 18, "plan" : { "name" : "Developer", "price_per_month" : 0, "conversions_per_month" : 25, "maximum_file_size" : 1048576 }}';
    	} else if (TEST_CALLOUT_INDEX==2) {
            System.debug('Zamzar Mock Index=2');
            return '{ "id" : 16, "key" : "55de648435099e8548b371e040fed74563db45e0", "status" : "failed", "sandbox" : true, "created_at" : "2016-02-01T13:41:00Z", "finished_at" : "2016-02-01T13:41:13Z", "source_file" : {"id":2,"name":"test.pdf","size":90571}, "target_files" : [{"id":3,"name":"test.png","size":15311}], "target_format" : "png", "credit_cost" : 1}';
        } else if (TEST_CALLOUT_INDEX==3) {
            System.debug('Zamzar Mock Index=3');
            return '{"test_credits_remaining" : 3, "credits_remaining" : 18, "plan" : { "name" : "Developer", "price_per_month" : 0, "conversions_per_month" : 25, "maximum_file_size" : 1048576 }}';
//        } else if (TEST_CALLOUT_INDEX==4) {
//            System.debug('Zamzar Mock Index=4');
//            return '{ "id" : 15, "key" : "55de648435099e8548b371e040fed74563db45e0", "status" : "successful", "sandbox" : true, "created_at" : "2016-02-01T13:41:00Z", "finished_at" : "2016-02-01T13:41:13Z", "source_file" : {"id":2,"name":"test.pdf","size":90571}, "target_files" : [{"id":3,"name":"test.png","size":15311}], "target_format" : "png", "credit_cost" : 1}';
    	} else {
    		return 'undefined';
    	}
    }
}