/*********************************************************************************************** x
Name            : psaExpenseAttachmentManagementController
Author          : CLD
Created Date    : Oct 2015
Revision History:

Usage           : Controller for the psaExpenseAttachmentManagement page.
                :
***********************************************************************************************/
public class psaExpenseAttachmentManagementController
{

    // - expense report displayed
    public pse__Expense_Report__c userExpenseReport {get; set;}

    // user expense items
    public ExpenseLine[] userExpenseLines {get; set;}

    public boolean hasPageError {get; set;}
    public String pageErrorMessage {get; set;}

    // ----------------------------------------------------
    // - constructor : standard controller extension
    // ----------------------------------------------------
    public psaExpenseAttachmentManagementController(ApexPages.StandardController stdController)
    {
        // expense report by id
        String expRptId = ApexPages.currentPage().getParameters().get('id');

        // verify an expense report by id was passed
        hasPageError = false;
        if(String.isEmpty(expRptId)) {
          hasPageError = true;
          pageErrorMessage = 'Error loading page, missing required expense report id.';
        }
        else {
          lookupExpenseReport(expRptId);
          lookupExpensesWithAttachments(expRptId);
        }
    }

    // ----------------------------------------------------
    // Fetch expense report by id!
    // ----------------------------------------------------
    private void lookupExpenseReport(String expReportId)
    {
        if (String.isNotEmpty(expReportId))
        {
            // lookup
            userExpenseReport = [
                select Id,
                       Name,
                       pse__Resource__r.Name,
                       pse__Project__c,
                       pse__Project__r.Name,
                       pse__Project__r.PSA_Customer_Requires_Expense_Receipts__c,
                       pse__First_Expense_Date__c,
                       pse__Status__c,
                       pse__Description__c
                  from pse__Expense_Report__c
                 where id = :expReportId
            ];
        }
    }

    // ----------------------------------------------------
    // Fetch expenses with optional attachments by expense report id!
    // ----------------------------------------------------
    private void lookupExpensesWithAttachments(String expReportId)
    {
        userExpenseLines = new ExpenseLine[]{};
        if (expReportId != null)
        {
            for (pse__Expense__c exp : [
                 select Id,
                        Name,
                        pse__Expense_Date__c,
                        pse__Amount__c,
                        pse__Billable__c,
                        pse__Description__c,
                        pse__Expense_Report__c,
                        pse__Type__c,
                        ( SELECT Id,
                                 Name,
                                 BodyLength,
                                 ParentId
                            FROM Attachments )
                   from pse__Expense__c
                  where pse__Expense_Report__c = :expReportId])
            {
                userExpenseLines.add(new ExpenseLine(exp));
            }
        }
    }

    public class ExpenseLine
    {
        public pse__Expense__c expense {get; set;}
        public Attachment[] attachments {get; set;}
        public boolean hasAttachments {get; set;}

        public ExpenseLine(pse__Expense__c e)
        {
            this.expense = e;
            this.attachments= (e != null && e.attachments != null) ? e.attachments : new Attachment[]{};

            this.hasAttachments = attachments != null && attachments.size() > 0;

        }
    }

}