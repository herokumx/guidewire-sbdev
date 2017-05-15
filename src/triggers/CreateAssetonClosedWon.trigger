trigger CreateAssetonClosedWon on Opportunity (after update) {
   for(Opportunity o: trigger.new){ 
    if(o.isWon == true && o.HasOpportunityLineItem == true){
     String opptyId = o.Id;
     OpportunityLineItem[] OLI = [Select UnitPrice, Quantity, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, Description, Converted_to_Asset__c  
                                  From OpportunityLineItem 
                                  where OpportunityId = :opptyId  and Converted_to_Asset__c = false];
     Asset[] ast = new Asset[]{};
     Asset a = new Asset();
     for(OpportunityLineItem ol: OLI){
      a = new Asset();
      a.AccountId = o.AccountId;
      a.Product2Id = ol.PricebookEntry.Product2Id;
      a.Quantity = ol.Quantity;
      a.Price =  ol.UnitPrice;
      a.PurchaseDate = o.CloseDate;
      a.Status = 'Purchased';
      a.Description = ol.Description;
      a.Name = ol.PricebookEntry.Product2.Name;
      ast.add(a);
      ol.Converted_to_Asset__c = true;
     }
    update OLI; 
    insert ast;
   }
  }
    
    // Set of AccountIds that need their Power Ranking recalculated due to change in Opportunity status
    Set<Id> AccIds = new Set<Id>();
    // cycle through Opportunities to see if was just won or had been won and is no longer
    for (Opportunity o : trigger.new) {
        if ( (o.iswon && !trigger.oldmap.get(o.id).iswon) || (!o.iswon && trigger.oldmap.get(o.id).iswon) )
            AccIds.add(o.accountid);
    }
    // if we have accounts to recalculate, do so now
    if (AccIds.size() > 0 ) GWUtilities.AccountPowerRankingRecalcfromOpportunity(AccIds);
}