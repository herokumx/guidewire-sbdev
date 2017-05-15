@isTest(seeAllData=true)

private class TestGWUserProfileHelper 
{
    static testMethod void testUserProfile() 
    {   
    
        GWUserProfileHelper.isPresalesManager();
        GWUserProfileHelper.isPresales();
        GWUserProfileHelper.isSales();
        GWUserProfileHelper.isSysAdmin();

    }
    

}