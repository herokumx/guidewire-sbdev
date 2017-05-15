public with sharing class SearchStoryController {

/***************************************************************************************************************************************
    Class:          SearchStoryController
    
    Description:    Custom search for Customer_Information__c & Customer_Story__c objects
    
    Author:         Jeremy Henson
        
    Revision Hist:  J.Henson, 10/01/2012, Initial Version
****************************************************************************************************************************************/

//  Get Field Describe Info
//  ------------------------------------------------------------------------------------------------------------------------------------
    public Map<String, Schema.SobjectField> fieldMap;
    public Schema.DescribeFieldResult DescribeField(String fieldName){
    //  Split into object & field name
        List<String> fieldData = fieldName.split(':');      
    //  Get the right map
        Map<String, Schema.SobjectField> fieldTOdescribe = objectTOfieldmap().get(fieldData[0]);
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
    public Map<String, String> objNameTOfields = new Map<String, String>{
        'Customer_Information__c'   => 'id,name,Account__c,Account__r.Name,Region__c,LOBs__c,DWP_in_Millions__c', 
        'Product__c'                => 'id,name, Customer_Information__c'
    };  

//  Search type toggle (RUN ON PAGE LOAD)
//  ------------------------------------------------------------------------------------------------------------------------------------
    public PageReference SelectSearchType(){
    
    //  Clear the maps & filters
        objectTOfieldmap = null;
        clearFilters();
        objNameTOfields.clear();
        
    //  Add customer info which applies to both search types
        objNameTOfields.put('Customer_Information__c','id,name,Account__c,Account__r.Name,Region__c,LOBs__c,DWP_in_Millions__c');

    //  Select the object & pre-populate filters        
        if(searchType == 'info'){           
            objNameTOfields.put('Product__c','id,name, Customer_Information__c');
        } else {
            objNameTOfields.put('Customer_Story__c','id,name,AccountId__c,Story_Title__c,Story_Type__c,Products__c,Customer_Info_ID__c');
        }
        
    //  Set the default filters for the type  - no longer want filters defaulted - April 2013      
        //setDefaultFilters();
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
    

//  Default Filters
//  ------------------------------------------------------------------------------------------------------------------------------------
    public Map<String, List<String>> searchTypeTOdefaultFilters = new Map<String, List<String>>{
        'info'  => new List<String>{'Customer Information:Region','Customer Information:DWP (in Millions US$)','Customer Information:LOBs','Product:Product'}, 
        'story' => new List<String>{'Customer Story:Story Type','Customer Story:Products Involved','Customer Information:Region','Customer Information:DWP (in Millions US$)'}
    };  

//  Set Default Filters
//  ------------------------------------------------------------------------------------------------------------------------------------
    public void setDefaultFilters(){
                        
        filters = new List<filter>{};
        Integer i = 0;
                
        for(String s : searchTypeTOdefaultFilters.get(searchType)){                     
            AddFilter();
            filter f = idTOFilter.get(i);       
            currentFilterId = i;                    
            f.selectedField = s;
            SelectFilterType(); //  Once the field is selected, discover its type                                                   
            i++;                    
        }           
        
    }   
    
//  Generate Object Label to Field Map
//  ---------------------------------------------------------------------------------------------
    Map<String, Map<String, Schema.SobjectField>> objectTOfieldmap;
    public Map<String, Map<String, Schema.SobjectField>> objectTOfieldMap(){
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
        return objectTOfieldMap;
    }

//  Allowed Search Filters
//  ------------------------------------------------------------------------------------------------------------------------------------
    List<SelectOption> filterFields;
    public Map<String, Set<String>> objLabelTOallowedFilters = new Map<String, Set<String>>{
        'Customer Information'  => new Set<String>{'Region__c', 'LOBs__c', 'Distribution_Channel__c', 'DWP_in_Millions__c', 'Country__c', 'Account_Name__c'}, 
        'Product'               => new Set<String>{'Products__c','Upgraded__c','Product_Version__c', 'First_Go_Live_Date__c', 'Deal_Close_Date__c', 'Competition__c', 'Add_On_Module_s__c'},
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
             
            for(String key : objectTOfieldmap().keySet()){          
                Map<String, Schema.SobjectField> M = objectTOfieldmap().get(key);
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
    
    List<Selectoption> list3 = new List<Selectoption>{  new Selectoption('INCLUDES','INCLUDES')     };
    
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
        
        if(DescribeField(f.selectedField) != null){
            
        
            Schema.DescribeFieldResult describeF = DescribeField(f.selectedField);      
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
    
    //  Get the selected filter
        filter f = idTOfilter.get(currentFilterID);
        
    //  If a field has been selected, populate its data, otherwise clear it out
        if(f.selectedField != null && f.selectedField != ''){           
        
        //  Get the describe info
            Schema.DescribeFieldResult describeF;
            
        //  For Dist Channel which is a formula, grab the select options from the account field it references
        //  for all other fields, get the describe info
            if(f.selectedField == 'Customer Information:Distribution Channel'){
                describeF = Schema.sObjectType.Account.fields.Distribution_Channel__c;
            } else {
                describeF = DescribeField(f.selectedField);
            }
            
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
                if(f.selectedOperator == 'NOT LIKE')searchStr = '(NOT '+labelTOname.get(f.selectedField) + ' LIKE ';
                else searchStr = labelTOname.get(f.selectedField) + ' '+ f.selectedOperator+' ';
                
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
        
        if(!validsearch)apexpages.addmessage(invalidsearch);        
        return buildSearchFilters;
    }


//  SOSL Search (if keyword is populated, NOTE: we never use SOSL for Customer Info search type)
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public string searchQuery {get; set;}
    public String keyword {get; set;}
    public List<List<sObject>> SearchObjects(){
    
    //  Add the customer story search & filters
        searchquery = 'Customer_Story__c'+'('+objNameTOfields.get('Customer_Story__c');
        if(objectLabelTOfilters().get('Customer Story') != null)searchquery += ' WHERE '+objectLabelTOfilters().get('Customer Story')+' ';
        
    
    //  Add the customer info filters
        if(objectLabelTOfilters().get('Customer Information') != null){
            if(objectLabelTOfilters().get('Customer Story') == null)
            searchquery += ' WHERE'; else searchquery += ' AND';
            searchquery += ' Customer_Information__c in ('+ idsTOstr(StoryCustomerInfoIDs()) +')';
        }

    //  Close the search
        searchquery += ')'; 
        searchquery = 'FIND \''+String.escapeSingleQuotes(keyword)+'\' IN ALL FIELDS RETURNING ' + searchquery;

    //  Do the search                                   
        List<List<SObject>>searchList;
        if(validsearch){
            try{                    searchList=search.query(searchquery);   } 
            catch (Exception x){    apexpages.addmessages(x);               }
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
            
            queryStr ='select '+objNameTOfields.get('Customer_Information__c')+',  (Select Products__c, Upgraded__c, Add_On_Module_s__c From Products__r)  from Customer_Information__c';                           
            if(objectLabelTOfilters().get('Customer Information') != null){
                queryStr += ' WHERE '+objectLabelTOfilters().get('Customer Information');
            }
            
            if(objectLabelTOfilters().get('Product') != null){
                if(objectLabelTOfilters().get('Customer Information') == null)
                queryStr += ' WHERE'; else queryStr += ' AND';
                queryStr += ' id in ('+ idsTOstr(ProductCustomerInfoIDs()) +')';
            }           
            
        } else {

            queryStr ='select '+objNameTOfields.get('Customer_Story__c')+' from Customer_Story__c';                         
            if(objectLabelTOfilters().get('Customer Story') != null){
                queryStr += ' WHERE '+objectLabelTOfilters().get('Customer Story');
            }
            
            if(objectLabelTOfilters().get('Customer Information') != null){
                if(objectLabelTOfilters().get('Customer Story') == null)
                queryStr += ' WHERE'; else queryStr += ' AND';
                queryStr += ' Customer_Information__c in ('+ idsTOstr(StoryCustomerInfoIDs()) +')';
            }
            
        }
    
        queryStr += ' LIMIT 200';
                
        searchQuery += queryStr+'\r\n';
        
        if(validsearch){        
            try{                    QueryResults.add(database.query(queryStr));     } 
            catch (Exception x){    apexpages.addmessages(x);                       }   
        }
                        
        return queryResults;
                
    }
    
//  Get Products Sub Query (Return Customer Info IDs)
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public Set<Id> ProductCustomerInfoIDs(){
            
        Set<Id>ProductInfoIds = new Set<Id>{};
        
        //  Get search filters
            String prdSearchFilters = objectLabelTOfilters().get('Product');
            String querystr = 'Select Customer_Information__c from Product__c where '+prdSearchFilters;
            
        //  Query for products that match (if filters are valid)                    
            if(validsearch){                                    
                try{
                    for(Product__c p : Database.query(querystr))
                        ProductInfoIds.add(p.Customer_Information__c);
                }catch (Exception x){
                    apexpages.addmessages(x);
                }           
            }           
            
        return ProductInfoIds;      
    }
     
//  Get Customer Info Sub Query (Return Customer Info IDs)
//  ------------------------------------------------------------------------------------------------------------------------------------    
    public Set<Id> StoryCustomerInfoIDs(){
            
        Set<Id>StoryInfoIds = new Set<Id>{};
                                            
        //  Query for products that match
        String productfilters = objectLabelTOfilters().get('Customer Information');
        if(validsearch){
            try{                    
                for(Customer_Information__c CI : Database.query('Select Id from Customer_Information__c where '+productFilters)){
                    StoryInfoIds.add(CI.Id);
                }
            }catch (Exception x){
                apexpages.addmessages(x);
            }
        }                   
                        
        return StoryInfoIds;        
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
    public List<Customer_Information__c>    inforesults     {get; set;}
    public Integer                          totalStories    {get; set;}
    public Integer                          totalInfos      {get; set;}
     
    public List<result> FindResults(){
        
            inforesults = new List<customer_information__c>{};
            results = new List<result>{};
            totalStories = 0;
            totalInfos = 0;
            
            List<List<sObject>> searchList;                     
            if(keyword != null && keyword != '' && searchType == 'story')searchList = SearchObjects();  // keyword search only for story
            else searchList = QueryObjects();

            Set<Id>infoIDs = new Set<Id>{};
                             
            if(searchList != null){             

                Map<Id, List<Customer_Story__c>> acctTOstories = new Map<Id, List<Customer_Story__c>>{};        
                            
                for(List<Sobject> soList : searchList){
                
                    for(Sobject SO : soList){
                    
                    //  Customer Info Searches are not grouped
                        if(SO.getSObjectType() == Customer_Information__c.sObjectType){
                            Customer_Information__c CI = (Customer_Information__c)SO; 
                            inforesults.add(CI);                                                            
                        }   
            
                    //  Map cust story to account           
                        if(SO.getSObjectType() == Customer_Story__c.sObjectType){
                            Customer_Story__c story = (Customer_Story__c)SO;
                            List<Customer_Story__c> added = new List<Customer_Story__c>{};
                            if(acctTOstories.get(story.AccountId__c) != null)added.addAll(acctTOstories.get(story.AccountId__c));
                            added.add(story);
                            if(story.AccountId__c != null)acctTOstories.put(story.AccountId__c, added);
                            //  NOTE: total Stories count increases even if Story is not linked through Customer Info ID to Account, so will not show in results grid
                            totalStories++;
                        }                           
                        
                    }                   
                }
                
                if(searchType == 'story'){
                                                                    
                //  Add all the acct IDs to a single set                
                    Set<Id>acctIDs = new Set<Id>{};
                    acctIDs.addAll(acctTOstories.keySet());
                                            
                //  Query for all the accts (some might not have been returned by the original search)  
                    String queryStr = 'select Id, Name from Account where id in ('+ idsTOstr(acctIDs) +') order by name asc';
                    try{
                        for(Account a : Database.query(queryStr)){
                            result r = new result(a, acctTOstories.get(a.id));
                            results.add(r);     
                        }
                    } catch (Exception x){ 
                        Apexpages.addMessages(x); 
                    }
                }
                
                if((results.size() == 0 && inforesults.size() == 0) && validsearch){
                    Apexpages.Message noresults = new Apexpages.message(Apexpages.Severity.Info, 'No Results Found');
                    apexpages.addMessage(noresults);
                }
            } 
        
        return results;
    }
    
//  Convert a set of strings to a string for dynamic soql
//  ------------------------------------------------------------------------------------------------------------------------------------
    public static String idsTOstr(Set<Id> strings){
        Set<String> stringset = new Set<String>{};
        for(Id idStr : strings)stringset.add((String)idStr);
        return setTOstr(stringset);     
    }
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
        public List<Customer_Story__c> stories {get; set;}              
        public Integer storiesCount {get;set;}      
        public Boolean displaySub {get; set;}
        
        public result(Account passA, List<Customer_Story__c> passStories){
            a = passA;
            stories = passStories;
            storiesCount = (passStories == null ? 0 : passStories.size());
            displaySub = (passStories != null  ? true : false);
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