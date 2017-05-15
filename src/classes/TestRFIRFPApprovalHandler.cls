@isTest(seeAllData = true)
public class TestRFIRFPApprovalHandler 
{
    static testmethod void ApproversTestEmea()
    {   
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testingser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standusertestha@testorg.com');
        insert u;
        
                
        opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500, Region__c ='EMEA', Services_Director__c = u.id,
                                           Premium_In_Scope__c = 100,RFI_Approval_Sd__c = 'Approved',RFi_Approval_Sc__c = 'Approved',
                                           RFp_Approval_Sd__c = 'Approved',RFp_Approval_SC__c = 'Approved');             
                                          
        insert opp; 
        
    
        opp.RFI_Approval_SC__c = 'denied'; 
        opp.RFI_Approval_SD__c = 'denied';
        opp.RFP_Approval_SC__c = 'Denied';
        opp.RFP_Approval_SD__c = 'denied';  
        update opp;
          
     } 
    
     static testmethod void ApproversTestAmer()
     {   
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testingser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standusertestha1@testorg.com');
        insert u;
        
                
        opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500, Region__c ='Amer', Services_Director__c = u.id,
                                           Premium_In_Scope__c = 100,RFI_Approval_Sd__c = 'Approved',RFi_Approval_Sc__c = 'Approved',
                                           RFp_Approval_Sd__c = 'Approved',RFp_Approval_SC__c = 'Approved');             
                                          
        insert opp; 
        
    
        opp.RFI_Approval_SC__c = 'denied'; 
        opp.RFI_Approval_SD__c = 'denied';
        opp.RFP_Approval_SC__c = 'Denied';
        opp.RFP_Approval_SD__c = 'denied';  
        update opp;
          
     } 
    
    static testmethod void ApproversTestApac()
    {   
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testingser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standusertestha2@testorg.com');
        insert u;
        
                
        opportunity opp = new opportunity (StageName = 'Prospecting', CloseDate = system.today(),
                                           Name='testopp', Amount=500, Region__c ='APAC', Services_Director__c = u.id,
                                           Premium_In_Scope__c = 100,RFI_Approval_Sd__c = 'Approved',RFi_Approval_Sc__c = 'Approved',
                                           RFp_Approval_Sd__c = 'Approved',RFp_Approval_SC__c = 'Approved');             
                                          
        insert opp; 
        
    
        opp.RFI_Approval_SC__c = 'denied'; 
        opp.RFI_Approval_SD__c = 'denied';
        opp.RFP_Approval_SC__c = 'Denied';
        opp.RFP_Approval_SD__c = 'denied';  
        update opp;
          
     }      
}