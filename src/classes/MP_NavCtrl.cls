/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 * 	This class determines if the current page is the Home Page or Product List Page (UI will highlight the tab selected)
 *  This class also adds the logic for the 'Go to Community' link to redirect to the appropriate Community based
 *  on the user license type.
 */

public with sharing class MP_NavCtrl {
    public String communityUrl{get; set;}
    public String currentUrl{get;set;}
    public Boolean homeSelected {get;set;}
    public Boolean browseSelected {get;set;}
    public String communityLinkName;
    
    public MP_NavCtrl() {
        communityLinkName = '';
        currentUrl = ApexPages.currentPage().getURL();
        if(currentUrl.contains('ccrz__Products')){
            browseSelected = true;
            homeSelected = false;
        }
        else if(currentUrl.contains('ccrz__HomePage')){
            homeSelected = true;
            browseSelected = false;
        }
        Id userId = UserInfo.getUserId();
        User u = [  SELECT Id, Name, Profile.UserLicense.LicenseDefinitionKey
                    FROM User
                    WHERE Id=:userId];

        String userLicense = u.Profile.UserLicense.LicenseDefinitionKey;

        try {
            
            if(userLicense != null){
                if (userLicense == 'PID_Customer_Community' || userLicense == 'PID_Customer_Community_Plus_Login'){
                    communityLinkName = 'Customer';
                } else if (userLicense == 'PID_Partner_Community' || userLicense == 'PID_Partner_Community_Login'){
                    communityLinkName = 'Partner';
                }
                ccrz.ccLog.log('userLicense : ' + userLicense);
            	ccrz.ccLog.log('communityLinkName : ' + communityLinkName);
            }
            
            if (communityLinkName != null) {
                ccrz__E_MenuItem__c menuItem = [SELECT ccrz__URL__c FROM ccrz__E_MenuItem__c WHERE ccrz__DisplayName__c = :communityLinkName LIMIT 1];
                communityUrl = menuItem.ccrz__URL__c;
            }
        } catch (Exception ex){
            ccrz.ccLog.log('Error fetching community link: ' + ex);
        } finally {
            if (communityUrl == null) {
                communityUrl = '';
            }
        }
    }
}