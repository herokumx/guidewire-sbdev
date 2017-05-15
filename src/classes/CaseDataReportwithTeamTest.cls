/*
    *****************************************************************************************************************************
    Class Name - CaseDataReportwithTeamTest
    Class Type -  Trigger Handler Test Ckass 
    Test Class-
    Purpose- 
    
    *****************************************************************************************************************************
    
    Name        Email              Date             Notes 
    Suchitra                                        Initial Creation
    
    *****************************************************************************************************************************
    */
    
    @isTest
    
    private class CaseDataReportwithTeamTest{
    
        static testMethod void testCaseDataReportwithTeamTest() {
        
        
        
            test.StartTest();
            
            PageReference pageRef = Page.CaseDataReportwithTeam;
            Test.setCurrentPage(pageRef);
            
            
            Account acc = CS_TestDataUtility.createCustomerAccount();
            
            //create parent asset
            List<Asset> parentAsset = CS_TestDataUtility.createParentAssetRecord(acc,true);
            
            //create product
            Product2 prd = CS_TestDataUtility.createProductRecord();
            
            //create pricebook 
            Pricebook2 pb = CS_TestDataUtility.createPriceBook();
            
            //create pricebookentry 
            
            PricebookEntry pbe = CS_TestDataUtility.createPriceBookEntry(prd,pb);
            
            User usrRecord = CS_TestDataUtility.createServiceTestUser();
            
             usrRecord.CS_User_Team__c = 'Support';
             
             update usrRecord;
            
            //create child asset
            Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, parentAsset[0], 'Implementation');
            
            childAsset.CS_Primary_Supp_Partner__c =  usrRecord.Id;
            
            update childAsset;
            
            //create contact
            Contact con = CS_TestDataUtility.createContact(acc, 'General Customer');
            
            //create service contract 
            ServiceContract sc = CS_TestDataUtility.createServiceContract(acc);  
            
            //create service contracl line items 
            ContractLineItem cntractLineItem =  CS_TestDataUtility.createServiceContractLineItem(sc,  pbe) ;  
            
            
            
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.SetupOwnerId = UserInfo.getUserId();
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            //Asset childAsset = CS_TestDataUtility.createChildAssetRecord(acc, prd, childAsset  , 'Production');
            
            
            CS_Asset_Contact_Permissions__c acp = CS_TestDataUtility.createACP(parentAsset[0], con, 'Customer Support', true);
            
            // create case
            Case c = CS_TestDataUtility.createCaseCS(acc,childAsset,con);  
            
                    
            c.OwnerId = usrRecord.Id;
            
            update c; 
            
            CaseTeamRole cRole = new CaseTeamRole();
            
            User admin = [SELECT Id FROM user WHERE Profile.Name =:'System Administrator' AND IsActive=:true][0];
    
            
            system.runAs(admin){
            //cRole = CS_TestDataUtility.createCaseTeamRole('Follow the Sun','Edit');   
            cRole = [Select Id from CaseTeamRole Where Name=:'Leads'][0];
            CaseTeamMember ctMember = CS_TestDataUtility.createCaseTeamMember(c.Id,usrRecord.Id,cRole .Id);
            } 
           
            
            
            
            system.runAs(usrRecord){
            //test.startTest();
            CaseDataReportwithTeam caseData = new CaseDataReportwithTeam();
            caseData.userSelected = null;
            
            System.Debug('caseData is.. ' + caseData );
            
            caseData = new CaseDataReportwithTeam();
            //caseData.getParameters();
            caseData.getUserIDs();
            
            List<CaseDataReportwithTeam.WrapCase> lstWrappedCase = caseData.caseList;
           // System.Debug('++lstWrappedCase++' + lstWrappedCase );
            
            caseData.userSelected =  usrRecord.Id;
            
            List<CaseDataReportwithTeam.WrapCase> lstWrappedCaseNew = caseData.caseList;
            
            
            caseData.processRequests();
            
            
            }  
            test.stopTest();
        }
    
    }