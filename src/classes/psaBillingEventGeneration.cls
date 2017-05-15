/******************************************************************************************************************************
Name            : psaBillingEventGeneration
Author          : CLD Partners
Created Date    : March 6, 2015
Description     : Contains methods that generate Billing Events for Projects/Engagments usign the ApiBillingServices methods.
Revisions       : Added custom apex logging on 2015-08-12
                : 9/16/15  cklassen  Moved recalc logic to separate class, modified email method, and cleaned out old code
********************************************************************************************************************************/
// !!! NOTE:  FF Needs to be instructed to use this class as the handler for the billing generate process
// !!!        Set Configuration Option > Billing > billingInterfaceGenerate > Value as psaBillingEventGeneration (this class)
/********************************************************************************************************************************/
global class psaBillingEventGeneration implements pse.APICommonsService.iBatchCallback
{
  //List of methods that are not being implemented
  global void afterStart(pse.APICommonsService.BatchContext bc){}
  global void beforeExecute(pse.APICommonsService.BatchContext bc, Set<ID> scope){}
  global void afterExecute(pse.APICommonsService.BatchContext bc, Set<ID> scope){}
  global void beforeFinish(pse.APICommonsService.BatchContext bc){}
  global pse.APICommonsService.BatchJobType getJobType(){return pse.APICommonsService.BatchJobType.Generate;}

  //2 class variables used for custom apex debug logging
  private static String apexLogSource = 'psaBillingEventGeneration';
  private static Integer apexLogMethodSequenceMaster = 0;

  /**************************************************************************************
  // Name         : beforeStart
  // Description  : This method is the call-back that fires before BE Generation starts
  // Author       : CLD Partners
  // Revisions    : 2015-05-15  Klassen  Initial Implementation
  //              : 2015-08-12  Klassen  Added custom apex log logic
  ***************************************************************************************/
  global void beforeStart(pse.APICommonsService.BatchContext bc) {
    //update apexLog variables used for custom apex code logging
    apexLogMethodSequenceMaster += 1;
    Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
    String apexLogMethod = 'beforeStart';

    Try {
      System.Debug('**** psaBillingEventGeneration.beforeStart - START ***');
      System.Debug('**** psaBillingEventGeneration.beforeStart - bc = '+bc);
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.beforeStart - bc', String.valueOf(bc), null);

      pse.APIBillingService.BillingContextGenerate bbc = (pse.APIBillingService.BillingContextGenerate)bc;
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.beforeStart - bbc', String.valueOf(bbc), null);

      System.Debug('**** psaBillingEventGeneration.beforeStart - bbc = ' + bbc);
      System.Debug('BEG Region: ' + bbc.RegionID);
      System.Debug('BEG Account: ' + bbc.AccountID);
      System.Debug('BEG Project: ' + bbc.ProjectID);
      System.Debug('BEG Time Period: ' + bbc.timePeriodID);
      System.Debug('BEG Include Prior Periods: ' + bbc.includePriorPeriods);

      //Get the time period start and end dates
      Date startDate = ([Select pse__Start_Date__c From pse__Time_Period__c Where Id =: bbc.timePeriodID]).pse__Start_Date__c;
      Date endDate = ([Select pse__End_Date__c From pse__Time_Period__c Where Id =: bbc.timePeriodID]).pse__End_Date__c;
      System.debug('Time Period Start and End Dates: ' + startDate + ' : ' + endDate);
      //Add apex log record
      psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Time Period Start and End Dates: ' + startDate + ' : ' + endDate, null, null);

      //Build a set of Project Ids to Process the Timecard Daily Cap logic
      Set<Id> projectIds = getProjectIds(bbc);
      System.debug('beforeStart ProjectIds: ' + projectIds);
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'beforeStart ProjectIds', String.valueOf(projectIds), null);

      if (projectIds.size() > 0) {
        //Execute code which will add a misc. adjustment for any projects that have the Minimum billable hours applies set to true, but no timecards exist
        // no min. hours. misc. adjustment exists.  Also, the Clear Billing Rules logic will run which will delete any misc. adjs. flagged as created by billing rules
        // for un-released billing events for the specified list of projects (except holdback release and min hours misc. adjs.)
        psaBillingRulesApplication bra = new psaBillingRulesApplication();
        bra.launchBillingRulesBeforeStart(projectIds, startDate, endDate);
      }

      System.Debug('**** psaBillingEventGeneration.beforeStart - END ***');
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.beforeStart - DONE', null, null);      
    } catch (Exception ex) {
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.beforeStart-Line Number:' + ex.getLineNumber(), 'MESSAGE=' + ex.getMessage() + '   STACKTRACE=' + ex.getStackTraceString(), null);
      sendErrorEmail(ex, 'Billing Event Generation Error');
    }

    //Insert the list of PSA Apex Log records
    Try {
      psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
      psaApexLog.insertApexLogRecords();
    } Catch (Exception ex) {
      System.debug('Error trying to insert the Apex Log Records in psaBillingEventGeneration.beforeFinish: ' + ex.getMessage());
      sendErrorEmail(ex, 'Billing Event Generation Error');
    }
  }

  /**************************************************************************************
  // Name         : recalcBillingEvents
  // Description  : This method is the call-back that fires when BE Generation is complete
  // Author       : CLD Partners
  // Revisions    : 2015-05-15  Klassen  Initial Implementation
  //              : 2015-08-12  Klassen  Added custom apex log logic
  ***************************************************************************************/
  global void afterFinish(pse.APICommonsService.BatchContext bc) {
    //update apexLog variables used for custom apex code logging
    apexLogMethodSequenceMaster += 1;
    Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
    String apexLogMethod = 'afterFinish';

    Try {
      System.Debug('**** psaBillingEventGeneration.afterFinish - START ***');
      System.Debug('**** psaBillingEventGeneration.afterFinish - bc = '+bc);
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.afterFinish - bc', String.valueOf(bc), null);

      pse.APIBillingService.BillingContextGenerate bbc = (pse.APIBillingService.BillingContextGenerate)bc;
      System.Debug('**** psaBillingEventGeneration.afterFinish - bbc = '+bbc);
      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.afterFinish - bbc', String.valueOf(bbc), null);
      
      //Get the time period start end date
      Date startDate = ([Select pse__Start_Date__c From pse__Time_Period__c Where Id =: bbc.timePeriodID]).pse__Start_Date__c;
      Date endDate = ([Select pse__End_Date__c From pse__Time_Period__c Where Id =: bbc.timePeriodID]).pse__End_Date__c;
      System.debug('Time Period Start and End Dates: ' + startDate + ' : ' + endDate);

      Set<Id> projectIds = getProjectIds(bbc);
      System.debug('afterFinish ProjectIds: ' + projectIds);

      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Projects for the Billing Rules Application', String.valueOf(projectIds), null);

      if (projectIds.size() > 0) {
        integer BATCH_SIZE = 5;
        PSA_Billing__c psaBilling = PSA_Billing__c.getValues('default');
        if (psaBilling != null) {
          if (psaBilling.PSA_Billing_Rules_Batch_Size__c != null) {
            BATCH_SIZE = (Integer)psaBilling.PSA_Billing_Rules_Batch_Size__c;
          }
        }
        
        //Add apex log record
        psaApexLog.createApexLog(2, apexLogSource, apexLogMethod, apexLogMethodSequence, 'Total Projects for Billing Rules App: ' + projectIds.size(), null, null);

        psaBillingRulesApplicationBatch braBatch = new psaBillingRulesApplicationBatch(projectIds, startDate, endDate, true);
        System.debug('**** psaBillingRulesApplicationBatch: starting batch exection *****************');
        Id batchId = database.executeBatch(braBatch, BATCH_SIZE);    
        System.debug('**** psaBillingRulesApplicationBatch: Batch executed batchId: ' +batchId); 
      }

      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.afterFinish - DONE', null, null);

    } catch (Exception ex) {
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'psaBillingEventGeneration.afterFinish-Line Number:' + ex.getLineNumber(), 'MESSAGE=' + ex.getMessage() + '   STACKTRACE=' + ex.getStackTraceString(), null);
      sendErrorEmail(ex, 'Billing Event Generation Error');
    }

    //Insert the list of PSA Apex Log records
    Try {
      psaApexLog.createApexLogGovernerLimits(apexLogSource, apexLogMethod);
      psaApexLog.insertApexLogRecords();
    } Catch (Exception ex) {
      System.debug('Error trying to insert the Apex Log Records in psaBillingEventGeneration.afterFinish: ' + ex.getMessage());
      sendErrorEmail(ex, 'Billing Event Generation Error');
    }
  }

  /**************************************************************************************
  // Name         : sendErrorEmail
  // Description  : This method sends an error notification via email
  // Author       : CLD Partners
  // Revisions    : 2015-08-19  Klassen  Initial Implementation
  //              : 
  ***************************************************************************************/
  public static void sendErrorEmail(Exception ex, String subjectText) {
      PSA_Logging__c psaLogging = PSA_Logging__c.getValues('default');
      if (psaLogging != null && psaLogging.PSA_Error_Email_List__c != null) {
        String emailList = psaLogging.PSA_Error_Email_List__c;

        // Send an email to the Apex job's submitter notifying of job completion. 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        String[] toAddresses = emailList.split(',');       
        mail.setToAddresses(toAddresses);
        //String subjectText = 'Billing Event Generation Error'; 
        mail.setSubject(subjectText);
        mail.setPlainTextBody('BEG Failed at LINE=' + ex.getLineNumber() + 
              ' STACKTRACE=' + ex.getStackTraceString() + 
              ' MESSAGE=' + ex.getMessage());
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      } else {
        System.debug('No Error Email List values to send an error notification to in PSA Logging Custom Setting');
      }
  }

  /**************************************************************************************
  // Name         : getProjectIds
  // Description  : Get a list of Project Ids based on BillingContextGenerate info such 
  //              :  region, account, and project
  // Author       : CLD Partners
  // Revisions    : 2015-07-15  Klassen  Initial Implementation
  //              : 2015-08-12  Klassen  Added custom apex log logic
  ***************************************************************************************/
  public static Set<Id> getProjectIds(pse.APIBillingService.BillingContextGenerate bbc) {
    //update apexLog variables used for custom apex code logging
    apexLogMethodSequenceMaster += 1;
    Integer apexLogMethodSequence = apexLogMethodSequenceMaster;
    String apexLogMethod = 'getProjectIds';

    Set<Id> projectIds = new Set<Id>();
    if (bbc.ProjectId != null) {
      projectIds.add(bbc.ProjectID);

      //Add apex log record
      psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BEG for Single Project', String.valueOf(projectIds), null);
    } else {
      //No project id, so try account id
      if (bbc.AccountID != null) {
        Map<Id, pse__Proj__c> accountProjectMap = new Map<Id, pse__Proj__c>(
          [
            Select Id, Name From pse__Proj__c Where pse__Account__c = :bbc.AccountID 
          ]);
        if (accountProjectMap != null && accountProjectMap.size() > 0) {
          projectIds = accountProjectMap.keySet();

          //Add apex log record
          psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BEG for Single Account - ' + bbc.AccountID, String.valueOf(projectIds), null);
        }
      } else {
        //no account id, so use region
        String regionIdFilter = '%' + bbc.RegionID + '%';
        Map<Id, pse__Proj__c> regionProjectMap = new Map<Id, pse__Proj__c>(
          [
            Select Id, Name 
              From pse__Proj__c 
              Where pse__Region__c IN (
                Select Id  
                From pse__Region__c 
                Where pse__Region_ID_Chain__c Like :regionIdFilter
              ) 
              And pse__Exclude_From_Billing__c = false 
          ]);

        if (regionProjectMap != null && regionProjectMap.size() > 0) {
          projectIds = regionProjectMap.keySet();

          //Add apex log record
          psaApexLog.createApexLog(1, apexLogSource, apexLogMethod, apexLogMethodSequence, 'BEG for Region - ' + bbc.RegionID, String.valueOf(projectIds), null);
        }
      }

    }
    //System.debug('Project Id Set: ' + projectIds);
    return projectIds;
  }

}