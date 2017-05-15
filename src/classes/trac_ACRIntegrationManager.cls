/**
 * @description Set the AccountContacts Status to Pending
 * @author KJ, Traction On Demand
 * @date July 2/2015
 */

public class trac_ACRIntegrationManager {

    /****************************************************  
    *  trac_AccountACRIntegrationManager Public Method(s) 
    *****************************************************/

    public static void run (Map<Id,Account> accountOldMap, Map<Id,Account> accountNewMap) {
        Accounts qualifiedAccounts = new Accounts(accountOldMap, accountNewMap);

        if(qualifiedAccounts.Ids.size() > 0) {
            AccountContacts relatedAccountContacts = new AccountContacts();
            relatedAccountContacts.loadWhereAccountIds(qualifiedAccounts.Ids);
            relatedAccountContacts.setStatusPending();          
        }
    }   

    public static void run (Map<Id,Contact> contactOldMap, Map<Id,Contact> contactNewMap) {
        Contacts qualifiedContacts = new Contacts(contactOldMap, contactNewMap);

        if(qualifiedContacts.Ids.size() > 0) {
            AccountContacts relatedAccountContacts = new AccountContacts();
            relatedAccountContacts.loadWhereContactIds(qualifiedContacts.Ids);
            relatedAccountContacts.setStatusPending();          
        }
    }           

    /***************************************************************** Accounts Wrapper Class ****************************************************************/

    @TestVisible
    class Accounts {
        public Set<Id> Ids {get; private set;}
        private Id siteRecordTypeId;
        @TestVisible private String PENDING_APPROVAL_STATUS = 'Pending Approval';
        @TestVisible private String APPROVED_STATUS         = 'Approved';

        public Accounts(Map<Id,Account> accountOldMap, Map<Id,Account> accountNewMap) {
            siteRecordTypeId = getSiteRecordTypeId();
            this.Ids         = filter(accountOldMap, accountNewMap);            
        }

        /****************************************************  
        *  Accounts Private Method(s) 
        *****************************************************/

        private Set<Id> filter(Map<Id,Account> accountOldMap, Map<Id,Account> accountNewMap) {
            Set<Id> result = new Set<Id>();

            for(Account newAccount :accountNewMap.values()) {
                Account oldAccount = accountOldMap.get(newAccount.Id);
                if(
                    newAccount.RecordTypeId == siteRecordTypeId &&
                    (
                        oldAccount.BillingStreet              != newAccount.BillingStreet ||
                        oldAccount.BillingCity                != newAccount.BillingCity ||
                        oldAccount.BillingState               != newAccount.BillingState ||
                        oldAccount.BillingCountry             != newAccount.BillingCountry ||
                        oldAccount.BillingPostalCode          != newAccount.BillingPostalCode ||
                        oldAccount.Invoice_Delivery_Method__c != newAccount.Invoice_Delivery_Method__c ||
                        oldAccount.CurrencyIsoCode            != newAccount.CurrencyIsoCode ||
                        oldAccount.Payment_Term__c            != newAccount.Payment_Term__c 
                    )
                        
                ) {
                    result.add(newAccount.Id);
                }               
                                
                if(
                    newAccount.RecordTypeId       != siteRecordTypeId &&
                    oldAccount.Approval_Status__c == PENDING_APPROVAL_STATUS &&
                    newAccount.Approval_Status__c == APPROVED_STATUS                    
                ) {
                    result.add(newAccount.Id);
                }                               
            }
            return result;              
        }

        private Id getSiteRecordTypeId() {
           /* List<RecordType> siteRecordType = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' 
                AND DeveloperName = 'Site'
            ];*/
            
            Id recordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site').RecordTypeId;

            //if(siteRecordType.size() > 0)
            if(recordTypeId  != null)
                return recordTypeId;
            else
                throw new NoRecordTypeException('RecordType Site is not defined');
        }
    }

    /***************************************************************** Accounts Wrapper Class ****************************************************************/

    @TestVisible
    class Contacts {
        public Set<Id> Ids {get; private set;}

        public Contacts(Map<Id,Contact> contactOldMap, Map<Id,Contact> contactNewMap) {
            this.Ids = filter(contactOldMap, contactNewMap);
        }

        /****************************************************  
        *  Contacts Private Method(s) 
        *****************************************************/

        private Set<Id> filter(Map<Id,Contact> contactOldMap, Map<Id,Contact> contactNewMap) {
            Set<Id> result = new Set<Id>();

            for(Contact newContact :contactNewMap.values()) {
                Contact oldContact = contactOldMap.get(newContact.Id);
                if(
                    newContact.FirstName   != oldContact.FirstName ||
                    newContact.LastName    != oldContact.LastName ||
                    newContact.Print_As__c != oldContact.Print_As__c ||
                    newContact.Email       != oldContact.Email ||
                    newContact.Secondary_Email__c       != oldContact.Secondary_Email__c ||
                    newContact.Phone       != oldContact.Phone ||
                    newContact.OtherPhone       != oldContact.OtherPhone  
                ) {
                    result.add(newContact.Id);
                }
            }
            return result;
        }
    }

    /***************************************************************** AccountContacts Wrapper Class ****************************************************************/
    
    @TestVisible
    class AccountContacts {
        private List<Account_Contact__c> accountContacts; 
        private Map<Id,Account_Contact__c> updatedAccountContacts;

        @TestVisible private final String PENDING_STATUS = 'Pending Integration';

        public AccountContacts() {
            accountContacts        = new List<Account_Contact__c>();
            updatedAccountContacts = new Map<Id,Account_Contact__c>();
        }

        /****************************************************  
        *  AccountContacts Public Method(s) 
        *****************************************************/

        public void loadWhereAccountIds(Set<Id> ids) {
            if(ids.size() > 0) {
                accountContacts = [
                    SELECT Integration_Status__c
                    FROM Account_Contact__c
                    WHERE Account__c IN :ids
                ];
            }               
        }

        public void loadWhereContactIds(Set<Id> ids) {
            if(ids.size() > 0) {
                accountContacts = [
                    SELECT Integration_Status__c
                    FROM Account_Contact__c
                    WHERE Contact__c IN :ids
                ];
            }               
        }

        public void setStatusPending() {
            if(accountContacts.size() > 0) {
                for(Account_Contact__c anAccountContact :accountContacts) {
                    if(anAccountContact.Integration_Status__c != PENDING_STATUS) {
                        anAccountContact.Integration_Status__c = PENDING_STATUS;
                        updatedAccountContacts.put(anAccountContact.Id, anAccountContact);
                    }                   
                }
                if(updatedAccountContacts.size() > 0) {
                    update accountContacts;
                }               
            }               
        }
    }

    public class NoRecordTypeException extends Exception {}
}