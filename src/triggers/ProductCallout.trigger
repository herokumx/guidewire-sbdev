trigger ProductCallout on Product2 (after Update) 
{
    Set<id> prodids = new Set<id>();
    for (Product2 p : Trigger.new)
	 {
	   // Check if the product is Eligible for Integration.      
	   if(P.Product_Integration_Status__c =='Eligible for Product Setup' && P.Approval_Status__c == 'Approved')
	           prodids.add(p.id);
     }

	 if(ProductSkuCallout.flag)
      {
	    if(!prodIds.isEmpty())
	    {
		// make the asynchronous web service callout
	     ProductSkuCallout.sendProductSku(prodIds);
		}
	 }
}