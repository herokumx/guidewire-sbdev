@isTest
public class CS_CreateContactACPHandlerTest
{
    static testmethod void createACP()
    {
        
        Test.StartTest();
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc,'General customer');
        
        List<Asset> AstLst = CS_TestDataUtility.createParentAssetRecord(acc,True);
        
        AstLst[0].CS_Support_Group__c ='Billing System';
        Update AstLst[0];
        
            pw_cc__CountryObject__c pcc ;
            pw_cc__State__c pcs ;
            
           
            pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = 'USA',
            pw_cc__IsoCode_2__c = 'US'
            );
            insert pcc;

        pcs = new pw_cc__State__c(
        pw_cc__Country__c = pcc.id,
        pw_cc__IsoCode__c = 'VA');
        insert pcs;
        Map<String,String> mapOfRecordType = GWUtilities.getRecordTypeId('Community_Access_Request__c'); 
       
        Community_Access_Request__c caReq = new Community_Access_Request__c();
        caReq.RecordTypeId = mapOfRecordType.get('Update_Access_Request');
        careq.Account__c = acc.Id;
        caReq.First_Name__c ='test1';
        caReq.Last_Name__c ='Cartest';
        caReq.Title__c ='Developer';
        caReq.Email__c ='haritest@gmail.com';
        caReq.Phone__c = '3456728906';
        caReq.Mailing_Street__c ='Farwell stree';
        caReq.Mailing_City__c ='Foster city';
        caReq.Mailing_State__c = pcs.Id;
        caReq.Mailing_Country__c = pcs.pw_cc__Country__c;
        caReq.Mailing_Zip_Postal_Code__c ='97685';
        caReq.Contact__c = cont.Id; 
        caReq.BillingCenter_Support_Group__c ='Billing System';
        caReq.ClaimCenter_support_group__c ='Claim System';
        caReq.BillingCenter_Access_type__c = 'General Customer';
        caReq.ClaimCenter_Access_type__c = 'Customer Support';
        caReq.Authorize_Change__c = true;
        
        insert caReq;
        
        caReq.Create_Contact__c = true;
        
        
        update caReq;
   
      
            
        
        Test.StopTest();
    }
    
    static testmethod void createACP2()
    {
        
        Test.StartTest();
        Account acc = CS_TestDataUtility.createCustomerAccount();
        Contact cont = CS_TestDataUtility.createContact(acc,'General customer');
        
        List<Asset> AstLst = CS_TestDataUtility.createParentAssetRecord(acc,True);
        
        AstLst[0].CS_Support_Group__c ='Billing System';
        Update AstLst[0];
        
            pw_cc__CountryObject__c pcc ;
            pw_cc__State__c pcs ;
            
           
            pcc = new pw_cc__CountryObject__c(
            pw_cc__IsoCode_3__c = 'USA',
            pw_cc__IsoCode_2__c = 'US'
            );
            insert pcc;

            pcs = new pw_cc__State__c(
                pw_cc__Country__c = pcc.id,
                pw_cc__IsoCode__c = 'VA');
            insert pcs;
        
      
        Map<String,String> mapOfRecordType = GWUtilities.getRecordTypeId('Community_Access_Request__c'); 
         
        
         Community_Access_Request__c careqUpdate = new Community_Access_Request__c();
            careqUpdate.RecordTypeId = mapOfRecordType.get('Update_Access_Request');
            //careqUpdate.RecordTypeId = RtU.Id;
            careqUpdate.Account__c = acc.Id;
            careqUpdate.First_Name__c ='test1';
            careqUpdate.Last_Name__c ='Cartest';
            careqUpdate.Title__c ='Developer';
            careqUpdate.Email__c ='haritest@gmail.com';
            careqUpdate.Phone__c = '3456728906';
            careqUpdate.Mailing_Street__c ='Farwell stree';
            careqUpdate.Mailing_City__c ='Foster city';
            careqUpdate.Mailing_State__c = pcs.Id;
            careqUpdate.Mailing_Country__c = pcs.pw_cc__Country__c;
            careqUpdate.Mailing_Zip_Postal_Code__c ='97685';
            careqUpdate.BillingCenter_Support_Group__c ='Billing System';
            careqUpdate.ClaimCenter_support_group__c ='Claim System';
            careqUpdate.BillingCenter_Access_type__c = 'General Customer';
            careqUpdate.ClaimCenter_Access_type__c = 'Customer Support';   
            careqUpdate.Contact__c = cont.Id; 
            careqUpdate.Authorize_Change__c = true;
            
            careqUpdate.Data_Management_Support_Group__c = 'Data Management';
            careqUpdate.Data_Management_Access_Type__c = 'General Custoemr';
            careqUpdate.Digital_Portals_support_group__c = 'Digital Portals';
            careqUpdate.Digital_Portals_Access_Type__c = '';
            careqUpdate.GW_Live_Support_Group__c = 'GW Live';
            careqUpdate.GW_Live_Access_Type__c = 'General Customer';
            careqUpdate.Predictive_Analytics_Support_Group__c = 'Predictive Analytics';
            careqUpdate.Predictive_Analytics_Access_Type__c = 'Customer Support';
            
            insert careqUpdate;
            
           // careqUpdate.Access_Type__c = 'Partner'; 
            careqUpdate.Create_Contact__c = true;
            update careqUpdate;
            
        
        Test.StopTest();
    }
    
    

}