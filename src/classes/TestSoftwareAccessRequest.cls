//--------------------
// Test Class for Software Access Request Controller and helper Class.
// Date: 1/23/2016
// Author: Rohit Koul
//--------------------

@isTest(seeAllData=true)
Private class TestSoftwareAccessRequest { 
  private static Id createSAR(){
     //    List<Profile> lstProfile =[Select Id from Profile 
     //                               where profile.userlicense.name = 'Partner Community'];
    //    List<RecordType> lstRecordType = [Select Id from RecordType where Name ='Partner'];
	//	List<User> userList = [Select ID from User where isactive = true and Profile.Id in: lstProfile];
	
        Account objAccount = psaTestUtils.createTestAccount('Test Account', '12345');
        objAccount.Participant_id__c = '1234';
        objAccount.BillingStreet = '123 Sesame Street';
        objAccount.BillingCity = 'Sesame City';
        objAccount.BillingState = 'CA';
        objAccount.BillingPostalCode = '90210';
        objAccount.BillingCountry = 'USA';
        update objAccount;
        
        Contact contact = new Contact();
        contact.LastName = 'testContact';
        contact.AccountId = objAccount.Id;
        contact.Category__c = 'Billing';
		contact.Email = 'testGuidewire@mail.com';
	
        insert contact;

		Account_Contact__c acrObj = new Account_Contact__c();
		acrObj.Account__c = objAccount.Id;
		acrObj.Contact__c = contact.Id;
		acrObj.Participant_Account__c = objAccount.Id;
		acrObj.Contact_Type__c ='Ship To';
		insert acrObj;
		
		opportunity opp = new opportunity();
        opp.StageName='Closed-Won';
        opp.CloseDate=system.today();
        opp.CurrencyIsoCode ='USD';
        opp.Name='Test Opportinity1'; 
        opp.amount=5000;
        
        insert opp;     
        
        Software_Access_Request__c sarObj = new Software_Access_Request__c(Status__C = 'Draft',Products__c ='Other;Standards Based Templates;Thunderhead;Guidewire Live', Customer_Contact_Name__c =  acrObj.Id,Customer_Name__c = objAccount.Id, Request_type__c = 'New Customer', Opportunity__c=opp.Id, Date_needed__c = System.today(), Content_items__c = 'test1,CA,GA;test2,CA,GA');
	    insert sarObj;
	    return sarObj.Id;
  }  
  static testMethod void testSAR() {
    ApexPages.currentPage().getParameters().put('Id', createSAR());
    ApexPages.StandardController controller = new ApexPages.StandardController(new Software_Access_Request__c());
    SoftwareAccessRequestController sarCon = new SoftwareAccessRequestController(controller);
    sarCon.initializeValues();
	sarCon.assignCustomSettings();
	sarCon.assignContentItems();	
	sarCon.getCustomerContactDetails();
	sarCon.Save();
	SoftwareAccessRequestController sarCon1 = new SoftwareAccessRequestController(controller);
	sarCon1.submitRequest();
	ApexPages.currentPage().getParameters().put('retURL', 'testReturn');
	SoftwareAccessRequestController sarCon2 = new SoftwareAccessRequestController(controller);
	sarCon2.completeReq();	
  }
}