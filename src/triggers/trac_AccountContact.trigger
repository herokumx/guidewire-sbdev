/**
 * @description Generates a 5 digit Auto Number for the Contact_Name__c field
 *
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */

trigger trac_AccountContact on Account_Contact__c (before insert, before update) {

    //if( trac_DisableTriggerUsingCustomSetting.isAccountContactTriggerDisabled() ){
    //    System.debug('trac_AccountContact trigger is disabled.');
    //    return;
    //}
    //else{
    //    System.debug('trac_AccountContact trigger is enabled.');
    //}

    if( trigger.isBefore && trigger.isInsert || trigger.isBefore && trigger.isUpdate){
        List <Account_Contact__c> filteredContacts = new List<Account_Contact__c>();

        // Filter out all contacts except those that have contact keys and an integration status of 'Pending Integration'
        for (Account_Contact__c a : Trigger.new) {
            if(a.Contact_Key__c == null && a.Integration_Status__c == 'Pending Integration') {
                filteredContacts.add(a);
            }
        }

        // Set the contact_key__c fields to unique values
        trac_GenerateAutoNumber.setAccountContactKeys(filteredContacts);

        for (Account_Contact__c a: filteredContacts) {
            System.debug('a.Contact_Name__c:1:'+a.Contact_Name__c);

            //append the contact key id to the contact and account contact name 
            if ( a.Contact_Name__c != NULL && !a.Contact_Name__c.contains(a.Contact_Key__c) ){
                System.debug('a.Contact_Name__c:2:'+a.Contact_Name__c);
                a.Contact_Name__c = a.Contact_Key__c + a.Contact_Name__c;
            }
        }           
    }
}