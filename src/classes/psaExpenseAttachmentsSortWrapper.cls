/****************************************************************************************
Name            : psaExpenseAttachmentsSortWrapper
Author          : CLD Partners
Created Date    : February 5, 2016
Description     : Sorts Expense Attachments by Expense Date and then Attachment Description
Revisions       : 2/5/16  - Initial version
                : 
******************************************************************************************/
global class psaExpenseAttachmentsSortWrapper implements Comparable {
    public psaCombineExpenseReceipts.ExpenseAttachment expAttachment {get; set;}

    //Constructor
    public psaExpenseAttachmentsSortWrapper(psaCombineExpenseReceipts.ExpenseAttachment expAttachmentIn) {
        this.expAttachment = expAttachmentIn;
    }   

    // Compare Invoice Summary Lines based on the Invoice Summary Line Type.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        psaExpenseAttachmentsSortWrapper compareToExpAttachment = (psaExpenseAttachmentsSortWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (expAttachment.SortValue > compareToExpAttachment.expAttachment.SortValue) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (expAttachment.SortValue < compareToExpAttachment.expAttachment.SortValue) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}