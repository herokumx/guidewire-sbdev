/**
 * @description Test class for trac_ACRIntegrationManager
 * @author KJ, Traction On Demand
 * @date July 2/2015
 */

@isTest
private class trac_ACRIntegrationManagerTest {

	private static trac_TestValidData testValidData = new trac_TestValidData();
	private static Id siteRecordType                = getSiteRecordTypeId();
	private static Id noSiteRecordType              = getNoSiteRecordTypeId();
    public static Id COUNTRY_ID  = setCountryId(); 
	@isTest static void test_Contacts() {
		List<Contact> contacts = createContacts(200);
		insert testValidData.getType(Contact.class).makeValid(contacts);

		//Test Contacts with same fields value
		Map<Id,Contact> oldMap = new Map<Id,Contact>(contacts.deepClone(true));
		Map<Id,Contact> newMap = new Map<Id,Contact>(contacts.deepClone(true));
		trac_ACRIntegrationManager.Contacts acrContacts = new trac_ACRIntegrationManager.Contacts(oldMap, newMap);
		// Assert that there is no qualified contacts because the criterias didn't change
		System.assertEquals(0, acrContacts.Ids.size());

		List<String> criteriaFields = new List<String>{
			'FirstName', 'LastName', 'Email','Print_As__c'
		};
		//Test Contacts with RecordType Site and criteria changed.
		for(String field :criteriaFields) {			
			acrContacts = getAcrContacts(oldMap.values().deepClone(true), newMap.values().deepClone(true), field);
			System.assertEquals(200, acrContacts.Ids.size());
		}
	}
	
	@isTest static void test_Account_SiteRecordType() {
		List<Account> accounts = createAccounts(200, true);
		insert testValidData.getType(Account.class).makeValid(accounts);

		//Test Accounts with same fields value
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts.deepClone(true));
		Map<Id,Account> newMap = new Map<Id,Account>(accounts.deepClone(true));
		trac_ACRIntegrationManager.Accounts acrAccounts = new trac_ACRIntegrationManager.Accounts(oldMap, newMap);
		// Assert that there is no qualified account because the criterias didn't change
		System.assertEquals(0, acrAccounts.Ids.size());

