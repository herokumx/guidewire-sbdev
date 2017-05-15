public with sharing class ProjectListController {

   public String status { get; set; }
   public List<Project__c> theProjects {get;set;}
   
   
    public ProjectListController()
    {
            status = 'Active';
            reloadPage();   
    }
       

  public Boolean getIsPresalesManager() {
      return GWUserProfileHelper.isPresalesManager();
  }

    public void reloadPage()
    {
        if(status == 'All')
        {
            theProjects= [SELECT Name, Status__c, Description__c, Category__c, Total_Participant_Hours__c, Total_Prep_Hours__c from Project__c
                                           ORDER By Category__c ];
        }
        else
        {
            theProjects= [SELECT Name, Status__c, Description__c, Category__c, Total_Participant_Hours__c, Total_Prep_Hours__c from Project__c 
                                           WHERE Status__c = :status
                                           ORDER By Category__c ];
        
        }

    }

    @RemoteAction
    public static String deleteProject(String projectID)
    {
  
        Project__c toDelete = [SELECT Id FROM Project__c where Id = :projectID];
        if(toDelete != null)
        {
            delete toDelete;  
        }
        return 'Success';
    }

}