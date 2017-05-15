/**
 * @description Testing trac_AccountContactHandler Generates auto number for the Contact_Key__c field
 *
 * @author Tanminder Rai, Traction On Demand
 * @date May 25/2015
 */
@isTest
private class trac_AccountContactHandlerTest {

  //************************ Test Utils *************************

  private static List<Contact> createContact(Integer howMany){
    List<Contact> contList = new List<Contact>();
    for (Integer i = 0; i < howMany; i++){
      contList.add( new Contact(LastName='Test'+i, Email='test@test.com') );
    }
    insert contList;
    return contList;    
  }

	//************************ Unit Tests **************************

  //Test that the auto number is incremented when new Account_Contact__c records are created
   @isTest
    static void accountGenerateAutoNumTest(){
      insert new Five_Digit_Id__c(Current_Value__c = 10002);

      List<Contact> contList = createContact(2);
      Account acc = new Account(Name = 'Test', Participant_Id__c = '0');
      insert acc;
      Account_Contact__c accountContact = new Account_Contact__c(Contact__c = contList[0].Id, Account__c=acc.Id, Integration_Status__c = 'Pending Integration', Participant_Account__c=acc.Id); 
    	insert accountContact;

      for (Account_Contact__c accRetrieve :[SELECT Id, Contact_Key__c
                                 			  FROM Account_Contact__c 
                                 			  WHERE Id=:accountContact.Id]){
          System.assertEquals(String.ValueOf(10002), accRetrieve.Contact_Key__c);
      }

        //The next account contact should get the next consecutive number
      Account_Contact__c accountContact2 = new Account_Contact__c(Contact__c = contList[0].Id, Account__c=acc.Id, Integration_Status__c = 'Pending Integration', Participant_Account__c=acc.Id); 
      insert accountContact2;  
      for (Account_Contact__c accRetrieve :[SELECT Id, Contact_Key__c
                                        FROM Account_Contact__c 
                                        WHERE Id=:accountContact2.Id]){
          System.assertEquals(String.ValueOf(10003), accRetrieve.Contact_Key__c);
      }

    }       

    //Test that the auto number is incremented when record is updated to match trigger condition
    @isTest
    static void accountGenerateAutoNumUpdateTest(){

      insert new Five_Digit_Id__c(Current_Value__c = 1002);

      List<Contact> contList = createContact(2);
      Account acc = new Account(Name = 'Test', Participant_Id__c = '0');
      insert acc;
      Account_Contact__c accountContact = new Account_Contact__c(Contact__c = contList[0].Id, Account__c=acc.Id, Participant_Account__c=acc.Id); 
      insert accountContact;

      accountContact.Integration_Status__c = 'Pending Integration';
      update accountContact;

      for (Account_Contact__c accRetrieve :[SELECT Id, Contact_Key__c
                                        FROM Account_Contact__c 
                                        WHERE Id=:accountContact.Id]){
          System.assertEquals(String.ValueOf(1002), accRetrieve.Contact_Key__c);
      }
    }

    // Test for query failure
    @isTest
    static void generateAutoNumberFailure(){
        List<Contact> contList = createContact(2);
        Account acc = new Account(Name = 'Test', Participant_Id__c = '0');
        insert acc;
        Account_Contact__c accountContact = new Account_Contact__c(Contact__c = contList[0].Id, Account__c=acc.Id, Participant_Account__c=acc.Id); 
        insert accountContact;

        accountContact.Integration_Status__c = 'Pending Integration';
        trac_GenerateAutoNumber.TEST_EXCEPTION = true;

        // Attempt an update
        try {
            update accountContact;
            System.assert(False, 'Expected exception not thrown');
        } catch (DmlException exp) {
            // Success because the account was not updated
        }
    }
}