public class PSAMealsDailyCap {


Public Static boolean allow = true; 
public static void stopTrigger(){
    allow = false;
}

Public Static List<Id> getProjectsSpecifExpenses(List<pse__Expense__c> expenseList,Map<Id,Decimal> dailyCapProjectMap){ 
    List<pse__Expense__c> expenseListToVlaidateForCap = new  List<pse__Expense__c>();

    // get all projects Ids.
    List<ID> projIdList = new List<ID>();
    List<ID> expIdList = new List<ID>();
    for(pse__Expense__c expense : expenseList)
    {
       projIdList.add(expense.pse__Project__c);
       //&& expense.pse__Status__c != 'Rejected'
        if (expense.pse__Status__c!= null )
        {
           expenseListToVlaidateForCap.add(expense);
        }    
       expIdList.add(expense.Id);
    } 
    List<pse__Expense__c> expenseListVar  = [Select Id,pse__Expense_Date__c,pse__Project__c,pse__Status__c,pse__Type__c,pse__Amount__c    from pse__Expense__c where pse__Project__c in: projIdList  and  Id not in:expIdList];
    //and pse__Status__c != 'Rejected'
    for (pse__Expense__c exp: expenseListVar)
    {
       expenseListToVlaidateForCap.add(exp);
    }
    Map<String,List<pse__Expense__c>> expenseListMap  =  getExpenseListMap(expenseListToVlaidateForCap);

    List<Id> projectsOverCap = new List<Id>();
    Set<Id> projectsOverCapTemp = new Set<Id>();
    for (String key: expenseListMap.keySet())
    {       Decimal dailyExpenseCap = 0;  
            Decimal totalExpenseAmount = 0;
            List<string> dateProjectList = key.split('_');
            if (dateProjectList != null && dateProjectList.size()>0 && dailyCapProjectMap != null)
            {
              dailyExpenseCap = dailyCapProjectMap.get(dateProjectList[0]);
            }
            // get total billable amount.
            for (pse__Expense__c expense : expenseListMap.get(key))
            {  //expense.pse__Status__c != 'Rejected' &&
                if ((expense.pse__Type__c == 'GM - Meals Self' || expense.pse__Type__c == 'Meals - Self - Dinner' || expense.pse__Type__c == 'Meals - Self - Lunch'|| expense.pse__Type__c == 'Meals - Self - Breakfast'))
                {
                 totalExpenseAmount += expense.pse__Amount__c;  
                }          
            }
            if (totalExpenseAmount > dailyExpenseCap && dateProjectList != null && dateProjectList.size()>0 && dailyCapProjectMap != null)
            {
               projectsOverCapTemp.add(Id.valueOf(dateProjectList[0]));
            }
     }
        for (ID idval:  projectsOverCapTemp)
        { 
           projectsOverCap.add(idval);
        }
    return projectsOverCap;
} 

public Static Map<String,List<pse__Expense__c>> getExpenseListMap(List<pse__Expense__c> expenseList){
  
    Map<String,List<pse__Expense__c>> expenseListMap = new Map<String,List<pse__Expense__c>>();  
    for (pse__Expense__c expense : expenseList)
    {
        List<pse__Expense__c> tempseExpenseList = new  List<pse__Expense__c>();
        if (expenseListMap != null && expenseListMap.get(expense.pse__Project__c + '_' + String.valueOf(expense.pse__Expense_Date__c)) != null)
        {
          tempseExpenseList = expenseListMap.get(expense.pse__Project__c + '_' + String.valueOf(expense.pse__Expense_Date__c));                 
        }
        tempseExpenseList.add(expense);
        expenseListMap.put(expense.pse__Project__c + '_' +  String.valueOf(expense.pse__Expense_Date__c),tempseExpenseList);
    }

    return expenseListMap;
}

// update method to return map of ID and Exp Object for update.
public Static Map<Id,Decimal> getDailyCapMap(List<Id> projectList,Set<Id> resourceIdList, Set<Date> datelist, Map<Id,Decimal> dailyCapProjectMap,Set<Id> expIDSet){ 
    System.debug('dailyCapProjectMap>>>>' +dailyCapProjectMap );
    System.debug('projectList>>>>' +projectList ); 
     //and pse__Status__c != 'Rejected'
    List<pse__Expense__c> expenseList = [Select Id,PSA_Daily_Meals_Cap__c,pse__Project__r.currencyISOCode,currencyISOCode,pse__Amount__c,pse__Billing_Amount__c,pse__Billable_Amount__c,pse__Expense_Date__c,pse__Project__c,pse__Non_Billable_Incurred_Amount__c,pse__Type__c,pse__Status__c  from pse__Expense__c where pse__Project__c in : projectList  and pse__Resource__c in :resourceIdList and pse__Expense_Date__c in:datelist and    pse__Billable__c = true];  
    System.debug('expenseList>>>>' +expenseList );
    Map<String,List<pse__Expense__c>> expenseListMap  =  getExpenseListMap(expenseList);
    

    // add current expences marked as  Approved to expenseListMap

    Map<Id,Decimal>  dailyCapforExpenseMap = new   Map<Id,Decimal>();

        
    for (String key: expenseListMap.keySet())
    { 

        
            Decimal dailyExpenseCap = 0;  
            Decimal dailyExpenseOverLimit = 0;  
            Decimal totalExpenseAmount = 0;
            List<string> dateProjectList = key.split('_');
            if (dateProjectList != null && dateProjectList.size()>0 && dailyCapProjectMap != null)
            {
              dailyExpenseCap = dailyCapProjectMap.get(dateProjectList[0]);
            }
            // get total billable amount.
            Decimal conversionRate = 1;
            
            for (pse__Expense__c expense : expenseListMap.get(key))
            {   //only check against the approved expences.
                if (expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c != 0 && (expense.pse__Type__c == 'GM - Meals Self' || expense.pse__Type__c == 'Meals - Self - Dinner' || expense.pse__Type__c == 'Meals - Self - Lunch'|| expense.pse__Type__c == 'Meals - Self - Breakfast') && expense.pse__Status__c != null && (expense.pse__Status__c == 'Approved' || (expIDSet.size()> 0 && expIDSet.contains(expense.Id))))
                {                
                    totalExpenseAmount += expense.pse__Billing_Amount__c;             
                }           
            }
            System.debug('dailyExpenseCap>>>' + dailyExpenseCap);
            System.debug('totalExpenseAmount>>>' + totalExpenseAmount);
            System.debug('expenseListMap.get(key)>>>>>' + expenseListMap.get(key)); 
            System.debug('expIDSet>>>>>' + expIDSet); 
            
            dailyExpenseOverLimit =  totalExpenseAmount - dailyExpenseCap;

            Decimal conversionRateRev = 1;

            //subtract from GM - Meals Self
        if (dailyExpenseOverLimit > 0) 
            {  
               
                for (pse__Expense__c expense : expenseListMap.get(key))
                { 

                   // update only Expenses that are approved.
                    if (expIDSet.size()> 0 && expIDSet.contains(expense.Id))
                    {
                                if (expense.pse__Type__c !=null && expense.pse__Type__c == 'GM - Meals Self' &&  expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c > 0) 
                                {  
                                    if (expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c != 0)
                                    {
                                      conversionRateRev =  expense.pse__Billable_Amount__c/expense.pse__Billing_Amount__c;  
                                    }
                                   // conversionRateRev =  expense.pse__Billing_Amount__c/expense.pse__Billable_Amount__c;
                                   System.debug('conversionRateRev>>>>>' + conversionRateRev); 
                                    if (expense.pse__Billing_Amount__c >= dailyExpenseOverLimit)
                                    {
                                        dailyCapforExpenseMap.put(expense.Id,(dailyExpenseOverLimit * conversionRateRev).setScale(2));
                                        dailyExpenseOverLimit = 0;  
                                    }else{
                                    System.debug('conversionRateRev>>>>>4' + conversionRateRev); 
                                        dailyCapforExpenseMap.put(expense.Id,(expense.pse__Billing_Amount__c * conversionRateRev).setScale(2));
                                        dailyExpenseOverLimit = dailyExpenseOverLimit - (expense.pse__Billing_Amount__c * conversionRate).setScale(2);

                                    }
                                }
                     }
                 }  
            }


            // subtract from Dinner.
            if (dailyExpenseOverLimit > 0)
            {
                for (pse__Expense__c expense : expenseListMap.get(key))
                {  

                  // update only Expenses that are approved.
                    if (expIDSet.size()> 0 && expIDSet.contains(expense.Id))
                    {
                
                           if (expense.pse__Type__c !=null && expense.pse__Type__c == 'Meals - Self - Dinner' && expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c > 0 ) 
                            {  
                               if (expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c != 0)
                                {
                                  conversionRateRev =  expense.pse__Billable_Amount__c/expense.pse__Billing_Amount__c;  
                                }
                                if (expense.pse__Billing_Amount__c >= dailyExpenseOverLimit)
                                {
                                    dailyCapforExpenseMap.put(expense.Id,(dailyExpenseOverLimit * conversionRateRev).setScale(2));
                                    dailyExpenseOverLimit = 0;  
                                }else{
                                    dailyCapforExpenseMap.put(expense.Id,(expense.pse__Billing_Amount__c * conversionRateRev).setScale(2));
                                    dailyExpenseOverLimit = dailyExpenseOverLimit - (expense.pse__Billing_Amount__c * conversionRate).setScale(2);
                                }
                            }
                   }
                 }  
            }
            // subtract from Lunch.
            if (dailyExpenseOverLimit > 0)
            {
                for (pse__Expense__c expense : expenseListMap.get(key))
                {
                    // update only Expenses that are approved.
                    if (expIDSet.size()> 0 && expIDSet.contains(expense.Id))
                    {
                            if (expense.pse__Type__c !=null && expense.pse__Type__c == 'Meals - Self - Lunch' && expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c > 0 )
                            {
                               if (expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c != 0)
                                {
                                  conversionRateRev =  expense.pse__Billable_Amount__c/expense.pse__Billing_Amount__c;  
                                }
                                if (expense.pse__Billing_Amount__c >= dailyExpenseOverLimit)
                                {
                                    dailyCapforExpenseMap.put(expense.Id,(dailyExpenseOverLimit * conversionRateRev).setScale(2));
                                    dailyExpenseOverLimit = 0;  
                                }else{
                                    dailyCapforExpenseMap.put(expense.Id,(expense.pse__Billing_Amount__c * conversionRateRev).setScale(2));                                   
                                    dailyExpenseOverLimit = dailyExpenseOverLimit - (expense.pse__Billing_Amount__c * conversionRate).setScale(2);
                                    
                                }
                            }
                    }
                 }  
            }

            // subtract from Breakfast
            if (dailyExpenseOverLimit > 0)
            {
                for (pse__Expense__c expense : expenseListMap.get(key))
                {
                   // update only Expenses that are approved.
                    if (expIDSet.size()> 0 && expIDSet.contains(expense.Id))
                    {
                                if (expense.pse__Type__c !=null && expense.pse__Type__c == 'Meals - Self - Breakfast' && expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c > 0 )
                                {
                                    if (expense.pse__Billing_Amount__c != null && expense.pse__Billing_Amount__c != 0)
                                    {
                                      conversionRateRev =  expense.pse__Billable_Amount__c/expense.pse__Billing_Amount__c;  
                                    }
                                    if (expense.pse__Billing_Amount__c >= dailyExpenseOverLimit)
                                    {
                                        dailyCapforExpenseMap.put(expense.Id,(dailyExpenseOverLimit * conversionRateRev).setScale(2));
                                        dailyExpenseOverLimit = 0; 
                                    }else{
                                        dailyCapforExpenseMap.put(expense.Id,(expense.pse__Billing_Amount__c * conversionRateRev).setScale(2));
                                        dailyExpenseOverLimit = dailyExpenseOverLimit - (expense.pse__Billing_Amount__c * conversionRate).setScale(2);
                                    }   
                                }
                    }
                 } 
            }

  
    }
    System.debug('dailyCapforExpenseMap>>>>>>>>'+ dailyCapforExpenseMap);

    return dailyCapforExpenseMap;
    
   

}

@future
public static void updateExpenseReport(Set<Id> expReportIDSet){
    system.debug('expReportIDSet>>>>>'+ expReportIDSet);
    List<pse__Expense__c>  expList = [select Id,pse__Expense_Report__c, pse__Expense_Report__r.Id,pse__Billing_Amount__c,pse__Non_Billable_Amount__c,	pse__Exchange_Rate_Incurred_Currency__c,pse__Exchange_Rate_Billing_Currency__c from pse__Expense__c where pse__Expense_Report__c in: expReportIDSet];
	Map<Id,Decimal> billbaleAmtMap = new Map<Id,Decimal>();
	Map<Id,Decimal> nonBillbaleAmtMap = new Map<Id,Decimal>();
	for(pse__Expense__c exp: expList){
	     // add values to billbaleAmtMap
		  if(billbaleAmtMap.containskey(exp.pse__Expense_Report__r.Id)){		  
				billbaleAmtMap.put(exp.pse__Expense_Report__r.Id,(billbaleAmtMap.get(exp.pse__Expense_Report__r.Id) + exp.pse__Billing_Amount__c).setScale(2));
	      }else{
		        billbaleAmtMap.put(exp.pse__Expense_Report__r.Id,exp.pse__Billing_Amount__c.setScale(2));
		  }
		   // add values to non - billbaleAmtMap
          if(nonBillbaleAmtMap.containskey(exp.pse__Expense_Report__r.Id)){		  
				nonBillbaleAmtMap.put(exp.pse__Expense_Report__r.Id,(nonBillbaleAmtMap.get(exp.pse__Expense_Report__r.Id) + (exp.pse__Non_Billable_Amount__c/exp.pse__Exchange_Rate_Incurred_Currency__c * exp.pse__Exchange_Rate_Billing_Currency__c)).setScale(2));
	      }else{
		        nonBillbaleAmtMap.put(exp.pse__Expense_Report__r.Id,(exp.pse__Non_Billable_Amount__c/exp.pse__Exchange_Rate_Incurred_Currency__c * exp.pse__Exchange_Rate_Billing_Currency__c).setScale(2));
		  }
	} 


Boolean updateExpReport = false;
List<pse__Expense_Report__c> expReportToUpdate = [Select id,pse__Total_Billable_Amount__c,pse__Total_Non_Billable_Amount__c from  pse__Expense_Report__c where Id IN:billbaleAmtMap.keySet()];
for(pse__Expense_Report__c expReport : expReportToUpdate){
   if(billbaleAmtMap.size()> 0 && nonBillbaleAmtMap.size()>0){
	   expReport.pse__Total_Billable_Amount__c = billbaleAmtMap.get(expReport.Id);
	   expReport.pse__Total_Non_Billable_Amount__c = nonBillbaleAmtMap.get(expReport.Id);
	   updateExpReport = true;
   }
}

if(updateExpReport){
 Database.update(expReportToUpdate);
}

}
  


}