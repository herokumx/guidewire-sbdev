@isTest
public with sharing class TestUpdateDatePublishedContentVersion {

@isTest
private static void testContentInsertandUpdate(){
  // verify all the usage terms are alligned with T
  List<ContentVersion> conVerList = [select Id,usage_terms__c,Data_Classification__c from contentVersion where ID in: setupContentVer()];
  for(ContentVersion conVersion: conVerList){
  	 if(conVersion.Data_Classification__c == 'Public'){
  	 	 system.assertequals(conVersion.usage_terms__c , 'This asset contains information that can be publicly distributed through authorized company channels.');
  	 }else if(conVersion.Data_Classification__c == 'Customer Restricted'){
  	 	 system.assertequals(conVersion.usage_terms__c , 'This asset contains Guidewire Customer proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.');
  	 }else if(conVersion.Data_Classification__c == 'Guidewire Internal'){
  	 	 system.assertequals(conVersion.usage_terms__c , 'This asset contains Guidewire proprietary and confidential information. It is intended for Guidewire Internal use on a need-to-know basis only.');
  	 }
  } 
}

public static List<Id> setupContentVer(){
 
 GW_Common_Settings__c gwSettings = new GW_Common_Settings__c(name= 'EnableContentVersionTrigger', Boolean_Value__c = true);
 insert gwSettings; 
 Id recordTypeId = Schema.SObjectType.ContentVersion.RecordTypeInfosByName.get('Sales Portal').RecordTypeId;
 List<ContentVersion> conVersionList = new List<ContentVersion>();
 
 ContentVersion testContentInsert1 = new ContentVersion(ContentURL='http://www.guidewire1.com/',Title ='GwtestTitle1.com',RecordTypeId = recordTypeId,Data_Classification__c ='Customer Restricted');
 conVersionList.add(testContentInsert1);
 ContentVersion testContentInsert2 = new ContentVersion(ContentURL='http://www.guidewire2.com/',Title ='GwtestTitle2.com',RecordTypeId = recordTypeId,Data_Classification__c = 'Guidewire Internal');
 conVersionList.add(testContentInsert2);
 ContentVersion testContentInsert3 = new ContentVersion(ContentURL='http://www.guidewire3.com/',Title ='GwtestTitle3.com',RecordTypeId = recordTypeId,Data_Classification__c = 'Public');
 conVersionList.add(testContentInsert3);
 ContentVersion testContentInsert4 = new ContentVersion(ContentURL='http://www.guidewire4.com/',Title ='GwtestTitle4.com',RecordTypeId = recordTypeId,Data_Classification__c ='Customer Restricted1');
 conVersionList.add(testContentInsert4);
 ContentVersion testContentInsert5 = new ContentVersion(ContentURL='http://www.guidewire5.com/',Title ='GwtestTitle5.com',RecordTypeId = recordTypeId,Data_Classification__c = 'Guidewire Internal1');
 conVersionList.add(testContentInsert5);
 ContentVersion testContentInsert6 = new ContentVersion(ContentURL='http://www.guidewire6.com/',Title ='GwtestTitle6.com',RecordTypeId = recordTypeId,Data_Classification__c = 'Public1');
 conVersionList.add(testContentInsert6);
 
 insert conVersionList;
 
 for(ContentVersion conVer : conVersionList){
   if(conVer.Data_Classification__c != null){
     if(conVer.Data_Classification__c == 'Customer Restricted1'){
        conVer.Data_Classification__c = 'Customer Restricted'; 
     }
     if(conVer.Data_Classification__c == 'Guidewire Internal1'){
        conVer.Data_Classification__c = 'Guidewire Internal'; 
     }
     if(conVer.Data_Classification__c == 'Public1'){
        conVer.Data_Classification__c = 'Public'; 
     }
    } 
 }
 update conVersionList;
 List<Id> idlist = new List<Id>();
 for(ContentVersion conVer : conVersionList){
	 idlist.add(conVer.Id);
 }
 return idlist;
}


}