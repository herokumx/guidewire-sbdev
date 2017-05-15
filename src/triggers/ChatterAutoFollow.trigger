trigger ChatterAutoFollow on Opportunity (after insert, after update)
{
   if(trigger.isInsert || trigger.isUpdate) {}
          //ChatterAutoFollowHandler.AutoFollow(trigger.new, trigger.newmap.keyset());
    
}