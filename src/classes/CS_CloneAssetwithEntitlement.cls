/*
*****************************************************************************************************************************
Class Name - CS_CloneAssetwithEntitlement
Class Type -  Global Service Class 
Test Class-
Purpose- Asset Clone


*****************************************************************************************************************************

Name            Email              Date              Notes 
Mani G                                              Initial Creation

*****************************************************************************************************************************
*/
global class CS_CloneAssetwithEntitlement { 

    webservice static String CloneAsset(Id AssetId){

    System.debug('Input Value=====' + Assetid);
    
    Asset NAsset=[select AccountId, Catastrophe_App__c, ContactId,
                                    CS_Account_Mgmt_Portal_Date__c,
                                     CS_Account_Mgmt_Portal_License__c, CS_App_Server__c, CS_AppSvr_Version__c,
                                     CS_Archiving__c, CS_Asset_Mailing_Address__c, CS_BFO_Batch_Server__c,
                                     CS_BFO_CPU_Count__c, CS_BFO_License__c, CS_BFO_License_Date__c,
                                     CS_BI_License_Date__c, CS_Browser_Version__c, CS_Business_Intelligence_License__c,
                                     CS_Carbon_Copy_Email_1__c, CS_Carbon_Copy_Email_2__c, CS_Carbon_Copy_Email_3__c,
                                     CS_Catastrophe_App_Date__c, CS_CDM_License__c, CS_CDM_License_Date__c, 
                                     CS_Claim_Portal_Date__c, CS_Claim_Portal_License__c, CS_ClaimCanvas_App_Date__c,
                                     CS_Clustering__c, CS_Cognos_License__c, CS_Cognos_License_Date__c,
                                     CS_Compare_App_Date__c, CS_ComparePlus_App_Date__c, CS_Contractual_Financial_Penalties__c,
                                     CS_Cur_Dev_Version__c, CS_CurGoLive_ProdVers__c,
                                     CS_Customer_Implementation_Manager__c, CS_Database_Server__c, CS_DataHub_Date__c,
                                     CS_DataHub_License__c, CS_Date_SBOP_License__c, CS_Date_Std_Reporting_License__c,
                                     CS_Date_Vendorportal_License__c, CS_Dbsvr_Version__c, CS_Doc_Mgmt__c, CS_Est_Go_Live__c,
                                     CS_Gateway_for_Portal_Agents__c, CS_Gateway_for_Portal_Agents_Date__c, CS_GPS_Number__c,
                                     CS_GW_Imp_Active__c, CS_GW_Rolloff_Date__c, CS_GW_SC_ImpDate__c, CS_Hail_App_Date__c,
                                     CS_InetSoft_License__c, CS_InetSoft_License_Date__c, CS_InfoCenter_Date__c,
                                     CS_InfoCenter_License__c, CS_InsuranceCloud_Partner__c, CS_Intro_to_Support_Complete_Date__c, 
                                     CS_JVM_Tunings__c, CS_JVM_Vendor__c, CS_JVM_Version__c, CS_License_SBOP__c, 
                                     CS_License_Std_Reporting__c, CS_License_Vendor_Portal__c, CS_LiveApp_ClaimCanvas__c, 
                                     CS_LiveApp_Compare__c, CS_LiveApp_ComparePlus__c, CS_LiveApp_Hail__c, CS_LiveApp_ViewPoint__c, 
                                     CS_LiveApp_ViewPoint_Date__c, CS_Load_Balancer__c, CS_London_Market_License_Date__c,
                                     CS_London_Markets_License__c, CS_MyAgentsApp_Date__c, CS_Non_Standard_SLA__c,
                                     CS_Number_Solution_Owners__c, CS_Operating_System__c, CS_Org_Type__c, 
                                     CS_OS_Version__c, CS_PE_Contact__c, CS_PE_Weekly_Call__c, CS_Pri_Supp_Org__c, CS_Primary_Supp_Partner__c,
                                     CS_Prod_Svcs_Contract__c, CS_Product__c, CS_Product_Version__c, CS_Project_Manager__c, CS_Project_Product_Manager__c,
                                     CS_Quote_and_Buy_License__c, CS_Quote_and_Buy_License_Date__c, CS_Rally_Licensed__c,
                                     CS_Rally_Licenses_Provided__c, CS_Rating_Mgr_Lic_Date__c, CS_Rating_Mgr_License__c, CS_RCS_Active_Customer__c,
                                     CS_RCS_Details__c, CS_RCS_End_Date__c, CS_RCS_Owner__c, CS_RCS_Start_Date__c, CS_RCS_Type__c, CS_Region__c, 
                                     CS_Reinsurance_Lic_Date__c, CS_Reinsurance_License__c, CS_SBOP_Core_Count__c, CS_SC_Weekly_Call__c, CS_Sec_Support_Partner__c, 
                                     CS_Secondary_PM1__c, CS_Secondary_PM2__c, CS_Service_Level__c, CS_Services_Acct_Mgr__c, CS_Services_Alliances_Manager__c,
                                     CS_SolnCenter_Contact__c, CS_Solution_Owners_By_Contract__c, CS_Spotlight_App__c, CS_Spotlight_App_Date__c,
                                     CS_Support_Trans_Date__c, CS_SVN_Upload_Date__c, CS_Thunder_Head_License__c, CS_Thunderhead_License_Date__c,
                                     CS_URL_SVN__c, CS_Weekly_Call__c, CurrencyIsoCode,
                                     Description,InstallDate, IsCompetitorProduct,License_Type__c, MyAgents_App__c, Name, OwnerId,Price,
                                      Product2Id, PurchaseDate, 
                                     Quantity, Renewal_Date__c,SerialNumber, Status, SystemModstamp, UsageEndDate from Asset where id=:AssetId];
    
    Asset newAsset = NAsset.clone(false);
             //insert newAsset;
    Database.SaveResult AssetList = Database.insert(newAsset, false);
    system.debug('Result==='+AssetList);
    system.debug('AssetId==='+AssetList.getId());

    List<Entitlement>  entCheck=  New List<Entitlement>([select id from Entitlement where Assetid =:Assetid]);

    if(entCheck.size()>0){
    Entitlement NEntitlement=[select AccountId,BusinessHoursId, CasesPerEntitlement, ContractLineItemId, 
                                            EndDate, Id, IsPerIncident,Name, RemainingCases, ServiceContractId, SlaProcessId,
                                            StartDate, Status, SystemModstamp, Type from Entitlement where Assetid =:Assetid];

    if(NEntitlement !=null){
        Entitlement newEntitlement = NEntitlement.clone(false);                                         
        Database.SaveResult EntList = Database.insert(newEntitlement, false);
        Entitlement  UpdateEnt= New Entitlement(id=EntList.getId(),Assetid=AssetList.getId());
        update UpdateEnt;
    }
}

   if (AssetList.isSuccess() ){
        Return (String)AssetList.getId();
   }
    else{Return 'Error'; } 

  }
}