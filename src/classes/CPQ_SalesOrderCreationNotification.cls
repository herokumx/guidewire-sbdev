global with sharing class CPQ_SalesOrderCreationNotification {

    public final static String ERROR_IN_DATA = 'There was an error in data received.';
    public final static String ORDER_NOT_FOUND = 'The selected order could not be found.';
    public final static String EMAIL_EXCEPTION = 'Attempt to send the email failed. Please share following message with your admin: \n{0}';
    public final static String SUCCESS = 'Email sent successfully.';
    public final static String BASE_URL = URL.getSalesforceBaseUrl().toExternalForm() + '/';

    // public CPQ_SalesOrderCreationNotification() {
    //     // @TODO: Nothing
    // }

    webservice static String notifyRevTeam(Id pOrderId) {

        if(String.isBlank(pOrderId)) {
            return ERROR_IN_DATA;
        }

        List<Order> lstCurrentOrder = [SELECT Id
                                            , SBQQ__Quote__c
                                            , OpportunityId
                                            , SBQQ__Quote__r.Owner.Name
                                            , SBQQ__Quote__r.Owner.Email
                                         FROM Order
                                        WHERE Id = : pOrderId];

        if(lstCurrentOrder.isEmpty()) {
            return ORDER_NOT_FOUND;
        }

        Messaging.SingleEmailMessage emailInstance = new Messaging.SingleEmailMessage();

        emailInstance.setSenderDisplayName(lstCurrentOrder[0].SBQQ__Quote__r.Owner.Name);
        emailInstance.setReplyTo(lstCurrentOrder[0].SBQQ__Quote__r.Owner.Email);
        emailInstance.setToAddresses( new List<String>{System.Label.CPQ_SOCrationMailRecepient} );
        emailInstance.setBccAddresses( new List<String>{UserInfo.getUserEmail()} );

        List<String> lstMailContents = new List<String> {
            BASE_URL + lstCurrentOrder[0].Id,
            BASE_URL + lstCurrentOrder[0].SBQQ__Quote__c,
            BASE_URL + lstCurrentOrder[0].OpportunityId,
            lstCurrentOrder[0].SBQQ__Quote__r.Owner.Name
        };

        emailInstance.setPlainTextBody(String.format(System.Label.CPQ_SOCrationMailBody.replace('<nl>', '\n'), lstMailContents));
        emailInstance.setSubject(System.Label.CPQ_SOCrationMailSubject);

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { emailInstance });
        } catch(EmailException exceptionInstance) {
            return String.format(EMAIL_EXCEPTION, new List<String>{exceptionInstance.getMessage()});
        }

        return SUCCESS;
    }
}