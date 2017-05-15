trigger UpdateApprovers on Opportunity (after insert,after update)
{
    UpdateApproversHandler uah = new UpdateApproversHandler();
    
    if(UpdateApproversHandler.flag)
    {   
        
        if(trigger.Isinsert)
            uah.InsertRequesters(trigger.newmap.keyset());
        
        if(trigger.isUpdate)     
           uah.ApproversMethod(trigger.oldmap, trigger.newmap.keyset());   
    
    }

}