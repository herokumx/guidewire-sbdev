@isTest(seeAllData=true)
private class TestUserRegionHelper {

    static testMethod void testHelper() {
    
        UserRegionHelper.getCurrentUserDefaultRegion();
        
        UserRegionHelper.getDefaultRegionForRole('APAC');
        UserRegionHelper.getDefaultRegionForRole('EMEA');
        

    }
}