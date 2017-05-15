/*
******************************************************************************************************************************
Controller Class Name- CS_CaseCreateController
Object - Case
Purpose- Controller  Class Case Creation  Lighnting  Component
*****************************************************************************************************************************

Name     Email              Date         Notes 
Shan Xu  shanx@slalom.com                Initial Creation

*****************************************************************************************************************************
*/
public class CS_CaseCreateController {
 
@AuraEnabled
public static list<Case> getCaselist() {
 
return [Select id, CaseNumber, Subject, Description from Case Order by CreatedDate desc limit 10];
 
}
 
@AuraEnabled
public static void getCaseupdatedlist(Case newCase) {
 
insert newCase;
}
 
}