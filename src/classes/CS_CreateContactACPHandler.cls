/*
******************************************************************************************************************************
Controller Class Name- CS_CreateContactACPHandler
Object - Community_Access_Request__c
Purpose- Trigger Handler 
******************************************************************************************************************************
Name        Email                               Date       Notes 
Hari        hyarapathineni@guidewire.com                   Initial Creation        
Suchitra    spurushotham@guideswire.com      11/07/2016    If its an Update Request record Type, Update the ACP's
******************************************************************************************************************************
*/

public class CS_CreateContactACPHandler
{
  public static boolean flag = true;
  
  public void ContactACP(List<Community_Access_Request__c> carLst, Map<id,Community_Access_Request__c> carOldMap, Set<Id> carIds)
  {
    boolean updateflag = false;
    
    List<Contact> conList = new List<Contact>();
   
    RecordType ContactRT = [Select id,name from recordType Where SobjectType = 'Contact' and DeveloperName = 'Support'];
    RecordType RequestRT = [Select id,name from recordType Where SobjectType = 'Community_Access_Request__c' and DeveloperName = 'New_Account_Request'];
    RecordType AssetRT = [Select id,name from recordType Where SobjectType = 'Asset' and DeveloperName = 'Parent_Asset'];
    system.debug('Asset RT:'+AssetRT.name);
    
    /***********************
    - CAR Update Variable Init 
    ************************/
    Map<Id,String> mapOfRecordType = GWUtilities.getRecordTypeDeveloperName('Community_Access_Request__c'); //Code for update CAR request. 
    Set<Id> setContactId = new Set<Id>(); //Code for update CAR request.
    Map<String,CS_Asset_Contact_Permissions__c> mapExistingAcps = new Map<String,CS_Asset_Contact_Permissions__c>(); //Code for update CAR request.
    List<CS_Asset_Contact_Permissions__c> lstACPUpdate = new List<CS_Asset_Contact_Permissions__c>(    ); //Code for update CAR request.
    Set<Id> setAccountId = new Set<Id>();
    Map<String,String> mapCarGroup = new Map<String, String>();
    /***********************
    - CAR Variable Init ends here 
    ************************/
      
    for(Community_Access_Request__c car: carLst)
    {
       Community_Access_Request__c oldCar = carOldMap.get(car.Id);
       /***********************
        - CAR Update Init Logic.  
        ************************/
       System.Debug('car.RecordtypeId>>>>>' + car.RecordtypeId + mapOfRecordType.get(car.RecordtypeId)  + car.Contact__c + 'car.Authorize_Change__c>>>>' + car.Authorize_Change__c);
       if (mapOfRecordType.get(car.RecordtypeId).ToUpperCase() == 'UPDATE_ACCESS_REQUEST' && car.Authorize_Change__c == true ){
           setContactId.add(car.Contact__c);
       }
        /***********************
        - CAR Update Init Logic 
        Ends Here .  
        ************************/
              
       if(car.recordTypeId == RequestRT.Id && oldcar.Create_Contact__c != car.Create_Contact__c &&  car.Create_Contact__c == true)
       {
         Contact con = new Contact();
           con.accountId = car.Account__c;
           con.FirstName = car.First_Name__c;
           con.Lastname = car.Last_Name__c;
           con.email = car.Email__c;   
           con.phone = car.Phone__c;
           con.title = car.title__c;
           con.currencyisocode ='USD';
           con.MailingStreet = car.Mailing_Street__c;
           con.MailingCity = car.Mailing_City__c;
           
        // con.MailingState = car.Mailing_State__r.name;
           con.MailingState = car.State__c;
                 system.debug('State value :' + con.MailingState);
        // con.MailingCountry = car.Mailing_Country__r.name;
           con.MailingCountry = car.Country__c;
                 system.debug('Country value :' + con.MailingCountry);
                 
           con.MailingPostalCode = car.Mailing_Zip_Postal_Code__c;
           con.RecordTypeId = ContactRT.Id;
           con.CommunityAccessRequestId__c = car.Id;  // Store the Id of the Communty access request record on new contact.
           conList.add(con); 
                           
        }
     }
    if (conList.size() > 0){
     insert conList;
    }

    /**************************************************************************************************************************************************
    - If there was a CAR of Record Type Update/ 
        Logic - Loops through the CAR. 
                Checks if there are corresponding ACPs for the CAR permission. If there is not and if there is a corresponding parent asset group. 
                It creates the ACP 
                If in case the ACP already exists, it checks if the Access TYpe is the Same. If the Access Type is different. This it updates the Access Type. 

    ****************************************************************************************************************************************************/
    if (setContactId.size() > 0)
    {
        List<CS_Asset_Contact_Permissions__c> lstAssetContactPermissions = new List<CS_Asset_Contact_Permissions__c>([Select ID, CS_ACP_Unique_Key__c,CS_Asset__c,CS_Contact__c,CS_Asset__r.CS_Support_Group__c,CS_Access_Type__c  from CS_Asset_Contact_Permissions__c Where CS_Contact__c IN:setContactId AND CS_Asset__r.CS_No_Customer_Contact__c=:False]); //Get existing ACPs for Contact associated with the Community Access Request Form. 

        //Make a Map of ACPs from the Above queried ACPs'. Key to the Map is Contact ID + Asset ID 
        for (CS_Asset_Contact_Permissions__c loopExistingASP:lstAssetContactPermissions){
        mapExistingAcps.put(String.Valueof(loopExistingASP.CS_Contact__c) + String.Valueof(loopExistingASP.CS_Asset__c) ,loopExistingASP);
        System.Debug('mapwhenformed' + mapExistingAcps);
        }
        Map<ID, Contact> mapAccountsforTypeCheck = new Map<Id,Contact>([Select ID, Name, Account.Id, User__r.IsActive, Account.RecordType.Name from Contact Where Id in:setContactId]); //Query additional information of Contact and put it in a Map. 
        for (Contact cntact: mapAccountsforTypeCheck.values() ){
            setAccountId.add(cntact.Account.Id);
        }
        
        List<Asset> lstAsset =new List<Asset>([Select Id, CS_Is_Active__c,AccountId,CS_Support_Group__c from Asset where CS_Record_Type_Name__c = 'Parent Asset' AND AccountId in:setAccountId AND CS_No_Customer_Contact__c=:False]); //Make a list of Assets that be further used in the below code to check if thers is no corresponding ACP, we will create one. 
        
        for(Community_Access_Request__c car: carLst)
        {
            if (car.BillingCenter_Support_Group__c != '' && car.BillingCenter_Support_Group__c != null ){
            mapCarGroup.put(car.BillingCenter_Support_Group__c, car.BillingCenter_Access_type__c);
            }
            if (car.ClaimCenter_support_group__c != ''&& car.ClaimCenter_support_group__c != null){
            mapCarGroup.put(car.ClaimCenter_support_group__c, car.ClaimCenter_Access_type__c);
            }
            if (car.PolicyCenter_support_group__c != '' && car.PolicyCenter_support_group__c != null){
            mapCarGroup.put(car.PolicyCenter_support_group__c, car.PolicyCenter_Access_type__c);
            }
            if (car.Data_Management_support_group__c != '' && car.Data_Management_support_group__c != null)
            {
            mapCarGroup.put(car.Data_Management_support_group__c, car.Data_Management_Access_type__c);
            }
            if (car.Digital_Portals_support_group__c != '' && car.Digital_Portals_support_group__c != null){
            mapCarGroup.put(car.Digital_Portals_support_group__c, car.Digital_Portals_Access_type__c);
            }
            System.Debug('++mapCarGroup++' + mapCarGroup);
            //Loop thru assets, check the one that does not have a corresponding ACP and create a new ACP 
            /*
            for (Asset assetRecord: lstAsset){
                System.Debug('++contact+asset++' + String.ValueOf(car.Contact__c) + String.ValueOf(assetRecord.Id));
                System.Debug('++ mapExistingAcps.get(String.ValueOf(car.Contact__c) + String.ValueOf(assetRecord.Id))++' + mapExistingAcps.get(String.ValueOf(car.Contact__c) + String.ValueOf(asset.Id)));
                if (mapExistingAcps.get(String.ValueOf(car.Contact__c) + String.ValueOf(asset.Id)) == null && mapCarGroup.get(assetRecord.CS_Support_Group__c) != ''&& mapCarGroup.get(assetRecord.CS_Support_Group__c) != null){
                        Contact cnt = mapAccountsforTypeCheck.get(car.Contact__c);
                        if (cnt.AccountId == assetRecord.AccountID){
                        CS_Asset_Contact_Permissions__c acp = new CS_Asset_Contact_Permissions__c();
                            acp.CS_Access_Type__c = mapCarGroup.get(assetRecord.CS_Support_Group__c);
                            acp.CS_Contact__c = cnt.Id;
                            acp.CS_Asset__c = assetRecord.Id;
                            acp.Name = cnt.name;
                            
                            if (cnt.user__r.IsActive) //IF it has a relevant User in active state, then activate the ACP. 
                            {
                                acp.CS_IsActive__c = true;
                            }else {
                                acp.CS_IsActive__c = false;
                            }    

                            lstACPUpdate.add(acp);
                            System.Debug('++ lstACPUpdate_1++' + lstACPUpdate);
                        }
                }
            } */
            System.Debug('++ lstACPUpdate1 ++' + lstACPUpdate);
            //Loop through the ACP's check if the Assess Type has changed in the Update request. If changed. Update the Access Type.               
            for (CS_Asset_Contact_Permissions__c acpRecord:lstAssetContactPermissions){

                String acpAssetGroup = acpRecord.CS_Asset__r.CS_Support_Group__c; 

                if (acpRecord.CS_Access_Type__c != mapCarGroup.get(acpRecord.CS_Asset__r.CS_Support_Group__c) && mapCarGroup.get(acpRecord.CS_Asset__r.CS_Support_Group__c) !='' && mapCarGroup.get(acpRecord.CS_Asset__r.CS_Support_Group__c) != null )
                    {
                        
                        acpRecord.CS_Access_Type__c = mapCarGroup.get(acpRecord.CS_Asset__r.CS_Support_Group__c);
                        lstACPUpdate.add(acpRecord);
                        
                    }
                                
                }
            mapCarGroup.clear();
        }   
        System.Debug('++ lstACPUpdate ++' + lstACPUpdate);
        //If there are values in the list, update the ACP List. 
        if (lstACPUpdate.size() >0 ){

        upsert lstACPUpdate;
        } 
    
    }

    /**************************************************************************************************************************************************
    End of changes made for Requirement to Update the ACP on Update CAR request 
    ****************************************************************************************************************************************************/
    
   
     Map<id,Id> ContactReqMap = new Map<id,id>();  // store the Contact to CommReq ids.
      for(Contact cont: conList)
      {
          if(cont.CommunityAccessRequestId__c != null)
           {
               Id reqId = Id.valueOf(cont.CommunityAccessRequestId__c);
               ContactReqMap.put(reqId,Cont.Id);
           }
      }
     
      List<Community_Access_Request__c> reqLst = [Select id,name, Contact__c,Account__c from Community_Access_Request__c where Id IN: carIds];
      List<Community_Access_Request__c> updateCarLst = new List<Community_Access_Request__c>();
      Set<id> AccountIds = new Set<Id>();
      for(Community_Access_Request__c car: reqLst)
      {
        if(ContactReqMap.get(car.Id) != Null)
        {
            Car.Contact__c = ContactReqMap.get(car.Id);
            updateflag = true;
        }
        accountIds.add(car.Account__c);
        updateCarLst.add(car);
      }
      if(updateFlag)
      {
        flag = false;
        update updateCarLst;
      }
      
        
        List<string> excludeLst = new List<String>();
      
      // Custom setting to store the groups to be excluded.
        List<Support_Groups_CAR__c> groups = Support_Groups_CAR__c.getAll().values();
        for(Support_Groups_CAR__c sg : groups)
        {
            excludeLst.add(sg.Group__c);
        }
           
        List<CS_Asset_Contact_Permissions__c> acpLst = new List<CS_Asset_Contact_Permissions__c>();
      
        List<Community_Access_Request__c> updatedReqLst = [Select id,name, Create_Contact__c,Contact__c,Contact__r.name,Account__c,recordTypeId,BillingCenter_Support_Group__c,BillingCenter_Access_type__c,ClaimCenter_support_group__c,ClaimCenter_Access_type__c,Data_Management_support_group__c,
                                                       Data_Management_Access_type__c,Digital_Portals_support_group__c,Digital_Portals_Access_type__c, GW_Live_Support_Group__c, GW_Live_Access_Type__c,PolicyCenter_support_group__c,
                                                       PolicyCenter_Access_type__c,Predictive_Analytics_Support_Group__c,Predictive_Analytics_Access_Type__c from Community_Access_Request__c where Id IN: carIds];
                                                       
           List<Asset> AsstLst = [Select id,name,CS_Support_Group__c,AccountId,RecordtypeId from Asset where AccountId IN: AccountIds and RecordtypeId =: AssetRT.Id  and CS_Support_Group__c not IN: excludeLst];
           system.debug('Asset code lst :'+asstLst.size());
           
           
           for(Community_Access_Request__c car: updatedReqLst)
           {
              Community_Access_Request__c oldCar = carOldMap.get(car.Id);
              if(car.recordTypeId == RequestRT.Id && ((oldcar.Create_Contact__c != car.Create_Contact__c &&  car.Create_Contact__c == true) || (oldcar.Contact__c == Null && car.Contact__c != Null)) )
              {
              for(Asset asst : AsstLst)
              {
                  
                  if(asst.CS_Support_Group__c != null)
                  {
                      CS_Asset_Contact_Permissions__c acp = new CS_Asset_Contact_Permissions__c();
                         acp.CS_Contact__c = car.Contact__c;
                         acp.CS_Asset__c = asst.Id;
                         acp.Name = car.Contact__r.name;
                         acp.CS_IsActive__c = false;
                         
                        if(asst.CS_Support_Group__c == car.BillingCenter_Support_Group__c )
                        {
                           acp.CS_Access_Type__c = car.BillingCenter_Access_type__c;
                        }
                        else if(asst.CS_Support_Group__c == car.ClaimCenter_support_group__c )
                        {
                            acp.CS_Access_Type__c = car.ClaimCenter_Access_type__c;
                        }
                         else if(asst.CS_Support_Group__c == car.Data_Management_support_group__c)
                        {
                            acp.CS_Access_Type__c = car.Data_Management_Access_type__c;
                        }
                         else if(asst.CS_Support_Group__c == car.Digital_Portals_support_group__c)
                        {
                            acp.CS_Access_Type__c = car.Digital_Portals_Access_type__c;
                        }
                         else if(asst.CS_Support_Group__c == car.GW_Live_Support_Group__c)
                        {
                             acp.CS_Access_Type__c = car.GW_Live_Access_Type__c;
                        }
                        else if(asst.CS_Support_Group__c == car.PolicyCenter_support_group__c)
                        {
                            acp.CS_Access_Type__c = car.PolicyCenter_Access_type__c;
                        }
                         else if(asst.CS_Support_Group__c == car.Predictive_Analytics_Support_Group__c)
                        {
                            acp.CS_Access_Type__c = car.Predictive_Analytics_Access_Type__c;
                        }
                        else if(car.BillingCenter_Support_Group__c == null || car.ClaimCenter_support_group__c == null || car.Data_Management_support_group__c == null || car.Digital_Portals_support_group__c == null || car.GW_Live_Support_Group__c == null || car.PolicyCenter_support_group__c == null || car.Predictive_Analytics_Support_Group__c == null )
                        {
                            acp.CS_Access_Type__c ='General Customer';
                        }
                        acpLst.add(acp);
                        
                  }
              }
             }
           }
           if (acpLst.size()>0){
        insert acpLst;  
       system.debug('Acp code lst :'+acpLst.size());
       }
    }
  
 }