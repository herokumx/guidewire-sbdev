// Created for Story S-269111 by Paras Dhingra on 11/26/2014 
// Description: Class will compare opportunities between fromDate and toDate and 
// return list of the opportunities to display on
/* Last Modified By : Paras Dhingra 4/30/2015
   Reason : To Handle Opportunities with multiple line items(products)
*/
public with sharing class ForecastSnapshotTrendController {
    public Forecast_Trending_Snapshot__c fromDate{get;set;}
    public Forecast_Trending_Snapshot__c toDate{get;set;}
    public Set<String> MapRegions {get;set;}
    public Date minfromDate{get;set;}
    public List<String> MapCategories{get;set;}
    public Boolean displayMap {get;set;}
    private Map<Id,Forecast_Trending_Snapshot__c> fromDateMap{get;set;}
    private Map<Id,Forecast_Trending_Snapshot__c> toDateMap{get;set;}
    public Map<String,Map<String,ForecastTrendCategoryWrapper>> ForeCastTrendMap{get;set;}
    private Integer FiscalYearstartMonth =  [select FiscalYearStartMonth from Organization ].FiscalYearStartMonth;
    private Integer currentFY = System.today().month()>=FiscalYearstartMonth ? System.today().year()+1:System.today().year();
    public String currentRegion {get;set;}
    public ForecastSnapshotTrendController(){
        fromDate = new Forecast_Trending_Snapshot__c();
        todate = new Forecast_Trending_Snapshot__c();
        ForeCastTrendMap = new Map<String,Map<String,ForecastTrendCategoryWrapper>>();
        MapRegions = new Set<String>();
        MapCategories = new List<String>{'Forecast','Pipeline'}; 
        MapCategories.sort();
        displayMap=false;
        List<Forecast_Trending_Snapshot__c> tempList = new List<Forecast_Trending_Snapshot__c> ([Select Id, Snapshot_Date__c from Forecast_Trending_Snapshot__c ORDER BY Snapshot_Date__c ASC LIMIT 1]);
        if(templist.size()>0 && templist[0]!=null)
            minfromDate= tempList[0].Snapshot_Date__c;
        }
    
    public class ForecastTrendOpportunityWrapper{
         public String Prospect {get;set;}
         public decimal Added{get; set;}
         public decimal Deleted{get; set;}
         public String Notes{get; set;}
         public ForecastTrendOpportunityWrapper(){
            Prospect = '';
            Added =0;
            Deleted = 0;
            Notes= '';
         }
        }
    public class ForecastTrendCategoryWrapper{
        public List<ForecastTrendOpportunityWrapper> OpportunityList{get;set;}
        public Decimal netChange {get;set;}
        public ForecastTrendOpportunityWrapper fxChanges {get;set;}
        public ForecastTrendCategoryWrapper(){
            OpportunityList = new List<ForecastTrendOpportunityWrapper>();
            fxChanges = new ForecastTrendOpportunityWrapper();
            netChange = 0;
            netChange.setScale(2);
        }
    }
    private void fetchData(){
    	if(currentRegion==null || currentRegion == '')
    	{
    		String pageURL = ApexPages.currentPage().getUrl();
            pageURL = pageURL.split('apex/')[1];
            if(pageURL.contains('AMER')){
            	currentRegion = 'AMER';
            }else if(pageURL.contains('EMEA')){
            	currentRegion = 'EMEA';
            }else if(pageURL.contains('APAC')){
            	currentRegion = 'APAC';
            }
    	}
        Date fiscalStartDate = date.newInstance(currentFY-1,FiscalYearstartMonth,1);
        Date fiscalEndDate  = date.newInstance(currentFY,FiscalYearstartMonth-1,31); // Assuming that July is the fiscalyearendmonth
        List<Forecast_Trending_Snapshot__c> fromDateList;
        List<Forecast_Trending_Snapshot__c> toDateList;
        if(currentRegion!=null && currentRegion!=''){
         fromDateList = new List<Forecast_Trending_Snapshot__c> ([SELECT Amount__c, Amount_Converted__c, Amount_local__c, Close_Date__c, Forecast_Category__c, 
        Forecast_Date__c, Opportunity_ID__c, Opportunity_Name__c,Region__c,Snapshot_Date__c, Stage__c from 
        Forecast_Trending_Snapshot__c where Snapshot_Date__c =:fromDate.Close_Date__c AND Forecast_Date__c>=:fiscalStartDate AND  Forecast_Date__c<=:fiscalEndDate
         AND Region__c=:currentRegion]); // fetch opportunities only of current fiscal year
        
         toDateList = new List<Forecast_Trending_Snapshot__c> ([SELECT Amount__c, Amount_Converted__c, Amount_local__c, Close_Date__c, Forecast_Category__c, 
        Forecast_Date__c, Opportunity_ID__c, Opportunity_Name__c,Region__c,Snapshot_Date__c, Stage__c from 
        Forecast_Trending_Snapshot__c where Snapshot_Date__c =:toDate.Close_Date__c AND Forecast_Date__c>=:fiscalStartDate AND  Forecast_Date__c<=:fiscalEndDate
         AND Region__c=:currentRegion]); // fetch opportunities only of current fiscal year
        	
        }else{
        	fromDateList = new List<Forecast_Trending_Snapshot__c> ([SELECT Amount__c, Amount_Converted__c, Amount_local__c, Close_Date__c, Forecast_Category__c, 
        Forecast_Date__c, Opportunity_ID__c, Opportunity_Name__c,Region__c,Snapshot_Date__c, Stage__c from 
        Forecast_Trending_Snapshot__c where Snapshot_Date__c =:fromDate.Close_Date__c AND Forecast_Date__c>=:fiscalStartDate AND  Forecast_Date__c<=:fiscalEndDate]); // fetch opportunities only of current fiscal year
        
         toDateList = new List<Forecast_Trending_Snapshot__c> ([SELECT Amount__c, Amount_Converted__c, Amount_local__c, Close_Date__c, Forecast_Category__c, 
        Forecast_Date__c, Opportunity_ID__c, Opportunity_Name__c,Region__c,Snapshot_Date__c, Stage__c from 
        Forecast_Trending_Snapshot__c where Snapshot_Date__c =:toDate.Close_Date__c AND Forecast_Date__c>=:fiscalStartDate AND  Forecast_Date__c<=:fiscalEndDate]); // fetch opportunities only of current fiscal year
        	
        }
        system.debug('fromList='+ fromDateList);
        system.debug('currentREgion='+ currentRegion);
        fromDateMap = new Map<Id,Forecast_Trending_Snapshot__c>();
        toDateMap = new Map<Id,Forecast_Trending_Snapshot__c>();
        for(Forecast_Trending_Snapshot__c Snapshot : fromDateList)
        {
        	if(fromDateMap.containsKey(Snapshot.Opportunity_ID__c)) // Modified on 4/30/2015 to club multiple Opportunity products by Paras Dhingra # Start
        	{
        		Forecast_Trending_Snapshot__c tempObject = fromDateMap.get(Snapshot.Opportunity_ID__c);
        		tempObject.Amount__c += (Snapshot.Amount__c == null?0.0:Snapshot.Amount__c);
        		tempObject.Amount_Converted__c += (Snapshot.Amount_Converted__c == null?0.0:Snapshot.Amount_Converted__c);
        		tempObject.Amount_local__c += (Snapshot.Amount_local__c == null?0.0:Snapshot.Amount_local__c);
        		fromDateMap.put(Snapshot.Opportunity_ID__c,tempObject);
        	}else{
        		fromDateMap.put(Snapshot.Opportunity_ID__c, Snapshot);
        	}
            
        }
        for(Forecast_Trending_Snapshot__c Snapshot : toDateList)
        {
        	if(toDateMap.containsKey(Snapshot.Opportunity_ID__c)){
        		Forecast_Trending_Snapshot__c tempObject = toDateMap.get(Snapshot.Opportunity_ID__c);
        		tempObject.Amount__c += (Snapshot.Amount__c == null?0.0:Snapshot.Amount__c);
        		tempObject.Amount_Converted__c += (Snapshot.Amount_Converted__c == null?0.0:Snapshot.Amount_Converted__c);
        		tempObject.Amount_local__c += (Snapshot.Amount_local__c == null?0.0:Snapshot.Amount_local__c);
        		toDateMap.put(Snapshot.Opportunity_ID__c,tempObject);
        	}else{
        		toDateMap.put(Snapshot.Opportunity_ID__c, Snapshot);
        	}
         // Modified on 4/30/2015 to club multiple Opportunity products by Paras Dhingra # End   
        }
    }
    private void sortData(){
        
        ForeCastTrendMap = new Map<String,Map<String,ForecastTrendCategoryWrapper>>();
        ForecastTrendOpportunityWrapper CurrentSnapshotforecast;
        ForecastTrendOpportunityWrapper CurrentSnapshotpipeline;
        ForecastTrendCategoryWrapper pipelineList = new ForecastTrendCategoryWrapper();
        ForecastTrendCategoryWrapper forecastList = new ForecastTrendCategoryWrapper();
        Map<Id,Forecast_Trending_Snapshot__c> fromDateMapClone = fromDateMap;//Copy of FromDateMap to remove the matching opportunities 
        for(Id key: toDateMap.keySet())
        {
            Boolean addtoList = false;
            if(fromDateMap.containskey(key))
            {   
                Forecast_Trending_Snapshot__c fromDateOpp = fromDateMap.get(key);
                Forecast_Trending_Snapshot__c toDateOpp = toDateMap.get(key);
                fromDateMapClone.remove(key); // Remove the Opportunity which is already in toDateMap
               
                 if(toDateOpp.Forecast_Category__c == 'Closed' || toDateOpp.Forecast_Category__c == 'Commit')// Check if opportunity category on toDate is Forecast
                {
                    
                    CurrentSnapshotforecast = new ForecastTrendOpportunityWrapper();// Instantiate the Forecast opp for updation 
                    CurrentSnapshotforecast.Notes = '';
                    if(fromDateOpp.Forecast_Category__c == 'Pipeline' || fromDateOpp.Forecast_Category__c == 'Best Case'){
                        CurrentSnapshotpipeline = new ForecastTrendOpportunityWrapper();
                        CurrentSnapshotpipeline.deleted = fromDateOpp.Amount_Converted__c;
                        CurrentSnapshotpipeline.notes = 'Removed from Pipeline\n';
                        CurrentSnapshotpipeline.Prospect = toDateOpp.Opportunity_Name__c;
                     
                        addtoMap(toDateOpp,'Pipeline',CurrentSnapshotpipeline);
                        CurrentSnapshotforecast.Added = fromDateOpp.Amount_Converted__c;
                        CurrentSnapshotforecast.notes += 'Added to Forecast\n';
                        addtoList = true;
                    }
                    if(fromDateOpp.Amount__c!=toDateOpp.Amount__c){
                     
                        decimal amountDiff = toDateOpp.Amount_Converted__c - fromDateOpp.Amount_Converted__c;
                        if(amountDiff <0)
                            CurrentSnapshotforecast.Deleted += amountDiff *(-1);
                        else
                            CurrentSnapshotforecast.Added += amountDiff;
                        CurrentSnapshotforecast.notes+= 'Amount Changed from USD ' +fromDateOpp.Amount_Converted__c.round().format()+' to USD '+ toDateOpp.Amount_Converted__c.round().format() +'\n';
                        addtoList = true;   
                    }else if(fromDateOpp.Amount__c==toDateOpp.Amount__c)
                    {
                        if(fromDateOpp.Amount_Converted__c!= toDateOpp.Amount_Converted__c)
                        {
                            addtoFX(toDateOpp,'Forecast',(toDateOpp.Amount_Converted__c-fromDateOpp.Amount_Converted__c));
                        }
                    }
                    if(toDateOpp.Forecast_Date__c != fromDateOpp.Forecast_Date__c)//To check if forecast date is changed
                    { 
                        Integer fromDateFY = fromDateOpp.Forecast_Date__c.month()>=FiscalYearstartMonth?fromDateOpp.Forecast_Date__c.year()+1:fromDateOpp.Forecast_Date__c.year();
                        Integer toDateFY = toDateOpp.Forecast_Date__c.month()>=FiscalYearstartMonth ? toDateOpp.Forecast_Date__c.year()+1:toDateOpp.Forecast_Date__c.year();
                        Integer currentFY = System.today().month()>=FiscalYearstartMonth ? System.today().year()+1:System.today().year();
                        if(fromDateFY != toDateFY)
                        {
                            if(currentFY!=toDateFY)
                            {
                                CurrentSnapshotforecast.notes += 'Moved to FY'+toDateFY+'\n';
                                CurrentSnapshotforecast.Deleted = fromDateOpp.Amount_Converted__c;
                                addtoList = true;
                            }
                            
                        }
                                                
                    }
                    
                    //Add the opportunity which is changed to the Map List
                    if(addtoList == true)
                    {
                        
                        addtoMap(toDateOpp,'Forecast',CurrentSnapshotforecast);
                    }                        
                
                }
                else if(toDateOpp.Forecast_Category__c == 'Pipeline' || toDateOpp.Forecast_Category__c == 'Best Case')// Check if opportunity category on toDate was Pipeline
                {
                    CurrentSnapshotpipeline = new ForecastTrendOpportunityWrapper();// Instantiate the Pipeline opp for updation 
                    CurrentSnapshotpipeline.Notes = '';
                    if(fromDateOpp.Forecast_Category__c == 'Commit' || fromDateOpp.Forecast_Category__c == 'Closed'){
                        CurrentSnapshotforecast = new ForecastTrendOpportunityWrapper();
                        CurrentSnapshotforecast.Notes = '';
                        CurrentSnapshotforecast.deleted = fromDateOpp.Amount_Converted__c;
                        CurrentSnapshotforecast.notes += 'Removed from Forecast\n';
                        CurrentSnapshotforecast.Prospect = toDateOpp.Opportunity_Name__c;
                       
                        addtoMap(toDateOpp,'Forecast',CurrentSnapshotforecast); //To add removed forecast in the list
                        CurrentSnapshotpipeline.Added = fromDateOpp.Amount_Converted__c;
                        CurrentSnapshotpipeline.notes += 'Added to Pipeline\n';
                        addtoList = true;
                    }
                    if(fromDateOpp.Amount__c!=toDateOpp.Amount__c){
                     
                        decimal amountDiff = toDateOpp.Amount_Converted__c - fromDateOpp.Amount_Converted__c;
                        if(amountDiff <0)
                            CurrentSnapshotpipeline.Deleted += amountDiff *(-1);
                        else
                            CurrentSnapshotpipeline.Added += amountDiff;
                        CurrentSnapshotpipeline.notes+= 'Amount Changed from USD ' +fromDateOpp.Amount_Converted__c.round().format()+' to USD '+ toDateOpp.Amount_Converted__c.round().format() +'\n';
                        addtoList = true;   
                    }else if(fromDateOpp.Amount__c==toDateOpp.Amount__c)
                    {
                        if(fromDateOpp.Amount_Converted__c!= toDateOpp.Amount_Converted__c)
                        {
                            Decimal amountDiff = (toDateOpp.Amount_Converted__c-fromDateOpp.Amount_Converted__c);
                            amountDiff.setScale(2);
                            addtoFX(toDateOpp,'Pipeline',amountDiff);
                        }
                        
                    }
                    if(toDateOpp.Forecast_Date__c != fromDateOpp.Forecast_Date__c)//To check if forecast date is changed
                    { 
                        Integer fromDateFY = fromDateOpp.Forecast_Date__c.month()>=FiscalYearstartMonth?fromDateOpp.Forecast_Date__c.year()+1:fromDateOpp.Forecast_Date__c.year();
                        Integer toDateFY = toDateOpp.Forecast_Date__c.month()>=FiscalYearstartMonth ? toDateOpp.Forecast_Date__c.year()+1:toDateOpp.Forecast_Date__c.year();
                        
                        if(fromDateFY != toDateFY)
                        {
                            if(currentFY !=toDateFY)
                            {
                                CurrentSnapshotpipeline.notes += 'Moved to FY'+toDateFY;
                                CurrentSnapshotpipeline.Deleted = fromDateOpp.Amount_Converted__c;
                                addtoList = true;
                            }   
                            
                        }
                                                
                    }
                    
                    //Add the opportunity which is changed to the Map List
                    if(addtoList == true)
                    { 
                     //CurrentSnapshotpipeline.Prospect = toDateOpp.Opportunity_Name__c;
                     addtoMap(toDateOpp,'Pipeline',CurrentSnapshotpipeline);
                    }                        
                }
                    
            }else //fromDatemap does not contains key hence adding new opportunity
            {
                ForecastTrendOpportunityWrapper newOpportunityWrap = new ForecastTrendOpportunityWrapper();
                Forecast_Trending_Snapshot__c toDateOpp = toDateMap.get(key);
                newOpportunityWrap.Notes = ' This is a new Opportunity\n';
                newOpportunityWrap.Added = toDateOpp.Amount_Converted__c;
                newOpportunityWrap.Prospect = toDateOpp.Opportunity_Name__c;
                //Add new Opportunity to the pipeline list.
                if(toDateOpp.Forecast_Category__c == 'Pipeline' || toDateOpp.Forecast_Category__c == 'Best Case')// Check if opportunity category on toDate was Pipeline
                {
                    
                    addtoMap(toDateOpp,'Pipeline',newOpportunityWrap);
                }
                else //Add new Opportunity to the forecast list.
                {
                    
                    addtoMap(toDateOpp,'Forecast',newOpportunityWrap);
                    
                }
                
            }

        }
        for(Id Key : fromDateMapClone.keyset())//Process the remaining opporrtunities which were removed
        {
            Forecast_Trending_Snapshot__c fromdateOppRemoved = fromDateMapClone.get(key);
            ForecastTrendOpportunityWrapper oldOpportunityWrap = new ForecastTrendOpportunityWrapper();
            oldOpportunityWrap.Deleted = fromdateOppRemoved.Amount_Converted__c;
            oldOpportunityWrap.Notes = 'This opportunity was Deleted or Moved to other Financial Year\n';
            oldOpportunityWrap.Prospect = fromdateOppRemoved.Opportunity_Name__c;
            if(fromdateOppRemoved.Forecast_Category__c == 'Pipeline' || fromdateOppRemoved.Forecast_Category__c == 'Best Case')// Check if opportunity category on removed opp was Pipeline
                {
                   
                    addtoMap(fromdateOppRemoved,'Pipeline',oldOpportunityWrap);
                }
                else //Add new Opportunity to the forecast list.
                {
                   
                    addtoMap(fromdateOppRemoved,'Forecast',oldOpportunityWrap);
                }
        }
        for(String Region : ForeCastTrendMap.keySet())//Process the Forex Changes and add empty forecast categories if not present
        {
            for(String ForeCastCategory: MapCategories)
            {
                if(!ForeCastTrendMap.get(Region).containsKey(ForeCastCategory))
                {
                    ForeCastTrendMap.get(Region).put(ForeCastCategory, new ForecastTrendCategoryWrapper());
                }
                    System.debug('Region'+Region+' Category'+ ForeCastCategory);
                    System.debug('fxchanges'+ForeCastTrendMap.get(Region).get(ForeCastCategory).fxChanges.Added);
                if(ForeCastTrendMap.get(Region).get(ForeCastCategory).fxChanges.Added < 0)//Update the fxChanges values if negative
                {
                    
                    ForeCastTrendMap.get(Region).get(ForeCastCategory).fxChanges.Deleted = ForeCastTrendMap.get(Region).get(ForeCastCategory).fxChanges.Added*(-1);
                    ForeCastTrendMap.get(Region).get(ForeCastCategory).fxChanges.Added = -1;
                    
                }
            }   
            
                    
        }
        
    }
    private void addtoMap(Forecast_Trending_Snapshot__c Opp, String ForeCastCategory, ForecastTrendOpportunityWrapper OppWrap){
        if(!ForeCastTrendMap.containskey(Opp.Region__c))
            {
                Map<String,ForecastTrendCategoryWrapper> tempMap = new Map<String,ForecastTrendCategoryWrapper>();
                tempMap.put(ForeCastCategory, new ForecastTrendCategoryWrapper());
                ForeCastTrendMap.put(Opp.Region__c,tempMap);
            }
        else
        {
            if(!ForeCastTrendMap.get(Opp.Region__c).containsKey(ForeCastCategory))
            {
                Map<String,ForecastTrendCategoryWrapper> tempMap = new Map<String,ForecastTrendCategoryWrapper>();
                tempMap.put(ForeCastCategory, new ForecastTrendCategoryWrapper());
                ForeCastTrendMap.get(Opp.Region__c).put(ForeCastCategory,new ForecastTrendCategoryWrapper());
            }
        }   
        if(OppWrap.Added!=null)
            ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).netChange+=OppWrap.Added;
        if(OppWrap.Deleted!=null)
            ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).netChange-=OppWrap.Deleted;
        OppWrap.Prospect = Opp.Opportunity_Name__c;
        ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).OpportunityList.add(OppWrap);
    }
    private void addtoFX(Forecast_Trending_Snapshot__c Opp, String ForeCastCategory, Decimal AmountDiff){//Add Forex changes
        if(!ForeCastTrendMap.containskey(Opp.Region__c))// Checks if Region does not exists
            {
                Map<String,ForecastTrendCategoryWrapper> tempMap = new Map<String,ForecastTrendCategoryWrapper>();
                tempMap.put(ForeCastCategory, new ForecastTrendCategoryWrapper());
                ForeCastTrendMap.put(Opp.Region__c,tempMap);
            }
        else
        {
            if(!ForeCastTrendMap.get(Opp.Region__c).containsKey(ForeCastCategory))//If Region exists check if Category Exists
            {
                ForeCastTrendMap.get(Opp.Region__c).put(ForeCastCategory,new ForecastTrendCategoryWrapper());
                
            }
        }   
        ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).fxChanges.Notes='Changes due to Forex Rates';
        ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).fxChanges.Prospect='Forex Changes';
        ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).fxChanges.Added +=AmountDiff;
        ForeCastTrendMap.get(Opp.Region__c).get(ForeCastCategory).netChange +=AmountDiff;
        
    }
    public pagereference Submit(){
        ForeCastTrendMap = new Map<String,Map<String,ForecastTrendCategoryWrapper>>();
        if(fromDate.Close_Date__c == toDate.Close_Date__c )
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'Values for both fields cannot be equal'));
            displayMap=false;
            return null;
        }
        if(fromDate.Close_Date__c == null || toDate.Close_Date__c == null)
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'Please enter from date and to date to proceed'));
            displayMap=false;
            return null;
        }
        if(fromDate.Close_Date__c >toDate.Close_Date__c)
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'From date cannot have value greater than To Date '));
            displayMap=false;
            return null;
        }
        if(toDate.Close_Date__c >=System.today())
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'To Date value should be before'+system.today().format()));
            displayMap=false;
            return null;
        }
        if(fromDate.Close_Date__c >=System.today())
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'From Date value should be before'+system.today().format()));
            displayMap=false;
            return null;
        }
        if(fromDate.Close_Date__c <minfromDate)
        {
            Apexpages.addMessage(new Apexpages.message(ApexPages.severity.WARNING,'There is no forecast data for this date.'));
            displayMap=false;
            return null;
        }
        displayMap = true;
        fetchData();
        sortData();
        MapRegions = ForeCastTrendMap.keySet();
        
        return null;
    }
    public pageReference generateCSV(){
    	String page = '/apex/ForeCastSnapshotTrendCSV?fromDate='+fromDate.Close_Date__c+'&todate='+toDate.Close_Date__c;
    	if(currentRegion!=null)
    		page = page + '&region='+currentRegion;
        Pagereference csvReference = new Pagereference(page);
        csvReference.setRedirect(true);
        return csvReference;
    }
    private Date setStringToDateFormat(String myDate) {
   String[] myDateOnly = myDate.split(' ');
   String[] strDate = myDateOnly[0].split('/');
   if(strDate.size()>2){
        Integer myIntDate = integer.valueOf(strDate[1]);
        Integer myIntMonth = integer.valueOf(strDate[0]);
        Integer myIntYear = integer.valueOf(strDate[2]);
        Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
        return d;
   }
   return null;
   
}
    public void processCSV(){
        fromDate.Close_Date__c = setStringToDateFormat(ApexPages.currentPage().getParameters().get('fromDate'));
        toDate.Close_Date__c = setStringToDateFormat(ApexPages.currentPage().getParameters().get('toDate'));
        currentRegion = ApexPages.currentPage().getParameters().get('region');
        fetchData();
        sortData();
        MapRegions = ForeCastTrendMap.keySet();
    }
}