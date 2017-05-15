/*
*****************************************************************************************************************************
Class Name - CS_Softwaredownload_Util
Class Type - Util
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani                                           Initial Creation
Mani       manig@slalom.Com   08/04/2016       Updated to Asset Grouping Changes 
Mani       manig@slalom.Com   08/25/2016       Modified for DE434
Mani G     manig@slalom.com  08/26/2016        For Partner Certified Assets , Releases will happen to assets linked to main Releases
Mani G     manig@slalom.com  09/28/2016        Commenting the code which populates the Content Version link to SD
*****************************************************************************************************************************
*/
public  class CS_Softwaredownload_Util 
{

    @future
    public  Static Void  ProcessDownloads(Set<Id> SetPVIds,Set<Id> LstAssetids)
    {    
        List<CS_Software_Downloads__c> LstCS= New List<CS_Software_Downloads__c>();
        Set<Id> PrdId= New Set<id>();
        List <CS_Release__c> LstRelease= New List<CS_Release__c>([Select id,CS_Product__c,Name from  CS_Release__c where id in:SetPVIds]);
        for(CS_Release__c csr:LstRelease){PrdId.add(csr.CS_Product__c);}
        //System.debug('LstRelease='+LstRelease);
        //System.debug('PrdId=='+PrdId);
        //List<Asset> LstAsset= New List<Asset>([Select id,Product2id ,Product2.Product__c from asset Where Product2.Product__c in : PrdId 
        List<Asset> LstAsset= New List<Asset>([Select id,Product2id ,Product2.Product__c from asset Where Product2id in : PrdId 
                                                and id in :LstAssetids and   CS_Record_Type_Name__C='Child Asset']);
        System.debug('LstAsset'+LstAsset);
        List<ContentDocumentLink> LstCDL = New  List<ContentDocumentLink>([Select Id, ContentDocument.Title, ContentDocument.FileExtension, 
                                                                            ContentDocument.LatestPublishedVersionId, 
                                                                            ContentDocument.FileType, LinkedEntityId, ContentDocumentId 
                                                                            from ContentDocumentLink where LinkedEntityId 
                                                                            in :SetPVIds]);
        Set<id> SetCD=New Set<id>();
        for(ContentDocumentLink cdl : LstCDL) {
            SetCD.add(cdl.ContentDocumentId);
        }
        system.debug('SetCD==' +SetCD);
        List<ContentDocument> LstCD= [Select Id, Title, FileExtension, LatestPublishedVersionId, FileType from ContentDocument where Id in :SetCD];
        Map<id,Map<Id,ContentDocument>> MMapCD= New Map<id,Map<Id,ContentDocument>>();
        Map<Id,ContentDocument> MapCD= New Map<id,ContentDocument>();
        for (ContentDocument newCD : LstCD) {
            for (ContentDocumentLink newCDL : LstCDL) { 
                    MapCD.Put(newCDL.LinkedEntityId,newCD);
                    MMapCD.put(newCDL.LinkedEntityId,MapCD);
            }
        }
        for (CS_Release__c csr :LstRelease ){
                for (Asset ast:LstAsset){
                        CS_Software_Downloads__c newCS = New CS_Software_Downloads__c ();
                        if(csr.CS_Product__c == ast.Product2id ){
                                newCS.CS_Asset__c=ast.id;
                                //newCS.CS_File_Id__c=(String) MMapCD.get(csr.id).get(csr.id).get('LatestPublishedVersionId');
                                //newCS.CS_File_Type__c=(String) MMapCD.get(csr.id).get(csr.id).get('FileType');
                                newCS.CS_Release__c=csr.id;
                                //newCS.CS_FileExtension__c=(String) MMapCD.get(csr.id).get(csr.id).get('FileExtension');
                                //newCS.Name=(String) MMapCD.get(csr.id).get(csr.id).get('Title');
                                newCS.Name=csr.name;
                                //newCS.CS_Document_Id__c=(String) MMapCD.get(csr.id).get(csr.id).get('Id');
                        }
                        LstCS.add(newCS);  
                }
        }
        if (lstCS != null && !lstCS.isEmpty()) {
            try {
                Insert lstCS;
            } catch (DmlException ex) {
                System.debug('DmlException ' + ex.getMessage());
                CS_ExceptionHandler.createErrorRecordMessage( 'Error Occured While Publishing Release Records to Asset'+ ex.getMessage(),'CS_Softwaredownload_Util.ProcessDownloads ');
            }
        }
        
}
}