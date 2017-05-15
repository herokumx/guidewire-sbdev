@istest
public class TriggerTests{
    public static testmethod void testAttachments(){
        // create Account/Opportunity
        Account a = new Account(name = 'test');
        insert a;
        Opportunity o = new Opportunity(closedate = date.today().adddays(15), stagename = 'Prospecting', accountid = a.id, name = 'test',
            Deal_type__c = 'sample', payment_cycle__c = 'annual', amount = 1);
        insert o;
        // add attachment to Opp without ProspectPlan in the name
        Attachment a1 = new Attachment(name = 'some file.txt', body = blob.valueof('Test document body'), parentid = o.id);
        insert a1;
        // check the datetime stamp not populated
        o = [select id, prospect_plan_update_time__c from Opportunity where id = :o.id];
        system.assertequals(null, o.prospect_plan_update_time__c);
        // add file with prospectplan in name
        Attachment a2 = new Attachment(name = 'some file prospectPlan.txt', body = blob.valueof('Test document body'), parentid = o.id);
        insert a2;
        // check the datetime stamp not populated
        o = [select id, prospect_plan_update_time__c from Opportunity where id = :o.id];
        system.assertnotequals(null, o.prospect_plan_update_time__c);
    }
    
    public static testmethod void testAccountPartnerType(){
        // create account with blank alliance and prospective partner type
        Account a = new Account(name = 'test', prospective_partner_Type__c = 'First Option');
        insert a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assertequals(a.alliance_type__c , 'First Option');
        // add new option in prospective
        a.prospective_partner_Type__c = 'Second Option';
        update a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assert(a.alliance_type__c.contains('Second Option') && a.alliance_type__c.contains('First Option'));
        // add second option again
        a.prospective_partner_Type__c = 'Second Option';
        update a;
        a = [select id, prospective_partner_Type__c , alliance_type__c from Account where id = :a.id];
        system.assertequals(a.prospective_partner_Type__c, null);
        system.assertequals(a.alliance_type__c.countmatches('Second Option'), 1);                
    } 
}