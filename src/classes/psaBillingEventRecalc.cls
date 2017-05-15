/******************************************************************************************************************************
Name            : psaBillingEventRecalc
Author          : CLD Partners
Created Date    : September 16, 2015
Description     : Contains methods that re-calc Billing Events usingthe ApiBillingServices methods.
Revisions       : 
********************************************************************************************************************************/
// !!! NOTE:  FF Needs to be instructed to use this class as the handler for the billing recalc process
// !!!        Set Configuration Option > Billing > billingInterfaceRecalc > Value as psaBillingEventRecalc (this class)
/********************************************************************************************************************************/
global class psaBillingEventRecalc implements pse.APICommonsService.iBatchCallback {
	//List of methods that are not being implemented
	global void beforeStart(pse.APICommonsService.BatchContext bc){}
	global void afterStart(pse.APICommonsService.BatchContext bc){}
	global void beforeExecute(pse.APICommonsService.BatchContext bc, Set<ID> scope){}
	global void afterExecute(pse.APICommonsService.BatchContext bc, Set<ID> scope){}
	global void beforeFinish(pse.APICommonsService.BatchContext bc){}
	global pse.APICommonsService.BatchJobType getJobType(){return pse.APICommonsService.BatchJobType.Recalc;}

	//2 class variables used for custom apex debug logging
	private static String apexLogSource = 'psaBillingEventRecalc';
	private static Integer apexLogMethodSequenceMaster = 0;

	global void afterFinish(pse.APICommonsService.BatchContext bc) {
		//update apexLog variables used for custom apex code logging
		apexLogMethodSequenceMaster += 1;
		Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
		String apexLogMethod = 'afterFinish';

	    Try {
			System.Debug('**** psaBillingEventRecalc.afterFinish - START ***');
			System.Debug('**** psaBillingEventRecalc.afterFinish - bc = '+bc);
			//Add apex log record
			psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventRecalc.afterFinish - bc', String.valueOf(bc), null);

			pse.APIBillingService.BillingContextRecalc bbc = (pse.APIBillingService.BillingContextRecalc)bc;
			System.Debug('**** psaBillingEventRecalc.afterFinish - bbc = '+bbc);
			//Add apex log record
			psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventRecalc.afterFinish - bbc', String.valueOf(bbc), null);

			//Build a list of billing events and update them as "re-calced" and check the Conga-related boxes to re-gen. the docs
			//Update the recalc date/time, reset invoice detail urls, delete any related invoice detail attachments
			List<pse__Billing_Event__c> beRecalcedList = 
				[Select Id, PSA_Billing_Event_Recalc_Date__c, PSA_Generate_Invoice_Detail__c, PSA_Generate_Invoice_Preview__c
					From pse__Billing_Event__c 
					Where Id =:bbc.billingEventIds 
				];
			//Add apex log record
			psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Recalc Billing Event List', String.valueOf(beRecalcedList), null);
			if (beRecalcedList != null && beRecalcedList.size() > 0) {
				for(pse__Billing_Event__c be : beRecalcedList) {
					System.debug('Updating ' + be);
					be.PSA_Billing_Event_Recalc_Date__c = DateTime.now();
				}
				psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Updating Billing Event List', String.valueOf(beRecalcedList), null);
				update beRecalcedList;
			}

			System.debug('psaBillingEventRecalc.afterFinish Be Ids: ' + bbc.billingEventIds);

			//Add apex log record
			psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventRecalc.afterFinish - DONE', null, null);

	    } catch (Exception ex) {
	      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventRecalc.afterFinish-Line Number:' + ex.getLineNumber(), 'MESSAGE=' + ex.getMessage() + '   STACKTRACE=' + ex.getStackTraceString(), null);
	      psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Event Recalc Error');
	    }

	    //Insert the list of PSA Apex Log records
	    Try {
			psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
			psaApexLog.insertApexLogRecords();
	    } Catch (Exception ex) {
			System.debug('Error trying to insert the Apex Log Records in psaBillingEventRecalc.afterFinish: ' + ex.getMessage());
	      psaBillingEventGeneration.sendErrorEmail(ex, 'Billing Event Recalc Error');
	    }
	}

  /**************************************************************************************
  // Name         : recalcBillingEvents
  // Description  : This method calls the psa API to Recalc Billing Events
  // Author       : CLD Partners
  // Revisions    : 2015-05-15  Klassen  Initial Implementation
  //              : 2015-08-12  Klassen  Added custom apex log logic
  ***************************************************************************************/
  public static void recalcBillingEvents(Set<Id> projectIds) {
    //update apexLog variables used for custom apex code logging
    apexLogMethodSequenceMaster += 1;
    Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
    String apexLogMethod = 'recalcBillingEvents';

    //Add apex log record
    psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'recalcBillingEvents - START', null, null);

    Set<Id> beIds = new Set<Id>();
    for(pse__Billing_Event__c be : [
      Select Id 
        From pse__Billing_Event__c 
        Where pse__Project__c  =:projectIds 
        And pse__Is_Released__c = false
    ]){
        beIds.add(be.Id);
    }
    
    //Add apex log record
    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Billing Event Ids', String.valueOf(beIds), null);

    if(!beIds.isEmpty())
    {
      pse.APIBillingService.BillingContextRecalc bc = new pse.APIBillingService.BillingContextRecalc();
      bc.billingEventIds = beIds;
      system.debug('****** psaRecalcBillingEvents - recalcBillingEvents - bc = '+ bc);

      pse.APICommonsService.BatchStatus bs =  pse.APIBillingService.recalc(bc);
      system.debug('****** psaRecalcBillingEvents - recalcBillingEvents - bs = '+ bs);
    }

    //Add apex log record
    psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'recalcBillingEvents - DONE', null, null);
  }

}