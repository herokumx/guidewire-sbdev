Public Class WhatChangedReport {
    Public Date OldDate { get; set; }
    Public Date LatestDate { get; set; }
    Public Map < Id, WrappData > mapWrap = new Map < Id, WrappData > ();
    Public List < WrappData > lstWrapperClass = new List < WrappData > ();
    Public List < WrappData > lstAMERPipeLineWrapperClass;
    Public List < WrappData > lstAMERForecastWrapperClass;
    Public List < WrappData > lstEMEAPipeLineWrapperClass;
    Public List < WrappData > lstEMEAForecastWrapperClass;
    Public List < WrappData > lstAPACPipeLineWrapperClass;
    Public List < WrappData > lstAPACForecastWrapperClass;
    Public Map < Id, WrappData > mapWrapAPAC;
    Public Map < Id, WrappData > mapWrapAMER;
    Public Map < Id, WrappData > mapWrapEMEA;
    Set<Id> setOpptyId;
    
    Public List < WrappData > getlstAMERForecastWrapperClass() {
        /*lstAMERForecastWrapperClass.clear();
        for (WrappData wdd: mapWrapAMER.values()) {
            if (wdd.Category == 'Forecast') {
                lstAMERForecastWrapperClass.Add(wdd);
            }
        }*/
        return lstAMERForecastWrapperClass;
    }

    Public List < WrappData > getlstAMERPipeLineWrapperClass() {
        /*lstAMERPipeLineWrapperClass.clear();
        for (WrappData wdd: mapWrapAMER.values()) {
            if (wdd.Category == 'Pipeline') {
                lstAMERPipeLineWrapperClass.Add(wdd);
            }
        }*/
        return lstAMERPipeLineWrapperClass;
    }
    Public List < WrappData > getlstEMEAForecastWrapperClass() {
        /*lstEMEAForecastWrapperClass.clear();
        for (WrappData wdd: mapWrapEMEA.values()) {
            if (wdd.Category == 'Forecast') {
                lstEMEAForecastWrapperClass.Add(wdd);
            }
        }*/
        return lstEMEAForecastWrapperClass;
    }

    Public List < WrappData > getlstEMEAPipeLineWrapperClass() {
        /*lstEMEAPipeLineWrapperClass.clear();
        
        for (WrappData wdd: mapWrapEMEA.values()) {
            if (wdd.Category == 'Pipeline') {
                lstEMEAPipeLineWrapperClass.Add(wdd);
            }
        }*/
        return lstEMEAPipeLineWrapperClass;
    }

    Public List < WrappData > getlstAPACForecastWrapperClass() {
        /*lstAPACForecastWrapperClass.clear();
        for (WrappData wdd: mapWrapAPAC.values()) {
            if (wdd.Category == 'Forecast') {
                lstAPACForecastWrapperClass.Add(wdd);
            }
        }*/
        return lstAPACForecastWrapperClass;
    }

    Public List < WrappData > getlstAPACPipeLineWrapperClass() {
        /*lstAPACPipeLineWrapperClass.clear();
        for (WrappData wdd: mapWrapAPAC.values()) {
            if (wdd.Category == 'Pipeline') {
                lstAPACPipeLineWrapperClass.Add(wdd);
            }
        }*/
        return lstAPACPipeLineWrapperClass;
    }

    Public List < WrappData > getlstWrapData() {
        lstWrapperClass.clear();
        /*
for(WrappData wdd:mapWrapAMER.values()){
if(wdd.Category=='Forecast'){
lstWrapperClass.Add(wdd);
}
}
for(WrappData wdd:mapWrapAMER.values()){
if(wdd.Category=='Pipeline'){
lstWrapperClass.Add(wdd);
}
}
for(WrappData wdd:mapWrapEMEA.values()){
if(wdd.Category=='Forecast'){
lstWrapperClass.Add(wdd);
}
}
for(WrappData wdd:mapWrapEMEA.values()){
if(wdd.Category=='Pipeline'){
lstWrapperClass.Add(wdd);
}
}
for(WrappData wdd:mapWrapAPAC.values()){
if(wdd.Category=='Forecast'){
lstWrapperClass.Add(wdd);
}
}
for(WrappData wdd:mapWrapAPAC.values()){
if(wdd.Category=='Pipeline'){
lstWrapperClass.Add(wdd);
}
}
*/
        //lstWrapperClass.AddAll(mapWrapEMEA.values());
        //lstWrapperClass.AddAll(mapWrapAPAC.values());
        return lstWrapperClass;
    }
    
    //Moved WhatChangedReport constructor code to GenerateReport Function
    public WhatChangedReport()
    {
    }
    
    public void Init()
    {
        OldDate = Date.today();
        LatestDate = Date.today();
        GenerateReport();
    }
    
    //Method to Generate Report based on selected dates by Raskhik 2014-07-27
    public void GenerateReport() {
        
        setOpptyId = new Set<Id>();
        //Commented following line by Raskhik 2014-07-27
        //List < Forecast_Trending__c > lstForecastLatest = [Select Id, Name, CurrencyIsoCode, Amount_Converted__c, Account_Name__c, Amount__c, Billing_Country__c, Deal_Type__c, Fiscal_Period__c, Forecast_Bucket__c, Forecast_Category__c, Forecast_Date__c, Forecast_Period__c, Opportunity_ID__c, Opportunity_Name__c, Region__c from Forecast_Trending__c where CreatedDate > : (System.today() - 1) order by CreatedDate ASC];
        List < Forecast_Trending__c > lstForecastLatest = [Select Id, Name, CurrencyIsoCode, Amount_Converted__c, Account_Name__c, Amount__c, Billing_Country__c, Deal_Type__c, Fiscal_Period__c, Forecast_Bucket__c, Forecast_Category__c, Forecast_Date__c, Forecast_Period__c, Opportunity_ID__c, Opportunity_Name__c, Region__c from Forecast_Trending__c where DAY_ONLY(CreatedDate) =:LatestDate order by CreatedDate ASC];

        mapWrapAMER = new Map < Id, WrappData >();
        mapWrapEMEA = new Map < Id, WrappData >();
        mapWrapAPAC = new Map < Id, WrappData > ();
        Integer ii = 0;
        for (Forecast_Trending__c ftoo: lstForecastLatest) {
            ii++;
            WrappData wdd = new WrappData();
            if (!mapWrap.containskey(ftoo.Opportunity_ID__c)) {
                wdd.SNO = ii + '';
            }
            wdd.opportunityId = ftoo.Opportunity_ID__c;
            wdd.opportunityName = ftoo.Opportunity_Name__c;
            wdd.AccountName = ftoo.Account_Name__c;
            wdd.Region = ftoo.Region__c;
            //wdd.Amountold = ftoo.Amount__c+'';
            //wdd.AmountoldConverted = ftoo.Amount__c+'';
            if (ftoo.Amount__c != null) {
                wdd.AmountLatest = ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '';
            }
            if (ftoo.Amount_Converted__c != null) {
                wdd.AmountLatestConverted = 'USD ' + ftoo.Amount_Converted__c.setScale(2) + '';
            }
            //wdd.ForeCastPeriodold = ftoo.Forecast_Period__c;
            wdd.ForeCastPeriodLatest = ftoo.Forecast_Period__c;
            //wdd.ForeCastCategoryold = ftoo.Forecast_Category__c;
            wdd.ForeCastCategoryLatest = ftoo.Forecast_Category__c;
            if (ftoo.Forecast_Category__c == 'Pipeline' || ftoo.Forecast_Category__c == 'Best Case') {
                wdd.Category = 'Pipeline';
            }
            if (ftoo.Forecast_Category__c == 'Commit' || ftoo.Forecast_Category__c == 'Closed') {
                wdd.Category = 'Forecast';
            }
            wdd.Notes = 'This is a new Opportunity';
            if (ftoo.Region__c == 'EMEA') {
                mapWrapEMEA.put(wdd.opportunityId, wdd);
            } else if (ftoo.Region__c == 'APAC') {
                mapWrapAPAC.put(wdd.opportunityId, wdd);
                System.debug('*****' + wdd.opportunityName);
            } else if (ftoo.Region__c == 'AMER') {
                mapWrapAMER.put(wdd.opportunityId, wdd);
            } else {}
            mapWrap.put(wdd.opportunityId, wdd);
        }
        
        //Commented following line by Raskhik 2014-07-27
        //List < Forecast_Trending__c > lstForecastOld = [Select Id, Name, CurrencyIsoCode, Amount_Converted__c, Account_Name__c, Amount__c, Billing_Country__c, Deal_Type__c, Fiscal_Period__c, Forecast_Bucket__c, Forecast_Category__c, Forecast_Date__c, Forecast_Period__c, Opportunity_ID__c, Opportunity_Name__c, Region__c from Forecast_Trending__c where CreatedDate > : (System.today() - 4) and CreatedDate < : (System.today() - 2) order by CreatedDate ASC];
        List < Forecast_Trending__c > lstForecastOld = [Select Id, Name, CurrencyIsoCode, Amount_Converted__c, Account_Name__c, Amount__c, Billing_Country__c, Deal_Type__c, Fiscal_Period__c, Forecast_Bucket__c, Forecast_Category__c, Forecast_Date__c, Forecast_Period__c, Opportunity_ID__c, Opportunity_Name__c, Region__c from Forecast_Trending__c where DAY_ONLY(CreatedDate) =:OldDate order by CreatedDate ASC];

        for (Forecast_Trending__c ftoo: lstForecastOld) {
            if (mapWrapEMEA.containskey(ftoo.Opportunity_ID__c)) {
                if ((mapWrapEMEA.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '') || (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c) || (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c)) {
                    if (ftoo.Amount__c != null) {
                        mapWrapEMEA.get(ftoo.Opportunity_ID__c).Amountold = ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '';
                    }
                    if (ftoo.Amount_Converted__c != null) {
                        mapWrapEMEA.get(ftoo.Opportunity_ID__c).AmountoldConverted = 'USD ' + ftoo.Amount_Converted__c.setScale(2) + '';
                    }
                    mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastPeriodold = ftoo.Forecast_Period__c;
                    mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryold = ftoo.Forecast_Category__c + '';
                    String displaymessageEMEA = '';
                    if ((mapWrapEMEA.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.Amount__c + '')) {
                        displaymessageEMEA = displaymessageEMEA + 'Amount has been changed from ' + 'USD ' + ftoo.Amount_Converted__c.setScale(2) + ' to ' + mapWrapEMEA.get(ftoo.Opportunity_ID__c).AmountLatestConverted;
                    }
                    if ((mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c + '')) {
                        displaymessageEMEA = displaymessageEMEA + ' Period has been changed from ' + ftoo.Forecast_Period__c + ' to ' + mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest;
                    }
                    if ((mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c + '')) {
                        displaymessageEMEA = displaymessageEMEA + ' Forecast Category has been changed from ' + ftoo.Forecast_Category__c + ' to ' + mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest;
                    }
                    mapWrapEMEA.get(ftoo.Opportunity_ID__c).Notes = displaymessageEMEA;
                    if (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Pipeline' || mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Best Case') {
                        mapWrapEMEA.get(ftoo.Opportunity_ID__c).Category = 'Pipeline';
                    }
                    if (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Commit' || mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Closed') {
                        mapWrapEMEA.get(ftoo.Opportunity_ID__c).Category = 'Forecast';
                    }
                    if ((mapWrapEMEA.get(ftoo.Opportunity_ID__c).AmountLatest == null) && (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest == null) && (mapWrapEMEA.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == null)) {
                        mapWrapEMEA.get(ftoo.Opportunity_ID__c).Notes = 'This Opportunity was deleted.';
                    }
                    setOpptyId.add(ftoo.Opportunity_ID__c);
                }
            } else if (mapWrapAPAC.containskey(ftoo.Opportunity_ID__c)) {
                System.debug('######');
                if ((mapWrapAPAC.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '') || (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c) || (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c)) {
                    if (ftoo.Amount__c != null) {
                        mapWrapAPAC.get(ftoo.Opportunity_ID__c).Amountold = ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '';
                    }
                    if (ftoo.Amount_Converted__c != null) {
                        mapWrapAPAC.get(ftoo.Opportunity_ID__c).AmountoldConverted = 'USD ' + ftoo.Amount_Converted__c.setScale(2) + '';
                    }
                    mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastPeriodold = ftoo.Forecast_Period__c;
                    mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryold = ftoo.Forecast_Category__c + '';
                    String displaymessageAPAC = '';
                    if ((mapWrapAPAC.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '')) {
                        displaymessageAPAC = 'Amount has been changed from ' + 'USD ' + ftoo.Amount_Converted__c.setScale(2) + ' to ' + mapWrapAPAC.get(ftoo.Opportunity_ID__c).AmountLatestConverted;
                    }
                    if ((mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c + '')) {
                        displaymessageAPAC = displaymessageAPAC + ' Period has been changed from ' + ftoo.Forecast_Period__c + ' to ' + mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest;
                    }
                    if ((mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c + '')) {
                        displaymessageAPAC = displaymessageAPAC + ' Forecast Category has been changed from ' + ftoo.Forecast_Category__c + ' to ' + mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest;
                    }
                    mapWrapAPAC.get(ftoo.Opportunity_ID__c).Notes = displaymessageAPAC;
                    if (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Pipeline' || mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Best Case') {
                        mapWrapAPAC.get(ftoo.Opportunity_ID__c).Category = 'Pipeline';
                    }
                    if (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Commit' || mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Closed') {
                        mapWrapAPAC.get(ftoo.Opportunity_ID__c).Category = 'Forecast';
                    }
                    if ((mapWrapAPAC.get(ftoo.Opportunity_ID__c).AmountLatest == null) && (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest == null) && (mapWrapAPAC.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == null)) {
                        mapWrapAPAC.get(ftoo.Opportunity_ID__c).Notes = 'This Opportunity was deleted.';
                    }
                    setOpptyId.add(ftoo.Opportunity_ID__c);
                }
            } else if (mapWrapAMER.containskey(ftoo.Opportunity_ID__c)) {
                System.debug('######');
                if ((mapWrapAMER.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '') || (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c) || (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c)) {
                    if (ftoo.Amount__c != null) {
                        mapWrapAMER.get(ftoo.Opportunity_ID__c).Amountold = ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '';
                    }
                    if (ftoo.Amount_Converted__c != null) {
                        mapWrapAMER.get(ftoo.Opportunity_ID__c).AmountoldConverted = 'USD ' + ftoo.Amount_Converted__c + '';
                    }
                    mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastPeriodold = ftoo.Forecast_Period__c;
                    mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryold = ftoo.Forecast_Category__c + '';
                    String displaymessageAMER = '';
                    if ((mapWrapAMER.get(ftoo.Opportunity_ID__c).AmountLatest != ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '')) {
                        displaymessageAMER = 'Amount has been changed from ' + 'USD ' + ftoo.Amount_Converted__c + ' to ' + mapWrapAMER.get(ftoo.Opportunity_ID__c).AmountLatestConverted;
                    }
                    if ((mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest != ftoo.Forecast_Period__c + '')) {
                        displaymessageAMER = displaymessageAMER + ' Period has been changed from ' + ftoo.Forecast_Period__c + ' to ' + mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest;
                    }
                    if ((mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest != ftoo.Forecast_Category__c + '')) {
                        displaymessageAMER = displaymessageAMER + ' Forecast Category has been changed from ' + ftoo.Forecast_Category__c + ' to ' + mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest;
                    }
                    mapWrapAMER.get(ftoo.Opportunity_ID__c).Notes = displaymessageAMER;
                    //mapWrapAMER.get(ftoo.Opportunity_ID__c).Notes = 'Amount has been changed';
                    if (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Pipeline' || mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Best Case') {
                        mapWrapAMER.get(ftoo.Opportunity_ID__c).Category = 'Pipeline';
                    }
                    if (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Commit' || mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == 'Closed') {
                        mapWrapAMER.get(ftoo.Opportunity_ID__c).Category = 'Forecast';
                    }
                    setOpptyId.add(ftoo.Opportunity_ID__c);
                }
                if ((mapWrapAMER.get(ftoo.Opportunity_ID__c).AmountLatest == null) && (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastPeriodLatest == null) && (mapWrapAMER.get(ftoo.Opportunity_ID__c).ForeCastCategoryLatest == null)) {
                    mapWrapAMER.get(ftoo.Opportunity_ID__c).Notes = 'This Opportunity was deleted.';
                    setOpptyId.add(ftoo.Opportunity_ID__c);
                }
                
            } else {
                WrappData wddd = new WrappData();
                wddd.SNO = ii + '';
                wddd.opportunityId = ftoo.Opportunity_ID__c;
                wddd.opportunityName = ftoo.Opportunity_Name__c;
                wddd.AccountName = ftoo.Account_Name__c;
                wddd.Region = ftoo.Region__c;
                wddd.Amountold = ftoo.CurrencyIsoCode + ' ' + ftoo.Amount__c + '';
                wddd.AmountoldConverted = 'USD ' + ftoo.Amount__c + '';
                //wddd.AmountLatest = ftoo.CurrencyIsoCode+' '+ftoo.Amount__c+'';
                //wddd.AmountLatestConverted = 'USD '+ftoo.Amount__c+'';
                wddd.ForeCastPeriodold = ftoo.Forecast_Period__c;
                //wddd.ForeCastPeriodLatest = ftoo.Forecast_Period__c;
                wddd.ForeCastCategoryold = ftoo.Forecast_Category__c;
                //wddd.ForeCastCategoryLatest = ftoo.Forecast_Category__c;
                if (ftoo.Forecast_Category__c == 'Pipeline' || ftoo.Forecast_Category__c == 'Best Case') {
                    wddd.Category = 'Pipeline';
                }
                if (ftoo.Forecast_Category__c == 'Commit' || ftoo.Forecast_Category__c == 'Closed') {
                    wddd.Category = 'Forecast';
                }
                wddd.Notes = 'This Opportunity was deleted.';
                if (wddd.Region == 'EMEA') {
                    mapWrapEMEA.put(ftoo.Opportunity_ID__c, wddd);
                } else if (wddd.Region == 'APAC') {
                    mapWrapAPAC.put(ftoo.Opportunity_ID__c, wddd);
                } else if (wddd.Region == 'AMER') {
                    mapWrapAMER.put(ftoo.Opportunity_ID__c, wddd);
                } else {}
                mapWrap.put(ftoo.Opportunity_ID__c, wddd);
                setOpptyId.add(ftoo.Opportunity_ID__c);
            }
        }
        createWrapperData();
        //return null;
    }
    
    public void createWrapperData()
    {
        lstAMERPipeLineWrapperClass = new List < WrappData >();
        lstAMERForecastWrapperClass = new List < WrappData >();
        lstEMEAPipeLineWrapperClass = new List < WrappData >();
        lstEMEAForecastWrapperClass = new List < WrappData >();
        lstAPACPipeLineWrapperClass = new List < WrappData >();
        lstAPACForecastWrapperClass = new List < WrappData >();
        
        for (WrappData wdd: mapWrapAMER.values())
        {
            if(setOpptyId.contains(wdd.opportunityId))
            {
                if (wdd.Category == 'Forecast')
                {
                    lstAMERForecastWrapperClass.Add(wdd);
                }
                else if(wdd.Category == 'Pipeline')
                {
                    lstAMERPipeLineWrapperClass.Add(wdd);
                }
            }
        }
        
        for (WrappData wdd: mapWrapEMEA.values())
        {
            if(setOpptyId.contains(wdd.opportunityId))
            {
                if (wdd.Category == 'Forecast') {
                    lstEMEAForecastWrapperClass.Add(wdd);
                }
                else if (wdd.Category == 'Pipeline') {
                    lstEMEAPipeLineWrapperClass.Add(wdd);
                }
            }
        }
        
        for (WrappData wdd: mapWrapAPAC.values()) {
            if(setOpptyId.contains(wdd.opportunityId))
            {
                if (wdd.Category == 'Forecast') {
                    lstAPACForecastWrapperClass.Add(wdd);
                }
                else if (wdd.Category == 'Pipeline') {
                    lstAPACPipeLineWrapperClass.Add(wdd);
                }
            }
        }
    }
    
    Public Class WrappData {
        Public String SNO {
            get;
            set;
        }
        Public String opportunityId {
            get;
            set;
        }
        Public String opportunityName {
            get;
            set;
        }
        Public String AccountName {
            get;
            set;
        }
        Public String Region {
            get;
            set;
        }
        Public String Amountold {
            get;
            set;
        }
        Public String AmountoldConverted {
            get;
            set;
        }
        Public String AmountLatest {
            get;
            set;
        }
        Public String AmountLatestConverted {
            get;
            set;
        }
        Public String Category {
            get;
            set;
        }
        Public String ForeCastPeriodold {
            get;
            set;
        }
        Public String ForeCastPeriodLatest {
            get;
            set;
        }
        Public String ForeCastCategoryold {
            get;
            set;
        }
        Public String ForeCastCategoryLatest {
            get;
            set;
        }
        Public String Notes {
            get;
            set;
        }
    }
}