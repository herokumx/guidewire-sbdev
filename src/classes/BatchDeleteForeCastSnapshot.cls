// Batch class created for Story S-270558
// Descriptiom : Batch class to delete records older than 365 days from current date

global class BatchDeleteForeCastSnapshot implements Database.Batchable<sObject>{
	 global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	date d = system.today().addDays(-365);
    	String month = d.month()<10?'0'+String.valueOf(d.month()):String.valueOf(d.month());
    	String day = d.day()<10?'0'+String.valueOf(d.day()):String.valueOf(d.day());
        String query = 'SELECT Id FROM Forecast_Trending_Snapshot__c where Snapshot_Date__c <='+d.year()+'-'+month+'-'+day;
        System.debug(query);
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Forecast_Trending_Snapshot__c> scope)
    {
		Database.DeleteResult[] DR = Database.delete(scope, false);    
	}   
    global void finish(Database.BatchableContext BC)
    {
    }

}