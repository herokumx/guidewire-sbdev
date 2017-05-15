/****************************************************************************************
Name            : psaProjectForecastCalculation
Author          : CLD
Created Date    : April 29, 2015
Description     : For scheduled batch execution of project forecast calculations
                : 
******************************************************************************************/
global with sharing class psaProjectForecastCalculation 
{
    public psaProjectForecastCalculation() {}

    public static void removeDuplicateEvAs (List<Id> projectIds){
        String mapKey;
        Map<String, Id> evaMap = new map<string, id>(); // Key is "assignment Id + time Period Id"
        List<pse__Est_Vs_Actuals__c> evaDupList = new List<pse__Est_Vs_Actuals__c>();
        //System.debug('Project Ids: ' + projectIds);

        for(pse__Est_vs_Actuals__c eva : 
           [
               select id, Name,
                        pse__Assignment__c, pse__Assignment__r.Name,PSA_Resource_Request__c,PSA_Resource_Request__r.Name,
                        pse__Project__c, pse__Project__r.Name, PSA_Source__c, 
                        pse__Time_Period__c, pse__Time_Period__r.Name
               from pse__Est_vs_Actuals__c
               where pse__Time_Period__c <> '' AND pse__Project__c in :projectIds
               order by createddate
           ])
        {
            if (eva.PSA_Source__c == 'Assignment') {
                mapKey = eva.pse__Project__c + '|' + eva.pse__Assignment__c + '|' + eva.pse__Time_Period__c;
            } else if (eva.PSA_Source__c == 'Resource Request') {
                mapKey = eva.pse__Project__c + '|' + eva.PSA_Resource_Request__c + '|' + eva.pse__Time_Period__c;
            } else {
                mapKey = 'invalid source';
            }

            if(evaMap.containsKey(mapKey))
            {
                System.debug('Found Duplicate EVA: ' + eva);

                pse__Est_vs_Actuals__c tmpEvA = new pse__Est_vs_Actuals__c(
                    id = eva.id);               
                evaDupList.add(tmpEvA);
            }
            else
            {
                // Not a dup (yet) so add to the Map
                evaMap.put(mapKey, eva.id);
            }           
        }

        if(evaDupList.size() > 0)
        {
            System.debug('Deleting ' + evaDupList.size() + ' duplicates. ' + evaDupList);
            delete evaDupList;
        }
    }

    /**************************************************************************************
    // Name        : calculateBillingForecast
    // Description : Performs Billing Forecast calculation for one or more projects.
    //               NOTE: The list of projects passed in should be already filtered to
    //               include those that are eligible for billing forecast calculation, determined
    //               based on their Include in Billing forecast field, etc. 
    //
    ***************************************************************************************/
    public static void calculateBillingForecast(List<Id> projectIds)
    {
        //ADDED 3/9/17 BY CLD TO DELETE ANY DUPLICATE EVAS THAT EXIST
        removeDuplicateEvAs(projectIds);

        Date currentMonthStart = Date.Today().toStartOfMonth();
        Map <String, PSA_Project_Forecast__c> projectForecastMap = new Map<String, PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> forecastsForExclusion = new List<PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> forecastsForZero = new List<PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> forecastsForInsert = new List<PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> forecastsForUpdate = new List<PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast_Detail__c> forecastDetailsForInsert = new List<PSA_Project_Forecast_Detail__c>();
        List <PSA_Project_Forecast_Detail__c> forecastDetailsForDelete = new List<PSA_Project_Forecast_Detail__c>();
        Map<String,Double> conversionRateMap = new Map<String,Double>();

        // Get Month time periods from current month onward
        List <pse__Time_Period__c> upcomingTimePeriods = [
            SELECT Id, Name, pse__Start_Date__c, pse__End_Date__c, PSA_Seasonality_Factor__c
              FROM pse__Time_Period__c
             WHERE pse__Type__c = 'Month'
               AND pse__End_Date__c >= TODAY
             ORDER BY pse__Start_Date__c];

        // Get percentages for forecast categories from custom setting
        Map<String, Decimal> forecastPercentMap = new Map<String, Decimal>();
        PSA_Forecast__c forecastSettings = PSA_Forecast__c.getOrgDefaults();
        Decimal salesPercent=0,upsidePercent=0,piplinePercent=0,forecastPercent=0,committedPercent=0;
        if(forecastSettings != null)
        {
            salesPercent = forecastSettings.PSA_Forecast_Category_Percent_Sales__c;
            upsidePercent = forecastSettings.PSA_Forecast_Category_Percent_Upside__c;
            piplinePercent = forecastSettings.PSA_Forecast_Category_Percent_Pipeline__c;
            forecastPercent = forecastSettings.PSA_Forecast_Category_Percent_Forecast__c;
            committedPercent = forecastSettings.PSA_Forecast_Category_Percent_Committed__c;
        }
        forecastPercentMap.put('Sales', salesPercent);
        forecastPercentMap.put('Upside', upsidePercent);
        forecastPercentMap.put('Pipeline', piplinePercent);
        forecastPercentMap.put('Forecast', forecastPercent);
        forecastPercentMap.put('Committed', committedPercent);

        // Get current day currency conversion rates in case we need to convert EvA cost amounts from 
        // resource currency to project currency
        for(CurrencyType curr: [SELECT IsoCode,ConversionRate FROM CurrencyType WHERE isActive = True])
        {
            conversionRateMap.put(curr.IsoCode, curr.ConversionRate);
        }

        // Get info about the projects, along with related information from Fixed Fee Services milestones,
        // Est vs Actuals, Discount, Holdback, and Expenses
        // Changed below Query to include PSA_Milestone_Type__c = 'Billable Expenses - Fixed' 
        List<pse__Proj__c> projects = [
        SELECT Id, CurrencyIsoCode, pse__Project_Id__c, pse__Is_Active__c, PSA_Include_in_Billing_Forecast__c, PSA_Forecast_Category__c,
               pse__Start_Date__c, pse__End_Date__c, pse__Stage__c, pse__Is_Billable__c,
               pse__Billing_Type__c, pse__Expense_Budget__c, PSA_BR_Expenses_Billing_Type__c,
               PSA_BR_Expense_Amt_Per_Day__c, PSA_BR_Billing_Levels_for_Expense_Amt__c, PSA_BR_Expense_Pct_of_Services__c, PSA_BR_Billing_Levels_for_Expense_Pct__c,
               PSA_BR_Account_Discount_Applies__c, PSA_BR_Account_Discount__r.PSA_Discount_Active__c, PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c,
               PSA_BR_Account_Discount__r.PSA_Discount_Cap__c, PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c, PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c, 
               PSA_BR_Account_Discount__r.PSA_Discount_Percent__c, PSA_BR_Holdback_Applies__c, PSA_BR_Holdback_End_Date__c, 
               PSA_BR_Holdback_Pct__c, PSA_BR_Holdback_Applied_To_Date__c,
               (SELECT Id, Name, pse__Project__c, PSA_Milestone_Type__c, pse__Target_Date__c, pse__Status__c, pse__Actual_Date__c, pse__Milestone_Amount__c 
                  FROM pse__Milestones__r
                 WHERE (PSA_Milestone_Type__c = 'Billable Services - Fixed' OR  PSA_Milestone_Type__c = 'Billable Expenses - Fixed')
                   AND pse__Target_Date__c >= THIS_MONTH
                   AND ( pse__Actual_Date__c = null or pse__Actual_Date__c > Today) ),
               (SELECT Id, Name, pse__Project__c, pse__Start_Date__c, pse__End_Date__c, PSA_Source__c, PSA_Forecast_Category__c, 
                       PSA_Estimated_Billings__c, PSA_Estimated_Cost__c, PSA_Cost_Currency_Code__c, pse__Estimated_Days__c, pse__Estimated_Hours__c,
                       pse__Scheduled_Bill_Rate__c, pse__Time_Period_Type__c, pse__Time_Period__r.PSA_Seasonality_Factor__c, 
                       pse__Actual_Billable_Amount__c, PSA_Actual_Cost__c, pse__Actual_Days__c, pse__Actual_Hours__c, PSA_Billing_Level__c,
                       PSA_Resource_Request__r.Name, PSA_Resource_Request__r.PSA_Billing_Level__c, PSA_Resource_Request__r.pse__Resource_Role__c, PSA_Resource_Request__r.PSA_Part_Time__c,
                       pse__Assignment__r.pse__Assignment_Number__c, pse__Assignment__r.pse__Resource__r.Name, pse__Assignment__r.PSA_Part_Time__c, 
                       pse__Assignment__r.pse__Resource__c, PSA_Resource_Request__r.pse__Staffer_Resource__c, PSA_Resource_Request__r.pse__Requested_Bill_Rate__c
                  FROM pse__Est_Vs_Actuals__r
                 WHERE pse__Time_Period_Type__c = 'Month'
                   AND PSA_Forecast_Category__c != 'Upside'
                   AND pse__End_Date__c >= THIS_MONTH
                   AND PSA_Source__c != 'NONE')
          FROM pse__Proj__c
         WHERE Id = :projectIds
           AND pse__Start_Date__c != null
         ORDER BY pse__Project_Id__c];

        // Get PSA Project Forecast records with the following criteria
        // For Project Id's supplied
        // Current month or future OR past month and Include in Forecast is True
        List<PSA_Project_Forecast__c> forecasts = [
        SELECT Id, 
               PSA_Include_in_Forecast__c,
               PSA_Time_Period__c,
               PSA_For_Month_Ending__c,
               CurrencyIsoCode,
               PSA_Project__r.pse__Project_Id__c,
               PSA_Item_Key__c,
               (SELECT Id, Name, PSA_Item_Key__c,
                       PSA_Forecast_Category__c, PSA_Forecast_Category_Percent__c, PSA_Forecast_Source__c, PSA_Forecast_Type__c, PSA_Include_in_Forecast__c,
                       PSA_Scheduled_Billings__c, PSA_Scheduled_Cost__c, PSA_Scheduled_Days__c, PSA_Scheduled_Hours__c, PSA_Scheduled_Time_Billings__c, 
                       PSA_Seasonality_Factor__c, PSA_Resource__c, PSA_Est_Vs_Actuals__c, PSA_Scheduled_Bill_Rate__c
                  FROM PSA_Project_Forecast_Details__r)
          FROM PSA_Project_Forecast__c 
         WHERE PSA_Project__c = :projectIds
           AND (PSA_For_Month_Ending__c >= TODAY OR (PSA_For_Month_Ending__c < TODAY AND PSA_Include_in_Forecast__c = True))
         ORDER BY PSA_Project__r.pse__Project_Id__c, PSA_For_Month_Ending__c];

        // Iterate through existing forecasts.  Put them in a map, and put all the detail items in a map
        // Set past project forecasts for exclusion from billing forecasting
        for(PSA_Project_Forecast__c existingPF : forecasts)
        {
            if(existingPF.PSA_For_Month_Ending__c < currentMonthStart)
            {
                existingPF.PSA_Include_in_Forecast__c = false;

                forecastsForExclusion.add(existingPF);
            }
            else
            {
                projectForecastMap.put(existingPF.PSA_Item_Key__c, existingPF);
            }
        }

        // Iterate through the Projects and calculate the billing forecast for each
        for(pse__Proj__c project : projects)
        {
            String servicesBillingType = project.pse__Billing_Type__c;
            String projectCurrency = project.CurrencyIsoCode;

            // GET THE START AND END DATES THAT DEFINE THE FORECAST RANGE
            // Start of range = Start of current month
            // End of range = Latest of: Project End Date, Last Assignment End Date, Last RR End Date, Billing Milestone Target Date, Holdback End Date (if applicable)
            Date projectStartDate = project.pse__Start_Date__c;
            Date projectEndDate = project.pse__End_Date__c;
            if(projectEndDate==null) projectEndDate = projectStartDate;
            Date forecastStartDate = currentMonthStart;
            Date latestEndDate = projectEndDate;
            Date forecastEndDate;

            // Check for latest Assignment/Resource Request end date
            for(pse__Est_Vs_Actuals__c eVa : project.pse__Est_Vs_Actuals__r)
            {
                if(eVa.pse__End_Date__c > latestEndDate)
                {
                    latestEndDate = eva.pse__End_Date__c;
                }
            }

            // Check for latest Fixed Fee billing milestone target date
            for(pse__Milestone__c m : project.pse__Milestones__r)
            {
                if(m.pse__Target_Date__c > latestEndDate)
                {
                    latestEndDate = m.pse__Target_Date__c.toStartOfMonth().addMonths(1) -1;
                }
            }

            // Check for holdback end date
            if(project.PSA_BR_Holdback_Applies__c && project.PSA_BR_Holdback_End_Date__c > latestEndDate)
            {
                latestEndDate = project.PSA_BR_Holdback_End_Date__c.toStartOfMonth().addMonths(1) -1;
            }
            
            forecastEndDate = latestEndDate;
            // DONE GETTING THE START AND END DATES FOR FORECAST RANGE

            System.debug('~~~~~Checking project ' + project.pse__Project_Id__c + ': forecastStartDate ' + forecastStartDate + ', forecastEndDate ' + forecastEndDate);

            // GET PRELIMINARY INFORMATION NEEDED FOR EXPENSE BILLING FORECAST
            // If expense billing type is Percent of Services or Flat Amount per Day, get billing levels that would apply toward services amount
            String expenseBillingType = project.PSA_BR_Expenses_Billing_Type__c;
            Set<String> setBillingLevelsForExpenseBillings = new Set<String>();
            Decimal expenseAmountPerMonth = 0;
            if(expenseBillingType=='Percent of Services')
            {
                List<String> lstBillingLevelsPctServices = new List<String>();
                String billingLevels = project.PSA_BR_Billing_Levels_for_Expense_Pct__c;
                if(billingLevels==null) billingLevels = '';
                lstBillingLevelsPctServices = billingLevels.split(';');
                setBillingLevelsForExpenseBillings = new Set<String>(lstBillingLevelsPctServices);
            }
            else if(expenseBillingType=='Flat Amount per Day')
            {
                List<String> lstBillingLevelsAmtPerDay = new List<String>();
                String billingLevels = project.PSA_BR_Billing_Levels_for_Expense_Amt__c;
                if(billingLevels==null) billingLevels = '';
                lstBillingLevelsAmtPerDay = billingLevels.split(';');
                setBillingLevelsForExpenseBillings = new Set<String>(lstBillingLevelsAmtPerDay);
            }
            else if(expenseBillingType=='As Incurred')
            {
                // Calculate expense budget amount average between project start and end date
                Decimal expenseBudget = project.pse__Expense_Budget__c;
                Integer monthsBetweenProjectStartAndEnd = projectStartDate.monthsBetween(projectEndDate) + 1;
                System.debug('~~~~ Project start/end range: ' + monthsBetweenProjectStartAndEnd + ' and expense budget is ' + expenseBudget);
                if(expenseBudget > 0)
                {
                    expenseAmountPerMonth = expenseBudget / monthsBetweenProjectStartAndEnd;
                    expenseAmountPerMonth.setScale(2);
                }
            }
            else
            {
                System.debug('~~~~~ Unsupported Expenses Billing Type: ' + expenseBillingType);
            }

            // GET PRELIMINARY INFORMATION NEEDED FOR DISCOUNT FORECAST
            // If Account-level Discount applies, get billing levels that would apply to services to be discounted
            // TO DO: Instead of resetting the Account Discount for each project iteration, it should be applicable across
            //        projects, so move it to higher scope in this method. Note this will be odd in forecasting since it
            //        will be first-come first-served, and it will be unpredictable which projects get the discount and
            //        which don't since they will be over cap.
            boolean accountDiscountApplies = project.PSA_BR_Account_Discount_Applies__c;
            boolean accountDiscountActive = project.PSA_BR_Account_Discount__r.PSA_Discount_Active__c;
            Decimal accountDiscountTotal = project.PSA_BR_Account_Discount__r.PSA_Discount_Amount_Applied__c;
            Decimal accountDiscountCap = project.PSA_BR_Account_Discount__r.PSA_Discount_Cap__c;
            Decimal accountDiscountPercent = project.PSA_BR_Account_Discount__r.PSA_Discount_Percent__c;
            Date accountDiscountEndDate = project.PSA_BR_Account_Discount__r.PSA_Discount_End_Date__c;
            if(accountDiscountTotal == null) accountDiscountTotal = 0;
            accountDiscountTotal = accountDiscountTotal * -1;
            if(accountDiscountCap == null) accountDiscountCap = 0;
            if(accountDiscountPercent == null) accountDiscountPercent = 0;
            System.debug('~~~~~ Discount stuff: discountApplies ' + accountDiscountApplies + ' accountDiscountActive ' + accountDiscountActive + ' accountDiscountTotal ' + accountDiscountTotal + ' accountDiscountCap ' + accountDiscountCap + ' accountDiscountPercent ' + accountDiscountPercent + ' accountDiscountEndDate ' + accountDiscountEndDate + ' billing levels ' + project.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c);
            Set<String> setBillingLevelsForAccountDiscount = new Set<String>();
            if(accountDiscountApplies && accountDiscountActive)
            {
                List<String> lstBillingLevelsForDiscount = new List<String>();
                String billingLevels = project.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c;
                if(billingLevels==null) billingLevels = '';
                lstBillingLevelsForDiscount = billingLevels.split(';');
                setBillingLevelsForAccountDiscount = new Set<String>(lstBillingLevelsForDiscount);
            }

            // Get any existing Holdback balance on the project to use as the starting amount for holdback already applied
            Decimal totalHoldback = -1 * project.PSA_BR_Holdback_Applied_To_Date__c;

            // Iterate through the months needing forecast records. For each month, check whether a forecast already exists.
            // If not, create one.  If forecasts exist past the forecast end date, exclude those from the forecast.
            for(pse__Time_Period__c month : upcomingTimePeriods)
            {
                Decimal seasonalBillingsForExpensePctServicesBillLevelsForMonth=0;
                Decimal totalSeasonalBillingsForMonth = 0;
                Decimal servicesDaysForExpenseFlatAmtForMonth = 0;
                Decimal accountDiscountAmountForMonth = 0;
                Decimal holdbackAmountForMonth = 0;
                String pfKey = project.pse__Project_Id__c + '-' + month.Name;
                System.debug('~~~~~Checking for forecast with key ' + pfKey + '.');

                // BEGIN HANDLING OF PROJECT FORECAST HEADER RECORDS
                PSA_Project_Forecast__c projectForecast = projectForecastMap.get(pfKey);
                if(projectForecast != null)
                {
                    System.debug('~~~~~FOUND forecast with key ' + pfKey + ': ' + projectForecast);
                    if(projectForecast.PSA_For_Month_Ending__c <= forecastEndDate)
                    {
                        if(projectForecast.PSA_Include_in_Forecast__c == false)
                        {
                            // Forecast was excluded but now should not be. Include it.
                            System.debug('~~~~~Adding excluded forecast ' + pfKey + ' back in.');
                            projectForecast.PSA_Include_in_Forecast__c = true;
                            forecastsForUpdate.add(projectForecast);
                        }

                        // If the project has a forecast category of Sales or Upside, the forecast details will need to be removed from the forecast and the forecast zeroed out
                        if(project.PSA_Forecast_Category__c == null || project.PSA_Forecast_Category__c == 'Sales' || project.PSA_Forecast_Category__c == 'Upside')
                        {
                            System.debug('~~~~~ Clearing forecast for ' + pfKey);
                            forecastsForZero.add(projectForecast);
                        }
                    }
                    else
                    {
                        if(projectForecast.PSA_Include_in_Forecast__c == true)
                        {
                            // Forecast is now out past the lastest forecastable date. Zero out its billing forecast info.
                            System.debug('~~~~~Taking included billing forecast ' + pfKey + ' out.');
                            forecastsForZero.add(projectForecast);
                        }
                    }

                    // Set all Forecast Details for deletion, so that full recalculation will be done for projects
                    forecastDetailsForDelete.addAll(projectForecast.PSA_Project_Forecast_Details__r);
                }
                else
                {
                    if(month.pse__End_Date__c <= forecastEndDate)
                    {
                        System.debug('~~~~~Creating new forecast ' + pfKey + '.');
                        projectForecast = new PSA_Project_Forecast__c();
                        projectForecast.CurrencyIsoCode = projectCurrency;
                        projectForecast.PSA_Project__c = project.Id;
                        projectForecast.PSA_Time_Period__c = month.Id;
                        projectForecast.PSA_Include_in_Forecast__c = True;
                        projectForecast.PSA_Days_in_Period__c = Date.daysInMonth(month.pse__End_Date__c.year(), month.pse__End_Date__c.month());
                        projectForecast.PSA_Item_Key__c = pfKey;
                        forecastsForInsert.add(projectForecast);
                        projectForecastMap.put(pfKey, projectForecast);
                    }
                }
                // END HANDLING OF PROJECT FORECAST HEADER RECORDS

                // BEGIN HANDLING OF PROJECT FORECAST DETAIL RECORDS
                // Now the parent project forecast records have been handled.
                // Calculate Project Forecast Details for months within the forecast range.
                // Only do this when the project has an appropriate forecast category.
                if(project.PSA_Forecast_Category__c != null && project.PSA_Forecast_Category__c != 'Sales' && project.PSA_Forecast_Category__c != 'Upside'
                        && month.pse__End_Date__c >= forecastStartDate && month.pse__End_Date__c <= forecastEndDate)
                {
                    // BEGIN T&M SERVICES FORECAST
                    // Only include if the Services Billing Type is not Fixed Price
                    if(servicesBillingType != 'Fixed Price')
                    {
                        // Determine whether to evaluate account-level DISCOUNT for the current month when calculating T&M Services billings. 
                        // Criteria are:
                        // - Account-Level Discount applies to project
                        // - Account-Level Discount associated with the project is active
                        // - There is no cap on the Account-level discount, or the running discount total up to the current month is still under the cap
                        // - There is no end date on the Account-level discount, or the discount end date is in or after the current month
                        boolean evaluateDiscountForMonth = (accountDiscountApplies && accountDiscountActive && (accountDiscountCap == null || accountDiscountTotal < accountDiscountCap) && (accountDiscountEndDate == null || accountDiscountEndDate >= month.pse__End_Date__c));
                        System.debug('Evaluate discount for month ending ' + month.pse__End_Date__c + '? ' + evaluateDiscountForMonth);

                        // Determine whether to evaluate HOLDBACK for the current month when calculating T&M Services billings. 
                        // Criteria are:
                        // - Holdback applies to project
                        // - Holdback percent is specified
                        // - Holdback End Date is on or after the current month
                        boolean evaluateHoldbackForMonth = (project.PSA_BR_Holdback_Applies__c && project.PSA_BR_Holdback_End_Date__c != null && project.PSA_BR_Holdback_End_Date__c >= month.pse__Start_Date__c &&  project.PSA_BR_Holdback_Pct__c != null);
                        System.debug('Evaluate holdback for month ending ' + month.pse__End_Date__c + '? ' + evaluateHoldbackForMonth);

                        // Iterate Est vs Actuals by month and create/update Project Forecast Details
                        for(pse__Est_Vs_Actuals__c eva : project.pse__Est_Vs_Actuals__r)
                        {
                            String evaDetailItemKey = '', evaForecastSource='', evaForecastType='';
                            String evaForecastCategory = eva.PSA_Forecast_Category__c;
                            Decimal estimatedBillings = eva.PSA_Estimated_Billings__c;
                            Decimal seasonalBillings = estimatedBillings;
                            Decimal seasonalityFactorForMonth = month.PSA_Seasonality_Factor__c;
                            Decimal seasonality = seasonalityFactorForMonth;
                            Decimal estimatedDays = eva.pse__Estimated_Days__c;
                            String evaCostCurrency = eva.PSA_Cost_Currency_Code__c;
                            Boolean isPartTimeResource = false;
                            Id resourceId;
                            Decimal billRate;

                            if(evaForecastCategory==null)
                            {
                                evaForecastCategory = project.PSA_Forecast_Category__c;
                            }

                            if(eva.pse__End_Date__c == month.pse__End_Date__c)
                            {
                                // Set Item Key, Forecast Type, and Forecast Source differently depending on whether the EvA is from 
                                // a resource request or an assignment.  And determine whether the resource request or assignment is for 
                                // a part-time resource.
                                resourceId = null; //Default the resourceId to null
                                if(eva.PSA_Source__c == 'Resource Request')
                                {
                                    evaDetailItemKey = pfKey + '|' + eva.PSA_Resource_Request__r.Name;
                                    evaForecastType = 'Resource Request';
                                    evaForecastSource = 'Resource Request - ' + eva.PSA_Resource_Request__r.pse__Resource_Role__c + ' - ' + eva.PSA_Resource_Request__r.PSA_Billing_Level__c;
                                    isPartTimeResource = eva.PSA_Resource_Request__r.PSA_Part_Time__c;
                                    billRate = eva.PSA_Resource_Request__r.pse__Requested_Bill_Rate__c;
                                    if (eva.PSA_Resource_Request__r.pse__Staffer_Resource__c != null) 
                                    {
                                        resourceId = eva.PSA_Resource_Request__r.pse__Staffer_Resource__c;
                                    }
                                }
                                else if(eva.PSA_Source__c == 'Assignment')
                                {
                                    evaDetailItemKey = pfKey + '|' + eva.pse__Assignment__r.pse__Assignment_Number__c;
                                    evaForecastType = 'Assignment';
                                    evaForecastSource = 'Assignment - ' + eva.pse__Assignment__r.pse__Resource__r.Name;
                                    isPartTimeResource = eva.pse__Assignment__r.PSA_Part_Time__c;
                                    resourceId = eva.pse__Assignment__r.pse__Resource__c;
                                    billRate = eva.pse__Scheduled_Bill_Rate__c;
                                }


                                // Calculate seasonally-adjusted billings as the Estimated Billings from the EvA times the seasonality factor
                                // for the EvA month.  If the EvA is for a part-time resource, override the seasonality factor as 100%.
                                if(isPartTimeResource)
                                {
                                    // Don't adjust for seasonality if part-time
                                    seasonalBillings = estimatedBillings;
                                    seasonality = 100;
                                }
                                else
                                {
                                    // Full time, so adjust for seasonality
                                    if(seasonalityFactorForMonth > 0)
                                    {
                                        seasonalBillings = estimatedBillings * (seasonalityFactorForMonth/100);
                                    }
                                }

                                // If the project's expense billing type is Percent of Services summarize seasonal T&M billings from EvA's having the specified billing levels
                                // If the project's expense billing type is Flat Amount per Day summarize Estimated Days from EvA's having the specified billing levels
                                // These will be used to calculate the expense forecast for the month
                                if(expenseBillingType=='Percent of Services' || expenseBillingType=='Flat Amount per Day')
                                {
                                    if(setBillingLevelsForExpenseBillings.contains(eva.PSA_Billing_Level__c))
                                    {
                                        System.debug('Billing level ' + eva.PSA_Billing_Level__c + ' IS contained in expense-related Billing Levels.');
                                        seasonalBillingsForExpensePctServicesBillLevelsForMonth += seasonalBillings;
                                        servicesDaysForExpenseFlatAmtForMonth += estimatedDays;
                                    }
                                    else
                                    {
                                        System.debug('Billing level ' + eva.PSA_Billing_Level__c + ' is NOT contained in expense-related Billing Levels.');
                                    }
                                    System.debug('Month: ' + month.pse__End_Date__c + ': Total Seasonal Services from EvAs with billing levels for Expense Pct Services: ' + seasonalBillingsForExpensePctServicesBillLevelsForMonth);
                                }

                                // If an account-level discount applies, summarize seasonal T&M billings from EvA's having the billing levels specified in the discount
                                // These will be used to calculate the discount amount for the month
                                if(evaluateDiscountForMonth)
                                {
                                    // Only include EvAs in discount if they have the billing level
                                    if(setBillingLevelsForAccountDiscount.contains(eva.PSA_Billing_Level__c))
                                    {
                                        // Set the discount basis as Seasonally-adjusted billings for applicable billing levels times discount percent
                                        System.debug('Billing level ' + eva.PSA_Billing_Level__c + ' IS contained in Account Discount Billing Levels.');
                                        accountDiscountAmountForMonth += seasonalBillings * (accountDiscountPercent/100);
                                        System.debug('~~~~~ Base discount amount is ' + accountDiscountAmountForMonth);
                                    }                                   
                                }

                                // Update total seasonal billings for the months (irrespective of billing levels) for Holdback
                                totalSeasonalBillingsForMonth += seasonalBillings;
                                System.debug('~~~~~ Adding EvA ' + eva.Name + ' to Total Seasonal Billings for Month ending ' + month.pse__End_Date__c + '. New totalSeasonalBillingsForMonth: ' + totalSeasonalBillingsForMonth);

                                // If the Est vs Actuals cost rate currency is different from the project currency, 
                                // convert the cost value to the project currency
                                Double evaCost = eva.PSA_Estimated_Cost__c;
                                Double scheduledCost = 0;
                                if(evaCost == null || evaCost == 0)
                                {
                                    scheduledCost = 0;
                                }
                                else if(evaCostCurrency != projectCurrency)
                                {
                                    // First put eva cost in terms of corp currency
                                    Double evaConversionRate = conversionRateMap.get(evaCostCurrency);
                                    if(evaConversionRate != null && evaConversionRate != 0)
                                    {
                                        scheduledCost = evaCost / evaConversionRate;

                                        // Next put the cost in terms of project currency. No need to do it if project is already in corp currency.
                                        if(projectCurrency != 'USD')
                                        {
                                            Double projectConversionRate = conversionRateMap.get(projectCurrency);
                                            if(projectConversionRate != null && projectConversionRate != 0)
                                            {
                                                scheduledCost = scheduledCost * projectConversionRate;
                                            }                                       
                                        }
                                    }
                                }
                                else
                                {
                                    scheduledCost = evaCost;
                                }

                                System.debug('~~~~~ Going to create a new T&M PFD for ' + evaDetailItemKey);
                                PSA_Project_Forecast_Detail__c tmFD = new PSA_Project_Forecast_Detail__c();
                                tmFD.CurrencyIsoCode = projectCurrency;
                                tmFD.PSA_Project_Forecast__c = projectForecast.Id;
                                tmFD.PSA_Forecast_Source__c = evaForecastSource;
                                tmFD.PSA_Forecast_Type__c = evaForecastType;
                                tmFD.PSA_Scheduled_Cost__c = scheduledCost;
                                tmFD.PSA_Scheduled_Days__c = estimatedDays;
                                tmFD.PSA_Scheduled_Hours__c =  eva.pse__Estimated_Hours__c;
                                tmFD.PSA_Scheduled_Time_Billings__c = estimatedBillings;                
                                tmFD.PSA_Item_Key__c = evaDetailItemKey;
                                tmFD.PSA_Forecast_Category__c = evaForecastCategory;
                                tmFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(evaForecastCategory);
                                tmFD.PSA_Include_in_Forecast__c = True;
                                tmFD.PSA_Scheduled_Billings__c = seasonalBillings;
                                tmFD.PSA_Seasonality_Factor__c = seasonality;
                                tmFD.PSA_Resource__c = resourceId; //Added 3/9/16 to facilitate financial reporting
                                tmFD.PSA_Est_Vs_Actuals__c = eva.Id; //Added 3/9/16 to facilitate financial reporting
                                tmFD.PSA_Scheduled_Bill_Rate__c = billRate; //Added 3/9/16 to facilitate financial reporting
                                forecastDetailsForInsert.add(tmFD);
                            }
                        }

                        if(evaluateDiscountForMonth)
                        {
                            // Now that we've traversed the EvA's and have the base discount for the month, 
                            // add the month's discount to the running total and compare to the cap.
                            // If we are still under the cap, apply the full discount amount
                            // If this puts us over the cap, apply only the amount that fits
                            if(accountDiscountCap != null && accountDiscountCap > 0)
                            {
                                Decimal newDiscountTotal = accountDiscountTotal + accountDiscountAmountForMonth;
                                if (newDiscountTotal > accountDiscountCap)
                                {
                                    accountDiscountAmountForMonth = accountDiscountCap - accountDiscountTotal;
                                    System.debug('~~~~~ Hit the cap of ' + accountDiscountCap + '. Discount amount for month is reduced to ' + accountDiscountAmountForMonth);
                                }
                            }

                            // Increment the total account discount so that it increases toward cap
                            accountDiscountTotal += accountDiscountAmountForMonth;  
                        }

                        if(evaluateHoldbackForMonth)
                        {
                            // Calculate holdback amount for the month and add it to the project holdback total
                            // If the holdback end date is before the current month, then apply the held back percent of 
                            // seasonally-adjusted billings for the month to represent a HOLDBACK CREDIT.
                            // If the holdback end date is in the current month, apply all of the total already held back
                            // to represent a HOLDBACK CHARGE, for month of holdback release.
                            if(month.pse__End_Date__c < project.PSA_BR_Holdback_End_Date__c)
                            {
                                holdbackAmountForMonth = (-1 * (project.PSA_BR_Holdback_Pct__c / 100) * totalSeasonalBillingsForMonth);
                                totalHoldback -= holdbackAmountForMonth;
                                System.debug('~~~~~ Applying holdback for month ending ' + month.pse__End_Date__c + ' of ' + holdbackAmountForMonth + '. Total holdback is ' + totalHoldback);
                            }
                            else if(month.pse__Start_Date__c <= project.PSA_BR_Holdback_End_Date__c && month.pse__End_Date__c >= project.PSA_BR_Holdback_End_Date__c)
                            {
                                holdbackAmountForMonth = totalHoldback;
                                System.debug('~~~~~ Applying holdback RELEASE for month ending ' + month.pse__End_Date__c + ' of ' + holdbackAmountForMonth);
                            }
                        }
                    }
                    // END T&M SERVICES FORECAST


                    // BEGIN FIXED FEE SERVICES FORECAST
                    // Summarize fixed fee milestones by month and create/update Project Forecast Details
                    String ffsDetailItemKey = pfKey + '|FFS';
                    Decimal fixedFeeSum = 0;
                    for(pse__Milestone__c milestone : project.pse__Milestones__r)
                    {
                    // add milestone.billable services PSA_Milestone_Type__c = Billable Services - Fixed and the above query. 
                        if(milestone.pse__Target_Date__c >= month.pse__Start_Date__c && milestone.pse__Target_Date__c <= month.pse__End_Date__c &&  milestone.PSA_Milestone_Type__c == 'Billable Services - Fixed')
                        {
                            fixedFeeSum += milestone.pse__Milestone_Amount__c;
                        }
                    }

                    if(fixedFeeSum <> 0)
                    {
                        // Only create a new forecast detail if the amount is non-zero and there's not already one for the period
                        // This will keep from having a ton of Fixed Fee Services forecast details around when they serve no purpose
                        System.debug('~~~~~ Going to create a new Fixed Fee PFD for ' + ffsDetailItemKey);
                        PSA_Project_Forecast_Detail__c ffsFD = new PSA_Project_Forecast_Detail__c();
                        ffsFD.CurrencyIsoCode = projectCurrency;
                        ffsFD.PSA_Project_Forecast__c = projectForecast.Id;
                        ffsFD.PSA_Forecast_Source__c = 'Fixed Fee Services';
                        ffsFD.PSA_Forecast_Type__c = 'Fixed Fee Services';
                        ffsFD.PSA_Scheduled_Cost__c = 0;
                        ffsFD.PSA_Scheduled_Days__c = 0;
                        ffsFD.PSA_Scheduled_Hours__c = 0;
                        ffsFD.PSA_Scheduled_Time_Billings__c = 0;               
                        ffsFD.PSA_Item_Key__c = ffsDetailItemKey;
                        ffsFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                        ffsFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                        ffsFD.PSA_Include_in_Forecast__c = True;
                        ffsFD.PSA_Scheduled_Billings__c = fixedFeeSum;
                        forecastDetailsForInsert.add(ffsFD);
                    }
                    // END FIXED FEE SERVICES FORECAST




                    // BEGIN EXPENSE BILLING FORECAST
                    String expDetailItemKey = pfKey + '|EXP';
                    if(expenseBillingType=='As Incurred')
                    {
                        // Create a new forecast detail or update the existing for the period.
                        if(expenseAmountPerMonth <> 0 && month.pse__End_Date__c >= projectStartDate && month.pse__Start_Date__c <= projectEndDate)
                        {
                            // Only create a new forecast detail if the amount is non-zero and there's not already one for the period
                            // This will keep from having a ton of Expense forecast details around when they serve no purpose
                            System.debug('~~~~~ Going to create a new As Incurred EXPENSE PFD for ' + expDetailItemKey);
                            PSA_Project_Forecast_Detail__c expFD = new PSA_Project_Forecast_Detail__c();
                            expFD.CurrencyIsoCode = projectCurrency;
                            expFD.PSA_Project_Forecast__c = projectForecast.Id;
                            expFD.PSA_Forecast_Source__c = 'Expenses';
                            expFD.PSA_Forecast_Type__c = 'Expenses';
                            expFD.PSA_Scheduled_Cost__c = 0;
                            expFD.PSA_Scheduled_Days__c = 0;
                            expFD.PSA_Scheduled_Hours__c = 0;
                            expFD.PSA_Scheduled_Time_Billings__c = 0;               
                            expFD.PSA_Item_Key__c = expDetailItemKey;
                            expFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                            expFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                            expFD.PSA_Include_in_Forecast__c = True;
                            expFD.PSA_Scheduled_Billings__c = expenseAmountPerMonth;
                            forecastDetailsForInsert.add(expFD);
                        }
                    }
                    else if(expenseBillingType == 'Percent of Services' || expenseBillingType == 'Flat Amount per Day')
                    {
                        Decimal expenseBillings = 0;
                        if(expenseBillingType == 'Percent of Services')
                        {
                            Decimal pctServices = project.PSA_BR_Expense_Pct_of_Services__c;
                            if(pctServices == null) pctServices = 0;
                            expenseBillings = seasonalBillingsForExpensePctServicesBillLevelsForMonth * (pctServices / 100);
                        }
                        else
                        {
                            Decimal amtPerDay = project.PSA_BR_Expense_Amt_Per_Day__c;
                            if(amtPerDay == null) amtPerDay = 0;
                            expenseBillings = servicesDaysForExpenseFlatAmtForMonth * (amtPerDay);
                        }
                        
                        System.debug('~~~~~ Going to create a new Pct Services EXPENSE PFD for ' + expDetailItemKey);
                        PSA_Project_Forecast_Detail__c expFD = new PSA_Project_Forecast_Detail__c();
                        expFD.CurrencyIsoCode = projectCurrency;
                        expFD.PSA_Project_Forecast__c = projectForecast.Id;
                        expFD.PSA_Forecast_Source__c = 'Expenses';
                        expFD.PSA_Forecast_Type__c = 'Expenses';
                        expFD.PSA_Scheduled_Cost__c = 0;
                        expFD.PSA_Scheduled_Days__c = 0;
                        expFD.PSA_Scheduled_Hours__c = 0;
                        expFD.PSA_Scheduled_Time_Billings__c = 0;               
                        expFD.PSA_Item_Key__c = expDetailItemKey;
                        expFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                        expFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                        expFD.PSA_Include_in_Forecast__c = True;
                        expFD.PSA_Scheduled_Billings__c = expenseBillings;
                        forecastDetailsForInsert.add(expFD);
                    } else if (expenseBillingType == 'Fixed Amount')
                    {
                            fixedFeeSum = 0;   
                            for(pse__Milestone__c milestone : project.pse__Milestones__r)
                            {
                            // add milestone.billable services PSA_Milestone_Type__c = Billable Expenses - Fixed and the above query. 
                                if(milestone.pse__Target_Date__c >= month.pse__Start_Date__c && milestone.pse__Target_Date__c <= month.pse__End_Date__c  &&  milestone.PSA_Milestone_Type__c == 'Billable Expenses - Fixed' )
                                {
                                    fixedFeeSum += milestone.pse__Milestone_Amount__c;
                                }
                            }
                            if(fixedFeeSum <> 0)
                            {
                                // Only create a new forecast detail if the amount is non-zero and there's not already one for the period
                                // This will keep from having a ton of Fixed Fee Expenses forecast details around when they serve no purpose
                                System.debug('~~~~~ Going to create a new Fixed Fee PFD for ' + ffsDetailItemKey);
                                PSA_Project_Forecast_Detail__c expFD = new PSA_Project_Forecast_Detail__c();
                                expFD.CurrencyIsoCode = projectCurrency;
                                expFD.PSA_Project_Forecast__c = projectForecast.Id;
                                expFD.PSA_Forecast_Source__c = 'Expenses';
                                expFD.PSA_Forecast_Type__c = 'Expenses';
                                expFD.PSA_Scheduled_Cost__c = 0;
                                expFD.PSA_Scheduled_Days__c = 0;
                                expFD.PSA_Scheduled_Hours__c = 0;
                                expFD.PSA_Scheduled_Time_Billings__c = 0;               
                                expFD.PSA_Item_Key__c = expDetailItemKey;
                                expFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                                expFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                                expFD.PSA_Include_in_Forecast__c = True;
                                expFD.PSA_Scheduled_Billings__c = fixedFeeSum;
                                forecastDetailsForInsert.add(expFD);
                            }
                    }
                    // END EXPENSE BILLING FORECAST

                    // BEGIN DISCOUNT BILLING FORECAST
                    String discDetailItemKey = pfKey + '|ADJ-AD';
                    if(accountDiscountApplies)
                    {
                        System.debug('~~~~~ Going to create a new Account Discount PFD for ' + discDetailItemKey);
                        PSA_Project_Forecast_Detail__c discFD = new PSA_Project_Forecast_Detail__c();
                        discFD.CurrencyIsoCode = projectCurrency;
                        discFD.PSA_Project_Forecast__c = projectForecast.Id;
                        discFD.PSA_Forecast_Source__c = 'Services Adjustment: Discount';
                        discFD.PSA_Forecast_Type__c = 'Services Adjustment';        
                        discFD.PSA_Item_Key__c = discDetailItemKey;
                        discFD.PSA_Scheduled_Cost__c = 0;
                        discFD.PSA_Scheduled_Days__c = 0;
                        discFD.PSA_Scheduled_Hours__c = 0;
                        discFD.PSA_Scheduled_Time_Billings__c = 0;
                        discFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                        discFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                        discFD.PSA_Include_in_Forecast__c = True;
                        discFD.PSA_Scheduled_Billings__c = (accountDiscountAmountForMonth * -1);
                        forecastDetailsForInsert.add(discFD);
                    }
                    // END DISCOUNT BILLING FORECAST

                    // BEGIN HOLDBACK BILLING FORECAST
                    String hbDetailItemKey = pfKey + '|ADJ-HB';
                    if(project.PSA_BR_Holdback_Applies__c)
                    {
                        System.debug('~~~~~ Going to create a new Holdback PFD for ' + hbDetailItemKey);
                        PSA_Project_Forecast_Detail__c hbFD = new PSA_Project_Forecast_Detail__c();
                        hbFD.CurrencyIsoCode = projectCurrency;
                        hbFD.PSA_Project_Forecast__c = projectForecast.Id;
                        hbFD.PSA_Forecast_Source__c = 'Services Adjustment: Holdback';
                        hbFD.PSA_Forecast_Type__c = 'Services Adjustment';      
                        hbFD.PSA_Item_Key__c = hbDetailItemKey;
                        hbFD.PSA_Scheduled_Cost__c = 0;
                        hbFD.PSA_Scheduled_Days__c = 0;
                        hbFD.PSA_Scheduled_Hours__c = 0;
                        hbFD.PSA_Scheduled_Time_Billings__c = 0;
                        hbFD.PSA_Forecast_Category__c = project.PSA_Forecast_Category__c;
                        hbFD.PSA_Forecast_Category_Percent__c = forecastPercentMap.get(project.PSA_Forecast_Category__c);
                        hbFD.PSA_Include_in_Forecast__c = True;
                        hbFD.PSA_Scheduled_Billings__c = holdbackAmountForMonth;
                        forecastDetailsForInsert.add(hbFD);
                    }
                    // END DISCOUNT HOLDBACK FORECAST

                }
                // END HANDLING OF PROJECT FORECAST DETAIL RECORDS
            }
        }

        // Add the forecasts needing exclusion
        forecastsForUpdate.addAll(forecastsForExclusion);

        // Update existing forecast records
        Database.Update(forecastsForUpdate);

        // Insert new forecast records
        Database.Insert(forecastsForInsert);

        // Delete any forecast details that need removal
        if(forecastDetailsForDelete.size() > 0)
        {
            Database.Delete(forecastDetailsForDelete);
        }

        // Insert any new forecast details.
        // Any forecast details created for new Project Forecast records will first need
        // to have their parent record Id set. To do this, look up the parent in the map
        if(forecastDetailsForInsert.size() > 0)
        {
            for(PSA_Project_Forecast_Detail__c pfd : forecastDetailsForInsert)
            {
                if(pfd.PSA_Project_Forecast__c == null)
                {
                    System.debug('~~~ PFD with key ' + pfd.PSA_Item_Key__c + ' needs parent...');
                    String parentKey = pfd.PSA_Item_Key__c.left(pfd.PSA_Item_Key__c.IndexOf('|'));
                    System.debug('~~~ Checking for parent with key ' + parentKey);
                    PSA_Project_Forecast__c parent = projectForecastMap.get(parentKey);
                    if(parent!=null)
                    {
                        pfd.PSA_Project_Forecast__c = parent.Id;
                    }
                    else
                    {
                        System.debug('!!!!!! Error. No parent found for project forecast detail using key ' + parentKey);
                    }
                }
            }
            Database.Insert(forecastDetailsForInsert);
        }
    }



    /**************************************************************************************
    // Name        : calculateRevenueForecast
    // Description : Performs Revenue Forecast calculation for one or more projects.
    //               NOTE: The list of projects passed in should be already filtered to
    //               include those that are eligible for revenue forecast calculation, determined
    //               based on their Include in Forecasting, Include in Billing forecast fields, etc. 
    //
    ***************************************************************************************/
    public static void calculateRevenueForecast(List<Id> projectIdsForRevenueForecast)
    {
        Date currentMonthStart = Date.Today().toStartOfMonth();
        Date currentMonthEnd = currentMonthStart.addMonths(1) -1;
        Map <Date, pse__Time_Period__c> timePeriodMap = new Map<Date, pse__Time_Period__c>();
        Map <String, PSA_Project_Forecast__c> projectForecastMap = new Map<String, PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> revForecastsForInsert = new List<PSA_Project_Forecast__c>();
        List <PSA_Project_Forecast__c> revForecastsForUpdate = new List<PSA_Project_Forecast__c>();

        // Get Month time periods from three years ago onward
        Date threeYearsAgo = Date.today().addMonths(-36).toStartOfMonth();
        List <pse__Time_Period__c> timePeriods = [
            SELECT Id, Name, pse__Start_Date__c, pse__End_Date__c, PSA_Seasonality_Factor__c
              FROM pse__Time_Period__c
             WHERE pse__Type__c = 'Month'
               AND pse__End_Date__c > :threeYearsAgo
             ORDER BY pse__Start_Date__c];

        // Put time periods in a map keyed on time period end date
        if(timePeriods!=null && timePeriods.size() > 0)
        {
            for(pse__Time_Period__c tp : timePeriods)
            {
                timePeriodMap.put(tp.pse__End_Date__c, tp);
            }
        }
        
        // Get the revenue forecast template
        Id rfTemplateId = null;
/* FFRR removal
        ffrr__Template__c rfTemplate = [SELECT Id, Name FROM ffrr__Template__c WHERE Name = 'Guidewire Project Forecast Template'];
        if(rfTemplate == null)
        {
            System.debug('~~~~~~~ No revenue forecast template called Guidewire Project Forecast Template was found.');
        }
        else
        {
            rfTemplateId = rfTemplate.Id;
        }
*/

        // Get info about the projects relevant to revenue forecasting
        List<pse__Proj__c> projects = [
        SELECT Id, pse__Project_Id__c, pse__Is_Active__c, PSA_Include_in_Billing_Forecast__c, pse__Include_In_Forecasting__c,
               pse__Start_Date__c, pse__End_Date__c, pse__Stage__c, pse__Is_Billable__c, pse__Billing_Type__c,
               PSA_Revenue_Forecast_Model__c, PSA_Revenue_Deferral_End_Date__c, PSA_Revenue_Deferral_Duration__c, PSA_Revenue_Ratable_Period_Counts__c,
               PSA_Revenue_Refund_Cap__c, PSA_Revenue_Refund_Expiration_Date__c, PSA_Revenue_Refund_Percent__c, 
               PSA_BR_Holdback_Applies__c, PSA_BR_Holdback_Pct__c, PSA_BR_Holdback_End_Date__c,
               (SELECT Id, 
                       PSA_Include_in_Forecast__c,
                       PSA_Time_Period__c,
                       PSA_For_Month_Ending__c,
                       PSA_Days_in_Period__c,
                       CurrencyIsoCode,
                       PSA_Project__r.pse__Project_Id__c,
                       PSA_Item_Key__c,
                       PSA_Forecast_Services_Revenue__c,
                       PSA_Forecast_Expense_Revenue__c,
                       PSA_Forecast_Revenue__c,
                       PSA_Forecast_Deferred_Services_Revenue__c,
                       PSA_Forecast_Deferred_Expense_Revenue__c,
                       PSA_Forecast_Deferred_Revenue__c,
                       PSA_Forecast_Billings__c,
                       PSA_Forecast_Expense_Billings__c,
                       PSA_Forecast_Services_Billings__c,
                       PSA_Forecast_Percent_Complete__c
                  FROM PSA_Project_Forecasts__r
                 ORDER BY PSA_For_Month_Ending__c)
          FROM pse__Proj__c
         WHERE Id = :projectIdsForRevenueForecast
           AND pse__Include_In_Forecasting__c = True
           AND PSA_Revenue_Forecast_Model__c != null
           AND pse__Start_Date__c != null
         ORDER BY pse__Project_Id__c];

        // Iterate through the Projects and calculate the revenue forecast for each
        for(pse__Proj__c project : projects)
        {
            if(project.pse__Include_In_Forecasting__c)
            {
                String revenueForecastModel = project.PSA_Revenue_Forecast_Model__c;
                Date deferralEndDate = project.PSA_Revenue_Deferral_End_Date__c;
                Decimal deferredServicesRevenueSum = 0;
                Decimal deferredExpensesRevenueSum = 0;
                Integer deferralDuration = 0;
                if(project.PSA_Revenue_Deferral_Duration__c != null) deferralDuration = Integer.valueOf(project.PSA_Revenue_Deferral_Duration__c);
                RatableRevenueSchedule rrSchedule;
                Date refundExpirationDate;
                Decimal refundCap = 0;
                Decimal refundPercent = 0;
                Decimal refundDeferredAmount = 0;
                PercentCompleteRevenueSchedule pcrSchedule;
                boolean percentCompleteIsServicesOnly = false;

                // GET THE START AND END DATES THAT DEFINE THE FORECAST RANGE
                // Start of range = Start of current month
                // End of range varies depending on the project's revenue forecast model
                Date projectStartDate = project.pse__Start_Date__c;
                Date projectEndDate = project.pse__End_Date__c;
                if(projectEndDate==null) projectEndDate = projectStartDate;
                Date forecastStartDate = currentMonthStart;
                Date latestEndDate = projectEndDate;
                Date forecastEndDate;

                // Iterate through existing forecasts and put them in a map.
                // This will be used to find existing ones to update, or to determine whether it's necessary to create more where they don't exist
                for(PSA_Project_Forecast__c existingPF : project.PSA_Project_Forecasts__r)
                {
                    projectForecastMap.put(existingPF.PSA_Item_Key__c, existingPF);
                    System.debug('~~~~~~ Adding forecast to map for REVENUE forecast ' + existingPF.PSA_Item_Key__c);
                }

                if(revenueForecastModel == 'As Delivered - No Deferral')
                {
                    // Last forecast will be that of the latest billing forecast record, since 
                    // revenue is forecast simply as billed and there's no deferral.
                    latestEndDate = getLastForecastDate(project.PSA_Project_Forecasts__r);
                    if(latestEndDate == null) latestEndDate = projectEndDate;
                }
                else if(revenueForecastModel == 'As Delivered - Fixed Deferral End Date')
                {
                    // Last forecast will be the latest of: 
                    // a) Deferral End Date, 
                    // b) Latest existing billing forecast record, or 
                    // c) Project End Date
                    latestEndDate = projectEndDate;
                    Date lastForecastDate = getLastForecastDate(project.PSA_Project_Forecasts__r);
                    if(lastForecastDate != null && lastForecastDate > projectEndDate) 
                    {
                        latestEndDate = lastForecastDate;
                    }

                    if(deferralEndDate != null && deferralEndDate > latestEndDate)
                    {
                        latestEndDate = deferralEndDate;
                    }
                }
                else if(revenueForecastModel == 'As Delivered - Fixed Deferral Duration')
                {
                    // Last forecast will be the later of: 
                    // a) the forecast aligning with the project end date, or 
                    // b) the forecast which is <deferralDuration> periods following the latest project forecast with forecast billings > 0
                    // c) the latest existing project forecast record
                    latestEndDate = projectEndDate;
                    Date lastForecastDateWithBF = getLastForecastDateWithBillingForecast(project.PSA_Project_Forecasts__r);
                    if(lastForecastDateWithBF != null && lastForecastDateWithBF > projectEndDate) 
                    {
                        latestEndDate = lastForecastDateWithBF;
                    }

                    Date lastForecastDate = getLastForecastDate(project.PSA_Project_Forecasts__r);
                    if(lastForecastDate != null) 
                    {
                        lastForecastDate = lastForecastDate.addMonths(-1 * deferralDuration);
                        if(lastForecastDate > latestEndDate)
                        {
                            latestEndDate = lastForecastDate;
                        }
                    }                   

                    // Add <deferral duration> months to the latest date
                    latestEndDate = (latestEndDate.addMonths(deferralDuration + 1).toStartOfMonth()) - 1;
                    System.debug('~~~~~ Latest end date for fixed deferral duration:' + latestEndDate);
                }
                else if(revenueForecastModel == 'Ratable')
                {
                    // Initialize a Ratable Revenue Schedule instance that can be used with the current project to
                    // calculate ratable revenue.
                    String ratablePeriodCounts = project.PSA_Revenue_Ratable_Period_Counts__c;
                    rrSchedule = new RatableRevenueSchedule(ratablePeriodCounts, project.pse__Start_Date__c, currentMonthStart);

                    // Determine last forecast date, which will be the latest of: 
                    // a) the forecast aligning with the project end date, or 
                    // b) the forecast which is the the sum total of months defined in Ratable Period Counts after the project start date
                    // c) the latest existing project forecast record
                    latestEndDate = projectEndDate;                 
                    Date projectFirstMonthEnd = project.pse__Start_Date__c.addMonths(1).toStartOfMonth() - 1;
                    System.debug('~~~~~~ Project first month end date is ' + projectFirstMonthEnd);
                    Date latestRatablePeriodDate = projectFirstMonthEnd.addMonths(rrSchedule.totalPeriodCount - 1);
                    System.debug('~~~~~~ Added ' + (rrSchedule.totalPeriodCount-1) + ' periods to first month end to get ' + latestRatablePeriodDate);
                    if(latestRatablePeriodDate != null && latestRatablePeriodDate > projectEndDate) 
                    {
                        latestEndDate = latestRatablePeriodDate;
                    }

                    Date lastForecastDate = getLastForecastDate(project.PSA_Project_Forecasts__r);
                    if(lastForecastDate != null && lastForecastDate > latestEndDate)
                    {
                        latestEndDate = lastForecastDate;
                    }
                }
                else if(revenueForecastModel == 'As Delivered - Holdback' && project.PSA_BR_Holdback_Applies__c)
                {
                    // For Holdback revenue forecast model, last forecast will be the later of: 
                    // a) the forecast aligning with the project end date, or 
                    // b) the forecast which aligns with Holdback End Date, or
                    // c) the latest existing project forecast record
                    latestEndDate = projectEndDate;
                    Date lastForecastDateWithBF = getLastForecastDateWithBillingForecast(project.PSA_Project_Forecasts__r);
                    if(lastForecastDateWithBF != null && lastForecastDateWithBF > projectEndDate) 
                    {
                        latestEndDate = lastForecastDateWithBF;
                    }

                    Date holdbackEndDate = project.PSA_BR_Holdback_End_Date__c;
                    if(holdbackEndDate != null)
                    {
                        // Check against the last day of the month including holdback end date.
                        // Just in case holdback end date isn't defined as last day of the month
                        Date holdbackEndDateAdjusted = holdbackEndDate.addMonths(1).toStartOfMonth() -1;
                        if(holdbackEndDateAdjusted > latestEndDate)
                        {
                            latestEndDate = holdbackEndDateAdjusted;
                        }
                    }
                }
                else if(revenueForecastModel == 'As Delivered - Subject to Refund')
                {
                    // For Subject to Refund revenue forecast model, last forecast will be the later of: 
                    // a) the forecast aligning with the project end date, or 
                    // b) the forecast which aligns with Refund Expiration Date, or
                    // c) the latest existing project forecast record
                    latestEndDate = projectEndDate;
                    Date lastForecastDateWithBF = getLastForecastDateWithBillingForecast(project.PSA_Project_Forecasts__r);
                    if(lastForecastDateWithBF != null && lastForecastDateWithBF > projectEndDate) 
                    {
                        latestEndDate = lastForecastDateWithBF;
                    }

                    Date refundExpDateTemp = project.PSA_Revenue_Refund_Expiration_Date__c;
                    if(refundExpDateTemp != null)
                    {
                        // Check against the last day of the month including refund expiration date.
                        // Just in case refund exp date isn't defined as last day of the month
                        refundExpirationDate = refundExpDateTemp.addMonths(1).toStartOfMonth() -1;
                        if(refundExpirationDate > latestEndDate)
                        {
                            latestEndDate = refundExpirationDate;
                        }
                    }

                    // Get the other refund-related parameters
                    refundCap = project.PSA_Revenue_Refund_Cap__c;
                    if(refundCap == null) refundCap = 0;
                    refundPercent = project.PSA_Revenue_Refund_Percent__c;
                    if(refundPercent == null) refundPercent = 0;

                    // Get previously-deferred refund sum to apply toward refund cap when calculating
                    List <PSA_Project_Forecast__c> priorForecasts = getPriorBillingForecasts(projectForecastMap, currentMonthEnd);
                    for(PSA_Project_Forecast__c pf : priorForecasts)
                    {
                        Decimal priorDeferred = pf.PSA_Forecast_Deferred_Revenue__c;
                        if(priorDeferred==null) priorDeferred = 0;
                        refundDeferredAmount += priorDeferred;
                    }
                }
                else if(revenueForecastModel == 'Percent Complete' || revenueForecastModel == 'Percent Complete - Services Only')
                {
                    // For Percent Complete revenue forecast models last forecast for revenue forecast will be the project end date: 
                    latestEndDate = projectEndDate;

                    // Initialize a percent complete revenue schedule for calculating
                    pcrSchedule = new PercentCompleteRevenueSchedule();

                    // Determine which percent complete model is being used
                    if(revenueForecastModel == 'Percent Complete - Services Only') percentCompleteIsServicesOnly = true;
                }
                else if(revenueForecastModel == 'User-Defined')
                {
                    latestEndDate = projectEndDate;
                    System.debug('~~~~~~ User defined revenue forecast. No calculation will be performed.');
                }

                forecastEndDate = latestEndDate;
                System.debug('~~~~~~ Forecast end date will be ' + forecastEndDate);
                // DONE GETTING THE START AND END DATES FOR FORECAST RANGE


                // Iterate through the months needing forecast records (upcoming time periods). 
                // For each month, check whether a forecast already exists. If not, create one.
                // Put each forecast in a list for update or insert.
                Integer currentMonthNumber=0, ratableMonthNumber = 0;
                for(pse__Time_Period__c month : timePeriods)
                {
                    if(month.pse__End_Date__c > currentMonthStart && month.pse__End_Date__c <= forecastEndDate)
                    {
                        currentMonthNumber++;
                        String pfKey = project.pse__Project_Id__c + '-' + month.Name;
                        System.debug('~~~~~Checking for forecast with key ' + pfKey + '.');

                        // BEGIN INITIAL HANDLING OF PROJECT FORECAST HEADER RECORDS TO DEFINE THE SET
                        PSA_Project_Forecast__c projectForecast = projectForecastMap.get(pfKey);
                        if(projectForecast != null)
                        {
                            System.debug('~~~~~ REV FORECASTING: FOUND forecast with key ' + pfKey + ': ' + projectForecast);
                            if(projectForecast.PSA_For_Month_Ending__c <= forecastEndDate)
                            {
                                // Put it in the list of revenue forecasts to update.
                                System.debug('~~~~~Going to update forecast for REVENUE ' + pfKey + '.');
/* FFRR removal
                                projectForecast.ffrftemplate__c = rfTemplateId;
*/
                                revForecastsForUpdate.add(projectForecast);
                            }
                        }
                        else
                        {
                            // Create a new project forecast record, specifically for Revenue forecast
                            System.debug('~~~~~Creating new forecast for REVENUE ' + pfKey + '.');
                            projectForecast = new PSA_Project_Forecast__c();
                            projectForecast.PSA_Project__c = project.Id;
                            projectForecast.PSA_Time_Period__c = month.Id;
                            projectForecast.PSA_Include_in_Forecast__c = True;
                            projectForecast.PSA_Days_in_Period__c = Date.daysInMonth(month.pse__End_Date__c.year(), month.pse__End_Date__c.month());
                            projectForecast.PSA_Item_Key__c = pfKey;
/* FFRR removal                         
                            projectForecast.ffrftemplate__c = rfTemplateId;
*/
                            revForecastsForInsert.add(projectForecast);
                            projectForecastMap.put(pfKey, projectForecast);
                        }
                        // END INITIAL HANDLING OF PROJECT FORECAST HEADER RECORDS

                        //Declare variables for Forecast Expense Billings and Service Billings.
                        Decimal psaProjectForecastExpenseBilling = projectForecast.PSA_Forecast_Expense_Billings__c != null ? projectForecast.PSA_Forecast_Expense_Billings__c : 0;
                        Decimal psaProjectForecastServicesBilling = projectForecast.PSA_Forecast_Services_Billings__c != null ? projectForecast.PSA_Forecast_Services_Billings__c : 0;
                        

                        // Now that we have the forecast record, perform the revenue forecast calc
                        if(revenueForecastModel == 'As Delivered - No Deferral')
                        {
                            System.debug('~~~~~~ Forecast model is As Delivered - No Deferral ');
                            projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                            projectForecast.PSA_Forecast_Services_Revenue__c = psaProjectForecastServicesBilling;
                            projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                            projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = 0;
                        }
                        else if (revenueForecastModel == 'As Delivered - Fixed Deferral End Date')
                        {
                            if(deferralEndDate == null)
                            {
                                // No deferral end date was supplied, so don't defer any revenue
                                System.debug('~~~~~ No deferral end date, so no deferred revenue.');
                                projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Services_Revenue__c = psaProjectForecastServicesBilling;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = 0;
                            }
                            else if (deferralEndDate > month.pse__End_Date__c)
                            {
                                // Forecast month is before the deferral end date, so defer all revenue
                                System.debug('~~~~~ Before deferral end date, so ALL deferred revenue.');
                                projectForecast.PSA_Forecast_Expense_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Services_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = psaProjectForecastServicesBilling;
                                deferredExpensesRevenueSum += psaProjectForecastExpenseBilling;
                                deferredServicesRevenueSum += psaProjectForecastServicesBilling;
                            }
                            else if (deferralEndDate == month.pse__End_Date__c)
                            {
                                // Forecast month matches the deferral end date, so all deferred revenue should be forecast
                                System.debug('~~~~~ AT deferral end date, so deferred revenue will be forecast.');
                                projectForecast.PSA_Forecast_Expense_Revenue__c = deferredExpensesRevenueSum + psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Services_Revenue__c = deferredServicesRevenueSum + psaProjectForecastServicesBilling;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = 0;
                                deferredExpensesRevenueSum = 0;
                                deferredServicesRevenueSum = 0;
                            }
                            else if (deferralEndDate < month.pse__End_Date__c)
                            {
                                // Forecast month is AFTER deferral end date. No revenue will be deferred
                                System.debug('~~~~~ AFTER deferral end date, so no revenue will be deferred.');
                                projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Services_Revenue__c = psaProjectForecastServicesBilling;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = 0;
                            }
                        }
                        else if(revenueForecastModel == 'As Delivered - Fixed Deferral Duration')
                        {
                            // Get the PSA Project Forecast from <deferralDuration> months before the current forecast
                            // and use its deferred revenue amounts for current month's forecast revenue amounts
                            //PSA_Project_Forecast__c priorForecast = getPriorBillingForecast(allForecastsForProject, month.pse__End_Date__c, deferralDuration);
                            PSA_Project_Forecast__c priorForecast = getPriorBillingForecast(project.pse__Project_Id__c, timePeriods, projectForecastMap, month.pse__End_Date__c, deferralDuration);
                            if(priorForecast != null)
                            {
                                System.debug('~~~~~ GETTING deferred revenue from forecast ' + deferralDuration + ' months before ' + month.pse__End_Date__c);
                                projectForecast.PSA_Forecast_Expense_Revenue__c =  priorForecast.PSA_Forecast_Deferred_Expense_Revenue__c;
                                projectForecast.PSA_Forecast_Services_Revenue__c = priorForecast.PSA_Forecast_Deferred_Services_Revenue__c;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = psaProjectForecastServicesBilling;
                            }
                            else
                            {
                                System.debug('~~~~~ No forecast for ' + deferralDuration + ' months before ' + month.pse__End_Date__c + ' exists.');
                                projectForecast.PSA_Forecast_Expense_Revenue__c =  0;
                                projectForecast.PSA_Forecast_Services_Revenue__c = 0;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = psaProjectForecastExpenseBilling;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = psaProjectForecastServicesBilling;
                            }
                        }
                        else if(revenueForecastModel == 'Ratable')
                        {
                            // With this model, Forecast Services Billings for each month will be distributed over a set of periods
                            // as dictated using the project's Revenue: Ratable Period Counts field values.  

                            // If this is the CURRENT month, check if it falls after the beginning of a ratable period set. If it does, we 
                            // need to take the forecast services revenue from the past period and apply it ratably over the current and upcoming
                            // periods.  No changes will be made to past revenue forecast data
                            if(currentMonthNumber==1)
                            {
                                RatablePeriodSet currentMonthRPS = rrSchedule.getRatablePeriodSet(month.pse__End_Date__c);
                                if(currentMonthRPS != null && currentMonthRPS.firstMonthEndDate < month.pse__End_Date__c)
                                {
                                    // This month falls after the beginning of a ratable period set. Go back and spread the billings from prior months
                                    // over the current and upcoming months of the set.
                                    for(Date pastPeriodEnd : currentMonthRPS.allMonthEndDates)
                                    {
                                        if(pastPeriodEnd < month.pse__End_Date__c)
                                        {
                                            pse__Time_Period__c ptp = timePeriodMap.get(pastPeriodEnd);
                                            String pastForecastKey = project.pse__Project_Id__c + '-' + ptp.Name;
                                            PSA_Project_Forecast__c pastProjectForecast = projectForecastMap.get(pastForecastKey);
                                            if(pastProjectForecast != null)
                                            {
                                                Decimal pastForecastServicesBillings = pastProjectForecast.PSA_Forecast_Services_Billings__c;
                                                rrSchedule.applyBillingsForPeriod(pastPeriodEnd, pastForecastServicesBillings);
                                            }
                                        }
                                    }
                                }
                            }  

                            // For the current month onward, take the forecast services billings and spread it out over the remainder
                            // of its applicable ratable period set. Take the portion applicable to the month and apply it as the month's
                            // forecast services revenue
                            Decimal forecastServicesBillings = psaProjectForecastServicesBilling;
                            if(forecastServicesBillings==null) forecastServicesBillings = 0;
                            Decimal monthRevenue = rrSchedule.applyBillingsForPeriod(month.pse__End_Date__c, forecastServicesBillings);
                            projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                            projectForecast.PSA_Forecast_Services_Revenue__c = monthRevenue;
                            projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                            projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = forecastServicesBillings - monthRevenue;
                        }
                        else if(revenueForecastModel == 'As Delivered - Holdback' && project.PSA_BR_Holdback_Applies__c)
                        {
                            // Billing forecast will already account for any holdback credits and holdback release charges 
                            // So all we need to do is show the deferred services revenue as services billings times holdback percent
                            projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                            projectForecast.PSA_Forecast_Services_Revenue__c = psaProjectForecastServicesBilling;
                            projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;

                            if(month.pse__End_Date__c < project.PSA_BR_Holdback_End_Date__c)
                            {
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = psaProjectForecastServicesBilling * (project.PSA_BR_Holdback_Pct__c / 100);
                            }
                            else
                            {
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = 0;
                            }
                        }
                        else if(revenueForecastModel == 'As Delivered - Subject to Refund')
                        {
                            System.debug('~~~~~~Processing forecast subject to refund for month ending ' + month.pse__End_Date__c);
                            System.debug('~~~~~~Previously deferred amount is ' + refundDeferredAmount);
                            Decimal servicesBillings = psaProjectForecastServicesBilling;
                            if(servicesBillings==null) servicesBillings = 0;
                            Decimal refundAmount = servicesBillings * (refundPercent / 100);
                            Decimal amountToDefer = 0, amountToRecognize = 0;

                            // Determine whether the refund expiration date has passed and if this is the first month
                            // after the expiration date
                            if(month.pse__End_Date__c > refundExpirationDate)
                            {
                                if(month.pse__End_Date__c.addMonths(-1) <= refundExpirationDate)
                                {
                                    // This is the first month following the refund expiration date
                                    // In addition to all of the current month billing forecast, past deferral will be recognized
                                    System.debug('~~~~~~Just passed exp date. Will recognize ' + servicesBillings + ' for current month plus ' + refundDeferredAmount + ' of prior deferral.');
                                    amountToDefer = 0;
                                    amountToRecognize = servicesBillings + refundDeferredAmount;
                                }
                                else
                                {
                                    // This is after the first month following refund expiration
                                    // Nothing will be deferred and forecast billings will be recognized
                                    amountToDefer = 0;
                                    amountToRecognize = servicesBillings;
                                    System.debug('~~~~~~Exp date passed before last month. Will recognize ' + amountToRecognize + ' and defer none.');
                                }
                            }
                            else
                            {
                                // Before the refund expiration date.  
                                // See if the accumulated deferred revenue has hit the cap
                                if (refundDeferredAmount >= refundCap)
                                {
                                    // Cap was exceeded in a prior period. Recognize all billings and defer none.
                                    amountToDefer = 0;
                                    amountToRecognize = servicesBillings;
                                    System.debug('~~~~~~Cap was exceeded before. Will defer 0 and forecast ' + amountToRecognize);
                                }
                                else if (refundDeferredAmount < refundCap && refundDeferredAmount + refundAmount > refundCap)
                                {
                                    // Cap was just exceeded in this period. Recognize the over-cap portion and defer the under-cap portion.
                                    //amountToRecognize = (refundDeferredAmount + refundAmount) - refundCap;
                                    amountToDefer = refundCap - refundDeferredAmount;
                                    amountToRecognize = servicesBillings - amountToDefer;
                                    System.debug('~~~~~~Exceeded cap: ' + refundCap + ' at ' + (refundDeferredAmount+amountToDefer) + '. Will defer ' + amountToDefer + ' and forecast ' + amountToRecognize);
                                }
                                else
                                {
                                    // Still under the cap. Defer the whole refund amount.
                                    amountToRecognize = servicesBillings - refundAmount;
                                    amountToDefer = refundAmount;
                                    System.debug('~~~~~~Under cap: ' + refundCap + ' at ' + (refundDeferredAmount+amountToDefer) + '. Will defer ' + amountToDefer + ' and forecast 0');
                                }

                            }

                            // Increment refund amount by whatever was deferred
                            refundDeferredAmount += amountToDefer;

                            // Update the project forecast
                            System.debug('~~~~~~Forecast Revenue: ' + amountToRecognize + ' and deferred revenue: ' + amountToDefer);
                            projectForecast.PSA_Forecast_Expense_Revenue__c =  psaProjectForecastExpenseBilling;
                            projectForecast.PSA_Forecast_Services_Revenue__c = amountToRecognize;
                            projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = 0;
                            projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = amountToDefer;
                        }
                        else if(revenueForecastModel == 'Percent Complete' || revenueForecastModel == 'Percent Complete - Services Only')
                        {
                            // If this is the CURRENT month, calculate the accumulated revenue for past periods plus current period
                            if(currentMonthNumber==1)
                            {
                                Date pastMonthEnd = projectStartDate.addMonths(1).toStartOfMonth() -1;
                                while(pastMonthEnd < month.pse__End_Date__c)
                                {
                                    pse__Time_Period__c ptp = timePeriodMap.get(pastMonthEnd);
                                    String pastForecastKey = project.pse__Project_Id__c + '-' + ptp.Name;
                                    PSA_Project_Forecast__c pf = projectForecastMap.get(pastForecastKey);
                                    if(pf != null)
                                    {
                                        System.debug('~~~~~ Applying percent complete calc for past month: ' + pastMonthEnd);
                                        PercentCompleteResults pastPCR = pcrSchedule.applyBillingsForPeriod(pf, percentCompleteIsServicesOnly);
                                        System.debug('~~~~~ Past PCR: ' + pastPCR);
                                    }
                                    pastMonthEnd = pastMonthEnd.addMonths(2).toStartOfMonth() -1;
                                }
                            }

                            // Calculate revenue for the month in question
                            PercentCompleteResults pcr = pcrSchedule.applyBillingsForPeriod(projectForecast, percentCompleteIsServicesOnly);
                            if(pcr != null)
                            {
                                System.debug('~~~~~ PCR for month ' + month.pse__End_Date__c + ': ' + pcr);
                                projectForecast.PSA_Forecast_Services_Revenue__c = pcr.currentServicesToForecast + pcr.priorServicesToForecast;
                                projectForecast.PSA_Forecast_Expense_Revenue__c = pcr.currentExpensesToForecast + pcr.priorExpensesToForecast;
                                projectForecast.PSA_Forecast_Deferred_Expense_Revenue__c = pcr.expenseBillings - pcr.currentExpensesToForecast;
                                projectForecast.PSA_Forecast_Deferred_Services_Revenue__c = pcr.servicesBillings - pcr.currentServicesToForecast;
                            }
                        }
                    }
                }
            }
        }

        // Update existing forecast records
        if(!revForecastsForUpdate.isEmpty()) Database.Update(revForecastsForUpdate);

        // Insert new forecast records
        if(!revForecastsForInsert.isEmpty()) Database.Insert(revForecastsForInsert);

    }

    /*****************************************************************************************************************/
    /** Given a list of PSA Project Forecast records for a project, ordered by month, returns the latest one        **/
    /*****************************************************************************************************************/
    private static Date getLastForecastDate(List<PSA_Project_Forecast__c> forecastList)
    {
        Date lastForecastDate = null;
        if(forecastList != null &&  forecastList.size() > 0)
        {
            PSA_Project_Forecast__c pfc = forecastList.get(forecastList.size() -1);
            lastForecastDate = pfc.PSA_For_Month_Ending__c;
        }
        return lastForecastDate;
    }

    /*****************************************************************************************************************/
    /** Given a list of PSA Project Forecast records for a project, ordered by month, returns the latest one that has 
    /** a non-zero value for its Forecast Billings amount                                                             
    /*****************************************************************************************************************/
    private static Date getLastForecastDateWithBillingForecast(List<PSA_Project_Forecast__c> forecastList)
    {
        Date lastForecastDate = null;
        if(forecastList != null &&  forecastList.size() > 0)
        {
            for(PSA_Project_Forecast__c pfc : forecastList)
            {
                if(pfc.PSA_Forecast_Billings__c > 0) lastForecastDate = pfc.PSA_For_Month_Ending__c;
            }
        }
        return lastForecastDate;
    }

    /*****************************************************************************************************************/
    /** Given a map of PSA Project Forecast records for a project, finds the Project Forecast                       **/
    /** record for <monthsBefore> months prior to the month provided.  If not found, returns null                   **/
    /*****************************************************************************************************************/
    private static PSA_Project_Forecast__c getPriorBillingForecast(String projectId, List <pse__Time_Period__c> timePeriods, Map <String, PSA_Project_Forecast__c> forecastMap, Date currentMonthEnd, Integer monthsBefore)
    {
        PSA_Project_Forecast__c priorForecast = null;
        Date priorMonthEnd = currentMonthEnd.toStartOfMonth().addMonths(-1 * (monthsBefore -1)) -1;
        String forecastKey = '';
        for(pse__Time_Period__c tp : timePeriods)
        {
            if(tp.pse__End_Date__c == priorMonthEnd)
            {
                forecastKey = projectId + '-' + tp.Name;
                priorForecast = forecastMap.get(forecastKey);
                break;
            }
        }
        return priorForecast;
    }

    /*****************************************************************************************************************/
    /** Given a map of PSA Project Forecast records for a project, returns a list of all forecasts for periods      **/
    /** prior to the specified date                                                                                 **/
    /*****************************************************************************************************************/
    private static List<PSA_Project_Forecast__c> getPriorBillingForecasts(Map <String, PSA_Project_Forecast__c> forecastMap, Date currentMonthEnd)
    {
        List<PSA_Project_Forecast__c> priorForecastList = new List<PSA_Project_Forecast__c>();
        List<PSA_Project_Forecast__c> allForecasts = forecastMap.values();
        if(allForecasts!=null && allForecasts.size() > 0)
        {
            for(PSA_Project_Forecast__c pf : allForecasts)
            {
                if(pf.PSA_For_Month_Ending__c < currentMonthEnd)
                {
                    priorForecastList.add(pf);
                }
            }
        }
        return priorForecastList;
    }


    /*****************************************************************************************************************/
    /** This method allows the billing forecast refresh to be called from the project detail page                   **/
    /*****************************************************************************************************************/
    Webservice static string refreshBillingForecast(string projId)
    {
        string message = '';
        try
        {
            psaProjectForecastCalculation.calculateBillingForecast(new List<Id>{projId});
            message = 'SUCCESS';
        }
        catch(System.CalloutException e)
        {
            message = e.getMessage();
        }
        return message;
    }


    /*****************************************************************************************************************/
    /** This method allows the revenue forecast refresh to be called from the project detail page                   **/
    /*****************************************************************************************************************/
    Webservice static string refreshRevenueForecast(string projId)
    {
        string message = '';
        try
        {
            psaProjectForecastCalculation.calculateRevenueForecast(new List<Id>{projId});
            message = 'SUCCESS';
        }
        catch(System.CalloutException e)
        {
            message = e.getMessage();
        }
        return message;
    }

    /*****************************************************************************************************************/
    /** This method allows the billing and revenue forecast refresh to be called from the project detail page       **/
    /*****************************************************************************************************************/
    Webservice static string refreshBillingAndRevenueForecast(string projId)
    {
        string message = '';
        try
        {
            psaProjectForecastCalculation.calculateBillingForecast(new List<Id>{projId});
            psaProjectForecastCalculation.calculateRevenueForecast(new List<Id>{projId});
            message = 'SUCCESS';
        }
        catch(System.CalloutException e)
        {
            message = e.getMessage();
        }
        return message;
    }


    /**********************************************************************
    * This inner class is used for calculation of ratable revenue forecasts and holds the calculated revenue results.
    *
    * It contains the following:
    * - forecastBillingsMap: Map of forecasted services BILLINGS keyed on the period for which forecast
    * - forecastRevenueMap: Map of forecasted REVENUE resulting from ratable calculation, keyed on month for which forecast
    * - ratablePeriodSets: One or more RatablePeriodSet objects pertaining to the project's overall ratable revenue schedule
    ***********************************************************************/
    class RatableRevenueSchedule
    {
        String ratablePeriodPattern;
        Integer totalPeriodCount;
        List<RatablePeriodSet> ratablePeriodSets;
        Map<Date, Decimal> forecastBillingsMap;
        Map<Date, Decimal> forecastRevenueMap;
        Map<Date, RatablePeriodSet> monthToPeriodSetMap = new Map<Date, RatablePeriodSet>();
        Map<Date, Integer> remainingSetDaysMap;

        // Constructor. Uses project info and ratable period pattern definition to initialize a schedule for calculating
        // forecast revenue on a ratable basis
        public RatableRevenueSchedule(String ratablePeriodCounts, Date projectStartDate, Date currentMonthStartDate)
        {
            this.ratablePeriodPattern = ratablePeriodCounts == null ? '0' : ratablePeriodCounts;
            this.totalPeriodCount = 0;
            this.ratablePeriodSets = new List<RatablePeriodSet>();
            this.forecastBillingsMap = new Map<Date, Decimal>();
            this.forecastRevenueMap = new Map<Date, Decimal>();
            this.remainingSetDaysMap = new Map<Date, Integer>();
            
            // Create an integer list of ratable period counts
            List<String> ratablePeriodCountsTemp = ratablePeriodCounts.split(',');
            List<Integer> ratablePeriodCountsList = new List<Integer>();
            for(String s : ratablePeriodCountsTemp)
            {
                if(s.isNumeric())
                {
                    Integer x = Integer.valueOf(s);
                    ratablePeriodCountsList.add(x);
                }
            }
            System.debug('~~~~~~ Ratable Period Counts: ' + ratablePeriodCountsList);

            // For each number in the ratable period counts list, create a RatablePeriodSet.
            // Each will contain the information about a series of periods over which revenue will be forecast
            // in a ratable manner
            Date monthEndDate = projectStartDate.addMonths(1).toStartOfMonth() -1;
            for(Integer rpIndex = 0; rpIndex < ratablePeriodCountsList.size(); rpIndex++)
            {
                RatablePeriodSet rps = new RatablePeriodSet();
                rps.totalPeriodCount = 0;
                rps.remainingPeriodCount = 0;
                rps.totalDaysFromFirstMonth = 0;
                rps.totalDaysFromCurrentMonth = 0;
                List<Date> allMonthEndDatesForPeriodSet = new List<Date>();
                List<Date> remainingMonthEndDatesForPeriodSet = new List<Date>();
                rps.firstMonthEndDate = monthEndDate;
                rps.currentMonthEndDate = currentMonthStartDate.addMonths(1).toStartOfMonth() - 1;
                Integer currentPeriodCount = ratablePeriodCountsList.get(rpIndex);
                System.debug('~~~~~~ Processing period count: ' + currentPeriodCount);

                // For each month represented in the period set, create a list of month end dates representing
                // the months over which ratable revenue will be forecast
                for(Integer currPeriodIndex = 0; currPeriodIndex < currentPeriodCount; currPeriodIndex ++)
                {
                    System.debug('~~~~~ Handling ' + currPeriodIndex + ' of ' + currentPeriodCount);
                    System.debug('~~~~~ And month is ' + monthEndDate);
                    allMonthEndDatesForPeriodSet.add(monthEndDate);
                    if(monthEndDate >= Date.today())
                    {
                        remainingMonthEndDatesForPeriodSet.add(monthEndDate);
                        rps.remainingPeriodCount += 1;
                        rps.totalDaysFromCurrentMonth += Date.daysInMonth(monthEndDate.year(), monthEndDate.month());
                    }
                    Integer daysInMonth = Date.daysInMonth(monthEndDate.year(), monthEndDate.month());
                    rps.totalDaysFromFirstMonth += daysInMonth;
                    rps.totalPeriodCount += 1;
                    totalPeriodCount += 1;
                    
                    // Initialize the forecast billings and forecast revenue maps
                    forecastBillingsMap.put(monthEndDate, 0);
                    forecastRevenueMap.put(monthEndDate, 0);
                    monthToPeriodSetMap.put(monthEndDate, rps);

                    // Increment month end for next iteration
                    monthEndDate = monthEndDate.addMonths(2).toStartOfMonth() - 1;
                }
                rps.lastMonthEndDate = monthEndDate;
                rps.allMonthEndDates = allMonthEndDatesForPeriodSet;
                rps.remainingMonthEndDates = remainingMonthEndDatesForPeriodSet;

                // Re-Iterate the months in the period set and create the map of remaining set days by month
                Integer accumSetDays = 0;
                for(Date rpsMonth : rps.allMonthEndDates)
                {
                    Integer daysInMonth = Date.daysInMonth(rpsMonth.year(), rpsMonth.month());
                    Integer remainingSetDays = rps.totalDaysFromFirstMonth - accumSetDays;
                    remainingSetDaysMap.put(rpsMonth, remainingSetDays);
                    accumSetDays += daysInMonth;
                }

                // Add to the list of sets of ratable periods
                this.ratablePeriodSets.add(rps);
                System.debug('~~~~~ Prepared Ratable Period Set: ' + rps);
            }
        }

        // Takes the forecast services billings for a given month and spreads it out as applicable
        // based on ratable revenue foreast pattern.  Returns the forecast revenue amount applicable
        // to the month provided. This will include any prior-summarized ratable revenue added to the period
        // plus the applicable portion of that passed in, which is the final revenue number for the period.
        public Decimal applyBillingsForPeriod(Date periodEndDate, Decimal forecastServicesBillings)
        {
            Decimal periodRevenue = 0;
            if(forecastServicesBillings==null) forecastServicesBillings = 0;

            // Find the appropriate ratable period set
            RatablePeriodSet rps = monthToPeriodSetMap.get(periodEndDate);
            if(rps!=null)
            {
                // Get remaining days for the set, from current month onward
                Integer remainingSetDays = remainingSetDaysMap.get(periodEndDate);

                // Divide billing amount by total days to get amount per day
                Decimal amountPerDay = forecastServicesBillings / remainingSetDays;
                System.debug('~~~~~~ Forecast billings for period ' + periodEndDate + ': ' + forecastServicesBillings);
                System.debug('~~~~~~ Remaining set days is ' + remainingSetDays + ' and amount per day is ' + amountPerDay);

                // Iterate through each month of the set starting with the month in question and 
                // calculate a revenue value based on days in the month and amount per day
                // JL 2015-05-14 changed to start at the beginning of the period set even if some periods have passed: for(Date d : rps.remainingMonthEndDates)
                for(Date d : rps.allMonthEndDates)
                {
                    if(d >= periodEndDate)
                    {
                        Integer daysInMonth = Date.daysInMonth(d.year(), d.month());
                        Decimal revenuePortionForMonth = amountPerDay * daysInMonth;
                        Decimal existingRevForMonth = forecastRevenueMap.get(d);
                        if(existingRevForMonth == null) existingRevForMonth = 0;
                        System.debug('~~~~~~ Already stored rev for month ' + d + ' is ' + existingRevForMonth);
                        System.debug('~~~~~~ New portion for month ' + d + ' is ' + revenuePortionForMonth);
                        if(existingRevForMonth==null) existingRevForMonth = 0;
                        existingRevForMonth += revenuePortionForMonth;
                        System.debug('~~~~~ Revenue for month ' + d + ' is ' + existingRevForMonth);
                        forecastRevenueMap.put(d, existingRevForMonth);
                    }
                }

                periodRevenue = forecastRevenueMap.get(periodEndDate);
                System.debug('~~~~~ FINAL Revenue for month ' + periodEndDate + ' is ' + periodRevenue);
            }
            else
            {
                System.debug('~~~~~~ No ratable period defined for ' + periodEndDate + '. Will recognize full billing forecast...');
                periodRevenue = forecastServicesBillings;
            }

            if(periodRevenue == null) periodRevenue = 0;
            return periodRevenue;
        }

        // Finds and returns the RatablePeriodSet containing the month provided 
        public RatablePeriodSet getRatablePeriodSet(Date monthEndDate)
        {
            return monthToPeriodSetMap.get(monthEndDate);
        }

    }

    /**********************************************************************
    * This inner class is used for calculation of ratable revenue forecasts.
    * It contains information about a specific set of sequential periods over which 
    * revenue may need to be split on a ratable basis. 
    *
    * It contains the following:
    * - firstMonthEndDate: End Date of the first month of the set
    * - lastMonthEndDate: End Date of the last month of the set of ratable periods
    * - currentMonthEndDate: End Date of the current month
    * - allMonthEndDates: List of month end dates for all periods in the set
    * - remainingMonthEndDates: List of month end dates from current month to the end of the set
    * - totalPeriodCount: Number of months represented in the set
    * - remainingPeriodCount: Number of months from current month through the end of the set
    * - totalDaysFromFirstMonth: Total calendar days included in the months comprising the full set of months
    * - totalDaysFromCurrentMonth: Total calendar days included in months starting with the current month
    ***********************************************************************/
    class RatablePeriodSet
    {
        Date firstMonthEndDate;
        Date lastMonthEndDate;
        Date currentMonthEndDate;
        List<Date> allMonthEndDates;
        List<Date> remainingMonthEndDates;
        Integer totalPeriodCount;
        Integer remainingPeriodCount;
        Integer totalDaysFromFirstMonth;
        Integer totalDaysFromCurrentMonth;
    }


    /**********************************************************************
    * This inner class is used for calculation of percent complete revenue forecasts and holds the calculated revenue results.
    *
    * It contains the following:
    * - billingAndRevenueSchedule: Map of PercentCompleteResults keyed on the period for which forecast
    * - lastPercentComplete: The percent complete value for the most recently processed month. If the most recently processed is empty, provides the prior non-zero value
    * - cumulativeServicesBillings: Sum of services billings over months processed
    * - cumulativeExpensesBillings: Sum of expense billings over months processed
    ***********************************************************************/
    class PercentCompleteRevenueSchedule
    {
        Map <Date, PercentCompleteResults>  billingAndRevenueSchedule;
        Decimal lastPercentComplete;
        Decimal cumulativeServicesBillings;
        Decimal cumulativeExpensesBillings;

        public PercentCompleteRevenueSchedule()
        {
            billingAndRevenueSchedule = new Map <Date, PercentCompleteResults>();
            lastPercentComplete = 0;
            cumulativeServicesBillings = 0;
            cumulativeExpensesBillings = 0;
        }


        /**********************************************************************
        * Takes a Project Forecast for a period and calculates revenue for the period based
        * on forecast billings and percent complete.  For each period's billings, tracks
        * cumulative billings and the percent complete values provided in order to 
        * accumulate revenue properly.
        *
        * If "Services Only" then this will not defer and accumulate expense revenue, and will instead
        * treat it as forecast as-billed. 
        ***********************************************************************/
        public PercentCompleteResults applyBillingsForPeriod(PSA_Project_Forecast__c projectForecast, boolean servicesOnly)
        {
            PercentCompleteResults pcr = new PercentCompleteResults();
            pcr.monthEndDate = projectForecast.PSA_For_Month_Ending__c;

            // Set Services Billings
            Decimal servicesBillings = projectForecast.PSA_Forecast_Services_Billings__c;
            if(servicesBillings == null) servicesBillings = 0;
            pcr.servicesBillings = servicesBillings;
            
            // Set Expense Billings
            Decimal expenseBillings = projectForecast.PSA_Forecast_Expense_Billings__c;
            if(expenseBillings == null) expenseBillings = 0;
            pcr.expenseBillings = expenseBillings;
            
            // Set Total Billings
            pcr.totalBillings = servicesBillings + expenseBillings;

            // Get the current month percent complete. If there's no value, use the percent complete
            // supplied for the most recent month having a non-zero value
            Decimal percentComplete = projectForecast.PSA_Forecast_Percent_Complete__c;
            if(percentComplete == null) percentComplete = lastPercentComplete;
            pcr.percentComplete = percentComplete;

            // Calculate forecast revenue based on forecast billings and percent complete
            pcr.currentServicesToForecast = pcr.servicesBillings * (percentComplete/100);
            if(servicesOnly)
            {
                pcr.currentExpensesToForecast = pcr.expenseBillings;
            }
            else
            {
                pcr.currentExpensesToForecast = pcr.expenseBillings * (percentComplete/100);
            }
            
            pcr.totalRevenueToForecast = pcr.currentServicesToForecast + pcr.currentExpensesToForecast;
            pcr.priorServicesToForecast = cumulativeServicesBillings * ((percentComplete - lastPercentComplete) / 100);

            if(servicesOnly)
            {
                pcr.priorExpensesToForecast = 0;
            }
            else
            {
                pcr.priorExpensesToForecast = cumulativeExpensesBillings * ((percentComplete - lastPercentComplete) / 100);
            }
            
            pcr.cumulativeRevenueToForecast = pcr.priorServicesToForecast + pcr.priorExpensesToForecast + pcr.totalRevenueToForecast;
            pcr.deferredRevenueForPeriod = pcr.totalBillings - pcr.totalRevenueToForecast;

            // Update the cumulative amounts with the latest month
            cumulativeServicesBillings += servicesBillings;
            cumulativeExpensesBillings += expenseBillings;
            pcr.cumulativeBillings = cumulativeServicesBillings + cumulativeExpensesBillings;

            // Set most recent percent complete value
            lastPercentComplete = percentComplete;

            // Add to map
            billingAndRevenueSchedule.put(projectForecast.PSA_For_Month_Ending__c, pcr);
            return pcr;
        }
    }



    /**********************************************************************
    * This inner class is used for calculation of percent complete forecasts.
    * It contains information about cumulative billings and revenue, with revenue
    * based on percent complete.  Each is for a specific month.
    *
    * It contains the following:
    * - monthEndDate: End Date of the month to which the data pertains
    * - percentComplete: Percent complete value pertaining to the current month
    * - servicesBillings: Amount of services billings for the period 
    * - expenseBillings: Amount of expense billings for the period 
    * - totalBillings: Sum of services and expense billings
    * - cumulativeBillings: Current month billings plus all past month billings
    * - currentServicesToForecast: servicesBillings times percentComplete
    * - currentExpensesToForecast: expenseBillings times percentComplete
    * - priorServicesToForecast: Amount of prior deferred services revenue to recognize based on current month percent complete
    * - priorExpensesToForecast: Amount of prior deferred expense revenue to recognize based on current month percent complete
    * - totalRevenueToForecast: current services and expenses plus prior services and expenses
    * - cumulativeRevenueToForecast: totalRevenueToForecast from current and prior months
    * - deferredRevenueForPeriod: totalBillings minus totalRevenueToForecast
    ***********************************************************************/
    class PercentCompleteResults
    {
        Date monthEndDate;
        Decimal percentComplete;
        Decimal servicesBillings;
        Decimal expenseBillings;
        Decimal totalBillings;
        Decimal cumulativeBillings;
        Decimal currentServicesToForecast;
        Decimal currentExpensesToForecast;
        Decimal priorServicesToForecast;
        Decimal priorExpensesToForecast;
        Decimal totalRevenueToForecast;
        Decimal cumulativeRevenueToForecast;
        Decimal deferredRevenueForPeriod;
    }
/*
    private static void codeCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
*/  
}