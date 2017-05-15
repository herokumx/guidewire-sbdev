/*
*****************************************************************************************************************************
Class Name - CS_CraController
Class Type -  Controller
Test Class-
Purpose- CRA Lightning Component Controller


*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                            Initial Creation

*****************************************************************************************************************************
*/
public with sharing class CS_CraController {

@AuraEnabled
  public static String getAccountUrl() {
  	string URL;
    List<User> usr=[select  contact.accountid from user where  isactive=true and username=:userinfo.getUserName()];
    List<CS_Resource_Area__c> resourceAreaList=[select Id from CS_Resource_Area__c where  CS_Account__c=:usr[0].contact.accountid];
    if(resourceAreaList != null && resourceAreaList.size() > 0){
    	Url='/relatedlist/' + resourceAreaList[0].Id + '/AttachedContentDocuments';
    }
    else {
    	URL='';
    }   
    return Url;
  }
}