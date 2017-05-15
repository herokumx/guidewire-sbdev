/**************************************************************************************
// Name          : psaPDFGenerationUtil
// Date          : May 15, 2015 
// Description   : Utility class including a Rest call and an HTTP callout which help generate combined attachment PDFs
// Author        : CLD Partners
// Revisions     : 2015-05-12 Spano initial version
//               : 2015-10-22 Klassen Updated to fix bug with SF critical update regardinging
//                  treating get content as pdf as a callout
//               : 2015-12-01 Klassen Updated to support multiple types of source objects --
//                  such as billing events and expense reports
//               : 2016-03-15 Klassen Re-wrote logic to be based on a single combined expense receipt document
//               : 2016-05-02  Klassen  Added logic to set the status of the combine receipts process
***************************************************************************************/
@RestResource(urlMapping='/createexpensepdf/*')
global class psaPDFGenerationUtil {

    /**************************************************************************************
    // Name         : doWork
    // Description  : Send an email notification to the user who initiated the combine receipts process
    // Author       : CLD Partners
    // Revisions    : 2015-07-01  Spano  Initial version
    //              : 2015-12-04  Klassen  Updated to be more generic and include a combined
    //                  expense receipt document for both Expense Reports and Billing Events
    //              : 2016-05-02  Klassen  Added logic to set the status of the combine receipts process
    //                  and removed old code
    ***************************************************************************************/
    public static void doWork(List<Id> objectIds, String sourceObjectType, String sourceObjectId, 
            Integer currentFileNumber, Integer totalFileCount) {
        System.debug('EEEE Got in to the doWork method - variables--objectIds:' + objectIds + ', sourceObjectType:' + 
                sourceObjectType + ', sourceObjectId:' + sourceObjectId + ', currentFileNumber:' + currentFileNumber);
        /*First obtain the groups of Ids that will be attached*/
        //List<List<String>> idGroups = getIdGroups(objectIds, sourceObjectType);
        Set<Id> attachmentIds = getIdGroups(objectIds, sourceObjectType);
        System.debug('Attachment Ids: ' + attachmentIds);
        //System.debug('Id groups: '+idGroups);
        List<Attachment> toInsert = new List<Attachment>();
        List<feeditem> feeditems = new list<feeditem>();
        //For each list of ids, find the associated billing event name or expense report name, find the attachments with those ids, 
        // and attach the combined list of attachments to the source object (either expense report or billing event)
        Integer count = 1;
        String sourceObjectName = '';
        String contentFileName;

        //Originally, multiple object Ids could be passed in, but the batch process now only includes one record at a time
        //for(List<String> nextList : idGroups){

            List<attachment> attach = 
                [SELECT Id,ParentId,ContentType,Body,Description,BodyLength 
                    from Attachment 
                    where ID in :attachmentIds
                ];
            System.debug('EEEE THe list of attachments is: '+attach);
            if(attach != null && attach.size() > 0){
                Attachment example = attach.get(0);
                //Obtain the expense report name and the billing event Name from the related expense
                List<pse__Expense__c> expNames = 
                    [Select pse__Expense_Report__r.Name,pse__Expense_Date__c,pse__Expense_Report__r.pse__Resource__r.name,pse__Project__R.name, pse__billing_event_item__r.pse__billing_event__r.name 
                        from pse__Expense__c 
                        where id = :example.parentId 
                        limit 1
                    ];
                System.debug('Expenses: '+expNames);
                
                //If there is no associated expense report or billing event, stop trying to execute
                if(expNames == null || expNames.size() == 0){
                    return;
                } else {
                    if (sourceObjectType == 'BillingEvent') {
                        sourceObjectName = expNames[0].pse__billing_event_item__r.pse__billing_event__r.name;
                    } else if (sourceObjectType == 'ExpenseReport') {
                        sourceObjectName = expNames[0].pse__Expense_Report__r.Name;
                    }
                }
                //Set the content file name variable
                if(sourceObjectType == 'ExpenseReport'){
                    Date expenseDate = expNames[0].pse__Expense_Date__c;
                    Datetime eDT = Datetime.newInstance(expenseDate.Year(), expenseDate.month(), expenseDate.day());
                    String myDate = eDT.format('MM/dd/yyyy');
                    myDate = myDate.replace('/', '|');
                    System.debug('Exp Rpt Resource: '+expNames[0].pse__Expense_Report__r.pse__Resource__r.name);
                    contentFileName = expNames[0].pse__Expense_Report__r.pse__Resource__r.name+'_'+myDate+'_'+expNames[0].pse__Project__r.name+'.pdf';
                }
                else{
                    System.debug('Content File Name Parts-currentFileNumber:' + currentFileNumber + ',totalFileCount:' + totalFileCount + ',sourceObjectName:' + sourceObjectName);                    
                    contentFileName = 'Receipt '+currentFileNumber+' of '+totalFileCount + ' '+sourceObjectName+'.pdf';
                    System.debug('Content File Name: ' + contentFileName);
                }
                

                String attachIds = '';
                Integer c = 0;
                for(Attachment a : attach){
                    attachIds += a.id;
                    if(c < attach.size() - 1){
                        attachIds += ',';
                    }
                }

                //Load the vf page that combines all expense receipts into a single PDF file
                PageReference pdf = Page.psaPDFMerge;
                pdf.getParameters().put('ids',attachIds);
                
                Blob body;
                if(!test.isRunningTest()){
                    body = pdf.getContent();
                }else{
                    body=blob.valueOf('test content');
                }
                System.debug('The body is size: '+body);
                System.debug('The source object id is: '+sourceObjectId);

                //Insert the chatter feed item based on the PDF file that was created by the VF page just above
                FeedItem post = new FeedItem();
                post.ParentId = sourceObjectId;
                post.Type = 'ContentPost';
                post.ContentData =body;
                post.ContentFileName = contentFileName; 
                feedItems.add(post);
                count++;
            }
        //}
        insert feedItems;

        contentFileName = contentFileName.replace('.pdf', '');
        //Create the PSA Combined Expense Receipt Doc objects based on links
        List<PSA_Combined_Expense_Receipt__c> combinedExpReceipts = new List<PSA_Combined_Expense_Receipt__c>();
        //read the contentdocumentlink which has the chatter feed attachment
        list<ContentDocumentLink> Files = 
            [SELECT ContentDocument.title, ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :sourceObjectId
                AND ContentDocument.title = :contentFileName
                ORDER BY ContentDocument.title
            ];
        
        //Loop through the Files object and create new PSA Combined Expense Receipt records with the link to the files
        // There should only be one File in the list
        for(ContentDocumentLink file: Files) {
            PSA_Combined_Expense_Receipt__c combinedExpReceipt = new PSA_Combined_Expense_Receipt__c();
            String shortName = 'URL Link - '+file.ContentDocument.title;
            if (shortName.length() > 78) {
                shortName = shortName.left(78) + '..';
            } 
            combinedExpReceipt.Name = shortName;
            if (sourceObjectType == 'BillingEvent') {
                combinedExpReceipt.PSA_Billing_Event__c = file.linkedEntityId;
            } else if (sourceObjectType == 'ExpenseReport') {
                combinedExpReceipt.PSA_Expense_Report__c = file.linkedEntityId;
            }
            combinedExpReceipt.PSA_Combined_Receipt_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + file.ContentDocumentId;
            combinedExpReceipt.PSA_Source_Object_Id__c = sourceObjectId;
            combinedExpReceipt.PSA_Long_Name__c = 'URL Link - '+file.ContentDocument.title;
            combinedExpReceipts.add(combinedExpReceipt);
        } 
        if(combinedExpReceipts != null && combinedExpReceipts.size() > 0) {
            insert combinedExpReceipts;
        }

        if (sourceObjectType == 'BillingEvent') {
            //Create the PSA Billing Event Expense Receipt Doc objects based on links
            List<PSA_Billing_Event_Expense_Receipt_Docs__c> links = new List<PSA_Billing_Event_Expense_Receipt_Docs__c>();
            //read the contentdocumentlink which has the chatter feed attachment
            // There should only be one File in the list
            Files = 
                [SELECT ContentDocument.title, ContentDocumentId, LinkedEntityId 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :sourceObjectId
                    AND ContentDocument.title = :contentFileName
                    ORDER BY ContentDocument.title
                ];
            
            for(ContentDocumentLink file: Files) {
                PSA_Billing_Event_Expense_Receipt_Docs__c docPkg = new PSA_Billing_Event_Expense_Receipt_Docs__c();
                docPkg.Name = 'URL Link - '+file.ContentDocument.title;
                docPkg.PSA_Billing_Event__c = file.linkedEntityId;
                docPkg.PSA_Expense_Receipt_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + file.ContentDocumentId;
                links.add(docPkg);
            } 

            if(links != null && links.size() > 0) {
                insert links;
            }
        }

        //Send email notification 
        if(sourceObjectType=='ExpenseReport'){
            psaCombineExpenseReceipts.sendProcessCompleteEmail(UserInfo.getUserId(), sourceObjectId, sourceObjectType);
        }
        
        if (currentFileNumber == totalFileCount) {
            //Set the Combine Receipt Progress value
            psaCombineExpenseReceipts.updateCombineReceiptProgress('Complete', sourceObjectId, sourceObjectType, false, true);
        }
    }

    global static Set<Id> getIdGroups(List<Id> objectIds, String sourceObjectType) {
        Set<Id> attachmentIdSet = new Set<Id>();

        List<PSA_Combined_Expense_Receipt__c> docs = [Select id,PSA_Attachment_Ids__c from PSA_Combined_Expense_Receipt__c where Id in:objectIds];
        System.debug('Combined Docs is: '+docs);

        List<Id> idsToDelete = new List<Id>();
        if(docs != null && docs.size() > 0){
            for(PSA_Combined_Expense_Receipt__c doc : docs){
                String idList = doc.PSA_Attachment_Ids__c;
                idsToDelete.add(doc.id);
                String[] separate = idList.split(',');
                for(String s : separate){
                    s = s.replace('\'', '');                    
                    attachmentIdSet.add(s);
                }
            }
            //Delete the expense receipt docs since they are no longer needed
            System.debug('Deleting docs');

        }

        List<PSA_Combined_Expense_Receipt__c> toRemove = [Select id from PSA_Combined_Expense_Receipt__c where id in :idsToDelete];
        delete toRemove;

        return attachmentIdSet;
    }
}