@istest(seeAllData=True)
global class ProductSkuCallOutMock implements HttpCalloutMock
{  
    protected Integer code;
    protected String Status;
    protected String JsonString;
    protected Id ProdId;

    global ProductSkuCallOutMock(Integer code,String Status,Id ProdId)
   {
     JSONGenerator gen = JSON.createGenerator(true);
         gen.writeStartObject();
     gen.writeFieldName('products');
         gen.writeStartArray();
     gen.writeStartObject();
       
           gen.writeStringField('id',ProdId);
       gen.writeStringField('status',Status);
       
     gen.writeEndObject();
       gen.writeEndArray();
        gen.writeEndObject();
        
    this.jsonString = gen.getAsString();
    this.code =code;       
  }
    global HttpResponse respond(HTTPRequest req)
   {
           HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(code);
            res.setBody(JsonString);
      return res;
    }
}


/*
@isTest(seeAllData = true)
global class ProductSkuCallOutMock implements HttpCalloutMock
{  
    global HttpResponse respond(HTTPRequest req)
	{
           HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setStatus('Success');
			res.setBody('{ "products": [  {  "id": "01t29000000NDvf",   "status": "success"    }  ]}');
            return res;
    }
}
*/