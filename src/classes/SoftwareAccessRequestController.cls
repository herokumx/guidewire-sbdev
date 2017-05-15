//--------------------
// Software Access Request Form Controller.
// Date: 1/23/2016
// Author: Rohit Koul
//--------------------
public class SoftwareAccessRequestController {

    public Software_Access_Request__c sarObjVar {get; set; }
    Public Account_Contact__c acrVar {get; set;}
    Public Opportunity oppVar {get; set;} 
    public Boolean displayCustomerContactDetails {get; set; }
    public Boolean displayOpportunityDetails {get; set; }
    public List<productWRPCLass> productWRPCLassList{get; set; }
    public Boolean isDetail{get; set; } 
    public Boolean isThunderhead{get; set; } 
    public Boolean isPredictiveAnalytics{get; set; }
    
    
  /* Public Boolean isPAforClaims{get; set;}
     Public Boolean isPAforProfitability{get; set;}
     Public Boolean isPAModelViewer{get; set;}
     Public Boolean isPAforScoringService{get; set;}
  */

   // public sObject inputObj{get; Set;}
    
    public SoftwareAccessRequestController(ApexPages.StandardController stdController) {
             initializeValues();
             this.sarObjVar = (Software_Access_Request__c)stdController.getRecord();
             isDetail = false;
			 isThunderhead = false;
			 isPredictiveAnalytics = false;
         /*  isPAforProfitability = false;
             isPAModelViewer = false;
             isPAforScoringService = false;
         */  
			 if(ApexPages.currentPage().getParameters().get('id') != null &&  ApexPages.currentPage().getParameters().get('id') != ''){
                    isDetail = true;
                    if(ApexPages.currentPage().getParameters().get('retURL') != null &&  ApexPages.currentPage().getParameters().get('retURL') != ''){
                        isDetail = false;
                    }
                    this.sarObjVar  = [ Select Services_account_manager__c,Customer_time_zone__c,Thunderhead_End_Date__c,Predictive_Products_Start_Date__c,Predictive_Products_End_Date__c,
                                        Software_Removal_Date__c,State__c,Customer_Owner__c,Service_standard__c,Status__c,Delivery_type__c, Sales_account_manager__c, Requester_Name__c, Request_type__c, Products__c, Portals__c, OwnerId, Options__c, Name, 
                                        Live_apps__c, Predictive_Products__c,LastModifiedDate, LastModifiedById, IsDeleted, Id, Ext_Packs__c, Date_needed__c, Customer_Name__c,Customer_Name__r.MPL_Sales_Rep__r.Email,Customer_Name__r.Owner.Email, Customer_Name__r.Services_Account_Manager__r.Email, 
                                        Customer_Contact_Name__c, Opportunity__c, CurrencyIsoCode, CreatedDate, CreatedById, Core_quantity__c, Content_items__c, Additional_comments__c From Software_Access_Request__c where Id =: ApexPages.currentPage().getParameters().get('id')];
                  if(sarObjVar.Status__C != null && sarObjVar.Status__C == 'Submitted'){
                     isDetail = true;
                     ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Request Submitted, no further updates allowed.');
                     ApexPages.addMessage(msg);
                  }
				  

                  // assign values to WRP class using product.
                for (productWRPCLass prdWRPVar :  productWRPCLassList)
                {
                    if (sarObjVar.Products__c != null && sarObjVar.Products__c.contains(prdWRPVar.productName))
                    {

					   // assign thunderhead variables.
   					    if(prdWRPVar.productName == 'Thunderhead'){
						   isThunderhead =  true; 
						}else{
						   isThunderhead =  false; 
						}
						
						 // assign Predictive Analytics variables.
   					    if(prdWRPVar.productName == 'Predictive Analytics'){
						   isPredictiveAnalytics =  true; 
						}else{
						   isPredictiveAnalytics =  false; 
						}
		     /*	
						// assign Predictive Analytics for Profitability variables.
   					    if(prdWRPVar.productName == 'Predictive Analytics for Profitability'){
						   isPAforProfitability =  true; 
						}else{
						   isPAforProfitability =  false; 
						}
						
						// assign Predictive Analytics Model Viewer.
   					    if(prdWRPVar.productName == 'Predictive Analytics Model Viewer'){
						   isPAModelViewer =  true; 
						}else{
						   isPAModelViewer =  false; 
						}
						
						// assign Predictive Analytics Scoring Service.
   					    if(prdWRPVar.productName == 'Predictive Analytics Scoring Service'){
						   isPAforScoringService =  true; 
						}else{
						   isPAforScoringService =  false; 
						}
		    	*/

					    // check for exact Product Name.
						List<String> productFieldValueList = sarObjVar.Products__c.Split(';');
						for (String prd : productFieldValueList)
						{
							if (prd != null && prd == prdWRPVar.productName)
							{
							    prdWRPVar.productIncluded = true;
							}
						}
					   	// assign Standards Based Templates value
							if (prdWRPVar.productName == 'Standards Based Templates' && prdWRPVar.sbtWrpClassVar !=null && sarObjVar != null && sarObjVar.Content_items__c != null)
							{ 
							System.debug ('Standards Based Templates>>>>>>>>>>'+prdWRPVar.sbtWrpClassVar); 
							   // prepare map of name and state
							   System.debug ('Content_items__c>>>>>>>>>>'+sarObjVar.Content_items__c); 
								Map<String,List<String>> contentItemNameStateMap = new Map<String,List<String>>();
								List<String> nameStateList = sarObjVar.Content_items__c.Split(';');
								List<String> stateStr = new List<String>();
								for (String nameStateVar: nameStateList )
								{     
								      stateStr = new List<String>();
									  List<String> artList = nameStateVar.Split(',');
										for (Integer i = 1; i < artList.size() ; i++)
										{
										   stateStr.add(artList[i]); 
										}
								  	  contentItemNameStateMap.put(artList[0],stateStr);
								}
								System.debug ('contentItemNameStateMap>>>>>>>>>>'+contentItemNameStateMap); 
                            
							   for (standardsBasedTemplatesWrpClass sbtWrpVar: prdWRPVar.sbtWrpClassVar){
								if (contentItemNameStateMap.get(sbtWrpVar.name) != null)
								{
								   sbtWrpVar.included = true;
								   String stateString = '';
									for (String state : contentItemNameStateMap.get(sbtWrpVar.name))
									{  
										if (stateString != '')
										{
										   stateString += ';' +  state;
										}else{
										   stateString = state;
										}
									}
									if (stateString != null && stateString == 'N/A')
									{
									    sbtWrpVar.sarVarTemp.state__c = '';
									}else{
								        sbtWrpVar.sarVarTemp.state__c = stateString;
								    }
								}
							   }
							}
							System.debug ('Debug>>>>>>>>>>'+prdWRPVar.sbtWrpClassVar); 
                    }
				} 
				
                getCustomerContactDetails();
                getOpportunityDetails();
              }
   }
    
