@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {

    Boolean  isMockResponseSuccessful;  // set by constructor, used to vary the mockresponse

    global MockHttpResponseGenerator(Boolean isMockResponseSuccessful) {
        this.isMockResponseSuccessful  = isMockResponseSuccessful;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
      
        // Create a fake response
        /*
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"foo":"bar"}');
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
        */
        HttpResponse hResp    = new HttpResponse();
        if (this.isMockResponseSuccessful) {
          hResp.setStatusCode(200);
          hResp.setStatus('OK');
          hResp.setBody('{"foo":"bar"}');
        }
        else {
          hResp.setStatusCode(400);
          hResp.setStatus('Not OK');
          hResp.setStatus('Bad request');
        }
        return hResp;

    }
}