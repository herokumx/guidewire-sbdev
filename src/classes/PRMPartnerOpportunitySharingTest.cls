@isTest(seealldata=true)
class PRMPartnerOpportunitySharingTest
{
    static testMethod void testPRMPartnerOppty()
    {
        List<Profile> lstProfile =[Select Id from Profile
                                    where profile.userlicense.name = 'Partner Community'];
       
          
        list<user> ulst = [select id,name,contact.Account.id from user where profile.userlicense.name = 'Partner Community' and user.contact.Account.name != null and isactive=true ];
       
       
       
        List<RecordType> lstRecordType = [Select Id from RecordType where Name ='Partner'];
        List<RecordType> lstPartnerOpptyRT = [Select Id from RecordType where Name ='Partner Opportunity'];
         id accid=ulst[0].contact.Account.id;
         id recid=lstPartnerOpptyRT[0].id;
       
       
        
       
       Opportunity oppty = new Opportunity(SWOT_Strengths__c='S Value',
                                            SWOT_Weaknesses__c='W Value',
                                            SWOT_Opportunities__c = 'O Value',
                                            SWOT_Threats__c = 'T Value',
                                            SWOT_Strategy_SO__c = 'SO Value',
                                            SWOT_Strategy_ST__c = 'ST Value',
                                            SWOT_Strategy_WO__c = 'WO Value',
                                            SWOT_Strategy_WT__c = 'WT Value',
                                            Name = 'Test SWOT Opportunity',
                                            StageName = 'Qualified',
                                            CloseDate = Date.today(),
                                            Premium_In_Scope__c = 1000,
                                            PRM_Referring_Partner2__c =accid,
                                            RecordTypeId =recid,
                                            Amount=100);
       
            Database.saveResult saveResult = Database.insert(oppty, false);
            //Opportunity opp =[Select RecordType.Name from Opportunity];
           // system.debug('****'+opp.RecordType.Name);
          // system.assert(saveResult.isSuccess());
        
       
    }
}