    public void initializeValues() {
        sarObjVar = new Software_Access_Request__c();
        acrVar = new Account_Contact__c();
        oppVar = new Opportunity();
        productWRPCLassList = setproductWRPCLassListValues();
    }

    public List<productWRPCLass> setproductWRPCLassListValues(){
           productWRPCLassList = new List<productWRPCLass>();
           List<Software_Access_Request_Settings__c> sarSettingsList = Software_Access_Request_Settings__c.getall().values();
           String objectName = 'Software_Access_Request__c'; 
           Schema.SObjectType targetType = Schema.GetGlobalDescribe().Get(objectName); 
           Map<String, Schema.SObjectField> fieldMap = new  Map<String, Schema.SObjectField>(); 
           if(targetType != null){ 
         //  inputObj = targetType.NewSObject();
           fieldMap = targetType.getDescribe().fields.getMap();
           }
           for (Software_Access_Request_Settings__c sarSetting : sarSettingsList) 
            {
             productWRPCLass pwrpClass = new productWRPCLass();
             pwrpClass.productIncluded = false;
             pwrpClass.productName = sarSetting.Name;
                if (sarSetting.Field_API_Name__c != null)
                {
                   pwrpClass.fieldApiName = sarSetting.Field_API_Name__c;
                   pwrpClass.dependentFieldLable = fieldMap.get(sarSetting.Field_API_Name__c).getDescribe().getLabel();
                }else{
                   pwrpClass.fieldApiName = '';
                   pwrpClass.dependentFieldLable = '';
                }
				if (sarSetting.Name != null && sarSetting.Name == 'Standards Based Templates'){
				    List<standardsBasedTemplatesWrpClass> sbtWrpClassList = new List<standardsBasedTemplatesWrpClass>();
					if (SoftwareAccessRequestHelper.getstandardsBasedTemplates() !=null)
					{
						for (String  sbt : SoftwareAccessRequestHelper.getstandardsBasedTemplates())
						{  
						   standardsBasedTemplatesWrpClass sbtWrpClass = new standardsBasedTemplatesWrpClass();
						   sbtWrpClass.included = false;
						   sbtWrpClass.name = sbt;
						   sbtWrpClass.state = ''; 
						   sbtWrpClass.sarVarTemp = new Software_Access_Request__c();
						   sbtWrpClassList.add(sbtWrpClass);
						}
					}
				   pwrpClass.sbtWrpClassVar = sbtWrpClassList;
				}
				productWRPCLassList.add(pwrpClass);
            }
            return productWRPCLassList;
    }
    public void getCustomerContactDetails(){
    
        if (sarObjVar.Customer_Contact_Name__c != null)
        {   
            displayCustomerContactDetails = true;
            acrVar = SoftwareAccessRequestHelper.getContactDetails(sarObjVar.Customer_Contact_Name__c);
	    }else{
           displayCustomerContactDetails = false;
        }
		// assign thunderhead and Predictive Analytics products flag on customercontact details change.
		assignCustomSettings();
    }
    
