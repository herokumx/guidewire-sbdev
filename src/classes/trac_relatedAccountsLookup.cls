/**
 * @description 
 *
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */

public with sharing class trac_relatedAccountsLookup {

	public List<relatedListCls> relatedList {get; set;}

	public trac_relatedAccountsLookup(ApexPages.StandardController controller) {

		String accId = ApexPages.CurrentPage().getParameters().get('Id');
		Map<Id, Account_Contact__c> relatedACR = new Map<Id, Account_Contact__c>([SELECT Account__c, Contact_Name__c, Contact__c, Contact_Type__c FROM Account_Contact__c WHERE Account__c = :accId]);

		System.debug('relatedACR::'+relatedACR);

		Set<Id> contactIds = new Set<Id>();
		if(!relatedACR.isEmpty()){
			for ( Account_Contact__c acr : relatedACR.values() ){
				contactIds.add(acr.Contact__c);
			}
		}

		Map<Id, Contact> relatedContacts = new Map<Id, Contact>([SELECT Name, MailingAddress FROM Contact WHERE Id IN :contactIds]);
		
		System.debug('relatedContacts::'+relatedContacts);

		relatedList = new List<relatedListCls>();

		if(!relatedACR.isEmpty()){
			for ( Account_Contact__c acr : relatedACR.values() ){
				relatedList.add(new relatedListCls(acr, relatedContacts.get(acr.Contact__c) ));
			}
		}	
		System.debug('relatedList::'+relatedList);


	}

	//Wrapper Class
	class relatedListCls{
		public String name {get; private set;}
		public Address address {get; private set;}
		public String city {get; private set;}
		public String country {get; private set;}
		public String state {get; private set;}
		public String street {get; private set;}
		public String type {get; private set;}

		public relatedListCls(Account_Contact__c accountContact, Contact cont){
			name = accountContact.Contact_Name__c;
			address = cont.MailingAddress;
			if (address != null ){
				city = cont.MailingAddress.getCity() != null ? cont.MailingAddress.getCity(): '';
				country = cont.MailingAddress.getCountry() != null ? cont.MailingAddress.getCountry(): '';
				state = cont.MailingAddress.getState() != null ? cont.MailingAddress.getState(): '';
				street = cont.MailingAddress.getStreet() != null ? cont.MailingAddress.getStreet(): '';
			}

			type = accountContact.Contact_Type__c;
		}

	}
}