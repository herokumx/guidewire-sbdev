trigger RFIRFPApprovalDenial on Opportunity (after update) 
{
    RFIRFPApprovalHandler app = new RFIRFPApprovalHandler();
    if(RFIRFPApprovalHandler.flag)
    {
        app.SCSDRequested(trigger.newmap.keyset(),trigger.oldMap); 
    }       
}