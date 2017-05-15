/*
    *****************************************************************************************************************************
    Class Name - CS_ContactACPSynchTest
    Class Type -  Trigger Handler Test Class
    Test Class-
    Purpose- 
    
    *****************************************************************************************************************************
    
    Name        Email              Date             Notes 
    Suchitra                                        Initial Creation
    
    *****************************************************************************************************************************
    */
    
    @isTest
    
    private class CS_ContactACPSynchTest{
    
        static testMethod void CS_ContactACPSynchTest() {
        
        
            test.StartTest();
            
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
            Contact con = CS_TestDataUtility.createProspectContact(acc);
            
            //create service contract 
            ServiceContract sc = CS_TestDataUtility.createServiceContract(acc);  
            
            //create service contracl line items 
            ContractLineItem cntractLineItem =  CS_TestDataUtility.createServiceContractLineItem(sc,  pbe) ;  
            
            CS_ByPass__c byPassValidation = new CS_ByPass__c();
            byPassValidation.Name = 'CS_Disable_ValidationRule__c';
            byPassValidation.SetupOwnerId = UserInfo.getUserId();
            byPassValidation.CS_Disable_ValidationRule__c = true;
            insert byPassValidation;
            
            Map<String,String> mapOfRecordType = GWUtilities.getRecordTypeId('Contact'); 
              
            con.RecordTypeId =  mapOfRecordType.get('Support');
            update con;
            
            test.stopTest();
            }  
            
        }