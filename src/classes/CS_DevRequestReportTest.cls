/*
    *****************************************************************************************************************************
    Class Name - CS_DevRequestReportTest
    Class Type - Trigger Handler Test Ckass 
    Test Class- N/A
    Purpose- 
    
    *****************************************************************************************************************************
    
    Name        Email              Date             Notes 
    Suchitra                                        Initial Creation
    
    *****************************************************************************************************************************
 */
    
    @isTest
    
    private class CS_DevRequestReportTest{
    
        static testMethod void testCS_DevRequestReportTest() {
        
        
        
            test.StartTest();
            
            PageReference pageRef = Page.CS_DevRequestReport;
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
            
             usrRecord.CS_User_Team__c = 'Enablement-CE';
             
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
            c.CS_ODC__c = false;
                    
            c.OwnerId = usrRecord.Id;
            
            update c; 
            
            
            
            User admin = [SELECT Id FROM user WHERE Profile.Name =:'System Administrator' AND IsActive=:true][0];
    
            
            system.runAs(admin){
                    
             
            RecordType rt = [Select id,name,DeveloperName from RecordType where SobjectType = 'CS_Request__c' and DeveloperName = 'Dev_Request'];
            
            
            CS_Request__c req = new CS_Request__c( recordTypeId = rt.Id,
                                         Pgm_Request_Owner__c ='BillingCenter PgM',
                                         CS_Request_Status__c ='Draft',
                                         CS_Information_Request__c ='Testing',
                                         CS_Case__c = c.Id,
                                         CS_Request_Type__c = 'Short Term Request' );
            
            //insert req;
            
            req.CS_Submitted_First_Time__c = true ;
            req.CS_Escalation_Note__c ='Testing the case';
            req.CS_Dev_Jira__c ='TestJira';
            req.Dev_Assignee__c = admin.Id;
            
            //update req;
            
            system.runAs(usrRecord){
            //test.startTest();
            CS_DevRequestReport caseData = new CS_DevRequestReport();
                        
            System.Debug('caseData is.. ' + caseData );
            
            caseData = new CS_DevRequestReport();
         
            
            List<CS_DevRequestReport.wrapCasewithDevRequest> lstWrappedCase = caseData.caseList;
                  
            caseData.startDate = date.today();
            caseData.endDate = (date.today()).addDays(2);
            
            List<CS_DevRequestReport.wrapCasewithDevRequest> lstWrappedCaseNew = caseData.caseList;
            
            
            caseData.processRequests();
            caseData.SendDates();
            
            }  
            test.stopTest();
        }
    
    }
    }