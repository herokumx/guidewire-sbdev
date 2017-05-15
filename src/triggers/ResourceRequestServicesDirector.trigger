trigger ResourceRequestServicesDirector on ResourceRequest__c (after insert) 
{
    ResourceRequestServicesDirectorHandler requestHandler = new ResourceRequestServicesDirectorHandler();
     List<ResourceRequest__c> reqLst = [select id,name,Opportunity__c,opportunity__r.name,opportunity__r.stageName,Status__c,Event_Type__c, 
                                        Presentation_Type__c,Event_Goals__c,Location__c, RFx_External_Due__c,RFx_Internal_Due__c,RFx_Received__c
                                       from ResourceRequest__c where Id =:Trigger.newMap.keyset()];
    requestHandler.UpdateResourceRequest(reqLst);
                                                                                                      

}