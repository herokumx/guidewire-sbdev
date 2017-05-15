public with sharing class StaffingController {

    public PageReference redirectToRegion() {
    
        PageReference  targetPage = new PageReference('/apex/'+ UserRegionHelper.getCurrentUserDefaultRegion() +'_Staffing');
        targetPage.setRedirect(true);
        return targetPage;
        
    }

}