/*
******************************************************************************************************************************
Controller Class Name- CS_DisplayMilestoneCtrl
Object - Case
Purpose- 
*****************************************************************************************************************************

Name            Email              Date         Notes 
Mani G                              09/03/2016       Initial Creation

*****************************************************************************************************************************
*/
public with sharing class CS_DisplayMilestoneCtrl {

	private final Entitlement mysObject;
    private list<CS_Milestone_Business_Hours__c> displayMilestone;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public CS_DisplayMilestoneCtrl(ApexPages.StandardController stdController) {
        this.mysObject = (Entitlement)stdController.getRecord();

    }
     public List<CS_Milestone_Business_Hours__c> getdisplayMilestone() {
        Entitlement SlaProcessname=[Select SlaProcess.name from entitlement where id =:mysObject.id];
        displayMilestone= New List<CS_Milestone_Business_Hours__c>([select CS_Business_Days__c, CS_Entitlement_Process_Name__c,
                                                                     CS_Exception_Email__c, CS_Milestone_Name__c, CS_Severity__c
                                                                     from CS_Milestone_Business_Hours__c  
                                                                     where CS_Entitlement_Process_Name__c =:SlaProcessname.SlaProcess.name
                                                                     order by CS_Severity__c asc ]);
        return displayMilestone;
     }
}