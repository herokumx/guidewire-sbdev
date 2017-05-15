trigger FirstProduct on OpportunityLineItem (before insert,after delete)
{

    FirstProductHandler prodHandler=new FirstProductHandler();
    
    if(Trigger.isInsert)
          prodHandler.updateFirstProduct(Trigger.new);
    
    if(Trigger.isDelete)
          prodHandler.updateFirstProductOnDelete(Trigger.old);
}