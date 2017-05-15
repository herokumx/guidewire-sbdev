/****************************************************************************************
Name            : psaBillingEventRegenerateController
Author          : CLD Partners 
Created Date    : September 15, 2015
Description     : Controller class for the psaBillingEventRegenerate vf page 
Revisions       : 9/15/15 - Initial version
                : 9/28/15 - Klassen  Fixed Billing Event queries to use new custom BE
                    Time Period field instead of the billing event batch time period
                : 10/16/15 - Klassen  Add ability to prevent an email from getting sent to
                    CIM when the invoice docs are attached
                : 2/18/16 - Klassen  Add ability to link old BE with new BE via BE History object
******************************************************************************************/
public without sharing class psaBillingEventRegenerateController {

    private String currentBEId;
    private String step = '';
    private String currentJobId = '';
    private String projId = '';
    private String tpId = '';
    private String emailCIM = '0';
    private Integer counter = 0;
    private Integer retryCount = 0;
    public DateTime startDateTime {get; set;}
    public DateTime endDateTime {get; set;}
    public String startedFinishedDateTime {get; set;}
    public String newBEName {get; set;}
    public String newBEURL {get; set;}
	public Boolean pollerEnabled {get; set;}
	private Integer maxRefreshCount = 100;
    public String oldBEName {get; set;}

    //2 class variables used for custom apex debug logging
    private static String apexLogSource = 'psaBillingEventRegenerateController';
    private static Integer apexLogMethodSequenceMaster = 0;

    /**************************************************************************************
    // Name         : psaBillingEventRegenerateController
    // Description  : Constructor to set default variable values and retrieve any querystring
    //					values
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 2016-02-18  Klassen  Added new parameter "OldBE" to help link old BE in then
    //                  Billing Event History object with the new billing event
    ***************************************************************************************/
    public psaBillingEventRegenerateController() {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'psaBillingEventRegenerateController';

    	//Initialize variables
		if (pollerEnabled == null) {pollerEnabled=true;}
		//Retrieve the max refresh count from the PSA Billing custom setting
        PSA_Billing__c psaBilling = PSA_Billing__c.getValues('default');
        if (psaBilling != null) {
          if (psaBilling.PSA_Billing_Event_Max_Refresh__c != null) {
            maxRefreshCount = (Integer)psaBilling.PSA_Billing_Event_Max_Refresh__c;
          }
        }

        //Get parameter values
        if (Apexpages.currentPage().getParameters().get('id') != null && Apexpages.currentPage().getParameters().get('id') != '') {
        	currentBEId = Apexpages.currentPage().getParameters().get('id');        	
        }
        if (Apexpages.currentPage().getParameters().get('step') != null && Apexpages.currentPage().getParameters().get('step') != '') {
        	step = Apexpages.currentPage().getParameters().get('step');
        	if (step == 'done' || step == 'failed' || step == 'invalid') {
        		pollerEnabled = false;
        	}
        }
        if (Apexpages.currentPage().getParameters().get('jobId') != null && Apexpages.currentPage().getParameters().get('jobId') != '') {
        	currentJobId = Apexpages.currentPage().getParameters().get('jobId');
        }
        if (Apexpages.currentPage().getParameters().get('emailcim') != null && Apexpages.currentPage().getParameters().get('emailcim') != '') {
            emailCIM = Apexpages.currentPage().getParameters().get('emailcim');
        }
        if (Apexpages.currentPage().getParameters().get('tp') != null && Apexpages.currentPage().getParameters().get('tp') != '') {
        	tpId = Apexpages.currentPage().getParameters().get('tp');     	
        }
        if (Apexpages.currentPage().getParameters().get('proj') != null && Apexpages.currentPage().getParameters().get('proj') != '') {
        	projId = Apexpages.currentPage().getParameters().get('proj');
        }
        if (Apexpages.currentPage().getParameters().get('oldBE') != null && Apexpages.currentPage().getParameters().get('oldBE') != '') {
            oldBEName = Apexpages.currentPage().getParameters().get('oldBE');
        }
        if (Apexpages.currentPage().getParameters().get('retry') != null && Apexpages.currentPage().getParameters().get('retry') != '') {
            String retryParam = Apexpages.currentPage().getParameters().get('retry');
            retryCount = Integer.valueOf(retryParam);
        }
        if (Apexpages.currentPage().getParameters().get('count') != null && Apexpages.currentPage().getParameters().get('count') != '') {
        	String counterParam = Apexpages.currentPage().getParameters().get('count');
        	counter += Integer.valueOf(counterParam);
        	if (counter == maxRefreshCount) {
        		pollerEnabled = false;
        	}
        }
        if (Apexpages.currentPage().getParameters().get('start') != null && Apexpages.currentPage().getParameters().get('start') != '') {
        	startDateTime = DateTime.valueOf(Apexpages.currentPage().getParameters().get('start'));
        } else {
        	startDateTime = DateTime.now();
        }
    }

    /**************************************************************************************
    // Name         : startRegenerateProcess
    // Description  : Automatically called when the vf page loads.  Controls the flow of 
    //					processes that are needed to re-generate a billing event
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public PageReference startRegenerateProcess() {
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'startRegenerateProcess';

        //log variable values
        logVariableValues(apexLogMethod, apexLogMethodSequence);

    	//Only run this method if a billing event has been identified (must be in Draft status)
    	String jobStatus;
    	System.debug('Current Step: ' + step);

        //If the project id or time period id is missing, display a message to the user and end the process
        if (projId == '' || tpId == '') {
            if (currentBEId != null && currentBEId != '') {
                pse__Billing_Event__c billingEvent = getValidBillingEvent(currentBEId, null, null);
                if (billingEvent != null) {
                    System.debug('Billing Event found but missing required page parameters: ' + billingEvent);
                    newBEURL = getBEURL();
                    System.debug('new BE URL: ' + newBEURL);
                    newBEName = billingEvent.Name;
                    System.debug('new BE Name: ' + newBEName);
                }               
            }
            //display message to user that required values are missing
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'TThe project and/or time period inputs are missing.');
            Apexpages.addMessage(msg);
            endDateTime = DateTime.now();
            formatStartedFinishedTime();

            return null;            
        }

    	//Check if the max refresh count has been reached.  If so, attempt to set the billing event url
    	// and display a warning message
    	if (counter >= maxRefreshCount) {
    		if (currentBEId != null && currentBEId != '') {
			    pse__Billing_Event__c billingEvent = getValidBillingEvent(currentBEId, null, null);
				if (billingEvent != null) {
					System.debug('Billing Event found after max refresh count has been reached: ' + billingEvent);
					newBEURL = getBEURL();
					System.debug('new BE URL: ' + newBEURL);
					newBEName = billingEvent.Name;
					System.debug('new BE Name: ' + newBEName);
				}    			
    		}

			//display message to user 
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'The maximum number of page reloads has been reached.  There may have been a problem regenerating the billing event or creating the invoice documents.');
            Apexpages.addMessage(msg);
    		endDateTime = DateTime.now();
    		formatStartedFinishedTime();

    		return null;
    	}

    	// and display a warning message
    	if (step == 'clear' && currentJobId == '') {
    		System.debug('Clear billing about to be called: ' + currentBEId);

    		//clear the billing event
		    pse__Billing_Event__c billingEvent = getValidBillingEvent(currentBEId, null, null);
			if (billingEvent != null) {
				System.debug('Billing Event found for Clear Billing: ' + billingEvent);

                //added 2/18/16 by cklassen to link old and new billing events
                oldBEName = billingEvent.Name;

				//Original billing event has not been deleted yet, so call the delete method
				//projId = billingEvent.pse__Project__c;
				//tpId = billingEvent.PSA_Time_Period__c;

				String message = psaBillingEventRegenerate.runBillingEventClear(billingEvent.Id);
				if (message.contains('SUCCESS') == true) {
					currentJobId = message.replace('SUCCESS', '');
	    			//display message to user that original billing event is being cleared
		            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, billingEvent.Name + ' is being cleared');
		            Apexpages.addMessage(msg);
				} else {
	    			//display message to user that the clear billing event job failed
		            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The job to clear ' + billingEvent.Name + ' failed');
		            Apexpages.addMessage(msg);
					step = 'failed';
				}
    		} else {
    			//display message to user that no valid Billing Event was found
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'A valid billing event was not found.  The billing event may already be released or invoiced.');
	            Apexpages.addMessage(msg);
	            step = 'invalid';
    		}
    	} else if (step == 'clear' && currentJobId != '') {
    		System.debug('Clear started using Job Id: ' + currentJobId + ' - checking job status');

    		//check job status
    		jobStatus = checkJobStatus(currentJobId);
    		System.debug('Job Status=' + jobStatus);
    		if (jobStatus == 'DONE') {
    			//Set the step to beg
    			step = 'beg';
    			currentJobId = '';
    		}

			//display message to user that the clear billing event job status is being checked
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Checking Billing Event Clear status');
            Apexpages.addMessage(msg);
    	} else if (step == 'beg' && currentJobId == '') {
    		System.debug('About to start BEG for proj/tp: ' + projId + '/' + tpId);
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'About to start BE for proj/tp: ' + projId + '/' + tpId, 'Retry Count:' + retryCount, null);

            String message;
            Try {
                message = psaBillingEventRegenerate.runBillingEventGeneration(projId, tpId);
            } catch (Exception ex) {
                message = 'FAILED';

            }
			if (message.contains('SUCCESS') == true) {
				currentJobId = message.replace('SUCCESS', '');

    			//display message to user that a new billing event is being generated
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Generating the new billing event');
	            Apexpages.addMessage(msg);
			} else {
    			//display message to user that the billing event gen job failed
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The job to re-generate the billing event failed');
	            Apexpages.addMessage(msg);
	            step = 'failed';
			}
    	} else if (step == 'beg' && currentJobId != '') {
    		System.debug('BEG started - Job Id= ' + currentJobId + '- checking job status');
            System.debug('Retry Count: ' + retryCount);

    		//check job status
    		jobStatus = checkJobStatus(currentJobId);
    		if (jobStatus == 'DONE') {
    			//Now check for a billing event that has the recalc date filled in
    			pse__Billing_Event__c billingEvent = getValidBillingEvent(null, projId, tpId);
    			if (billingEvent != null) {
					if (billingEvent.PSA_Billing_Event_Recalc_Date__c != null) {
						currentBEId = billingEvent.Id;

                        //*** If we ever want to archive a copy of billing events that are being re-generated, 
                        // we can un-comment the following code to store the Prior Billing Event from the 
                        // Billing Event History object based on the Billing Event Name
                        //Set the Prior Billing Event
                        //Id priorBillingEvent = getOldBEIdFromHistory(oldBEName);
                        //billingEvent.PSA_Prior_Billing_Event__c = priorBillingEvent;
                        //update billingEvent;

		    			//Set the step to beg
		    			step = 'doc';
		    			currentJobId = '';
	    			}
                } else if (retryCount <= 5) {
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'No BE for proj/tp: ' + projId + '/' + tpId, 'Retry Count:' + retryCount, null);
                    retryCount+=1;
    			} else {
                    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'No BE for proj/tp: ' + projId + '/' + tpId, 'Retry Count:' + retryCount, null);

    				//unable to find billing event, so display a message
		            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'A new billing event was not found.  The billing event source items may have gotten associated with a prior billing event that has not been released yet.');
		            Apexpages.addMessage(msg);
		            step = 'failed';
    			}
    		}

			//display message to user that the billing event generation status is being checked...
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Checking Billing Event Generation status');
            Apexpages.addMessage(msg);
        } else if (step == 'doc') {
			pse__Billing_Event__c billingEvent = getValidBillingEvent(currentBEId, null, null);
			
            //set the Send CIM Email field to false if emailCIM is False
            if (emailCIM == '0') {
                billingEvent.PSA_Send_CIM_Notification__c = false;
                update billingEvent;
            }

            if (billingEvent.PSA_Billing_Event_Docs_Started_Date__c == null) {
				billingEvent.PSA_Billing_Event_Docs_Started_Date__c = Datetime.now();
				billingEvent.PSA_Generate_Invoice_Detail__c = true;
				billingEvent.PSA_Generate_Invoice_Preview__c = true;
				update billingEvent;

				//display message to user that the billing event generation status is being checked...
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Starting to generate Invoice Documents');
	            Apexpages.addMessage(msg);
			} else if (billingEvent.PSA_Billing_Event_Docs_Started_Date__c != null && 
					billingEvent.PSA_Billing_Event_Docs_Attached_Date__c == null) {
				//display message to user that the billing event generation status is being checked...
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Generating Invoice Documents');
	            Apexpages.addMessage(msg);
			} else {
    			//Set the step to beg
    			step = 'done';

				//display message to user that the billing event generation status is being checked...
	            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Finishing the Invoice Documents');
	            Apexpages.addMessage(msg);
			}
        } else if (step == 'failed' || step == 'invalid') {
            if (currentBEId != '') {
                Try {
                    pse__Billing_Event__c billingEvent = getSingleBillingEvent(currentBEId);

                    newBEURL = getBEURL(); //billingEvent.PSA_billingEventURL__c;
                    System.debug('new BE URL: ' + newBEURL);
                    newBEName = billingEvent.Name;
                    System.debug('new BE Name: ' + newBEName);
                } Catch (Exception ex) {
                    System.debug('Failed to get a billing event for the billing event id: ' + currentBEId);
                }
            }

            //display message to user that the billing event generation process failed
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'The billing event generation process failed ' + currentBEId);
            Apexpages.addMessage(msg);
            endDateTime = DateTime.now();
            startedFinishedDateTime = formatStartedFinishedTime();
    	} else {
    		if (step == 'done' && currentBEId != '') {
				pse__Billing_Event__c billingEvent = getValidBillingEvent(currentBEId, null, null);

				newBEURL = getBEURL(); //billingEvent.PSA_billingEventURL__c;
				System.debug('new BE URL: ' + newBEURL);
				newBEName = billingEvent.Name;
				System.debug('new BE Name: ' + newBEName);
    		}

			//display message to user that the billing event generation process is done
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'The billing event re-generation process is now complete');
            Apexpages.addMessage(msg);
    		endDateTime = DateTime.now();
    		startedFinishedDateTime = formatStartedFinishedTime();
    	}

        //log variable values
        logVariableValues(apexLogMethod, apexLogMethodSequence);

        //Insert the list of PSA Apex Log records
        Try {
          psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
          psaApexLog.insertApexLogRecords();
        } Catch (Exception ex) {
          System.debug('Error trying to insert the Apex Log Records in psaBillingEventRegenerateController.startRegenerateProcess: ' + ex.getMessage());
          //sendErrorEmail(ex, 'Billing Event Re-Generation Controller Error');
        }

        return null;
    }

    /**************************************************************************************
    // Name         : formatStartedFinishedTime
    // Description  : Sets a variable used to display the start/end time of the entire process 
    //					
    // Author       : CLD Partners
    // Revisions    : 2015-09-25  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private String formatStartedFinishedTime() {
    	return String.valueOf(startDateTime) + ' - ' + String.valueOf(endDateTime);
    }

    /**************************************************************************************
    // Name         : checkJobStatus
    // Description  : Check the status of an apex job and return a message indicating if it 
    //					has completed successfully, failed or is still running
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private String checkJobStatus(String apexJobId) {
    	if (apexJobId == 'null') {
    		return 'DONE';
    	} else {
	    	AsyncApexJob aaj = 
	    		[SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
					FROM AsyncApexJob 
					WHERE ID =: apexJobId
				];
			System.Debug('Apex job id: '+aaj.Id);
			if (aaj.Status == 'Completed') {
				return 'DONE';
			} else if (aaj.Status == 'Aborted' || aaj.Status == 'Failed') {
				return 'FAILED';
			} else {
				return 'PROCESSING';
			}
    	}
    }

    /**************************************************************************************
    // Name         : reloadPage
    // Description  : Called by the vf page actionpoller to reload the page.  Includes all 
    //					relevant page parameters
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
	public PageReference reloadPage() {
		PageReference pageRef = new PageReference(getPageURL());
		pageRef.getParameters().put('id', currentBEId);
		pageRef.getParameters().put('jobId', currentJobId);
		pageRef.getParameters().put('step', step);
		pageRef.getParameters().put('proj', projId);
		pageRef.getParameters().put('tp', tpId);
        pageRef.getParameters().put('emailcim', emailCIM);
		pageRef.getParameters().put('start', String.valueOf(startDateTime));
		pageRef.getParameters().put('count', String.valueOf(counter));
        pageRef.getParameters().put('retry', String.valueOf(retryCount));
        pageRef.getParameters().put('oldBE', oldBEName);
		pageRef.setRedirect(true);
		return pageRef;
	}

    /**************************************************************************************
    // Name         : getPageURL
    // Description  : Gets the url of the psaBillingEventRegenerate page
    //					
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
	public String getPageURL() {
		String urlString = ApexPages.CurrentPage().GetURL();
		return urlString.substring(0,urlString.indexOf('?'));
	}

    /**************************************************************************************
    // Name         : getBEURL
    // Description  : Gets a direct url of a billing event 
    //					
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
	public String getBEURL() {
		String fullURL = '';
        fullURL = '/' + currentBEId;
        return fullURL;
	}

    /**************************************************************************************
    // Name         : getValidBillingEvent
    // Description  : Retrieves a billing event based on either the billing event id or if 
    //					that is not provided then by project and time period
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private pse__Billing_Event__c getValidBillingEvent(String beId, String projectId, String timePeriodId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getValidBillingEvent';

		if (beId != null) {
		    List<pse__Billing_Event__c> beList = 
				[Select Id, Name, pse__Project__c, PSA_Time_Period__c, 
						PSA_Billing_Event_Recalc_Date__c, PSA_Billing_Event_Docs_Attached_Date__c, 
	    				PSA_Billing_Event_Docs_Started_Date__c, PSA_Generate_Invoice_Preview__c, 
	    				PSA_Generate_Invoice_Detail__c, PSA_Invoice_Detail_Document__c, 
	    				pse__Project__r.pse__Region__c, PSA_Prior_Billing_Event__c, CreatedDate
					From pse__Billing_Event__c
					Where Id = :beId
					And pse__Status__c = 'Draft'
                    Order By CreatedDate Desc
				];
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event for BE: ' + beId, String.valueOf(beList), null);

			if (beList != null && beList.size() > 0) {
				return beList[0];
			} else {
				return null;
			}
		} else {
			List<pse__Billing_Event__c> beList = 
				[Select Id, Name, pse__Project__c, PSA_Time_Period__c, 
						PSA_Billing_Event_Recalc_Date__c, PSA_Billing_Event_Docs_Attached_Date__c, 
	    				PSA_Billing_Event_Docs_Started_Date__c, PSA_Generate_Invoice_Preview__c, 
	    				PSA_Generate_Invoice_Detail__c, PSA_Invoice_Detail_Document__c, 
	    				pse__Project__r.pse__Region__c
					From pse__Billing_Event__c
	    			Where pse__Project__c =: projectId
	    			And PSA_Time_Period__c =: timePeriodId
	    			And pse__Status__c = 'Draft'
				];
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event for tp/proj: ' + timePeriodId + '/' + projectId, String.valueOf(beList), null);

			if (beList != null && beList.size() > 0) {
				return beList[0];
			} else {
				return null;
			}
		}    	
    }

    /**************************************************************************************
    // Name         : getSingleBillingEvent
    // Description  : Retrieves a billing event based on the billing event id. The query  
    //                  has no other filters besides id
    // Author       : CLD Partners
    // Revisions    : 2015-09-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private pse__Billing_Event__c getSingleBillingEvent(String beId) {
        //update apexLog variables used for custom apex code logging
        apexLogMethodSequenceMaster += 1;
        Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
        String apexLogMethod = 'getSingleBillingEvent';

        Try {
            pse__Billing_Event__c be = 
                [Select Id, Name, pse__Project__c, PSA_Time_Period__c, 
                        PSA_Billing_Event_Recalc_Date__c, PSA_Billing_Event_Docs_Attached_Date__c, 
                        PSA_Billing_Event_Docs_Started_Date__c, PSA_Generate_Invoice_Preview__c, 
                        PSA_Generate_Invoice_Detail__c, PSA_Invoice_Detail_Document__c, 
                        pse__Project__r.pse__Region__c
                    From pse__Billing_Event__c
                    Where Id = :beId
                ];
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event', String.valueOf(be), null);

            return be;
        } Catch (Exception ex) {
            //Add apex log record
            psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Error', String.valueOf(ex), null);
            return null;
        }        
    }

    /**************************************************************************************
    // Name         : logVariableValues
    // Description  : Retrieves a billing event based on the billing event id. The query  
    //                  has no other filters besides id
    // Author       : CLD Partners
    // Revisions    : 2015-09-28  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    private void logVariableValues(String apexLogMethod, Integer apexLogMethodSequence) {
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'currentBEId: ' + currentBEId, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'oldBEName: ' + oldBEName, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'step: ' + step, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'currentJobId: ' + currentJobId, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'projId: ' + projId, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'tpId: ' + tpId, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'retry count: ' + retryCount, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'counter: ' + counter, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'startDateTime: ' + startDateTime, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'endDateTime: ' + endDateTime, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'startedFinishedDateTime: ' + startedFinishedDateTime, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'newBEName: ' + newBEName, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'pollerEnabled: ' + pollerEnabled, null, null);
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'maxRefreshCount: ' + maxRefreshCount, null, null);

    }

    /**************************************************************************************
    // Name         : getOldBEIdFromHistory
    // Description  : Lookup Id from old BE in BE History so it can be updated on new BE.
    //                  As of March 2016, Re-generated billing events are not being archived, 
    //                  but they ever need to be, this method may be un-commented and called 
    //                  during the "} else if (step == 'beg' && currentJobId != '') {" condition
    // Author       : CLD Partners
    // Revisions    : 2016-02-18  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    /*
    private Id getOldBEIdFromHistory(String oldBEName) {
        System.debug('Old Billing Event Name:' + oldBEName);
        PSA_Billing_Event_History__c beHistory = 
            [Select Id From PSA_Billing_Event_History__c Where PSA_Name__c = :oldBEName Limit 1];
        if (beHistory != null) {
            return beHistory.Id;
        } else {
            return null;
        }
    }
    */
}