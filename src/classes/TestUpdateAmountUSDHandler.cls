@isTest
private class TestUpdateAmountUSDHandler 
{
    static testmethod void TestAmount()
    {
        opportunity opp = new opportunity();
        opp.StageName='Closed-Won';
        opp.CloseDate=system.today();
        opp.CurrencyIsoCode ='USD';
        opp.Name='Test Opportinity1'; 
        opp.amount=5000;
        
        insert opp;        
        
     }
}