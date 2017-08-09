global with sharing class CPQ_GenerateOrderFile {

    public static final String STR_ORDER_COLUMNS = 'transactiontype__c,datecreated__c,customerid__c,l_customerid__c,message,referenceno__c,termname__c,shippingmethod__c,shipto__c,billto__c,basecurr__c,currency__c,exchratetype__c,ch_License_Type__c,ch_Warranty_Period__c,quantity__c,unit__c,locationid__c,departmentid__c,l_classid__c,ch_Baseline_Measure__c,ch_AUTO_RENEWAL__c,ch_Term_Years__c,ch_Escalation_on_Fees__c,ch_Escalation_Effective_Period__c,ch_Escalation_Description__c,ch_Growth_Rate_Clause__c,ch_Reduction_Rate_Clause__c,ch_Notification_Required__c,ch_Notification_Period__c,ch_Perpetual_Buyout_Option__c,ch_Growth_Rate_Buffer__c,ch_Reduction_Rate_Buffer__c,itemdesc_original__c,itemid__c,l_employeeid__c,price__c,memo__c,revrectemplate__c,revrecstartdate__c,revrecenddate__c,startdate__c,modenew__c,eom__c,Software_Delivery_Date__c,PO_Number__c,Out_Clause_Date__c,Contract_Ref_Number__c,Oppty_Id__c,Contract_Sign_Date__c,Payment_Due__c,Order_Type__c,Original_Order_Number__c,Bill_To_Customer_Id__c,Timestamp_for_Order_Upload__c,Sales_Order_End_Date__c,List_Price__c,Subscription_Term_Duration__c,Prorated_Support_Cost__c,Support_Distribution__c,Contract_Effective_Date__c,Royalties__c,Perpetual_Buyout_Option__c,OrderNumber__c'; // list of column names for csv
    public static final String STR_MESSAGE = 'message'; // message
    public static final String STR_FILENAME = 'Sales Order Document_{0}.csv'; // filename

    public static final Map<String, Schema.SObjectField> MAPFIELD_META =
        Schema.SObjectType.CPQ_Billing_Schedule__c.fields.getMap();

    /**
     * Method to Create Sales Order from Button on opportunity
     */
    Webservice static void createOrderAttachment(Id pOrderId) {

        Set<String> setBillingScheduleFields = MAPFIELD_META.keySet();
        String newBillingSceduleField ;
        String bsQuery = 'SELECT ';

        bsQuery += String.join(new List<String>(setBillingScheduleFields), ', ');

        bsQuery += ' , Order__r.Wire_Message__r.Message__c FROM CPQ_Billing_Schedule__c WHERE Order__c = : pOrderId ';

        List<CPQ_Billing_Schedule__c> lstBillingSchedules = (List<CPQ_Billing_Schedule__c>) Database.query(bsQuery);

        if(lstBillingSchedules != null && !lstBillingSchedules.isEmpty() && lstBillingSchedules[0].Order__c != null) {
            String strHeader = STR_ORDER_COLUMNS.deleteWhitespace().remove('__c') + '\n';
            strHeader = strHeader.replace('referenceno', 'Product Name');
            String finalstr = strHeader ;
            List<String> strFieldNamelist = STR_ORDER_COLUMNS.deleteWhitespace().split(',');
            String recordString = '';
            String strWireMsg = '';
            if(lstBillingSchedules[0].Order__r.Wire_Message__c != null && lstBillingSchedules[0].Order__r.Wire_Message__r.Message__c != null) {
                strWireMsg = lstBillingSchedules[0].Order__r.Wire_Message__r.Message__c;
            }
            for(CPQ_Billing_Schedule__c objBillingSched:lstBillingSchedules) {
                for(String strFieldAPIName : strFieldNamelist) {

                    if(!strFieldAPIName.equalsIgnoreCase(STR_MESSAGE) && objBillingSched.get(strFieldAPIName) != null) {
                        if(MAPFIELD_META.get(strFieldAPIName).getDescribe().getType() == Schema.DisplayType.Date) {
                            /*recordString += DateTime.newInstance((Date) objBillingSched.get(strFieldAPIName), Time.newInstance(0,0,0,0)).format('M/dd/yyyy').escapeCsv() + ',';*/
                            recordString += ((Date) objBillingSched.get(strFieldAPIName)).format().escapeCsv() + ',';
                        } else if(strFieldAPIName.equalsIgnoreCase('datecreated__c')) {
                            recordString += ((Datetime) objBillingSched.get(strFieldAPIName)).format('M/dd/yyyy').escapeCsv() + ',';
                        } else if(MAPFIELD_META.get(strFieldAPIName).getDescribe().getType() == Schema.DisplayType.Datetime) {
                            recordString += ((Datetime) objBillingSched.get(strFieldAPIName)).format('M/dd/yyyy HH:mm').escapeCsv() + ',';
                        } else if(MAPFIELD_META.get(strFieldAPIName).getDescribe().getType() == Schema.DisplayType.Percent) {
                            recordString += ((Double) objBillingSched.get(strFieldAPIName)) + '%,';
                        } else {
                            recordString += String.valueOf(objBillingSched.get(strFieldAPIName)).escapeCsv() + ',';
                        }
                    } else if(STR_MESSAGE.equalsIgnoreCase(strFieldAPIName) && String.isNotBlank(strWireMsg)) {
                        recordString += strWireMsg.escapeCsv() + ',';
                    } else {
                        recordString += ''+ ',';
                    }
                }
                recordString += '\n';
            }
            finalstr = finalstr + recordString;
            Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf(finalstr);
            attachment.Name = String.format(STR_FILENAME, new List<String> { Datetime.now().format('yyyyMMdd_HH_mm') });
            attachment.ParentId = lstBillingSchedules[0].Order__c;
            try {
                insert attachment;
            } catch(DmlException exceptionInstance) {
                System.debug('Exception occurred : ' + exceptionInstance.getMessage());
            }
        }
    }
}