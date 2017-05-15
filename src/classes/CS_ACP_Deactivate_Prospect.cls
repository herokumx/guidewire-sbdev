/*
******************************************************************************************************************************
Controller Class Name- CS_ACP_Deactivate_Prospect
Object - CS_Asset_Contact_Permissions__c
Purpose- Trigger Handler 
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com      			 Initial Creation

*****************************************************************************************************************************
*/
global class CS_ACP_Deactivate_Prospect implements Schedulable {
	global void execute(SchedulableContext sc) {
		//MyBatchClass b = new MyBatchClass();
		//database.executebatch(b);(
				deactivateProspect();
				deactivate_ACP();

	}
	List<CS_Asset_Contact_Permissions__c> newACP=New List<CS_Asset_Contact_Permissions__c>();

	 public void deactivateProspect()
	 {

	 		List<CS_Asset_Contact_Permissions__c> AcpUpdate= New List<CS_Asset_Contact_Permissions__c>(
	 		[Select id,CS_IsActive__c,CS_Access_Type__c,CS_Evaluation_End_Date__c from CS_Asset_Contact_Permissions__c 
	 		 where CS_Access_Type__c='Prospect' and  CS_Evaluation_End_Date__c=Today]);


	 		for(CS_Asset_Contact_Permissions__c acp: AcpUpdate){
				CS_Asset_Contact_Permissions__c  updACP= new CS_Asset_Contact_Permissions__c(Id=acp.id,CS_IsActive__c=False);
				newACP.add(updACP);

		}

		Update newACP;

	 }

// Deactivate ACPS on Asset  based on Asset out of service date 
	 public void deactivate_ACP()
	 {

	 		List<CS_Asset_Contact_Permissions__c> AcpUpdate= New List<CS_Asset_Contact_Permissions__c>(
	 		[Select id,CS_IsActive__c,CS_Access_Type__c,CS_Evaluation_End_Date__c from CS_Asset_Contact_Permissions__c 
	 		 where   CS_Asset__r.UsageEndDate=Today]);


	 		for(CS_Asset_Contact_Permissions__c acp: AcpUpdate){
				CS_Asset_Contact_Permissions__c  updACP= new CS_Asset_Contact_Permissions__c(Id=acp.id,CS_IsActive__c=False);
				newACP.add(updACP);

		}

		Update newACP;

	 }
}