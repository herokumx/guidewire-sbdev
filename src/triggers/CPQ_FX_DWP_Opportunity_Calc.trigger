trigger CPQ_FX_DWP_Opportunity_Calc on Opportunity (before update) {
	CPQ_FX_DWP_Calc_Helper handler = new CPQ_FX_DWP_Calc_Helper(Trigger.isExecuting, Trigger.size);
	
	if(Trigger.isBefore){
		handler.OpportunityUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
	}
	
}