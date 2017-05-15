/**************
Trigger: Attachment After Insert
Description: runs after an attachment is added to a record; looks for files attached to an Opportunity record that has ProspectPlan in the file name
    For any of these, updates the Opportunity with the current date/time for tracking.
    
Created: June 1,2012, Vankerk Solutions
Modification Log:

**************/
trigger Attachment_AfterInsert on Attachment (after insert) {
    try {
        List<Opportunity> OppUpd = new List<Opportunity>();
        // cycle through new attachments, looking for Opportunity linked with 'ProspectPlan' in the title
        // query for the parent.type field to identify the polymorphic field's look up table
        for (Attachment a : [select id, name, parentid, parent.type from Attachment where id in :trigger.new]) {
            if (a.parent.type == 'Opportunity' && a.name.touppercase().contains('PROSPECTPLAN'))
                OppUpd.add(new Opportunity(id = a.parentid, Prospect_Plan_Update_Time__c = datetime.now()));
        }
        // if Opportunities to update, do so now
        if (OppUpd.size() > 0) update OppUpd;
    } catch (Exception e) {
        trigger.new[0].adderror('There was a problem processing the new Attachment: '+e.getstacktracestring()+': '+e);
    }
}