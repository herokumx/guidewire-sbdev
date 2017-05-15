/**************************************************************************************
// Name          	: psaCostRates
// Date          	: April 13, 2015
// Description		: Contains methods to set the Cost Rates on Resources and propagate them 
//						to Assignments
// Author        	: CLD Partners
// Revisions     	: 2015-04-08  Klassen  Initial version (copied from a prototype written by Schwartz)
//				 	: 
***************************************************************************************/
global with sharing class psaCostRates {
	/*
	public static List<pse__Assignment__c> updateAssignmentCostRates(Contact cont, List<pse__Assignments> assignments) {
		List<pse__Assignment__c> assignmentsToUpdate = new List<pse__Assignment__c>();
		for (pse__Assignment__c assignment : assignments) {
			if (cont.Id == assignment.pse__Resource__c) {
				assignment.pse__Cost_Rate_Amount__c = cont.pse__Default_Cost_Rate__c;
				//assignment.pse__Cost_Rate_Currency_Code__c = cont.
				//assignment.pse__Resource_Cost_Rate_Date__c = Date.today();
				assignmentsToUpdate.add(assignment);
			}
		}
		return assignmentsToUpdate;
	}
	*/

	public static Boolean setResourceCostRates(Contact cont, List<PSA_Cost_Rate__c> costRates) {
		Boolean costRateFound = false;
		for (PSA_Cost_Rate__c costRate : costRates) {
			if (costRate.PSA_PS_Level__c == cont.PSA_PS_Level__c &&
					costRate.PSA_Department__c == cont.PSA_Resource_Department__c &&
					costRate.PSA_Legal_Entity__c == cont.PSA_Resource_Entity__c) {
				cont.pse__Default_Cost_Rate__c = costRate.PSA_Delivery_Cost_Rate__c;
				cont.PSA_Fully_Loaded_Cost_Rate__c = costRate.PSA_Fully_Loaded_Cost_Rate__c;
				cont.PSA_Cost_Rate_Effective_Date__c = Date.today();
				costRateFound = true;
				break;
			}
		}
		if (costRateFound == false) {
			cont.pse__Default_Cost_Rate__c = 0.0;
			cont.PSA_Fully_Loaded_Cost_Rate__c = 0.0;
			cont.PSA_Cost_Rate_Effective_Date__c = Date.today();
		}
		return costRateFound;
	}

	public static List<PSA_Cost_Rate__c> loadCostRates() {
		Date dt = Date.today();
		List<PSA_Cost_Rate__c> costRates = 
			[SELECT Id, Name, CurrencyIsoCode, PSA_Delivery_Cost_Rate__c, PSA_Effective_Date__c,
					PSA_Fully_Loaded_Cost_Rate__c, PSA_Legal_Entity__c, PSA_PS_Level__c, PSA_Propagated_Date__c, 
					PSA_Department__c
				FROM PSA_Cost_Rate__c
				WHERE PSA_Effective_Date__c <= :dt
				ORDER BY PSA_Effective_Date__c Desc
			];
		return costRates;		
	}


	/*   propagateRates
     *   Purpose is to update resources' (Contacts) cost rate 
     *   and fully loaded cost rate using specific psa cost rate records
	*/
/*
	webservice static string propagateSpecificRates(List<Id> psa_Cost_Rates){

		List<Contact> contactsToUpdate = new List<Contact>();
		Datetime now = System.now();

		// Get list of PSA Cost Rates

		List<PSA_Cost_Rate__c> cost_rates =[SELECT Id, Name, 
													CurrencyIsoCode, 
													PSA_Delivery_Cost_Rate__c,
													PSA_Effective_Date__c,
													PSA_Fully_Loaded_Cost_Rate__c,
													PSA_Legal_Entity__c,
													PSA_PS_Level__c,
													PSA_Propagated_Date__c
											FROM PSA_Cost_Rate__c
											WHERE Id IN: psa_Cost_Rates];
		
		Long numOfRates = 0;

		if(cost_rates != Null && cost_rates.size() > 0){
			numOfRates = cost_rates.size();
			Long numOfContacts = 0;
			System.debug('*** Number of cost rates to propagate: ' + numOfRates);

	 		// Loop through the rates that need to be propagated...
			for(PSA_Cost_Rate__c rate : cost_rates){

				List<Contact> contactMatch = [SELECT Id,
											  PSA_Fully_Loaded_Cost_Rate__c,
											  pse__Default_Cost_Rate__c,
											  PSA_Cost_Rate_Effective_Date__c
											  FROM Contact
											  WHERE PSA_PS_Level__c =: rate.PSA_PS_Level__c
											  AND CurrencyIsoCode =: rate.CurrencyIsoCode
											  AND PSA_Resource_Entity__c =: rate.PSA_Legal_Entity__c
											  AND isdeleted = false
											  AND pse__is_resource__c = true];
				
				

				if(contactMatch != Null && contactMatch.size() > 0){
					numOfContacts = contactMatch.size();
					
					// Set the contact's delivery cost rate and fully loaded cost rate...
					for(Contact c : contactMatch){
						c.PSA_Fully_Loaded_Cost_Rate__c = rate.PSA_Fully_Loaded_Cost_Rate__c;
						c.pse__Default_Cost_Rate__c = rate.PSA_Delivery_Cost_Rate__c;
						c.PSA_Cost_Rate_Effective_Date__c = rate.PSA_Effective_Date__c;
						contactsToUpdate.add(c);
					}
				}
				//rate.PSA_Propagated_Date__c = now;
			}

			System.debug('*** Contacts eligble for cost rate changes: ' + numOfContacts);
			
			// Update all the contacts affected...
			if(numOfContacts > 0){
				update contactsToUpdate;
				System.debug('*** Contact records updated: ' + numOfContacts);
				return 'Successfully updated ' + numOfContacts + ' resources';
			}
			else{
				return 'No resources were updated (no match for update)';
			}
		}
		else{
			return 'No PSA Cost Rates selected to propagate';
		}	
	}
*/

}