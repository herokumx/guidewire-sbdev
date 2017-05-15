trigger ProductBeforeInsertBeforeUpdate on Product__c (before insert, before update,after update) {

   ProductHelper objProducthelper = new ProductHelper ();
    
   If(trigger.isinsert)
   {
       objProducthelper.insertProductsPurchased(Trigger.New);         
   } 
   else if(trigger.isupdate && !ProductHelper.IsExcecuted)
   {
       if(Trigger.isBefore)
           objProducthelper.updateProductsPurchased(Trigger.New, Trigger.oldMap);
       else
           ProductHelper.updateVersionRuh(Trigger.newMap, Trigger.oldMap);
   } 
}