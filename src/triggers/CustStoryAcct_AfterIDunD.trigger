/************
Trigger: Customer Story Account after insert/delete/undelete
Description: we want to summarize all the accounts linked to each story; after adding or deleting story links, send the story to a utility method
    to summarize it.
    
Created: April 19/14, Vankerk Solutions
Modification Log

************/
trigger CustStoryAcct_AfterIDunD on Customer_Story_Account__c (after insert, after delete, after undelete) {
    Set<Id> CustStoryIds = new set<Id>();
    // cycle through cust story acct and pull in cust story ID for summarizing
    for (Customer_Story_Account__c csa : (trigger.isdelete ? trigger.old : trigger.new) ) {
        CustStoryIds.add(csa.customer_story__c);
    }
    // send stories to utility to summarize
    GWUtilities.SummaryCustomerStoryAccounts(CustStoryIds);
}