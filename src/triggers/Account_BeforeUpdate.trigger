/**********
Trigger: Account Before Update
Description: if factors in the JT Power Ranking change, send the Account for reranking

Created: Feb 6/13, Vankerk Solutions
Modification Log:
    Apr 11/2013: added Industry into power ranking factors
**********/
trigger Account_BeforeUpdate on Account (before update, before insert, after insert, after update) {

/*******
Added by Rakshik on 08/15
Description: If the account has MLP Sales Rep record then give that user Read Write access to the Account and associated Opportunities
********/
{
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            AccountTgrHandler.onAccountInsert(Trigger.new);
        }
        else if(Trigger.isUpdate)
        {
            AccountTgrHandler.onAccountUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
/*******/
    if (trigger.isupdate) {
        // List of Accounts that need recalculating
        List<Account> Recalc = new List<Account>();
        //AccountOwnerSharingRule rule = new AccountOwnerSharingRule();
        // loop through accounts to see if power ranking factor fields have changed
        for (Account a : trigger.new) {
            // if direct premiums or buying entity have changed or industry changed and was/is Medical Mal Practice
            if (a.direct_premiums__c != trigger.oldmap.get(a.id).direct_premiums__c ||
                a.buying_entity__c != trigger.oldmap.get(a.id).buying_entity__c ||
                (a.industry != trigger.oldmap.get(a.id).industry && (a.industry == 'Medical Mal Practice' || trigger.oldmap.get(a.id).industry == 'Medical Mal Practice')) )
                
                //a.AccessLevel('Edit');
               

                Recalc.add(a);
        }
        // if we have accounts to recalc, do so now
        if (Recalc.size() > 0) GWUtilities.AccountPowerRankingRecalc(Recalc);
    }
    // for new or updated accounts, if prospective partner type is filled in (through lead conversion mapping)
    //    then add option to the alliance type multi select field
    for (Account a : trigger.new) {
        // if partner type is not null
        if (a.prospective_partner_type__c != null) {
            // if alliance type is blank, add this one in
            if (a.alliance_type__c == null) a.alliance_type__c = a.prospective_partner_type__c;
            // else check if option is already contained and add if not
            else if (!a.alliance_type__c.containsignorecase(a.prospective_partner_type__c) )
                a.alliance_type__c += ';' + a.prospective_partner_type__c;
            a.prospective_partner_type__c = null;
        }
    }
    
    if(trigger.isbefore)
    {
        if(trigger.isInsert || trigger.isUpdate)
        {
             AccountTgrHandler.onAccountInsertUpdate(Trigger.new);
             // update standard address fields.
              AccountTgrHandler.validateCustomandUpdateStandardAddressFields(Trigger.new);
        } 
    }
    
 
    
    
    
}