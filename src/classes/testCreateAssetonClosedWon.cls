@isTest 

private class testCreateAssetonClosedWon {
    
    static testMethod void testCreateAssetonClosedWon(){
        
        // create product/pbe for USD
        Product2 p = new Product2(name = 'testing', isactive = true);
        insert p;
        // add to standard PBE
        Pricebook2 std = [select id from Pricebook2 where isstandard = true];
        Pricebookentry pbe = new Pricebookentry(product2id = p.id, pricebook2id = std.id, unitprice = 2, currencyisocode = 'USD', isactive = true);
        insert pbe;
        Account a = [select Id from Account limit 1];

        Opportunity o = new Opportunity();
        OpportunityLineItem ol = new OpportunityLineItem();
        
        o.AccountId = a.Id;
        o.Name = 'test';
        o.StageName = 'Prospecting';
        o.CloseDate = date.today();
        o.currencyisocode = 'USD';
        o.Deal_type__c = 'sample';
        o.payment_cycle__c = 'annual';
        o.amount = 1;
        insert o;
        o = [select id, stagename, currencyisocode from Opportunity where id = :o.id];
        
        ol.OpportunityId = o.Id;
        ol.Quantity = 1;
        ol.UnitPrice = 2.00;
        ol.PricebookEntryId = pbe.Id;
        
        insert ol;
        
        o.StageName= 'Closed Won';
        update o;
        
        // method is not actually testing that an asset was created succesfully... [Niki Vankerk]
       // delete ol;
       // delete o;
        
        
        
    }
    
    
}