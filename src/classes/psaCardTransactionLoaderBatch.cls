/*********************************************************************************************** x
Name            : psaCardTransactionLoaderBatch
Author          : CLD
Created Date    : Oct 2015
Revision History:

Usage           : Batch for card transaction loader
                :
***********************************************************************************************/
global class psaCardTransactionLoaderBatch implements Database.Batchable<sObject>
{

    // -- construct a psaCardTransactionLoaderBatch
    public psaCardTransactionLoaderBatch() { }

    // --- start the batch
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
          return Database.getQueryLocator([
                    SELECT CreatedById,
                           CreatedDate,
                           CurrencyIsoCode,
                           Id,
                           Name,
                           OwnerId,
                           PSA_Acquirer_Reference_Data__c,
                           PSA_Amount_in_Billing_Currency__c,
                           PSA_Amount_in_Original_Currency__c,
                           PSA_Billing_Conversion_Rate__c,
                           PSA_Billing_Currency_Conversion_Date__c,
                           PSA_Billing_Currency_Currency_Code__c,
                           PSA_Debit_Or_Credit_Indicator__c,
                           PSA_EmployeeId__c,
                           PSA_Merchant_Country_Code__c,
                           PSA_Merchant_Name__c,
                           PSA_Merchant_Postal_Code__c,
                           PSA_Merchant_State_Province__c,
                           PSA_Merchant_Street_Address__c,
                           PSA_Posting_Date__c,
                           PSA_ProcessorTransactionId__c,
                           PSA_Transaction_Date__c,
                           SystemModstamp
                      FROM PSA_Card_Transaction_Stage__c

                     WHERE Id not in ( SELECT PSA_Card_Transaction_Stage__c
                                         FROM PSA_Card_Transaction__c )

                     ]);
                    // ?????  do we need to include by date range????
    }

    // process the batch records
    global void execute(Database.BatchableContext BC, PSA_Card_Transaction_Stage__c[] scope)
    {
        psaCardTransactionLoader.process(scope);

    }

    // finish processing.....
    global void finish(Database.BatchableContext BC)
    {

        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [
            SELECT Id,
                   Status,
                   NumberOfErrors,
                   JobItemsProcessed,
                   TotalJobItems,
                   CreatedBy.Email
              FROM AsyncApexJob
             WHERE Id = :BC.getJobId()];

      // log Apex job details
      String apexJobDetails = '**** psaCardTransactionLoaderBatch Finish()  status: ' + a.status + ' Total Jobs: ' + a.TotalJobItems + ' Errors: ' + a.NumberOfErrors;

      //system.debug(apexJobDetails);

      psaIntegrationUtils.writeLogEntry(
             BC.getJobId(),
            'Card Transactions',
            'Card Transactions',
            psaIntegrationUtils.LOG_TYPE_INFORMATION,
            apexJobDetails,
            apexJobDetails,
            null,
            null);
  }
}