public class CaseEscalatorHandler 
{
    public void Escalator(Map<Id,Case> OldCaseMap, List<Case> csLst)
    {
        for(case cse : csLst)
        {
            Case oldCase = OldCaseMap.get(cse.Id);
            if(OldCase.IsEscalated != cse.IsEscalated && cse.IsEscalated)            
               cse.Case_Escalator__c = userinfo.getUserId();            
        }
    }

}