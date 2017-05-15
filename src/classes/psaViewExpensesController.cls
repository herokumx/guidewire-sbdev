/****************************************************************************************
Name            : psaViewExpensesController
Author          : CLD Partners 
Created Date    : February 17, 2016 
Description     : Controller for psaViewExpenses vf page (used as in-line vf page on Expense Report) 
                    
Revisions       : 2/17/16 - Initial version 
                : 
******************************************************************************************/
public with sharing class psaViewExpensesController {

    private ApexPages.StandardController controller {get; set;}
    public pse__Expense_Report__c er {get;set;}
    public List<pse__Expense__c> expenses {get;set;}
    public List<String> labels {get;set;}
    public Map<Id, List<AttachmentLink>> expenseToURLs {get;set;}
    
    public psaViewExpensesController(ApexPages.StandardController controller) {
        this.er = (pse__Expense_Report__c)controller.getRecord();
        expenses = 
            [Select Id, PSA_Incurred_Country__r.Name,pse__Description__c, pse__Incurred_Tax__c, PSA_Receipt_Attached__c, GW_Card_Reimbursement_Amount__c, 
                    pse__Non_Billable_Amount__c, pse__Reimbursement_Amount__c, pse__Billable__C, pse__Expense_Date__c,
                    pse__Type__c,currencyISOcode, name, pse__Amount__c, PSA_Receipt_Type__c, PSA_VAT_Reclaimable__c, PSA_Incurred_Country__c
                from pse__Expense__c 
                where pse__Expense_Report__c = :er.id
                order by pse__Expense_Date__c, pse__Type__c, Name
            ];
        Set<Id> expenseIDs = new Set<Id>();
        expenseToURLs = new Map<Id, List<AttachmentLink>>();
        for(pse__Expense__c exp : expenses){
            expenseIds.add(exp.id);
            expenseToURLS.put(exp.id, new List<AttachmentLink>());
        }
       
        List<Attachment> attached = [Select Id,Name,ParentId from Attachment where parentID in :expenseIds order by Name];
        for(Attachment a : attached){
            List<AttachmentLink> attachs = expenseToURLs.get(a.parentId);
            if(attachs == null){
                attachs = new List<AttachmentLink>();
            }
            String urlToAdd = System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+a.id;
            String fileName = a.name;
            AttachmentLink al = new AttachmentLink(a.Id, urlToAdd, fileName);
            attachs.add(al);
            expenseToUrls.put(a.parentId, attachs);
        }
        
        System.debug('Expense to urls: '+expenseToUrls);
    }
    
    public class attachmentLink{
        public Id attachmentId {get; set;}
        public String attachmentURL {get;set;}
        public String attachmentFileName {get;set;}
        
        public AttachmentLink(Id attId, String attUrl, String fileName){
            this.attachmentId = attId;
            this.attachmentURL = attURL;
            this.attachmentfileName = fileName;
        }
    }
}