public with sharing class AccountTgrHandler
{
    static List<AccountShare> lstAccountShare = new List<AccountShare>();
    static List<pw_cc__State__c>  stateList = [Select Id,Name from pw_cc__State__c];
    static List<pw_cc__CountryObject__c>  countryList = [Select Id,Name from pw_cc__CountryObject__c];
    
    public static void onAccountInsert(List<Account> lstAccount)
    {
        for(Account account :lstAccount)
        {
            if(String.isNotBlank(account.MPL_Sales_Rep__c))
            {
                AccountShare accountShare = getAccountShare(account);
                lstAccountShare.add(accountShare);
            }
        }
        
        if(!lstAccountShare.isEmpty())
        {
            Database.SaveResult[] lstSaveResult = Database.insert(lstAccountShare, false);
        }
    }
    
    public static void onAccountUpdate(List<Account> lstNewAccount, Map<Id,Account> mapOldAccount)
    {
        Set<Id> setUserId = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        
        for(Account account :lstNewAccount)
        {
            if(String.isNotBlank(account.MPL_Sales_Rep__c) && (account.MPL_Sales_Rep__c != mapOldAccount.get(account.Id).MPL_Sales_Rep__c))
            {
                setUserId.add(mapOldAccount.get(account.Id).MPL_Sales_Rep__c);
                setAccountId.add(account.Id);
                AccountShare accountShare = getAccountShare(account);
                lstAccountShare.add(accountShare);
            }
        }
        
        
        
        if(setUserId.size() > 0 && setAccountId.size() > 0)
        {
            List<AccountShare> lstAccountShareToDel = [Select Id from AccountShare 
                                                    where UserOrGroupId IN :setUserId AND 
                                                    AccountId IN :setAccountId AND 
                                                    AccountAccessLevel = 'Edit' 
                                                    AND OpportunityAccessLevel = 'Edit'];
                                                    
            if(!lstAccountShareToDel.isEmpty())
            {
                Database.DeleteResult[] lstDelSaveResult = Database.delete(lstAccountShareToDel, false);
            }
        }
        
        if(!lstAccountShare.isEmpty())
        {
            Database.SaveResult[] lstSaveResult = Database.insert(lstAccountShare, false);
        }
    }
    
    public static AccountShare getAccountShare(Account account)
    {
        AccountShare accountShare = new AccountShare();
        accountShare.UserOrGroupId = account.MPL_Sales_Rep__c;
        accountShare.AccountAccessLevel = 'Edit';
        accountShare.OpportunityAccessLevel = 'Edit';
        accountShare.AccountId = account.Id;
        return accountShare;
    }
    
    public static void onAccountInsertUpdate(List<Account> Accountlst)
    {
       set<string> countrylst = new set<string>();
        
        for(account acc: Accountlst)
          {
             countrylst.add(acc.BillingCountry);
    	  }
    
    	list<Region__c> regionlst = [select id,country__c,Sub_region__c from Region__c where country__c =: countrylst];
    
    	map<string,string> regionmap = new map<string,string>();
    
    	for(Region__c reg: regionlst)
    	  {
      		  regionmap.put(reg.country__c.toLowercase(), reg.sub_region__c);
    	  }
    
   		 for(account acc: Accountlst)
   		 {
             if(acc.billingCountry!=NULL)
             {
             string s=acc.BillingCountry.toLowercase();
      		 if(regionmap.containsKey(s))
         		 acc.Sub_Region__c = regionmap.get(s);
             else
                 acc.Sub_Region__c = ' ';
             }
             else
                 acc.Sub_Region__c =' ';
    	 } 
        
              
    }
    
    // Update Standard Address fields using the custom Address fields
    
    public static void validateCustomandUpdateStandardAddressFields(List<Account> accountList){
        Id recordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site').RecordTypeId;	
	    Map<Id,pw_cc__State__c> stateMap = new Map<Id,pw_cc__State__c>();
	    Map<Id,pw_cc__countryOBject__c> countryMap = new Map<Id,pw_cc__countryObject__c>();
	       if(stateList.size()>0){
	       	for(pw_cc__State__c st : stateList){
	        	stateMap.put(st.Id,st);
	       	}
	       }
	       
	       if(countryList.size()>0){
	         for(pw_cc__countryOBject__c ct : countryList){
	        	countryMap.put(ct.Id,ct);
	       	}
	       
	   }
	  
	   for(Account acc : accountList){
	       // validate address.
	       if((acc.Requested_Approval__c != null && acc.Requested_Approval__c != '') || (acc.RecordTypeID == recordTypeId)){
	         if(acc.Billing_Street__c == null || acc.Billing_Street__c == ''){
	            acc.Billing_Street__c.addError('Billing Street is required');
	         } 
	        /* if(acc.pw_cc__BillingStateLookup__c == null){
	            acc.pw_cc__BillingStateLookup__c.addError('Billing State is required');
	         }*/
	         if(acc.pw_cc__BillingCountryLookup__c == null){
	            acc.pw_cc__BillingCountryLookup__c.addError('Billing Country is required');
	         }
	         if((acc.Billing_Zip_Postal_Code__c == null || acc.Billing_Zip_Postal_Code__c == '') && countryMap.get(acc.pw_cc__BillingCountryLookup__c) != null &&  countryMap.get(acc.pw_cc__BillingCountryLookup__c).Name != 'Hong Kong' ){
	            acc.Billing_Zip_Postal_Code__c.addError('Billing Zip/Postal Code is required');
	         }
	         if(acc.Billing_City__c == null || acc.Billing_City__c == ''){
	            acc.Billing_City__c.addError('Billing City is required');
	         }
	       }
	       
	       // validate invoice delivery and payement terms.
	       
	        if((acc.Requested_Approval__c != null && acc.Requested_Approval__c != '')){
	         if(acc.Invoice_Delivery_Method__c == null || acc.Invoice_Delivery_Method__c == ''){
	            acc.Invoice_Delivery_Method__c.addError('Invoice Delivery Method is required');
	         }
	         if(acc.Payment_Term__c == null || acc.Payment_Term__c == ''){
	            acc.Payment_Term__c.addError('Payment Term is required');
	         }
	       }
	       
	       
	       // Assign Address values.
	       // if(acc.Billing_Street__c != null && acc.Billing_Street__c != ''){
	            acc.BillingStreet =  acc.Billing_Street__c; 
	        // }
	         if(acc.pw_cc__BillingStateLookup__c != null && stateMap != null && stateMap.get(acc.pw_cc__BillingStateLookup__c) != null){
	            acc.BillingState =stateMap.get(acc.pw_cc__BillingStateLookup__c).Name;
	         }else{
	            acc.BillingState = '';
	         }
	         if(acc.pw_cc__BillingCountryLookup__c != null && countryMap != null && countryMap.get(acc.pw_cc__BillingCountryLookup__c) !=null){
	             acc.BillingCountry =countryMap.get(acc.pw_cc__BillingCountryLookup__c).Name;
	         }else{
	             acc.BillingCountry = '';
	         }
	       //  if(acc.Billing_Zip_Postal_Code__c != null && acc.Billing_Zip_Postal_Code__c != ''){
	            acc.BillingPostalCode =acc.Billing_Zip_Postal_Code__c;
	        // }
	        // if(acc.Billing_City__c != null && acc.Billing_City__c != ''){
	           acc.BillingCity =acc.Billing_City__c; 
	        // }
       }
    }
    
    
}