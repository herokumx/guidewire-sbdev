public with sharing class CS_CaseCreateFromCaseView {
    
    private final pse__Assignment__c Assg;
    public Case NewCase {get; set;}
    public id Aset {get; set;}
    public id product {get; set;}
    public boolean usersEqual{get; set;}
   
   public CS_CaseCreateFromCaseView(ApexPages.StandardController controller){
       
       usersEqual = true;
       Recordtype rt = [Select id from RecordType where sObjecttype = 'Case' and  DeveloperName ='CS_Customer_Support'];
       
       NewCase = new Case();         
       NewCase.AccountId = Label.Guidewire_AccountId;
       NewCase.Environment_Affected__c = 'Implementation';
       NewCase.Asset_Type__c = 'OnPremise';
       NewCase.RecordTypeId = rt.Id;
       
   }
   
   public PageReference redirect(){
       
       String baseUrl = System.URL.getCurrentRequestUrl().toExternalForm();
        string assetType = '';     
        system.debug('###### Base URL is : ' + baseUrl + ' :: Query ::  ' + System.URL.getCurrentRequestUrl().getQuery());
        if(ApexPages.currentPage().getParameters() != null){
            if(ApexPages.currentPage().getParameters().get('def_asset_id') != null){
                system.debug('###### Asset Id is : ' + ApexPages.currentPage().getParameters().get('def_asset_id'));
                Asset thisAsset = [select Parent.Is_Hosted__c from Asset where Id=: ApexPages.currentPage().getParameters().get('def_asset_id') ];
                system.debug('###### Is Hosted Flag : ' + thisAsset.Parent.Is_Hosted__c);
            
                if(thisAsset.Parent.Is_Hosted__c){
                    // assetType = '&00N4C000000pUBP=Hosted';
                    assetType = '&00Nc0000001azuk=Hosted';
             
                } else {
                    // assetType = '&00N4C000000pUBP=OnPremise';
                    assetType = '&00Nc0000001azuk=OnPremise';
                }
            }
            
        }
        
        // List<Asset> parentAssetList = [select Id, Is_Hosted__c from Asset where ];
       if(!baseUrl.contains('500')){
          baseUrl = baseUrl.substring(baseUrl.indexOf('?')+1,baseUrl.length());
       }else{
           baseUrl = '';
       }
       
       
       PageReference pg;
       system.debug(UserInfo.getProfileId());
       if(Label.CS_OverrideCaseNewPage.contains(UserInfo.getProfileId().substring(0,15))){
           ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.Warning,'Customer Cases should be created from the Assignment.  This page is for Guidewire internal Cases'));
           return null;
       }else{
           pg = new PageReference('/setup/ui/recordtypeselect.jsp?nooverride=1&ent=Case&save_new_url=%2F500%2Fe%3F&'+baseUrl+assetType);
           return pg;
       }
       
   }
   
   
   public List<SelectOption> getAssetList() 
     {
        List<SelectOption> assets = new List<SelectOption>();
        assets.add(new SelectOption('', '--None--'));

        for (Asset p: [select id,name from Asset where recordtype.developername = 'Child_Asset' and (AccountId =: Label.Guidewire_AccountId) order by name asc]) 
        {
            assets.add(new SelectOption(p.Id, p.Name));
        }

        return assets;
    }

    public Id getAset() 
    {
        return this.Aset;
    }

    public void setAset(Id AsetId) 
    {
        this.Aset = AsetId;
    }
    
    public List<SelectOption> getProductList() 
     {
        List<SelectOption> prods = new List<SelectOption>();
        prods.add(new SelectOption('', '--None--'));
        
        for (Product2 p: [select Id, Name from Product2 where isActive = true and recordtype.developername = 'Standard_Products' order by name asc]) 
        {
            prods.add(new SelectOption(p.id, p.Name));
        }

        return prods;
    }

    public Id getProduct() 
    {
        return this.product;
    }

    public void setProduct(Id prdId) 
    {
        this.product = prdId;
    }

    public List<SelectOption> getVersionList() 
    {
       List<SelectOption> versions = new List<SelectOption>();
         versions.add(new SelectOption('', '--None--'));
        
        if(product != null)
        {
        
           for (CS_Release__c v: [Select id,name,CS_Product__c from CS_Release__c where  CS_Product__c =: product order by name Desc] ) 
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
        
        List<Contact> contactList = [Select Id from Contact Where email =:UserInfo.getUserEmail() and AccountId =: Label.Guidewire_AccountId];
                        
         NewCase.Assetid = aset;
         NewCase.Productid = product; 
         if(!contactList.isEmpty()){
            NewCase.contactid=contactList[0].Id;
         }
         //Setting the DMLOption on Case instance
         NewCase.setOptions(dmlOpts);
         insert NewCase;
         
        }
        catch(Exception e)
        {
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));          
        }
        
        PageReference page = new ApexPages.StandardController(NewCase).view();
        return page;
    }
}