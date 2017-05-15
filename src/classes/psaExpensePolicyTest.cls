@isTest
private class psaExpensePolicyTest {
	@isTest static void testExpensePoliciesProject() {
		PageReference pg = Page.psaExpensePolicyEntry;
		test.setCurrentPage(pg);
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('prjid', testProject.id);
        psaExpensePolicyEntryController epec = new psaExpensePolicyEntryController();

        
        List<psaExpensePolicyEntryController.PSAPolicyModel> listPolicies = new List<psaExpensePolicyEntryController.PSAPolicyModel>();
        epec.listPolicyModel = listPolicies;
        epec.addNewPolicy();
        listPolicies = epec.listPolicyModel;
        System.debug(listPolicies.size());
        List<PSA_Expense_Policy__c> expenses = new List<PSA_Expense_Policy__c>();
        PSA_Expense_Policy__c firstPolicy = psaTestUtils.createTestPolicy('Test One', testProject.id, null, 'Airfare - Domestic', 'Receipt Required', 100, false);
        PSA_Expense_Policy__c secondPolicy = psaTestUtils.createTestPolicy('Test Two', testProject.id, null, 'Hotel', 'Single Billing Limit', 100, false);
		PSA_Expense_Policy__c thirdPolicy = psaTestUtils.createTestPolicy('Test Three', testProject.id, null, 'Gas for Rental Car', 'Note Required', 100, false);
		PSA_Expense_Policy__c fourthPolicy = psaTestUtils.createTestPolicy('Test Four', testProject.id, null, 'Office Supplies', 'Amount Review Threshold', 100, false);
		expenses.add(firstPolicy);
		expenses.add(secondPolicy);
		expenses.add(thirdPolicy);
		expenses.add(fourthPolicy);
		epec.expensePolicies = expenses;
		System.debug('originally it is: '+epec.expensePolicies);
		epec.loadPolicies();
		System.debug('originally: '+epec.listPolicyModel);
		PSA_Expense_Policy__c extra = psaTestUtils.createTestPolicy('Test Five', testProject.id, null, 'Excess Baggage', 'Receipt Required', 100, false);
		expenses.clear();
		expenses.add(extra);
		epec.addPoliciesToList(expenses);
		epec.save();
		System.debug('After: '+epec.listPolicyModel);


		Integer count = 0;
		for(psaExpensePolicyEntryController.PSAPolicyModel next : epec.listPolicyModel){
			if(count != 0){
				next.isCheck = true;
			}
			else{
				next.isCheck = false;
			}
			count++;
		}
		epec.removePolicy();
		epec.save();
		epec.close();
		Test.stopTest();
	}

