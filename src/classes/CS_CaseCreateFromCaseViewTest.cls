@isTest
private class CS_CaseCreateFromCaseViewTest 
{
    private static testmethod void caseCreation() 
    {
        Account a = psaTestUtils.createTestAccount('Test Account', '98675');
        a.Participant_id__c = '8796';
        update a;
        
       Contact c = CS_TestDataUtility.createContact(a,'General Customer');
        
        Product2 pd = new Product2();
        pd.Name='TestProduct1'; 
        pd.ProductCode='TEPD1';
        pd.Product_Group_Name__c = 'BillingCenter Group';
        insert pd;
        
         CS_Release__c release = new CS_Release__c();
         release.CS_Product__c = pd.Id;
         release.CS_IsActive__c = true;
         release.CS_Major_Release_version__c = '8';
         release.CS_Minor_Release_Version__c ='1';
         insert release;
        
        Asset parentAsset = new Asset();
        parentAsset.Name='TestParentAssetProspect1'; 
                                     parentAsset.AccountId=a.Id; 
                                     parentAsset.CS_Support_Group__c='Billing System';
                                     parentAsset.Status = 'Prospect';
                                     parentAsset.CS_Is_Active__c = true;
        insert parentAsset;
        
        Asset childAst = CS_TestDataUtility.createChildAssetWithRelease(a,pd,parentAsset,release,'active');
        
       Case cs = new Case(); 
        
       ApexPages.StandardController sc = new ApexPages.StandardController(cs);

       CS_CaseCreateFromCaseView disCon = new CS_CaseCreateFromCaseView(sc);
       
       
                            
       test.starttest(); 
       
         disCon.setAset(childAst.Id);
         disCon.setProduct(Pd.Id);
         disCon.getProduct();
         disCon.getAset();
         List<SelectOption> assets = disCon.getAssetList();   
         List<SelectOption> versions = disCon.getVersionList();   
         List<SelectOption> products = disCon.getProductList();     
         PageReference redirect = disCon.redirect();           
         PageReference result = disCon.saveMe(); 
         
       test.stopTest();
    }
}