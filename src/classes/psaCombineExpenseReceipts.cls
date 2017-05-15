/**************************************************************************************
// Name          : psaCombineExpenseReceipts
// Date          : September 11, 2015 
// Description   : Script to combine expense receipts and attach combined docs onto billing event
// Author        : CLD Partners
// Revisions     : 2015-09-11 Mayfield initial version
//               : 2015-09-27 Mayfield Updated to fix Heap Size bug and Future method calling Future
//						method bug
//				 : 2015-12-01 Klassen Updated to make it more generic to support both 
//					billing events and expense reports
//               : 2016-02-15 Klassen Updated to use new Expense Attachment Sorting functionality
//               : 2016-05-02 Klassen Updated to set process in progress status fields
***************************************************************************************/
public class psaCombineExpenseReceipts {
	
	public static void createCombinedExpenseDoc(Id sourceObjectId, String sourceDocType, String sessionId) {

        System.debug('\nsourceObjectId passed into createCombinedExpenseDoc: ' + sourceObjectId + 
        		' and sourceDocType: ' + sourceDocType + ' and sessionID: ' + sessionId);
        System.debug('\nAttachment: Limit of Heap Size: ' + Limits.getLimitHeapSize());

        //** FIRST, build a map of the related expenses (from Expense Report or Billing Event)
        Map<Id, pse__Expense__c> relatedExpenses;
        if (sourceDocType == 'ExpenseReport') {
        	relatedExpenses = new Map<Id, pse__Expense__c>(
        	[Select Id, pse__Expense_Date__c, pse__Expense_Report__c, pse__Resource__r.name 
        		from pse__Expense__c 
        		where pse__Expense_Report__c = :sourceObjectId
        	]);
        } else if (sourceDocType == 'BillingEvent') {
        	relatedExpenses = new Map<Id, pse__Expense__c>(
        	[Select Id, pse__Expense_Date__c, pse__Expense_Report__c,pse__Resource__r.name 
        		from pse__Expense__c 
        		where pse__Billing_Event_Item__r.pse__Billing_Event__c = :sourceObjectId ORDER BY pse__Resource__r.name
        	]);
        }
        
        //** SECOND, get a list of related attachments (there could be more than one per expense, especially if an attachment
        // was converted to an image file from a non-image file)
        //*** cklassen 3/15/16 - removed "Body" field from the soql query... serves no purpose and can cause heap size exception
        List<Attachment> attachments = 
            [Select Id,ParentId,ContentType,Description,BodyLength, Name 
                from Attachment 
                where ParentId in :relatedExpenses.keySet() 
                AND ContentType like '%image%' 
                ORDER BY Name
            ];
        System.debug('\nAttachment: Current Heap Size (after attachments list): ' + Limits.getHeapSize());

        //** THIRD, sort the list of attachments based on expense date then file name
        List<psaCombineExpenseReceipts.ExpenseAttachment> expenseAttachmentList = new List<psaCombineExpenseReceipts.ExpenseAttachment>();
        psaCombineExpenseReceipts.ExpenseAttachment expAttach;
        for (pse__Expense__c exp : relatedExpenses.values()) {
            for (Attachment attach : attachments) {
                if (attach.ParentId == exp.Id) {
                    if(sourceDocType == 'ExpenseReport'){
                        expAttach = new psaCombineExpenseReceipts.ExpenseAttachment(attach.Id, exp.Id, exp.pse__Expense_Date__c, attach.Name, 
                            exp.pse__Resource__r.name);
                        expAttach.AttachmentBodyLength = attach.BodyLength;
                        expAttach.AttachmentDescription = attach.Description;
                        expenseAttachmentList.add(expAttach);
                    }
                    else{
                        expAttach = new psaCombineExpenseReceipts.ExpenseAttachment(attach.Id, exp.Id, exp.pse__Expense_Date__c, attach.Name, 
                            exp.pse__Resource__r.name);
                        expAttach.AttachmentBodyLength = attach.BodyLength;
                        expAttach.AttachmentDescription = attach.Description;
                        expenseAttachmentList.add(expAttach);
                    }
                    
                }
            }
        }
        System.debug('Expense Attachments List: ' + expenseAttachmentList);

        List<psaExpenseAttachmentsSortWrapper> expAttachWrapperList = new List<psaExpenseAttachmentsSortWrapper>();
        for (psaCombineExpenseReceipts.ExpenseAttachment expAttachment : expenseAttachmentList) {
            expAttachWrapperList.add(new psaExpenseAttachmentsSortWrapper(expAttachment));
        }
        expAttachWrapperList.sort();
        System.debug('expAttachWrapperList:' + expAttachWrapperList);

        System.debug('Start of perform attachment');
        Integer maxSize = 30000000;
        Integer currentSize = 0;
        String attachmentIdList = '';
        List<PSA_Combined_Expense_Receipt__c> bunches = new List<PSA_Combined_Expense_Receipt__c>();
        PSA_Combined_Expense_Receipt__c receiptDoc;

        //** FOURTH, break out the attachments into "buckets", each of which has a maximum combined file size of 
        // 30MB (due to a chatterfeed SF limitation)
        List<psaAttachmentGroup> buckets = new List<psaAttachmentGroup>();
        if(expAttachWrapperList != null){
            Integer count = 0;
            for(psaExpenseAttachmentsSortWrapper a : expAttachWrapperList){
                System.debug('***** ' + a);
                if (currentSize + a.expAttachment.AttachmentBodyLength > maxSize) {
                    //reached the max so create a new combined expense receipt record
                    receiptDoc = new PSA_Combined_Expense_Receipt__c();
                    attachmentIdList = attachmentIdList.left(attachmentIdList.length()-1);
                    receiptDoc.PSA_Attachment_Ids__c = attachmentIdList;
                    System.debug('****** ' + attachmentIdList);
                    bunches.add(receiptDoc);

                    //reset variables
                    attachmentIdList = '';
                    currentSize = 0;
                }
                attachmentIdList += '\'' + a.expAttachment.AttachmentId + '\',';
                currentSize += a.expAttachment.AttachmentBodyLength;
            }

            //Add the last set of attachment ids
            receiptDoc = new PSA_Combined_Expense_Receipt__c();
            attachmentIdList = attachmentIdList.left(attachmentIdList.length()-1);
            receiptDoc.PSA_Attachment_Ids__c = attachmentIdList;
            System.debug('****** ' + attachmentIdList);
            bunches.add(receiptDoc);
        }

        List<id> bunchIds = new List<Id>();
        if(bunches.size() > 0){
            insert bunches;
            for(PSA_Combined_Expense_Receipt__c doc : bunches){
                bunchIds.add(doc.id);
            }
            System.debug('The bunches are: '+bunches);
        }
            
        //Set the Combine Receipt Progress value
        psaCombineExpenseReceipts.updateCombineReceiptProgress('Combining Attachments', sourceObjectId, 
                sourceDocType, false, false);

        //** SIXTH, call a batch job to create the combined attachments, one at a time (batch size=1).  This is done
        // to help prevent a heap size limit error
        integer BATCH_SIZE = 1;
        psaCombineExpenseReceiptsBatch combineReceiptsBatch = new psaCombineExpenseReceiptsBatch(bunchIds, 
        		sessionId, false, sourceDocType, sourceObjectId);
        //System.debug('**** psaCombineExpenseReceiptsSchedulable: starting batch exection *****************');
	    Id batchId = database.executeBatch(combineReceiptsBatch, BATCH_SIZE);    
        System.debug('**** psaCombineExpenseReceiptsSchedulable: Batch executed batchId: ' +batchId);
	}