    public void getOpportunityDetails(){
    
           if (sarObjVar.Opportunity__c != null)
          {   
            displayOpportunityDetails = true;
            oppVar = SoftwareAccessRequestHelper.getOpportunityInfoDetails(sarObjVar.Opportunity__c);
          }else{
           displayOpportunityDetails = false;
           }
          // assign thunderhead and Predictive Analytics products flag on customercontact details change.
           assignCustomSettings();
          } 
          
	 
    public PageReference assignCustomSettings(){
        // Build product multiselect to Save
        String productMultiSelect = '';
        for(productWRPCLass prdWRPVar :productWRPCLassList)
        {  
            if (prdWRPVar.productIncluded && productMultiSelect != '')
            {
             productMultiSelect += ';';   
            }
            if (prdWRPVar.productIncluded)
            {
               productMultiSelect += prdWRPVar.productName;
            }
        }
        sarObjVar.Products__c = productMultiSelect;
		if(productMultiSelect.contains('Thunderhead')){
		   isThunderhead =  true; 
		}else{
		  isThunderhead =  false; 
		}
		
		 // assign Predictive Analytics variables.
   		 if(productMultiSelect.contains('Predictive Analytics')){
			isPredictiveAnalytics =  true; 
		  }else{
		    isPredictiveAnalytics =  false; 
	      }
		
	/*  	if(productMultiSelect.contains('Predictive Analytics for Claims')){
		    isPAforClaims =  true; 
	     	}else{
		    isPAforClaims =  false; 
		    }
	  					
		    if(productMultiSelect.contains('Predictive Analytics for Profitability')){
		    isPAforProfitability =  true; 
		    }else{
		    isPAforProfitability =  false; 
	        }
		    if(productMultiSelect.contains('Predictive Analytics Model Viewer')){
		     isPAModelViewer =  true; 
	    	}else{
	         isPAModelViewer =  false; 
		    }
		    if(productMultiSelect.contains('Predictive Analytics Scoring Service')){
			isPAforScoringService =  true; 
		    }else{
			isPAforScoringService =  false; 
		    }
   */		
        return null;
    }

	public PageReference assignContentItems(){
	   String contentItems = '';
       for(productWRPCLass prdWRPVar :productWRPCLassList)
        {
			if (prdWRPVar.sbtWrpClassVar != null)
			{
			  for (standardsBasedTemplatesWrpClass sbtWrpVar: prdWRPVar.sbtWrpClassVar){
					if (sbtWrpVar.included)
					{
					List<String> stateList =  new List<String>();
					    if (contentItems != ''){
						   contentItems += ';' + sbtWrpVar.name ; 
						}else{
							contentItems =  sbtWrpVar.name;  
                        }
						if (sbtWrpVar.sarVarTemp.State__c != null)
						{
							if(sbtWrpVar.sarVarTemp.State__c.contains(';')){
							stateList = sbtWrpVar.sarVarTemp.State__c.split(';');   
							}else{
							stateList.add(sbtWrpVar.sarVarTemp.State__c);
							}
						}else{
							contentItems += ',' + 'N/A';
						}
						for (String st : stateList)
						{
							contentItems += ',' + st; 
						}
					  }
			   } 
			}
		}
		sarObjVar.Content_items__c = contentItems;
		return null;
	}
     
