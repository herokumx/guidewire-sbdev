/****************************************************************************************
Name            : psaProjectBillingRulesController
Author          : CLD Partners
Created Date    : March 3, 2015
Description     : Controller class for the psaProjectBillingRules vf page 
Revisions       : 3/3/15 - Initial version
******************************************************************************************/
public with sharing class psaProjectBillingRulesController {

    private final pse__Proj__c proj;
    public List<AssignmentExtension> assignments {get; set; }

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public psaProjectBillingRulesController(ApexPages.StandardController stdController) {
        this.proj = (pse__Proj__c)stdController.getRecord();
        if (Apexpages.currentPage().getParameters().get('saved') != null && Apexpages.currentPage().getParameters().get('saved') == 'y') {
            String msgText = 'The Billing Rules changes have been saved.';
            ApexPages.Message statusMessage = new ApexPages.Message(ApexPages.Severity.Info, msgText);
            Apexpages.addMessage(statusMessage);
        } else if (Apexpages.currentPage().getParameters().get('exec') != null && Apexpages.currentPage().getParameters().get('exec') == 'y') {
            String msgText = 'The Billing Rules have been applied.';
            ApexPages.Message statusMessage = new ApexPages.Message(ApexPages.Severity.Info, msgText);
            Apexpages.addMessage(statusMessage);
        }
        if (assignments == null) {
            getLTAAssignments();
        }
    }

    private void getLTAAssignments() {
        AssignmentExtension assignmentController = new AssignmentExtension();
        assignments = assignmentController.buildAssignmentExtensions(
            [Select Id, Name, pse__Resource__r.Name, PSA_LTA_Start_Date__c, PSA_LTA_Billable__c
                From pse__Assignment__c
                Where pse__Project__c = :proj.Id
                And PSA_LTA_Eligible__c = true
                Order By pse__Resource__r.Name
            ]
        );
    }

    public PageReference saveAndReturn(){
        //Use try/catch block to gracefully handle/display validation error messages
        try {
            update proj;
            PageReference pg = new PageReference('/' + proj.id);
            pg.setRedirect(true);
            return pg;
        } catch(DmlException e) {
            ApexPages.Message statusMessage = new ApexPages.Message(ApexPages.Severity.Error, e.getdmlMessage(0));
            Apexpages.addMessage(statusMessage);
            return null;        
        }
    }

    public void save() {
        //Use try/catch block to gracefully handle/display validation error messages
        boolean success = true;
        try {
            update proj;
        } catch(Exception e) {
            ApexPages.Message statusMessage = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            Apexpages.addMessage(statusMessage);        
            success = false;
        }
        if(success){
            ApexPages.Message successMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'Project Saved');
            Apexpages.addMessage(successMessage);    
        }
            
    }

//    public PageReference cancel() { 
//        PageReference pgRef = new ApexPages.PageReference('/'+proj.Id);
//        return pgRef;
//    }

    public PageReference applyBillingRules() {
        psaBillingRulesApplication billingRulesApp = new psaBillingRulesApplication();        
        billingRulesApp.launchBillingRules(new Set<Id>{proj.Id}, null, null);

        //PageReference pg = new PageReference(System.currentPageReference().getURL());
        PageReference pg = Page.psaProjectBillingRules;
        pg.getParameters().put('Id', proj.Id);
        pg.getParameters().put('exec', 'y');
        pg.setRedirect(true);
        return pg;
        //return null;
    }

    public class AssignmentExtension {
        public Id AssignmentId {get; set; }
        public String AssignmentName {get; set; }
        public String ResourceName {get; set; }
        public String LTAStartDate {get; set; }
        public Boolean LTAIsBillable {get; set; }
        public String LTAIsBillableChecked {get; set; }

        public AssignmentExtension() {}

        public List<AssignmentExtension> buildAssignmentExtensions (List<pse__Assignment__c> assignments) {
            List<AssignmentExtension> assignmentsExtensionList = new List<AssignmentExtension>();
            AssignmentExtension assignmentExtension;
            if (assignments != null && assignments.size() > 0) {
                for (pse__Assignment__c assignment : assignments) {
                    assignmentExtension = new AssignmentExtension();
                    assignmentExtension.AssignmentId = assignment.Id;
                    assignmentExtension.AssignmentName = assignment.Name;
                    assignmentExtension.ResourceName = assignment.pse__Resource__r.Name;
                    assignmentExtension.LTAStartDate = formatDateValue(assignment.PSA_LTA_Start_Date__c);
                    assignmentExtension.LTAIsBillable = assignment.PSA_LTA_Billable__c;
                    if (assignment.PSA_LTA_Billable__c) {
                        assignmentExtension.LTAIsBillableChecked = ' checked';
                    } else {
                        assignmentExtension.LTAIsBillableChecked = '';
                    }
                    assignmentsExtensionList.add(assignmentExtension);
                }
            }
            return assignmentsExtensionList;
        }

        private String formatDateValue(Date dateValue) {
            return String.valueOf(dateValue.month()) + '/' + String.valueOf(dateValue.day()) + '/' + String.valueOf(dateValue.year());
        }
    }
}