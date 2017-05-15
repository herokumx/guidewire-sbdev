trigger prmopportunityshare on Opportunity (after insert, after update) {

    prmpartnerOpportunitysharing psharing = new prmpartneropportunitysharing();
    
    if(trigger.isinsert || trigger.isupdate)
    {
        psharing.partneropportunitysharing(Trigger.new);
    }
}