/**************************************************************************************
// Name          : psaExpensePolicyEntryController
// Date          : April 20, 2015
// Description   : Controller for the psaExpensePolicyEntry VF Page
// Author        : CLD Partners
// Revisions     : 2015-04-20  Spano Initial Revision
//               : 
***************************************************************************************/
public with sharing class psaExpensePolicyEntryController {
    
    //The project associated with the policies
    public pse__Proj__c mainProject {get;set;}
    //The account associated with the policies
    public Account mainAccount {get;set;}
    public List<PSA_Expense_Policy__c> expensePolicies {get;set;}
    public List<PSAPolicyModel> listPolicyModel {get;set;}

    //A set of Policies to delete
    public Set<Id> toDelete {get;set;}

    public String projectId {get;set;}
    private String accountId {get;set;}

    //The id of the account related to the main project
    public String relatedAccountId {get;set;}
    //The id being used from the project that is having its policies copied
    public String projCopy {get;set;}
    private String rateSetId {get;set;}
    private String contextId {get;set;}

    public boolean isAccountRendered{get;set;}
    public boolean isProjectRendered{get;set;}
    public Boolean isGlobal {get;set;}
    public boolean relatedAccountPolicyExists {get;set;}
    private Set<String> existingPolicies;

    private String errorMessage;




    public psaExpensePolicyEntryController() {
        projectId = ApexPages.currentPage().getParameters().get('prjid');
        rateSetId = ApexPages.currentPage().getParameters().get('rsid');
        accountId = ApexPages.currentPage().getParameters().get('acctid');

        toDelete = new Set<Id>();


        //Determine if this is a project, account level, or global expense policy
        isAccountRendered = (accountId != null && (projectId == null || projectId == ''));
        isProjectRendered = (projectId != null && projectId != '' && (accountId == null || accountId == ''));
        

        listPolicyModel = new List<PSAPolicyModel>();

        //If the project is rendered, find the parent project based off of the first expense policy, check 
        //to see if a related account exists
        if(isProjectRendered){
            contextId = projectId;
            List<pse__Proj__c> projects = [SELECT Id,Name,Pse__Account__c from pse__Proj__c where ID =: projectId];
            if(projects != null && projects.size() > 0){
                mainProject = projects.get(0);
                relatedAccountId = projects.get(0).pse__account__c;
            }
            doesAccountPolicyExist();
            //set context id to projectid
        }

        //If the account is rendered, set the context to the account and set the main account to the Account id on 
        //the first expense policy
        else if(isAccountRendered){
            contextId = accountId;
            List<Account> accounts = [SELECT ID,Name from Account where ID = :accountId];
            if(accounts != null && accounts.size() > 0){
                mainAccount = accounts.get(0);
            }
            //set contextid to accountid
        }
        else{
            contextId = null;
            //set the context id to null
            //load the defaults
        }
        if(accountId == null && projectId == null){
            isGlobal = true;
            contextId = null;
        }


        boolean isPolicyFound = false;
        //Obtain a list of expense policies based on either the account, project, or global level
        expensePolicies = queryPolicyByContextId(contextID);
        if(expensePolicies != null && expensePolicies.size() > 0){
            //Load the policies into the GUI
            loadPolicies();
        }
        
    }

    public List<PSA_Expense_Policy__c> queryPolicyByContextId(String contextId){
        List<PSA_Expense_Policy__c> policies = null;
        if(contextId == null){
            policies = [SELECT id, Name,
                                        PSA_Account__c,
                                        PSA_Account__r.name,
                                        PSA_Project__c,
                                        PSA_Project__r.name,
                                        PSA_Amount_Review_Threshold__c,
                                        PSA_Billable_Limit__c,
                                        PSA_Expense_Type__c,
                                        PSA_Policy_Type__c,
                                        PSA_Receipt_Required_Threshold__c
                                FROM PSA_Expense_Policy__c
                                WHERE (PSA_Account__c = ''
                                      AND PSA_Project__c = '')];
        }
        else{
            policies = [SELECT id, Name,
                                        PSA_Account__c,
                                        PSA_Account__r.name,
                                        PSA_Project__c,
                                        PSA_Project__r.name,
                                        PSA_Amount_Review_Threshold__c,
                                        PSA_Billable_Limit__c,
                                        PSA_Expense_Type__c,
                                        PSA_Policy_Type__c,
                                        PSA_Receipt_Required_Threshold__c
                                FROM PSA_Expense_Policy__c
                                WHERE (PSA_Account__c =: contextId
                                      OR PSA_Project__c =: contextId)];

        }
        return policies;
    }

     // save button...
        public PageReference save(){
            try{
                if(validate()){
                    savePolicies();
                    return null;
                }
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,errorMessage));
                    return null;
                }
            }
            catch(Exception except){
                System.debug('*** Exception: ' + except.getMessage());
                return null;
            }
    }

    private boolean checkForDuplicates(){

        Map<String, Map<String, Boolean>> potentialMap = new Map<String, Map<String, Boolean>>();
        for(PSAPolicyModel nextModel : listPolicyModel){
            PSA_Expense_Policy__c nextPolicy = nextModel.policy;
            String policyType = nextPolicy.PSA_Policy_Type__c;
            Map<String, Boolean> existForType = potentialMap.get(policyType);
            
            if(existForType == null){
                existForType = new Map<String, Boolean>();
                String expenseType = nextPolicy.PSA_Expense_Type__c;
                existForType.put(expenseType, true);
                potentialMap.put(policyType, existForType);
            }
            else{
                String expenseType = nextPolicy.PSA_Expense_Type__c;
                Boolean exists = existForType.get(expenseType);
                if(exists == null || exists == false){
                    existForType.put(expenseType, true);
                }
                else{
                    errorMessage = 'Only one Expense Policy can exist for a single policy type and expense type pairing';
                    return true;
                }
            }
        }
        return false;
    }

    private boolean validate(){

        for(PSAPolicyModel nextModel : listPolicyModel){
                PSA_Expense_Policy__c nextPolicy = nextModel.policy;

                if(nextPolicy.name == null || nextPolicy.name == '' || nextPolicy.PSA_Policy_Type__c == null || nextPolicy.PSA_Policy_Type__c == '' ||
                    nextPolicy.PSA_Expense_Type__c == null || nextPolicy.PSA_Expense_Type__c == ''){
                    errorMessage = 'Name, policy type and expense type are all required';
                    return false;
                }

                if(nextPolicy.PSA_Policy_Type__c == 'Single Billing Limit'){
                    if(nextPolicy.PSA_Billable_Limit__c == null || nextPolicy.PSA_Billable_Limit__c < 0){
                        errorMessage = 'Billable Limit required with policies of type Single Billing Limit';
                        return false;
                    }
                }
                else if(nextPolicy.PSA_Policy_Type__c == 'Receipt Required'){
                    if(nextPolicy.PSA_Receipt_Required_Threshold__c == null || nextPolicy.PSA_Receipt_Required_Threshold__c < 0){
                        errorMessage = 'Receipt Required Threshold is required with policies of type Receipt Required';
                        return false;
                    }
                }
                else if(nextPolicy.PSA_Policy_Type__c == 'Amount Review Threshold'){
                    if(nextPolicy.PSA_Amount_Review_Threshold__c == null || nextPolicy.PSA_Amount_Review_Threshold__c < 0){
                        errorMessage = 'Review Required Threshold is required with policies of type Amount Review Threshold';
                        return false;
                    }
                }
        }
        if(checkForDuplicates()){
            return false;
        }
        else{
            
        }
    
        return true;
        
    }

    private pageReference savePolicies(){
            
            try{

                    List<PSA_Expense_Policy__c> toSave = new List<PSA_Expense_Policy__c>();
                    for(PSAPolicyModel nextModel : listPolicyModel){
                        if(!toDelete.contains(nextModel.policy.id)){
                            System.debug('Adding: '+nextModel.policy.name+' to the list');
                            PSA_Expense_Policy__c newPolicy = nextModel.policy;
                            if(isProjectRendered){
                                newPolicy.psa_Account__c = null;
                                newPolicy.psa_Project__c = mainProject.id;
                            }
                            else if(isAccountRendered){
                                newPolicy.psa_Account__c = mainAccount.id;
                                newPolicy.psa_Project__c = null;
                            }
                            toSave.add(newPolicy);
                        }
                    }
                    
                    upsert toSave;

                    System.debug('Upserted!');

                   if(toDelete != null && toDelete.size() > 0){
                        System.debug('We are deleting now');
                        List<PSA_Expense_Policy__c> policiesToDelete = [SELECT id FROM PSA_Expense_Policy__c
                                                            WHERE id in :toDelete];
                        delete policiesToDelete;
                    }
                    
                    
                    expensePolicies = queryPolicyByContextId(contextID);
                    System.debug('We have a new list: '+expensePolicies);

                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Rate Set Saved Successfully'));
                    toDelete = new Set<id>();
                    if(contextId == null){
                        return new PageReference('/');
                    }
                    return new PageReference('/' + contextID);
            }
            catch(Exception except){
                System.debug('*** Exception: ' + except.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, except.getMessage()));
            }
            return null;
    }

    public void loadPolicies(){
        listPolicyModel = new List<PSAPolicyModel>();
        for(PSA_Expense_Policy__c policy : expensePolicies){
            PSAPolicyModel model = new PSAPolicyModel();
            model.policy = policy;
            listPolicyModel.add(model);
        }
    }

    public void addPoliciesToList(List<PSA_Expense_Policy__c> policies){
        for(PSA_Expense_Policy__c policy : policies){
            PSAPolicyModel model = new PSAPolicyModel();
            model.policy = policy;
            listPolicyModel.add(model);
        }
    }

    // add new rate
    public void addNewPolicy(){
        PSAPolicyModel model;
        model = new PSAPolicyModel();
        listPolicyModel.add(model);
    }

    //Remove selected policy
    public void removePolicy(){
        System.debug('Trying to remove');
            if(listPolicyModel != null && listPolicyModel.size() > 0){
                System.debug('List policy model is: '+listPolicyModel);
                List<PSAPolicyModel> tmpPolicies = new List<PSAPolicyModel>();
                for(PSAPolicyModel model : listPolicyModel){
                    System.debug('First model: '+model);
                    if(!model.isCheck){
                        tmpPolicies.add(model);
                    }   
                    else{
                          toDelete.add(model.policy.id);
                    }
                }                           
                if(tmpPolicies.size() > 0){
                    listPolicyModel = new List<PSAPolicyModel>();
                    listPolicyModel = tmpPolicies;
                }
            }
        }

    // close button...
    public PageReference close(){
        if(contextID == null){
            contextID = '';
        }
        return new PageReference('/' + contextID);
    }

    public void loadFromProject(){
        System.debug('The id being used is: '+projCopy);
        List<PSA_Expense_Policy__c> newPolicies = queryPolicyByContextId(projCopy);
        List<PSA_Expense_Policy__c> correctPolicies = new List<PSA_Expense_Policy__c>();
        if(newPolicies != null && newPolicies.size() > 0){

            for(PSA_Expense_Policy__c nextPolicy : newPolicies){
                PSA_Expense_Policy__c newPolicy = nextPolicy.clone(false, true, false, false);
                if(isProjectRendered){
                    newPolicy.psa_Account__c = null;
                    newPolicy.psa_Project__c = mainProject.id;
                }
                else if(isAccountRendered){
                    newPolicy.psa_Account__c = mainAccount.id;
                    newPolicy.psa_Project__c = null;
                }
                correctPolicies.add(newPolicy);
            }

            expensePolicies.addAll(correctPolicies);
            addPoliciesToList(correctPolicies);
        }

    }

    public void doesAccountPolicyExist(){
        if(relatedAccountId == null || relatedAccountId == ''){
            relatedAccountPolicyExists = false;
            return;
        }
        expensePolicies = queryPolicyByContextId(relatedAccountId);
       
            
        if(expensePolicies == null || expensePolicies.size() == 0){
            relatedAccountPolicyExists = false;
        }
        else{
            relatedAccountPolicyExists = true;
        }
    }

    public void loadFromRelatedAccount(){
        System.debug('The related account is: '+relatedAccountId);
        if(relatedaccountId == null || relatedAccountId == ''){
            return;
        }
        List<PSA_Expense_Policy__c> newPolicies = queryPolicyByContextId(relatedAccountId);
        List<PSA_Expense_Policy__c> correctPolicies = new List<PSA_Expense_Policy__c>();
        if(newPolicies != null && newPolicies.size() > 0){

            for(PSA_Expense_Policy__c nextPolicy : newPolicies){
                PSA_Expense_Policy__c newPolicy = nextPolicy.clone(false, true, false, false);
                if(isProjectRendered){
                    newPolicy.psa_Account__c = null;
                    newPolicy.psa_Project__c = mainProject.id;
                }
                else if(isAccountRendered){
                    newPolicy.psa_Account__c = mainAccount.id;
                    newPolicy.psa_Project__c = null;
                }
                correctPolicies.add(newPolicy);
            }

            expensePolicies.addAll(correctPolicies);
            addPoliciesToList(correctPolicies);
        }
    }

    public class PSAPolicyModel{
        public PSA_Expense_Policy__c policy {get;set;}
        public Id policyId {get;set;}
        public String RateName {get;set;}
        public boolean isCheck {get;set;}

        public PSAPolicyModel(){
            policy = new PSA_Expense_Policy__c();
        }
    }
}