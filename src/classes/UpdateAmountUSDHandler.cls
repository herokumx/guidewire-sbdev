public class UpdateAmountUSDHandler 
{
    public Map<String,Decimal> getDateSpecificCurrencyMap(Date dateVar,List<DatedConversionRate> datedConversionRateList){
                Map<String,Decimal> dateSpecificCurrencyMap = new Map<String,Decimal>();
                for(DatedConversionRate dcr : datedConversionRateList){
                    if (dateVar != null && dcr.startDate <= dateVar && dcr.nextStartDate > dateVar)
                    {
                      dateSpecificCurrencyMap.put(dcr.IsoCode,dcr.ConversionRate);
                    }
                }
            return dateSpecificCurrencyMap; 
    }  
    
    public void UpdateAmount(list<opportunity> opplst)
    {
      /*  for(opportunity opp: opplst)
        {
              opp.Amount_USD__c = util.convertToOrgCurrency(opp.CurrencyIsoCode, opp.Amount, opp.CloseDate);          
        }  
      */
        Set<Date> closedt = new Set<Date>();
        Set<String> isoCodeLst = new Set<String>();
          for(Opportunity opp : opplst)
           {
              closedt.add(opp.CloseDate);
              isoCodeLst.add(opp.CurrencyIsoCode);
           }
          List<DatedConversionRate> DcrLst = [select id, isoCode,conversionrate, nextStartDate, startDate from DatedConversionRate
                                               where isoCode=:isoCodeLst and startDate <= :closedt and nextStartDate > : closedt Limit 49000];

          map<String,List<DatedConversionRate>> dcrMap = new map<String,List<DatedConversionRate>>();

          for(DatedConversionRate dcr : DcrLst)
          {
             if(dcrMap.containsKey(dcr.isoCode))
              {
                List<DatedConversionRate> dcrlst2 = dcrMap.get(dcr.isoCode);
                 dcrlst2.add(dcr);
                 dcrMap.put(dcr.isoCode,dcrlst2);
              }
            else
              {
                List<DatedConversionRate> dcrlst1 = new List<DatedConversionRate>();
                dcrlst1.add(dcr);
                dcrMap.put(dcr.isoCode,dcrlst1);

              }
           }

            for(opportunity opp: opplst)
                {
                    List<DatedConversionRate> dcrlst3 = dcrMap.get(opp.CurrencyIsoCode);
                    Decimal res = 0.0;
                    for(DatedConversionRate dcr : dcrlst3)
                    {
                        if(dcr.startDate <= opp.CloseDate &&  dcr.nextStartDate > opp.CloseDate && opp.Amount!=null)
                         {
                            res = opp.Amount / dcr.conversionRate;
                            break;
                         }

                    }

                    opp.Amount_USD__c = res;
                }
    }

    public void UpdateQuotaARR(List<Opportunity> newOppList, Map<Id,Opportunity> oldOppMap){
        GW_Common_Settings__c commonSetting = GW_Common_Settings__c.getInstance('StaticFYDate');
        Date fyStartDate; 
        If(commonSetting != null && commonSetting.Current_FY_Start_Date__c != null) {
            fyStartDate = commonSetting.Current_FY_Start_Date__c;
        }   
    //  Date fyEndDate = commonSetting.Current_FY_End_Date__c;
        System.debug('UpdateQuotaARR>>>>>>'+ newOppList);
        
        Set<Date> tempclosedDateSet = new Set<Date>();
        // restrict DateConversionRate to current opportunities.
           for(Opportunity opp : newOppList)
           {
                 tempclosedDateSet.add(opp.CloseDate);
                 tempclosedDateSet.add(System.today());
              if(fyStartDate != null){
                tempclosedDateSet.add(fyStartDate);
              }
           } 
        
       List<DatedConversionRate> datedConversionRateList = [Select StartDate,nextStartDate,IsoCode,ConversionRate From DatedConversionRate  where startDate <= :tempclosedDateSet and nextStartDate > : tempclosedDateSet Limit 10000];
        
       for (Opportunity newOpp: newOppList)
        {
           Decimal quotaARRValue = 0; 
           Date tempClosedDate = System.today();
           
            // is insert or meets criteria on update
            if (newOpp.Amount != null && (oldOppMap == null || (oldOppMap != null && (oldOppMap.get(newOpp.Id).CloseDate != newOpp.CloseDate || (oldOppMap.get(newOpp.Id).StageName != newOpp.StageName && (newOpp.StageName == 'Closed - Won' || newOpp.StageName == 'No Intent to Buy' || newOpp.StageName == 'Project Cancelled' || newOpp.StageName == 'Opportunity Died' || newOpp.StageName == 'Guidewire Excluded' || newOpp.StageName == 'Dead/Dry' ) || oldOppMap.get(newOpp.Id).Amount != newOpp.Amount)))))
            {
              // check with current Date.
              If(oldOppMap == null && newOpp.CloseDate < System.today() && newOpp.StageName !=null && newOpp.StageName == 'Closed - Won'){
                  tempClosedDate = System.today();
              }else if(newOpp.CloseDate < System.today() && oldOppMap.get(newOpp.Id).StageName != newOpp.StageName && (newOpp.StageName == 'Closed - Won' || newOpp.StageName == 'No Intent to Buy' || newOpp.StageName == 'Project Cancelled' || newOpp.StageName == 'Opportunity Died' || newOpp.StageName == 'Guidewire Excluded' || newOpp.StageName == 'Dead/Dry' )){
                  tempClosedDate = System.today();
              }else{
                  tempClosedDate = newOpp.CloseDate; 
              } 
            
              Decimal conversionRateOld =  getDateSpecificCurrencyMap(tempClosedDate,datedConversionRateList).get(newOpp.CurrencyIsoCode);
              if(conversionRateOld == null){
                conversionRateOld =  getDateSpecificCurrencyMap(System.today(),datedConversionRateList).get(newOpp.CurrencyIsoCode);
              }
              
              if (fyStartDate != null && tempClosedDate >= fyStartDate){
                  Decimal conversionRateNew =  getDateSpecificCurrencyMap(fyStartDate,datedConversionRateList).get(newOpp.CurrencyIsoCode);
                  if(conversionRateNew != null){
                 newOpp.Quota_ARR__c = newOpp.Amount / conversionRateNew;
                  }else{
                    if (conversionRateOld != null) 
                    { 
                      newOpp.Quota_ARR__c = newOpp.Amount/conversionRateOld;
                    }
                  }
              }else{
                 //   conversionRateOld =  getDateSpecificCurrencyMap(System.today()).get(newOpp.CurrencyIsoCode);
                    if(conversionRateOld != null){
                    newOpp.Quota_ARR__c = newOpp.Amount/conversionRateOld;
                    }
              }
            }
        }
    }


}