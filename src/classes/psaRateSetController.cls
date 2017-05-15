/**************************************************************************************
// Name          : psaRateSetController
// Date          : February 25, 2015
// Description   : Controller class for managing the PSA Rate Card Set and Rate Cards
//                 
// Author        : CLD Partners
// Revisions     : 2015-02-25  Schwartz   Initial version
                    2015-04-01 Spano      Removed Region functionality.
***************************************************************************************/
    public with sharing class psaRateSetController {
        public PSA_Rate_Set__c rateSet {get;set;}
        public List<PSARateModel> listRateModel {get;set;}
        public String rateSetId {get;set;}
        public String projectId {get;set;}
        public String projectAccountId {get;set;}
        public String projectCurrency {get;set;}
        public Boolean isAccountRendered {get;set;}
        public Boolean isProjectRendered {get;set;}
        public String accountId {get;set;}

        private String contextID {get;set;}
        private Set<String> setExistingRates;

        private List<PSA_Rate__c> toDelete;

        public String projCopy {get;set;}
        public ID relatedAccountRateSetId {get;set;}
        
        public boolean relatedAccountRateSetExists {get; set;}

        public psaRateSetController() {
            
            Boolean isRateSetFound = false;
            String currencyCode = 'USD';
            
            projectId = ApexPages.currentPage().getParameters().get('prjid');
            rateSetId = ApexPages.currentPage().getParameters().get('rsid');
            accountId = ApexPages.currentPage().getParameters().get('acctid');

            setExistingRates = new Set<String>();
            toDelete = new List<PSA_Rate__c>();
            listRateModel = new List<PSARateModel>();

            if(rateSetId != null && rateSetId.length() > 0){
                rateSet = queryRateSet(rateSetId);
                if(rateSet != null){
                    isRateSetFound = true;
                }
            }

            isAccountRendered = (accountId != null && (projectId == null || projectId == ''));
            isProjectRendered = (projectId != null && projectId != '' && (accountId == null || accountId == ''));
            if(!isAccountRendered && !isProjectRendered){
                isAccountRendered = 
                isProjectRendered = true;
            }

            if(isRateSetFound){
                // get any rates associated with rate set...
                loadRatesToRateSet(rateSet.id, null);
            }
            else{
                    // Find the rate set (if exists)
                    // based on contextID(acountId or ProjectId)
                    if(isAccountRendered){
                        contextID = accountId;
                        projectAccountId = accountId;
                    } 
                    else if(isProjectRendered){
                        contextID = projectId;
                        List<pse__Proj__c> project = [SELECT CurrencyIsoCode,pse__Account__c from pse__Proj__c where ID = :projectId limit 1];
                        if(project.size() > 0){
                            projectCurrency = project.get(0).currencyIsoCode;
                            projectAccountId = project.get(0).pse__Account__c;
                            currencyCode = projectCurrency;
                        }
                        doesAccountRateExist();
                    }
                    else{
                        // No context given
                        // *** ERROR CONDITION ***
                    }

                    rateSet = queryRateSetByContextId(contextID);
                    if(rateSet != null){
                        isRateSetFound = true;
                    }

                    if(isRateSetFound){
                        loadRatesToRateSet(rateSet.id, currencyCode);
                        if(projectCurrency != null){
                            rateSet.currencyIsoCode = projectCurrency;
                        }
                        else{
                            rateSet.currencyIsoCode = 'USD';
                        }
                    }

            }

            if(listRateModel.size() == 0){
                // Do we want to add empty row to add? If so, do it here...
                //addNewRate();
            }

            if(rateSet == null){
                rateSet = new PSA_Rate_Set__c();
                if(isAccountRendered){
                    contextID = accountId;
                    rateSet.PSA_Account__c = Id.valueOf(accountId);
                }
                else if(isProjectRendered){
                    contextID = projectId;
                    rateSet.PSA_Project__c = Id.valueOf(projectId);
                }
            }
        }

        /**************************************************************************************
        // Name        : save
        // Description : Validate the rates and save the rate set

                    
        //Arguments: 
    ***************************************************************************************/
        public PageReference save(){
            try{
                if(validate()){
                    saveRateSet();
                    return null;
                }
                else{
                    return null;
                }
            }
            catch(Exception except){
                System.debug('*** Exception: ' + except.getMessage());
                return null;
            }
        }

        /**************************************************************************************
        // Name        : saveAndReturn
        // Description : Validate the rates and save the rate set, then return the user to the previous page

                    
        //Arguments: 
    ***************************************************************************************/
        public PageReference saveAndReturn(){
            PageReference pg = Page.psaRateSetEntry;
            pg.setRedirect(true);
            try{
                if(validate()){
                    saveRateSet();
                    return new PageReference('/' + contextID);
                }
                else{
                    return null;
                }
            }
            catch(Exception except){
                System.debug('*** Exception: ' + except.getMessage());
                return null;
            }
        }

        /**************************************************************************************
        // Name        : close
        // Description : Close the page without savings

                    
        //Arguments: 
    ***************************************************************************************/
        public PageReference close(){
            return new PageReference('/' + contextID);
        }

        /**************************************************************************************
        // Name        : addNewRate
        // Description : Add a new rate to the rate set

                    
        //Arguments: 
    ***************************************************************************************/
        public void addNewRate(){
            PSARateModel model;
            if(rateSet != null){
                model = new PSARateModel(rateSet.currencyIsoCode);
            }
            else{
                model = new PSARateModel();
            }
            listRateModel.add(model);
        }

        /**************************************************************************************
        // Name        : refreshValues
        // Description : refresh the rates associated with the rate set

                    
        //Arguments: 
        ***************************************************************************************/
        public void refreshValues(){
            if(rateSet != null){
                // get any rates associated with rate set...
                loadRatesToRateSet(rateSet.id, rateSet.CurrencyIsoCode);
            }

        }

        /**************************************************************************************
        // Name        : loadFromGlobal
        // Description : Loads the rates from the global rate set

                    
        //Arguments: 
    ***************************************************************************************/
        public void loadFromGlobal(){
            List<PSA_Rate_Set__c> rateSets = [SELECT id 
                                FROM PSA_Rate_Set__c
                                WHERE PSA_Is_Global__c = true];

            System.debug('Loading from global: '+rateSets.get(0).id);
            if(rateSets != null && rateSets.size() > 0){
                copyAllRatesToRateSet(rateSets.get(0).id, rateSet.currencyIsoCode);
            }

        }

        /**************************************************************************************
        // Name        : loadFromProject
        // Description : Loads the rates from a related project

                    
        //Arguments: 
    ***************************************************************************************/
        public void loadFromProject(){
            System.debug('The id being used is: '+projCopy);
            contextID = projCopy;

            List<pse__Proj__c> project = [SELECT CurrencyIsoCode from pse__Proj__c where ID = :contextID limit 1];
            if(project.size() > 0){
                System.debug('Found a project');
                projectCurrency = project.get(0).currencyIsoCode;
            }

            boolean isRateSetFound = false;
            PSA_Rate_Set__c existing = queryRateSetByContextId(contextID);
            if(existing != null){
                System.debug('Found a rate set');
                System.debug('Rate set is id: '+existing.id);
                isRateSetFound = true;
            }

            if(isRateSetFound){
                copyAllRatesToRateSet(existing.id, null);
            }
        }
        
        /**************************************************************************************
        // Name        : doesAccountRateExist
        // Description : Determines if a related account rate set exists

                    
        //Arguments: 
    ***************************************************************************************/
        public void doesAccountRateExist(){
            PSA_Rate_set__c existing = queryRateSetByContextId(projectAccountId);
            System.debug('Related account rate set is: '+existing);
            
            if(existing == null){
                relatedAccountRateSetExists = false;
            }
            else{
                relatedAccountRateSetId = existing.Id;
                relatedAccountRateSetExists = true;
            }
        }

        /**************************************************************************************
        // Name        : loadFromAccount
        // Description : Loads the rates from the associated account

                    
        //Arguments: 
    ***************************************************************************************/
        public void loadFromAccount(){
            
            copyAllRatesToRateSet(relatedAccountRateSetId, null);
            
        }

        /**************************************************************************************
        // Name        : removeRate
        // Description : Removes rates except for the last rate

                    
        //Arguments: 
    ***************************************************************************************/
        public void removeRate(){
            if(listRateModel != null && listRateModel.size() > 0){
                List<PSARateModel> tmpRates = new List<PSARateModel>();
                for(PSARateModel model : listRateModel){
                    if(!model.isCheck){
                        tmpRates.add(model);
                    }  
                    else{
                        if(model.RateRecord.id != null){
                            toDelete.add(model.RateRecord);
                        }
                    } 
                }                           
               //if(tmpRates.size() > 0){
                //    listRateModel = new List<PSARateModel>();
                    listRateModel = tmpRates;
               // }
            }
        }

        /**************************************************************************************
        // Name        : copyAllRatesToRateSet
        // Description : Copies the rates from rate_set_id to the current rate set

                    
        //Arguments: String rate_set_id the id of the rate set from which to copy rates
                    String currencCode the currency Code to load the rates with, if null, load all of them
        ***************************************************************************************/
        private void copyAllRatesToRateSet(String rate_set_id, String currencyCode){

            List<PSA_Rate__c> allRates;
            if(currencyCode == null){
                allRates = [SELECT id, Name, CurrencyIsoCode, 
                                                PSA_Average_Cost_Rate__c, PSA_Billing_Level__c,
                                                PSA_Bill_Rate_Amount__c, PSA_End_Date__c,
                                                PSA_Bill_Rate_Set__c, PSA_Start_Date__c, 
                                                LastModifiedDate, LastModifiedById
                                        FROM PSA_Rate__c
                                        WHERE PSA_Bill_Rate_Set__c =: rate_set_id
                                        ORDER BY PSA_Billing_Level__c];
                currencyCode = 'USD';
            }
            else{
                allRates = [SELECT id, Name, CurrencyIsoCode, 
                                                PSA_Average_Cost_Rate__c, PSA_Billing_Level__c,
                                                PSA_Bill_Rate_Amount__c, PSA_End_Date__c,
                                                PSA_Bill_Rate_Set__c, PSA_Start_Date__c, 
                                                LastModifiedDate, LastModifiedById
                                        FROM PSA_Rate__c
                                        WHERE PSA_Bill_Rate_Set__c =: rate_set_id AND CurrencyIsoCode = :currencyCode
                                        ORDER BY PSA_Billing_Level__c];
            }

            listRateModel = new List<PSARateModel>();
            System.debug('All rates is size: '+allRates.size());
            for(PSA_Rate__c rate : allRates){
                PSARateModel rateModel = new PSARateModel();
                PSA_Rate__c nextRate = new PSA_Rate__c(
                    currencyIsoCode = rate.currencyIsoCode,
                    PSA_Average_Cost_Rate__c = rate.PSA_Average_Cost_Rate__c,
                    PSA_Billing_Level__c = rate.PSA_Billing_Level__c,
                    PSA_Bill_Rate_Amount__c = rate.PSA_Bill_Rate_Amount__c,
                    PSA_Start_Date__c = rate.PSA_Start_Date__c,
                    PSA_End_Date__c = rate.PSA_End_Date__c
                );
                rateModel.RateRecord = nextRate;
                listRateModel.add(rateModel);
            }

        }            

        /**************************************************************************************
        // Name        : loadRatesToRateSet
        // Description : Loads rates with currency code currencyCode from the rate set with id rate_set_id to the existing rate set

                    
        //Arguments: String rate_set_id the id of the rate set from which to copy rates
                    String currencCode the currency Code to load the rates with
    ***************************************************************************************/
        private void loadRatesToRateSet(String rate_set_id, String currencyCode){
                if(currencyCode == null){
                    currencyCode = 'USD';
                }
                List<PSA_Rate__c> rates = queryRates(rate_set_id, currencyCode);
                listRateModel = new List<PSARateModel>();
                
                for(PSA_Rate__c rate : rates){
                    setExistingRates.add(rate.id);
                    PSARateModel rateModel = new PSARateModel();
                    rateModel.RateRecord =  rate;
                    listRateModel.add(rateModel);
                }
        }   

        /**************************************************************************************
        // Name        : validate
        // Description : Validates the rates and rate set before allowing the Save to take place

                    
        //Arguments:
    ***************************************************************************************/
        private Boolean validate(){
            // validate rate set...
            Boolean isValid = true;
            String errorMessage = '';
            if(rateSet.Name == null){
                errorMessage += '<li>Name is required</li>';
                isValid = false;
            }
            if(rateSet.CurrencyIsoCode == null){
                errorMessage += '<li>Currency Code is required</li>';
                isValid = false;
            }

            Integer counter = 0;
            if(rateSet.PSA_Account__c != null){counter++;}
            if(rateSet.PSA_Project__c != null){counter++;}
            if(counter > 1){
                // only account or project, but not more than one specified...
                errorMessage += '<li>Only Account or Project may be set</li>';
                isValid = false;
            }
            if(counter == 0 && rateSet.PSA_Is_Global__c == false){
                errorMessage += '<li>If no project or account is assigned, rate set must be global';
                isValid = false;
            }
            if(counter > 0 && rateSet.PSA_Is_Global__c == true){
                errorMessage += '<li>If a project or account is assigned, can not be marked as global';
                isValid = false;
            }
            
            if(isValid){
            // validate rates...
                Map<String, List<PSARateModel>> rateBillLevelMap = new Map<String, List<PSARateModel>>();
                for(PSARateModel model : listRateModel){
                    List<PSARateModel> existing = rateBillLevelMap.get(model.RateRecord.PSA_Billing_Level__c);
                    if(existing == null){
                        existing = new List<PSARateModel>();
                    }
                    existing.add(model);
                    rateBillLevelMap.put(model.RateRecord.PSA_Billing_Level__c, existing);
                }

                for(PSARateModel model : listRateModel){
                    Integer sameCounter = 0;
                    List<PSARateModel> existing = rateBillLevelMap.get(model.RateRecord.PSA_Billing_Level__c);
                    for(PSARateModel sameLevel : existing){
                        if((model.RateRecord.psa_Start_Date__c >= sameLevel.RateRecord.psa_Start_Date__c && model.RateRecord.PSA_Start_Date__c < sameLevel.RateRecord.PSA_End_Date__c)
                            || (model.RateRecord.psa_End_Date__c > sameLevel.RateRecord.psa_Start_Date__c && model.RateRecord.PSA_End_Date__c <= sameLevel.RateRecord.psa_End_Date__c)){
                                if(model.rateRecord.currencyIsoCode == sameLevel.rateRecord.currencyIsoCode){
                                    System.debug('Rate for billing level: '+model.rateRecord.PSA_Billing_Level__c + 'has currency: '+model.rateRecord.currencyIsoCode);
                                    System.debug('Its partner has: '+sameLevel.rateRecord.currencyIsoCode);
                                    sameCounter++;
                                    if(sameCounter > 1){
                                        errorMessage += '<li>Can only have one rate per billing level unless dates do not overlap</li>';
                                        isValid = false;
                                        break;
                                    }
                                }
                        }
                    }
                    if(!isValid){
                        break;
                    }
                }
            }

            // get any matching rate set and rates...
            if(isValid){
                List<PSA_Rate_Set__c> matchingRateset = queryForDupeRateSets(rateSet.id, rateSet.PSA_Account__c, rateSet.PSA_Project__c, rateSet.PSA_Is_Global__c);
                if(matchingRateset.size() > 0 && !rateSet.PSA_Is_Global__c){
                        errorMessage += '<li>A duplicate rate set would be created for this Account or Project. Matching rate set: ' + matchingRateset[0].Name + ' rate set.</li>';
                        isValid = false;                
                }

                // TODO: Also check for overlaping start and end dates...


            }

            if(!isValid){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            }
            return isValid;
        }

        /**************************************************************************************
        // Name        : saveRateSet
        // Description : Commits the rate set to the database

                    
        //Arguments:
    ***************************************************************************************/
        private pageReference saveRateSet(){
            try{
                    upsert rateSet;

                    List<PSA_Rate__c> listRates = new List<PSA_Rate__c>();
                    Set<String> deleteRates = new Set<String>();
                    for(PSARateModel model : listRateModel){
                        if(model.RateRecord.id == null){
                            model.RateRecord.PSA_Bill_Rate_Set__c = rateSet.id;
                        }
                        listRates.add(model.RateRecord);
                        if(model.RateRecord.Id != null && setExistingRates.contains(model.RateRecord.id)){
                            deleteRates.add(model.RateRecord.id);
                        }
                    }
                    
                    // delete rates
                    if(toDelete.size() > 0){
                        List<PSA_Rate__c> ratesToDelete = [SELECT id FROM PSA_Rate__c 
                                                            WHERE PSA_Bill_Rate_Set__c =: rateSet.id 
                                                            AND id in : toDelete];
                        delete ratesToDelete;
                    }

                    // insert/update rates
                    if(listRates.size() > 0){
                        upsert listRates;
                        for(PSA_Rate__c rateRecord : listRates){
                            setExistingRates.add(rateRecord.id);
                        }
                    }

                    rateSet = queryRateSet(rateSet.Id);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Rate Set Saved Successfully'));
                    return new PageReference('/' + contextID);
            }
            catch(Exception except){
                System.debug('*** Exception: ' + except.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, except.getMessage()));
            }
            return null;
        }

        /**************************************************************************************
        // Name        : queryRateSetByContextId
        // Description : Queries for a rate set by the context id. If context id is null, query the global rate set.

                    
        //Arguments:
    ***************************************************************************************/
        private PSA_Rate_Set__c queryRateSetByContextId(string context_id){

            List<PSA_Rate_Set__c> rateSets;
            if(context_id != null){
                rateSets = [SELECT id, Name,
                                        PSA_Account__c,
                                        PSA_Project__c,
                                        PSA_Is_Global__c,
                                        CreatedById, CreatedDate, LastModifiedDate, LastModifiedById
                                FROM PSA_Rate_Set__c
                                WHERE (PSA_Account__c =: context_id
                                      OR PSA_Project__c =: context_id)];
                if(rateSets != null && rateSets.size() > 0){
                    return rateSets[0];
                }
                return null;
            }


           else{
                rateSets = [SELECT id, Name,
                                        PSA_Account__c,
                                        PSA_Project__c,
                                        PSA_Is_Global__c,
                                        CreatedById, CreatedDate, LastModifiedDate, LastModifiedById
                                FROM PSA_Rate_Set__c
                                WHERE (PSA_Account__c = null
                                      AND PSA_Project__c = null)];
                if(rateSets != null && rateSets.size() > 0){
                    return rateSets[0];
                }
                return null;                                
            }
        }


        /**************************************************************************************
        // Name        : queryRateSet
        // Description : Query for a rate set with the given ID

                    
        //Arguments: string rate_set_id the rate set id of the rate set being queried
    ***************************************************************************************/
        private PSA_Rate_Set__c queryRateSet(string rate_set_id){
            List<PSA_Rate_Set__c> rateSets = [SELECT id, Name, CurrencyIsoCode,
                                        PSA_Account__c, 
                                        PSA_Project__c,
                                        PSA_Is_Global__c,
                                        CreatedById, CreatedDate, LastModifiedDate, LastModifiedById
                                FROM PSA_Rate_Set__c
                                WHERE id =: rate_set_id];
            if(rateSets != null && rateSets.size() > 0){
                return rateSets[0];
            }
            return null;                                
        }

        /**************************************************************************************
        // Name        : queryRates
        // Description : queries for rates with the given rate set id and currency code

                    
        //Arguments: rate_set_id the id of the rate set that rates must have
                    currencyCode the currency 
    ***************************************************************************************/
        private List<PSA_Rate__c> queryRates(string rate_set_id, String currencyCode){
            List<PSA_Rate__c> rates = [SELECT id, Name, CurrencyIsoCode, 
                                                PSA_Average_Cost_Rate__c, PSA_Billing_Level__c,
                                                PSA_Bill_Rate_Amount__c, PSA_End_Date__c,
                                                PSA_Bill_Rate_Set__c, PSA_Start_Date__c, 
                                                LastModifiedDate, LastModifiedById
                                        FROM PSA_Rate__c
                                        WHERE PSA_Bill_Rate_Set__c =: rate_set_id AND CurrencyIsoCode = :currencyCode
                                        ORDER BY PSA_Billing_Level__c, PSA_Start_Date__c DESC];
            if(rates != null && rates.size() > 0){
                return rates;
            }
            return new List<PSA_Rate__c>();
        }

        /**************************************************************************************
        // Name        : queryForDupeRateSets
        // Description : Determines if there is a rate set identical to the one being inserted

                    
        //Arguments:
    ***************************************************************************************/
        private List<PSA_Rate_Set__c> queryForDupeRateSets(String rate_set_id, String acct_id, String proj_id, boolean isGlobal){
            List<String> rateIds = new List<String>();
            rateIds.add(rate_set_id);
            List<PSA_Rate_Set__c> rateSets;

            if(!isGlobal){
                rateSets = [SELECT id, Name, CurrencyIsoCode,
                                        PSA_Account__c,
                                        PSA_Project__c,
                                        CreatedById, CreatedDate, LastModifiedDate, LastModifiedById
                                FROM PSA_Rate_Set__c
                                WHERE id NOT IN: rateIds
                                AND PSA_Account__c =: acct_id
                                AND PSA_Project__c =: proj_id];
            }
            else{
                rateSets = [SELECT id, Name, CurrencyIsoCode from PSA_Rate_Set__c where PSA_Is_Global__c = true];
            }
            return rateSets;                            
        }

//      private List<PSA_Rate__c> queryForOverlappingDates(String acct_id, String proj_id, Date start_date, Date end_date){
//          // Find any rates within start and end date
//      }


    // wrapper class for PSA Rates
    public class PSARateModel{
        public PSA_Rate__c RateRecord {get;set;}
        public Id RateSetId {get;set;}
        public String CurrencyIsoCode {get;set;}
        public String RateName {get;set;}
        public Decimal AverageCostRate {get;set;}
        public String BillLevel {get;set;}
        public Decimal BillRate {get;set;}
        public Date StartDate {get;set;}
        public Date EndDate {get;set;}
        public Boolean isCheck {get;set;}

        public PSARateModel(){
            RateRecord = new PSA_Rate__c();
            AverageCostRate = 0;
            BillRate = 0;
        }

        public PSARateModel(String currencyCode){
            RateRecord = new PSA_Rate__c();
            AverageCostRate = 0;
            BillRate = 0;
            if(currencyCode != null){
                CurrencyIsoCode = currencyCode;
                RateRecord.CurrencyIsoCode = currencyCode;
            }

        }
    }
}