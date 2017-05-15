/*
*****************************************************************************************************************************
Class Name - CS_Case_Util
Class Type -  UTIL
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Shan Xu                        05/13/2016       Initial Creation
Mani G                         09/08/2016       Bug Fix  for DE641
Mani G                         09/18/2016       Bug Fix  for DEXXXX
Isaac                          09/10/2016       Bug Fix for INC0063826
*****************************************************************************************************************************
*/
public with sharing class CS_Case_Util {

/*
 //Commented it  out by Mani G on 09/16 as Entitlement Match by ACP is not a valid Scenario
    Public Static Void EntMatchbyACP(Set<Id> ACPId,List<Case> caseList)
    {
        System.debug('InPut Values ====' + ACPID);
        Set<Id> ACPIds = New set<Id>();
        Set<Id> Assetid = New set<Id>();
        List<Case> caseListToUpdate = new List<Case>();

        Map<id,CS_Asset_Contact_Permissions__c> mapAstCts= new Map<id,CS_Asset_Contact_Permissions__c>([select id,CS_Access_Type__c, CS_Asset__c,
                                                            CS_Asset__r.accountid,CS_Asset__r.product2.product__c,CS_Asset__r.product2id,
                                                            CS_Asset_Name__c, CS_Asset_Status__c, CS_Contact__c, CS_Contact_Type__c,
                                                            CS_Asset__r.CS_Carbon_Copy_Email_1__c,CS_Asset__r.CS_Carbon_Copy_Email_2__c,CS_Asset__r.CS_Carbon_Copy_Email_3__c
                                                            from CS_Asset_Contact_Permissions__c where  id in:ACPId] );

        
         for(CS_Asset_Contact_Permissions__c fo:mapAstCts.values() ) {
                                Assetid.add(fo.CS_Asset__c);
                    }   
            

        Map<Id,Entitlement> mapEnt= New Map<Id,Entitlement>([select id,name,businesshoursid,Assetid from entitlement where Assetid  in:AssetId]);
            
            
            for(SObject so: caseList){
                Case b = (Case)so;
                
                if (b.CS_Contact_Asset__c != null && mapAstCts != null && !mapAstCts.isEmpty()) {
                    System.debug('Iam Inside the IF COndiiton  Now');
                    b.AssetId = mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__c; 
                    b.AccountId = mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.Accountid;             
                    // Added Check  for Bug Fix DE641
                    if(mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.product2id!=Null){
                        b.ProductId = mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.product2id;
                    }
                    b.CS_Carbon_Copy_Email_1__c=mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.CS_Carbon_Copy_Email_1__c;
                    b.CS_Carbon_Copy_Email_2__c=mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.CS_Carbon_Copy_Email_2__c;
                    b.CS_Carbon_Copy_Email_3__c=mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__r.CS_Carbon_Copy_Email_3__c;
                    if (mapEnt != null && !mapEnt.isEmpty()) {
                        for(Entitlement ent: mapEnt.values()) {
                            if( mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__c == ent.Assetid) {
                                b.entitlementid = ent.id;
                                b.businesshoursid=ent.businesshoursid;
                                
                            }
                        }
                    }
                }
           
                caseListToUpdate.add(b);
            }           

    }

    */

Public Static Void EntMatchbyAST(Set<Id> SetAssetId,List<Case> caseList){
        List<Id> AssetId = New List<Id>();
        List<Case> caseListToUpdate = new List<Case>();
         Map<id,Asset> mapAstCts= new Map<id,Asset>([Select id,Accountid,Product2id,Product2.product__c,
                                                    parent.CS_Carbon_Copy_Email_1__c,
                                                    parent.CS_Carbon_Copy_Email_2__c,
                                                    parent.CS_Carbon_Copy_Email_3__c from Asset where   id in:SetAssetId ]);
            for(Asset fo:mapAstCts.values() ) {
                                AssetId.add(fo.id);
                    }
            
            Map<Id,Entitlement> mapEnt= New Map<Id,Entitlement>([select id,name,businesshoursid,Assetid from entitlement where Assetid  in:AssetId]);
            
            
            for(SObject so: caseList){
                Case b = (Case)so;
                
                if (b.AssetId != null && mapAstCts != null && !mapAstCts.isEmpty()) {
                    
                    //b.AssetId = mapAstCts.get(b.CS_Contact_Asset__c).CS_Asset__c; 
                    b.AccountId = mapAstCts.get(b.AssetId).AccountId;
                     // Commented out for Bug Fix DE641
                    /*
                    if(mapAstCts.get(b.AssetId).Product2.product__c!=null){
                        b.ProductId = mapAstCts.get(b.AssetId).Product2.product__c;
                    }

                    else{
                        b.ProductId = mapAstCts.get(b.AssetId).Product2id;
                    } 
                    */
                    // Added Check  for Bug Fix DE641
                    if(mapAstCts.get(b.AssetId).Product2id!=null && b.AccountId != Label.Guidewire_AccountId){
                        b.ProductId = mapAstCts.get(b.AssetId).Product2id;
                    }
                    b.CS_Carbon_Copy_Email_1__c=mapAstCts.get(b.AssetId).parent.CS_Carbon_Copy_Email_1__c;
                    b.CS_Carbon_Copy_Email_2__c=mapAstCts.get(b.AssetId).parent.CS_Carbon_Copy_Email_2__c;
                    b.CS_Carbon_Copy_Email_3__c=mapAstCts.get(b.AssetId).parent.CS_Carbon_Copy_Email_3__c;
                    if (mapEnt != null && !mapEnt.isEmpty()) {
                        for(Entitlement ent: mapEnt.values()) {
                            if( mapAstCts.get(b.AssetId).id == ent.Assetid) {
                                b.entitlementid = ent.id;
                                b.businesshoursid=ent.businesshoursid;
                                
                            }
                        }
                    }
                }

                caseListToUpdate.add(b);
            }

}


     Public Static List<CaseMilestone> AutoCloseResponseTime_FirstEmail(Set<Id> setemailMessageCase,Set<Id> setemailMessage,Map<String,String> setToemailMessage){

        Map<id,Case> MapCase = New Map<id,Case>([Select id,contact.email from case where Id in:setemailMessageCase]);
        List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
            List<emailmessage> Lstemailmessage=  new List<emailmessage>([select id,toaddress,parentid,subject,Parent.contact.email from 
                                                    emailmessage where parentid in:setemailMessageCase and  id not in :setemailMessage  ]);
            system.debug('Lstemailmessage==' +Lstemailmessage);
            System.debug('Called Inside ====Response Target');

            if ((Lstemailmessage == null || Lstemailmessage.isEmpty()) && !setemailMessageCase.isEmpty()) {
                List<CaseMilestone> caseMileStoneList =  new List <CaseMilestone> ([Select Id,CaseId,Case.contact.email, CompletionDate, IsCompleted from CaseMilestone 
                                                        where CaseId in :setemailMessageCase and  MilestoneType.Name like '%Initial Response%'  and  IsCompleted=false]);

            system.debug('caseMileStoneList==' +caseMileStoneList);                         

                for (CaseMilestone cm : caseMileStoneList) {
                    system.debug('+++++++++++++++++++++++');
                    system.debug(setToemailMessage.get(cm.Case.contact.email));
                    system.debug('+++++++++++++++++++++++');    
                    cm.CompletionDate = Datetime.now();
                    caseMilestoneListToUpdate.add(cm);
                }
            
            system.debug('CMS to Update=' +caseMilestoneListToUpdate);
            }

            return  caseMilestoneListToUpdate;

     }


Public Static List<CaseMilestone> AutoCloseResponseTime(Set<Id> setemailMessageCase,Set<Id> setemailMessage,Map<String,String> setToemailMessage){
            List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
            List<emailmessage> Lstemailmessage=  new List<emailmessage>([select id,toaddress,parentid,subject,Parent.contact.email from 
                                                    emailmessage where parentid in:setemailMessageCase and  id not in :setemailMessage and 
                                                    subject like   '%Initial Response%' ]);
            system.debug('Lstemailmessage==' +Lstemailmessage);
            System.debug('Called Inside ====Response Target');

            if ((Lstemailmessage == null || Lstemailmessage.isEmpty()) && !setemailMessageCase.isEmpty()) {
                List<CaseMilestone> caseMileStoneList =  new List <CaseMilestone> ([Select Id,CaseId,Case.contact.email, CompletionDate, IsCompleted from CaseMilestone 
                                                        where CaseId in :setemailMessageCase and  MilestoneType.Name like '%Initial Response%'  and  IsCompleted=false]);

            system.debug('caseMileStoneList==' +caseMileStoneList);                         

                for (CaseMilestone cm : caseMileStoneList) {
                    system.debug('+++++++++++++++++++++++');
                    system.debug(setToemailMessage.get(cm.Case.contact.email));
                    system.debug('+++++++++++++++++++++++');    
                    cm.CompletionDate = Datetime.now();
                    caseMilestoneListToUpdate.add(cm);
                }
            
            system.debug('CMS to Update=' +caseMilestoneListToUpdate);
            }

            return  caseMilestoneListToUpdate;
     }

Public Static List<CaseMilestone> AutoClosePrelimAPTarget(Set<Id> setemailMessageCase,Set<Id> setemailMessage,Map<String,String> setToemailMessage){
            List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
            List<emailmessage> Lstemailmessage=  new List<emailmessage>([select id,toaddress,parentid,subject,Parent.contact.email from 
                                                    emailmessage where parentid in:setemailMessageCase and  id not in :setemailMessage and 
                                                    subject like   '%Preliminary Action Plan%' ]);
            system.debug('Lstemailmessage==' +Lstemailmessage);
            System.debug('Called Inside ====Prelim AP Target');

            if ((Lstemailmessage == null || Lstemailmessage.isEmpty()) && !setemailMessageCase.isEmpty()) {
                List<CaseMilestone> caseMileStoneList =  new List <CaseMilestone> ([Select Id,CaseId,Case.contact.email, CompletionDate, IsCompleted from CaseMilestone 
                                                        where CaseId in :setemailMessageCase and  MilestoneType.Name like '%Preliminary Action Plan%'
                                                         and IsCompleted=false]);

            system.debug('caseMileStoneList==' +caseMileStoneList);                         

                for (CaseMilestone cm : caseMileStoneList) {
                    system.debug('+++++++++++++++++++++++');
                    system.debug(setToemailMessage.get(cm.Case.contact.email));
                    system.debug('+++++++++++++++++++++++');    
                    cm.CompletionDate = Datetime.now();
                    caseMilestoneListToUpdate.add(cm);
                }
            
            system.debug('CMS to Update=' +caseMilestoneListToUpdate);
            }

            return  caseMilestoneListToUpdate;
     }

Public Static List<CaseMilestone> AutoClosePrelimDPTarget(Set<Id> setemailMessageCase,Set<Id> setemailMessage,Map<String,String> setToemailMessage){
            List<CaseMilestone> caseMilestoneListToUpdate = new List<CaseMilestone>();
            List<emailmessage> Lstemailmessage=  new List<emailmessage>([select id,toaddress,parentid,subject,Parent.contact.email from 
                                                    emailmessage where parentid in:setemailMessageCase and  id not in :setemailMessage and 
                                                    subject like   '%Detailed Action Plan%' ]);
            system.debug('Lstemailmessage==' +Lstemailmessage);
            System.debug('Called Inside ====Det AP Target');

            if ((Lstemailmessage == null || Lstemailmessage.isEmpty()) && !setemailMessageCase.isEmpty()) {
                List<CaseMilestone> caseMileStoneList =  new List <CaseMilestone> ([Select Id,CaseId,Case.contact.email, CompletionDate, IsCompleted from CaseMilestone 
                                                        where CaseId in :setemailMessageCase and  MilestoneType.Name like '%Detailed Action Plan%' and IsCompleted=false ]);

            system.debug('caseMileStoneList==' +caseMileStoneList);                         

                for (CaseMilestone cm : caseMileStoneList) {
                    system.debug('+++++++++++++++++++++++');
                    system.debug(setToemailMessage.get(cm.Case.contact.email));
                    system.debug('+++++++++++++++++++++++');    
                    cm.CompletionDate = Datetime.now();
                    caseMilestoneListToUpdate.add(cm);
                }
            
            system.debug('CMS to Update=' +caseMilestoneListToUpdate);
            }

            return  caseMilestoneListToUpdate;
     }

Public Static void CloseRestorationMS (Set<Id> CaseRestorationIds){

    List<CaseMilestone> lstUpdateCMS = New  List<CaseMilestone>();
    List<CaseMilestone>  CMS =New  List<CaseMilestone> ([Select id,MilestoneType.name ,iscompleted,caseid from CaseMilestone 
                                    where caseid in:CaseRestorationIds and iscompleted =false and MilestoneType.name like  '%Restoration%' ]);

    System.debug('CMS Value==' + CMS);
    If (CMS.size() >0 ){
      
        For(CaseMilestone nCms :CMS ){
             CaseMilestone newCMS= New CaseMilestone (id=nCms.id,Completiondate=System.Now());//INC0063826
             lstUpdateCMS.add(newCMS);
        }
        //System.debug('Request to Update=='+LstUpdateCSR);
        
        if (lstUpdateCMS != null && !lstUpdateCMS.isEmpty() ){
            try {
                Update lstUpdateCMS;
            } catch (DmlException ex) {
                System.debug('DmlException ' + ex.getMessage());
            }
        }
        
    }
}
}