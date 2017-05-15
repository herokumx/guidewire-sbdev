/*
*****************************************************************************************************************************
Class Name - CS_ExceptionHandler
Class Type -  Handler
Test Class-
Purpose- Error Log Handler

*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                           Initial Creation


*****************************************************************************************************************************
*/
global without sharing class CS_ExceptionHandler {
    public CS_ExceptionHandler() {
        
    }

// Method used to catch exception on Customer Onboarding Setup via Service Contract
  @future
     public static void createErrorRecord(string exceptionMessage,Id ObjectId){
         CS_Error_Logs__c newErrorRecord = new CS_Error_Logs__c();
         newErrorRecord.CS_Error_Message__c = exceptionMessage;
         newErrorRecord.CS_Record_Id__c=ObjectId;
         newErrorRecord.CS_User__c=UserInfo.getUserId();
         newErrorRecord.CS_Object_Name__c=String.valueOf(ObjectId.getSObjectType());
         Database.insert(newErrorRecord,false);
     }

     @future
     public static void createErrorRecordMessage(string exceptionMessage,String Calledmethod){
         CS_Error_Logs__c newErrorRecord = new CS_Error_Logs__c();
         newErrorRecord.CS_Error_Message__c = exceptionMessage;
         newErrorRecord.CS_User__c=UserInfo.getUserId();
         newErrorRecord.CS_Called_Method__c=Calledmethod;
         Database.insert(newErrorRecord,false);
     }

}