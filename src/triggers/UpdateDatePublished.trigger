trigger UpdateDatePublished on ContentVersion (before Insert, before Update)
{
    UpdateDatePublishedHandler dpH = new UpdateDatePublishedHandler();
    
    if(trigger.isInsert)
         dpH.documentHandler(trigger.new);
    
    if(trigger.isUpdate)
        dpH.versionHandler(trigger.new, trigger.oldmap);       

}