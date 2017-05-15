/*
Class Name - CS_CaseStatusUpdate 
Description - custom button to update the status for the professional services team 


*/

global with sharing class CS_CaseStatusUpdate {


    //Method which gets invoked from the button. 
    webservice static Boolean updateCase(string caseId){ 
        
        boolean flag;
        
        try{
    
            //Get the case ID from the button and get other information from the below query. 
            Case cse = [Select Status, IsClosed from Case Where id=:caseId];
            
            //If the the case is closed then execute further logic. 
            system.debug('-----'+cse);
            if (!cse.IsClosed){
            
              cse.status = 'Closed by customer';
              update cse;
              flag = true;
            }
        }catch(Exception e){
            flag = false;
        }
        return flag;
    }
}