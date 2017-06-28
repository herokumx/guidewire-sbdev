public with sharing class CPQ_In_Scope_DWP_Calc_Helper {
	private boolean m_isExecuting = false;
	private integer BatchSize = 0;
	private decimal percentageIncrease = 0.25;
	private decimal multLvl1 = 0.0;
	private decimal multLvl2 = 0.001144;
	private decimal multLvl3 = 0.000942;
	private decimal multLvl4 = 0.00074;
	private integer steps = 4;
	private integer renewalYearCutoff = 3;

	//Static run variable
	private static boolean run = true;
	public static boolean runOnce(){
		if(run){
			run=false;
			return true;
		}else{
			return run;
		}
	}

	//Constructor
	public CPQ_In_Scope_DWP_Calc_Helper(boolean isExecuting, integer size){
		System.debug('CPQ_In_Scope_DWP_Calc_Helper Helper Created');
		m_isExecuting = isExecuting;
		BatchSize = size;
	}

	public void OnAfterInsert(Opportunity[] newOpportunities, Map<ID, Opportunity> opportunityMap){
		List<ID> oppsToCalculate = new List<ID>();
		for (Opportunity opp :newOpportunities) {
			if (opp.Premium_In_Scope__c != null && opp.Premium_In_Scope__c != 0) {
				oppsToCalculate.add(opp.Id);
			}
		}
		CalculateDWP(oppsToCalculate, opportunityMap);
	}

	public void OnAfterUpdate(Opportunity[] oldOpportunities, Opportunity[] updatedOpportunities, Map<ID, Opportunity> oldOpportunityMap, Map<ID, Opportunity> newOpportunityMap){
		List<ID> oppsToCalculate = new List<ID>();
		for (Opportunity opp :updatedOpportunities) {
			if (opp.Premium_In_Scope__c != null && opp.Premium_In_Scope__c != 0) {
				oppsToCalculate.add(opp.Id);
			}
		}
		CalculateDWP(oppsToCalculate, newOpportunityMap);
	}

	public void OnBeforeInsert(Opportunity[] newOpportunities, Map<ID, Opportunity> opportunityMap){
		Map<Id, Id> previousToCurrentOpp = new Map<Id, Id>();
		for (Opportunity opp :newOpportunities) {
			if (opp.CPQ_Term_Sequence__c != null && opp.CPQ_Term_Sequence__c > renewalYearCutoff) {
				if (opp.Original_Opportunity_New__c != null) {
					previousToCurrentOpp.put(opp.id, opp.Original_Opportunity_New__r.Id);
				} else {
					opp.Original_Opportunity_New__c = opp.Id;
					previousToCurrentOpp.put(opp.id, opp.Id);
				}

			}
		}

		for (Opportunity prevOpp : [SELECT Id, CPQ_Renewal_In_Scope_DWP__c FROM Opportunity WHERE Id IN : previousToCurrentOpp.keySet()]) {
			if (prevOpp.CPQ_Renewal_In_Scope_DWP__c != null && prevOpp.CPQ_Renewal_In_Scope_DWP__c > 0) {
				Id currentId = previousToCurrentOpp.get(prevOpp.Id);
				Opportunity current = opportunityMap.get(currentId);
				//This is where we update the current Preimium In Scope to be the Renewal In Scope from the previous year.
				current.Premium_In_Scope__c = prevOpp.CPQ_Renewal_In_Scope_DWP__c;
			}
		}
	}

	public void OnBeforeUpdate(Opportunity[] oldOpportunities, Opportunity[] updatedOpportunities, Map<ID, Opportunity> oldOpportunityMap, Map<ID, Opportunity> newOpportunityMap)
	{
		Map<Id, Id> previousToCurrentOpp = new Map<Id, Id>();
		for (Opportunity opp :updatedOpportunities) {
			if (opp.CPQ_Term_Sequence__c != null && opp.CPQ_Term_Sequence__c > renewalYearCutoff) {
				if (opp.Original_Opportunity_New__c != null) {
					previousToCurrentOpp.put(opp.id, opp.Original_Opportunity_New__r.Id);
				} else {
					opp.Original_Opportunity_New__c = opp.Id;
					previousToCurrentOpp.put(opp.id, opp.Id);
				}
			}
		}

		for (Opportunity prevOpp : [SELECT Id, CPQ_Renewal_In_Scope_DWP__c FROM Opportunity WHERE Id IN : previousToCurrentOpp.keySet()]) {
			if (prevOpp.CPQ_Renewal_In_Scope_DWP__c != null && prevOpp.CPQ_Renewal_In_Scope_DWP__c > 0) {
				Id currentId = previousToCurrentOpp.get(prevOpp.Id);
				Opportunity current = newOpportunityMap.get(currentId);
				//This is where we update the current Preimium In Scope to be the Renewal In Scope from the previous year.
				current.Premium_In_Scope__c = prevOpp.CPQ_Renewal_In_Scope_DWP__c;
			}
		}

	  //included by Hari to create Contracts and Contract Lines.
		List<ServiceContract> SCLst = new List<ServiceContract>();
        List<ContractLineItem> SClineLst = new List<ContractLineItem>();
        List<opportunityLineItem> OppProdsLst = [select id,name,currencyIsoCode,OpportunityId,Product2Id,PricebookentryId,pricebookentry.Product2Id,PricebookEntry.Pricebook2Id,opportunity.Account.Name,opportunity.currencyIsocode,
                                                 UnitPrice,Quantity,opportunity.Ship_To__c,opportunity.Ship_To__r.Participant_Account__c from opportunityLineItem where opportunityId =: newOpportunityMap.keyset() ];

        Map<id,string> AccountnamesMap = new Map<id,string>();
        Map<Id,Id> ShipToParticipants = new Map<Id,Id>();
       // Set<Id> ProductIds = new Set<Id>();

        Map<id,list<opportunityLineItem>> OppProdsMap = new Map <id,list<opportunityLineItem>>();
        for(opportunityLineItem line : OppProdsLst) {
          if(OppProdsMap.containsKey(line.OpportunityId)) {
	        list<opportunityLineItem> lst1 = OppProdsMap.get(line.OpportunityId);
	        lst1.add(line);
	        OppProdsMap.put(line.OpportunityId, lst1);
	      }
	      else {
	       list<opportunityLineItem> lst2 = new list<opportunityLineItem>();
	       lst2.add(line);
	       OppProdsMap.put(line.OpportunityId, lst2);
	      }

	      AccountnamesMap.put(line.opportunityId, line.opportunity.Account.Name);
	      ShipToParticipants.put(line.opportunityId, line.opportunity.Ship_To__r.Participant_Account__c);
	     // ProductIds.add(line.Product2Id);
	   }

	   // Updated code to fix query exception faced due to invisibility of data in test context.
	   Pricebook2 activepbs;
	   if(Test.isRunningTest()) {
		   activepbs = new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'StandardPB');
	   } else {
		   activepbs = [select Id, Name from Pricebook2 where isActive = true and IsStandard = true limit 1];
	   }

	    // ORIGINAL CODE: Pricebook2 activepbs = [select Id, Name from Pricebook2 where isActive = true and IsStandard = true limit 1];
       // Map<id,PricebookEntry> PBEMap = new Map<id,PricebookEntry>([select id,name,currencyisocode,product2Id,product2.Name,product2.sku_id__c,pricebook2Id from pricebookentry where Product2Id =: ProductIds and pricebook2Id =: activepbs.Id ]);

        for (Opportunity opp :updatedOpportunities) {
          Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
          if( opp.CPQ_Create_Service_Contract__c == True && opp.CPQ_Create_Service_Contract__c != oldOpp.CPQ_Create_Service_Contract__c ) {
            integer int1 = Math.round(Math.random()*100000);
            string s = AccountnamesMap.get(opp.Id).substringBefore(' ');
	        string s1 =opp.Name.substringBefore(' ');

           ServiceContract sc = new ServiceContract();
            sc.Name = s+'SC'+int1;
            sc.Accountid = ShipToParticipants.get(Opp.Id);
            sc.CPQ_Opportunity__c = Opp.Id;
            sc.CS_Ship_to_Contact__c = opp.Ship_To__c;
	        sc.CPQ_Contract_Identifier__c = s1+int1;
	        sc.pricebook2Id = activepbs.Id;
	        sc.currencyisocode = Opp.currencyisocode;
	        sc.StartDate = Date.today();

	        SCLst.add(sc);

	       list<opportunityLineItem> newLst = OppProdsMap.get(opp.Id);
	       for(opportunityLineItem lin : newLst) {
	         ContractLineItem cli = new ContractLineItem();

    	     ServiceContract sc1 = new ServiceContract(CPQ_Contract_Identifier__c = s1+int1);
		     cli.ServiceContract = sc1;
		     cli.PriceBookEntryId=lin.PricebookEntryId;
		     cli.UnitPrice=lin.UnitPrice;
		     cli.Quantity =lin.Quantity;
		     cli.StartDate = Date.today();

		     SClineLst.add(cli);
	       }
         }

        }
        insert SCLst;
        insert SClineLst;
	}

	public void CalculateDWP(List<ID> oppsToCalculate, Map<ID, Opportunity> opportunityMap) {
		Map<Id, Decimal> opptoOriginal = new Map<Id, Decimal>();
		Set<Id> originalOpps = new Set<Id>();
		for (Opportunity iterateOpp : opportunityMap.values()) {
			originalOpps.add(iterateOpp.Original_Opportunity_New__c);
		}

		List<Opportunity> oldOppList = [SELECT Id, Premium_In_Scope__c FROM Opportunity where Id IN :originalOpps];
		for (Opportunity iterateOldOpp : oldOppList) {
			opptoOriginal.put(iterateOldOpp.Id, iterateOldOpp.Premium_In_Scope__c);
		}

		List<CPQ_In_Scope_DWP__c> newDWP = new List<CPQ_In_Scope_DWP__c>();
		List<CPQ_In_Scope_DWP__c> delDWP = new List<CPQ_In_Scope_DWP__c>();
		for (Opportunity opp: opportunityMap.values()) {
			Decimal amountForDWP;
			//If it's not a renewal opportunity then just use our own Premium In Scope value
			if (!opp.SBQQ__Renewal__c) {
				amountForDWP = opp.Premium_In_Scope__c;
			}
			//If it's a renewal then use our parent's Premium In Scope value
			else {
				amountForDWP = opptoOriginal.get(opp.Original_Opportunity_New__c);
			}
			if (amountForDWP == null) continue;

			//Remove all the old entries
			List<CPQ_In_Scope_DWP__c> toDel = [SELECT Id, Premium_Amount__c FROM CPQ_In_Scope_DWP__c WHERE Opportunity__c = :opp.Id AND Premium_Amount__c != :String.valueOf(amountForDWP)];
			delDWP.addAll(toDel);

			List<CPQ_In_Scope_DWP__c> recordCheck = [SELECT Id, Premium_Amount__c FROM CPQ_In_Scope_DWP__c WHERE Opportunity__c = :opp.Id AND Premium_Amount__c = :String.valueOf(amountForDWP)];
			if (recordCheck.size() >= steps) continue;


			//Level 1
			decimal DWPStart = amountForDWP;
			decimal increase = DWPStart * percentageIncrease;
			decimal DWPEnd = DWPStart + increase;

			//decrease level 3
			DWPStart -= increase * 3;
			DWPEnd -= increase *3;
			CPQ_In_Scope_DWP__c dwp_3 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Decrease',
				DWP_Multiplier__c = multLvl1
			);
			newDWP.add(dwp_3);

			//decrease level 2
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp_2 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Decrease',
				DWP_Multiplier__c = multLvl1
			);
			newDWP.add(dwp_2);

			//decrease level 1
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp_1 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Decrease',
				DWP_Multiplier__c = multLvl1
			);
			newDWP.add(dwp_1);

			//standard level
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Buffer',
				DWP_Multiplier__c = multLvl1
			);
			newDWP.add(dwp);

			//Level 2
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp2 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Increase',
				DWP_Multiplier__c = multLvl2
			);
			newDWP.add(dwp2);

			//Level 3
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp3 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Increase',
				DWP_Multiplier__c = multLvl3
			);
			newDWP.add(dwp3);

			//Level 4
			DWPStart = DWPEnd;
			DWPEnd += increase;
			CPQ_In_Scope_DWP__c dwp4 = new CPQ_In_Scope_DWP__c(
				Premium_Amount__c = String.valueOf(amountForDWP),
				Opportunity__c = opp.Id,
				DWP_Range_Start__c = DWPStart + 1,
				DWP_Range_End__c = DWPEnd,
				DWP_Range_Type__c = 'Increase',
				DWP_Multiplier__c = multLvl4
			);
			newDWP.add(dwp4);
		}

		delete delDWP;
		insert newDWP;
	}
}