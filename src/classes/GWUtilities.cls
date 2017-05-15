/*************
Class: GW Utilities
Description: Collection of classes to help manage Guidewire logic

Created: Feb 6/13, Vankerk Solutions
Modification Log:
    Apr 11/13: added rank of 0 for Medical Mal Practice industry and lowered bottom range boundary to 100000
    Aug 12/13: moved test code into separate test class
    Jul 02/15: Rohit: Adding additional logic for generic Apex methods.
    Sep 09/16: Mani: Added  method to return Profile Name
*************/
public class GWUtilities {
    
    // calculate JT Power Ranking for each account based on Buying Entity and which products have been purchased already
    public static List<Account> AccountPowerRankingRecalc(List<Account> Accs) {
        double factor = 0;
        // list of Accounts to send back that need Power Ranking updated (used when called from Opportunity)
        List<Account> UpdAccs = new List<Account>();
        
        // cycle through incoming Accounts to determine the factor
        for (Account a : Accs) {
            // if Buying Entity not Yes or all products already purchased or industry is Med Mal practice, factor = 0 and end
            if (a.buying_entity__c != 'Yes' ||
                (a.BillingCenter__c > 0 && a.PolicyCenter__c > 0 && a.ClaimCenter__c > 0) ||
                 a.industry == 'Medical Mal Practice' )
                factor = 0;
            // else set starting factor and then look at each product not yet purchased and direct premiums
            else {
                // if already a customer of something, start with 2; if not a customer yet, leave as 0
                if (a.BillingCenter__c > 0 || a.PolicyCenter__c > 0 || a.ClaimCenter__c > 0)
                    factor = 2;
                else
                    factor = 0;
                    
                //system.debug(' dwp value: '+a.direct_premiums__c+ ' and currency '+a.currencyisocode);
                // if DWP over 5M
                if (a.direct_premiums__c >= 5000000) {
                    // if Claims not yet bought, add 2
                    if (a.ClaimCenter__c == 0)
                        factor += 2;
                    // if Policy not yet bought, add 3
                    if (a.PolicyCenter__c == 0)
                        factor += 3;
                } // end if over 5M
                // if DWP less than 5M but more than 1M
                else if (a.direct_premiums__c >= 1000000) {
                    // if Claims not yet bought, add 1.5
                    if (a.ClaimCenter__c == 0)
                        factor += 1.5;
                    // if Policy not yet bought, add 2.25
                    if (a.PolicyCenter__c == 0)
                        factor += 2.25;
                } // end if over 1M
                // if DWP less than 1M but more than 100K
                else if (a.direct_premiums__c >= 100000) {
                    // if Claims not yet bought, add 1
                    if (a.ClaimCenter__c == 0)
                        factor += 1;
                    // if Policy not yet bought, add 1.5
                    if (a.PolicyCenter__c == 0)
                        factor += 1.5;
                } // end if over 300K
            } // end else
            // multiple factor by DWP to get rank
            double rank = factor * (a.direct_premiums__c == null ? 0 : a.direct_premiums__c);
            // if not the same as current ranking, update account and add to Upd list
            if (a.JT_Power_ranking__c != rank) {
                a.JT_Power_ranking__c = rank;
                UpdAccs.add(a);
            } // end if needs updating
        } // end loop through accounts
        return UpdAccs;
    }
    
    // method to call power ranking update from Opportunity - we query for all the required fields here and use the Account based method
    //    to do the calculation.  If anything needs updating, save the account changes here.
    // using future method so the Account rollup fields are recalculated before we query for them.
    @future public static void AccountPowerRankingRecalcfromOpportunity(Set<Id> AccIds) {
        // query for all Account fields needed for recalculation
        Map<Id, Account> AccMap = new Map<Id, Account>([select id, jt_power_ranking__c, direct_premiums__c, buying_entity__c, billingcenter__c, claimcenter__c, policycenter__c, industry
            from Account where id in :AccIds]);
        // list of accounts that need to be updated with new JT rank
        List<Account> AccstoUpdate = new List<Account>();
        AccstoUpdate = AccountPowerRankingRecalc(AccMap.values());
        // if there are accounts to update, do so now
        if (AccstoUpdate.size() > 0) update AccstoUpdate;
    }
    
