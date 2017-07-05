@isTest
public class CPQ_GenerateBillingSchedulesOnDemandTest {
    
    public static testMethod void testMethod1() {
    
        Account acc = new Account(Name = 'New Account');
        insert acc;
        
        Order orderObj = new Order(Name = 'Test Order',
                                   AccountId = acc.Id,
                                   EffectiveDate = Date.today(),
                                   Status = 'Draft');
        insert orderObj;
        
        CPQ_GenerateBillingSchedulesOnDemand.createBillingSchedules(orderObj.Id);
    }
}