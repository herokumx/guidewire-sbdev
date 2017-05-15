/**************************************************************************************
// Name          : psaAttachmentGroup
// Date          : May 15, 2015 
// Description   : Facilitates grouping attachments into subsets for combining into a pdf document
// Author        : CLD Partners
// Revisions     : 2015-05-12 Spano initial version
//               : 2016-02-15 Klassen Modified to support attachment sorting capability 
***************************************************************************************/
public with sharing class psaAttachmentGroup {

	private Integer size;
	private List<psaCombineExpenseReceipts.ExpenseAttachment> attachments;

	public psaAttachmentGroup() {
		attachments = new List<psaCombineExpenseReceipts.ExpenseAttachment>();
		size = 0;
	}

	public void add(psaCombineExpenseReceipts.ExpenseAttachment a){
		attachments.add(a);
		size += a.AttachmentBodyLength;
	}

	public Integer getSize(){
		return size;
	}

	public List<psaCombineExpenseReceipts.ExpenseAttachment> getAttachments(){
		return attachments;
	}
}