	/**************************************************************************************
    // Name         : scheduleCombineExpenseReceipts
    // Description  : Create a scheduled job to combine any expense receipts in image format
    // Author       : CLD Partners
    // Revisions    : 2015-09-26  Mayfield  Initial version
    //              : 
    ***************************************************************************************/
    public static void scheduleCombineExpenseReceipts(Set<id> billingEventIds, String sourceObjectId, 
    		String sourceObjectType) {

        //Define the time to launch the scheduled job
        Integer xSeconds = 5;
        Datetime sysTime = System.now().addSeconds( xSeconds );
        String cronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + 
            sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();

        //Store the sessionID in case the scheduled job needs to run in that user context
        String sessionID = userInfo.getSessionId();
        system.debug('about to create scheduled job, sessionID: ' + sessionID);

        //Set the Combine Receipt Progress value
        psaCombineExpenseReceipts.updateCombineReceiptProgress('Scheduling Receipt Combine Job', 
            sourceObjectId, sourceObjectType, false, false);

        //Schedule the job
        psaCombineExpenseReceiptsSchedulable s;
        s = new psaCombineExpenseReceiptsSchedulable(sourceObjectId, sourceObjectType, sessionID); 
        System.schedule('PSA Combine Expense Receipts for 1 Time: ' + String.valueOf(Datetime.now()), cronExpression, s);
    }

