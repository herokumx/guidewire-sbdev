/**
 * @description Testing the account handler
 *
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */

@isTest
private class trac_AccountHandlerTest {

    public static Id PROS_RT;
    public static Id COUNTRY_ID; 

    private static void setRecordType(){
        RecordType rt = [SELECT id, Name FROM RecordType 
                                        WHERE sobjecttype='Account' 
                                        AND Name=:'Prospect' LIMIT 1];

        PROS_RT = rt.Id;
    }
    
    private static void setCountryId(){
      
      
      pw_cc__CountryObject__c country = new pw_cc__CountryObject__c(
                                  Name = 'Test Country',
                                  pw_cc__IsoCode_2__c = 'TC',
                                  pw_cc__IsoCode_3__c = 'TC'
                                );
      insert country;                           
      COUNTRY_ID = country.Id;
    }

   @isTest
    static void accountGenerateAutoNumTest(){

        insert new Four_Digit_Id__c(Current_Value__c = 1002);

        Account a = new Account(Name = 'Test', Approval_Status__c = 'Approved'); 
        insert a;

        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a.Id]){
            System.assertEquals(String.ValueOf(1002), accRetrieve.Participant_id__c);
        }

        //The next account should get the next consecutive number
        Account a2 = new Account(Name = 'Test2', Approval_Status__c = 'Approved'); 
        insert a2;    
        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a2.Id]){
            System.assertEquals(String.ValueOf(1003), accRetrieve.Participant_id__c);
        }            

        Account a3 = new Account(Name = 'Test3', Approval_Status__c = 'Approved'); 
        insert a3;    
        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a3.Id]){
            System.assertEquals(String.ValueOf(1004), accRetrieve.Participant_id__c);
        } 

        //the participant Id should remain the same after updating if Participant_id__c already exists
        a.Email__c = 'test@test.com';
        update a;
        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a.Id]){
            System.assertEquals(String.ValueOf(1002), accRetrieve.Participant_id__c);
        } 
     }

    //updating status to approved 
    @isTest
    static void accountGenerateAutoNumUpdateTest(){

        insert new Four_Digit_Id__c(Current_Value__c = 1002);

        Account a = new Account(Name = 'Test'); 
        insert a;

        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a.Id]){
            System.assertEquals(NULL, accRetrieve.Participant_id__c);
        }

        a.Approval_Status__c = 'Approved';
        update a;

        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a.Id]){
            System.assertEquals(String.ValueOf(1002), accRetrieve.Participant_id__c);
        }
    }

    // Test for query failure
    @isTest
    static void generateAutoNumberFailure(){
        Account a = new Account(Name = 'Test'); 
        insert a;

        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id=:a.Id]){
            System.assertEquals(NULL, accRetrieve.Participant_id__c);
        }

        trac_GenerateAutoNumber.TEST_EXCEPTION = true;

        // Attempt an update
        a.Approval_Status__c = 'Approved';
        try {
            update a;
            System.assert(False, 'Expected exception not thrown');
        } catch (DmlException exp) {
            // Success because the account was not updated
        }
    }

    //Bulk Test
    @isTest
    static void accountGenerateAutoNumBulkTest(){

        insert new Four_Digit_Id__c(Current_Value__c = 1000);

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i<200 ; i++){
            accounts.add(new Account(Name = 'Test'+String.ValueOf(i), Approval_Status__c = 'Approved')); 
        }
        insert accounts;

        for (Account accRetrieve :[SELECT Id, Participant_id__c
                                              FROM Account 
                                              WHERE Id IN :accounts]){
            System.assertNotEquals(null, accRetrieve.Participant_id__c);
        }
    }

    //Testing that the record is submittted for approval
    @isTest
    static void accountAutoSubmitTest(){
        setRecordType();
        setCountryId();
        Account acc = new Account(
                                Name = 'Test Account', 
                                Approval_Status__c = 'Resubmit Required',
                                Participant_id__c = '6652',
                                RecordTypeId = PROS_RT,
                                Requested_Approval__c = 'New Customer - Direct',
                                /*BillingStreet = 'test',
                                BillingCity = 'test',
                                BillingCountry = 'Canada',
                                BillingPostalCode = 'test',*/
                                pw_cc__BillingCountryLookup__c = COUNTRY_ID,
                                Billing_Zip_Postal_Code__c = '0010',
                                Billing_City__c = 'test',
                                Billing_Street__c ='testStreet',
                                //update custom Account Billing address fields.
                                Invoice_Delivery_Method__c = 'E',
                                Payment_Term__c = 'Net 30'
                                );       
        Test.startTest();
        insert acc;
        Test.stopTest();

        update acc;

        List<ProcessInstance> processInstances = [select Id, Status from ProcessInstance where TargetObjectId = :acc.id];
        System.assertEquals(1, processInstances.size());
    }

     @isTest
     private static void validateAccountContactDeletetion(){
        setRecordType();
        setCountryId();
        Test.startTest();
        List<Contact> contList = createContact(2);
        Account acc = new Account(Name = 'Test',  pw_cc__BillingCountryLookup__c = COUNTRY_ID,
                                Billing_Zip_Postal_Code__c = '0010',
                                Participant_id__c = '6666',
                                Billing_City__c = 'test',
                                Billing_Street__c ='testStreet',
                                //update custom Account Billing address fields.
                                Invoice_Delivery_Method__c = 'E',
                                Payment_Term__c = 'Net 30',recordTypeid = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site').RecordTypeId);
        insert acc;
        
        Account acc1 = new Account(
                                Name = 'Test Account', 
                                Participant_id__c = '6652',
                                RecordTypeId = PROS_RT,
                                pw_cc__BillingCountryLookup__c = COUNTRY_ID,
                                Billing_Zip_Postal_Code__c = '0010',
                                Billing_City__c = 'test',
                                Billing_Street__c ='testStreet',
                                Invoice_Delivery_Method__c = 'E',
                                Payment_Term__c = 'Net 30'
                                );       
        insert acc1;

        Account_Contact__c accountContact = new Account_Contact__c(Contact__c = contList[0].Id, RecordStatus__c  = 'Active',Contact_Key__c ='test', Account__c=acc.Id, Participant_Account__c=acc1.Id); 
        insert accountContact;

         try{
             delete contList;
          }catch(DmlException ex){
          }
          try{
            delete acc;
          }catch(DmlException ex){
          }
        Test.stopTest();
     
     }

private static List<Contact> createContact(Integer howMany){
    List<Contact> contList = new List<Contact>();
    for (Integer i = 0; i < howMany; i++){
      contList.add( new Contact(LastName='Test'+i, Email='test@test.com') );
    }
    insert contList;
    return contList;    
  }

}