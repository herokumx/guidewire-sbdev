/*
*****************************************************************************************************************************
Class Name - CS_ReleaseTriggerHandler
Class Type -  Handler
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                           Initial Creation
Mani       manig@slalom.Com   08/25/2016       Modified for DE434
Mani G     manig@slalom.com  08/26/2016        For Partner Certified Assets , Releases will happen to assets linked to main Releases
*****************************************************************************************************************************
*/
public class CS_ReleaseTriggerHandler   implements CS_ITrigger{

    Private Set<Id> SetPid = New Set<Id>();
    Private Set<Id> SetPVid = New Set<Id>();
    Private Set<Id> Assetid = New Set<Id>();
    Private Map<Id,String>  ReleaseMajormap= New Map<Id,String>();
    
    public CS_ReleaseTriggerHandler() {
        
    }

    public void bulkBefore()
    {
        
        
    }

    public void bulkAfter()
    {

        if (Trigger.isUpdate) {    
            for(SObject att: Trigger.new){
                 
                    CS_Release__c a = (CS_Release__c)att;
                    //CS_Release__c oldRelease =(CS_Release__c)Trigger.oldMap;
                    Map<Id, CS_Release__c> RlsOldMap = (Map<Id, CS_Release__c>)Trigger.oldMap;
                    if(a.CS_IsActive__c==true && RlsOldMap.get(a.id).CS_IsActive__c==False){
                        SetPvid.add(a.id);   
                        SetPid.add(a.CS_Product__c);     
                        ReleaseMajormap.put(a.id,a.CS_Major_Release_version__c);
                    }
                }
        list<Asset> AssetList= New List<Asset>([Select id,Name,CS_product_version__r.CS_Major_Release_version__c,Product2id,Product2.Product__c,Account.Recordtype.name 
                                            from Asset where Product2id in :SetPid 
                                            and Account.Recordtype.name in ('Customer')]);


        List<Asset> PartnerAsset = New List<Asset>([Select id,Name,CS_product_version__r.CS_Major_Release_version__c,Product2id,Product2.Product__c,Account.Recordtype.name 
                                            from Asset where Product2id in :SetPid 
                                            and Account.Recordtype.name ='Partner' and status='Certification' 
                                            and CS_product_version__r.CS_Major_Release_version__c in :(ReleaseMajormap.values() )]);

        if(PartnerAsset!=null && !PartnerAsset.isEmpty()) {AssetList.addall(PartnerAsset);}
        For (Asset lst : AssetList) {
                    Assetid.add(lst.id);
        }
        if (SetPvid.size()>0 &&  AssetList.size() >0){
            CS_Softwaredownload_Util.ProcessDownloads (SetPvid,Assetid);
        }
        }
    }


    public void beforeInsert(SObject so){
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
    }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so){   

    }
    
    public void afterInsert(SObject so){

    }
    
    public void afterUpdate(SObject oldSo, SObject so){
    }
    
    public void afterDelete(SObject so){
    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(){
        }

}