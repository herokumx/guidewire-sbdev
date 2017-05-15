public class ServicesDirectorEmailHandler 
{   
    public static void SalesEventEmail(id userid, string usrname, sales_event__c salesEvent )
    {
        string url = Label.Valid_URL;
        
        String startDate = '';
        String endDate = '';
        Time t1 = Time.newInstance(0, 0, 0, 0);
        
        if(salesevent.Confirmed_Start_Date__c != null)
        startDate = Datetime.newInstance(salesevent.Confirmed_Start_Date__c, t1).format('YYYY-MM-dd');
                    
        if(salesevent.Confirmed_End_Date__c != null)
        endDate = Datetime.newInstance(salesevent.Confirmed_End_Date__c, t1).format('YYYY-MM-dd');
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        
        message.setSaveAsActivity(false);
        message.setTargetObjectId(userid);
        message.setSubject('A new Sales Event has been created for the '+salesevent.Opportunity__r.Name+'');
        message.setHtmlbody('Hello&nbsp'+usrname+', <br> <br> This is to notify that a new Sales Event is created for the opportunity: <a href=" '+url+'/'+Salesevent.Opportunity__c+' ">'
                            +salesevent.Opportunity__r.Name+' </a> <br><br> <table align="left"> <tr> <td> Event:</td> <td>'
                            +salesevent.Name+'</td> </tr> <tr> <td> Event Type: </td> <td>'+salesevent.Event_Type__c+
                            '</td> </tr><tr> <td> Stage: </td> <td> '+salesevent.Opportunity__r.stageName+'</td> </tr> <tr> <td> Presentation Type:</td> <td> '+salesevent.Presentation_Type__c+
                           '</td> </tr> <tr> <td> Location: </td> <td>'+salesevent.Location__c+'</td> </tr> <tr> <td> Start Date: </td> <td>'
                            +startdate+'</td> </tr> <tr> <td> End Date: </td> <td>'
                            +enddate+'</td> </tr><tr> </tr> <tr>  Event Goals: <br><br>'+salesevent.Event_Goals__c+
                           '</tr> <tr> Thank you. </tr> </table>');
        
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] {message});
        
    }
    
    public static void ResourceRequestEmail(id userid, string usrname, ResourceRequest__c ResReqst)
    {
        string url = Label.Valid_URL;
        
        String InternalDate = '';
        String externalDate = '';
        String ReceivedDate ='';
        Time t1 = Time.newInstance(0, 0, 0, 0);
        
        if(resreqst.RFx_Received__c != null)
        ReceivedDate = Datetime.newInstance(resreqst.RFx_Received__c, t1).format('YYYY-MM-dd');
                    
        if(resreqst.RFx_Internal_Due__c != null)
        InternalDate = Datetime.newInstance(resreqst.RFx_Internal_Due__c, t1).format('YYYY-MM-dd');
        
        if(resreqst.RFx_External_Due__c != null)
        externalDate = Datetime.newInstance(resreqst.RFx_External_Due__c, t1).format('YYYY-MM-dd');
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        
        message.setSaveAsActivity(false);
        message.setTargetObjectId(userid);
        message.setSubject('A new Resource Request has been created for the '+ResReqst.Opportunity__r.Name+'');
        message.setHtmlbody('Hello&nbsp'+usrname+', <br> <br> This is to notify that a new Resource Request is created for the opportunity: <a href=" '+url+'/'+ResReqst.Opportunity__c+' ">'
                            +ResReqst.Opportunity__r.Name+' </a> <br><br> <table align="left"> <tr> <td> Event:</td> <td>'
                            +ResReqst.Name+'</td> </tr> <tr> <td> Event Type: </td> <td>'+ResReqst.Event_Type__c+
                            '</td> </tr><tr> <td> Stage: </td> <td> '+ResReqst.Opportunity__r.stageName+'</td> </tr> <tr> <td> Presentation Type:</td> <td> '
                            +ResReqst.Presentation_Type__c+'<tr> <td> Status:</td> <td> '+ResReqst.Status__c+'</td> </tr> <tr> <td> Location: </td> <td>'
                            +ResReqst.Location__c+'</td> </tr> <tr> <td> RFP Received Date: </td> <td>'
                            +ReceivedDate+'</td> </tr> <tr> <td>  RFP Internal Due Date: </td> <td>'
                            +InternalDate+'</td> </tr> <tr> <td> RFP External Due Date: </td> <td>'
                            +externalDate+'</td> </tr> <tr> </tr> <tr>  Event Goals: <br><br>'+ResReqst.Event_Goals__c+
                           '</tr> <tr> Thank you. </tr> </table>');
        
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] {message});
     }   

}