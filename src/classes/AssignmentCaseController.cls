public class AssignmentCaseController
{

    

    private final pse__Assignment__c Assg;
    public Case NewCase {get; set;}
    public id Aset {get; set;}
    public string installationStr {get;set;}
    public boolean usersEqual{get; set;}
    public Map<string,boolean> AssetIdHostedFlagMap = new Map<string,boolean>();
    
    public AssignmentCaseController(ApexPages.StandardController controller)
    {
        Assg = (pse__Assignment__c)controller.getRecord();
        usersEqual = true;
        Recordtype rt = [Select id from RecordType where sObjecttype = 'Case' and  DeveloperName ='CS_Customer_Support'];
        
        NewCase = new Case();         
        NewCase.CS_Project_Assignment__c = Assg.Id;
        NewCase.contactid=Assg.pse__resource__c;
        NewCase.RecordTypeId = rt.Id;
        NewCase.Environment_Affected__c ='Implementation';
     }
     
   public PageReference checkResource()
     {
        
        pse__assignment__c asgn = [select id,name,pse__resource__c, pse__resource__r.pse__Salesforce_User__c from pse__assignment__c where id =: ApexPages.currentPage().getParameters().get('id')];
        if(asgn.pse__resource__r.pse__Salesforce_User__c != userinfo.getUserId())
        {
           usersEqual = false;
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Case can be created only by the Resource of the Assignment'));
           
        } 
       
        return null;       
     }
            
   public List<SelectOption> getAssetList() 
     {
        pse__Assignment__c Assgn =  [select id,pse__resource__c,name,pse__Project__c,pse__Project__r.pse__Account__c, pse__Project__r.PSA_Customer_Account__c  from pse__Assignment__c where id =: Assg.Id];
        
        List<SelectOption> assets = new List<SelectOption>();
        assets.add(new SelectOption('', '--None--'));

        for (Asset p: [select id,name,AccountId,parent.Is_Hosted__c from Asset where recordtype.name = 'Child Asset' and (AccountId =: Assgn.pse__Project__r.pse__Account__c or AccountId =: Assgn.pse__Project__r.PSA_Customer_Account__c) ]) 
        {
            system.debug('######## Asset Hosted?  p.Id : ' + p.Id + ' p.parent.Is_Hosted__c    ' + p.parent.Is_Hosted__c );
            AssetIdHostedFlagMap.put(p.Id,p.parent.Is_Hosted__c);
            assets.add(new SelectOption(p.Id, p.Name));
        }

        return assets;
    }
    
  
    
    public PageReference installationStr() {
        boolean isHosted = false;
        system.debug('########### Selected Asset Id : ' + Aset);
        if(Aset != null){
            if(AssetIdHostedFlagMap != null){
          isHosted = AssetIdHostedFlagMap.get(Aset); 
        }
        
        if(isHosted){
            installationStr = 'Hosted';
            NewCase.Asset_Type__c = 'Hosted';
        } else {
            installationStr = 'OnPremise';
            NewCase.Asset_Type__c = 'OnPremise';            

        }
        
        
        }
        return null;
    }

    public Id getAset() 
    {
        return this.Aset;
    }

    public void setAset(Id AsetId) 
    {
        
        this.Aset = AsetId;
    }

    public List<SelectOption> getVersionList() 
    {
       List<SelectOption> versions = new List<SelectOption>();
         versions.add(new SelectOption('', '--None--'));
        
        if(Aset != null)
        {
           Asset ast =[select id,name,Product2Id from Asset where id =: getAset()];    
        
           for (CS_Release__c v: [Select id,name,CS_Product__c from CS_Release__c where  CS_Product__c =: ast.Product2Id order by name Desc] ) 
            {
                versions.add(new SelectOption(v.Id, v.Name));
            }
         }
        return versions;        
    }
    
     
     
    public PageReference saveMe()
    {
        try{
        
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
                        
         NewCase.Assetid = aset;
         //Setting the DMLOption on Case instance
         NewCase.setOptions(dmlOpts);
         insert NewCase;
         
        }
        catch(Exception e)
        {
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Asset and Product Version is Required'));          
        }
        
        PageReference page = new ApexPages.StandardController(NewCase).view();
        return page;
    }       
}