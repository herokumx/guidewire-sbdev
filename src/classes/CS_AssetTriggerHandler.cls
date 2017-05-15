/*
******************************************************************************************************************************
Controller Class Name- CS_AssetTriggerHandler
Object - Asset
Purpose- Trigger Handler 
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com      			 Initial Creation
Mani G   manig@slalom.com  08/03/2016    Updated for Asset gourping Changes
										  - ACPs will be created only for Asset Record Type Parent Asset
										  - Software Download Records will be created for Child Asset
										  - When Parent Asset is Deactivated ACPS on Parent Asset will be deactivated
										  - When Parent Asset is Deactivated Child Assets will be deactivated
Mani G   manig@slalom.com  08/25/2016    Modified for DE433	
Mani G   manig@slalom.com  08/26/2016    Modified for DE433 (Only Minor Releases Linked to Major release SDs will be created 
                                         for Partner Certified Asset)	
Mani G   manig@slalom.com  08/27/2016   Added No_longer_with_firm__c Check on Contact Query     
Mani G   manig@slalom.com  09/07/2016   Added a Check CS_No_Customer_Contact__c on Parent Asset DE362
Mani G   manig@slalom.com  09/16/2016   Bug Fix for DE362 Cognos Automation Fix
Mani G   manig@slalom.com  09/21/2016   Fixed the Evaluation end date being  called on Asset Update event
*****************************************************************************************************************************
*/
public without sharing class CS_AssetTriggerHandler implements CS_ITrigger {

	private List<CS_Asset_Contact_Permissions__c> assetContactListToInset = new List<CS_Asset_Contact_Permissions__c>();
	private List<CS_Software_Downloads__c> softwardDownloadListToInsert = new List<CS_Software_Downloads__c>();
	private Set<Id> insertedSoftwareDownloadIds = new Set<Id>();
	private List<FeedItem> feedItemListToInsert = new List<FeedItem>();
	private Map<String, List<String>> productToVersionMap = new Map<String, List<String>>();
	private Map<Id, Id> productToParentMap = new Map<Id, Id>();
	private Map<Id, Id> assetProductToParentMap = new Map<Id, Id>();
	private Set<Id> AstIdDeactivation= New Set<Id>();
	private	Set<Id> AstIdActivation= New Set<Id>();
	private Set<ID> AcpId= New Set<ID>();
	private Set<Id> ParentAssetIds=  New Set<Id>();
	private List<Asset>  ChildAssetList= new List<Asset>();
	private List<AssetShare> newAssetShareList= New List<AssetShare>();
	private Map<Id,String> AssetReleaseMap= new Map<Id,String>();
	private Map<Id,CS_Release__c> RelMap=new Map<Id,CS_Release__c>();
	private CS_ByPass__c bypass {
    	get {
    		return 	CS_ByPass__c.getInstance(UserInfo.getUserId());
    	}
    }

	public CS_AssetTriggerHandler() {
		
	}

	public void bulkBefore()
	{
		if(Trigger.IsInsert && Trigger.isBefore){
		// Default Evaluation Date on Prospect Asset to  60 days from Created Date
		for (SObject so : Trigger.new) {
				Asset a = (Asset)so;
				//Map<Id, Asset> AstOldMap = (Map<Id, Asset>)Trigger.oldMap;
				if(a.status =='Prospect'){
					a.CS_Prospect_Evaluation_End_Date__c=System.Today()+60;
				}
				
				//Rohit : Code change for Data Migration, Please do not remove. 
				if(a.CS_DM_RightNow_Parent_ID__c != null){
				    a.ParentId = a.CS_DM_RightNow_Parent_ID__c;
				}
			}
		}
	}
	
	public void bulkAfter()
	{
		// Trigger IsInsert begins
		if (Trigger.isInsert) {

			Set<Id> accountIdSet = new Set<Id>();
			Set<Id> assetIdSet = new Set<Id>();
			Set<Id> parentAssetIdSet = new Set<Id>();
			Set<Id> childAssetIdSet = new Set<Id>();
			Set<Id> parentproductIds = new Set<Id>();
			Set<Id> versionIds = new Set<Id>();
			Set<Id> assetProductVersionIds = new Set<Id>();

			for (SObject so : Trigger.new) {
				Asset a = (Asset)so;
				// add parent asset ids to set for ACP creation
				if(a.ParentId == null && a.CS_Record_Type_Name__C=='Parent Asset') {
					accountIdSet.add(a.AccountId);
					parentAssetIdSet.add(a.Id);
				// Added Child Asset Check for DE362
				} else if(a.CS_Record_Type_Name__C=='Child Asset' && a.CS_No_Software_Downloads__c==False) {
					// else add child asset ids for software download creation
					childAssetIdSet.add(a.Id);
				}
			}
			// if user is batch user, invoke future method to Support Data Migrations
			if (bypass.CS_Batch_Context__c) {
					if(parentAssetIdSet!=null && !parentAssetIdSet.isEmpty()){
						CS_Asset_Util.createACP(accountIdSet, parentAssetIdSet);
					}

					if(childAssetIdSet!=null && !childAssetIdSet.isEmpty()){
						CS_Asset_Util.createSoftwareDownloads(childAssetIdSet);
					}
			} else {

				// query the rest of asset fields that are customer account  and Parent Product to fetch the Product Version
			String queryString = 'Select Id,status, Product2Id, CS_product_version__r.CS_Major_Release_version__c,CS_Product_Version__c,Account.IsPartner,Account.Name,Account.RecordType.Name from Asset where Id in :childAssetIdSet';			
			List<Asset> assets = Database.query(queryString);
								
			for (Asset a : assets) {
				// Exisiting Customer and Not a Prospect Asset
				if (a.Account.RecordType.Name == 'Customer' && a.Product2Id != null && a.status !='Prospect') {
     				parentproductIds.add(a.product2Id);
    				productToParentMap.put(a.Product2Id, a.Product2Id);
    			}		    
				// Prospect Customer and   Prospect Asset
				if (a.CS_Product_Version__c != null && (a.Account.RecordType.Name == 'Prospect'  || a.status== 'Prospect' )) {
					assetProductVersionIds.add(a.CS_Product_Version__c);
					assetProductToParentMap.put(a.Product2Id, a.CS_Product_Version__c);
				}
				/*
				// Partner Account and  Certified Asset
				if (a.Account.RecordType.Name == 'Partner' && a.CS_Product_Version__c != null  && a.status=='Certification'){
					system.debug('=====Iam Inside Partner Asset====='+a.CS_Product_Version__c);
					assetProductVersionIds.add(a.CS_Product_Version__c);
					assetProductToParentMap.put(a.Product2Id, a.CS_Product_Version__c);
				}
				*/
				// Partner Account and  Certified Asset
				if (a.Account.RecordType.Name == 'Partner' && a.CS_Product_Version__c != null  && a.status=='Certification'){
					system.debug('=====Iam Inside Partner Asset====='+a.CS_Product_Version__c);
					parentproductIds.add(a.product2Id);
    				productToParentMap.put(a.Product2Id, a.Product2Id);
    				AssetReleaseMap.put(a.id,a.CS_product_version__r.CS_Major_Release_version__c);
				}

			}		
			// query asset related customer account 
			List<Account> relatedCustomerAccounts = [Select Id, IsPartner from Account where Id in :accountIdSet];	
			// query all contacts related to account list queried previously
			List<Contact> allAccountContacts = [Select Id,name, AccountId,Account.RecordType.Name,Account.ispartner,CS_Access_Type__c,email,firstname,lastname,title,Phone
													 from Contact where AccountId in :relatedCustomerAccounts and RecordType.Name = 'Support' and No_longer_with_firm__c =False];

			// create a map to map from account Id to contacts
			Map<Id, List<Contact>> accountToContactMap = new Map<Id, List<Contact>>();
			for (Contact c : allAccountContacts) {
				if(c.Account.RecordType.Name =='Customer'){
					if (!accountToContactMap.containsKey(c.AccountId)) {
						accountToContactMap.put(c.AccountId, new List<Contact>());
					}
					accountToContactMap.get(c.AccountId).add(c);
				}
				else if(c.Account.RecordType.Name =='Partner' && c.CS_Access_Type__c =='Certified'){
					if (!accountToContactMap.containsKey(c.AccountId)) {
						accountToContactMap.put(c.AccountId, new List<Contact>());
						}
					accountToContactMap.get(c.AccountId).add(c);
				}
			}
			// query assets based on parentAssetIdSet
			// Added Check to Filter out Assets whih has No Customer Contact to True
			List<Asset> parentAssets = [Select Id, AccountId, ContactId, Status from Asset where Id in :parentAssetIdSet 
										and CS_No_Customer_Contact__c=false];
			// create ACP for customer account asset
			if (accountToContactMap != null && !accountToContactMap.isEmpty()) {
				//assetContactListToInset = createACP(accountToContactMap, Trigger.new);
				assetContactListToInset = createACP(accountToContactMap, parentAssets);				
			}

			if(AssetReleaseMap!=null && !AssetReleaseMap.isEmpty()){		
					RelMap= New Map<Id,CS_Release__c>(
										          [Select id,CS_Product__c from CS_Release__c where CS_Product__c in 
											       (Select product2id from Asset where Id in :AssetReleaseMap.keyset() )
											  		and CS_Major_Release_version__c in :AssetReleaseMap.values()]);												
			}
			system.debug('++++++++'+RelMap+'++++++++');


			// get all products that are associated with the assets (for customer only)
			// Added Active Check by Mani G on 06/10/2016
			List<Product2> products = [Select Id, Name, (Select CS_Product__c,CS_Major_Release_version__c, CS_Product_Version__c from 
										   Product_Version__r where CS_IsActive__c=true) from Product2 where 
										   Id in :parentproductIds];
				// add product version Ids to the set

			for (Product2 p : products) {
				if(!productToVersionMap.containsKey(p.Id)) {
						productToVersionMap.put(p.Id, new List<String>());
					}
				for (CS_Release__c pv : p.Product_Version__r) {
						versionIds.add(pv.Id);
						if(RelMap!=null & !RelMap.isEmpty()){
							if(RelMap.get(pv.id)!=null){
								productToVersionMap.get(p.Id).add(pv.Id);
								}

							}
					else{
							productToVersionMap.get(p.Id).add(pv.Id);
								}
					}
				}
				// query Asset  for child assets		
				List<Asset> childAssets = [Select Id,product2Id from Asset where id in :childAssetIdSet];
				// create software download records for customer account only for Child Assets 
				if (versionIds != null && !versionIds.isEmpty()) {
					//softwardDownloadListToInsert = createSoftwareDownloads(versionIds, Trigger.new);


					softwardDownloadListToInsert = createSoftwareDownloads(versionIds, childAssets);
				}
				// create software download records for prospect and partner account for  Child Assets 
				if (assetProductVersionIds != null && assetProductVersionIds.size() > 0) {
					softwardDownloadListToInsert = createSoftwareDownloads(assetProductVersionIds, assets);
				}
			}

			 childAssetShare((Map<Id,asset>)Trigger.newMap);
			
		}
		// Trigger IsInsert ends

		// Rohit : Temporary code , Please do not remove.
		/*if (Trigger.isUpdate && bypass.CS_Batch_Context__c) {

		            Set<Id> accountIdSetTemp = new Set<Id>();
					Set<Id> parentAssetIdSettemp = new Set<Id>();
				   for (SObject so : Trigger.new) {
						Asset asttemp = (Asset)so;
						Map<Id, Asset> AstOldMaptemp = (Map<Id, Asset>)Trigger.oldMap;
						if(asttemp != null && AstOldMaptemp.get(asttemp.Id).DM_Pass__c == false &&  asttemp.DM_Pass__c == true){
							 if(asttemp.ParentId == null && asttemp.CS_Record_Type_Name__C=='Parent Asset') {
									accountIdSetTemp.add(asttemp.AccountId);
									parentAssetIdSettemp.add(asttemp.Id);
							}
						}
				    }
					if(accountIdSetTemp!=null && !parentAssetIdSettemp.isEmpty()){
					  CS_Asset_Util.createACP(accountIdSetTemp, parentAssetIdSettemp);
					}
		} */

		// Rohit : Temporary code.
		
		
		if (Trigger.isUpdate) {
			for (SObject so : Trigger.new) {
				Asset ast = (Asset)so;
				Map<Id, Asset> AstOldMap = (Map<Id, Asset>)Trigger.oldMap;
				// Identify Parent Assets that are DeActivated 
				if (ast.CS_Is_Active__c ==false && AstOldMap.get(ast.Id).CS_Is_Active__c==true  && ast.CS_Record_Type_Name__c =='Parent Asset'
												&& (ast.status =='Prospect' || ast.status =='Implementation' ||  ast.status =='Production'  ) ){
					AstIdDeactivation.add(ast.id);
			   }	
			   // Identify Parent Assets that are Activated 
			   if (ast.CS_Is_Active__c ==true && AstOldMap.get(ast.Id).CS_Is_Active__c==false  && ast.CS_Record_Type_Name__c=='Parent Asset'
			   								  && (ast.status =='Prospect' || ast.status =='Implementation' ||  ast.status =='Production' )) {
					AstIdActivation.add(ast.id);
			   }

			   if(ast.CS_Record_Type_Name__C=='Parent Asset' && ast.status=='Production' &&  AstOldMap.get(ast.Id).status=='Implementation'){
					ParentAssetIds.add(ast.id);
				}
		}
			// Add Child Assets to the Asset Set for Deactivation
			if(AstIdDeactivation!=null && !AstIdDeactivation.isEmpty()){

				for(Asset AstDA: [SELECT Id, ParentId FROM Asset WHERE ParentId IN :AstIdDeactivation]) {
                	AstIdDeactivation.add(AstDA.Id);
            	}
            }
            // Add Child Assets to the Asset Set for Activation
            if(AstIdActivation!=null && !AstIdActivation.isEmpty()){

            	for(Asset AstA: [SELECT Id, ParentId FROM Asset WHERE ParentId IN :AstIdActivation]) {
                	AstIdActivation.add(AstA.Id);
            	}
           }
			if(! ParentAssetIds.isEmpty() && ParentAssetIds!=null ){
				for(Asset ast: [Select id,status,CS_record_Type_Name__C from asset 
								where  Parentid in :ParentAssetIds and  cs_record_Type_Name__C='Child Asset' ]){

					Asset NewAst=New Asset(id=ast.id,Status='Production');
					ChildAssetList.add(NewAst);
				}
			}

	}
}
	public void beforeInsert(SObject so)
	{

	}
	
	public void beforeUpdate(SObject oldSo, SObject so)
	{
	}
	
	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so)
	{	

	}
	
	public void afterInsert(SObject so)
	{

	}
	
	public void afterUpdate(SObject oldSo, SObject so)
	{
	}
	
	public void afterDelete(SObject so)
	{
	}
	
	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this 
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally()
	{
		// insert ACP record
		if (Trigger.isInsert && Trigger.isAfter && assetContactListToInset != null && !assetContactListToInset.isEmpty()) {
			try {
				insert assetContactListToInset;
			} catch (DmlException e) {
				System.debug('The following Error has occured ' + e.getMessage());
				CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting ACP'+ e.getMessage(),'CS_AssetTriggerHandler.Finally ');
			}
		}

		// create Software Download Records
		if (Trigger.isInsert && Trigger.isAfter && softwardDownloadListToInsert != null && !softwardDownloadListToInsert.isEmpty()) {
			try {
				Database.SaveResult[] srList = Database.insert(softwardDownloadListToInsert, false);
				for(Database.SaveResult sr : srList) {
					if (sr.isSuccess()) {
						insertedSoftwareDownloadIds.add(sr.getId());
						//System.debug(' Sucess =====insertedSoftwareDownloadIds ' + insertedSoftwareDownloadIds);
					} else {
						for (Database.Error err : sr.getErrors()) {
							System.debug('The following Erro has occured ' + err.getStatusCode() + ': ' + err.getMessage());
							CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting Software Downloads 1'+ err.getMessage(),'CS_AssetTriggerHandler.Finally ');
						}
					}
				}
			} catch(DmlException e) {
				System.debug('DML Exception on Software_Downloads__c' + e.getMessage());
				CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting Software Downloads 2'+ e.getMessage(),'CS_AssetTriggerHandler.Finally ');
			}
		}

		if (Trigger.isInsert && Trigger.isAfter && newAssetShareList != null && !newAssetShareList.isEmpty()) {
			system.debug('inside Finally newAssetShareList==='+newAssetShareList);

			try {
				insert newAssetShareList;
			} catch (DmlException e) {
				System.debug('The following Error has occured ' + e.getMessage());
				CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Inserting Asset Share'+ e.getMessage(),'CS_AssetTriggerHandler.Finally ');
			}
			
		}

			//Pass the AssetsIds to be Deactivated to Future method
           
			if( Trigger.isUpdate && Trigger.isafter && AstIdDeactivation.size() >0 ){
				CS_Asset_Util.deactivateProspectACP(AstIdDeactivation);
			}
			//Pass the AssetsIds to be Activated to Future method
			if( Trigger.isUpdate && Trigger.isafter && AstIdActivation.size() >0 ){
				CS_Asset_Util.ActivateProspectACP(AstIdActivation);
			}


			if(Trigger.isUpdate && Trigger.isafter && ChildAssetList.size()>0){

			try {
				 update ChildAssetList;
			}
			catch (DmlException e) {
				System.debug('The following Error has occured ' + e.getMessage());
				CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Updating Child Asset'+ e.getMessage(),'CS_AssetTriggerHandler.Finally ');
			}
				
			}
	}



	Public  void childAssetShare(Map<id,Asset> AssetMap ){

		Map<id,Set<id>> childAssetMap= new Map<id,Set<Id>>();
		Map<id,Set<id>> ACPMap= new Map<id,Set<Id>>();
		for(Asset ast:AssetMap.values()){
			if (ast.CS_Record_Type_Name__C != 'Parent Asset'){
				if(childAssetMap.containsKey(ast.parentid)){
					childAssetMap.get(Ast.parentid).add(ast.id);
				}
				else{

					childAssetMap.put(Ast.parentid,New Set<id>{ast.id});
				}

			}
		}	
		system.debug('childAssetMap==='+childAssetMap);
		if(!childAssetMap.isEmpty()){

			ACPMap=getParentACP(childAssetMap.keyset());
			if( !ACPMap.isEmpty()) {

				createChildAssetShare(childAssetMap,ACPMap);
			}
		}

	}

	public  Map<id,Set<id>>  getParentACP(Set<Id>  AssetIds){

		Map<id,Set<id>> ACPMap= new Map<id,Set<Id>>();
		for(CS_Asset_Contact_Permissions__c acp: [Select id,CS_Asset__c,CS_Contact__c from CS_Asset_Contact_Permissions__c where  CS_Asset__c in:AssetIds]){

			  if(ACPMap.containsKey(acp.CS_Asset__c)){
					ACPMap.get(acp.CS_Asset__c).add(acp.CS_Contact__c);
				}
				else{

					ACPMap.put(acp.CS_Asset__c,New Set<id>{acp.CS_Contact__c});
				}
		}
			system.debug('ACPMap==='+ACPMap);
			return ACPMap;

	}

	public void createChildAssetShare(Map<id,Set<id>> childAssetMap, Map<id,Set<id>> acpMap){
		Set<id> contactIds= New set<id>();
		Map<id,id>usermap= New Map<id,id>();
		

		for(id i : acpMap.keySet()){
			contactIds.addall(acpMap.get(i));
		}
		if( !contactIds.isEmpty()){

			for(User us:[Select id,contactid from user where contactid in :contactIds  and isactive=true]){

				usermap.put(us.contactId,us.id);
			}

			for(id i:childAssetMap.keyset()){

				for(id cid : childAssetMap.get(i)){
				 if(acpMap != null && acpMap.get(i) != null){
					for(id contactid:acpMap.get(i)){
						if(usermap.get(contactid) !=null){
							AssetShare newAssetShare = new AssetShare();
							newAssetShare.AssetAccessLevel = 'Read';
							newAssetShare.UserOrGroupId = usermap.get(contactid);
							newAssetShare.AssetId = cid;
							newAssetShare.RowCause = 'Manual';
							newAssetShareList.add(newAssetShare);
						}
					}
				  }
				}
			}
			system.debug('newAssetShareList==='+newAssetShareList);
		}


	}
	/*
	Method to create ACP 
	*/
	public List<CS_Asset_Contact_Permissions__c> createACP(Map<Id, List<Contact>> accToContactMap, List<Asset> assets) {
		List<CS_Asset_Contact_Permissions__c> acpList = new List<CS_Asset_Contact_Permissions__c>();
		//system.debug('Assets==' + assets);
		for (Asset a : assets) {			
			if(accToContactMap.get(a.AccountId) != null){
				for (Contact c : accToContactMap.get(a.AccountId)) {
					CS_Asset_Contact_Permissions__c ac = new CS_Asset_Contact_Permissions__c();
					if(a.status=='Prospect'){
					    ac.CS_Access_Type__c = 'Prospect';	
					}
					else{
					ac.CS_Access_Type__c = c.CS_Access_Type__c;
					}
					ac.CS_Asset__c = a.Id;
					ac.CS_Contact__c=c.Id;
					ac.Name=c.name;
					acpList.add(ac);
				}
			}
		}
		return acpList;
	}



	public List<CS_Software_Downloads__c> createSoftwareDownloads(Set<Id> versionIds, List<Asset> assets) {

		//System.debug('Passed Version Ids===='+versionIds +'Passed Asset Ids======'+assets );
		Set<Id> contentDocumentIds = new Set<Id>();
		Map<Id, ContentDocumentLink> versionDocumentsMap = new Map<Id, ContentDocumentLink>();
		// query content document based on related product versions
		List<ContentDocumentLink> contentDocumentLinks = [Select Id, ContentDocument.Title, ContentDocument.FileExtension, 
														  ContentDocument.LatestPublishedVersionId, ContentDocument.FileType,
														  LinkedEntityId, ContentDocumentId from ContentDocumentLink where 
														  LinkedEntityId in :versionIds];
		//system.debug('File Access ==='+contentDocumentLinks);
		// add content document ids to set
		for(ContentDocumentLink cdl : contentDocumentLinks) {
			contentDocumentIds.add(cdl.ContentDocumentId);
			versionDocumentsMap.put(cdl.LinkedEntityId, cdl);
		}

		//System.debug('versionDocumentsMap ' + versionDocumentsMap);
		//System.debug('contentDocumentIds ' + contentDocumentIds);

		// query related content documents based on contentDocumentIds set
		List<ContentDocument> contentDocuments = [Select Id, Title, FileExtension, LatestPublishedVersionId,FileType 
												  from ContentDocument where Id in :contentDocumentIds];

		List<CS_Software_Downloads__c> newSoftwareDownloadList = new List<CS_Software_Downloads__c>();
		//System.debug('contentDocuments ' + contentDocuments);
		CS_Software_Downloads__c sd;
		//if(contentDocumentLinks != null && !contentDocumentLinks.isEmpty()) {
			//system.debug('assets ' + assets);
			for (Asset a : assets) {
				//System.debug('productToParentMap ' + productToParentMap + '********' + productToVersionMap.get(productToParentMap.get(a.Product2Id)));

				if (productToVersionMap.get(productToParentMap.get(a.Product2Id)) != null) {
					for (String verId : productToVersionMap.get(productToParentMap.get(a.Product2Id))) {
						sd = new CS_Software_Downloads__c();
						sd.CS_Asset__c = a.Id;
						// added by Shan on 6/16
						sd.CS_Release__c = verId;
						/*
						if (versionDocumentsMap.get(verId)  != null) {
							sd.CS_File_Type__c = (String)versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileType');
							sd.CS_FileExtension__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileExtension');
							sd.CS_File_Id__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('LatestPublishedVersionId');
							sd.Name = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Title');
							sd.CS_Document_Id__c=(String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Id');
						}
						*/
						newSoftwareDownloadList.add(sd);
					}
				}

				if (assetProductToParentMap.values() != null) {
					//System.debug('assetProductToParentMap ' + assetProductToParentMap);
					for (String verId : assetProductToParentMap.values()) {
						sd = new CS_Software_Downloads__c();
						sd.CS_Asset__c = a.Id;
						// added by Shan on 6/16
						sd.CS_Release__c = verId;
						/*
						if (versionDocumentsMap.get(verId)  != null) {
							sd.CS_File_Type__c = (String)versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileType');
							sd.CS_FileExtension__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('FileExtension');
							sd.CS_File_Id__c = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('LatestPublishedVersionId');
							sd.Name = (String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Title');
							sd.CS_Document_Id__c=(String) versionDocumentsMap.get(verId).getSobject('ContentDocument').get('Id');

						}
						*/
						newSoftwareDownloadList.add(sd);
					}
				}
			}

			//System.debug('productToVersionMap ' + productToVersionMap +' | newSoftwareDownloadList ' + newSoftwareDownloadList.size());
		//}

		return newSoftwareDownloadList;
	}

}