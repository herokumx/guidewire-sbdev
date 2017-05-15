@isTest
class WhatChangedReportTest
{
    static testMethod void testReport()
    {
        List<Profile> lstProfile =[Select Id from Profile 
                                    where profile.userlicense.name = 'Partner Community'];
        
        List<RecordType> lstRecordType = [Select Id from RecordType where Name ='Partner'];
        List<RecordType> lstPartnerOpptyRT = [Select Id from RecordType where Name ='Partner Opportunity'];
        
        Account objAccount = New Account(name='TestProduct',Products_Purchased__c= 'BillingCenter');
        objAccount.RecordTypeId =lstRecordType[0].Id;
        insert objAccount;
        
        Opportunity oppty = new Opportunity(SWOT_Strengths__c='S Value',
                                            SWOT_Weaknesses__c='W Value',
                                            SWOT_Opportunities__c = 'O Value',
                                            SWOT_Threats__c = 'T Value',
                                            SWOT_Strategy_SO__c = 'SO Value',
                                            SWOT_Strategy_ST__c = 'ST Value',
                                            SWOT_Strategy_WO__c = 'WO Value',
                                            SWOT_Strategy_WT__c = 'WT Value',
                                            Name = 'Test SWOT Opportunity',
                                            StageName = 'Qualified',
                                            CloseDate = Date.today(),
                                            Premium_In_Scope__c = 1000,
                                            PRM_Referring_Partner2__c =objAccount.Id,
                                            RecordTypeId =lstPartnerOpptyRT[0].Id,
                                            Amount=100);
        
            Database.saveResult saveResult = Database.insert(oppty, false);
        
        Forecast_Trending__c forecastTestObject = new Forecast_Trending__c();
        forecastTestObject.Name ='testForeCast';
        forecastTestObject.Amount_Converted__c =12345;
        forecastTestObject.Account_Name__c ='tetAccForeCast';
        forecastTestObject.Amount__c =12345;
        forecastTestObject.Billing_Country__c ='testInd';
        forecastTestObject.Deal_Type__c ='ttForeCast';
        forecastTestObject.Fiscal_Period__c ='ttForeCast';
        forecastTestObject.Forecast_Bucket__c ='teForeCast';
        forecastTestObject.Forecast_Category__c ='testForeCast';
        forecastTestObject.Forecast_Date__c =Date.today();
        forecastTestObject.Opportunity_ID__c = oppty.Id;
        forecastTestObject.Opportunity_Name__c = 'testOppty';
        forecastTestObject.Region__c = 'testOppty';
        //insert forecastTestObject;
        
        Forecast_Trending__c forecastTestObjectNew = new Forecast_Trending__c();
        forecastTestObjectNew.Name ='testForeCast';
        forecastTestObjectNew.Amount_Converted__c =12345;
        forecastTestObjectNew.Account_Name__c ='tetAccForeCast';
        forecastTestObjectNew.Amount__c =12345;
        forecastTestObjectNew.Billing_Country__c ='testInd';
        forecastTestObjectNew.Deal_Type__c ='ttForeCast';
        forecastTestObjectNew.Fiscal_Period__c ='ttForeCast';
        forecastTestObjectNew.Forecast_Bucket__c ='teForeCast';
        forecastTestObjectNew.Forecast_Category__c ='Pipeline';
        forecastTestObjectNew.Forecast_Date__c =Date.today() + 1;
        forecastTestObjectNew.Opportunity_ID__c = oppty.Id;
        forecastTestObjectNew.Opportunity_Name__c = 'testOppty';
        forecastTestObjectNew.Region__c = 'EMEA';
        //insert forecastTestObjectNew;
        
        Forecast_Trending__c forecastTestObjectSec = new Forecast_Trending__c();
        forecastTestObjectSec.Name ='testForeCaest';
        forecastTestObjectSec.Amount_Converted__c =123456;
        forecastTestObjectSec.Account_Name__c ='tetAccForeCast';
        forecastTestObjectSec.Amount__c =123456;
        forecastTestObjectSec.Billing_Country__c ='tesetInd';
        forecastTestObjectSec.Deal_Type__c ='ttForeeCast';
        forecastTestObjectSec.Fiscal_Period__c ='tteForeCast';
        forecastTestObjectSec.Forecast_Bucket__c ='ForeCast';
        forecastTestObjectSec.Forecast_Category__c ='Pipeline';
        forecastTestObjectSec.Forecast_Date__c =Date.today() + 2;
        forecastTestObjectSec.Opportunity_ID__c = oppty.Id;
        forecastTestObjectSec.Opportunity_Name__c = 'testOppty';
        forecastTestObjectSec.Region__c = 'APAC';
        //insert forecastTestObjectSec;
        
        Forecast_Trending__c forecastTestObjectApac = new Forecast_Trending__c();
        forecastTestObjectApac.Name ='testForeCast';
        forecastTestObjectApac.Amount_Converted__c =12345;
        forecastTestObjectApac.Account_Name__c ='tetAccForeCast';
        forecastTestObjectApac.Amount__c =12345;
        forecastTestObjectApac.Billing_Country__c ='testInd';
        forecastTestObjectApac.Deal_Type__c ='ttForeCast';
        forecastTestObjectApac.Fiscal_Period__c ='ttForeCast';
        forecastTestObjectApac.Forecast_Bucket__c ='teForeCast';
        forecastTestObjectApac.Forecast_Category__c ='Pipeline';
        forecastTestObjectApac.Forecast_Date__c =Date.today() + 2;
        forecastTestObjectApac.Opportunity_ID__c = oppty.Id;
        forecastTestObjectApac.Opportunity_Name__c = 'testOppty';
        forecastTestObjectApac.Region__c = 'APAC';
        
        Forecast_Trending__c apacForecastTestObj = new Forecast_Trending__c();
        apacForecastTestObj.Name ='testForeCast';
        apacForecastTestObj.Amount_Converted__c =12345;
        apacForecastTestObj.Account_Name__c ='tetAccForeCast';
        apacForecastTestObj.Amount__c =12345;
        apacForecastTestObj.Billing_Country__c ='testInd';
        apacForecastTestObj.Deal_Type__c ='ttForeCast';
        apacForecastTestObj.Fiscal_Period__c ='ttForeCast';
        apacForecastTestObj.Forecast_Bucket__c ='teForeCast';
        apacForecastTestObj.Forecast_Category__c ='Pipeline';
        apacForecastTestObj.Forecast_Date__c =Date.today() - 1;
        apacForecastTestObj.Opportunity_ID__c = oppty.Id;
        apacForecastTestObj.Opportunity_Name__c = 'testOppty';
        apacForecastTestObj.Region__c = 'AMER';
        
        Forecast_Trending__c forecastObj = new Forecast_Trending__c();
        forecastObj.Name ='testForeCast';
        forecastObj.Amount_Converted__c =123435;
        forecastObj.Account_Name__c ='tetAcceForeCast';
        forecastObj.Amount__c =123457;
        forecastObj.Billing_Country__c ='testyInd';
        forecastObj.Deal_Type__c ='ttForeCuast';
        forecastObj.Fiscal_Period__c ='ttForyeCast';
        forecastObj.Forecast_Bucket__c ='teForeCast';
        forecastObj.Forecast_Category__c ='Pipeline';
        forecastObj.Forecast_Date__c =Date.today() - 1;
        forecastObj.Opportunity_ID__c = oppty.Id;
        forecastObj.Opportunity_Name__c = 'testOppty';
        forecastObj.Region__c = 'AMER';
        
        List<Forecast_Trending__c> lstForecastTestObject = new List<Forecast_Trending__c>();
        lstForecastTestObject.add(forecastTestObject);
        lstForecastTestObject.add(apacForecastTestObj);
        lstForecastTestObject.add(forecastTestObjectNew);
        lstForecastTestObject.add(forecastTestObjectSec);
        lstForecastTestObject.add(forecastTestObjectApac);
        lstForecastTestObject.add(forecastObj);
        insert lstForecastTestObject;
        
        WhatChangedReport objWhatChangedReport = new WhatChangedReport();
        objWhatChangedReport.OldDate = Date.today();
        objWhatChangedReport.LatestDate = Date.today();
        objWhatChangedReport.Init();
        objWhatChangedReport.getlstAMERForecastWrapperClass();
        objWhatChangedReport.getlstAMERPipeLineWrapperClass();
        objWhatChangedReport.getlstEMEAForecastWrapperClass();
        objWhatChangedReport.getlstEMEAPipeLineWrapperClass();
        objWhatChangedReport.getlstAPACForecastWrapperClass();
        objWhatChangedReport.getlstAPACPipeLineWrapperClass();
        objWhatChangedReport.getlstWrapData();
        
        delete forecastTestObjectNew;
        objWhatChangedReport.Init();
        
        delete forecastTestObjectSec;
        delete forecastTestObjectApac;
        objWhatChangedReport.Init();
        
        delete apacForecastTestObj;
        delete forecastObj;
        objWhatChangedReport.Init();
    }
}