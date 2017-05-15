/**************************************************************************************
// Name          : psaRateSetUtils
// Date          : March 4, 2015
// Description   : Utilized by psaAssignmentTriggerHandler and psaResourceRequestTriggerHandler to retrieve rate set related data
// Author        : CLD Partners
// Revisions     : 2015-04-21 Spano Initial Version
//               : 
***************************************************************************************/

public with sharing class psaRateSetUtils {
    public psaRateSetUtils() {
        
    }

    /**************************************************************************************
    // Name         : setRateBucket
    // Description  : Creates a map of a Rate Set ID to a Map of Billing Levels to PSA Rates
    // Revisions    : 2015-04-21 Spano initial version
    ***************************************************************************************/
    public static Map<Id, Map<String, List<psaRateLookup>>> setRateBucket(Set<Id> account_ids, Set<Id> project_ids, List<String> currencies){
        Date today = System.today();
        Id rateId;
        Map<Id, Map<String, List<psaRateLookup>>> rateBucket = new Map<Id, Map<String, List<psaRateLookup>>>();
        for( PSA_Rate_Set__c rateSet : [SELECT 
                                        id,
                                        PSA_Account__r.id,
                                        PSA_Project__r.id,
                                        CurrencyIsoCode,
                                        (SELECT 
                                        PSA_Bill_Rate_Amount__c,
                                        PSA_Billing_Level__c, 
                                        PSA_Average_Cost_Rate__c,
                                        PSA_Start_Date__c,
                                        PSA_End_Date__c,
                                        CurrencyIsoCode
                                        FROM PSA_Bill_Rates__r where CurrencyIsoCode in :currencies)
                                        FROM PSA_Rate_Set__c
                                        WHERE Id in (SELECT PSA_Bill_Rate_Set__c
                                                     FROM PSA_Rate__c
                                                     WHERE (PSA_Bill_Rate_Set__r.PSA_Account__c IN :account_ids
                                                    OR PSA_Bill_Rate_Set__r.PSA_Project__c IN :project_ids OR
                                                    (PSA_Bill_Rate_Set__r.PSA_Account__c = '' AND PSA_Bill_Rate_Set__r.PSA_Project__c = ''))
                                                    )])
        {
            // for each rate set...
            if(rateSet.PSA_Project__c != null){
                rateId = rateSet.PSA_Project__r.id;
            }
            else if(rateSet.PSA_Account__c != null){
                rateId = rateSet.PSA_Account__r.id;
            }
            else{
                // this is the org default
                rateId = null;
            }

            // for each rate ...
            Map<String, List<psaRateLookup>> rateLookupMap = new Map<String, List<psaRateLookup>>();
            for(PSA_Rate__c rate : rateSet.PSA_Bill_Rates__r){
                List<psaRateLookup> atThatLevel = rateLookupMap.get(rate.PSA_Billing_Level__c);
                if(atThatLevel == null){
                    atThatLevel = new List<psaRateLookup>();
                }
                System.debug('Adding another rate of billing level ' +rate.PSA_Billing_Level__c  + 'and rate: '+rate.PSA_Bill_Rate_Amount__c);
                atThatLevel.add(new psaRateLookup(rate.PSA_Bill_Rate_Amount__c,
                                                                        rate.PSA_Average_Cost_Rate__c,
                                                                        rate.CurrencyIsoCode,
                                                                        rateSet.Id, rate.psa_Start_Date__c,
                                                                        rate.psa_End_Date__c));

                rateLookupMap.put(rate.PSA_Billing_Level__c,atThatLevel);
            }
            rateBucket.put(rateId, rateLookupMap);
        }
        return rateBucket;
    }
}