@isTest(seeAllData=false)
private class TestProjectListController {

    static testMethod void validateController() {
   

       Project__c newProject = new Project__c(Name='New Project',Status__c = 'Active',Description__c='Description');
       insert newProject;


       ProjectListController controller = new ProjectListController();
       
       System.assertEquals(controller.theProjects.size(), 1);
       
       controller.status = 'Inactive';
       controller.reloadPage();
       System.assertEquals(controller.theProjects.size(), 0);

       controller.status = 'All';
       controller.reloadPage();
       System.assertEquals(controller.theProjects.size(), 1);
       
       ProjectListController.deleteProject(newProject.Id);
       controller.reloadPage();
       System.assertEquals(controller.theProjects.size(), 0);
       
   
   }
   
}