@isTest
private class CS_CaseCommentTriggerHandlerTest {
    
    @isTest static void test_method_one() {

        //create custom setting CS_ByPass__c    
        CS_ByPass__c byp = new CS_ByPass__c();
        byp.CS_Batch_Context__c = true;

        CS_Profile_Id__c csProfile = new CS_Profile_Id__c();
        csProfile.CS_Customer_Profile_18__c = GWUtilities.getProfileId('GW Customer Community');
        csProfile.CS_Partner_Profile_18__c = GWUtilities.getProfileId('GW Partner Community');

        insert csProfile;
        
        //create test account
        Account acc = CS_TestDataUtility.createCustomerAccount();

        //create parent asset
        List<Asset> parentAsset = CS_TestDataUtility.createParentAssetRecord(acc,true);

        //create product
        Product2 prd = CS_TestDataUtility.createProductRecord();

        //create child asset
        Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');

        //create contact
        Contact con = CS_TestDataUtility.createContact(acc, 'General Customer');

        //create customer community test user
        User u = CS_TestDataUtility.createCustomerCommunityTestUser(con);
        
        //CS_Asset_Contact_Permissions__c acpRecord = CS_TestDataUtility.createAcp(parentAsset[0],con, 'Customer Support', true);

        //create case
        Case caseRec = CS_TestDataUtility.createCaseCS(acc, childAsset, con);
        
        GW_Common_Settings__c gwSettings = new GW_Common_Settings__c(name= 'EnableContentVersionTrigger', Boolean_Value__c = false);
        insert gwSettings;  
        
        
        
        //create case comment
        test.startTest();
        CaseComment caseComm1 = CS_TestDataUtility.createCaseComment(caseRec,'test comment1 body', true);       
        ContentVersion contentVersion = CS_TestDataUtility.createContentDocument();
        ContentVersion cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersion.Id];
        ContentDocumentLink cdl2 = CS_TestDataUtility.createUploadDocument(caseRec);
        
        //Create FeedItem 
        contentVersion cVersion = new contentVersion(
        pathonclient = 'My Document.docx',
        versionData = EncodingUtil.base64Decode('SampleImageFile')
        );
        insert cVersion;   
        //Inserting  post on chatter
        FeedItem textFeed = new FeedItem(
                Body = 'This is a text post',
                Type = 'TextPost',
                ParentId = caseRec.id               
        );          
        insert textFeed;
        
        FeedComment fc = new FeedComment(
            feedItemId = textFeed.Id,
            relatedRecordId = cVersion.id,
            commentBody = 'Test Comment Body'
            //commentType = 'ContentComment'
        );   
        try {
        insert fc;
        }catch (DmlException e)
        {
              System.assert( e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
                
        }
        
        
        
        System.runAs(u){            
            
            CaseComment caseComm2 = CS_TestDataUtility.createCaseComment(caseRec,'test comment2 body', true);

            CaseComment caseComm3 = CS_TestDataUtility.createCaseComment(caseRec,'test comment3 body', false);

            caseComm3.commentbody = 'test comments';
            update caseComm3;
            
                 
            }
            
            
        Case caseRecN = new case();  
        Boolean updateCaseStatus;   
        CS_CaseStatusUpdate csUpdateService = new CS_CaseStatusUpdate (); 
        
        updateCaseStatus = CS_CaseStatusUpdate.updateCase(caseRecN.Id);
        System.assertEquals(updateCaseStatus, false);
        
        /*
        Case caseR = [Select Id from Case where IsClosed = false LIMIT 1][0];
        
        User admin = [SELECT Id FROM user WHERE Profile.Name =:'System Administrator' AND IsActive=:true][0]; 
        
       
        updateCaseStatus = CS_CaseStatusUpdate.updateCase(caseR.Id);
        System.assertEquals(updateCaseStatus, true);
        */      
        //Close Case Test Coverage for WebService Apex CS_CaseStatusUpdate
         
        //Test Coverage for CaseCommentExtension 
        
        ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
        CaseCommentExtension testCaseCommentExtension = new CaseCommentExtension(sc);
        
        PageReference pageRef = Page.CS_CreateCaseCommentFromCasePost;
        pageRef.getParameters().put('id', caseRec.Id);
        Test.setCurrentPage(pageRef);
        CaseComment comm = new CaseComment();
        comm.commentbody= 'Test Coverage Baby !';
        comm.ParentId = caseRec.Id;
        testCaseCommentExtension.comment = comm;
        testCaseCommentExtension.addComment();
        CaseComment comm2 = new CaseComment();
        comm2.commentbody= '';
        comm2.ParentId = caseRec.Id;
        testCaseCommentExtension.comment = comm2;
        testCaseCommentExtension.addComment();
        
        test.stopTest();
    }       

    static testMethod void testCreateCaseUpdate() {

        test.starttest();

         List<Case> cas = CS_CaseCreateController.getCaselist();
         Account a = CS_TestDataUtility.createCustomerAccount();
         Contact c = CS_TestDataUtility.createContact(a,'General Customer');
          RecordType rt1 = [Select id,name,DeveloperName from RecordType where SobjectType = 'Case' and DeveloperName = 'CS_Customer_Support'];
         Case ca = new Case();
        ca.recordtypeId = rt1.Id;
        ca.Severity__c = '3-Major';
        ca.CS_Urgency__c ='low';
        ca.Category__c ='Data';
        ca.Subject ='Testing case';
        ca.ContactId = c.Id;
        ca.Status = 'New';

        insert ca;

        CS_CaseStatusUpdate csUpdateService = new CS_CaseStatusUpdate (); 
        
        boolean updateCaseStatus = CS_CaseStatusUpdate.updateCase(ca.Id);

        test.stoptest();
    }
}