/****************************************************************************************
Name            : psaRefreshProjectBillingBalances
Author          : CLD Partners 
Created Date    : April 22, 2015
Description     : Resets Billing Event and Project "To Date" balances related to Billing
					
Revisions       : 2015-04-22 - Initial version (extracted from psaBillingRulesApplication)
				: 2015-08-04 - Added custom apex debug logging
                : 2015-11-17 - Modified to use Expense and Misc. Adj. source amounts rather than BEI amounts
                : 2016-01-06 - Fixed bug that was causing users to have to check the CIM Reviewed
                                box on Billing Events twice -- solved by rounding the Current Billing Amount
******************************************************************************************/
public with sharing class psaRefreshProjectBillingBalances {
    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaRefreshProjectBillingBalances';
    private static Integer apexLogMethodSequenceMaster = 0;
    
	public psaRefreshProjectBillingBalances() {}

    /**************************************************************************************
    // Name         : refreshBillingBalances
    // Description  : Update Billing Event Summary fields and add/update PSA Project Balances
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
//    public static void refreshBillingBalances(Set<Id> projectIds) {
    public static void refreshBillingBalances(Set<Id> billingEventIds, Set<Id> projectIds, 
            Set<Id> accountDiscountIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'refreshBillingBalances';

        //Add apex log records with the initial class variables
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Ids', String.valueOf(billingEventIds), null);
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project Ids', String.valueOf(projectIds), null);
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Account Discount Ids', String.valueOf(accountDiscountIds), null);

    	//Update the balances for all un-released billing events for the set of projects
    	updateBillingEventBalances(billingEventIds);

    	//Add or Update PSA Project Balance records
    	addOrUpdatePSAProjectBalances(billingEventIds);

    	//Update Account Discount "To-Date" fields
    	updateAccountDiscountBalances(accountDiscountIds);
    }

    /**************************************************************************************
    // Name         : updateAccountDiscountBalances
    // Description  : Update summary fields on PSA Account Discount records if either the
    //                  Discount Applied to Date or Eligible Billings to Date have changed
    // Author       : CLD Partners 
    // Revisions    : 2015-04-25  Klassen  Initial Implementation
    ***************************************************************************************/
    public static void updateAccountDiscountBalances(Set<Id> accountDiscountIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'updateAccountDiscountBalances';

        //Retrieve a list of Projects related to Account Discounts
        AggregateResult[] arProjects = 
            [Select PSA_BR_Account_Discount__c AccountDiscountId, 
                    SUM(PSA_BR_Discount_Applied_To_Date_Number__c) TotalDiscount, 
                    SUM(PSA_BR_Discnt_Eligible_Billings_Number__c) TotalEligibleBillings 
                From pse__Proj__c
                Where PSA_BR_Account_Discount__c  =:accountDiscountIds  
                Group By PSA_BR_Account_Discount__c
            ];
        System.debug('Project List: ' + arProjects);
        //Add apex log records with the list of Projects
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Projects Aggregate List', String.valueOf(arProjects), null);

        //If there are any project balance records for Discount-related summaries, summarized the amounts at the
        // account-discount level
        if (arProjects != null && arProjects.size() > 0) {
            //Populate master map of PSA Account Discounts 
            Map<Id, PSA_Account_Discount__c> accountDiscountMasterMap = new Map<Id, PSA_Account_Discount__c>(
                [Select Id, 
                        PSA_Discount_Amount_Applied__c, 
                        PSA_Discount_Eligible_Billings_To_Date__c 
                    From PSA_Account_Discount__c
                ]);
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'accountDiscountMasterMap', String.valueOf(accountDiscountMasterMap), (List<SObject>)accountDiscountMasterMap.values());

            //Initialize a list of Account Discount records to be updated
            List<PSA_Account_Discount__c> accountDiscountsToUpdate = new List<PSA_Account_Discount__c>();
            PSA_Account_Discount__c accountDiscount;
            Boolean accountDiscountUpdated;
            For (AggregateResult ar : arProjects) {
                accountDiscountUpdated = false;

                //Retrieve the matching Account Discount record
                accountDiscount = accountDiscountMasterMap.get((Id)ar.get('AccountDiscountId'));

                //If the Discount Amount Applied has changed, update it and set the update flag to true
                if (accountDiscount.PSA_Discount_Amount_Applied__c != (Decimal)ar.get('TotalDiscount')) {
                    accountDiscount.PSA_Discount_Amount_Applied__c = (Decimal)ar.get('TotalDiscount');
                    accountDiscountUpdated = true;
                }
                //If the Discount Eligible Billings To Date amount has changed, update it and set the update flag to true
                if (accountDiscount.PSA_Discount_Eligible_Billings_To_Date__c != (Decimal)ar.get('TotalEligibleBillings')) {
                    accountDiscount.PSA_Discount_Eligible_Billings_To_Date__c = (Decimal)ar.get('TotalEligibleBillings');
                    accountDiscountUpdated = true;
                }
                //If the update flag is true, add the account discount record to the list of records to be updated
                if (accountDiscountUpdated == true) {
                    accountDiscountsToUpdate.add(accountDiscount);
                }
            }
            System.debug('Account Discounts to Update: ' + accountDiscountsToUpdate);
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Account Discounts to Update', String.valueOf(accountDiscountsToUpdate), (List<SObject>)accountDiscountsToUpdate);

            //DML - Update the list of Account Discount records (if there are any to be updated)
            if (accountDiscountsToUpdate.size() > 0) {
                update accountDiscountsToUpdate;
            }

            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Account Discounts Update Completed', null, null);
        }
    }

    /**************************************************************************************
    // Name         : addOrUpdatePSAProjectBalances
    // Description  : Add or update PSA Project Balance records based on a set of Billing Event Ids
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
    private static void addOrUpdatePSAProjectBalances(Set<Id> billingEventIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'addOrUpdatePSAProjectBalances';

    	List<PSA_Project_Balance__c> projectBalancesToAdd = new List<PSA_Project_Balance__c>();
    	List<PSA_Project_Balance__c> projectBalancesToUpdate = new List<PSA_Project_Balance__c>();

    	//Populate a Map of project balances using the Billing Event Id as the key
    	Map<Id, List<PSA_Project_Balance__c>> projectBalanceMap = new Map<Id, List<PSA_Project_Balance__c>>();
   		List<PSA_Project_Balance__c> projectBalances = new List<PSA_Project_Balance__c>();
    	Id previousId;
    	List<PSA_Project_Balance__c> currentProjectBalanceList = 
    		[Select Id, Name, PSA_Project__c, PSA_Balance_Type__c, PSA_Current_Balance__c, 
    			PSA_Billing_Level__c, PSA_Billing_Event__c  
    			From PSA_Project_Balance__c 
    			Where PSA_Billing_Event__c In :billingEventIds
    			Order By PSA_Billing_Event__c
    		];
        //Add apex log records with the list of Project Balances
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'currentProjectBalanceList', String.valueOf(currentProjectBalanceList), (List<SObject>)currentProjectBalanceList);
    	
        if (currentProjectBalanceList != null && currentProjectBalanceList.size() > 0) {
    		for (PSA_Project_Balance__c projectBalance : currentProjectBalanceList) {
    			if (previousId != null && projectBalance.PSA_Billing_Event__c != previousId) {
    				projectBalanceMap.put(previousId, projectBalances);
    				//System.debug('BillingEvent Balance Map: ' + projectBalanceMap);
    				projectBalances = new List<PSA_Project_Balance__c>();
    			}
    			projectBalances.add(projectBalance);
    			previousId = projectBalance.PSA_Billing_Event__c;
    		}
    		//Add the final list of project balances
			projectBalanceMap.put(previousId, projectBalances);
    	}
    	//System.debug('Project Balance Map: ' + projectBalanceMap);
        //Add apex log records with the Map of list of Project Balances
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Project Balance Map', String.valueOf(projectBalanceMap), null);

    	PSA_Project_Balance__c projectBalance;
    	String billingLevel;
    	String balanceType;
    	Decimal currentBalance;
    	Id projectId;
        Id billingEventId;
        String currencyCode;
		ProjectBalanceAddOrUpdate projBalanceAddOrUpdate; //Class that contains a PSA Project Balance and a "newRecord" flag

    	//Add/update PSA Project Balances for Timecard Splits at the Billing Level, IF the related project has any 
        // Billing Rules assigned that have to do with a set of Billing Levels.  BRs 5, 6, 12 and 13 are applicable
        //*** Don't think these records are being utilized in any other code but leaving code in place because not 100% sure 
        //***  cklassen 6/26
        AggregateResult[] arList = 
            [Select pse__Project__c Proj, pse__Billing_Event__c BillingEvent, CurrencyISOCode CurrencyCode, 
            		pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c BillingLevel, 
					SUM(pse__Timecard_Split__r.PSA_Total_Billable_Number__c) TimecardAmount 
                From pse__Billing_Event_Item__c
                Where pse__Billing_Event__c =:billingEventIds
                And pse__Timecard_Split__c != null 
                And (
                    pse__Project__r.PSA_BR_Account_Discount__r.PSA_Discount_Billing_Levels__c != null Or 
                    pse__Project__r.PSA_BR_Project_Discount_Billing_Levels__c != null Or 
                    pse__Project__r.PSA_BR_Billing_Levels_for_Expense_Amt__c != null Or 
                    pse__Project__r.PSA_BR_Billing_Levels_for_Expense_Pct__c != null
                )
                Group By pse__Project__c, pse__Billing_Event__c, CurrencyISOCode, pse__Timecard_Split__r.pse__Timecard_Header__r.PSA_Billing_Level__c
            ];    	
//	            and pse__Is_Released__c = false
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Aggregate List of Timecard Amount by Billing Level', String.valueOf(arList), null);

		if (arList != null && arList.size() > 0) {
			System.debug('arList: ' + arList);
			for (AggregateResult ar : arList) {
				projectId = (Id)ar.get('Proj');
                billingEventId = (Id)ar.get('BillingEvent');
				billingLevel = (String)ar.get('BillingLevel');
                currencyCode = (String)ar.get('CurrencyCode');
				projectBalances = projectBalanceMap.get(billingEventId);
				System.debug('Project Balances for Billing Event: ' + billingEventId + ': ' + projectBalances);

				//Create or update a PSA Project Balance record for each Billing Level
				//T&M Services for Billing Level 
				balanceType = 'T&M Services for Billing Level';
				currentBalance = (Decimal)ar.get('TimecardAmount');
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, billingLevel, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                }
			}
		}
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Aggregate List of Timecard Amount by Billing Level Completed', null, null);

    	//Since "Summary" fields have already been populated on each Billing Event, now loop through all Billing Events 
        // and add summary amounts to PSA Project Balance records
        List<pse__Billing_Event__c> billingEventList = 
            [Select Id, pse__Project__c, CurrencyISOCode, 
					PSA_Discount_Applied__c, 
					PSA_Expense_Credits_Applied__c, 
					PSA_Expense_Total__c, 
					PSA_Holdback_Applied__c, 
                    PSA_Holdback_Release_Applied__c, 
                    PSA_Services_Credits_Applied__c, 
					PSA_T_M_Services_Total__c, 
                    PSA_Account_Discount_Services_Total__c 
                From pse__Billing_Event__c
                Where Id =:billingEventIds
            ];    	
//	            and pse__Is_Released__c = false
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event List', String.valueOf(billingEventList), (List<SObject>)billingEventList);

		if (billingEventList != null && billingEventList.size() > 0) {
			System.debug('billingEventList: ' + billingEventList);
            ProjectBalanceAddOrUpdate projectBalanceToAddOrUpdate;

			for (pse__Billing_Event__c billingEvent : billingEventList) {
                projectId = billingEvent.pse__Project__c;
				billingEventId = billingEvent.Id;
                currencyCode = billingEvent.CurrencyISOCode;
				projectBalances = projectBalanceMap.get(billingEventId);
				System.debug('Project Balances for BillingEvent: ' + billingEventId + ': ' + projectBalances);
                //Add apex log record
                psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project Balances for Billing Event: ' + billingEventId, String.valueOf(projectBalances), (List<SObject>)projectBalances);

				//*** Create or update a PSA Project Balance record for each Balance Type
				//T & M Services
				balanceType = 'T&M Services Total';
				currentBalance = billingEvent.PSA_T_M_Services_Total__c;
                if (currentBalance != 0) {
    				projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
    				if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
    					projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
    				} else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
    					projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
    				}
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'T&M Services Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
				//Services Credits Applied
				balanceType = 'Services Credits Applied';
                currentBalance = billingEvent.PSA_Services_Credits_Applied__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Services Credits Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
				//Expense Total Billing
				balanceType = 'Expense Total Billing';
                currentBalance = billingEvent.PSA_Expense_Total__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Expense Total Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
				//Expense Credits Applied
				balanceType = 'Expense Credits Applied';
                currentBalance = billingEvent.PSA_Expense_Credits_Applied__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Expense Credits Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
				//Holdback Applied
				balanceType = 'Holdback Applied';
                currentBalance = billingEvent.PSA_Holdback_Applied__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Holdback Applied Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
                //Holdback Release Applied
                balanceType = 'Holdback Release Applied';
                currentBalance = billingEvent.PSA_Holdback_Release_Applied__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Holdback Release Applied Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
				//Discount Applied
				balanceType = 'Discount Applied';
                currentBalance = billingEvent.PSA_Discount_Applied__c;
                if (currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Discount Applied Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
                //Discount Services Total
                balanceType = 'Discount Services Total';
                currentBalance = billingEvent.PSA_Account_Discount_Services_Total__c;
                if (currentBalance != null && currentBalance != 0) {
                    projBalanceAddOrUpdate = setProjectBalance(projectId, balanceType, currentBalance, projectBalances, null, billingEventId, currencyCode);
                    if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.newRecord == true) {
                        projectBalancesToAdd.add(projBalanceAddOrUpdate.projectBalance);
                    } else if (projBalanceAddOrUpdate != null && projBalanceAddOrUpdate.updatedRecord == true) {
                        projectBalancesToUpdate.add(projBalanceAddOrUpdate.projectBalance);
                    }
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Discount Services Project Balance Added or Updated', String.valueOf(projBalanceAddOrUpdate), null);
                }
			}
		}

		//Perform the DML operations
		//System.debug('Project Balance Recs to Add: ' + projectBalancesToAdd);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project Balance Recs to Add', String.valueOf(projectBalancesToAdd), null);

    	if (projectBalancesToAdd.size() > 0) {
    		insert projectBalancesToAdd;
		}

		//System.debug('Project Balance Recs to Update: ' + projectBalancesToUpdate);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project Balance Recs to Update', String.valueOf(projectBalancesToUpdate), (List<SObject>)projectBalancesToUpdate);
		if (projectBalancesToUpdate.size() > 0) {
			update projectBalancesToUpdate;
		}
    }

    /**************************************************************************************
    // Name         : setProjectBalance
    // Description  : Update an existing PSA Project Balance record or create a new one
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
    private static ProjectBalanceAddOrUpdate setProjectBalance(Id projectId, String balanceType, 
    		Decimal currentBalance, List<PSA_Project_Balance__c> projectBalanceList, String billingLevel, 
            Id billingEventId, String currencyCode) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'setProjectBalance';

    	//Initialize return variable
    	ProjectBalanceAddOrUpdate projBalanceAddOrUpdate = new ProjectBalanceAddOrUpdate();

    	//Attempt to retrieve the applicable PSA Project Balance record.  If not found, create a new record
    	PSA_Project_Balance__c projectBalance;
        if (billingLevel != null) {
            projectBalance = getProjectBalanceByTypeAndBillingLevel(balanceType, projectBalanceList, billingLevel);
        } else {
            projectBalance = getProjectBalanceByType(balanceType, projectBalanceList);
        }
//        System.debug('Refresh Proj Bill Blnces: ' + projectBalanceList);
//        System.debug('Refresh Proj Bill Blnces: Found projectBalance: ' + projectBalance);
        //Add apex log records
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Project Balance', String.valueOf(projectBalance), null);

		if (projectBalance == null) {
			projectBalance = createPSAProjectBalance(projectId, balanceType, currentBalance, 
                    billingLevel, billingEventId, currencyCode);
			projBalanceAddOrUpdate.projectBalance = projectBalance;
			projBalanceAddOrUpdate.newRecord = true;
            //Add apex log records
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'New Project Balance', String.valueOf(projectBalance), null);
		} else {
			//Update the existing PSA Project Balance record if the balance has changed
			if (projectBalance.PSA_Current_Balance__c != currentBalance) {
                projectBalance.PSA_Current_Balance__c = currentBalance;
				projBalanceAddOrUpdate.projectBalance = projectBalance;
				projBalanceAddOrUpdate.updatedRecord = true;
                //Add apex log records
                psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Updated Project Balance', String.valueOf(projectBalance), null);
			}
		}

		return projBalanceAddOrUpdate;
	}

    /**************************************************************************************
    // Name         : CLASS: ProjectBalanceAddOrUpdate
    // Description  : This class is used to contain a PSA Project Balance record and a boolean 
    //					indicator if the record was created or updated
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
	public class ProjectBalanceAddOrUpdate{
		public PSA_Project_Balance__c projectBalance {get; set; }
		public Boolean newRecord {get; set; }
		public Boolean updatedRecord {get; set; }
	}

    /**************************************************************************************
    // Name         : getProjectBalance
    // Description  : Search a list of PSA Project Balances for a specific Project and 
    //					Balance Type and return a PSA Project Balance record if it exists
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
    private static PSA_Project_Balance__c getProjectBalanceByType(String balanceType, 
    		List<PSA_Project_Balance__c> projectBalanceList) {
    	if (projectBalanceList == null) {
    		return null;
    	} else {
    		for (PSA_Project_Balance__c projectBalance : projectBalanceList) {
    			if (projectBalance.PSA_Balance_Type__c == balanceType) {
    				return projectBalance;
    			}
    		}
    	}
    	//If we got through the list of Project Balances without finding one, return null
    	return null;
    }

    /**************************************************************************************
    // Name         : getProjectBalanceByTypeAndBillingLevel
    // Description  : Search a list of PSA Project Balances for a specific Project and 
    //                  Balance Type and Billing Level and return a PSA Project Balance record if it exists
    // Author       : CLD Partners 
    // Revisions    : 2015-07-14  Klassen  Initial Implementation
    ***************************************************************************************/
    private static PSA_Project_Balance__c getProjectBalanceByTypeAndBillingLevel(String balanceType, 
            List<PSA_Project_Balance__c> projectBalanceList, String billingLevel) {
        if (projectBalanceList == null) {
            return null;
        } else {
            for (PSA_Project_Balance__c projectBalance : projectBalanceList) {
                if (projectBalance.PSA_Balance_Type__c == balanceType && projectBalance.PSA_Billing_Level__c == billingLevel) {
                    return projectBalance;
                }
            }
        }
        //If we got through the list of Project Balances without finding one, return null
        return null;
    }

    /**************************************************************************************
    // Name         : createPSAProjectBalance
    // Description  : Create a new PSA Project Balance record
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    ***************************************************************************************/
    private static PSA_Project_Balance__c createPSAProjectBalance(Id projectId, 
    		String balanceType, Decimal currentBalance, String billingLevel, Id billingEventId, 
            String currencyCode) {
    	PSA_Project_Balance__c newPSAProjectBalance = new PSA_Project_Balance__c();
    	newPSAProjectBalance.PSA_Project__c = projectId;
    	newPSAProjectBalance.PSA_Balance_Type__c = balanceType;
    	newPSAProjectBalance.PSA_Current_Balance__c = currentBalance;
    	newPSAProjectBalance.PSA_Billing_Level__c = billingLevel;
        newPSAProjectBalance.PSA_Billing_Event__c = billingEventId;
        newPSAProjectBalance.CurrencyISOCode = currencyCode;

    	return newPSAProjectBalance;
    }

    /**************************************************************************************
    // Name         : updateBillingEventBalances
    // Description  : Rollup Billing Event Invoice Line Summary amounts.  These will be used
    //                  to add or update PSA Project Balance records which will in turn 
    //                  automatically roll-up on summary fields on the related Project
    // Author       : CLD Partners 
    // Revisions    : 2015-04-22  Klassen  Initial Implementation
    //              : 2016-01-06  Klassen  Added rounding to Current Billing Amount to fix
    //                  a bug which forced the user to check the CIM Reviewed box twice in
    //                  some cases
    ***************************************************************************************/
    private static void updateBillingEventBalances(Set<Id> billingEventIds) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'updateBillingEventBalances';

        //Populate a map of all relevant billing events
        Map<Id, pse__Billing_Event__c> billingEventMap = new Map<Id, pse__Billing_Event__c>(
            [Select Id, 
                    Name, 
                    pse__Is_Released__c, 
                    pse__Project__c, 
                    pse__Billing_Event_Batch__c, 
                    PSA_Time_Period__r.pse__Type__c, 
                    PSA_Time_Period__r.pse__Start_Date__c, 
                    PSA_Time_Period__r.pse__End_Date__c,
                    PSA_Discount_Applied__c, 
                    PSA_Individual_Expenses_Exist__c,
                    PSA_Individual_Timecards_Exist__c,
					PSA_Expense_Credits_Applied__c, 
					PSA_Expense_Total__c, 
					PSA_Holdback_Applied__c, 
                    PSA_Holdback_Release_Applied__c, 
					PSA_Services_Credits_Applied__c, 
					PSA_T_M_Services_Total__c, 
                    PSA_Current_Billing_Amount__c, 
                    PSA_Current_Billing_Event_Item_Count__c, 
					(Select pse__Billing_Event__c, pse__Billing_Event__r.Name, pse__Timecard_Split__c, pse__Expense__c, 
		                    pse__Milestone__c, pse__Milestone__r.PSA_Milestone_Type__c, pse__Milestone__r.PSA_Invoice_Description__c, 
		                    pse__Miscellaneous_Adjustment__c, pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c, 
		                    pse__Miscellaneous_Adjustment__r.pse__Amount__c, pse__Miscellaneous_Adjustment__r.Name, pse__Amount__c, 
                            pse__Timecard_Split__r.pse__Total_Billable_Amount__c, pse__Expense__r.pse__Billing_Amount__c, pse__Milestone__r.pse__Milestone_Amount__c 
	                	From pse__Billing_Event_Items__r
                	)
                From pse__Billing_Event__c
                Where Id =:billingEventIds
	            And pse__Is_Released__c = false
            ]);
        //Add apex log record
        psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Map', String.valueOf(billingEventMap), (List<SObject>)billingEventMap.values());

		List<pse__Billing_Event__c> billingEvents = billingEventMap.values();
		if (billingEvents != null && billingEvents.size() > 0) {

            //Loop through each billing event, updating each summary balance field based on various criteria from the
            // billing event item records
			for (pse__Billing_Event__c billingEvent : billingEvents) {
				if (billingEvent.pse__Billing_Event_Items__r != null && billingEvent.pse__Billing_Event_Items__r.size() > 0) {
                    System.debug('Refresh Project Billing Balances: Billing Event Items for: ' + billingEvent.Name + ' : ' + billingEvent.pse__Billing_Event_Items__r);
                    //Add apex log record
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Refresh Project Billing Balances: Billing Event Items for: ' + billingEvent.Name, String.valueOf(billingEvent.pse__Billing_Event_Items__r), null);

					//Reset the summary fields
					billingEvent.PSA_Discount_Applied__c = 0.0;
					billingEvent.PSA_Expense_Credits_Applied__c = 0.0;
					billingEvent.PSA_Expense_Total__c = 0.0;
					billingEvent.PSA_Holdback_Applied__c = 0.0;
					billingEvent.PSA_Services_Credits_Applied__c = 0.0;
					billingEvent.PSA_T_M_Services_Total__c = 0.0;
                    billingEvent.PSA_Current_Billing_Amount__c = 0.0;
                    billingEvent.PSA_Current_Billing_Event_Item_Count__c = 0;
                    billingEvent.PSA_Holdback_Release_Applied__c = 0;
                    //Loop through all bililng event items, categorizing them in the appropriate 6 buckets
					for (pse__Billing_Event_Item__c beItem : billingEvent.pse__Billing_Event_Items__r) {
                        //Update summary fields used to determine whether or not a billing event amount or number of items
                        // has changed -- used in the Billing Event trigger (before update)
                        if (beItem.pse__Miscellaneous_Adjustment__c != null) {
                            billingEvent.PSA_Current_Billing_Amount__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
                        } else if (beItem.pse__Timecard_Split__c != null) {
                            billingEvent.PSA_Current_Billing_Amount__c += beItem.pse__Timecard_Split__r.pse__Total_Billable_Amount__c;
                        } else if (beItem.pse__Expense__c != null) {
                            billingEvent.PSA_Current_Billing_Amount__c += beItem.pse__Expense__r.pse__Billing_Amount__c;
                        } else if (beItem.pse__Milestone__c != null) {
                            billingEvent.PSA_Current_Billing_Amount__c += beItem.pse__Milestone__r.pse__Milestone_Amount__c;
                        } else {
                            billingEvent.PSA_Current_Billing_Amount__c += beItem.pse__Amount__c;
                        }
                        billingEvent.PSA_Current_Billing_Event_Item_Count__c += 1;
                    
                        //"Bucket" each type of billing event item
						if (beItem.pse__Timecard_Split__c != null) {
                            billingEvent.PSA_Individual_Timecards_Exist__c = true;
							billingEvent.PSA_T_M_Services_Total__c += beItem.pse__Timecard_Split__r.pse__Total_Billable_Amount__c;
						} else if (beItem.pse__Expense__c != null) {
                            billingEvent.PSA_Individual_Expenses_Exist__c = true;
							billingEvent.PSA_Expense_Total__c += beItem.pse__Expense__r.pse__Billing_Amount__c;
						} else if (beItem.pse__Milestone__c != null) {
							if (beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Expenses - Fixed') {
								billingEvent.PSA_Expense_Total__c += beItem.pse__Milestone__r.pse__Milestone_Amount__c;
							//} else if (beItem.pse__Milestone__r.PSA_Milestone_Type__c == 'Billable Services - Fixed') {
							//	billingEvent.PSA_T_M_Services_Total__c += beItem.pse__Amount__c;
							}
						} else if (beItem.pse__Miscellaneous_Adjustment__c != null) {
							//If the billing event item is for a misc. adj., use the Billing Rule Type to determine
                            // which summary balance field to update
							if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Minimum Hours') {
								billingEvent.PSA_T_M_Services_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services - Time and Materials') {
								billingEvent.PSA_T_M_Services_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Cap Flat Amount') {
								billingEvent.PSA_Services_Credits_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Percent of Services') {
								billingEvent.PSA_Expense_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Charge - Flat Amount') {
								billingEvent.PSA_Expense_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - As Incurred') {
								billingEvent.PSA_Expense_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expenses - Fixed Amount') {
								billingEvent.PSA_Expense_Total__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Percent of Services') {
								billingEvent.PSA_Expense_Credits_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Expense Credit - Cap Flat Amount') {
								billingEvent.PSA_Expense_Credits_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Holdback') {
								billingEvent.PSA_Holdback_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
                            } else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Charge - Holdback Release') {
                                //Special logic to handle a holdback release problem where the be item amount doesn't match the misc. adj. amount
                                //if (beItem.pse__Amount__c != beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c) {
                                //    beItem.pse__Amount__c = beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
                                //}
                                billingEvent.PSA_Holdback_Release_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Customer Discount') {
								billingEvent.PSA_Discount_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							} else if (beItem.pse__Miscellaneous_Adjustment__r.PSA_Billing_Rule_Type__c == 'Services Credit - Project Discount') {
								billingEvent.PSA_Discount_Applied__c += beItem.pse__Miscellaneous_Adjustment__r.pse__Amount__c;
							}
                            //System.debug('Holdback Applied Amount: ' + billingEvent.PSA_Holdback_Applied__c);
						}
					}

                    //Added 1/6/16 by cklassen to fix an error where the user has to check the CIM Reviewed box twice
                    // Caused by a rounding issue in the standard SF detail page UI for currency fields, so the code
                    // needs to also round off the value to 2 places
                    billingEvent.PSA_Current_Billing_Amount__c = billingEvent.PSA_Current_Billing_Amount__c.setScale(2, RoundingMode.HALF_UP);
				}
			}

            //DML - Update all of the refreshed billing events
            //Add apex log record
            psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'About to update Billing Events', String.valueOf(billingEvents), (List<SObject>)billingEvents);
			update billingEvents;
		}
    }

}