	/**************************************************************************************
    // Name         : sendProcessCompleteEmail
    // Description  : Send an email notification to the user who initiated the combine receipts process
    // Author       : CLD Partners
    // Revisions    : 2015-12-07  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void sendProcessCompleteEmail(Id userId, String sourceObjectId, 
    		String sourceObjectType) {

    	//Lookup the related Contact, so we can use the "setWhatId" parameter for the email template
    	Try {
            Contact userContact = 
                [Select Id From Contact Where pse__Salesforce_User__c = :userId Limit 1];
            if (userContact != null) {
                EmailTemplate templateId;
                if (sourceObjectType == 'BillingEvent') {
                    templateId = [Select id from EmailTemplate where name = 'PSA Billing Event Receipts Combined'];
                } else if (sourceObjectType == 'ExpenseReport') {
                    templateId = [Select id from EmailTemplate where name = 'PSA Expense Report Receipts Combined'];
                }

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateID(templateId.Id);
                mail.setTargetObjectId(userContact.Id);
                mail.setWhatId(sourceObjectId);
                mail.setSaveAsActivity(false);

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
    	} Catch (Exception ex) {
                System.debug('Error attempting to send email to SF Contact');                
        }
	}

    /**************************************************************************************
    // Name         : updateCombineReceiptProgress
    // Description  : Update the Combine Receipt Progress picklist on either an Expense 
    //                  Report or Billing Event with the current stage of the process
    // Author       : CLD Partners
    // Revisions    : 2016-04-05  Klassen  Initial version
    //              : 2016-05-02  Klassen  Added additional status fields
    ***************************************************************************************/
    public static void updateCombineReceiptProgress(String progressValue, String sourceObjectId, 
            String sourceObjectType, Boolean starting, Boolean ending) {
        if (sourceObjectType == 'ExpenseReport') {
            pse__Expense_Report__c expRpt = 
                [Select Id, PSA_Combined_Receipt_Progress__c, PSA_Doc_Gen_User__c, PSA_Doc_Gen_Start__c, 
                        PSA_Doc_Gen_End__c
                    From pse__Expense_Report__c
                    Where Id =:sourceObjectId
                    Limit 1
                ];
            expRpt.PSA_Combined_Receipt_Progress__c = progressValue;
            if (starting) {
                expRpt.PSA_Doc_Gen_User__c = UserInfo.getUserId();
                expRpt.PSA_Doc_Gen_Start__c = DateTime.now();
                expRpt.PSA_Doc_Gen_End__c = null;
            }
            if (ending) {
                expRpt.PSA_Doc_Gen_End__c = DateTime.now();
            }
            update expRpt;
        } else if (sourceObjectType == 'BillingEvent') {
            pse__Billing_Event__c billingEvent = 
                [Select Id, PSA_Combined_Receipt_Progress__c, PSA_Doc_Gen_User__c, PSA_Doc_Gen_Start__c, 
                        PSA_Doc_Gen_End__c
                    From pse__Billing_Event__c
                    Where Id =:sourceObjectId
                    Limit 1
                ];
            billingEvent.PSA_Combined_Receipt_Progress__c = progressValue;
            if (starting) {
                billingEvent.PSA_Doc_Gen_User__c = UserInfo.getUserId();
                billingEvent.PSA_Doc_Gen_Start__c = DateTime.now();
                billingEvent.PSA_Doc_Gen_End__c = null;
            }
            if (ending) {
                billingEvent.PSA_Doc_Gen_End__c = DateTime.now();
            }
            update billingEvent;
        }
    }

    /**************************************************************************************
    // Name         : [CLASS] ExpenseAttachment
    // Description  : A "joined" list of Expenses with their Attachments
    // Author       : CLD Partners
    // Revisions    : 2016-02-05  Klassen  Initial version
    //              : 2016-03-10  Spano  Added Resource Name to allow additinal layer of sorting
    //              : 2016-03-16  Klassen  Added Expense Name so it can be displayed on the pdf doc
    ***************************************************************************************/
    public class ExpenseAttachment {
        public Id ExpenseId {get; set;}
        public Id AttachmentId {get; set;}
        public Date ExpenseDate {get; set;}
        public String FileName {get; set;}
        public String ResourceName {get; set;}
        public String expType {get;set;}
        public Date expDate {get;set;}
        public String AttachmentDescription {get; set;}
        public Integer AttachmentBodyLength {get; set;}
        public String SortValue {get; set;}
        public Integer SortId {get; set;}
        public Boolean FirstAttachment {get; set;}
        public String ExpenseName {get; set;}

        public ExpenseAttachment(Id attachmentIdIn, Id expenseIdIn, Date expenseDateIn, String fileNameIn, String resourceNameIn){
            AttachmentId = attachmentIdIn;
            ExpenseId = expenseIdIn;
            ExpenseDate = expenseDateIn;
            FileName = fileNameIn;
            expDate = expenseDateIn;
            ResourceName = resourceNameIn;

            //Populate the SortValue, so the psaExpenseAttachmentsSortWrapper class can sort the ExpenseAttachments 
            // in a specific way (resource name then expense date then file name)
            DateTime expenseDateTime = DateTime.newInstance(expenseDate.year(), expenseDate.month(), expenseDate.day());
            SortValue = ResourceName + '|' + expenseDateTime.format('YYYY-MM-dd') + '|'+ FileName;
        }
    }
}