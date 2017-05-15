/*
******************************************************************************************************************************
Controller Class Name- CS_AssetContactTriggerHandler
Object - CS_Asset_Contact_Permissions__c
Purpose- Trigger Handler 
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation
Mani     manig@slalom.com  9/11/2016     Bug Fixes DE751 DE736
Mani     manig@slalom.com  9/12/2016     Bug Fixes  to support  CAR Changes
Mani     manig@slalom.com  9/17/2016     Big Fix For Asset Share Removal When ACP for customer is downgraded
                                         from Customer Support /Customer Support (Read only) to General Customer
Mani    manig@slalom.com   9/21/2016     DE953 - Bug Fix for Asset Share being created only for one asset per contact
Suchitra spurushotham      11/15/2016    Bug INC0065032 - We are passing additional case parameter ContactID when calling UTL_CS_CaseTeamMemberUtility
         @guidewire.com 

******************************************************************************************************************************                                      
ACPS are applied only to Support Contacts
Event    Permission                                     Action
create   General Customer                               Asset Share on Parent and Child Asset
update   Upgrade (General Customer to Customer Support) Case R/W Access 
update   Upgrade (General Partner to Customer Support)  Case R/W Access 
update   Upgrade (Customer Support(Read Only) to        Case R/W Access 
         Customer Support) 
update   Upgrade (General Customer to Customer Support  Case  Read Access
          (Read only)) 
update  Downgrade Customer Support/Customer(Readonly)   Remove Case Access
        to General Customer 

update  Deactivating ACP for Customer                   Remove Case Access and Asset Share 
*****************************************************************************************************************************
*/
public without sharing class CS_AssetContactTriggerHandler implements Cs_ITrigger {
    
    private List<CaseTeamMember> newCaseTeamMemberList = new List<CaseTeamMember>();
    private List<CaseTeamMember> caseTeamMemberListToUpdate = new List<CaseTeamMember>();
    private List<CaseTeamMember> caseTeamMemberListToDelete = new List<CaseTeamMember>();
    private List<AssetShare> assetShareListToInsert = new List<AssetShare>();
    private List<AssetShare> assetShareListToDelete = new List<AssetShare>();
    private List<CaseTeamMember> reactivatedCaseTeamMemberListToInsert = new List<CaseTeamMember>();
    private List<AssetShare> reactivateAssetShareListToInsert = new List<AssetShare>();
    private List<AccountShare> accountShareListToInsert = new List<AccountShare>();
    private List<AccountShare> PartneraccountShareListToInsert = new List<AccountShare>();
    private List<AccountShare> AccountShareList = new List<AccountShare>();
    private List<AccountShare> reactivatedPartnerAccountShareListToInsert = new List<AccountShare>();
    private List<AccountShare> reactivatedAccountShareListToInsert = new List<AccountShare>();
    private List<AccountShare> accountShareListToDelete = new List<AccountShare>();
    // set to hold related asset Ids
    private Set<Id> assetIds = new Set<Id>();
    private Set<String> accessTypes = new Set<String>();
    private CS_ByPass__c bypass {
        get {
            return  CS_ByPass__c.getInstance(UserInfo.getUserId());
        }
    }
    // constructor
    public CS_AssetContactTriggerHandler() {
        
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
        // If condition for Is Update Begins
        if (Trigger.isUpdate) {
            
            //ID sets to hold Access type changes
            Set<Id> memberIdSet = new Set<Id>();
            Set<Id> UserIdSet = new Set<Id>();
            Set<Id> assetIds = new Set<Id>();
            Set<Id> relatedCaseIds = new Set<Id>();

            //Id sets to hold deactivated ACP
            Set<Id> deactivateACPMemberIdSet = new Set<Id>();
            Set<Id> deactivatACPCaseIdSet = new Set<Id>();
            Set<Id> deactivatACPAssetIdSet = new Set<Id>();
            Set<Id> deactivatedPartnerContactIdSet = new Set<Id>();
            Set<Id> deactivatedACPAccountIdSet = new Set<Id>();
            Set<Id> deactivatedAcpIdSet = new Set<Id>();
            Set<Id> deactivatedPartnerACPAccountIdSet = new Set<Id>();
            Set<Id> deactivatedCustomerContactIdSet = new Set<Id>();

            // Id set to hold reactivated ACP
            Set<Id> reactivatedAssetIdSet = new Set<Id>();
            Map<Id, Set<Id>> reactivatedContactToAssetMap = new Map<Id,Set<Id>>();
            Set<Id> reactivatedPartnerContactIdSet = new Set<Id>();
            Set<Id> reactivatedACPAccountIdSet = new Set<Id>();
            Set<Id> reactivatedAcpIdSet = new Set<Id>();
            Set<Id> reactivatedCustomerContactIdSet = new Set<Id>();
            Set<Id> Parent_Child_AssetIds = New Set<Id>();



            // query updated asset contact records
            List<CS_Asset_Contact_Permissions__c> newAssetContactList = [Select Id, CS_Asset__c, CS_IsActive__c, 
                                                                         CS_Contact__c, CS_Access_Type__c from CS_Asset_Contact_Permissions__c 
                                                                         where Id in :Trigger.newMap.keySet()];

            for (SObject so : Trigger.new) {
                CS_Asset_Contact_Permissions__c ac = (CS_Asset_Contact_Permissions__c)so;
                Boolean oldActivateStatus = (Boolean) Trigger.oldMap.get(ac.Id).get('CS_IsActive__c');
                String  oldPermission = (String)Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c');
                
                // ACP Permissions Changed 
                if (ac.CS_IsActive__c == oldActivateStatus && ac.CS_Access_Type__c !=oldPermission){                

                    // ACP change from General to Case Read/Write Access 
                    // Bug Fixes DE751 DE736
                    if( (Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c')=='General Customer'||
                         Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c')=='General Partner') &&
                        (ac.CS_Access_Type__c =='Customer Support' ||
                         ac.CS_Access_Type__c =='Customer Support (View Only)'||
                         ac.CS_Access_Type__c =='Partner')){

                            // ACP  Change for Partner
                            if (ac.CS_Access_Type__c == 'Partner') {
                                System.debug('Inside Partner');
                                reactivatedAcpIdSet.add(ac.Id);
                                reactivatedPartnerContactIdSet.add(ac.CS_Contact__c);
                                reactivatedAssetIdSet.add(ac.CS_Asset__c);
                                if(reactivatedContactToAssetMap.containsKey(ac.CS_Contact__c))
                                    reactivatedContactToAssetMap.get(ac.CS_Contact__c).add(ac.CS_Asset__c);
                                else
                                    reactivatedContactToAssetMap.put(ac.CS_Contact__c, new Set<Id>{ac.CS_Asset__c});
                                accessTypes.add(ac.CS_Access_Type__c);
                                memberIdSet.add(ac.CS_Contact__c);
                            }
                            // ACP Change for Customer 
                            else{               
                                System.debug('ACP Change for Customer');        
                                reactivatedAssetIdSet.add(ac.CS_Asset__c);
                                if(reactivatedContactToAssetMap.containsKey(ac.CS_Contact__c))
                                    reactivatedContactToAssetMap.get(ac.CS_Contact__c).add(ac.CS_Asset__c);
                                else
                                    reactivatedContactToAssetMap.put(ac.CS_Contact__c, new Set<Id>{ac.CS_Asset__c});
                                accessTypes.add(ac.CS_Access_Type__c);
                                }
                    }       
                            //ACP  Toggle between Read and Write     
                            // Added check by Mani on 09/17   
                    else if  ((Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c')=='Customer Support'||
                             Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c')=='Customer Support (View Only)' ||
                             Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c')=='Partner') &&
                            (ac.CS_Access_Type__c =='General Customer' ||
                             ac.CS_Access_Type__c =='General Partner') ){
                                    System.debug('------Iam Inside -------');
                                    deactivateACPMemberIdSet.add(ac.CS_Contact__c);
                                    //deactivatACPAssetIdSet.add(ac.CS_Asset__c);       
                                    //deactivatedAcpIdSet.add(ac.Id);
                                    deactivatedPartnerContactIdSet.add(ac.CS_Contact__c);
                            }
                    else {
                                System.debug('Inside Access Toggle');
                                memberIdSet.add(ac.CS_Contact__c);
                                accessTypes.add(ac.CS_Access_Type__c);
                                assetIds.add(ac.CS_Asset__c);
                    }
                }
                
                // IF ACP Deactivated
                String oldAccessType = (String) Trigger.oldMap.get(ac.Id).get('CS_Access_Type__c');
                // if ACP record is deactivated, add to deactivated Id sets
                if (ac.CS_IsActive__c == false && oldActivateStatus== true)
                
                    // Commented by Mani G on 09/17 
                    //(ac.CS_Access_Type__c !='Customer Support' && ac.CS_Access_Type__c != 'Customer Support (View Only)' 
                    //  $&& ac.CS_Access_Type__c != 'Partner' && ac.CS_Access_Type__c != oldAccessType)) 
                       {
                                System.debug('------Iam Set here');
                                deactivateACPMemberIdSet.add(ac.CS_Contact__c);
                                deactivatACPAssetIdSet.add(ac.CS_Asset__c);                 
                    if (ac.CS_Access_Type__c == 'Partner') {
                                deactivatedAcpIdSet.add(ac.Id);
                                deactivatedPartnerContactIdSet.add(ac.CS_Contact__c);
                    }
                }


                // if ACP is re-activated, add to re-activated Id sets
                Map<Id, CS_Asset_Contact_Permissions__c> csOldMap = (Map<Id, CS_Asset_Contact_Permissions__c>)Trigger.oldMap;
                if (ac.CS_IsActive__c == true && oldActivateStatus== false &&
                 (ac.CS_Access_Type__c =='Customer Support' || ac.CS_Access_Type__c=='General Customer' || ac.CS_Access_Type__c == 'Customer Support (View Only)' || ac.CS_Access_Type__c == 'Partner')) {              
                                reactivatedAssetIdSet.add(ac.CS_Asset__c);
                                if(reactivatedContactToAssetMap.containsKey(ac.CS_Contact__c))
                                    reactivatedContactToAssetMap.get(ac.CS_Contact__c).add(ac.CS_Asset__c);
                                else
                                    reactivatedContactToAssetMap.put(ac.CS_Contact__c, new Set<Id>{ac.CS_Asset__c});
                                accessTypes.add(ac.CS_Access_Type__c);
                    if (ac.CS_Access_Type__c == 'Partner') {
                                reactivatedAcpIdSet.add(ac.Id);
                                reactivatedPartnerContactIdSet.add(ac.CS_Contact__c);
                    }
                }

            }

            //  User id  fetch from ACP Contact Ids
            for(User  UserCon : [select id  from User where contactid in:memberIdSet and isactive=true]){                                                         
                UserIdSet.add(UserCon.id);
            }

            // Partner Added to ACP 
            // query all active partner ACP in Trigger.old
            List<CS_Asset_Contact_Permissions__c> oldPartnerACPList = [Select Id from CS_Asset_Contact_Permissions__c
                                                                              where CS_Access_Type__c = 'Partner'
                                                                              and CS_IsActive__c = true
                                                                              and Id in :Trigger.oldMap.keySet()];

            // query all active partner ACP in Trigger.new
            List<CS_Asset_Contact_Permissions__c> newPartnerACPList = [Select Id from CS_Asset_Contact_Permissions__c
                                                                              where CS_Access_Type__c = 'Partner'
                                                                              and CS_IsActive__c = true
                                                                              and Id in :Trigger.newMap.keySet()];

            /* compare Trigger.new and Trigger.old, if there's no active ACP in trigger.new, but there are active ACPs in trigger.old, 
             * meaning that the last partner ACP is deactivated
             */
            if (oldPartnerACPList.size() > 0 && (newPartnerACPList == null || newPartnerACPList.isEmpty())) {
                for (CS_Asset_Contact_Permissions__c acp : [select CS_Contact__c  from
                                                           CS_Asset_Contact_Permissions__c where 
                                                           CS_Asset__c in:deactivatedAcpIdSet]) {
                    deactivatedCustomerContactIdSet.add(acp.CS_Contact__c);
                }
            }

            // query reactivated ACP's customer contacts
            for (CS_Asset_Contact_Permissions__c acp : [select CS_Contact__c  from
                                                           CS_Asset_Contact_Permissions__c where 
                                                           CS_Asset__c in:reactivatedAcpIdSet]) {
                reactivatedCustomerContactIdSet.add(acp.CS_Contact__c);
            }


            // retrieve ACP related account Ids for reactivated acps
            reactivatedACPAccountIdSet = getAcpRelatedAccountId(reactivatedAcpIdSet);
            
            // retrieve ACP related account Ids for deactivated acps
            deactivatedACPAccountIdSet = getAcpRelatedAccountId(deactivatedAcpIdSet);
            //System.debug('deactivatedACPAccountIdSet ' + deactivatedACPAccountIdSet);

            // re-create AssetShare record when ACP record is re-activated
            // look for deactivated parent's child assets
            Map<Id, Set<Id>> reactivatedParentChildAssetMap = new Map<Id, Set<Id>>();
            if (!reactivatedAssetIdSet.isEmpty()){
                    for(Asset a : [Select Id, ParentId from Asset where ParentId in :reactivatedAssetIdSet]){
                        if(reactivatedParentChildAssetMap.containsKey(a.ParentId))
                            reactivatedParentChildAssetMap.get(a.ParentId).add(a.Id);
                        else
                            reactivatedParentChildAssetMap.put(a.ParentId, new Set<Id>{a.Id});
                    }
                }
            if (reactivatedContactToAssetMap != null && !reactivatedContactToAssetMap.isEmpty()) {
                reactivateAssetShareListToInsert = createAssetShare(reactivatedContactToAssetMap, reactivatedParentChildAssetMap);
            }

            // re-create AccountShare when ACP with access type "partner" is re-activated
            if (reactivatedPartnerContactIdSet != null && !reactivatedPartnerContactIdSet.isEmpty()) {
                reactivatedAccountShareListToInsert = createAccountShare(reactivatedCustomerContactIdSet, reactivatedACPAccountIdSet);
            }

            // query re-activated ACP child Asset if deactivated ACP is parent
            Map<Id, Asset> childAssetMap = new Map<Id, Asset>([Select Id, ParentId from Asset where ParentId in :reactivatedAssetIdSet]);
            //system.debug('========childAssetMap===='+childAssetMap);
            // query re-activated ACP related cases
            List<Case> reactivatedACPCases;
            if (childAssetMap != null && !childAssetMap.isEmpty()) {
                reactivatedACPCases = [Select Id,ContactId,CS_Parent_AssetId__c from Case where AssetId in :childAssetMap.keySet()];//INC0065032, Added ContactID to Query
            } else {
                reactivatedACPCases = [Select Id,ContactId,CS_Parent_AssetId__c from Case where AssetId in :reactivatedAssetIdSet];//INC0065032, Added ContactID to Query
            }

            // re-create Case Team Member
            if (reactivatedACPCases!= null && !reactivatedACPCases.isEmpty() && reactivatedAssetIdSet != null && !reactivatedAssetIdSet.isEmpty()) {
                reactivatedCaseTeamMemberListToInsert = UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(reactivatedACPCases, accessTypes, Trigger.new);
                //System.debug('reactivatedCaseTeamMemberListToInsert ' + reactivatedCaseTeamMemberListToInsert);
            }

            // retrieve deactivated users' Ids
            Map<Id, User> deactivatedUserMap = getUserMap(deactivateACPMemberIdSet);
            // look for deactivated parent's child assets
            Map<Id, Asset> deactivatedParentChildAssetMap = new Map<Id, Asset>([Select Id from Asset where ParentId in :deactivatACPAssetIdSet]);

            
            // delete Asset Share record for deactivated ACP records
            //System.Debug('deactivatACPAssetIdSet====='+deactivatACPAssetIdSet);
            if (deactivatACPAssetIdSet != null && !deactivatACPAssetIdSet.isEmpty()) {

                if(deactivatedParentChildAssetMap !=null & !deactivatedParentChildAssetMap.isEmpty()) {
                    Parent_Child_AssetIds.addAll(deactivatedParentChildAssetMap.keyset());
                }
                Parent_Child_AssetIds.addAll(deactivatACPAssetIdSet);

                assetShareListToDelete =  deleteAssetShare(Parent_Child_AssetIds, deactivatedUserMap.keySet());
            }

            // retrieve deactivated partner users' Ids
            Map<Id, User> deactivatedPartnerCustomerContactMap = getUserMap(deactivatedCustomerContactIdSet);

            // delete Account Share for deactivated ACP records
            if (deactivatedPartnerContactIdSet != null && !deactivatedPartnerContactIdSet.isEmpty()) {
                //accountShareListToDelete = deleteAccountShare(deactivatedPartnerUserMap.keySet(), deactivatedACPAccountIdSet);
                accountShareListToDelete = deleteAccountShare(deactivatedPartnerCustomerContactMap.keySet(), deactivatedACPAccountIdSet);
                //System.debug('accountShareListToDelete ' + accountShareListToDelete);
            }

            // query asset related cases
            List<Case> relatedCases = [Select Id ,contactid from Case where Asset.ParentId in :assetIds];
            for (Case c : relatedCases) {
                relatedCaseIds.add(c.Id);
            }

            //System.debug('relatedCaseIds ' + relatedCaseIds);

            // call update case team member utility class method
            if (relatedCaseIds != null && !relatedCaseIds.isEmpty() && memberIdSet != null && !memberIdSet.isEmpty()) {
                caseTeamMemberListToUpdate = UTL_CS_CaseTeamMemberUtility.updateCaseTeamMember(relatedCaseIds, UserIdSet, accessTypes);
            }
            
            // look for deactivated parent's child assets
            Map<Id, Case> deactiveACPRelatedCaseMap = new Map<Id, Case>();

            // if deactivated ACP is parent asset, query for child assets
            if(deactivatedParentChildAssetMap != null && !deactivatedParentChildAssetMap.isEmpty()) {
                // query deactivated ACP child assets related cases
                deactiveACPRelatedCaseMap = new Map<Id, Case>([Select Id from Case where AssetId in :deactivatedParentChildAssetMap.keySet()]);
            } else {
                // else query cases if deactivated ACP is child asset
                deactiveACPRelatedCaseMap = new Map<Id, Case>([Select Id from Case where AssetId in :deactivatACPAssetIdSet]);
            }

            // delete case team member method if the ACP is deactivated

            if (deactivateACPMemberIdSet != null && !deactivateACPMemberIdSet.isEmpty() && deactiveACPRelatedCaseMap != null) {
                caseTeamMemberListToDelete = UTL_CS_CaseTeamMemberUtility.deleteCaseTeamMember(deactivatedUserMap.keySet(), deactiveACPRelatedCaseMap.keySet());
                //System.debug('caseTeamMemberListToDelete ' + caseTeamMemberListToDelete);
            }
        }

        // If condition for Is Update Ends
        // Added by Mani , to Default Evaluation End Date for Prospect for 60 days
        If(Trigger.isInsert && Trigger.isbefore){
            for (SObject To : Trigger.new) {
                CS_Asset_Contact_Permissions__c bi = (CS_Asset_Contact_Permissions__c)To;
                if(bi.CS_Access_Type__c =='Prospect') {
                    bi.CS_Evaluation_End_Date__c= System.today()+60;
                }
            }

        }
    }
    
    public void bulkAfter()
    {
        if (Trigger.isInsert) {
            
            Set<Id> contactIds = new Set<Id>();
            Set<Id> partnerContactIds = new Set<Id>();
            Set<Id> ActivepartnerContactIds = new Set<Id>();
            Set<Id> customerContactIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> partnerAccountIds= new Set<Id>();
            Set<Id> acpIds = new Set<Id>();
            //Map<Id, Id> acpContactToAssetMap = new Map<Id, Id>();
            Map<Id, set<Id>> acpContactToAssetMap = new Map<Id, Set<Id>>();

            for (SObject so : Trigger.new) {
                CS_Asset_Contact_Permissions__c assetContact = (CS_Asset_Contact_Permissions__c)so;
                assetIds.add(assetContact.CS_Asset__c);
                contactIds.add(assetContact.CS_Contact__c);
                //DE953 - associating one contact to multiple assets
                //acpContactToAssetMap.put(assetContact.CS_Contact__c, assetContact.CS_Asset__c);
                if(assetContact.CS_IsActive__c){
                    if(acpContactToAssetMap.containsKey(assetContact.CS_Contact__c)){
                        acpContactToAssetMap.get(assetContact.CS_Contact__c).add(assetContact.CS_Asset__c);
                    }
                    else{
                        acpContactToAssetMap.put(assetContact.CS_Contact__c, new Set<Id>{assetContact.CS_Asset__c});
                    }
                }
                if (assetContact.CS_Access_Type__c == 'Partner') {
                    acpIds.add(assetContact.Id);
                    partnerContactIds.add(assetContact.CS_Contact__c);
                    partnerAccountIds.add(assetContact.CS_Account_Id__c);
                    //accountIds.add(assetContact.CS_Asset__r.AccountId);
                }
            }
            
            for(CS_Asset_Contact_Permissions__c  ACPCon : [select CS_Contact__c  from
                                                           CS_Asset_Contact_Permissions__c where 
                                                           CS_Asset__c in:assetIds and CS_Contact__r.Account.Recordtype.name='Customer'  
                                                           and CS_IsActive__c=true ]) {

                customerContactIds.add(ACPCon.CS_Contact__c);
            }

            for(CS_Asset_Contact_Permissions__c  ACPPartner : [select CS_Contact__c  from
                                                           CS_Asset_Contact_Permissions__c where 
                                                           CS_Asset__c in:assetIds and CS_Contact__r.Account.Recordtype.name='Partner' 
                                                           and CS_IsActive__c=true ]) {

                ActivepartnerContactIds.add(ACPPartner.CS_Contact__c);

            }

            
            // retrieve related account Ids
            accountIds = getAcpRelatedAccountId(acpIds);

            // query open cases that are linked to ACP assets
            //List<Case> assetCases = [Select Id from Case where AssetId in :assetIds and Status != 'Closed'];
            // Modified by Mani G On 6/15/2016 . Apply visbility to All Cases on Asset
            List<Case> assetCases = [Select Id ,contactid,CS_Parent_AssetId__c from Case where AssetId in (Select id from Asset where Parentid in :assetIds)];

            // query newly created asset contact rewords and retrieve the access types that are in Customer Support, Customer Support (View Only), and Partner
            List<CS_Asset_Contact_Permissions__c> assetContacts = [Select CS_Asset__c, CS_Contact__c, CS_Access_Type__c from 
                                                                   CS_Asset_Contact_Permissions__c where Id in :Trigger.newMap.keySet() 
                                                                   and CS_Access_Type__c in 
                                                                   (:Label.Customer_Support, :Label.Customer_Support_View_Only, :Label.Partner)];

            for (CS_Asset_Contact_Permissions__c ac : assetContacts) {
                accessTypes.add(ac.CS_Access_Type__c);
            }
            // create case team member
            if (assetContacts != null && !assetContacts.isEmpty()) {
                newCaseTeamMemberList = UTL_CS_CaseTeamMemberUtility.createCaseTeamMember(assetCases, accessTypes, assetContacts);
            }
            System.debug('contact ++++++++++' +contactIds);
            // create AssetShare record
            if (acpContactToAssetMap != null && !acpContactToAssetMap.isEmpty()) {

                System.debug('Contact id is not null');
                Set<Id> ParentAstId= New Set<Id>();
                Map<Id, Set<Id>> reactivatedParentChildAssetMap = new Map<Id, Set<Id>>();
                //Modified the Query  by Mani G on 08/18/2016 to Add Child Assets to Asset Share if Child Asset Exisits

                //List<Asset> AssetList= New List<Asset>([Select id from Asset where  id in :assetIds or Parentid in :assetIds]);
                for(Id i : acpContactToAssetMap.keyset())
                    parentAstId.addAll(acpContactToAssetMap.get(i));
                if(!parentAstId.isEmpty()){
                    for(Asset a : [Select Id, ParentId from Asset where Parentid in :parentAstId]){
                        if(reactivatedParentChildAssetMap.containsKey(a.ParentId))
                            reactivatedParentChildAssetMap.get(a.ParentId).add(a.Id);
                        else
                            reactivatedParentChildAssetMap.put(a.ParentId, new Set<Id>{a.Id});
                    }
                }
                //assetShareListToInsert = createAssetShare(contactIds, ParentAstId);
                //assetShareListToInsert = createAssetShare(acpContactToAssetMap.keySet(), ParentAstId);
                //DE953 - new assetshare method
                assetShareListToInsert = createAssetShare(acpContactToAssetMap, reactivatedParentChildAssetMap);
            }

            // create AccountShare record for contact who's ACP access type is "Partner"
            if (partnerContactIds != null && !partnerContactIds.isEmpty()) {
                accountShareListToInsert = createAccountShare(partnerContactIds, accountIds);
                AccountShareList.addAll(accountShareListToInsert);
            }
            // Added by Mani G on 07/30 partner account share to Customer Contacts 
            if(customerContactIds!=null &&  partnerAccountIds!=null){

                PartneraccountShareListToInsert = createAccountShare(customerContactIds, partnerAccountIds);
                AccountShareList.addAll(PartneraccountShareListToInsert);
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
        //Inserting Case TeamMember
        try {
                if (Trigger.isInsert && Trigger.isAfter && newCaseTeamMemberList != null && !newCaseTeamMemberList.isEmpty()) {
                        upsert newCaseTeamMemberList;
                    }
            }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Upserting Case Team Member list newCaseTeamMemberList'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Updating Case TeamMember
        try {
                if (Trigger.isUpdate && caseTeamMemberListToUpdate != null && !caseTeamMemberListToUpdate.isEmpty()) {
                    update caseTeamMemberListToUpdate;
            
                }
            }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Updating Case Team Member list caseTeamMemberListToUpdate'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Deleting Case TeamMember
        try {
                if (Trigger.isUpdate && caseTeamMemberListToDelete != null && !caseTeamMemberListToDelete.isEmpty()) {
                    delete caseTeamMemberListToDelete;
                }
            }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Deleting Case Team Member list caseTeamMemberListToDelete'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Inserting Asset Share
        try {
                if (Trigger.isInsert && Trigger.isAfter && assetShareListToInsert != null && !assetShareListToInsert.isEmpty()) {
                    system.debug('=====> ' + assetShareListToInsert);
                    insert assetShareListToInsert;
                }
            }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Inserting Asset Share list assetShareListToInsert on ACP Create'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Deleting Asset Share
        try {
                if (Trigger.isUpdate && assetShareListToDelete != null && !assetShareListToDelete.isEmpty()) {
                    delete assetShareListToDelete;
                }
            }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Deleting Asset Share list assetShareListToDelete on ACP Update'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }
        //Insert  Case Team Member on ACP Reactivation
        try {
            if (Trigger.isUpdate && reactivatedCaseTeamMemberListToInsert != null && !reactivatedCaseTeamMemberListToInsert.isEmpty()) {
                upsert reactivatedCaseTeamMemberListToInsert;
            }
        }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Inserting Case TeamMember  list reactivatedCaseTeamMemberListToInsert on ACP Reactivation'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }
        //Insert Asset Share  on ACP Reactivation   
        try{
            if (Trigger.isUpdate && reactivateAssetShareListToInsert != null && !reactivateAssetShareListToInsert.isEmpty()) {
                insert reactivateAssetShareListToInsert;
            }
        }
            catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Inserting Case TeamMember  list reactivateAssetShareListToInsert on ACP Reactivation'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Upsert Asset Share on After
        try{
            if (Trigger.isAfter && accountShareListToInsert != null && !accountShareListToInsert.isEmpty()) {
                upsert AccountShareList;
            }
        }
        catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Upsert Asset Share  list accountShareListToInsert on ACP Reactivation'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

        //Insert Asset Share on After ACP Reactivation
        try{            
            if (Trigger.isUpdate && reactivatedAccountShareListToInsert != null && !reactivatedAccountShareListToInsert.isEmpty()) {
                insert reactivatedAccountShareListToInsert;
            }
        }
        catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Inserting Asset Share  list reactivatedAccountShareListToInsert on ACP Reactivation'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }

    //Delete Asset Share on After ACP Deactivation
     try{
            if (Trigger.isUpdate && accountShareListToDelete != null && !accountShareListToDelete.isEmpty()) {
                delete accountShareListToDelete;
            }
        }
        catch (DmlException e) {
                    System.debug('The following Error has occured ' + e.getMessage());
                    CS_ExceptionHandler.createErrorRecordMessage('Error Occured While Deleting Asset Share  list accountShareListToDelete on ACP Deactivation'+ e.getMessage(),'CS_AssetContactTriggerHandler.Finally');
            }


    }

    public List<AssetShare> deleteAssetShare(Set<Id> assetIds, Set<Id> userIds) {
        List<AssetShare> assetShareList = [Select Id from AssetShare where AssetId in :assetIds and UserOrGroupId in :userIds];

        return assetShareList;
    }
    
    //DE953 - a new method to create share only for the related acp contacts
    public List<AssetShare> createAssetShare(Map<Id, Set<Id>> contactAssetMap, Map<Id, Set<Id>> parentToChildAssetMap)
    {
        List<AssetShare> newAssetShareList = new List<AssetShare>();
        Map<Id, Id> usersToContactMap = new Map<Id, Id>();
        
        for(User u : [Select Id, ContactId from User where ContactId in :contactAssetMap.keyset() and isActive = :true]){
            usersToContactMap.put(u.ContactId, u.Id);
        }
        
        for(Id contactId : contactAssetMap.keyset()){
            for(Id assetId : contactAssetMap.get(contactId)){
                if(usersToContactMap.containskey(contactId)){
                    newAssetShareList.add(populateAssetShareFields(assetId, usersToContactMap.get(contactId)));
                    // Create for child assets
                    if(parentToChildAssetMap != null && parentToChildAssetMap.containsKey(assetId)){
                        for(Id childAssetId : parentToChildAssetMap.get(assetId)){
                            newAssetShareList.add(populateAssetShareFields(childAssetId, usersToContactMap.get(contactId)));
                        }
                    }
                }
            }
        }
        return newAssetShareList;
    }
    
    private AssetShare populateAssetShareFields(Id AssetId, Id UserId){
        AssetShare newAssetShare = new AssetShare();
        newAssetShare.AssetAccessLevel = 'Read';
        newAssetShare.UserOrGroupId = userId;
        newAssetShare.AssetId = assetId;
        newAssetShare.RowCause = 'Manual';
        return newAssetShare;
    }

    public List<AssetShare> createAssetShare(Set<Id> contactIds, Set<Id> assetIds) {
        // query user id based on contact ids
        System.debug('+++++++= Inside Create  Asset Share');
        List<User> users = [Select Id, ContactId from User where ContactId in :contactIds and isactive=true];
        List<AssetShare> newAssetShareList = new List<AssetShare>();

        if (users != null && !users.isEmpty()) {
             for (Asset ac : [Select id from Asset where Id in :assetIds]) {
                for (User u : users) {
                    AssetShare newAssetShare = new AssetShare();
                    newAssetShare.AssetAccessLevel = 'Read';
                    newAssetShare.UserOrGroupId = u.Id;
                    newAssetShare.AssetId = ac.id;
                    newAssetShare.RowCause = 'Manual';

                    newAssetShareList.add(newAssetShare);
                }
            }
        }

        return newAssetShareList;
    }
    

    public List<AccountShare> createAccountShare(Set<Id> partnerContIds, Set<Id> accountIds) {
        // query user id
        List<User> users = [Select Id, ContactId from User where ContactId in :partnerContIds];

        List<AccountShare> newAccountShareList = new List<AccountShare>();

        if (users != null && !users.isEmpty()) {
            for (Id accountId : accountIds) {
                for (User u: users) {
                    AccountShare newAccountShare = new AccountShare();
                    newAccountShare.AccountAccessLevel = 'Read';
                    newAccountShare.AccountId = accountId;
                    newAccountShare.UserOrGroupId = u.Id;
                    newAccountShare.RowCause = 'Manual';
                    newAccountShare.OpportunityAccessLevel = 'None';
                    newAccountShare.CaseAccessLevel = 'None';

                    newAccountShareList.add(newAccountShare);
                }
            }
        }

        return newAccountShareList;
    }

    public List<AccountShare> deleteAccountShare(Set<Id> userIds, Set<Id> accountIds) {
        return [Select Id, AccountId, UserOrGroupId from AccountShare where AccountId in :accountIds and UserOrGroupId in :userIds];
    }

    // query deactivated ACP's contact user Ids
    public Map<Id, User> getUserMap(Set<Id> contactIds) {
        Map<Id, User> userMap = new Map<Id, User>([Select Id from User where ContactId in :contactIds]);
        return userMap;
    }

    // retreive ACP related account Ids
    public Set<Id> getAcpRelatedAccountId(Set<Id> acpIdSet) {
        // query all ACP fields
        Set<Id> acpAccountIds = new Set<Id>();
        List<CS_Asset_Contact_Permissions__c> acpList = [Select Id, CS_Asset__r.AccountId from CS_Asset_Contact_Permissions__c where Id in :acpIdSet];
        for (CS_Asset_Contact_Permissions__c acp : acpList) {
            acpAccountIds.add(acp.CS_Asset__r.AccountId);
        }

        return acpAccountIds;
    }
}