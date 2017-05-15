public class GW_GenerateEntitledAssetsForDM {
    public static list<Asset> assListDM = new list<Asset>();
    public static List<CS_Product_Relation__c> productRelations {get;set;}
	public static List<Asset> assetList {get;set;}
	
	public static List<Asset> getAllEntitledAssetsforcreation(){
	   
	    ID parentRecordTypeId;
		ID childRecordTypeId;
	    List<RecordType> assetRecordTypes = [Select Id, Name from RecordType where SobjectType = 'Asset'];
        for (RecordType rt : assetRecordTypes) {
            if (rt.Name == 'Parent Asset') {
                parentRecordTypeId = rt.Id;
            } else if (rt.Name == 'Child Asset') {
                childRecordTypeId = rt.Id;
            }
        }
	 	
		List<Asset> assetListTemp = [Select Id,recordType.Name,Product2Id,Product2.Name from Asset where recordType.Name = 'Child Asset' and CS_RightNow_ID__c != null];
		List<Id> productIdList = new List<Id>(); 
		for(Asset asst : assetListTemp){
		   // add an exception for Contact Manager.
		    if(asst.Product2.Name != null && asst.Product2.Name != 'ContactManager'){
		       productIdList.add(asst.Product2Id);	
			}
		}

		// customer Asset Creation
        //Get all the product relation ship
		productRelations = [Select CS_Source_Product__c, CS_Source_Product_Id__c, CS_Target_Product_Id__c, CS_Target_Product__c, CS_Support_Group_Name__c,
                            CS_Target_Product__r.Name,CS_Target_Product__r.recordtype.name ,CS_Source_Product__r.Name,CS_No_Software_Downloads__c
                            from CS_Product_Relation__c
                            where CS_Create_Asset__c=true and CS_Target_Product__c not in: productIdList];

				
		List<ID> prdrelIdList  = new List<ID>();
		for(CS_Product_Relation__c prdrel : productRelations){
		   prdrelIdList.add(prdrel.CS_Source_Product__c);	
		}
		system.debug(prdrelIdList);
							
		assetList = [Select  Status,CS_TimeZone__c,CS_Primary_Supp_Partner__c,CS_Sec_Support_Partner__c, CS_Project_Product_Manager__c, CS_Pri_Supp_Org__c, CS_Prod_Svcs_Contract__c,CS_Project_Manager__c,
					   CS_Services_Acct_Mgr__c, CS_Services_Alliances_Manager__c, CS_SLA_Comment__c,InstallDate,Parent.CS_Support_Group__c,
					 /* CS_Business_Intelligence_License__c, CS_Carbon_Copy_Email_1__c, CS_Carbon_Copy_Email_2__c, CS_Carbon_Copy_Email_3__c, 
					  CS_Catastrophe_App_Date__c, CS_CDM_License__c, CS_CDM_License_Date__c, CS_SC_Weekly_Call__c, CS_CE_Contact__c, 
					  CS_LiveApp_ClaimCanvas__c, CS_ClaimCanvas_App_Date__c, CS_Claim_Portal_Date__c, CS_Claim_Portal_License__c, 
					  CS_Client_Side_Virtualization_Used__c, CS_Cognos_License__c, CS_Cognos_License_Date__c, CS_LiveApp_Compare__c, 
					  CS_Compare_App_Date__c, CS_LiveApp_ComparePlus__c, CS_ComparePlus_App_Date__c, CS_URL_SVN__c, CS_SVN_Upload_Date__c, 
					  CS_CPU_Core_Count__c, CS_Cur_Dev_Version__c, CS_CurGoLive_ProdVers__c, CS_GW_SC_ImpDate__c, CS_Customer_Name__c, 
					  CS_Customer_Implementation_Manager__c, CS_Database_Patch__c, CS_Database_Server__c, CS_Dbsvr_Version__c, 
					  CS_DataHub_Date__c, CS_DataHub_License__c, CS_DB_client_version__c, CS_Disaster_Recovery_product_used__c, 
					  CS_Disaster_Recovery_setup__c, CS_Doc_Mgmt__c, CS_Gateway_for_Portal_Agents__c, CS_Gateway_for_Portal_Agents_Date__c,
					  CS_GPS_Number__c, CS_GW_Imp_Active__c, CS_GW_Rolloff_Date__c, CS_LiveApp_Hail__c, CS_Hail_App_Date__c, CS_Hide_On_Case__c, 
					  CS_InetSoft_License__c, CS_InetSoft_License_Date__c, CS_InfoCenter_Date__c, CS_InfoCenter_License__c, CS_EST_Go_Live__c, 
					  CS_InsuranceCloud_Partner__c, CS_Intro_to_Support_Complete_Date__c, CS_Support_Trans_Date__c, CS_Is_Active__c, 
					  CS_Clustering__c, CS_JVM_Tunings__c, CS_JVM_Vendor__c, CS_JVM_Version__c, CS_License_Date__c, CS_Load_Balancer__c,
					   CS_London_Market_License_Date__c, CS_London_Markets_License__c, CS_Monitoring_Software__c, CS_MyAgentsApp_Date__c, 
					   CS_No_Downloadable__c, CS_Non_Standard_SLA__c, CS_Not_in_Use__c, CS_Number_of_Online_and_Batch_servers__c, 
					   CS_Rally_Licenses_Provided__c, CS_Number_Solution_Owners__c, CS_RCS_Active_Customer__c, CS_RCS_Details__c, 
					   CS_RCS_End_Date__c, CS_RCS_Owner__c, CS_RCS_Start_Date__c, CS_ODC_Status__c, CS_RCS_Type__c, CS_Operating_System__c, 
					   CS_Organization__c, CS_Org_Type__c, CS_OS_Version__c, CS_DM_RightNow_Parent_ID__c, CS_Physical_and_Virtual_Memory__c,
					    CS_Primary_Supp_Partner__c, CS_Project_Product_Manager__c, CS_Pri_Supp_Org__c, CS_Prod_Svcs_Contract__c, CS_Product__c, 
						CS_Product_Family__c, CS_Parent_Product__c, CS_Production_Customer__c, CS_Product_Set_Name__c, CS_Product_Type__c, 
						CS_Project_Manager__c, CS_Prospect_Evaluation_End_Date__c, CS_Quote_and_Buy_License__c, 
						CS_Quote_and_Buy_License_Date__c, CS_Rally_Licensed__c, CS_Rating_Mgr_Lic_Date__c, CS_Rating_Mgr_License__c, 
						CS_Record_Type_Name__c, CS_Region__c, CS_Regional_Alliances_Manager__c, CS_Reinsurance_Lic_Date__c, 
						CS_Reinsurance_License__c, CS_Related_InsuranceSuite_products__c, CS_Replication_details__c, 
						CS_Reporting_Requirements__c, CS_RightNow_City__c, CS_RightNow_Country__c, 
						CS_RightNow_Postal_Code__c, CS_RightNow_State_Prov__c, CS_RightNow_Street__c, 
						CS_Saas_Case_Url__c, CS_Saas_Documentation_Url__c, CS_SaaS_Url__c, CS_SBOP_Core_Count__c, CS_Date_SBOP_License__c, 
						CS_License_SBOP__c, CS_Sec_Support_Partner__c, CS_PE_Weekly_Call__c, CS_Secondary_PM1__c, CS_Secondary_PM2__c, CS_PE_Contact__c, CS_Server_Side_Virtualization_Used__c,
						 CS_Service_Level__c, CS_Services_Acct_Mgr__c, CS_Services_Alliances_Manager__c, CS_SLA_Comment__c, 
						 CS_Contractual_Financial_Penalties__c, CS_SolnCenter_Contact__c, CS_Solution_Owners_By_Contract__c, 
						 CS_Spotlight_App__c, CS_Spotlight_App_Date__c, CS_Date_Std_Reporting_License__c, CS_License_Std_Reporting__c, 
						 CS_Weekly_Call__c, CS_Support_Group__c, CS_Thunder_Head_License__c, CS_Thunderhead_License_Date__c, CS_TimeZone__c, 
						 CS_Date_Vendorportal_License__c, CS_License_Vendor_Portal__c, CS_View_Cases__c, CS_View_Contacts__c, 
						 CS_View_Documentation__c, CS_View_Download__c, CS_LiveApp_ViewPoint__c, CS_LiveApp_ViewPoint_Date__c,*/
		                 Id,recordType.Name,Account.CS_Account_Short_Name__c,Product2Id,parentId from Asset where recordType.Name = 'Child Asset' and Product2Id in: prdrelIdList and CS_RightNow_ID__c != null];		
		List<Asset> childAssetListToInsert = new List<Asset>(); 				 
		 system.debug('assetListSize>>>' + assetList.size()); 
		 system.debug('assetList>>>' + assetList); 

		 system.debug('productRelations>>>' + productRelations.size()); 
		 system.debug('productRelations>>>' + productRelations); 


		 // Concat Asset Name and parent Asset Name and remove all duplicates.

		 integer intVal = 1;

		 for (Asset childAsset : assetList) {
			for (CS_Product_Relation__c pr : productRelations) {
			       if(childAsset.Product2Id != null &&  pr.CS_Source_Product__c != null && childAsset.Product2Id == pr.CS_Source_Product__c && pr.CS_Target_Product__c != null && pr.CS_Support_Group_Name__c == childAsset.Parent.CS_Support_Group__c){
						Asset prodRelAsset = new Asset();
						prodRelAsset = childAsset.clone(false,true,false,false);
						prodRelAsset.Id = null;
						prodRelAsset.parentId = childAsset.parentId;
						prodRelAsset.Product2Id = pr.CS_Target_Product__r.Id;
						prodRelAsset.CS_Support_Group__c = pr.CS_Support_Group_Name__c;
						prodRelAsset.cs_rightnow_id__c = 'ENT-'+intVal;
						prodRelAsset.Name = childAsset.Account.CS_Account_Short_Name__c + ' ' + pr.CS_Target_Product__r.Name; 
						if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Source_Product__r.Name !='IBM Cognos' && pr.CS_Source_Product__r.Name != 'SAP Data Integrator'){
							prodRelAsset.CS_Not_in_Use__c=true;
						}
						if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Target_Product__r.Name != null && (pr.CS_Target_Product__r.Name.Contains('Language Pack') || pr.CS_Target_Product__r.Name.Contains('Localization'))){
						  prodRelAsset.CS_Hide_On_Case__c = true;
						}

					    if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Source_Product__r.Name =='IBM Cognos' && pr.CS_Support_Group_Name__c != null && pr.CS_Support_Group_Name__c == 'Data Management'){
							prodRelAsset.CS_No_Software_Downloads__c = true;
						}
			
						childAssetListToInsert.add(prodRelAsset); 
						intVal++;
					}            
			}
        }

		Map<String,Asset> uniqueAssetMap = new Map<String,Asset>();
		for(Asset astinsFinalVar: childAssetListToInsert){
		    String astParentName = astinsFinalVar.Name + String.valueof(astinsFinalVar.parentId); 
			uniqueAssetMap.put(astParentName,astinsFinalVar);       
		}

		System.debug('Map Size>>>>' + uniqueAssetMap.size());

		List<Asset> astListFinalForLoad = new List<Asset>();
		for(String key :uniqueAssetMap.keyset()){
		   astListFinalForLoad.add(uniqueAssetMap.get(key));       
		}

		System.debug('astListFinalForLoad>>>>' + astListFinalForLoad.size());

		System.debug('insertListSize>>>>>'+childAssetListToInsert.size());
		System.debug('productIdList>>>>'+ childAssetListToInsert);	
	/*
		for(Asset ast : childAssetListToInsert){
			//  System.debug('productIdList>>>>'+ childAssetListToInsert.size());	
			//	System.debug('Not In use>>>>>'+ ast.CS_Not_in_Use__c+'>>>>>ast.Name>>>>>'+ast.Name + '>>>>>ast.Product2.Name>>>>>'+ ast.Product2.Name +  '>>>>>astParentID>>>>>' + ast.parentId + '>>>>>ast.parentProduct>>>>>' + ast.parent.Name);		
		}	
	//	database.insert(childAssetListToInsert[0]);
	//	System.debug('ID>>>>>'+ childAssetListToInsert[0].id);
		/*Set<Id> assetListTemp2 = new Set<Id>();
		assetListTemp2.add(childAssetListToInsert[0].Id);
		CS_Asset_Util.createSoftwareDownloads(assetListTemp2);
		System.debug('ID>>>>>'+ childAssetListToInsert[0].id);	*/
		return astListFinalForLoad;

	//	database.insert(childAssetListToInsert[1]);	
	//	System.debug('ID>>>>>'+ childAssetListToInsert[1].id); 
		/*database.insert(childAssetListToInsert[2]);	
		/*database.insert(childAssetListToInsert[3]);	
		System.debug('ID>>>>>'+ childAssetListToInsert[1].id);  
		System.debug('ID>>>>>'+ childAssetListToInsert[2].id);  
		System.debug('ID>>>>>'+ childAssetListToInsert[3].id);    */
		//partner Asset Creation.			
	
	}

	public static List<Entitlement> getAllEntitledEntitlementsforcreation(){
	   
	    ID parentRecordTypeId;
		ID childRecordTypeId;
	    List<RecordType> assetRecordTypes = [Select Id, Name from RecordType where SobjectType = 'Asset'];
        for (RecordType rt : assetRecordTypes) {
            if (rt.Name == 'Parent Asset') {
                parentRecordTypeId = rt.Id;
            } else if (rt.Name == 'Child Asset') {
                childRecordTypeId = rt.Id;
            }
        }
	 	
		List<Asset> assetListTemp = [Select Id,recordType.Name,Product2Id,Product2.Name from Asset where recordType.Name = 'Child Asset' and CS_RightNow_ID__c != null and (NOT CS_RightNow_ID__c LIKE 'ENT-%')];
		List<Id> productIdList = new List<Id>(); 
		for(Asset asst : assetListTemp){
		   // add an exception for Contact Manager.
		    if(asst.Product2.Name != null && asst.Product2.Name != 'ContactManager'){
		       productIdList.add(asst.Product2Id);	
			}
		}

		// customer Asset Creation
        //Get all the product relation ship
		productRelations = [Select CS_Source_Product__c, CS_Source_Product_Id__c, CS_Target_Product_Id__c, CS_Target_Product__c, CS_Support_Group_Name__c,
                            CS_Target_Product__r.Name,CS_Target_Product__r.recordtype.name ,CS_Source_Product__r.Name,CS_No_Software_Downloads__c
                            from CS_Product_Relation__c
                            where CS_Create_Asset__c=true and CS_Target_Product__c not in: productIdList];

				
		List<ID> prdrelIdList  = new List<ID>();
		for(CS_Product_Relation__c prdrel : productRelations){
		   prdrelIdList.add(prdrel.CS_Source_Product__c);	
		}
		system.debug(prdrelIdList);
							
		assetList = [Select  Status,CS_TimeZone__c,CS_Primary_Supp_Partner__c,CS_Sec_Support_Partner__c, CS_Project_Product_Manager__c, CS_Pri_Supp_Org__c, CS_Prod_Svcs_Contract__c,CS_Project_Manager__c,
					   CS_Services_Acct_Mgr__c, CS_Services_Alliances_Manager__c, CS_SLA_Comment__c,InstallDate,Parent.CS_Support_Group__c,
					 /* CS_Business_Intelligence_License__c, CS_Carbon_Copy_Email_1__c, CS_Carbon_Copy_Email_2__c, CS_Carbon_Copy_Email_3__c, 
					  CS_Catastrophe_App_Date__c, CS_CDM_License__c, CS_CDM_License_Date__c, CS_SC_Weekly_Call__c, CS_CE_Contact__c, 
					  CS_LiveApp_ClaimCanvas__c, CS_ClaimCanvas_App_Date__c, CS_Claim_Portal_Date__c, CS_Claim_Portal_License__c, 
					  CS_Client_Side_Virtualization_Used__c, CS_Cognos_License__c, CS_Cognos_License_Date__c, CS_LiveApp_Compare__c, 
					  CS_Compare_App_Date__c, CS_LiveApp_ComparePlus__c, CS_ComparePlus_App_Date__c, CS_URL_SVN__c, CS_SVN_Upload_Date__c, 
					  CS_CPU_Core_Count__c, CS_Cur_Dev_Version__c, CS_CurGoLive_ProdVers__c, CS_GW_SC_ImpDate__c, CS_Customer_Name__c, 
					  CS_Customer_Implementation_Manager__c, CS_Database_Patch__c, CS_Database_Server__c, CS_Dbsvr_Version__c, 
					  CS_DataHub_Date__c, CS_DataHub_License__c, CS_DB_client_version__c, CS_Disaster_Recovery_product_used__c, 
					  CS_Disaster_Recovery_setup__c, CS_Doc_Mgmt__c, CS_Gateway_for_Portal_Agents__c, CS_Gateway_for_Portal_Agents_Date__c,
					  CS_GPS_Number__c, CS_GW_Imp_Active__c, CS_GW_Rolloff_Date__c, CS_LiveApp_Hail__c, CS_Hail_App_Date__c, CS_Hide_On_Case__c, 
					  CS_InetSoft_License__c, CS_InetSoft_License_Date__c, CS_InfoCenter_Date__c, CS_InfoCenter_License__c, CS_EST_Go_Live__c, 
					  CS_InsuranceCloud_Partner__c, CS_Intro_to_Support_Complete_Date__c, CS_Support_Trans_Date__c, CS_Is_Active__c, 
					  CS_Clustering__c, CS_JVM_Tunings__c, CS_JVM_Vendor__c, CS_JVM_Version__c, CS_License_Date__c, CS_Load_Balancer__c,
					   CS_London_Market_License_Date__c, CS_London_Markets_License__c, CS_Monitoring_Software__c, CS_MyAgentsApp_Date__c, 
					   CS_No_Downloadable__c, CS_Non_Standard_SLA__c, CS_Not_in_Use__c, CS_Number_of_Online_and_Batch_servers__c, 
					   CS_Rally_Licenses_Provided__c, CS_Number_Solution_Owners__c, CS_RCS_Active_Customer__c, CS_RCS_Details__c, 
					   CS_RCS_End_Date__c, CS_RCS_Owner__c, CS_RCS_Start_Date__c, CS_ODC_Status__c, CS_RCS_Type__c, CS_Operating_System__c, 
					   CS_Organization__c, CS_Org_Type__c, CS_OS_Version__c, CS_DM_RightNow_Parent_ID__c, CS_Physical_and_Virtual_Memory__c,
					    CS_Primary_Supp_Partner__c, CS_Project_Product_Manager__c, CS_Pri_Supp_Org__c, CS_Prod_Svcs_Contract__c, CS_Product__c, 
						CS_Product_Family__c, CS_Parent_Product__c, CS_Production_Customer__c, CS_Product_Set_Name__c, CS_Product_Type__c, 
						CS_Project_Manager__c, CS_Prospect_Evaluation_End_Date__c, CS_Quote_and_Buy_License__c, 
						CS_Quote_and_Buy_License_Date__c, CS_Rally_Licensed__c, CS_Rating_Mgr_Lic_Date__c, CS_Rating_Mgr_License__c, 
						CS_Record_Type_Name__c, CS_Region__c, CS_Regional_Alliances_Manager__c, CS_Reinsurance_Lic_Date__c, 
						CS_Reinsurance_License__c, CS_Related_InsuranceSuite_products__c, CS_Replication_details__c, 
						CS_Reporting_Requirements__c, CS_RightNow_City__c, CS_RightNow_Country__c, 
						CS_RightNow_Postal_Code__c, CS_RightNow_State_Prov__c, CS_RightNow_Street__c, 
						CS_Saas_Case_Url__c, CS_Saas_Documentation_Url__c, CS_SaaS_Url__c, CS_SBOP_Core_Count__c, CS_Date_SBOP_License__c, 
						CS_License_SBOP__c, CS_Sec_Support_Partner__c, CS_PE_Weekly_Call__c, CS_Secondary_PM1__c, CS_Secondary_PM2__c, CS_PE_Contact__c, CS_Server_Side_Virtualization_Used__c,
						 CS_Service_Level__c, CS_Services_Acct_Mgr__c, CS_Services_Alliances_Manager__c, CS_SLA_Comment__c, 
						 CS_Contractual_Financial_Penalties__c, CS_SolnCenter_Contact__c, CS_Solution_Owners_By_Contract__c, 
						 CS_Spotlight_App__c, CS_Spotlight_App_Date__c, CS_Date_Std_Reporting_License__c, CS_License_Std_Reporting__c, 
						 CS_Weekly_Call__c, CS_Support_Group__c, CS_Thunder_Head_License__c, CS_Thunderhead_License_Date__c, CS_TimeZone__c, 
						 CS_Date_Vendorportal_License__c, CS_License_Vendor_Portal__c, CS_View_Cases__c, CS_View_Contacts__c, 
						 CS_View_Documentation__c, CS_View_Download__c, CS_LiveApp_ViewPoint__c, CS_LiveApp_ViewPoint_Date__c,*/
		                 Id,recordType.Name,Account.CS_Account_Short_Name__c,Product2Id,parentId from Asset where recordType.Name = 'Child Asset' and Product2Id in: prdrelIdList and CS_RightNow_ID__c != null];		
		List<Asset> childAssetListToInsert = new List<Asset>(); 				 
		 system.debug('assetListSize>>>' + assetList.size()); 
		 system.debug('assetList>>>' + assetList); 

		 system.debug('productRelations>>>' + productRelations.size()); 
		 system.debug('productRelations>>>' + productRelations); 

		 Map<String,ID> assetMap =  new Map<String,ID>();
		
		 // Concat Asset Name and parent Asset Name and remove all duplicates.

		 integer intVal = 1;

		 for (Asset childAsset : assetList) {
			for (CS_Product_Relation__c pr : productRelations) {
			       if(childAsset.Product2Id != null &&  pr.CS_Source_Product__c != null && childAsset.Product2Id == pr.CS_Source_Product__c && pr.CS_Target_Product__c != null && pr.CS_Support_Group_Name__c == childAsset.Parent.CS_Support_Group__c){
						Asset prodRelAsset = new Asset();
						prodRelAsset = childAsset.clone(false,true,false,false);
						prodRelAsset.Id = null;
						prodRelAsset.parentId = childAsset.parentId;
						prodRelAsset.Product2Id = pr.CS_Target_Product__r.Id;
						prodRelAsset.CS_Support_Group__c = pr.CS_Support_Group_Name__c;
						prodRelAsset.cs_rightnow_id__c = 'ENT-'+intVal;
						prodRelAsset.Name = childAsset.Account.CS_Account_Short_Name__c + ' ' + pr.CS_Target_Product__r.Name; 
						if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Source_Product__r.Name !='IBM Cognos' && pr.CS_Source_Product__r.Name != 'SAP Data Integrator'){
							prodRelAsset.CS_Not_in_Use__c=true;
						}
						if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Target_Product__r.Name != null && (pr.CS_Target_Product__r.Name.Contains('Language Pack') || pr.CS_Target_Product__r.Name.Contains('Localization'))){
						  prodRelAsset.CS_Hide_On_Case__c = true;
						}

					    if(pr.CS_Target_Product__r.recordtype.name =='Entitled Product' && pr.CS_Source_Product__r.Name =='IBM Cognos' && pr.CS_Support_Group_Name__c != null && pr.CS_Support_Group_Name__c == 'Data Management'){
							prodRelAsset.CS_No_Software_Downloads__c = true;
						}
			            assetMap.put(childAsset.Account.CS_Account_Short_Name__c + ' ' + pr.CS_Target_Product__r.Name+childAsset.parentId,childAsset.Id);
						childAssetListToInsert.add(prodRelAsset); 
						intVal++;
					}            
			}
        }

		List<Asset> entAssetList = [Select Id,Name,parentId from Asset where CS_RightNow_Id__c Like 'ENT-%'];
		List<Entitlement> entitlementList = [Select Id,BusinessHoursId,AccountId,EndDate,Name,SlaProcessId,StartDate,Status,asset.ID from Entitlement Where asset.Id in: assetMap.values()];
		
		Map<Id,Entitlement> assetEntitlementsMap  = new Map<Id,Entitlement>();
	    for(Entitlement entVar : entitlementList){
		   assetEntitlementsMap.put(entVar.AssetId,entVar);
		}
	    List<Entitlement> entListtoinsert = new List<Entitlement>();
		//generate final Entitlement List
		for(Asset assetOBJVar : entAssetList){
		   if(assetMap.get(assetOBJVar.Name+assetOBJVar.parentId) != null && assetEntitlementsMap.get(assetMap.get(assetOBJVar.Name+assetOBJVar.parentId)) != null){
		      Entitlement entitlementVar = new Entitlement();
			  entitlementVar = assetEntitlementsMap.get(assetMap.get(assetOBJVar.Name+assetOBJVar.parentId)).clone(false,true,false,false);  
			  entitlementVar.name = assetOBJVar.Name;
			  entitlementVar.AssetId = assetOBJVar.Id;
			  entListtoinsert.add(entitlementVar);
			 }
		}

		System.debug('entListtoinsert>>>>>>>>>' +entListtoinsert.size());
		System.debug('entListtoinsertList>>>>>>>>>'+ entListtoinsert);
		return entListtoinsert; 


	
	
	}

}