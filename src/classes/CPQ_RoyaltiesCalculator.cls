public with sharing class CPQ_RoyaltiesCalculator {

    public static void calculateRoyalties(Map<Id, SBQQ__Quote__c> mapId_QuoteRecord) {

        Set<Id> setQuoteIds = mapId_QuoteRecord.keySet();

        if( NULL == setQuoteIds ||  setQuoteIds.isEmpty()) {
            return;
        }

        List<SBQQ__Quote__c> lstQuoteWithItems = new List<SBQQ__Quote__c>();

        lstQuoteWithItems = [SELECT Id
                                  , CPQ_Royalties__c
                                  , (SELECT Id
                                          , SBQQ__Product__r.SKU_ID__c
                                       FROM SBQQ__LineItems__r)
                               FROM SBQQ__Quote__c
                              WHERE Id IN : setQuoteIds];

        for(SBQQ__Quote__c quoteIterator : lstQuoteWithItems) {

            if( !mapId_QuoteRecord.containsKey(quoteIterator.Id) ) {
                continue;
            }

            mapId_QuoteRecord.get(quoteIterator.Id).CPQ_Royalties__c = false;

            if( NULL == quoteIterator.SBQQ__LineItems__r  ||  quoteIterator.SBQQ__LineItems__r.isEmpty()) {
                continue;
            }

            for(SBQQ__QuoteLine__c quoteLineIterator : quoteIterator.SBQQ__LineItems__r) {

                if( String.isNotBlank(quoteLineIterator.SBQQ__Product__r.SKU_ID__c)
                &&  System.Label.CPQ_RoyaltySkus.containsIgnoreCase(quoteLineIterator.SBQQ__Product__r.SKU_ID__c)) {
                    mapId_QuoteRecord.get(quoteIterator.Id).CPQ_Royalties__c = true;
                }
            }
        }
    }
}