@isTest(seeAllData=true)
Public class ProductSkuCallTest 
{
    private static testmethod void SkuTest()
	{	    
	    Schema.DescribeSObjectResult ProdSchema = Schema.SObjectType.Product2; 
        Map<String,Schema.RecordTypeInfo> ProductRecordTypeInfo = ProdSchema.getRecordTypeInfosByName(); 

        Id rtId = ProductRecordTypeInfo.get('Standard Products').getRecordTypeId();

		List<Product2> ProdLst = new List<Product2>();
	   Set<Id> skuids = new Set<Id>();

	   Product2 Prod = new Product2();

	            Prod.ProductCode = 'BI-INS1';
				Prod.name = 'Business Intelligence for InsuranceSuite1';
				Prod.Product_Group_Code__c ='Dmx1';
				Prod.Product_Group_Name__c ='Data MGMT';
				Prod.Product_Line_Code__c ='DA';
				Prod.Product_Line_name__c ='Data Analy';
				Prod.Product_Set_Code__c ='DARG';
				Prod.Product_Set_Name__c ='Data Mgmtment';
				Prod.Product_Type__c ='Other';
				Prod.Product_Source__c ='Other';
				Prod.RecordTypeId	= rtId;
				Prod.SKU_ID__c = 'Testsku11';
				Prod.Family ='Core';

				insert Prod;

       Id rtId1 = ProductRecordTypeInfo.get('Sku').getRecordTypeId();
       Product2 SkuProd1  = new Product2();
	           
			   SkuProd1.Name ='test2345';
               SkuProd1.SKU_ID__c ='L-100014';
			   SkuProd1.SKU_Name__c='Test-harii1';
               SkuProd1.Sku_Type__c='Training';
			   SkuProd1.Sku_Sub_Type__c='Fixed Fee';
               SkuProd1.SKU_Description__c='testing sku';
               SkuProd1.SKU_Internal_Description__c='';
               SkuProd1.SKU_Gl_Group__c='22040';
			   SkuProd1.SKU_Taxable__c=true;
               SkuProd1.SKU_Tax__c ='DC026789';
               SkuProd1.sku_Deployment_Type__c='on-premise';
               SkuProd1.SKU_Product_Line_Id__c ='CCX';
			   SkuProd1.IsActive=false;
               SkuProd1.Product__c = Prod.Id;	
			   SkuProd1.RecordTypeId = rtId1;

			   ProdLst.add(SkuProd1);
			   
			Product2 SkuProd2  = new Product2();
	           
			   SkuProd2.Name ='Test5673';
               SkuProd2.SKU_ID__c ='L-100018';
			   SkuProd2.SKU_Name__c='Test-harii2';
               SkuProd2.Sku_Type__c='Training';
			   SkuProd2.Sku_Sub_Type__c='Fixed Fee';
               SkuProd2.SKU_Description__c='testing sku23';
               SkuProd2.SKU_Internal_Description__c='Testing sku poduct';
               SkuProd2.SKU_Gl_Group__c='22040';
			   SkuProd2.SKU_Taxable__c=true;
               SkuProd2.SKU_Tax__c ='DC026789';
               SkuProd2.sku_Deployment_Type__c='on-premise';
               SkuProd2.SKU_Product_Line_Id__c ='CCX';
			   SkuProd2.IsActive=true;
               SkuProd2.Product__c = Prod.Id;
			   SkuProd2.RecordTypeId = rtId1;	
			   
			   ProdLst.add(SkuProd2);
			   
			   insert ProdLst;

			   ProdLst[0].Product_Integration_Status__c ='Eligible for Product Setup' ;
			   ProdLst[0].Approval_Status__c = 'Approved' ;
			   ProdLst[1].Product_Integration_Status__c = 'InEligible' ;
			   ProdLst[1].Approval_Status__c = 'Approved' ;

			   update ProdLst;

			   skuids.add(ProdLst[0].id);
			   skuids.add(ProdLst[1].id);

  
        ProductSkuCallOutMock Mockcall = new ProductSkuCallOutMock(200,'success',ProdLst[0].id);
        Test.setMock(HttpCalloutMock.class, Mockcall);
        
        Test.startTest();
           ProductSkuCallOut.sendProductSku(skuIds);    
        Test.stopTest();

    }
}