	@isTest static void testExpensePoliciesAccount() {
		PageReference pg = Page.psaExpensePolicyEntry;
		test.setCurrentPage(pg);
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

        ApexPages.currentPage().getParameters().put('acctid', a.id);
        psaExpensePolicyEntryController epec = new psaExpensePolicyEntryController();

        List<PSA_Expense_Policy__c> expenses = new List<PSA_Expense_Policy__c>();
        PSA_Expense_Policy__c firstPolicy = psaTestUtils.createTestPolicy('Test One', null, a.id, 'Airfare - Domestic', 'Receipt Required', 100, false);
        PSA_Expense_Policy__c secondPolicy = psaTestUtils.createTestPolicy('Test Two', null, a.id, 'Hotel', 'Single Billing Limit', 100, false);
		PSA_Expense_Policy__c thirdPolicy = psaTestUtils.createTestPolicy('Test Three', null, a.id, 'Gas for Rental Car', 'Note Required', 100, false);
		PSA_Expense_Policy__c fourthPolicy = psaTestUtils.createTestPolicy('Test Four', null, a.id, 'Office Supplies', 'Amount Review Threshold', 100, false);
		expenses.add(firstPolicy);
		expenses.add(secondPolicy);
		expenses.add(thirdPolicy);
		expenses.add(fourthPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		epec.save();
		epec.doesAccountPolicyExist();
		epec.loadFromRelatedAccount();
		epec.close();

    }

    @isTest static void testExpensePoliciesGlobal() {
		PageReference pg = Page.psaExpensePolicyEntry;
		test.setCurrentPage(pg);
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
		PSA_Expense_Policy__c firstPolicy = psaTestUtils.createTestPolicy('Test One', null, null, 'Airfare - Domestic', 'Receipt Required', 100, true);
        psaExpensePolicyEntryController epec = new psaExpensePolicyEntryController();
        List<PSA_Expense_Policy__c> expenses = new List<PSA_Expense_Policy__c>();
        PSA_Expense_Policy__c thirdPolicy = psaTestUtils.createTestPolicy('Test Three', null, null, 'Gas for Rental Car', 'Note Required', 100, false);
		PSA_Expense_Policy__c fourthPolicy = psaTestUtils.createTestPolicy('Test Four', null, null, 'Office Supplies', 'Amount Review Threshold', 100, false);
		expenses.add(thirdPolicy);
		expenses.add(fourthPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
    }

    @isTest static void testExpensePoliciesErrors() {
    	PageReference pg = Page.psaExpensePolicyEntry;
		test.setCurrentPage(pg);
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;
        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);

        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('prjid', testProject.id);
        psaExpensePolicyEntryController epec = new psaExpensePolicyEntryController();

        
        List<psaExpensePolicyEntryController.PSAPolicyModel> listPolicies = new List<psaExpensePolicyEntryController.PSAPolicyModel>();
        epec.listPolicyModel = listPolicies;
        epec.addNewPolicy();
        listPolicies = epec.listPolicyModel;
        System.debug(listPolicies.size());
        List<PSA_Expense_Policy__c> expenses = new List<PSA_Expense_Policy__c>();
        PSA_Expense_Policy__c firstPolicy = psaTestUtils.createTestPolicy(null, testProject.id, null, 'Airfare - Domestic', 'Receipt Required', 100, false);
		expenses.add(firstPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		try{
			epec.save();
		} catch(Exception e){
			System.debug('Correctly caught the error');
		}

		expenses.clear();
		firstPolicy = psaTestUtils.createTestPolicy('Test', testProject.id, null, 'Airfare - Domestic', 'Receipt Required', -1, false);
		expenses.add(firstPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		try{
			epec.save();
		} catch(Exception e){
			System.debug('Correctly caught the 2nd error');
		}

		expenses.clear();
		firstPolicy = psaTestUtils.createTestPolicy('Test', testProject.id, null, 'Airfare - Domestic', 'Single Billing Limit', -1, false);
		expenses.add(firstPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		try{
			epec.save();
		} catch(Exception e){
			System.debug('Correctly caught the 3rd error');
		}

		expenses.clear();
		firstPolicy = psaTestUtils.createTestPolicy('Test', testProject.id, null, 'Airfare - Domestic', 'Amount Review Threshold', -1, false);
		expenses.add(firstPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		try{
			epec.save();
		} catch(Exception e){
			System.debug('Correctly caught the 4th error');
		}

		expenses.clear();
		firstPolicy = psaTestUtils.createTestPolicy('Test', testProject.id, null, 'Airfare - Domestic', 'Receipt Required', 50, false);
		PSA_Expense_Policy__c secondPolicy = psaTestUtils.createTestPolicy('Test Two', testProject.id, null, 'Airfare - Domestic', 'Receipt Required', 100, false);
		expenses.add(firstPolicy);
		expenses.add(secondPolicy);
		epec.expensePolicies = expenses;
		epec.loadPolicies();
		try{
			epec.save();
		} catch(Exception e){
			System.debug('Correctly caught the duplicate error');
		}	
		Test.stopTest();

    }

    @isTest static void testExpensePoliciesLoad() {
		PageReference pg = Page.psaExpensePolicyEntry;
		test.setCurrentPage(pg);
		psaTestUtils.initDefaultWorkCalendar();
        //Create RPG
        pse__Region__c testR = psaTestUtils.createTestRegion('Corporate');
        pse__Practice__c testP = psaTestUtils.createTestPractice('Corporate');
        pse__Grp__c testG = psaTestUtils.createTestGroup('Corporate');
        Account a = psaTestUtils.createTestAccount('Test Account', '12345');
        a.Participant_id__c = '1234';
        update a;

        //Create 2 contacts, one to submit and one as the manager
        User u = psaTestUtils.createTestUser('userCLD2', 'tuserCLD2@tuser.com', 'userCLD2', 'test2', 'tuserCLD2@tuser.com', 'tuserCLD2');
        Contact c = psaTestUtils.createTestResource(u, testR, testP, testG);
        pse__Proj__c testProject = psaTestUtils.createTestProjectInProgress('Test Project', a, testR, testP, testG, null, c, u);
       	Test.startTest();
        pse__Proj__c testProject2 = psaTestUtils.createTestProjectInProgress('Test Project 2', a, testR, testP, testG, null, c, u);
        
        ApexPages.currentPage().getParameters().put('prjid', testProject.id);
        psaExpensePolicyEntryController epec = new psaExpensePolicyEntryController();
        PSA_Expense_Policy__c firstPolicy = psaTestUtils.createTestPolicy('Project test', testProject2.id, null, 'Airfare - Domestic', 'Receipt Required', 100, true);
        PSA_Expense_Policy__c accountPolicy = psaTestUtils.createTestPolicy('Project test', null, a.id, 'Airfare - Domestic', 'Receipt Required', 100, true);
        epec.projCopy = testProject2.id;
        epec.loadFromProject();
        epec.loadFromRelatedAccount();
        test.stopTest();
    }

}