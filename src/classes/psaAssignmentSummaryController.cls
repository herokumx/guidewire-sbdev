/****************************************************************************************
Name             : psaAssignmentStaffingSummaryController
Revision History : CLD 1/23/2015
Use              : Controller class for PsaAssignmentSummary page.
****************************************************************************************/
public class psaAssignmentSummaryController { 
    public pse__Proj__c projectRecord {get;set;}
    private pse__Proj__c pseProj;
    public Integer barMax {get;set;}

    
    //declare some variables for sorting
    public string sortOnField {get; set;}
    public String sortField { get; set; }
    public String sortDirection {get; set;}
    public List<pse__Assignment__c> AssignmentSummaryList { 
        get {
            return getAssignmentSummary(); 
        }  
        set;
    }
    
    public PsaAssignmentSummaryController(ApexPages.StandardController sc){
        
        barMax = 100;
        sortDirection = 'ASC';
        sortField = 'pse__Resource__r.Name';
        sortOnField ='';
        try{
            pseProj = (pse__Proj__c)sc.getRecord();
            pseProj = [
                SELECT Id, 
                       Name,
                       pse__Account__c,
                       pse__Account__r.Name
                  FROM pse__Proj__c where id=:pseProj.id
                ];
            System.debug('pseProj:::'+pseProj);

        }catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
    public pse__Proj__c getProjectDetails(){
        list<pse__Proj__c> psaProjList = new list<pse__Proj__c>();
        pse__Proj__c projObj = new pse__Proj__c ();
      psaProjList = [
        SELECT Name 

          FROM pse__Proj__c
         WHERE id = :pseProj.Id limit 1
      ];
      if(psaProjList.size() ==1 ){
        projObj = psaProjList[0];
      }
      return projObj;
    }
    
    public List<pse__Assignment__c> getAssignmentSummary(){

      //set soql query as string
      //String query =   'SELECT Name,  pse__Resource__c, pse__Resource__r.Name, pse__Start_Date__c, pse__End_Date__c, pse__scheduled_hours__c, Actual_Hours__c, To_Go_Hours__c, pse__Status__c FROM pse__Assignment__c WHERE pse__Project__c = \''+pseProj.Id+'\' AND pse__Status__c IN (\'Scheduled\',\'Tentative\',\'Closed\') ';
      String query =   'SELECT Name,  pse__Resource__c, pse__Resource__r.Name, pse__Start_Date__c, pse__End_Date__c, PSA_Percent_Complete_Plan__c, pse__scheduled_hours__c, PSA_Actual_Hours__c, To_Go_Hours__c, pse__planned_hours__c, pse__Status__c FROM pse__Assignment__c WHERE pse__Project__c = \''+pseProj.Id+'\'';
      
      
      //first time sortOnField is empty so set query order by  pse__Resource__r.Name
      //and set  sortOnField and sort direction
      if(sortOnField == '') {
          query +=  ' ORDER BY pse__Resource__r.Name';
          sortOnField = 'ORDER BY pse__Resource__r.Name';
          sortDirection = 'ASC';
      } else {
          query += sortOnField;
      }    
      
      query += ' limit 1000';
      
      return Database.query(query);
  }
      
    //method for applying sorting
   public void doSort() {
   
          //if sortonfield string ends with Desc then set sorting accending order 
        if(sortOnField.endswith(sortField + ' DESC')) {
            sortOnField = ' ORDER BY ' + sortField ;
            sortDirection = 'ASC';
            //if sortOnField is acccending then set it to descending
        } else if(sortOnField.endswith(sortField)) {
            sortOnField = ' ORDER BY ' + sortField +' DESC';
            sortDirection = 'DESC';
        } else {
            //set sorting according to increasing order
            sortOnField = ' ORDER BY ' + sortField ;
            sortDirection = 'ASC';  
        }            
    }
    
    /*public List<pse__Resource_Request__c> getResourceRequestSummary(){
      return [
        SELECT Name, 
               pse__Status__c, 
               pse__Resource_Role__c, 
               pse__Start_Date__c, 
               pse__End_Date__c, 
               pse__SOW_Hours__c, 
               pse__Percent_Allocated__c
          FROM pse__Resource_Request__c
         WHERE pse__Project__c=:pseProj.Id 
           AND pse__Status__c NOT IN ('Assigned','Cancelled')
           ORDER BY pse__Status__c,pse__Start_Date__c limit 1000
      ];
    }*/

    public decimal getSchedToGoHrs(){
      decimal totSchedToGoHrs = 0;
      list<pse__Assignment__c> assignmentList = [
        SELECT pse__project__c, To_Go_Hours__c //SchedToGoHrs__c
          FROM pse__Assignment__c
         WHERE pse__Project__c = :pseProj.Id
           AND pse__Status__c IN ('Allocated','Staffed')
      ];
      for(pse__Assignment__c asgnmt : assignmentList){
        if(asgnmt.To_Go_Hours__c != null)
          totSchedToGoHrs = totSchedToGoHrs + asgnmt.To_Go_Hours__c;
      }
      return totSchedToGoHrs;
    }

    /*public Decimal getbarValue(){
      Integer barValuei = 0;
      Decimal barValue = 0;
      list<pse__Assignment__c> assignmentList = [
        SELECT pse__project__c, pse__scheduled_hours__c, Actual_Hours__c, pse__planned_hours__c
          FROM pse__Assignment__c
         WHERE pse__Project__c = :pseProj.Id
           AND pse__Status__c IN ('Allocated','Staffed')
      ];
      for(pse__Assignment__c a : assignmentList){
        if(a.pse__Planned_Hours__c != 0 && a.Actual_Hours__c <= a.pse__Planned_Hours__c){
          barValue = (a.Actual_Hours__c / a.pse__Planned_Hours__c) * 100;
        }
        if(a.pse__Planned_Hours__c == null || a.pse__Planned_Hours__c == 0){
          barValue = 0;
        }
        if(a.pse__Planned_Hours__c != 0 && a.Actual_Hours__c > a.pse__Planned_Hours__c){
         barValue = 100; 
        }
        barValuei = Integer.valueof(barValue);
      }
      return barValuei;
    }*/

}