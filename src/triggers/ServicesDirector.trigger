trigger ServicesDirector on Opportunity (after insert, before update)
{
    if(trigger.isinsert)
    {
        //ServiceDirectorHandler.UpdateServiceDirector(trigger.new);
    }
    
    if(trigger.isupdate)
    {
        //ServiceDirectorHandler.UpdateServiceDirector1(trigger.newmap.keyset(), trigger.new, trigger.oldmap);
    }

}