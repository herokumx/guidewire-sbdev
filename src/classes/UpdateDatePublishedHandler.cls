public class UpdateDatePublishedHandler 
{
    public void documentHandler(list<ContentVersion> doculst)
    {
    	if(GW_Common_Settings__c.getInstance('EnableContentVersionTrigger').Boolean_Value__c){
	        for(ContentVersion cv : doculst)
	        {
	           cv.Date_Published__c = date.today();
	            
	           if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Customer Restricted' )
	               cv.usage_terms__c = 'This asset contains Guidewire Customer proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.'; 
	            
	           if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Guidewire Internal' )
	               cv.usage_terms__c = 'This asset contains Guidewire proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.';
	       
	           if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Public' )
	               cv.usage_terms__c = 'This asset contains information that can be publicly distributed through authorized company channels.';
	        }
       }
    }
    
    public void versionHandler(list<ContentVersion> verlst, map<id,ContentVersion> oldMap)
    {
    	if(GW_Common_Settings__c.getInstance('EnableContentVersionTrigger').Boolean_Value__c){
	        for(ContentVersion cv: verlst)
	        {         
	            ContentVersion cvOld = oldmap.get(cv.id);
	            
	            if(cvOld .VersionNumber != cv.VersionNumber)
	                cv.Date_Published__c = cv.LastModifiedDate.date(); 
	        
	            if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Customer Restricted' )
	               cv.usage_terms__c = 'This asset contains Guidewire Customer proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.'; 
	            
	           if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Guidewire Internal' )
	               cv.usage_terms__c = 'This asset contains Guidewire proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.';
	       
	           if(cv.Data_Classification__c != null && cv.Data_Classification__c =='Public' )
	               cv.usage_terms__c = 'This asset contains information that can be publicly distributed through authorized company channels.';                
	        }
    	}
    }
}