		List<String> criteriaFields = new List<String>{
			'BillingStreet', 'BillingCity', 'BillingState','Payment_Term__c',
			'BillingCountry', 'Invoice_Delivery_Method__c', 'CurrencyIsoCode'
		};
		//Test Accounts with RecordType Site and criteria changed.
		for(String field :criteriaFields) {			
			acrAccounts = getAcrAccounts(oldMap.values().deepClone(true), newMap.values().deepClone(true), field);
			System.assertEquals(200, acrAccounts.Ids.size());
		}
	}

	@isTest static void test_Account_NoSiteRecordType() {
		List<Account> accounts = createAccounts(200, false);
		insert testValidData.getType(Account.class).makeValid(accounts);

		//Test Accounts with same fields value
		Map<Id,Account> oldMap = new Map<Id,Account>(accounts.deepClone(true));
		Map<Id,Account> newMap = new Map<Id,Account>(accounts.deepClone(true));
		trac_ACRIntegrationManager.Accounts acrAccounts = new trac_ACRIntegrationManager.Accounts(oldMap, newMap);
		// Assert that there is no qualified account because the criterias didn't change
		System.assertEquals(0, acrAccounts.Ids.size());
		
		//Test Accounts with RecordType different than Site and criteria changed.
		for(Account anAccount :newMap.values()) {			
			anAccount.Approval_Status__c = 'Approved';
		}

		acrAccounts = new trac_ACRIntegrationManager.Accounts(oldMap, newMap);
		System.assertEquals(200, acrAccounts.Ids.size());
	}
	
	@isTest static void test_AccountContacts_LoadFromAccounts() {
		Four_Digit_Id__c autoNumberSettings1 = Four_Digit_Id__c.getOrgDefaults();
		autoNumberSettings1.Current_Value__c = 1000;
		upsert autoNumberSettings1;

		Five_Digit_Id__c autoNumberSettings2 = Five_Digit_Id__c.getOrgDefaults();
		autoNumberSettings2.Current_Value__c = 1000;
		upsert autoNumberSettings2;

		List<Account> accounts = createAccounts(1, false);
		insert testValidData.getType(Account.class).makeValid(accounts);

		List<Contact> contacts = createContacts(200);
		insert testValidData.getType(Contact.class).makeValid(contacts);

		List<Account_Contact__c> accountContacts = createAccountContacts(accounts[0], contacts);
		insert testValidData.getType(Account_Contact__c.class).makeValid(accountContacts);

		trac_ACRIntegrationManager.AccountContacts acrAccountContacts = new trac_ACRIntegrationManager.AccountContacts();
		acrAccountContacts.loadWhereAccountIds(new Set<Id>{accounts[0].Id});
		acrAccountContacts.setStatusPending();

		List<Account_Contact__c> acrAccountContactsUpdated = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :accounts[0].Id
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated) {
			System.assertEquals(anACRAccountContact.Integration_Status__c, acrAccountContacts.PENDING_STATUS);
		}
	}

	@isTest static void test_AccountContacts_LoadFromContacts() {
		Four_Digit_Id__c autoNumberSettings1 = Four_Digit_Id__c.getOrgDefaults();
		autoNumberSettings1.Current_Value__c = 1000;
		upsert autoNumberSettings1;

		Five_Digit_Id__c autoNumberSettings2 = Five_Digit_Id__c.getOrgDefaults();
		autoNumberSettings2.Current_Value__c = 1000;
		upsert autoNumberSettings2;

		List<Account> accounts = createAccounts(200, false);
		insert testValidData.getType(Account.class).makeValid(accounts);

		List<Contact> contacts = createContacts(1);
		insert testValidData.getType(Contact.class).makeValid(contacts);

		List<Account_Contact__c> accountContacts = createAccountContacts(contacts[0], accounts);
		insert testValidData.getType(Account_Contact__c.class).makeValid(accountContacts);

		trac_ACRIntegrationManager.AccountContacts acrAccountContacts = new trac_ACRIntegrationManager.AccountContacts();
		acrAccountContacts.loadWhereContactIds(new Set<Id>{contacts[0].Id});
		acrAccountContacts.setStatusPending();

		List<Account_Contact__c> acrAccountContactsUpdated = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :contacts[0].Id
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated) {
			System.assertEquals(anACRAccountContact.Integration_Status__c, acrAccountContacts.PENDING_STATUS);
		}
	}

	@isTest static void test_ACRIntegrationManager_RunOnAccounts() {
		Four_Digit_Id__c autoNumberSettings1 = Four_Digit_Id__c.getOrgDefaults();
		autoNumberSettings1.Current_Value__c = 1000;
		upsert autoNumberSettings1;

		Five_Digit_Id__c autoNumberSettings2 = Five_Digit_Id__c.getOrgDefaults();
		autoNumberSettings2.Current_Value__c = 1000;
		upsert autoNumberSettings2;

		List<Account> accounts = createAccounts(1, false);
		insert testValidData.getType(Account.class).makeValid(accounts);

		List<Contact> contacts = createContacts(200);
		insert testValidData.getType(Contact.class).makeValid(contacts);

		List<Account_Contact__c> accountContacts = createAccountContacts(accounts[0], contacts);
		insert testValidData.getType(Account_Contact__c.class).makeValid(accountContacts);

		//Test Contacts with same fields value
		update testValidData.getType(Account.class).makeValid(accounts);
		
		List<Account_Contact__c> acrAccountContactsUpdated1 = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :contacts[0].Id
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated1) {
			System.assertNotEquals(anACRAccountContact.Integration_Status__c, 'Pending Integration');
		}

		Set<Id> accountIds = new Set<Id>();

		for(Account anAccount :accounts) {
			anAccount.Approval_Status__c = 'Approved';
			anAccount.RecordTypeId       = noSiteRecordType;
			accountIds.add(anAccount.Id);
		}
		
		update testValidData.getType(Account.class).makeValid(accounts);

		List<Account_Contact__c> acrAccountContactsUpdated2 = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :accountIds
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated2) {
			System.assertEquals(anACRAccountContact.Integration_Status__c, 'Pending Integration');
		}
	}

	@isTest static void test_ACRIntegrationManager_RunOnContacts() {
		Four_Digit_Id__c autoNumberSettings1 = Four_Digit_Id__c.getOrgDefaults();
		autoNumberSettings1.Current_Value__c = 1000;
		upsert autoNumberSettings1;

		Five_Digit_Id__c autoNumberSettings2 = Five_Digit_Id__c.getOrgDefaults();
		autoNumberSettings2.Current_Value__c = 1000;
		upsert autoNumberSettings2;

		List<Account> accounts = createAccounts(200, false);
		insert testValidData.getType(Account.class).makeValid(accounts);

		List<Contact> contacts = createContacts(1);
		insert testValidData.getType(Contact.class).makeValid(contacts);

		List<Account_Contact__c> accountContacts = createAccountContacts(contacts[0], accounts);
		insert testValidData.getType(Account_Contact__c.class).makeValid(accountContacts);

		//Test Contacts with same fields value
		update testValidData.getType(Contact.class).makeValid(contacts);
		
		List<Account_Contact__c> acrAccountContactsUpdated1 = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :contacts[0].Id
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated1) {
			System.assertNotEquals(anACRAccountContact.Integration_Status__c, 'Pending Integration');
		}

		Set<Id> contactIds = new Set<Id>();
		for (Contact aContact :contacts) {
			aContact.Firstname = aContact.Firstname + 'Changed';
			contactIds.add(aContact.Id);
		}		
		update testValidData.getType(Contact.class).makeValid(contacts);
		
		List<Account_Contact__c> acrAccountContactsUpdated2 = [
			SELECT Integration_Status__c
			FROM Account_Contact__c
			WHERE Account__c = :contactIds
		];

		for(Account_Contact__c anACRAccountContact :acrAccountContactsUpdated2) {
			System.assertEquals(anACRAccountContact.Integration_Status__c, 'Pending Integration');
		}
	}


	private static List<Account_Contact__c> createAccountContacts(Account anAccount, List<Contact> contactList) {
		List<Account_Contact__c> result = new List<Account_Contact__c>();

		for(Contact aContact :contactList) {
			Account_Contact__c accountContact = new Account_Contact__c(
				Account__c             = anAccount.Id,
				Contact__c             = aContact.Id,
				Integration_Status__c  = 'Integrated',
				Participant_Account__c = anAccount.Id
			);
			result.add(accountContact);
		}
		return result;
	}

	private static List<Account_Contact__c> createAccountContacts(Contact aContact, List<Account> accountList) {
		List<Account_Contact__c> result = new List<Account_Contact__c>();

		for(Account anAccount :accountList) {
			Account_Contact__c accountContact = new Account_Contact__c(
				Account__c             = anAccount.Id,
				Contact__c             = aContact.Id,
				Integration_Status__c  = 'Integrated',
				Participant_Account__c = anAccount.Id
			);
			result.add(accountContact);
		}
		return result;
	}

	private static List<Account> createAccounts(Integer nbAccounts, Boolean isSiteRecordType) {
		List<Account> result = new List<Account>();
		for(Integer i = 0; i < nbAccounts; i++) {
			Account anAccount = new Account(
				Name                       = 'AccountName' + i,
				/*BillingStreet              = 'Street' + i,
				BillingCity                = 'Vancouver',
				BillingState               = 'British Columbia',
				BillingCountry             = 'Canada',
				BillingPostalCode          = 'A1A1A1',*/
				
				pw_cc__BillingCountryLookup__c = COUNTRY_ID,
                Billing_Zip_Postal_Code__c = '0010',
                Billing_City__c = 'test',
                Billing_Street__c ='testStreet',
				
				Invoice_Delivery_Method__c = 'E',
				CurrencyIsoCode            = 'CAD',
				Payment_Term__c            = 'Net 30',
				Approval_Status__c         = 'Pending Approval',
				Participant_id__c 		   = '' + i
			);
			if(isSiteRecordType) 
				anAccount.RecordTypeId = siteRecordType;
			else
				anAccount.RecordTypeId = noSiteRecordType;
			result.add(anAccount);
		}
		return result;
	}
    
    private static Id setCountryId(){
      
      
      pw_cc__CountryObject__c country = new pw_cc__CountryObject__c(
                                  Name = 'Test Country',
                                  pw_cc__IsoCode_2__c = 'TC',
                                  pw_cc__IsoCode_3__c = 'TC'
                                );
      insert country;                           
      return country.Id;
    }
    
	private static trac_ACRIntegrationManager.Accounts getAcrAccounts(List<Account> oldList, List<Account> newList, String fieldName) {		
		List<Account> newListReturned = new List<Account>();
		for(Account anAccount :newList) {
			anAccount = updateAccounts(anAccount, fieldName);
			newListReturned.add(anAccount);
		}
		return new trac_ACRIntegrationManager.Accounts(new Map<Id,Account>(oldList), new Map<Id,Account>(newListReturned));
	}
	
	private static Account updateAccounts(Account anAccount, String fieldName) {
		String currentFieldValue = String.valueOf(anAccount.get(fieldName));
		anAccount.put(fieldName, currentFieldValue + 'NewValue');

		return anAccount;		
	}

	private static List<Contact> createContacts(Integer nbContacts) {
		List<Contact> result = new List<Contact>();
		for(Integer i = 0; i < nbContacts; i++) {
			Contact anContact = new Contact(
				Firstname   = 'FirstName' + i,
				Lastname    = 'LastName' + i,
				Email       = 'email@email.com' + i,
				Print_As__c = 'FirstName LastName' + i
			);

			result.add(anContact);
		}
		return result;
	}

	private static trac_ACRIntegrationManager.Contacts getAcrContacts(List<Contact> oldList, List<Contact> newList, String fieldName) {		
		List<Contact> newListReturned = new List<Contact>();
		for(Contact anContact :newList) {
			anContact = updateContacts(anContact, fieldName);
			newListReturned.add(anContact);
		}
		return new trac_ACRIntegrationManager.Contacts(new Map<Id,Contact>(oldList), new Map<Id,Contact>(newListReturned));
	}
	
	private static Contact updateContacts(Contact anContact, String fieldName) {
		String currentFieldValue = String.valueOf(anContact.get(fieldName));
		anContact.put(fieldName, currentFieldValue + 'NewValue');

		return anContact;		
	}

	private static Id getSiteRecordTypeId() {
		List<RecordType> result = [
			SELECT Id 
			FROM RecordType 
			WHERE SObjectType = 'Account' 
			AND DeveloperName = 'Site'
		];

		return result[0].Id;
	}

	private static Id getNoSiteRecordTypeId() {
		List<RecordType> result = [
			SELECT Id 
			FROM RecordType 
			WHERE SObjectType = 'Account' 
			AND DeveloperName != 'Site'
		];

		return result[0].Id;
	}

}