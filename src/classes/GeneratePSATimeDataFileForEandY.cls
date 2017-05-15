//--------------------
// REST API to send Time Card data for E&Y.
// Date: 6/23/2015
// Author: Rohit Koul
//--------------------

@RestResource(urlMapping='/creatEandYExcelDataFile/*')
global class GeneratePSATimeDataFileForEandY {
	
  @HttpGet
  global static List<PSATimeCard> doGet() {
  	 if(System.now().month() == 1){
  	 	return formPSATimeCardDataSet(12,System.now().year()-1);
     }else{
  	   return formPSATimeCardDataSet(System.now().month()-1,System.now().year());
  	 }
  }
  
  @HttpPost
  global static List<PSATimeCard> getMonthSpecificData(String month,String year) {
  	 return formPSATimeCardDataSet(Integer.valueof(month),Integer.valueof(year));
  }
  
  global static List<pw_cc__CountryObject__c> countryList = [select Id,Name,pw_cc__IsoCode_2__c from pw_cc__CountryObject__c]; 
  global static Map<String,String> getCountryISOCodeMap(){
	   Map<String,String> countryMap = new Map<String,String>();
	   for(pw_cc__CountryObject__c countryVar : countryList){
	      countryMap.put(countryVar.Name,countryVar.pw_cc__IsoCode_2__c);
	   }
	   return countryMap;
  }  
  
  global static List<pw_cc__State__c> stateList = [select Id,Name,pw_cc__IsoCode__c from pw_cc__State__c]; 
  global static Map<String,pw_cc__State__c> getStateISOCodeMap(){
	   Map<String,pw_cc__State__c> stateMap = new Map<String,pw_cc__State__c>();
	   for(pw_cc__State__c stateVar : stateList){
	      stateMap.put(stateVar.Name,stateVar);
	   }
	   return stateMap;
  }  
  
  global class PSATimeCard{
	    public string Company{get; set;}  
	    public string Business_Unit{get; set;}  
	    public string Employee_Id{get; set;}  
	    public string Employee_Name{get; set;}   
	    public Date Work_Date{get; set;} 
	    public Integer Days{get; set;}  
	    public string Work_Country{get; set;} 
	    public string Work_State_Province_Canton{get; set;} 
	    public string File_ID{get; set;} 
   }
   
   
   global static List<PSATimeCard> formPSATimeCardDataSet(Integer month,Integer Year){
        List<PSATimeCard> psaTimeCardList = new List<PSATimeCard>(); 
        system.debug('month>>'+ month + 'Year>>>' + Year);
       //  1. Summary Period for Last month filter.    //9  d) Consider only last months values for TimeCard. // 2. Time Card Status as Approved.
	   	String baseQuery = 'Select ID,Name,pse__Day_Of_Week__c,pse__Timecard__r.PSA_Work_Location_Country__c,pse__Timecard__r.PSA_Work_Location_State__c,PSA_Timecard_Split__r.pse__Status__c,pse__Date__c,PSA_Timecard_Split__r.pse__Project__r.pse__Project_Type__c,PSA_Timecard_Split__r.pse__Approved__c,PSA_Timecard_Split__r.pse__Resource__r.PSA_Resource_Entity__c, PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_First_Name__c,PSA_Timecard_Split__r.pse__Resource__r.Middle_Initial__c, PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_Last_Name__c, PSA_Timecard_Split__r.pse__Resource__r.PSA_Resource_Entity__r.PSA_Entity_Code__c,PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c,PSA_Timecard_Split__r.pse__Resource__r.FirstName,PSA_Timecard_Split__r.PSA_Billable_Hours__c,PSA_Billable_hours__c, PSA_Timecard_Split__r.pse__Resource__r.LastName,PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c, PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_Country__c, PSA_Timecard_Split__r.pse__Timecard_Header__c, PSA_Timecard_Split__r.pse__Start_Date__c, PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Type__c, PSA_Timecard_Split__r.pse__Resource__c, PSA_Timecard_Split__r.pse__Project__r.pse__Project_ID__c, PSA_Timecard_Split__r.pse__Project__r.pse__Parent_Project__c, PSA_Timecard_Split__r.pse__Project__r.Name, PSA_Timecard_Split__r.pse__Project__c,PSA_Timecard_Split__r.pse__End_Date__c, PSA_Timecard_Split__r.Name, PSA_Timecard_Split__r.Id,PSA_Timecard_Split__r.pse__Resource__r.PSA_Home_State__r.pw_cc__IsoCode__c From  pse__Time_Date__c  where pse__Timecard__r.pse__Approved__c = true and ';
	  //  baseQuery += ' CALENDAR_YEAR(pse__Date__c) = ' +Year+  ' and  CALENDAR_MONTH(pse__Date__c) = ' + month +' and ';
	  baseQuery += ' CALENDAR_YEAR(pse__Date__c) = ' +Year+  ' and  CALENDAR_MONTH(pse__Date__c) = ' + month +' and ';
	   
	    // 5. Excluding Contingent Workers                     
	    baseQuery += GWUtilities.appendStringValuesToBaseQuery('PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Type__c', 'Contingent Worker','and','!=',false);
	 //   baseQuery += GWUtilities.appendStringValuesToBaseQuery('PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Type__c', 'Contingent','and','!=',false);
	  	//9 a. Exclude timecard records with project type value "Time Off"
	  	baseQuery += GWUtilities.appendStringValuesToBaseQuery('PSA_Timecard_Split__r.pse__Project__r.pse__Project_Type__c', 'Time Off','and','!=',false);
	  	
	  	
	  	// 7. Exclude Sat and Sundays.
	  	baseQuery += GWUtilities.appendStringValuesToBaseQuery('pse__Day_Of_Week__c', 'Saturday','and','!=',false);
	  	baseQuery += GWUtilities.appendStringValuesToBaseQuery('pse__Day_Of_Week__c', 'Sunday','and','!=',true);
	     
       // 10 a)  If multiple locations select location with most hours and b) if multiple locations with same hours select fisrt location entered as per time stamp, if time stamp blank or same then chose non-home location. 
	    Map<String,List<pse__Time_Date__c>>  workerIDDateMap = new  Map<String,List<pse__Time_Date__c>>(); 
	    
	    for(pse__Time_Date__c pseTimeDate: Database.Query(baseQuery)){
	    	 	 // 9 b. Exclude some non tax states from timecard.
	   	 // NOt using project ID as its an auto number and subjected to change - && PSA_Timecard_Split__r.pse__Project__r.pse__Project_ID__c == 'PR-000020'
	   	 String test ='new';
	   	 if(!(pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Type__c !=null && pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Type__c == 'Employee' && pseTimeDate.PSA_Timecard_Split__r.pse__Project__r.Name != null && pseTimeDate.PSA_Timecard_Split__r.pse__Project__r.Name == 'Professional Development' &&  pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c != null && ( pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c == 'Arizona' || pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c == 'Connecticut' || pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c == 'Massachusetts' || pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c == 'Maine' || pseTimeDate.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c == 'New York' )) ){
	   	
	    	String workerIDDateConcat =  pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c + String.valueof(pseTimeDate.pse__Date__c);
	    	List<pse__Time_Date__c> pseTimeDateTempList = new List<pse__Time_Date__c>();
	    	If(pseTimeDate.pse__Date__c != null && workerIDDateConcat != null && workerIDDateMap.containsKey(workerIDDateConcat)){
	    	     pseTimeDateTempList.addAll(workerIDDateMap.get(workerIDDateConcat));
                pseTimeDateTempList.add(pseTimeDate);
                 workerIDDateMap.put(workerIDDateConcat,pseTimeDateTempList);
	    	}else{
                 pseTimeDateTempList.add(pseTimeDate);
	    		 workerIDDateMap.put(workerIDDateConcat,pseTimeDateTempList);
	    	}
	   	 }
	   }
       
       // 10 a) filter locations with least hours.
       Set<Id> filterIds = new Set<Id>();
       for(String Key : workerIDDateMap.keySet()){
           if(workerIDDateMap.get(key).size()>1){
               for(pse__Time_Date__c pseTimeDateVar1:  workerIDDateMap.get(key)){
                  for(pse__Time_Date__c pseTimeDateVar2:  workerIDDateMap.get(key)){
                      if(pseTimeDateVar2.PSA_Billable_hours__c < pseTimeDateVar1.PSA_Billable_hours__c){
                         filterIds.add(pseTimeDateVar2.Id);
                      }
                  }
               }
          }
       }
       
       for(String Key : workerIDDateMap.keySet()){
           if(workerIDDateMap.get(key).size()>1){
               List<pse__Time_Date__c> newPSETimeDate = new List<pse__Time_Date__c>();
               for(pse__Time_Date__c pseTimeDateVar:  workerIDDateMap.get(key)){
                   if(!filterIds.contains(pseTimeDateVar.Id)){
                      newPSETimeDate.add(pseTimeDateVar);    
                   }
                }
               workerIDDateMap.put(Key,newPSETimeDate);
          }
       }
       
       // 10 b) choose fist time entry entered if same hours.
        Set<Id> filterIdSetSameHours = new Set<Id>();
        for(String Key : workerIDDateMap.keySet()){
             for(pse__Time_Date__c pseTimeDateVar1:  workerIDDateMap.get(key)){
                  for(pse__Time_Date__c pseTimeDateVar2:  workerIDDateMap.get(key)){
                      // No Time stamp concept here 
                      //if(pseTimeDateVar2.PSA_Billable_hours__c == pseTimeDateVar1.PSA_Billable_hours__c && pseTimeDateVar1.pse__Date__c != null && pseTimeDateVar2.pse__Date__c != null && pseTimeDateVar2.pse__Date__c < pseTimeDateVar1.pse__Date__c){
                       //  filterIdSetSameHours.add(pseTimeDateVar2.Id);
                      // }
                       if(pseTimeDateVar2.PSA_Billable_hours__c == pseTimeDateVar1.PSA_Billable_hours__c && pseTimeDateVar2.PSA_Timecard_Split__r.pse__Timecard_Header__r.PSA_Work_Location_State__c != pseTimeDateVar2.PSA_Timecard_Split__r.pse__Resource__r.PSA_Home_State__r.pw_cc__IsoCode__c){
                           filterIdSetSameHours.add(pseTimeDateVar2.Id);  
                       }    
                  }
               }  
        }    
            
       List<pse__Time_Date__c> newPSETimeDate2 = new List<pse__Time_Date__c>();
       for(String Key : workerIDDateMap.keySet()){
           if(workerIDDateMap.get(key).size()>1){
               List<pse__Time_Date__c> newPSETimeDate = new List<pse__Time_Date__c>();
               for(pse__Time_Date__c pseTimeDateVar:  workerIDDateMap.get(key)){
                   if(!filterIdSetSameHours.contains(pseTimeDateVar.Id)){
                      newPSETimeDate2.add(pseTimeDateVar);    
                   }
                }
               workerIDDateMap.put(Key,newPSETimeDate);
          }
       }
       
       List<pse__Time_Date__c> timeDateResultList = new List<pse__Time_Date__c>();
      
       for(String Key : workerIDDateMap.keySet()){
           for(pse__Time_Date__c pseTimeDateVar:  workerIDDateMap.get(key)){
              timeDateResultList.add(pseTimeDateVar);
           }    
       }
       
       // 9 e) Consider first 22 days only for worker. Truncate 23rd day if included.
       Map<String,List<pse__Time_Date__c>> workerIDTimeDateMap = new Map<String,List<pse__Time_Date__c>>();
       Set<Id> filter23rdDay = new Set<Id>();
       
       for(pse__Time_Date__c  timeDateVar: timeDateResultList){
           List<pse__Time_Date__c> pseTimeDateList = new List<pse__Time_Date__c>();
           if(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c != null && workerIDTimeDateMap.containsKey(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c)){
               pseTimeDateList.add(timeDateVar);
               pseTimeDateList.addAll(workerIDTimeDateMap.get(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c));
               workerIDTimeDateMap.put(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c,pseTimeDateList);
           }else if(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c != null){
               pseTimeDateList.add(timeDateVar);
               workerIDTimeDateMap.put(timeDateVar.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c,pseTimeDateList);
           }
       }
       
       for(String Key : workerIDTimeDateMap.keySet()){
           if(workerIDTimeDateMap.get(key).size() > 22){
               Id idval = null; 
               for(pse__Time_Date__c pseTimeDateVar1:  workerIDTimeDateMap.get(key)){
                     for(pse__Time_Date__c pseTimeDateVar2:  workerIDTimeDateMap.get(key)){
                         if(pseTimeDateVar2.pse__Date__c > pseTimeDateVar1.pse__Date__c ){
                             idval =  pseTimeDateVar2.Id;
                         }
                     }
              }
              if(idval != null){
                    filter23rdDay.add(idval); 
              } 
          }
       
       }
       List<pse__Time_Date__c> timeDateResultListFinal = new List<pse__Time_Date__c>();
       for(String Key : workerIDTimeDateMap.keySet()){
          for(pse__Time_Date__c pseTimeDateVar:  workerIDTimeDateMap.get(key)){
              if(!filter23rdDay.contains(pseTimeDateVar.Id)){
                  timeDateResultListFinal.add(pseTimeDateVar);
              }
          }
       }
       
       Map<String,String> countryMap = getCountryISOCodeMap();
       Map<String,pw_cc__State__c> stateMap = getStateISOCodeMap();
       
	   	for(pse__Time_Date__c pseTimeDate: timeDateResultListFinal){
	   		
	   		  PSATimeCard psaTimeCardVar = new PSATimeCard();
	   		   psaTimeCardVar.Company = 'Guidewire';
	   		   psaTimeCardVar.Business_Unit = '';  
	   		  if(pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Resource_Entity__r.PSA_Entity_Code__c != null){
	   		  	 Integer entityCode = Integer.valueof(pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Resource_Entity__r.PSA_Entity_Code__c);
	   		     if(entityCode >= 10 && entityCode <= 39){
	   		     	psaTimeCardVar.Business_Unit = 'AMER';
	   		     }else  if(entityCode >= 40 && entityCode <= 69){
	   		     	psaTimeCardVar.Business_Unit = 'EMEA';
	   		     }else  if(entityCode >= 70 && entityCode <= 89){
	   		     	psaTimeCardVar.Business_Unit = 'APAC';
	   		     } 
	   		  }
	   		  
	   		  psaTimeCardVar.Employee_Id = pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Worker_Id__c;
	  	      if(pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.Middle_Initial__c != null){
	  	      psaTimeCardVar.Employee_Name = pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_Last_Name__c + ', ' + pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_First_Name__c + ' ' + pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.Middle_Initial__c;
	  	      }else{
	  	       if(pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_Last_Name__c != null && pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_First_Name__c != null){
	  	     		  psaTimeCardVar.Employee_Name = pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_Last_Name__c + ', ' + pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.PSA_Legal_First_Name__c;
	  	       }else{
	  	      		  psaTimeCardVar.Employee_Name = pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.LastName + ', ' + pseTimeDate.PSA_Timecard_Split__r.pse__Resource__r.FirstName;
	  	       }
	  	     }
	          psaTimeCardVar.Work_Date = pseTimeDate.pse__Date__c;
	  	      psaTimeCardVar.Days= 1;
	  	      psaTimeCardVar.Work_Country = pseTimeDate.pse__Timecard__r.PSA_Work_Location_Country__c;  
	  	      psaTimeCardVar.Work_State_Province_Canton =  pseTimeDate.pse__Timecard__r.PSA_Work_Location_State__c;
	  	      psaTimeCardVar.File_ID = '';
	  	     
	  	      if(psaTimeCardVar.Work_Country != null && psaTimeCardVar.Work_State_Province_Canton != null){
	  	     	if(countryMap.containsKey(psaTimeCardVar.Work_Country)){
			  	      	psaTimeCardVar.Work_Country = countryMap.get(psaTimeCardVar.Work_Country);
			  	      	if(stateMap.containsKey(psaTimeCardVar.Work_State_Province_Canton)){
			  	      	  if(psaTimeCardVar.Work_Country == 'US' || psaTimeCardVar.Work_Country == 'CA'){	
			  	      	    psaTimeCardVar.Work_State_Province_Canton = stateMap.get(psaTimeCardVar.Work_State_Province_Canton).pw_cc__IsoCode__c;
			  	      	  }else{
			  	      	   	psaTimeCardVar.Work_State_Province_Canton = stateMap.get(psaTimeCardVar.Work_State_Province_Canton).Name;
			  	      	  }	
			  	      	  psaTimeCardList.add(psaTimeCardVar);
	  	      	      	}else if(psaTimeCardVar.Work_Country != 'US' && psaTimeCardVar.Work_Country != 'CA'){
	  	      	      	  psaTimeCardVar.Work_State_Province_Canton = '';
	  	      	      	  psaTimeCardList.add(psaTimeCardVar);
	  	      	      	}
	  	      	} 
	  	      }else if(psaTimeCardVar.Work_Country != null && countryMap.containsKey(psaTimeCardVar.Work_Country) && (psaTimeCardVar.Work_State_Province_Canton == null || !stateMap.containsKey(psaTimeCardVar.Work_State_Province_Canton))){
	  	        if(psaTimeCardVar.Work_Country != 'US' && psaTimeCardVar.Work_Country != 'CA'){
	  	            psaTimeCardVar.Work_Country = countryMap.get(psaTimeCardVar.Work_Country);
	  	             psaTimeCardVar.Work_State_Province_Canton = '';
	  	             psaTimeCardList.add(psaTimeCardVar);
	  	        }
	  	      }
	  	   }	   
	  	      
	  	return psaTimeCardList;
	}
	
	
}