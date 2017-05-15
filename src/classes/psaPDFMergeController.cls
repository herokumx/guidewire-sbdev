/**************************************************************************************
// Name          : psaPDFMergeController
// Date          : May 15, 2015 
// Description   : The Controller for the psaPDFMerge VF Page
// Author        : CLD Partners
// Revisions     : 2015-05-12 Spano initial version
//               : 2016-02-05 Klassen Added attachment sorting capability -- resource name, then expense date, then file name
//               : 2016-03-16 Klassen Added page formatting logic and Expense Name
***************************************************************************************/
global class psaPDFMergeController {
    public List<psaExpenseAttachmentsSortWrapper> expAttachWrapperList {get; set;}
    public Id lastAttachmentId {get; set;}

    /**************************************************************************************
    // Name        : psaPDFMergeController
    // Description : This controller retrieves a list of attachments and appends them to the expenseAttachments variable,
                    which is used by the VF page to create a PDF
    ***************************************************************************************/
    public psaPDFMergeController(){
        System.debug('In the constructor');
        String attachType = ApexPages.currentPage().getParameters().get('sourceType');
        String idList = ApexPages.currentPage().getParameters().get('ids');
        List<String> allIds = new List<String>();
        String[] idSplit = idList.split(',');
        for(String s : idSplit){
            allIds.add(s);
        }

        List<Attachment> attachmentList = 
            [Select Id, ParentId, ContentType, Description, Name
                From Attachment 
                Where Id in :allIds
                Order By Description
            ];
        System.debug('Expense attachments List: '+attachmentList);
        Set<Id> expenseIds = new Set<Id>();
        for (Attachment attach : attachmentList) {
            expenseIds.add(attach.ParentId);
        }

        List<pse__Expense__c> expenses = 
            [Select Id, Name, pse__Resource__r.name, pse__Type__c, pse__Expense_Date__c
                From pse__Expense__c
                Where Id = :expenseIds
                Order By pse__Expense_Date__c
            ];
        System.debug('Expenses List: ' + expenses);

        List<psaCombineExpenseReceipts.ExpenseAttachment> expenseAttachmentList = new List<psaCombineExpenseReceipts.ExpenseAttachment>();
        psaCombineExpenseReceipts.ExpenseAttachment expAttach;
        for (pse__Expense__c exp : expenses) {
            for (Attachment attach : attachmentList) {
                if (attach.ParentId == exp.Id) {
                    expAttach = new psaCombineExpenseReceipts.ExpenseAttachment(attach.Id, exp.Id, exp.pse__Expense_Date__c, attach.Name,exp.pse__Resource__r.name);
                    expAttach.AttachmentDescription = attach.Description;
                    expAttach.expType = exp.pse__Type__c;
                    expAttach.expDate = exp.pse__Expense_Date__c;
                    expAttach.resourceName = exp.pse__Resource__r.name;
                    expAttach.ExpenseName = exp.Name;
                    expenseAttachmentList.add(expAttach);
                }
            }
        }
        System.debug('Expense Attachments List: ' + expenseAttachmentList);

        expAttachWrapperList = new List<psaExpenseAttachmentsSortWrapper>();
        for (psaCombineExpenseReceipts.ExpenseAttachment expAttachment : expenseAttachmentList) {
            expAttachWrapperList.add(new psaExpenseAttachmentsSortWrapper(expAttachment));
        }
        expAttachWrapperList.sort();
        System.debug('expAttachWrapperList:' + expAttachWrapperList);
        System.debug('expAttachWrapperList size: ' + expAttachWrapperList);
        //System.debug('test:' + expAttachWrapperList[0].expAttachment.AttachmentId);

        //Add a sort id value and a boolean to indicate if this is the first attachment to each 
        // ExpenseAttachment record so only the first expense attachment
        // will display the header above it (for each expense)
        if (expAttachWrapperList != null && expAttachWrapperList.size() > 0) {
            psaCombineExpenseReceipts.ExpenseAttachment ea;
            Id previousExpenseId;
            Integer sortId;
            for (psaExpenseAttachmentsSortWrapper easw : expAttachWrapperList) {
                ea = easw.expAttachment;
                if (previousExpenseId == null || previousExpenseId != ea.ExpenseId) {
                    sortId = 1;
                }
                ea.SortId = sortId;
                if (sortId ==1) {
                    ea.FirstAttachment = true;
                } else {
                    ea.FirstAttachment = false;
                }
                previousExpenseId = ea.ExpenseId;
                sortId++;
            }
            lastAttachmentId = ea.AttachmentId;
        }
    }
}