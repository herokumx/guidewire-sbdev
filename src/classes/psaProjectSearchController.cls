public class psaProjectSearchController {
    public list <pse__Proj__c> proj {get;set;}  
    public string searchstring {get;set;}  
    
    public boolean isRateRendered {get;set;}
    public boolean isPolicyRendered {get;set;}
    public String accountId;
    public String currentProject;
    public psaProjectSearchController(ApexPages.StandardController controller) {
   
        accountId = apexpages.currentpage().getparameters().get('accountId');
        
        currentProject = apexpages.currentpage().getparameters().get('projectId');
        String typeOfSearch = apexpages.currentpage().getparameters().get('type');
        if(typeOfSearch == 'rate'){
            isPolicyRendered = false;
            search();
        }
        else if(typeOfSearch == 'policy'){
            isRateRendered = false;
            searchPolicy();
        }

   } 
   
   public void search(){  
   
     List<id> potentialProjects = new List<Id>();
     List<psa_Rate_Set__c> sets = [SELECT Id, psa_project__c from PSA_Rate_Set__c];
     for(PSA_Rate_Set__c next : sets){
         if(currentProject != '' && next.psa_Project__c != currentProject){
             potentialProjects.add(next.psa_Project__c);
         }
     
     }
     string searchquery='select name,id from pse__proj__c where id in :potentialProjects and pse__Account__c = :accountId';  
     proj = Database.query(searchquery);
     if(proj == null || proj.size() == 0){  
         isRateRendered = true;
     }
   }  
   
   public void searchPolicy(){  
   
     List<id> potentialProjects = new List<Id>();
     List<psa_Expense_Policy__c> sets = [SELECT Id, psa_project__c from PSA_Expense_Policy__c];
     for(PSA_Expense_Policy__c next : sets){
         if(currentProject != '' && next.psa_Project__c != currentProject){
             potentialProjects.add(next.psa_Project__c);
         }
     
     }
     string searchquery='select name,id from pse__proj__c where id in :potentialProjects and pse__Account__c = :accountId';  
     proj = Database.query(searchquery);  
     if(proj == null || proj.size() == 0){  
         isPolicyRendered = true;
     }
   }  
   
   public void clear(){  
       if(proj != null){
           proj.clear();
       }  
   }  
}