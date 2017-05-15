//--------------------
// REST API to send Billing Forecast Details.
// Date: 8/20/2015
// Author: Rohit Koul
//--------------------

@RestResource(urlMapping='/creatBillingForecastDetails/*')
global class GenerateBillingsForecastDetails {
 
  // Post request to get data specific to start and end date.	
  @HttpPost 
  global static List<BillingForecastDetails> getForecastDetails(String sDate,String eDate) {
  	 Date startdate = Date.valueof(sDate);
  	 Date endDate = Date.valueof(eDate);  
  	 List<PSA_Project_Forecast_Detail__c> forecastDetailList = [Select PSA_Project_Forecast__r.PSA_Project__c,PSA_Project_Forecast__r.PSA_Project__r.PSA_Empire_Project_ID__c,PSA_Project_Forecast__r.PSA_For_Month_Ending__c,PSA_Project_Forecast__r.PSA_Project__r.pse__Account__r.Name,PSA_Project_Forecast__r.PSA_Project__r.pse__Account__r.Participant_id__c,PSA_Project_Forecast__r.PSA_Project__r.pse__End_Date__c,
			  	 PSA_Project_Forecast__r.PSA_Project__r.pse__Start_Date__c,PSA_Forecast_Billings__c,PSA_Forecast_Category__c,PSA_Forecast_Category_Percent__c,PSA_Forecast_Source__c,PSA_Forecast_Type__c,PSA_Scheduled_Days__c,PSA_Scheduled_Hours__c,PSA_Seasonality_Factor__c,CurrencyIsoCode, 
			  	 PSA_Item_Key__c,PSA_Project_Forecast__r.PSA_Project__r.pse__Practice__r.Name,PSA_Project_Forecast__r.PSA_Project__r.Name,PSA_Project_Forecast__r.PSA_Project__r.pse__Project_ID__c,PSA_Project_Forecast__r.PSA_Project__r.pse__Region__r.Name,PSA_Scheduled_Cost__c,PSA_Scheduled_Hours_Seasonal__c,PSA_Scheduled_Time_Billings__c,PSA_Project_Forecast__r.PSA_Project__r.pse__Billing_Type__c,PSA_Project_Forecast__r.PSA_Time_Period__r.Name,
			  	 PSA_Project_Forecast__c, p.Id From PSA_Project_Forecast_Detail__c p where PSA_Project_Forecast__r.PSA_Project__c != null and PSA_Project_Forecast__c != null and PSA_Project_Forecast__r.PSA_Include_in_Forecast__c = true and PSA_Project_Forecast__r.PSA_For_Month_Ending__c >=: startdate and PSA_Project_Forecast__r.PSA_For_Month_Ending__c <=: endDate];
     
     List<BillingForecastDetails> forecastList = new List<BillingForecastDetails>();
     
     Map<String,Decimal> currencyCodeConversionRateMap = GWUtilities.currencyISOcodeconversionRateMap();  
     
     for(PSA_Project_Forecast_Detail__c forecastDetailVar: forecastDetailList){
     
	   	BillingForecastDetails forecast = new BillingForecastDetails();
	    forecast.Account_Participant_ID = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Account__r.Participant_id__c;
	    forecast.Account_Name = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Account__r.Name;
	    forecast.End_Date = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__End_Date__c;        
	    forecast.Forecast_Billings = forecastDetailVar.PSA_Forecast_Billings__c;
	    forecast.Forecast_Category = forecastDetailVar.PSA_Forecast_Category__c; 
	    forecast.Forecast_Category_Percent = forecastDetailVar.PSA_Forecast_Category_Percent__c;
	    forecast.Forecast_Source = forecastDetailVar.PSA_Forecast_Source__c;
	    forecast.Forecast_Type = forecastDetailVar.PSA_Forecast_Type__c;
	    forecast.For_Month_Ending = forecastDetailVar.PSA_Project_Forecast__r.PSA_For_Month_Ending__c;
	    forecast.Item_Key = forecastDetailVar.PSA_Item_Key__c;
	    forecast.Practice_Name = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Practice__r.Name; 
	    forecast.Project_Name = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.Name;
	    forecast.Project_ID = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Project_ID__c;
	    forecast.Region_Name = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Region__r.Name;
	    forecast.Scheduled_Cost = forecastDetailVar.PSA_Scheduled_Cost__c;
	    forecast.Scheduled_Days= forecastDetailVar.PSA_Scheduled_Days__c;
	    forecast.Scheduled_Hours=forecastDetailVar.PSA_Scheduled_Hours__c; 
	    forecast.Scheduled_Hours_Seasonal= forecastDetailVar.PSA_Scheduled_Hours_Seasonal__c;
	    forecast.Scheduled_Time_Billings = forecastDetailVar.PSA_Scheduled_Time_Billings__c;
	    if(forecastDetailVar.CurrencyIsoCode != null && currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode) != null && currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode) != 0){
	      forecast.Forecast_Billings_converted = (forecastDetailVar.PSA_Forecast_Billings__c/currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode)).setScale(2);
	      forecast.Scheduled_Cost_converted= (forecastDetailVar.PSA_Scheduled_Cost__c/currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode)).setScale(2);
	      forecast.Scheduled_Time_Billings_converted = (forecastDetailVar.PSA_Scheduled_Time_Billings__c/currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode)).setScale(2);
	      forecast.Conversion_Rate = currencyCodeConversionRateMap.get(forecastDetailVar.CurrencyIsoCode);
	    }
	    forecast.Seasonality_Factor = forecastDetailVar.PSA_Seasonality_Factor__c;
	    forecast.Services_Billing_Type = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Billing_Type__c;
	    forecast.Start_Date = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.pse__Start_Date__c;
	    forecast.Time_Period_Name = forecastDetailVar.PSA_Project_Forecast__r.PSA_Time_Period__r.Name;
	    forecast.Empire_Project_Id = forecastDetailVar.PSA_Project_Forecast__r.PSA_Project__r.PSA_Empire_Project_ID__c;
	    forecastList.add(forecast);
     }
	  return forecastList;
  }

  
  global class BillingForecastDetails{
    public string Account_Name{get; set;}
    public string Account_Participant_ID{get; set;}
    public date End_Date{get; set;}
    public decimal Forecast_Billings{get; set;}
    public decimal Forecast_Billings_converted{get; set;}
    public string Forecast_Category{get; set;}
    public decimal Forecast_Category_Percent{get; set;}
    public string Forecast_Source{get; set;}
    public string Forecast_Type{get; set;}
    public date For_Month_Ending{get; set;}
    public string Item_Key{get; set;}
    public string Practice_Name{get; set;}
    public string Project_Name{get; set;}
    public string Project_ID{get; set;}
    public string Region_Name{get; set;}
    public decimal Scheduled_Cost{get; set;}
    public decimal Scheduled_Cost_converted{get; set;}
    public decimal Scheduled_Days{get; set;}
    public decimal Scheduled_Hours{get; set;}
    public decimal Scheduled_Hours_Seasonal{get; set;}
    public decimal Scheduled_Time_Billings{get; set;}
    public decimal Scheduled_Time_Billings_converted{get; set;}
    public decimal Seasonality_Factor{get; set;}
    public string Services_Billing_Type{get; set;}
    public date Start_Date{get; set;}
    public string Time_Period_Name{get; set;}
    public string Empire_Project_Id{get; set;}
    public Decimal Conversion_Rate{get; set;}  
  }

}