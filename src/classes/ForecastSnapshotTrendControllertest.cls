@isTest(seealldata=true)
private class ForecastSnapshotTrendControllertest {

    static testMethod void ForecastSnapshotTrendtesthandler() {
        // Create Input Dates
        List<date> fromDatelist = new List<date>();
        List<date> toDateList = new List<date>();
        // Fetch the minimum snapshot date from object
        ForecastSnapshotTrendController testObj = new ForecastSnapshotTrendController();
         fromDateList.add(testObj.minfromDate);
         fromDateList.add(testObj.minfromDate-2);
         fromDateList.add(testObj.minfromDate+2);
         fromDateList.add(System.today());
         fromDateList.add(System.today()+2);
         toDateList.add(testObj.minfromDate);
         toDateList.add(testObj.minfromDate-2);
         toDateList.add(testObj.minfromDate+4);
         toDateList.add(testObj.minfromDate+8);
         toDateList.add(System.today());
         toDateList.add(System.today()+2);
         Test.startTest();
         PageReference pageRef = Page.ForecastSnapshotTrend;
         Test.setCurrentPage(pageRef);
         for(Date fdate : fromDateList)
         {
         	for(Date tdate:toDateList)
         	{
         		ForecastSnapshotTrendController testObj2 = new ForecastSnapshotTrendController();
         		testObj2.fromDate.Close_Date__c = fdate;
         		testObj2.toDate.Close_Date__c = tdate;
         		testObj2.Submit();
         		//testObj2.generateCSV();
         		//testObj2.processCSV();
         	}
         }
         Test.stopTest();
         
    }
}