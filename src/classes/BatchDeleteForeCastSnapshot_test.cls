// Batch class test created for Story S-270558
@isTest
private class BatchDeleteForeCastSnapshot_test {

    static testMethod void BatchDeleteTest() {
        //Create some test records for ForecastSnapshot
        List<Forecast_Trending_Snapshot__c> testObjlist = new List<Forecast_Trending_Snapshot__c>();
        for(integer i = 0; i< 10; i++)
        {
        	Forecast_Trending_Snapshot__c testObj = new Forecast_Trending_Snapshot__c();
        	testObj.Snapshot_Date__c = System.today().addDays(-400);
        	testObjlist.add(testObj);
        }
        date d = system.today().addDays(-365);
    	
        insert testObjlist;
        // Test the batch Class
        
        Test.startTest();
        BatchDeleteForeCastSnapshot testBatch = new BatchDeleteForeCastSnapshot();
        Database.executeBatch(testBatch);	
        Test.stopTest();
        Integer i = [select count() from Forecast_Trending_Snapshot__c where Snapshot_Date__c <=:d];
       System.assertEquals(i, 0);
    }
}