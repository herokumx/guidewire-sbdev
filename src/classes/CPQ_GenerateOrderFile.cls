global with sharing class CPQ_GenerateOrderFile {

    public static final String STR_ORDER_COLUMNS = Label.CPQ_GenerateOrder;//list of column names for csv
    public static final String STR_MESSAGE = 'message';//message
    public static final String STR_FILENAME = 'Sales Order Document.csv';//message

    public static final Map<String, Schema.SObjectField> MAPFIELD_META =
        Schema.SObjectType.CPQ_Billing_Schedule__c.fields.getMap();

    /**
     * Method to Create Sales Order from Button on opportunity
     */
    Webservice static String createOrderAttachment(Id pOrderId) {

        Set<String> setBillingScheduleFields = MAPFIELD_META.keySet();
        Set<String> setBillingSch = new Set<String>();
        String newBillingSceduleField ;
        String bsQuery = 'SELECT ';

        bsQuery += String.join(new List<String>(setBillingScheduleFields), ', ');

        bsQuery += ' , Order__r.Wire_Message__r.Message__c FROM CPQ_Billing_Schedule__c WHERE Order__c = : pOrderId ';

        List<CPQ_Billing_Schedule__c> lstBillingSchedules = (List<CPQ_Billing_Schedule__c>) Database.query(bsQuery);

        if(lstBillingSchedules != null && !lstBillingSchedules.IsEmpty() && lstBillingSchedules[0].Order__c !=null) {
            String strHeader = STR_ORDER_COLUMNS.remove('__c') + '\n';
            String finalstr = strHeader ;
            List<String> strFieldNamelist = STR_ORDER_COLUMNS.deleteWhitespace().split(',');
            String recordString ='';
            String strWireMsg = '';
            if(lstBillingSchedules[0].Order__r.Wire_Message__c != null && lstBillingSchedules[0].Order__r.Wire_Message__r.Message__c != null) {
                strWireMsg = lstBillingSchedules[0].Order__r.Wire_Message__r.Message__c;
            }
            for(CPQ_Billing_Schedule__c objBillingSched:lstBillingSchedules) {
                for(String strFieldAPIName: strFieldNamelist) {
                    if(!strFieldAPIName.equalsIgnoreCase(STR_MESSAGE)) {
                        if(objBillingSched.get(strFieldAPIName) != null) {
                            recordString += String.valueOf(objBillingSched.get(strFieldAPIName)).escapeCsv() + ',';
                        } else {
                            setBillingSch.add(MAPFIELD_META.get(strFieldAPIName).getDescribe().getLabel());
                        }
                    } else if(STR_MESSAGE.equalsIgnoreCase(strFieldAPIName) && String.isNotBlank(strWireMsg)) {
                        recordString += strWireMsg.escapeCsv() + ',';
                    } else if(STR_MESSAGE.equalsIgnoreCase(strFieldAPIName) && String.isBlank(strWireMsg)) {
                        setBillingSch.add('Order > Wire Message');
                    } else {
                        recordString += ''+ ',';
                    }
                    recordString += '\n';
                }
                finalstr = finalstr + recordString;
            }
            if(!setBillingSch.isEmpty()) {
                newBillingSceduleField = String.join(new List<String>(setBillingSch), ', ');
            }
            if(String.isBlank(newBillingSceduleField)) {
                Attachment attachment = new Attachment();
                attachment.Body = Blob.valueOf(finalstr);
                attachment.Name = STR_FILENAME;
                attachment.ParentId = lstBillingSchedules[0].Order__c;
                try {
                    insert attachment;
                } catch(DmlException exceptionInstance) {
                    System.debug('Exception occurred : ' + exceptionInstance.getMessage());
                }
            }
        }
        return newBillingSceduleField;
    }
}