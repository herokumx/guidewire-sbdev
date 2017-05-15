trigger ResourceRequest on ResourceRequest__c (after insert)
{
    ResourceRequestsHandler chatter = new ResourceRequestsHandler();
    chatter.ResourceRequestGroup(Trigger.newmap.keyset());
}