/****************************************************************************************
Name            : psaBillingHistory
Author          : CLD Partners
Created Date    : February 15, 2016
Description     : Contains methods to copy billing event and related records into billing 
                    event history custom objects
Revisions       : 2/15/16 - Klassen Initial version
                : 3/8/16 - Klassen Scheduling update to make job timing more flexible
******************************************************************************************/
public without sharing class psaBillingHistory {

    /**************************************************************************************
    // Name         : copyInvoiceSummaryLine
    // Description  : Creates a copy of deleted Invoice Summary Line records in the 
    //                  Invoice Summary Line History object
    // Author       : CLD Partners
    // Revisions    : 2016-02-16  Klassen  Initial version
    //              : 
    ***************************************************************************************/
	public static void copyInvoiceSummaryLine(List<PSA_Billing_Event_History__c> beHistoryList) {
		//Build a map of Billing Event History records which will be used to match up to child
		// invoice summary line history records
		Map<String, PSA_Billing_Event_History__c> beHistoryMap = new Map<String, PSA_Billing_Event_History__c>();
		if (beHistoryList != null && beHistoryList.size() > 0) {
			for (PSA_Billing_Event_History__c beHistory : beHistoryList) {
				beHistoryMap.put(beHistory.PSA_Name__c, beHistory); 
			}
		}

		//Populate a list of invoice summary lines to copy into invoice summary line history
		List<PSA_Invoice_Summary_Line__c> invSummaryLines = 
			[Select Id, Name, PSA_Amount__c, PSA_Billing_Event_Name__c, PSA_Description__c, 
					PSA_Summary_Line_Type__c, CurrencyISOCode 
				From PSA_Invoice_Summary_Line__c
				Where PSA_Billing_Event_Name__c = :beHistoryMap.keySet() 
				Order By Name
			];

		//Copy the Invoice Summary Line records into the Invoice Summary Line History object
		List<PSA_Invoice_Summary_Line_History__c> islHistoryList = new List<PSA_Invoice_Summary_Line_History__c>();
		PSA_Billing_Event_History__c beHistoryLookup;
		for (PSA_Invoice_Summary_Line__c isl : invSummaryLines) {
			beHistoryLookup = beHistoryMap.get(isl.PSA_Billing_Event_Name__c);

			PSA_Invoice_Summary_Line_History__c islHistory = new PSA_Invoice_Summary_Line_History__c();
			islHistory.PSA_Amount__c = isl.PSA_Amount__c;
			islHistory.PSA_Billing_Event_Name__c = isl.PSA_Billing_Event_Name__c;
			islHistory.PSA_Billing_Event_History__c = beHistoryLookup.Id;
			islHistory.PSA_Description__c = isl.PSA_Description__c;
			islHistory.Summary_Line_Id__c = isl.Name;
			islHistory.PSA_Summary_Line_Type__c = isl.PSA_Summary_Line_Type__c;
			islHistory.CurrencyISOCode = isl.CurrencyISOCode;
			islHistoryList.add(islHistory);
		}

		if (islHistoryList.size() > 0) {
			insert islHistoryList;
		}
	}

    /**************************************************************************************
    // Name         : copyBillingEvent
    // Description  : Creates a copy of deleted Billing Event records in the Billing Event History object
    //                  
    // Author       : CLD Partners
    // Revisions    : 2016-02-16  Klassen  Initial version
    //              : 
    ***************************************************************************************/
	public static void copyBillingEvent(List<pse__Billing_Event__c> billingEvents) {
		List<PSA_Billing_Event_History__c> beHistoryList = new List<PSA_Billing_Event_History__c>();
		
		for (pse__Billing_Event__c be : billingEvents) {
			PSA_Billing_Event_History__c beh = new PSA_Billing_Event_History__c();
			beh.CurrencyISOCode = be.CurrencyISOCode;
			beh.PSA_Account_Discount_Services_Total__c = be.PSA_Account_Discount_Services_Total__c;
			beh.PSA_Approved__c = be.pse__Is_Approved__c;
			beh.PSA_Billing_Detail_Template__c = be.PSA_Billing_Detail_Template__c;
			beh.PSA_Bill_To_Contact__c = be.PSA_Bill_To_Contact__c;
			beh.PSA_CIM_Reviewed__c = be.PSA_CIM_Reviewed__c;
			beh.PSA_CIM_User__c = be.PSA_CIM_User__c;
			beh.PSA_Comments__c = be.PSA_Comments__c;
			beh.PSA_Contact__c = be.pse__Billing_Contact__c;
			beh.PSA_Current_Billing_Amount__c = be.PSA_Current_Billing_Amount__c;
			beh.PSA_Current_Billing_Event_Item_Count__c = be.PSA_Current_Billing_Event_Item_Count__c;
			beh.PSA_Date__c = be.pse__Date__c;
			beh.PSA_Discount_Applied__c = be.PSA_Discount_Applied__c;
			beh.PSA_Expense_Credits_Applied__c = be.PSA_Expense_Credits_Applied__c;
			beh.PSA_Expense_Total__c = be.PSA_Expense_Total__c;
			beh.PSA_Holdback_Applied__c = be.PSA_Holdback_Applied__c;
			beh.PSA_Holdback_Release_Applied__c = be.PSA_Holdback_Release_Applied__c;
			beh.PSA_Integration_Status__c = be.PSA_Integration_Status__c;
			beh.PSA_Invoiced__c = be.pse__Invoiced__c;
			beh.PSA_Invoice_Date__c = be.pse__Invoice_Date__c;
			beh.PSA_Invoice_Number__c = be.pse__Invoice_Number__c;
			beh.PSA_Name__c = be.Name;
			beh.PSA_PM_Reviewed__c = be.PSA_PM_Reviewed__c;
			beh.PSA_PO_Number__c = be.PSA_PO_Number__c;
			beh.PSA_Project__c = be.pse__Project__c;
			beh.PSA_Billing_Stage__c = be.PSA_Billing_Stage__c;
			beh.PSA_Released__c = be.pse__Is_Released__c;
			beh.PSA_Send_CIM_Notification__c = be.PSA_Send_CIM_Notification__c;
			beh.PSA_Services_Credits_Applied__c = be.PSA_Services_Credits_Applied__c;
			beh.PSA_Ship_To_Contact__c = be.PSA_Ship_To_Contact__c;
			beh.PSA_Special_Invoice_Instructions__c = be.PSA_Special_Invoice_Instructions__c;
			beh.PSA_Status__c = be.pse__Status__c;
			beh.PSA_Summary_Amount__c = be.pse__Summary_Amount__c;
			beh.PSA_T_M_Services_Total__c = be.PSA_T_M_Services_Total__c;
			beh.PSA_Time_Period__c = be.PSA_Time_Period__c;
			beh.PSA_Prior_Billing_Event__c = be.PSA_Prior_Billing_Event__c;
			beHistoryList.add(beh);
		}

		//Insert any billing event history records
		if (beHistoryList.size() > 0) {
			insert beHistoryList;

			//now copy the related invoice summary lines
			copyInvoiceSummaryLine(beHistoryList);
		}
	}

    /**************************************************************************************
    // Name         : scheduleLinkNewBEtoPriorBE
    // Description  : Check if a scheduled job to link Billing Events with Prior Billing Events
    //                  already exists.  If so, do nothing, if not, schedule the job
    // Author       : CLD Partners
    // Revisions    : 2016-02-16  Klassen  Initial version
    //              : 
    ***************************************************************************************/
	public static void scheduleLinkNewBEtoPriorBE() {
		//Check if a scheduled job already exists for this.  If not, schedule it.
		List<CronJobDetail> apexJobs = 
        	[select Id, JobType, Name 
        		from CronJobDetail
           		where Name Like 'PSA Billing Event Link 1 Time: %'
           	];
        if (apexJobs != null && apexJobs.size() > 0) {
        	System.Debug('psaBillingHistorySchedulable has already been scheduled, so not scheduling again');
        } else {
        	scheduleBillingEventsLinkToHistory();
        }
	}

    /**************************************************************************************
    // Name         : linkNewBEtoPriorBE
    // Description  : If applicable, add the Prior Billing Event (History) to Billing Events
    //                  
    // Author       : CLD Partners
    // Revisions    : 2016-02-16  Klassen  Initial version
    //              : 
    ***************************************************************************************/
	public static void linkNewBEtoPriorBE() {
		Date lastXDays = Date.today().addDays(-90);

		//Populate a set of Billing Events to exclude if there is more than one billing event per Project
		// and Time Period combination -- won't know which billing event to link to a prior billing event
		Set<String> beToExcludeKeySet = new Set<String>();
		AggregateResult[] billingEventsToExclude = 
			[select pse__Project__r.Name ProjName, pse__Project__c ProjId, PSA_Time_Period__c TimePeriod, 
					count(Id) RecCount
				from pse__Billing_Event__c
				group by  pse__Project__r.Name, pse__Project__c, PSA_Time_Period__c
				having count(Id) > 1
			];
		if (billingEventsToExclude != null && billingEventsToExclude.size() > 0) {
			for (AggregateResult be : billingEventsToExclude) {
				beToExcludeKeySet.add(be.get('ProjId') + ':' + be.get('TimePeriod'));
			}
		}
		System.debug('Billing Events To Exclude From Linking: ' + billingEventsToExclude);

		//build a map of prior billing events -- limit to last x days.  If the same BE has been
		// regenerated multiple times, it should use the most recent be history record -- this is
		// controlled by sorting on the CreatedDate field
		String mapKey;
		List<PSA_Billing_Event_History__c> beHistoryList = 
			[Select Id, PSA_Name__c, PSA_Project__c, PSA_Time_Period__c, CreatedDate
				From PSA_Billing_Event_History__c
				Where CreatedDate > :lastXDays
				Order By CreatedDate
			];
		Map<String, PSA_Billing_Event_History__c> beHistoryMap = new Map<String, PSA_Billing_Event_History__c>();
		if (beHistoryList != null && beHistoryList.size() > 0) {
			for (PSA_Billing_Event_History__c beHistory : beHistoryList) {
				mapKey = beHistory.PSA_Project__c + ':' + beHistory.PSA_Time_Period__c;
				beHistoryMap.put(mapKey, beHistory);
				System.debug('Billing Event History: ' + beHistory);
			}
		}
		

		//build a list of billing events in the last x days and attempt to fill in the prior billing event
		// if it's blank.  Exclude any that match the beToExcludeKeySet.
		List<pse__Billing_Event__c> billingEventsToUpdate = new List<pse__Billing_Event__c>();
		List<pse__Billing_Event__c> billingEventsToLink = 
			[select Name, pse__Project__r.Name, pse__Project__c, PSA_Time_Period__c, PSA_Prior_Billing_Event__c
				from pse__Billing_Event__c
				where CreatedDate > :lastXDays
				and PSA_Prior_Billing_Event__c = null
			];
		if (billingEventsToLink != null && billingEventsToLink.size() > 0) {
			PSA_Billing_Event_History__c beHistoryLookup;
			for (pse__Billing_Event__c be : billingEventsToLink) {
				mapKey = be.pse__Project__c + ':' + be.PSA_Time_Period__c;
				beHistoryLookup = beHistoryMap.get(mapKey);
				System.debug('Map Key/Billing Event: ' + mapKey + '--' + be);
				if (beHistoryLookup != null) {
					System.debug('BE History: ' + beHistoryLookup);

					//check if the mapKey is in the set of excluded billing events.  if not, link the be
					if (!beToExcludeKeySet.contains(mapKey)) {
						System.debug('Setting Prior Billing Event: ' + be.Name + '--' + beHistoryLookup);
						be.PSA_Prior_Billing_Event__c = beHistoryLookup.Id;
						billingEventsToUpdate.add(be);
					}
				}
			}

			System.debug('Billing Events To Update: ' + billingEventsToUpdate);
			if (billingEventsToUpdate.size() > 0) {
				update billingEventsToUpdate;
			}
		}
	}

	/**************************************************************************************
    // Name         : scheduleBillingEventsLinkToHistory
    // Description  : Create a scheduled job to link current billing events to prior ones
    //					based on a matching project and time period
    // Author       : CLD Partners
    // Revisions    : 2016-02-19  Klassen  Initial version
    //              : 2016-03-08  Klassen  Added custom settings lookup for how far in the 
    //					future to schedule the job
    ***************************************************************************************/
    public static void scheduleBillingEventsLinkToHistory() {
        //Build a Cron to schedule a job in the next x seconds
        //Set a default value for how far in the future to schedule the job and then attempt
        // to retrieve the value from a custom setting (PSA Billing)
        Integer xSeconds = 180;
		PSA_Billing__c psaBilling = PSA_Billing__c.getValues('default');
		if (psaBilling != null) {
			if (psaBilling.PSA_Billing_History_Job_Seconds_Delay__c != null) {
				xSeconds = Integer.valueOf(psaBilling.PSA_Billing_History_Job_Seconds_Delay__c);
			}
		}

		Datetime sysTime = System.now().addSeconds( xSeconds );
		String cronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + 
			sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        psaBillingHistorySchedulable s = new psaBillingHistorySchedulable(); 
        System.schedule('PSA Billing Event Link 1 Time: ' + String.valueOf(Datetime.now()), cronExpression, s);
    }

	/**************************************************************************************
	// Name         : sendEmailNotification
	// Description  : This method sends a notification via email 
	// Author       : CLD Partners
	// Revisions    : 2016-03-08  Klassen  Initial Implementation
	//              : 
	***************************************************************************************/
	public static void sendEmailNotification(String subjectText, String bodyText) {
		String notifyEmailList = '';
		PSA_Billing__c psaBilling = PSA_Billing__c.getValues('default');
		if (psaBilling != null) {
			if (psaBilling.PSA_Billing_History_Error_Notify_List__c != null) {
				notifyEmailList = psaBilling.PSA_Billing_History_Error_Notify_List__c;
			}
		}

		if (notifyEmailList != '') {
	        // Send a notification email 
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

	        String[] toAddresses = notifyEmailList.split(',');       
	        mail.setToAddresses(toAddresses);
	        mail.setSubject(subjectText);
	        mail.setPlainTextBody(bodyText);

	        if (!Test.isRunningTest()) {
		        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        }
		}
	}
}