/**************************************************************************************
// Name          : psaMigrationScripts
// Date          : May 12, 2015
// Description   : Utility class that includes phases and milestones in migrated projects
// Author        : CLD Partners
// Revisions     : 2015-05-12 Spano initial version
//               : 2015-07-30 Klassen Fixes to avoid duplicate creation and added missing
//               :  fields to Milestone (pse__Closed_For_Time_Entry__c and RecordTypeId).
//               :  Also, added comments throughout the script for clarity
***************************************************************************************/
public with sharing class psaMigrationScripts {

  public static void addMilestonesAndPhases(){

  //Get list of project phases from the template project
    List<pse__Project_Phase__c> phases = 
          [SELECT Id, Name 
              from pse__Project_Phase__c 
              where pse__Project__r.name = 'Implementation - Basic Resources' 
              AND pse__Project__r.pse__Is_Template__c = true
            ];
    //Get list of milestones from the template project
    List<pse__Milestone__c> milestones = 
          [SELECT Id, Name, PSA_Milestone_Type__c, PSA_Utilization_Type__c, pse__Exclude_from_Billing__c, 
                pse__Closed_for_Time_Entry__c, RecordTypeId 
              from pse__Milestone__c 
              where pse__Project__r.name = 'Implementation - Basic Resources' 
              AND pse__Project__r.pse__Is_Template__c = true
            ];
    //Not sure what this is needed for, but left in for potential future use (cklassen 7/30/15)
    List<AggregateResult> projHelp = 
        [Select pse__Project__c 
         from pse__Project_Phase__c 
         where Name = 'Pilot' 
         group by pse__project__c
        ];
    Set<Id> projIds = new Set<Id>();
    for(AggregateResult next : projHelp){
        projIds.add((id)next.get('pse__Project__c'));
    }

    //Create list variables for milestones and project phases to insert at end of script
    List<pse__Milestone__c> toAddMStones = new List<pse__Milestone__c>();
    List<pse__Project_Phase__c> toAddPhases = new List<pse__Project_Phase__c>();
    
    //Get list of projects that need to have milestones and phases added
    // Currently limited to 200, but might be able to do all at one time
    List<pse__Proj__c> recentProjects = 
        [select Name,pse__Is_Active__c,pse__End_Date__c,ID,CreatedDate 
         from pse__Proj__c 
         where (PSA_Empire_Project_ID__c != '' OR PSA_GPS_Project_Id__c != '') 
         AND (Id Not In :projIds) 
         and Id Not In (
              select pse__Project__c 
              from pse__milestone__c 
            where PSA_Milestone_Type__c != 'Billable Expenses - Fixed'
              and PSA_Milestone_Type__c != 'Billable Services - Fixed'
         )        
         limit 200 
        ];
    
  //If a project is not Active, it needs to temporarily be set to Active in order to have
  // Milestones and Phases added to it.  It will be set back to Inactive at end of script
    List<pse__Proj__c> inactive = new List<pse__Proj__c>();
    System.debug('Recent projects: '+recentProjects);
    if(recentProjects != null && recentProjects.size() > 0){

      //Add the project to the list of inactive projects if applicable
      for(pse__Proj__c inact : recentProjects){
        Boolean status = inact.pse__Is_Active__c;
        if(status == false){
          inact.pse__Is_Active__c = true;
          inactive.add(inact);
        }
      }
      //Perform DML update
      if(inactive.size() > 0){
        update inactive;
      }

    //Loop through all projects adding the Milestones and Phases using the native salesforce 
    // Clone functionality.  This requires all fields that need to be copied to be explicitly 
    // included in the original "select" soql statement used to build the list of milestones 
    // and phases
      for(pse__Proj__c next : recentProjects){
        //Add all Phases from the template project
        for(pse__Project_Phase__c nextPhase : phases){
          pse__Project_Phase__c nextAdd = nextPhase.clone(false, true, true, false);
          nextAdd.pse__Project__c = next.Id;
          toAddPhases.add(nextAdd);
        }
    //Add all Milestones from the template project
        for(pse__Milestone__c milestone : milestones){
          pse__Milestone__c nextMile = milestone.clone(false, true, true, false);
          //Set the Target Date to the End Date of the Project if End Date is not blank.
          // Otherwise, set the Target Date to today's date
          if(next.pse__End_Date__c != null){
            nextMile.pse__Target_Date__c = next.pse__End_Date__c;
          }
          else{
            nextMile.pse__Target_Date__c = Date.today();
          }
          nextMile.pse__Project__c = next.Id;
          toAddMStones.add(nextMile);
        }
      }
    }
    System.debug('Adding milestones: '+toAddMStones);
    System.debug('Adding phases: '+toAddPhases);
    //Insert all new milestones
    if(toAddMStones != null && toAddMStones.size() > 0){
      insert toAddMStones;
    }
    //Insert all new Project Phases
    if(toAddPhases != null && toAddPhases.size() > 0){
      insert toAddPhases;
    }

    //If any projects had to temporarily be set to Active, now reset them
    // back to Inactive
    for(pse__Proj__c nextInactive : inactive){
      nextInactive.pse__Is_Active__c = false;
    }
    update inactive;
  }
}