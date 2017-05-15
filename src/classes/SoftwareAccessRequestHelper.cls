//--------------------
// Helper for Software Access Request Form Controller.
// Date: 1/23/2016
// Author: Rohit Koul
//--------------------

public class SoftwareAccessRequestHelper { 

    public static Account_Contact__c getContactDetails(Id acrId){
      List<Account_Contact__c> acrList = [Select Contact__r.Title,Participant_Account__r.MPL_Sales_Rep__c,Participant_Account__r.OwnerId,Participant_Account__r.Services_Account_Manager__c,Contact__r.Email,Contact__r.Name,Contact__r.Phone,Site_Account_Address__c from Account_Contact__c where id =: acrId]; 
            if (acrList.size()>0)
            {
                return acrList[0];
            }else 
            return new Account_Contact__c();
    }
    
    public static Opportunity getOpportunityInfoDetails(Id oppId){
      List<Opportunity> oppList = [Select id,Name,currencyISOcode,Term_Annual_License_Fee__c,Term_Length_Years__c,Premium_In_Scope__c from Opportunity where id =: oppId]; 
            if (oppList.size()>0)
            {
                return oppList[0];
            }else 
            return new Opportunity();
    }
    
	public static List<String> getstandardsBasedTemplates(){
	       List<String> sbtList = new List<String>();
	       Schema.DescribeFieldResult fieldResult = Software_Access_Request__c.Content_items__c.getDescribe();
           List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
           for(Schema.PicklistEntry f : ple)
		   {
			  sbtList.add(f.getValue());
		   }
		   return sbtList; 
	 }
}