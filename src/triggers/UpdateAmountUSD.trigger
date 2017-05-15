trigger UpdateAmountUSD on Opportunity (before insert, before update)
{
    UpdateAmountUSDHandler handler = new UpdateAmountUSDHandler();
    handler.UpdateAmount(trigger.new);
    //handler.UpdateQuotaARR(Trigger.new,Trigger.oldMap);
}