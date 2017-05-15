public class CPQ_OppProduct_Owner_Calc_Helper
{
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;
  
  List<OpportunityLineItem> OppLineLst = new List<OpportunityLineItem>();
  Set<id> OpportunityIds = new Set<id>();
  Set<id> ProductIds = new Set<id>();
  
  //Static run variable
  private static boolean run = true;
  public static boolean runOnce()
  {
    if(run){
      run=false;
      return true;
    }else{
      return run;
    }
  }
  public static boolean runAfter = True;
  
  //Constructor
  public CPQ_OppProduct_Owner_Calc_Helper(boolean isExecuting, integer size)
  {
    m_isExecuting = isExecuting;
    BatchSize = size;
  }
  
  public void OnBeforeInsert(OpportunityLineItem[] newOppProducts, Map<ID,OpportunityLineItem> OppProductMap)
  {
      for(OpportunityLineItem line : newOppProducts)
	   {
	     if(line.OpportunityId != null || line.Product2Id != null)
		 {
		   OppLineLst.add(line);
		   OpportunityIds.add(line.OpportunityId);
		   ProductIds.add(line.Product2Id);		   
		 }
	   }
	   updateOppProductOwner(OppLineLst,OpportunityIds,ProductIds);
  }
  
  public void OnBeforeUpdate(OpportunityLineItem[] oldOppProducts, OpportunityLineItem[] updatedOppProducts, Map<ID, OpportunityLineItem> oldOppProductMap, Map<ID, OpportunityLineItem> newOppProductMap)
  {
     for(OpportunityLineItem line : updatedOppProducts)
	 {
       OpportunityLineItem oldOppline = oldOppProductMap.get(line.Id);
       if( line.OpportunityId != oldOppline.OpportunityId || line.Product2Id != oldOppline.Product2Id )
		{
		   OppLineLst.add(line);
		   OpportunityIds.add(line.OpportunityId);
		   ProductIds.add(line.Product2Id);		   
		}
	 }
	 
	 if( OppLineLst.size()>0 )
	     updateOppProductOwner(OppLineLst,OpportunityIds,ProductIds);
  }
   
   public void OnAfterInsert(OpportunityLineItem[] newOppProducts, Map<ID,OpportunityLineItem> OppProductMap)
   {
     
   }
   
   public void OnAfterUpdate(OpportunityLineItem[] oldOppProducts, OpportunityLineItem[] updatedOppProducts, Map<ID, OpportunityLineItem> oldOppProductMap, Map<ID, OpportunityLineItem> newOppProductMap)
   {
     
   }
   
   public void updateOppProductOwner(List<OpportunityLineItem> opplilst, set<Id> OppIds, set<Id> ProdIds)
   { 
	   Map<id,Opportunity> OppMap = new Map<id,Opportunity> ([select id,name, ownerId, AccountId, Account.MPL_Sales_Rep__c,Account.Name,Ship_To__c,Ship_To__r.Participant_Account__c from Opportunity where Id IN: OppIds]);
	           
       Map<id,Product2> ProdMap = new Map<id,Product2> ([select id,name,Product__c,Product__r.Product_line_Name__c, Product__r.Product_Line_Code__c from Product2 where Id IN: ProdIds]);      
      
       for(OpportunityLineItem oli : opplilst)
       {
	      Opportunity opp = OppMap.get(oli.OpportunityId);
          Product2 p =  ProdMap.get(oli.Product2Id);
         
		  if(p.Product__r.Product_line_Name__c =='Core processing' || p.Product__r.Product_line_Name__c == 'Data and Analytics' || p.Product__r.Product_line_Name__c =='Other')
		  {
		      if(opp.ownerId != null)
		          oli.CPQ_Opportunity_Product_Owner__c = opp.ownerId;
		  }
		  else if(p.Product__r.Product_line_Name__c =='Digital Engagement')
		  {
		      if(opp.Account.MPL_Sales_Rep__c != null)
		          oli.CPQ_Opportunity_Product_Owner__c = opp.Account.MPL_Sales_Rep__c; 
		  }
	  }
   }
}


// After update Trigger : Test for update of Sales Price.
   
   /*  system.debug('after update');
       set<id> LineIds = new set<Id>();
       for(OpportunityLineItem line : updatedOppProducts )
       {
           system.debug('New Line Price :' + line.unitPrice );
           
           system.debug('Old Line Price :' + oldOppProductMap.get(line.Id).unitPrice );
             system.debug('sales force Id :' + line.Id );
           
           if(line.unitPrice != oldOppProductMap.get(line.Id).unitPrice && (line.CPQ_Year_1_ARR_Amount__c != null || line.CPQ_Year_2_ARR_Amount__c != null || line.CPQ_Year_3_ARR_Amount__c != null || line.CPQ_Year_4_ARR_Amount__c != null || line.CPQ_Year_5_ARR_Amount__c != null))
               LineIds.add(line.Id);
       }
       system.debug('size :' + LineIds.size() );
       updateSalesPrice(LineIds,oldOppProductMap);
     
   
   public void updateSalesPrice(Set<Id> OppLineIds, Map<ID, OpportunityLineItem> OppProductMap )
   {
       runAfter = false;
       List<OpportunityLineItem> updatelst = new List<OpportunityLineItem> ();
       List<OpportunityLineItem> opplilst =[select id, unitPrice,CPQ_Year_1_ARR_Amount__c, CPQ_Year_2_ARR_Amount__c, CPQ_Year_3_ARR_Amount__c, CPQ_Year_4_ARR_Amount__c, CPQ_Year_5_ARR_Amount__c from OpportunityLineItem
                                            where Id =: OppLineIds];
       system.debug('priceList :' + opplilst.size() );
                                            
       for(OpportunityLineItem lin : opplilst)
       {
          // if(lin.unitPrice != OppProductMap.get(lin.Id).UnitPrice)
          // {
               system.debug('New Line Price 1 :' + lin.unitPrice );
               system.debug('Old Line Price 1 :' + OppProductMap.get(lin.Id).unitPrice );
               lin.UnitPrice = lin.CPQ_Year_1_ARR_Amount__c + lin.CPQ_Year_2_ARR_Amount__c + lin.CPQ_Year_3_ARR_Amount__c + lin.CPQ_Year_4_ARR_Amount__c + lin.CPQ_Year_5_ARR_Amount__c;
               system.debug('new price :' + lin.UnitPrice);
               updatelst.add(lin);
         //  }
       }
       system.debug('New List :' + updatelst.size() );
       if (!updatelst.isEmpty())
       {
           system.debug('Is empty ' );
          update updatelst;
       }
   }
   */