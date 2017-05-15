public class ProductSkuCallout 
{
   public static boolean flag = true;    

  	@future (callout=true)
   public static void sendProductSku(Set<id> newProdIds)
   {   
      List<Product2> ProdLst = [select id,SKU_ID__c,SKU_Name__c,recordtype.name,sku_Deployment_Type__c,SKU_Gl_Group__c,SKU_Product_Line_Id__c,Sku_Type__c,SKU_Taxable__c,
                                Sku_Sub_Type__c, Product__c,SKU_Description__c,SKU_Internal_Description__c,SKU_Tax__c,IsActive,CreatedBy.Name,LastModifiedBy.Name, Product_Integration_Status__c,
								Product__r.name,Product__r.ProductCode, Product__r.Product_line_Name__c, Product__r.Product_Line_Code__c,product__r.Product_Group_Name__c,
								Product__r.Product_Group_Code__c,Product__r.Product_Set_Name__c,Product__r.Product_Set_Code__c,Product__r.Family,
								Product__r.Product_Source__c,Product__r.Product_Type__c from product2 where Id =: newProdIds ];
       	
    //Custom setting to store the Client Key, Secret key and end point URL and Email to send notification .	   
       List<ProdMaster_Mule__c> MuleValues = ProdMaster_Mule__c.getall().values();

	   JSONGenerator gen = JSON.createGenerator(true);
         gen.writeStartObject();
		 gen.writeFieldName('products');
         gen.writeStartArray();

		for (Product2 Prod : ProdLst)
		{
		      gen.writeStartObject();
			 
               gen.writeStringField('uuid',Prod.Id);
               gen.writeStringField('id',Prod.SKU_ID__c);
			   gen.writeStringField('name',Prod.SKU_Name__c);
               gen.writeStringField('type',Prod.Sku_Type__c);
			   gen.writeStringField('sub-type',Prod.Sku_Sub_Type__c);
               gen.writeStringField('description',Prod.SKU_Description__c);
			   string inter = ' ';
			   if (Prod.SKU_Internal_Description__c != null)
			   {
			     gen.writeStringField('internal-description',Prod.SKU_Internal_Description__c);
			   } 
			   else if (Prod.SKU_Internal_Description__c == null)
			   {
			     gen.writeStringField('internal-description', inter);
			   }            
               gen.writeStringField('gl-code',Prod.SKU_Gl_Group__c);
			 //  string taxb = string.valueOf(Prod.SKU_Taxable__c);
             //  gen.writeStringField('taxable',taxb);
               gen.writeStringField('tax-group',Prod.SKU_Tax__c);
               gen.writeStringField('deployment-type',Prod.sku_Deployment_Type__c);
               gen.writeStringField('line-code',Prod.SKU_Product_Line_Id__c);
			   //Send isActive field as Active or Inactive and not as True or False.
				string act='';
				if (Prod.IsActive)
				   act ='Active';
			    else if(!Prod.IsActive)
			       act ='Inactive';
			   gen.writeStringField('status',act);
			   gen.writeStringField('taxanomy-code',Prod.Product__r.ProductCode);
			   gen.writeStringField('taxanomy-name',Prod.Product__r.name);
			   gen.writeStringField('taxanomy-group-code',Prod.Product__r.Product_Group_Code__c);
				gen.writeStringField('taxanomy-group-name',Prod.product__r.Product_Group_Name__c);
				gen.writeStringField('taxanomy-line-code',Prod.Product__r.Product_Line_Code__c);
				gen.writeStringField('taxanomy-line-name',Prod.Product__r.Product_Line_name__c);
				gen.writeStringField('taxanomy-set-code',Prod.Product__r.Product_Set_Code__c);
				gen.writeStringField('taxanomy-set-name',Prod.Product__r.Product_Set_Name__c);
				gen.writeStringField('taxanomy-source',Prod.Product__r.Product_Source__c);
				gen.writeStringField('taxanomy-type',Prod.Product__r.Product_Type__c);
				gen.writeStringField('taxanomy-family',Prod.Product__r.Family);			
               gen.writeStringField('created-by',Prod.CreatedBy.Name);
               gen.writeStringField('modified-by',Prod.LastModifiedBy.Name);
			   
	           gen.writeEndObject();
	  }
        gen.writeEndArray();
        gen.writeEndObject();
        String jsonString = gen.getAsString();
	     system.debug('String value :'+ jsonString);

	  // Store the Custom setting values into strings.
	   string endpoint = MuleValues[0].End_point_URL__c;
	   string clintKey = MuleValues[0].Client_Id__c;
	   string SecretKey = MuleValues[0].Client_Secret__c;

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

		req.setEndpoint(endpoint);
		req.setHeader('client_id',clintKey);
		req.setHeader('client_secret',SecretKey);
		req.setMethod('POST');
        req.setBody(jsonString);
        req.setHeader('Content-Type','application/json');
         //   req.setEndpoint('https://gw-financial-force-dev.cloudhub.io/gw-financial-force/v1/process/products');        
	     //	req.setHeader('client_id','apikey');
	     //	req.setHeader('client_secret','YKwl9lNEGWZbD2b');
        // req.setCompressed(false); // otherwise we hit a limit of 32000  

        try {
		       res = http.send(req);        
                System.debug(res.getBody());
				System.debug(res.getStatusCode());
             
			if(res.getStatusCode() == 200)
			{
			   // call the Deserialise method to update products.
			    JParse(res.getBody()); 
			}  
			else if(res.getStatusCode() != 200)
			{
			  //send an email notification if the service is down.
			  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();


			  String toAddr = MuleValues[0].Email__c;
			  System.debug('email address :'+toAddr);
			  String[] toAddresses = new List<String>();
			  toAddresses.add(toAddr);
                
		  	//  String[] toAddresses = new String[] {'hyarapathineni@guidewire.com'};
            //  String[] ccAddresses = new String[] {'dmakam@guidewire.com'};
			  mail.setToAddresses(toAddresses);
			//  mail.setCcAddresses(ccAddresses);
			  mail.setSubject('Product  Internal service Exception');
			  mail.setPlainTextBody('An Exception has occured: Status Code :' + res.getStatusCode() +' Status Message :' + res.getStatus() +'Response Body :'+res.getBody());
              
			  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
			                     
          }
        catch(System.CalloutException e)
          {
            System.debug('Callout error: '+ e);
            System.debug(res.toString());
          }
}

public static void JParse(string JsonRes)
{	

Map<String, object> tmpResult = (Map<String, object>) JSON.deserializeuntyped(JsonRes);
System.debug('tmp ResultClass' + tmpResult);

List<object> resultList = (List<object>)(tmpResult.get('products'));
System.debug('tmp List' + resultList);

List<Product2> SuccessLst = new List<Product2>();
List<Product2> FailureLst = new List<Product2>();
List<Product2> FinalLst = new List<Product2>();

for (object entry : resultList) 
{
    Map<String, Object> customerAttributes = (Map<String, Object>)entry;
  
     Product2 prd = new Product2();
	 prd.Id =(String) customerAttributes.get('id');
	 prd.Mule_Response_Status__c =(String) customerAttributes.get('status');

	 	if (prd.Mule_Response_Status__c == 'success')
			{
			  SuccessLst.add(prd);
			}
   else if(prd.Mule_Response_Status__c == 'failure')
		     {
			    FailureLst.add(prd);
			 }				 
 }
   System.debug('product Map' + SuccessLst);
 
 for (Product2 Prod1 : SuccessLst)
		{
		   Prod1.Product_Integration_Status__c = 'Integration in Progress';
		   FinalLst.add(Prod1);
		}

for (Product2 Prod1 : FailureLst)
		{
		   Prod1.Product_Integration_Status__c = 'Ineligible';
		   FinalLst.add(Prod1);
		}
		
	flag = false;
	Update FinalLst;

}

}


 /*
    JSONParser parser = JSON.createParser(JsonRes);
    while (parser.nextToken() != null) 
	{
        // Start at the array of invoices.
        if (parser.getCurrentToken() == JSONToken.START_ARRAY) 
		{
            while (parser.nextToken() != null) 
			{
                // Advance to the start object marker to
                //  find next invoice statement object.
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
				{
                    // Read entire invoice object, including its array of line items.
                    ReturnResponse inv = (ReturnResponse)parser.readValueAs(ReturnResponse.class);
                    system.debug(' number: ' + inv.id);
					// system.debug('Size of list items: ' + inv.lineItems.size());
                    // For debugging purposes, serialize again to verify what was parsed.
                    String s = JSON.serialize(inv);
                    system.debug('Serialized : ' + s);

                    // Skip the child start array and start object markers.
                    parser.skipChildren();
                }
            }
        }
      }
	  
*/