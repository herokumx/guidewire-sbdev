/**************************************************************************************
// Name          : psaRateLookup
// Date          : March 4, 2015
// Description   : Class used by psaRateSetUtils to manage rate set data
// Author        : CLD Partners
// Revisions     : 2015-04-21 Spano Initial Revision
//				 : 
***************************************************************************************/
public with sharing class psaRateLookup {
	
	public String CurrencyIsoCode {get;set;}
    public Decimal BillRate {get;set;}
    public Decimal AvgCost {get;set;}
    public Id RateSetId {get;set;}
    public Date Start {get;set;}
    public Date EndDate {get;set;}

	public psaRateLookup(Decimal bill_rate, Decimal avg_cost, String currency_code, Id rate_set_id, Date start, Date endDate){
            BillRate = bill_rate;
            AvgCost = avg_cost;
            CurrencyIsoCode = currency_code;
            RateSetId = rate_set_id;
            this.Start = start;
            this.EndDate = endDate;
        }
        
}