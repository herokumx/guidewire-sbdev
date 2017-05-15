public with sharing class StorySearch_NewController {

/***************************************************************************************************************************************
    Class:          StorySearch_NewController
    
    Description:    Custom search for Customer_Story__c and Products objects
    
    Author:         Niki Vankerk, based on original code by J.Henson, 10/01/2012
        
    Revision Hist:  
****************************************************************************************************************************************/

//  Get Field Describe Info
//  ------------------------------------------------------------------------------------------------------------------------------------
    public Map<String, Schema.SobjectField> fieldMap;
    public Schema.DescribeFieldResult DescribeField2(String fieldName){
    //  Split into object & field name
        List<String> fieldData = fieldName.split(':');      
    //  Get the right map
        Map<String, Schema.SobjectField> fieldTOdescribe = objectTOfieldmap.get(fieldData[0]);
    //  Return the describe
        Schema.Describefieldresult F;
        try{
            F = fieldTOdescribe.get(labelTOname.get(fieldName)).getDescribe();
        } catch (Exception X){
            Apexpages.message fieldaccess = new Apexpages.message(Apexpages.severity.warning, 'No access to field: '+fieldname);
            Apexpages.addmessage(fieldaccess);
        }                       
        return  f;
    } 

//  Set Search Type (default to info)
//  ------------------------------------------------------------------------------------------------------------------------------------
    public String searchType {get{ if(searchType == null)return 'story'; else return searchType; } set;}    
    public Map<String, String> objNameTOfields {get; set;}

//  Search type toggle (RUN ON PAGE LOAD)
//  ------------------------------------------------------------------------------------------------------------------------------------
    public PageReference SelectSearchType(){
    
    //  Clear the maps & filters
        objectTOfieldmap = null;
        clearFilters();
        objNameTOfields = new Map<String, String>();
        
    //  Add Account info which applies to both search types
        objNameTOfields.put('Account','id,name,Region__c,LOBNEW__c,OverallDWP__c,Distribution_Channel__c,Domicile_Country__c');

    //  Select the object & pre-populate filters        
        if(searchType == 'info'){           
            // include any account fields we want to display in the list through the account relationship field
            objNameTOfields.put('Product__c','id,name,account__c, account__r.name,account__r.region__c, account__r.lobnew__c,account__r.OverallDWP__c,account__r.distribution_channel__c, account__r.domicile_country__c');
        } else {
            // pull ID back from Customer Story, then use the fields for Customer Story Account to bring back the story related fields
            objNameTOfields.put('Customer_Story__c','id');
            // include all account/customer story fields we want to display on the results page using the relationship fields
            objNameTOfields.put('Customer_Story_Account__c','id,account__c,account__r.name,customer_story__r.Story_Title__c,customer_story__r.Story_Type__c,customer_story__r.Products__c,customer_story__r.Name');

        }
        
        // system.debug('objNameTOfields: '+objNameTOfields);
        return null;
    }

//  Clear out filters
//  ------------------------------------------------------------------------------------------------------------------------------------        
    public Pagereference ClearFilters(){
        filterFields = null;
        filters = null;
        results=null;
        return null;        
    }
    
   
//  Generate Object Label to Field Map
//  ---------------------------------------------------------------------------------------------
    Map<String, Map<String, Schema.SobjectField>> objectTOfieldmap {
    get{
        //system.debug('getting object to field map with these elements: '+objecttofieldmap);
        if(objectTOfieldmap == null){
            objectTOfieldmap = new Map<String, Map<String, Schema.SobjectField>>{};
            for(String obj : objNameTOfields.keySet()){
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(obj);
                Schema.DescribeSObjectResult r = targetType.getDescribe();
                Map<String, Schema.SObjectField> M = r.fields.getMap();             
                String objLabel = obj.replace('__c','').replace('_',' ');               
                objLabelTOname.put( objLabel, obj);             
                objectTOfieldmap.put(objLabel, M);
            }                       
        }       
        //system.debug('objectTO fieldMap: '+objectTOfieldMap);
        return objectTOfieldMap;
    } set;}

//  Allowed Search Filters
//  ------------------------------------------------------------------------------------------------------------------------------------
    List<SelectOption> filterFields;
    public Map<String, Set<String>> objLabelTOallowedFilters = new Map<String, Set<String>>{
        'Account'  => new Set<String>{'Region__c', 'LOBNEW__c', 'Distribution_Channel__c', 'OverallDWP__c',  'Name', 'Domicile_Country__c'}, 
        'Product'               => new Set<String>{'Products__c','Upgraded__c','Product_Version__c', 'First_Go_Live_Date__c', 'Deal_Close_Date__c', 'Competition__c', 'Add_On_Module_s__c'},
     //   'Customer Story Account'        => new Set<String>{'Story_Type__c','Products__c','Date_Story_Captured__c', 'Quantifiable_Metric__c', 'Services_Story__c'},
        'Customer Story'        => new Set<String>{'Story_Type__c','Products__c','Date_Story_Captured__c', 'Quantifiable_Metric__c', 'Services_Story__c'}
    };          


//  Allowed Filter Field Types  
//  ------------------------------------------------------------------------------------------------------------------------------------    
    Set<String>allowedTypes = new Set<String>{'BOOLEAN','STRING','PICKLIST','MULTIPICKLIST','DOUBLE','DATE','DATETIME','PHONE', 'TEXTAREA'};
    
    
//  Get Filter Fields Available for Each Filter 
//  ------------------------------------------------------------------------------------------------------------------------------------        
    Map<String, String> labelTOname = new Map<String, String>{};
    Map<String, String> objLabelTOname = new Map<String, String>{};
    
    public List<Selectoption> getFilterFields(){
        if(filterFields == null){
            
            filterFields = new List<SelectOption>{};                                        
            filterFields.add(new Selectoption('','--None--'));
             
            for(String key : objectTOfieldmap.keySet()){          
                Map<String, Schema.SobjectField> M = objectTOfieldmap.get(key);
                String obj = key;                               
                for(String s : M.keySet()){
                    Schema.DescribeFieldResult F = M.get(s).getDescribe();
                    if(allowedTypes.contains(String.valueof(F.getType())) && F.isAccessible() && F.isFilterable()){     
                    //  If the filter is allowed and that object is in the search scope, allow it                               
                        if(objLabelTOallowedFilters.containsKey(obj) && objLabelTOallowedFilters.get(obj).contains(F.getName())){                   
                            obj = obj.replace('__c','').replace('_',' ');
                            filterFields.add(new Selectoption(obj+':'+F.getLabel(),obj+': '+F.getLabel()));
                            labelTOname.put(obj+':'+F.getLabel(), F.getName());
                        }                           
                    }
                }                                   
            }
            filterFields.sort();            
        }
        return filterFields;
    }
        
        
//  Get Filter Rows & Set 4 blank rows if null
//  ------------------------------------------------------------------------------------------------------------------------------------
    public Map<Integer, filter> idTOfilter = new Map<Integer, filter>{};
    public List<filter>filters;
    public Integer filterRows = 4;
    
    public List<filter> getFilters(){
        if(filters == null){
            filters = new List<filter>{};
            for(Integer i = 0; i < 4; i++){
                filter f = new filter(getFilterFields(), i);
                filters.add(f);
                idTOfilter.put(i, f);
            }
        }
        return filters;
    }


//  Add a new Filter
//  ------------------------------------------------------------------------------------------------------------------------------------
    public PageReference AddFilter(){
        filter f = new filter(getFilterFields(),filters.size());        
        idTOfilter.put(filters.size(), f);      
        filters.add(f); 
        return null;    
    }
    
//  Remove a filter
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public PageReference RemoveFilter(){    
        filters.remove(currentFilterID);
        idTOfilter = new Map<Integer, filter>{};
        Integer i = 0;
        for(filter f : filters){
            f.filterId = i;
            idTOfilter.put(i, f);                   
            i++;        
        }
                                    
        return null;    
    }

//  Populate Filter Operators Based on Field Type
//  ------------------------------------------------------------------------------------------------------------------------------------    
    List<Selectoption> list1 = new List<Selectoption>{  new Selectoption('LIKE','CONTAINS'),
                                                        new Selectoption('NOT LIKE','NOT CONTAINS') };
    
    List<Selectoption> list2 = new List<Selectoption>{  new Selectoption('>=','AFTER'),
                                                        new Selectoption('<=','BEFORE')             };
    
    List<Selectoption> list3 = new List<Selectoption>{  new Selectoption('INCLUDES','INCLUDES'),
                                                        new Selectoption('EXCLUDES','EXCLUDES')     };
    
    List<Selectoption> list4 = new List<Selectoption>{  new Selectoption('>','GREATER THAN'),
                                                        new Selectoption('<','LESS THAN')           };      

    List<Selectoption> list5 = new List<Selectoption>{  new Selectoption('=','EQUALS'),
                                                        new Selectoption('!=','NOT EQUALS')         };

    List<Selectoption> list6 = new List<Selectoption>{  new Selectoption('=','EQUALS')              };
                                                                                                                                                                                                                                                                            
    Map<String, List<Selectoption>> typeTOoperators = new Map<String, List<Selectoption>>{
        'PHONE'         => list1,       'BOOLEAN'       => list6,       'PICKLIST'  => list5,
        'STRING'        => list1,       'TEXTAREA'      => list1,       'DATE'      => list2,
        'DATETIME'      => list2,       'MULTIPICKLIST' => list3,       'DOUBLE'    => list4    
    };
    
    public void PopulateOperators(filter f){
        
        if(DescribeField2(f.selectedField) != null){
            
        
            Schema.DescribeFieldResult describeF = DescribeField2(f.selectedField);      
            f.filterOperators = typeTOoperators.get(String.valueof(describeF.getType()));
            
            if(describeF.getType() ==  Schema.DisplayType.DATE || describeF.getType() ==  Schema.DisplayType.DATETIME){
                f.helpText = 'Date formats must be entered as MM/DD/YYYY, i.e. 01/20/2011';
            }
    
            if(describeF.getType() == Schema.DisplayType.MULTIPICKLIST){
                f.helpText = 'Hold ctrl or shift to select multiple items. Returns records containing any of the selections';   
            }
    
            if(describeF.getType() ==  Schema.DisplayType.DOUBLE){
                f.helpText = 'For currency fields, please do not input any special characters, including commas or $ signs, e.g. $1,000';
            }
            
        }               
    }
    
    
//  Change the Filter when the Field is selected
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public Integer currentFilterID {get; set;}
    public Filter currentFilter;
    
    public PageReference SelectFilterType(){
    
        //system.debug('inside SelectFilterType: '+ currentFilterID + ' with filter of : '+idTOfilter.get(currentFilterID));
    //  Get the selected filter
        filter f = idTOfilter.get(currentFilterID);
        
    //  If a field has been selected, populate its data, otherwise clear it out
        if(f.selectedField != null && f.selectedField != ''){           
        
        //  Get the describe info
            Schema.DescribeFieldResult describeF;
            
        //  For Customer Story Account, grab the values from the Customer Story fields it references since we have a junction object
        //  for all other fields, get the describe info
      /*      if(f.selectedField == 'Customer Story Account:Story Type'){
                describeF = Schema.sObjectType.Customer_Story__c.fields.Story_Type__c;
            } else if(f.selectedField == 'Customer Story Account:Products Involved'){
                describeF = Schema.sObjectType.Customer_Story__c.fields.Products__c;
            } else if(f.selectedField == 'Customer Story Account:Year Story Captured'){
                describeF = Schema.sObjectType.Customer_Story__c.fields.Date_Story_Captured__c;
            } else
            {
       */         describeF = DescribeField2(f.selectedField);
       //     }
            
            if(describeF != null){
                    
            //  Set the type
                f.selectedFieldType = String.valueof(describeF.getType());  
            
            //  Get the pickvals for picklists
                if(describeF.getType() == Schema.DisplayType.PICKLIST || describeF.getType() == Schema.DisplayType.MULTIPICKLIST){
                    f.selectedOptions = new List<Selectoption>{};
                    for(Schema.Picklistentry p : DescribeF.getPicklistValues()){
                        f.selectedOptions.add(new Selectoption(p.getValue(), p.getLabel()));
                    }
                }
    
            //  Set the dropdowns for boolean fields
                if(describeF.getType() == Schema.DisplayType.BOOLEAN){
                    f.selectedOptions = new List<Selectoption>{};
                    f.selectedOptions.add(new Selectoption('false','false'));
                    f.selectedOptions.add(new Selectoption('true','true'));
                }
            
            //  Populate the filter operators for the filter
                PopulateOperators(f);
                    
            }       
    
        } else {
            f.selectedFieldType = null;
            f.filterOperators = null;
            f.searchString = null;
        }
        
        return null;
    
    }
    
    
    
//  Construct a SOSL/SOQL Where clause
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public Boolean validsearch;
    public Map<String, String> objectLabelTOfilters(){
        
        Apexpages.Message invalidsearch = new Apexpages.Message(Apexpages.severity.fatal,'Please enter/select a value for the selected field.');
        validsearch = true;
        
        Map<String, String> buildSearchFilters = new Map<String, String>{};
        for(filter f : getFilters()){
            if(f.selectedField != null){
                f.valid = true;
                List<String> fielddata = f.selectedField.split(':');        
                String searchStr;
                string fieldName =labelTOname.get(f.selectedField);
                // if this is a Customer Story Account field, add customer_story__r. in front since we are on the junction object
                if (fielddata[0] == 'Customer Story') fieldName = 'customer_story__r.'+fieldName;
                // if account field filter, both customer story account and product have MD fields called Account__c so preface with that
                if (fielddata[0] == 'Account') fieldName = 'account__r.'+fieldName;
                
                if(f.selectedOperator == 'NOT LIKE')searchStr = '(NOT '+fieldName  + ' LIKE ';
                else searchStr = fieldName + ' '+ f.selectedOperator+' ';
                
                if(f.selectedFieldType == 'STRING' || f.selectedFieldType == 'PHONE' || f.selectedFieldType == 'TEXTAREA'){
                    if(f.searchString == null || f.searchString ==  '')f.valid = false;
                    if(f.selectedOperator == 'LIKE')searchStr += '\'%' +f.searchString +'%\'';
                    else if(f.selectedOperator == 'NOT LIKE')searchStr += '\'%' +f.searchString +'%\')';
                    else searchStr += '\'' +String.escapeSingleQuotes(f.searchString) +'\'';
                } else if(f.selectedFieldType == 'PICKLIST'){
                    if(f.selectedPickval == null || f.selectedPickval ==  '')f.valid = false;
                    searchStr += '\'' +f.selectedPickval +'\'';
                } else if(f.selectedFieldType == 'BOOLEAN'){
                    if(f.selectedPickval == null || f.selectedPickval ==  '')f.valid = false;
                    searchStr += f.selectedPickval;             
                } else if(f.selectedFieldType == 'MULTIPICKLIST'){
                    if(f.selectedPickvals != null){
                        if(f.selectedPickvals.isEmpty())f.valid = false;
                        Set<String> s = new Set<String>{};
                        s.addAll(f.selectedPickvals);
                        searchStr += '('+ setTOstr(s) +')';
                    }
                } else if(f.selectedFieldType == 'DOUBLE'){
                    if(f.searchString == null || f.searchString ==  '')f.valid = false;
                    searchStr += f.searchString;
                } else if(f.selectedFieldType == 'DATE'){
                    if(f.searchString == null || f.searchString ==  '')f.valid = false;
                    try{ 
                        date d = date.parse(f.searchString);                        
                        String datestr = d.Year()+'-'+String.valueof(d.Month()).leftPad(2)+'-'+String.valueof(d.Day()).leftPad(2);
                        String dateSearch = datestr.replace(' ','0');                   
                        searchStr += dateSearch;
                    }
                    catch(Exception x){ apexpages.addmessages(x); f.valid = false;}
                            
                } else if(f.selectedFieldType == 'DATETIME'){
                    if(f.searchString == null || f.searchString ==  '')f.valid = false;
                    searchStr += f.searchString+'T00:00:00+00:00';      
                }                       
                
                if(buildSearchFilters.get(fielddata[0]) != null)
                    searchStr += ' AND '+buildSearchFilters.get(fielddata[0]);
                    
                String objLabel = fielddata[0];
                buildSearchFilters.put(objLabel,searchStr);
            
                if(!f.valid)validsearch = false;
            } 
        }
        //system.debug('search filters: '+buildSearchFilters);
        if(!validsearch)apexpages.addmessage(invalidsearch);        
        return buildSearchFilters;
    }


//  SOSL Search (only used if keyword is populated, NOTE: we never use SOSL for Customer Info/Account search type)
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public string searchQuery {get; set;}
    public String keyword {get; set;}
    public List<List<sObject>> SearchObjects(){
    
        // we want to use SOSL if we have a keyword search since it nicely searches through all the text fields on the Customer Story
        //  but since we have split account out of Customer Story and are joining to many accounts, we can't include the account filters
        //  in the SOSL.  This means we could get more than 2000 results back even though some of those won't get through the account
        //  filters.  Instead let's run the query against Customer Story Account join object without keyword, then build a set of story IDs 
        //  and run the keyword through SOSL on that limited set of stories.  Would be better if we could just pull the accounts that made the
        //  filtered cut and then SOSL stories but again we need to SOSL against the main Customer Story object to get the text search, and we
        //  don't have a way to limit the customer story search scope with just a list of account ids.
        
        // steps: 1. using account and story filters (if any) SOQL against Customer Story Account to get list without using keyword filter
        //        2. From this broader list, build list of story ids and run SOSL with keyword against that story list to get smaller list
        //        3. Finally we need to reduce the first SOQL result list from what was returned with SOSL keyword filter
        
        // 1. run the SOQL query to find customer story accounts that match all provided criteria - using both story and account filters
        // -- if they don't provide any filters we will get back all the customer story account links and could hit limits?
        
        List<List<sObject>> CustStoryAcctsearchresults = QueryObjects();
        
        // 2. now cycle through this list of Customer Story Account records to build a set of Customer Story Ids
        Set<Id> CustStoryIds = new Set<Id>();
        for(List<Sobject> soList : CustStoryAcctsearchresults){
            for(Sobject SO : soList){
                CustStoryIds.add((Id) so.get('customer_story__c'));    
            }
        }
      //  system.debug('our list of filtered cust stories before filtering by keyword: '+custstoryids);
        
        //  Build our simple SOSL query for the story Id where id in Cust Story Id set
        searchquery = 'FIND \''+String.escapeSingleQuotes(keyword)+'\' IN ALL FIELDS RETURNING Customer_Story__c (Id WHERE Id in :CustStoryIds)' ;

        //  Do the keyword search - here we have a limit of 2000 results for SOSL.  If we hit 2000 we need to use more filters on account/story to reduce results                                   
        List<List<SObject>>searchList;
        //system.debug(' about to run SOSL search: '+searchquery);
        if(validsearch){
            try{                    searchList=search.query(searchquery);   } 
            catch (Exception x){    apexpages.addmessages(x);               }
        }
        // 3. go into first element to pull out list of cust stories, then run through
        if (searchlist != null && searchlist.size() == 1) {
            // first check if the SOSL returned 2000 rows.  If so, show info message that they shoudl add more filters to reduce
            //    results set.  If no filters were applied we could have more than 2000 individual story records included in search
            if (searchlist[0].size() >=2000)
                apexpages.addmessage(new apexpages.message(apexpages.severity.info, 'Your search criteria returned over 2,000 stories. As a result, not all stories will be displayed.'));
           // system.debug('sosl results: '+searchlist[0]);
            // build set of stores returned from keyword filtering
            Set<Id> StoryIds = new Set<Id>();
            // cycle through results, pull in Story Id into set
            for (sobject s : searchlist[0]) {
                storyids.add((Id) s.get('Id'));
            }
           // system.debug('our list of storyids: '+storyids);
            // now cycle through the original (bigger) set of Cust Story Accounts that made the filtered SOQL and if it was also returned in the SOSL keyword search, add to the final list
            List<sObject> matching_CSA = new List<sobject>();

            for(List<Sobject> soList : CustStoryAcctsearchresults){
                for(Sobject SO : soList){
                    if (StoryIds.contains((Id) so.get('customer_story__c')))
                        matching_CSA.add(so);
                }
            }
            searchlist = new List<List<Sobject>>{matching_CSA};

          //  system.debug('returned records: '+searchlist);
            return searchlist;
                        
        }
        return searchList;
        
    }
    
//  SOQL Query (if keyword is empty)
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public List<List<sObject>> QueryObjects(){

        List<List<sObject>> queryResults = new List<List<sObject>>{};
        searchQuery = '';

        String queryStr;            
        
        if(searchType == 'info'){
            // search directly on Product__c table referencing account__r.name etc
            queryStr ='select '+objNameTOfields.get('Product__c')+', Products__c, Upgraded__c, Add_On_Module_s__c From Product__c';                           
            // add any account related filters
            if(objectLabelTOfilters().get('Account') != null){
                queryStr += ' WHERE '+objectLabelTOfilters().get('Account');
            }
            // add any product related filters
            if(objectLabelTOfilters().get('Product') != null){
                if(objectLabelTOfilters().get('Account') == null)
                    queryStr += ' WHERE '; else queryStr += ' AND ';
                queryStr += objectLabelTOfilters().get('Product');
            }           
            
        } else {

            queryStr ='select '+objNameTOfields.get('Customer_Story_Account__c')+' from Customer_Story_Account__c'; 
                                 
            if(objectLabelTOfilters().get('Customer Story') != null){
                queryStr += ' WHERE '+objectLabelTOfilters().get('Customer Story');
            }
            //system.debug('building SOQL with these filters on Account: '+  objectLabelTOfilters().get('Account')); 
            if(objectLabelTOfilters().get('Account') != null){
                // if we didn't have filters yet, add WHERE otherwise add an AND
                if(objectLabelTOfilters().get('Customer Story') == null)
                    queryStr += ' WHERE '; else queryStr += ' AND ';
                queryStr += objectLabelTOfilters().get('Account');
            }
            
        }
    
       // queryStr += ' order by account__r.name LIMIT 1000';
                
        searchQuery += queryStr+'\r\n';
        //system.debug('about to SOQL with this query : '+queryStr);
        if(validsearch){        
            try{                    QueryResults.add(database.query(queryStr));     } 
            catch (Exception x){    apexpages.addmessages(x);                       }   
        }
                        
        return queryResults;
                
    }
    
  
//  Do the search
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public PageReference doSearch(){
        results = FindResults();    
        return null;    
    }

//  Get the results
//  ------------------------------------------------------------------------------------------------------------------------------------
    public List<result>                     results         {get; set;}
    public Integer                          totalStories    {get; set;}
    public Integer                          totalStoryLinks    {get; set;}

     
    public List<result> FindResults(){
        
            results = new List<result>{};
            totalStories = 0;
            Set<Id> StoryIds = new Set<Id>();
            totalStoryLinks = 0;
            Set<Id> StoryLinkIds = new Set<Id>();
            // default search column/direction to account name ASC
            sortBy = 'Name'; 
            sortDir = 'ASC';
            
            List<List<sObject>> searchList;                     
            if(keyword != null && keyword != '' && searchType == 'story')  
                searchList = SearchObjects();  // keyword search only for story
            else searchList = QueryObjects();

                             
            if(searchList != null){             

                Map<Id, List<Customer_Story_Account__c>> acctTOstories = new Map<Id, List<Customer_Story_Account__c>>{};        
                Map<Id, List<Product__c>> acctTOprods = new Map<Id, List<Product__c>>{};        
                            
                for(List<Sobject> soList : searchList){
                
                    for(Sobject SO : soList){

                    //  Map products to account           
                        if(SO.getSObjectType() == Product__c.sObjectType){
                            Product__c prod = (Product__c)SO;
                            List<Product__c> added = new List<Product__c>{};
                            if(acctTOprods.get(prod.Account__c) != null)added.addAll(acctTOprods.get(prod.Account__c));
                            added.add(prod);
                            // sort prods for this account by name
                            added.sort();
                            if(prod.Account__c != null)acctTOprods.put(prod.Account__c, added);
                        } 
                                    
                    //  Map cust story account to account           
                        if(SO.getSObjectType() == Customer_Story_Account__c.sObjectType){
                            Customer_Story_Account__c story = (Customer_Story_Account__c)SO;
                            List<Customer_Story_Account__c> added = new List<Customer_Story_Account__c>{};
                            if(acctTOstories.get(story.Account__c) != null)added.addAll(acctTOstories.get(story.Account__c));
                            added.add(story);
                            // sort stories for this account by name
                            added.sort();
                            if(story.Account__c != null)acctTOstories.put(story.Account__c, added);
                            // add customer story and customer story account ids to sets for final count
                            StoryIds.add(story.customer_story__c);
                            StoryLinkIds.add(story.id);
                        }                           
                    } 
                }
                
                // set story sizes
                totalStories = storyids.size();
                totalStoryLinks = StoryLinkIds.size();
                
                if(acctTOstories.size() > 0){
                    for (Id aid :      acctTOstories.keyset()){
                        // customer story accounts were queried directly with all account fields through the account__r relationship field so pull that into Result
                        result r = new result(acctTOstories.get(aid)[0].account__r, acctTostories.get(aid));
                        results.add(r);
                   }        
                }
                if(acctTOprods.size() > 0){
                     for (Id aid :      acctTOprods.keyset()){
                        // products were queried directly with all account fields through the account__r relationship field so pull that into Result
                        result r = new result(acctTOprods.get(aid)[0].account__r , acctTOprods.get(aid));
                        results.add(r);
                    }        
                }
                                
                if(results.size() == 0 && validsearch){
                    Apexpages.Message noresults = new Apexpages.message(Apexpages.Severity.Info, 'No Results Found');
                    apexpages.addMessage(noresults);
                }
                sortlist(results);
            } 
        
        return results;
    }

    // fields to manage paging through results
    public integer pageNumber {get{if (pageNumber == null ) return 1; else return pageNumber;} set;}
    public integer totalPages {get{ return integer.valueof(math.ceil((double)results.size() / (double) pageSize));} set;}
    public integer pageSize {get {
        if (pageSize == null) return 50;
        return pageSize;} set;}
     
    public boolean getHasPrevious(){
        return (pageNumber != 1);
    }

    public boolean getHasNext(){
        return (pageNumber != totalPages);
    } 
    
    public pageReference Previous(){
        if (getHasPrevious())
            pageNumber--;
        return null;
    } 
    
    public pageReference Next(){
        if (getHasNext())
            pageNumber++;
        return null;
    }   
    
    // pageblocktable value, pulls the specific page of rows from the overall results list array for display
    public list<result> getRecords() {
        //system.debug('results size: '+results.size()+' and pagesize: '+pagesize);
        list<result> resultList = new list<result>();
        for (integer i=(pageNumber-1)*pageSize; i<(math.min(pageNumber*pageSize, results.size()));i++){
            resultList.add(results.get(i));
        }
        return resultList;
    } 
    
 
    // the column to sort results by and which direction (ASC, DESC)
    public String sortBy { get; set; }
    public String sortDir { get; set; }
 
    
    // called by clicking results table headers in results list
    public PageReference sortList() { 
        sortlist(results);
        return null; 
    } 
    
    // The sorting function works on results list sorting on any account field or the counts
    private List<result> sortList(List<result> cleanList) {

        // return the clean list if we don't have a sort field defined
        if (sortBy == null) { return cleanList; }
        // create an empty result List
        List<result> resultList = new List<result>();
        // and an object map which will be sorted
        Map<Object, List<result>> objectMap = new Map<Object, List<result>>();
        // now loop through the clean list and create the object map
        for (result item : cleanList) {
            // if sortBy is 'storiesCount' we are sorting by that value in each result
            if (sortBy == 'storiesCount') {
                if (objectMap.get(item.storiesCount) == null)
                    objectMap.put(item.storiesCount, new List<result>());
                // now add this record to the list for this sortby field value
                objectMap.get(item.storiesCount).add(item);            
            } 
            // otherwise we are referring to an Account field so go into the result's Account member
            else {
                // if we don't have a map entry for this items sortby field value, add it to the map
                if (objectMap.get(item.a.get(sortBy)) == null)
                    objectMap.put(item.a.get(sortBy), new List<result>());
                // now add this record to the list for this sortby field value
                objectMap.get(item.a.get(sortBy)).add(item);
            }
        }
        // get all the keys from the object map and sort them
        List<Object> keys = new List<Object>(objectMap.keySet());
        keys.sort();

        // now create a result list by adding all objects from the object map
        // in the sorted order
        for(Object key : keys) {
            resultList.addAll(objectMap.get(key));
        }
        // clear the clean list
        cleanList.clear();
        // depending on the direction add the items in the correct sorting to the clean list
        if (sortDir == 'ASC') {
          for (result item : resultList) {
            cleanList.add(item);
          }
        } else {
          for (Integer i = resultList.size()-1; i >= 0; i--) {
            cleanList.add(resultList[i]);
          }
        }
        // return the clean and now sorted list
        return cleanList;
    }    

//  Convert a set of strings to a string for dynamic soql
//  ------------------------------------------------------------------------------------------------------------------------------------
    // called to move list of multipicklist values into string with commas
    public static String setTOstr(Set<String> strings){
        String searchstr;
        for(String s : strings){
            if(searchstr != null)searchstr += ', \''+s+'\'';    
            if(searchstr == null)searchstr  = '\'' +s+'\''; 
        }       
        return searchstr;   
    }
    

//  Results wrapper
//  ------------------------------------------------------------------------------------------------------------------------------------
    public class result{
        public Account a {get; set;}        
        public List<Customer_Story_Account__c> stories {get; set;} 
        public List<Product__c> prods {get; set;}             
        public Integer storiesCount {get;set;}      
        public Boolean displaySub {get; set;}
        
        public result(Account passA, List<Customer_Story_Account__c> passStories){
            a = passA;
            stories = passStories;
            storiesCount = (passStories == null ? 0 : passStories.size());
            displaySub = (passStories != null  ? true : false);
            
        }                       

        public result(Account passA, List<Product__c> passProds){
            a = passA;
            prods = passProds;
            displaySub = (passProds!= null  ? true : false);
            
        }        
    }

//  Filter wrapper
//  ------------------------------------------------------------------------------------------------------------------------------------
    public class filter{
        public List<SelectOption> filterFields {get; set;}
        public List<SelectOption> filterOperators {get; set;}       
        public String helpText {get; set;}
        public List<SelectOption> selectedOptions {get; set;}
        
        public String selectedField {get; set;}
        public String selectedFieldType {get; set;}
        public String selectedOperator {get; set;}              
        public String selectedPickval {get; set;}                   
        public List<String> selectedPickvals {get; set;}        
        public String searchString {get; set;}       
        public Boolean valid {get; set;}    
        
        public Integer filterID {get; set;}
        
        public filter(List<Selectoption> passFilterFields, Integer passFilterID){
            filterFields = passFilterFields;
            filterID = passFilterID;
            valid = true;
        
        }
        
    }






}