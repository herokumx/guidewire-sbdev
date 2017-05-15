/*
******************************************************************************************************************************
Controller Class Name- CS_Caseclose_Util
Object - Case
Purpose- Util  Class   for Case Close  Component
*****************************************************************************************************************************

Name     Email              Date         Notes 
ManiG  manig@slalom.com                	Initial Creation
ManiG manig@slalom.com 		09/14/2016	Try Catch Block
*****************************************************************************************************************************
*/
public with sharing class CS_Caseclose_Util {


	Public Static void CloseSTR(Set<Id> CaseIds){
	System.debug('Cases Sent to Close===' + CaseIds);
	 List <CS_Request__c> LstUpdateCSR = New  List<CS_Request__c>();
	 List<CS_Request__c>  CSR= New  List<CS_Request__c> ([Select id,CS_is_Active__c,CS_Request_Type__c,
	 								                      CS_Case__c from  CS_Request__c where 
	 								                      CS_Case__c in:CaseIds and CS_Request_Status__c !='Answered'
	 								                      and  CS_Request_Type__c !='Long Term Request']);
	 //System.debug('Request to Update'+CSR);
	 If (CSR.size() >0 ){
	 	For(CS_Request__c nCsr :CSR ){
	 		 CS_Request__c newCSR= New CS_Request__c (id=nCsr.id,CS_Request_Status__c='Answered');
	 		 LstUpdateCSR.add(newCSR);
	 	}
	 	//System.debug('Request to Update=='+LstUpdateCSR);
	 	
	 	try {
            Update LstUpdateCSR;
        } catch (DmlException ex) {
            CS_ExceptionHandler.createErrorRecordMessage(ex.getMessage(), 'CloseSTR'); 
        }
	 	
	 }
	}

	Public Static void CloseCMS (Set<Id> CaseIds){

	List<CaseMilestone> lstUpdateCMS = New  List<CaseMilestone>();
	List<CaseMilestone>  CMS =New  List<CaseMilestone> ([Select id,iscompleted,caseid from CaseMilestone where caseid in:CaseIds and iscompleted =false]);


	If (CMS.size() >0 ){
	 	For(CaseMilestone nCms :CMS ){
	 		 CaseMilestone newCMS= New CaseMilestone (id=nCms.id,Completiondate=system.today());
	 		 lstUpdateCMS.add(newCMS);
	 	}
	 	//System.debug('Request to Update=='+LstUpdateCSR);
	 	try {
            Update lstUpdateCMS;
        } catch (DmlException ex) {
            CS_ExceptionHandler.createErrorRecordMessage(ex.getMessage(), 'CloseCMS'); 
        }
	 	
	 }


	}

	Public Static void CloseRestorationMS (Set<Id> CaseIds){
	
	List<CaseMilestone> lstUpdateCMS = New  List<CaseMilestone>();
	List<CaseMilestone>  CMS =New  List<CaseMilestone> ([Select id,MilestoneType.name ,iscompleted,caseid from CaseMilestone 
									where caseid in:CaseIds and iscompleted =false and MilestoneType.name like  '%Restoration%' ]);

	System.debug('CMS Value==' + CMS);
	If (CMS.size() >0 ){
	 	For(CaseMilestone nCms :CMS ){
	 		 CaseMilestone newCMS= New CaseMilestone (id=nCms.id,Completiondate=system.now());
	 		 lstUpdateCMS.add(newCMS);
            System.debug('=====lstUpdateCMS ==== ' + lstUpdateCMS);
	 	}
	 	System.debug('Request to Update=='+lstUpdateCMS);
        try {
            Update lstUpdateCMS;
        } catch (DmlException ex) {
            CS_ExceptionHandler.createErrorRecordMessage(ex.getMessage(), 'CloseRestorationMS'); 
        }
	 	
	}
}

}