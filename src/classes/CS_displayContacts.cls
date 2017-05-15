public class CS_displayContacts 
{
    private final Community_Access_Request__c aReq;
    public List<Contact> conList {get; set;}
    public boolean ContactsExist {get; set;}
            
    public CS_displayContacts(ApexPages.StandardController stdController)
    {
        ContactsExist = true; 
        this.aReq = (Community_Access_Request__c)stdController.getRecord();
        conList = new List<Contact>();           
    }
    
    public pageReference ContactsList()
    {
       Community_Access_Request__c request = [select id,name,Email__c,Full_Name__c from Community_Access_Request__c where id =: aReq.Id];
        
       if(request.Full_Name__c != NULL || request.Email__c != NULL)
       {      
          conList = [select id,name,email,accountId,account.name from Contact where name =: request.Full_Name__c or email=: request.Email__c];
       }
       
       if(conList.size() < 1)
       {
         ContactsExist = false; 
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No Matches found with Name or Email'));
       }
       
       return null;
    } 
     
     public Pagereference viewCon()
     {
       String conId = ApexPages.currentPage().getParameters().get('conId'); 
       PageReference redirectPG = new PageReference('/' + conId);
       redirectPG.setRedirect(true);
       
       return redirectPG;
    }        
  }     
       
           
  /*  public Pagereference returnPage()
    {
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        String CurrentId = ApexPages.currentPage().getParameters().get('id');
        PageReference redirectPG;
                
        if(retURL != null)
            redirectPG = new PageReference('/' + retURL);
        else if(CurrentId != null)
            redirectPG = new PageReference('/' + CurrentId);
        
        return redirectPG;
    }
  */