    // called by Customer Story Account trigger, summarizes account names on all stories into text field for reporting/viewing ease
    //    cycles through stories sent into method and lists account names alphabetically with ; inbetween. 
    public static void SummaryCustomerStoryAccounts(Set<Id> storyIds) {
        //system.debug(' in summary method with : '+storyids);
       list<Customer_Story__c> storyupdates = new List<Customer_Story__c>();
        // cycle through stories and linked accounts to build summary
        for (Customer_Story__c s : [select id, story_accounts__c, (Select id, account__r.name from customer_story_accounts__r order by account__r.name) from Customer_Story__c where id in :storyIds]) {
            // store names in a string
            string accts = '';
            // cycle through linked accounts to build string
            for (Customer_Story_Account__c csa : s.customer_story_accounts__r)
                accts += (accts.length() > 0 ? '; ' : '') + csa.account__r.name;
            // now put story into update list with acct summary
            s.story_accounts__c = accts;
            storyupdates.add(s);
        }
        update storyupdates;
    }
    
    // Apex generic logic.
    
    public static string appendStringValuesToBaseQuery(String key, String value, String condition, String operator, Boolean islast){
		   String whereClauseStr = '';
		       if(islast){
		       		whereClauseStr = ' ' + key + operator +  '\'' + value + '\'';  
		       }else{ 
		       		whereClauseStr = ' ' + key + operator + '\'' + value + '\'' +' '+ condition; 
		       }
	       return whereClauseStr;
	}
	
	// get conversion rate Map for specific currencyISOCode from CurrencyType.
	
	public Static Map<String,Decimal> currencyISOcodeconversionRateMap(){
        	List<CurrencyType>  currencyTypeList = [Select IsoCode, IsCorporate, IsActive, Id, ConversionRate From CurrencyType where IsActive = true];
	        Map<String,Decimal> currencyCodeConversionRateMap = new Map<String,Decimal>();
	        for(CurrencyType cType: currencyTypeList){
	           currencyCodeConversionRateMap.put(cType.IsoCode, cType.ConversionRate);
	        }
	        return currencyCodeConversionRateMap;
	} 
	
	// get record type developer name
	
	public static Map<Id,String> getRecordTypeDeveloperName(String objName){
	    
	    String query = 'Select Id,DeveloperName from RecordType Where soBjectType=:objName';
	    List<RecordType> listOfRecordTypes = Database.query(query);
	    Map<Id,String> mapRecordTypesDevName = new Map<Id,String>();
	    for(RecordType r : listOfRecordTypes){
	        mapRecordTypesDevName.put(r.Id,r.DeveloperName);
	    }
	    return mapRecordTypesDevName; 
	}

    // get record type developer name
    
    public static Map<String,String> getRecordTypeId(String objName){
        
        String query = 'Select Id,DeveloperName from RecordType Where soBjectType=:objName';
        List<RecordType> listOfRecordTypes = Database.query(query);
        Map<String,String> mapRecordTypesId = new Map<String,String>();
        for(RecordType r : listOfRecordTypes){
            mapRecordTypesId.put(r.DeveloperName,r.Id);
        }
        return mapRecordTypesId; 
    }

    // get Profile name
    Public static Map<id,Profile> getProfileName(Id profileId){
       Map<id,Profile> MapProfile= New Map<id,profile>([Select id,name from profile where id=:profileId]);
       return MapProfile;
    }

    // get Profile id
    Public static String getProfileId(string profileName){
       List<Profile> lstProfile = [Select Id from Profile where name=:profileName];
       return lstProfile[0].Id;
    }
}