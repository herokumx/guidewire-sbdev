/****************************************************************************************
Name            : psaBillingEventReleaseController
Author          : CLD Partners 
Created Date    : September 27, 2015
Description     : Controller class for the psaBillingEventRelease vf page 
Revisions       : 9/27/15 - Initial version
                : 12/7/15 - Klassen  Updated to use file conversion process before creating
                                a combined receipt pdf document
                : 3/17/16 - Klassen  Updated to use parameters expected by a batchable class
******************************************************************************************/
public without sharing class psaBillingEventReleaseController {

    private final pse__Billing_Event__c billingEvent;
    public String beURL {get; set;}
    public String beName {get; set;}

    /**************************************************************************************
    // Name         : psaBillingEventReleaseController
    // Description  : Constructor to set default variable values and retrieve any querystring
    //                  values
    // Author       : CLD Partners
    // Revisions    : 2015-09-27  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public psaBillingEventReleaseController(ApexPages.StandardController stdController) {
        this.billingEvent = (pse__Billing_Event__c)stdController.getRecord();
    }

    /**************************************************************************************
    // Name         : autoRun
    // Description  : Automatically called when the vf page loads.  Initiates the Combine 
    //                  Expense Receipts logic if applicable and then calls the PSA native
    //                  Billing Release logic
    // Author       : CLD Partners
    // Revisions    : 2015-09-27  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public PageReference autoRun() {
        pse__Billing_Event__c be = 
            [Select Id, Name, pse__Project__r.PSA_Customer_Requires_Expense_Receipts__c, 
                    PSA_CIM_Reviewed__c
                From pse__Billing_Event__c 
                Where Id = :this.billingEvent.Id
            ];
        if (be.PSA_CIM_Reviewed__c == false) {
            //display message to user that the CIM must first review the BE
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The CIM Reviewed box has not been checked.');
            Apexpages.addMessage(msg);
        } else {
            if (be.pse__Project__r.PSA_Customer_Requires_Expense_Receipts__c == true) {
                //run expense receipts combine logic -- first convert any non-image attachments into an image
                // formatted attachment so they are accessible to the PDF combined expense receipt process
                System.debug('Running expense receipts logic');
                List<pse__Expense__c> expenses;
                expenses = 
                    [Select Id, Name 
                        From pse__Expense__c
                        Where pse__Billing_Event_Item__r.pse__Billing_Event__c =: be.Id 
                        And PSA_Receipt_Attached__c = true
                        Order By pse__Resource__r.name,Name
                    ];
                if (expenses != null && expenses.size() > 0) {
                    //psaFileConvert.initiateConversion(expenses, be.Id , 'BillingEvent');
                    Set<Id> expenseIds = new Set<Id>();
                    for (pse__Expense__c expense : expenses) {
                        expenseIds.add(expense.Id);
                    }
                    psaFileConvert.initiateConversionBatch(expenseIds, be.Id, 'BillingEvent');
                }

                //display message to user that original billing event's receipts doc gen has been scheduled
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 
                    'The process to combine all expense receipts has been scheduled.');
                Apexpages.addMessage(msg); 
            } 
			  
            //run billing api release logic
            System.debug('Running billing api release logic');
            pse.APIBillingService.BillingContextRelease bc = new pse.APIBillingService.BillingContextRelease();
            bc.ids = new set<Id>{be.Id};
            bc.objectType = pse.APIBillingService.ObjectTypesRelease.Event;
            system.debug('****** psaBillingEventReleaseController - autorun - bc = '+ bc);
            pse.APICommonsService.BatchStatus bs =  pse.APIBillingService.release(bc);
            system.debug('****** psaBillingEventReleaseController - autorun - bs = '+ bs);

            //display message to user that psa billing release api has been called
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 
                'The PSA Billing Release API has been called and may take a few minutes to complete.');
            Apexpages.addMessage(msg);
        }

        beURL = getBEURL();
        beName = be.Name;

        //Redirect back to BE detail page
        PageReference pageRef = new PageReference(beURL);
        pageRef.setRedirect(true);
        return null;
    }

    /**************************************************************************************
    // Name         : getBEURL
    // Description  : Gets a direct url of a billing event 
    //                  
    // Author       : CLD Partners
    // Revisions    : 2015-09-27  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public String getBEURL() {
        String fullURL = '';
        fullURL = '/' + this.billingEvent.Id;
        return fullURL;
    }
}