/**
 * @description Generates a unique number 
 *
 * @date May 25/2015
 */
public with sharing class trac_GenerateAutoNumber {

    private static final Integer MAX_ATTEMPTS = 4;
    private static final Integer WAIT_TIME = 2;
    private static final String ERROR_NO_RECORD_FOUND   = 'No record found in custom settings';
    public static Boolean TEST_EXCEPTION = false;

    private static Integer numLoadAttempts = 0;
    private static Id siteRecordTypeId;
    /**
     * Set the participant_id__c field to a unique value on the given accounts
     * @param accounts The accounts
     */
    public static void setAccountParticipantIds(List<Account> accounts) {
        //Init Site RecordTypeId
        if(siteRecordTypeId == null)
            siteRecordTypeId = getSiteRecordTypeId();

        // Filter out all accounts except those with blank participant_id and 'Approved' approval status 
        List <Account> filteredAccounts = new List<Account>();
        for (Account a : accounts){
            if (
                a.RecordTypeId       != siteRecordTypeId &&
                a.Participant_id__c  == null &&
                a.Approval_Status__c == 'Approved'
            ) {
                filteredAccounts.add(a);
            }   
        }

        // No need to continue if no accounts are passed
        if (filteredAccounts.size() == 0) {
            return;
        }

        List<Four_Digit_Id__c> theSettings;

        // Get the custom setting containing the current unused participant ID
        try {
            theSettings = [
                SELECT  Current_Value__c
                FROM    Four_Digit_Id__c
                LIMIT 1
                FOR UPDATE
            ];

            /* It doesn't seem to be possible to lock the custom settings during a test to trigger an exception
             * so an exception is manually thrown here */
            if (Test.isRunningtest() && TEST_EXCEPTION) {
                throw new CustomException('test'); 
            }
        } catch (Exception e) {
            if (numLoadAttempts > MAX_ATTEMPTS) {
                throw new CustomException('There was an error processing your request. Please Try again');
            } else {
                wait(WAIT_TIME);
                numLoadAttempts+=1;
                setAccountParticipantIds(filteredAccounts);
            }
        }
        if(theSettings.isEmpty())
            throw new AuToNumberSettingsException(ERROR_NO_RECORD_FOUND);
        
        // Set the participant ID
        Integer i = Integer.ValueOf(theSettings[0].Current_Value__c);
        for (Account acc : filteredAccounts) {
            acc.Participant_id__c = String.valueOf(i++);
        }

        // Update the custom setting
        theSettings[0].Current_Value__c = i;
        update theSettings[0];
    }

    /**
     * Set the Contact_Key__c field of the given account contacts to a unique value
     * 
     * @param contacts The account contacts 
     */
    public static void setAccountContactKeys(List<Account_Contact__c> contacts) {
        // No need to continue if no accounts are passed
        if (contacts.size() == 0) {
            return;
        }

        List<Five_Digit_Id__c> theSettings;

        try {
            theSettings = [
                SELECT  Current_Value__c
                FROM    Five_Digit_Id__c
                LIMIT 1
                FOR UPDATE
            ];      

            /* It doesn't seem to be possible to lock the custom settings during a test to trigger an exception
             * so an exception is manually thrown here */
            if (Test.isRunningtest() && TEST_EXCEPTION) {
                throw new CustomException('test'); 
            }
        } catch (Exception e) {
            if (numLoadAttempts > MAX_ATTEMPTS) {
                throw new CustomException('There was an error processing your request. Please try again');
            } else {
                wait(WAIT_TIME);
                numLoadAttempts+=1;
                setAccountContactKeys(contacts);
            }
        }
        if(theSettings.isEmpty())
            throw new AuToNumberSettingsException(ERROR_NO_RECORD_FOUND);

        // Set the contact keys
        Integer i = Integer.ValueOf(theSettings[0].Current_Value__c);
        for (Account_Contact__c c : contacts) {
            c.Contact_Key__c = String.valueOf(i++);
        }

        // Update the custom setting
        theSettings[0].Current_Value__c = i;
        update theSettings[0];  
    }

    // Generic wait function
    private static void wait(Integer milliseconds) {
        Integer start = System.now().millisecond() ;
        while (System.now().millisecond() < (start + milliseconds)) {
            /*wait*/
        }
    }

    private static Id getSiteRecordTypeId() {           
        Id recordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site').RecordTypeId;
        if(recordTypeId  != null)
            return recordTypeId;
        else
            throw new NoRecordTypeException('RecordType Site is not defined');
    }

    public class CustomException extends Exception {}
    public class AuToNumberSettingsException extends Exception{}
    public class NoRecordTypeException extends Exception {}
}