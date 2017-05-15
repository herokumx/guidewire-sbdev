/**********
Class: TaskTriggerUtil
Description: Task trigger utility to support operations Database operations on Task.

Created: 09/30/2015
Created By: Rohit Koul*/

public class TaskTriggerUtil { 
 
 // Send email notification to Task owner when a task is created using MH sheets.
 public static void sendEmailNotificationToTaskOwner(List<Task> taskListVar){
    List<Task> taskList = [select id,owner.Name,Who.Id,Subject,Priority,owner.email,OwnerId,CreatedById,CreatedBy.Name from Task where MH_Action__c = true and Id in: taskListVar];
	List<Messaging.SingleEmailMessage> smailList =  new List<Messaging.SingleEmailMessage>();
    String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
    for(Task task : taskList){ 
        if(task.OwnerId != task.CreatedById){
        Messaging.SingleEmailMessage smail =  new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(task.owner.email); 
        smail.setToAddresses(sendTo);
        smail.setsubject('New Task-' + task.Subject);
        smail.setHtmlBody('<style> .summary { font-family: Verdana, Arial, Helvetica; font-weight: bold; font-size: 18px; color: #0066cc; }  .main { font-family: Verdana, Arial, Helvetica; font-weight: normal; font-size: 12px; line-height: 18px; color: black; }</style>     <html>   <head>    <base href="'+sfdcBaseURL+'">    </head>   <body>     <table cellspacing="0" cellpadding="0" bgcolor="#FFFFFF" border="0" width="100%">  <tr><td width="100%">   <table cellspacing="0" cellpadding="10" border="0" width="100%">  <tr><td bgcolor="#FFFFFF">    <table cellspacing="0" cellpadding="0" border="0">    <td class="summary">New Task</td></tr>    </table>    </tr></td>       </table>      </td></tr>   <tr><td height="5"></td></tr>   <tr><td style="padding:0 10 0 10px;"><p class="main">   To:  '+task.owner.Name+'   <br><br>' +task.CreatedBy.Name+' has assigned you the following new task:<br><br>Subject: '+ task.Subject+'<br>Priority: '+task.Priority+'<br><br>For more details, click the following link:<br><br><a href="'+sfdcBaseURL+ '/' + task.ID +'" target="_blank"> '+sfdcBaseURL+ '/' + task.ID +' </a>   </p></td></tr>   </table>   </body>   </html>');     
        smailList.add(smail);
        }    
    }
    if(smailList.size()>0){
     Messaging.sendEmail(smailList);    
    }
 }

}