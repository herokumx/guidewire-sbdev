@isTest
private class TestTaskTrigger { 
	static testMethod void createTask() {
          Profile p = [select id from profile where name='Standard User'];
          User usr = new User(alias = 'standt', email='standardTestuser@testorg.com',
          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
          localesidkey='en_US', profileid = p.Id,
          timezonesidkey='America/Los_Angeles', username='standardTestuser@testorg.com');
		  insert usr;
		  Task taskObj = new Task(OwnerId = usr.Id, MH_Action__c = true);
		  insert taskObj;
	}
}