     public PageReference submitRequest(){
        sarObjVar.Status__c = 'Submitted';

      //  Database.UPDATE(sarObjVar);
        return Save();
     } 

	 public PageReference completeReq(){
        sarObjVar.Status__c = 'Completed';
        return Save();
     } 


    public PageReference Save() {
	        System.debug('acrVar>>>>>>>' +acrVar + 'sarObjVar>>>>>>>'+ sarObjVar);
			if (acrVar !=null && sarObjVar.Request_type__c  != null &&  sarObjVar.Request_type__c != 'Partner requirements' &&  sarObjVar.Request_type__c != '(Other)')
			{
			    // if digital portal or guidewire live selected assign values & Request type != partner or other.
				if (sarObjVar.Products__c != null && (sarObjVar.Products__c.contains('Guidewire Live') || sarObjVar.Products__c.contains('Digital Portals') )){
					if (acrVar.Participant_Account__r.MPL_Sales_Rep__c == null && sarObjVar.Status__c == 'Submitted'){
				         ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Please provide MPL sales rep on associated Customer/Account record before submitting the Software request.');
                         ApexPages.addMessage(msg);
						 sarObjVar.Status__c = 'Draft';
						  return null;
					}else{
					    sarObjVar.Sales_account_manager__c =  acrVar.Participant_Account__r.MPL_Sales_Rep__c;
					}
				}
				
				// if anything other than Guidewire Live and Digital portals seleted & Request type != partner or other .
				Boolean assignOwnerId = false;
				if (sarObjVar.Products__c != null){
						List<Software_Access_Request_Settings__c> sarSettingsList = Software_Access_Request_Settings__c.getall().values();
						for (Software_Access_Request_Settings__c sarSettingVar: sarSettingsList){
							if (sarSettingVar.Name != 'Guidewire Live' && sarSettingVar.Name != 'Digital Portals' && sarObjVar.Products__c.contains(sarSettingVar.Name))
							{
				    			assignOwnerId = true;
							}
						}
						if(assignOwnerId){
						   sarObjVar.Customer_Owner__c =  acrVar.Participant_Account__r.OwnerId;
						}else{
						  sarObjVar.Customer_Owner__c  = null;
						}
						// & Request type != partner or other.
						if (acrVar.Participant_Account__r.Services_Account_Manager__c == null && sarObjVar.Status__c == 'Submitted')
						{
 							 ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Please provide Services Account Manager on associated Customer/Account record before submitting the Software request.');
                             ApexPages.addMessage(msg);
							 sarObjVar.Status__c = 'Draft';
							 return null;
						}else{
							sarObjVar.Services_account_manager__c =  acrVar.Participant_Account__r.Services_Account_Manager__c;
						}
			  }
		   }
		try 
		{	        
		   Database.Upsert(sarObjVar);
		}
		catch (Exception  ex)
		{
			sarObjVar.Status__c = 'Draft';
		    return null;
		}
			   
		PageReference detailPage = new PageReference('/'+sarObjVar.Id);
		return detailPage;
	
		   
     }
    

	public class standardsBasedTemplatesWrpClass{
	   public Boolean included{get; set;}
	   public String name{get; set;}
	   public String state{get; set;}
	   public Software_Access_Request__c sarVarTemp{get; set;}
	   public List<SelectOption> getStates(){
	       List<SelectOption> options = new List<SelectOption>();
		   options.add(new SelectOption('N/A','-None-'));
	       Schema.DescribeFieldResult fieldResult = Software_Access_Request__c.State__c.getDescribe();
           List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
           for(Schema.PicklistEntry f : ple)
		   {
			  options.add(new SelectOption(f.getLabel(), f.getValue()));
		   }
		   return options; 
	   }
	}
	 
    public class productWRPCLass{
      public String productName{get; set;}
      public Boolean productIncluded{get; set;}
      public String fieldApiName{get; set;}
      public String dependentFieldLable{get; set;} 
	  public List<standardsBasedTemplatesWrpClass> sbtWrpClassVar{get; set;} 
    }
}