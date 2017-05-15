// Unassigned transactions with User Ids.

Global class CreditCardTransUnassigned Implements Schedulable
{
  global void Execute(SchedulableContext sc)
  {
     CardTransactions();      
  }
    
  public static void CardTransactions()
  {

    Map<id, List<PSA_Card_Transaction__c>> ResourceTransMap = new Map<id, List<PSA_Card_Transaction__c>>();
    
    List<PSA_Card_Transaction__c> CardTransLst = [Select id,PSA_Expense_Report__c,PSA_Expense_Report__r.pse__Status__c, PSA_Salesforce_User__c,PSA_Salesforce_User__r.email,PSA_Resource__c,PSA_Resource__r.email,PSA_Resource__r.name, PSA_Merchant_Name__c, 
                                              PSA_Amount_in_Billing_Currency__c,PSA_Amount_in_Original_Currency__c,PSA_Transaction_Date__c
                                              from PSA_Card_Transaction__c where PSA_Salesforce_User__c != Null and (PSA_Expense_Report__c = Null or PSA_Expense_Report__r.pse__Status__c ='Draft') and PSA_Charge_Type__c != 'Personal' and PSA_Previously_Entered__c != true ];
    
    for(PSA_Card_Transaction__c card : CardTransLst)
    {
        if(ResourceTransMap.containsKey(card.PSA_Salesforce_User__c))
        {
           List<PSA_Card_Transaction__c> newTransLst = ResourceTransMap.get(card.PSA_Salesforce_User__c);
           newTransLst.add(card);
           ResourceTransMap.put(card.PSA_Salesforce_User__c, newTransLst);
        }
        else
        {
            ResourceTransMap.put(card.PSA_Salesforce_User__c, new List<PSA_Card_Transaction__c> {card}); 
        } 
    }
      
  Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
    
  for(Id UserId : ResourceTransMap.keySet())
  {
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
     integer length = ResourceTransMap.get(UserId).size();
      
      mail.setTargetObjectId(UserId);
      
      mail.setSaveAsActivity(false);   
      
    /*  string[] toAdd = new String[]{};
      toAdd.add('hyarapathineni@guidewire.com');
      //toAdd.add('NMcGinn@guidewire.com');      
      
      mail.setCCAddresses(toAdd);
    */
      
      mail.setSubject('FinancialForce Expense Transactions to be Reviewed');
      
           
      String Table = 'This is to inform you that you either have not submitted expense reports or credit card transactions have not been assigned to an expense report. Transactions are listed below for your reference, and you may login to FinancialForce to see your outstanding expense reports.';
                            
                             table=table+'<br>';
                             table=table+'<br>';
                             table =table+ '<u>Company Card Transactions</u>';
                             table=table+'<br>';
                             table=table+'<br>';
                             table=table + '<table border="0" ><tr><td align="center"><b><u>Transaction Date</u></b></td><td align="center"><b><u>Vendor Name</u></b></td><td align="center"><b><u>Amount in Original Currency</u></b></td><td align="center"><b><u>Amount in Billing Currency</u></b></td><td align="center"><b><u>Resource Name</u></b></td>';                                                            
                             for(integer i=0; i< length; i++)
                             {  
                             table=table+'<tr>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Transaction_Date__c +' </td>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Merchant_Name__c + '</td>';  
                             table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].PSA_Amount_in_Original_Currency__c +' </td>';
                             table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].PSA_Amount_in_Billing_Currency__c + '</td>'; 
                             table=table + '<td align="justify">' + ResourceTransMap.get(UserId)[i].PSA_Resource__r.name +' </td>';
                             table=table+'</tr>';
                             } 
                             table=table+'</table>';
                                          
       mail.setHtmlBody(table);
      
       emailMessageList.add(mail);  
  }
 Messaging.sendEmail(emailMessageList);
 }
}





/*

// Unassigned transactions with Resource Email ids.

public class CreditCardTransUnassigned
{
  public void CardTransactions()
  {
  
    Map<string, List<PSA_Card_Transaction__c>> ResourceTransMap = new Map<string, List<PSA_Card_Transaction__c>>();
    
    List<PSA_Card_Transaction__c> CardTransLst = [Select id,PSA_Expense_Report__c,PSA_Expense_Report__r.pse__Status__c, PSA_Resource__c,PSA_Resource__r.email,PSA_Resource__r.name, PSA_Merchant_Name__c, 
                                              PSA_Amount_in_Billing_Currency__c,PSA_Amount_in_Original_Currency__c,PSA_Transaction_Date__c
                                              from PSA_Card_Transaction__c where (PSA_Expense_Report__c = Null or PSA_Expense_Report__r.pse__Status__c ='Draft') ];
    
    for(PSA_Card_Transaction__c card : CardTransLst)
    {
        if(ResourceTransMap.containsKey(card.PSA_Resource__r.email))
        {
           List<PSA_Card_Transaction__c> newTransLst = ResourceTransMap.get(card.PSA_Resource__r.email);
           newTransLst.add(card);
           ResourceTransMap.put(card.PSA_Resource__r.email, newTransLst);
        }
        else
        {
            ResourceTransMap.put(card.PSA_Resource__r.email, new List<PSA_Card_Transaction__c> {card}); 
        } 
    }
      
  Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
    
  for(String ResEmail : ResourceTransMap.keySet())
  {
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
     integer length = ResourceTransMap.get(ResEmail).size();
     string[] toAdd = new String[]{};
     toAdd.add(ResEmail);      
      
      mail.setToAddresses(toAdd);
                      
      mail.setSubject('Unassigned Transactions');
      
      String Table = 'This is to inform you that you either have not submitted expense reports or credit card transactions that have not been assigned to an expense report. Transactions are listed below for your reference, and you may login to FinancialForce to see your outstanding expense reports.';
                            
                             table=table+'<br>';
                             table=table+'<br>';
                             table =table+ '<u>Company Card Transactions</u>';
                             table=table+'<br>';
                             table=table+'<br>';
                             table=table + '<table border="0" ><tr><td align="center"><b><u>Transaction Date</u></b></td><td align="center"><b><u>Vendor Name</u></b></td><td align="center"><b><u>Amount in Original Currency</u></b></td><td align="center"><b><u>Amount in Billing Currency</u></b></td><td align="center"><b><u>Resource Name</u></b></td>';                                                            
                             for(integer i=0; i< length; i++)
                             {  
                             table=table+'<tr>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(ResEmail)[i].PSA_Transaction_Date__c +' </td>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(ResEmail)[i].PSA_Merchant_Name__c + '</td>';  
                             table=table + '<td align="center">' + ResourceTransMap.get(ResEmail)[i].PSA_Amount_in_Original_Currency__c +' </td>';
                             table=table + '<td align="center">' + ResourceTransMap.get(ResEmail)[i].PSA_Amount_in_Billing_Currency__c + '</td>'; 
                             table=table + '<td align="justify">' + ResourceTransMap.get(ResEmail)[i].PSA_Resource__r.name +' </td>';
                             table=table+'</tr>';
                             } 
                             table=table+'</table>';
                                          
       mail.setHtmlBody(table);
      
       emailMessageList.add(mail);  
  }
 Messaging.sendEmail(emailMessageList);

 }
}
*/