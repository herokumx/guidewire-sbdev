//Hari: 03/21 - Update to include Personal Transactions at the Transaction Level.

// personal Transactions with User Ids.

Global class CreditCardPersonal Implements Schedulable
{
   global void Execute(SchedulableContext sc)
  {
     CardTransactionItems();      
  } 
    
   public static void CardTransactionItems()
   {

     Map<Id, List<PSA_Card_Transaction__c >> ResourceTransMap = new Map<id, List<PSA_Card_Transaction__c >>();
    
    List<PSA_Card_Transaction__c > CardTransLst = [select id,name,PSA_Amount_in_Original_Currency__c,PSA_Charge_Type__c,PSA_Transaction_Date__c,PSA_EmployeeId__c,  Number_of_Personal_Transactions__c, PSA_Merchant_Name__c,   Personal_Card_Reimbursement_Amount__c,  PSA_Posting_Date__c,PSA_Card_Transaction_Stage__c,
                                                    PSA_Card_Transaction_Stage__r.PSA_Billing_Currency_Currency_Code__c, CurrencyISOcode, PSA_Resource__c,PSA_Resource__r.name,PSA_Salesforce_User__c, (select id,name, PSA_Charge_Type__c, CurrencyISOCode, PSA_Card_Transaction__c,PSA_Amount_in_Original_Currency__c, GW_Card_Reimbursement_Amount__c from PSA_Card_Transaction_Items__r where  PSA_Charge_Type__c ='Personal') 
                                                   from PSA_Card_Transaction__c where  PSA_Transaction_Date__c = last_month and ( PSA_Charge_Type__c ='Personal' or  PSA_Charge_Type__c ='Itemized')];
    
    for(PSA_Card_Transaction__c card : CardTransLst)
    {
        if(ResourceTransMap.containsKey(card.PSA_Salesforce_User__c))
        {
           List<PSA_Card_Transaction__c > newTransLst = ResourceTransMap.get(card.PSA_Salesforce_User__c);
           newTransLst.add(card);
           ResourceTransMap.put(card.PSA_Salesforce_User__c, newTransLst);
        }
        else
        {
            ResourceTransMap.put(card.PSA_Salesforce_User__c, new List<PSA_Card_Transaction__c > {card}); 
        } 
    }
      
  Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
    
  for(Id UserId : ResourceTransMap.keySet())
  {
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
     integer length = ResourceTransMap.get(UserId).size();
      
    /* string[] toAdd = new String[]{};
       toAdd.add('hyarapathineni@guidewire.com');
            
       mail.setCCAddresses(toAdd);
    */
      mail.setTargetObjectId(UserId);
      mail.setSaveAsActivity(false);
                      
      mail.setSubject('FinancialForce Personal Transactions');
      
      String Table = 'You have identified the following transactions as personal expenses within the last month. Please provide payment no later than the 14th of the month if you have not done so already. For instructions on how to provide payment, please see the “Personal Charges” section located within the <a href="https://gwire.sharepoint.com/Finance/Documents/GW CC Global Policy 121715.pdf">Corporate Credit Card Policy and Procedure Manual.</a> ';
                       
                             table=table+'<br>';
                             table=table+'<br>';
                             table =table+ '<u>Personal Transactions</u>';
                             table=table+'<br>';
                             table=table+'<br>';
                             table=table + '<table border="0" ><tr><td align="center"><b><u>Card Transaction Date</u></b></td><td align="center"><b><u>Vendor Name</u></b></td><td align="center"><b><u>Amount in Original Currency</u></b></td><td align="center"><b><u>Personal Expense Amount</u></b></td><td align="center"><b><u>Resource Name</u></b></td>';                                                            
                             for(integer i=0; i< length; i++)
                             { 
                               if(ResourceTransMap.get(UserId)[i].PSA_Charge_Type__c == 'Personal')
                               {
                                  table=table+'<tr>';
                                  table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Transaction_Date__c +' </td>';
                                  table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Merchant_Name__c + '</td>';  
                                  table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].currencyisocode +' '+ResourceTransMap.get(UserId)[i].PSA_Amount_in_Original_Currency__c +' </td>';
                                  table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].Personal_Card_Reimbursement_Amount__c +' </td>'; 
                                  table=table + '<td align="justify">' + ResourceTransMap.get(UserId)[i].PSA_Resource__r.name +' </td>';
                                  table=table+'</tr>'; 
                               }
                               if(ResourceTransMap.get(UserId)[i].PSA_Charge_Type__c == 'Itemized')
                               {
                                 for(integer j=0;j<ResourceTransMap.get(UserId)[i].Number_of_Personal_Transactions__c; j++)
                                 {
                                   table=table+'<tr>';
                                   table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Transaction_Date__c +' </td>';
                                   table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Merchant_Name__c + '</td>';  
                                   table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].PSA_Card_Transaction_Items__r[j].currencyisocode +' '+ ResourceTransMap.get(UserId)[i].PSA_Card_Transaction_Items__r[j].PSA_Amount_in_Original_Currency__c +' </td>';
                                   table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].PSA_Card_Transaction_Stage__r.PSA_Billing_Currency_Currency_Code__c +' '+ ResourceTransMap.get(UserId)[i].PSA_Card_Transaction_Items__r[j].GW_Card_Reimbursement_Amount__c.setscale(2) +' </td>';
                                   table=table + '<td align="justify">' + ResourceTransMap.get(UserId)[i].PSA_Resource__r.name +' </td>';
                                   table=table+'</tr>';
                                 }
                               }
                             
                             } 
                             table=table+'</table>';
                                          
       mail.setHtmlBody(table);
      
       emailMessageList.add(mail);  
  }
 Messaging.sendEmail(emailMessageList);
}
}






/*

// personal Transactions with User Ids.

Global class CreditCardPersonal Implements Schedulable
{
   global void Execute(SchedulableContext sc)
  {
     CardTransactionItems();      
  } 
    
   public static void CardTransactionItems()
   {

    Map<Id, List<PSA_Card_Transaction_Item__c>> ResourceTransMap = new Map<id, List<PSA_Card_Transaction_Item__c>>();
    
    List<PSA_Card_Transaction_Item__c> CardTransLst = [select id,name, PSA_Charge_Type__c, PSA_Card_Transaction__c,PSA_Card_Transaction__r.PSA_Salesforce_User__c,PSA_Card_Transaction__r.PSA_Salesforce_User__r.email, PSA_Card_Transaction__r.PSA_Resource__c, 
                                                       PSA_Card_Transaction__r.PSA_Resource__r.email,PSA_Card_Transaction__r.PSA_Resource__r.name, PSA_Card_Transaction__r.PSA_Merchant_Name__c,PSA_Amount_in_Original_Currency__c, GW_Card_Reimbursement_Amount__c,
                                                       PSA_Card_Transaction__r.PSA_Transaction_Date__c from PSA_Card_Transaction_Item__c where PSA_Charge_Type__c ='Personal' and PSA_Card_Transaction__r.PSA_Transaction_Date__c = last_month];
    
    for(PSA_Card_Transaction_Item__c card : CardTransLst)
    {
        if(ResourceTransMap.containsKey(card.PSA_Card_Transaction__r.PSA_Salesforce_User__c))
        {
           List<PSA_Card_Transaction_Item__c> newTransLst = ResourceTransMap.get(card.PSA_Card_Transaction__r.PSA_Salesforce_User__c);
           newTransLst.add(card);
           ResourceTransMap.put(card.PSA_Card_Transaction__r.PSA_Salesforce_User__c, newTransLst);
        }
        else
        {
            ResourceTransMap.put(card.PSA_Card_Transaction__r.PSA_Salesforce_User__c, new List<PSA_Card_Transaction_Item__c> {card}); 
        } 
    }
      
  Messaging.SingleEmailMessage[] emailMessageList = new Messaging.SingleEmailMessage[]{};
    
  for(Id UserId : ResourceTransMap.keySet())
  {
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
     integer length = ResourceTransMap.get(UserId).size();
      
      mail.setTargetObjectId(UserId);
      mail.setSaveAsActivity(false);
                      
      mail.setSubject('FinancialForce Personal Transactions');
      
      String Table = 'You have identified the following expenses as personal expenses. Please log into the Bank of America Portal to provide payment no later than the 14th of the month if you have not done so already.';
                            
                             table=table+'<br>';
                             table=table+'<br>';
                             table =table+ '<u>Personal Transactions</u>';
                             table=table+'<br>';
                             table=table+'<br>';
                             table=table + '<table border="0" ><tr><td align="center"><b><u>Card Transaction Date</u></b></td><td align="center"><b><u>Vendor Name</u></b></td><td align="center"><b><u>Amount in Original Currency</u></b></td><td align="center"><b><u>Resource Name</u></b></td>';                                                            
                             for(integer i=0; i< length; i++)
                             {  
                             table=table+'<tr>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Card_Transaction__r.PSA_Transaction_Date__c +' </td>';
                             table=table + '<td align="Justify">' + ResourceTransMap.get(UserId)[i].PSA_Card_Transaction__r.PSA_Merchant_Name__c + '</td>';  
                             table=table + '<td align="center">' + ResourceTransMap.get(UserId)[i].PSA_Amount_in_Original_Currency__c +' </td>';
                             table=table + '<td align="justify">' + ResourceTransMap.get(UserId)[i].PSA_Card_Transaction__r.PSA_Resource__r.name +' </td>';
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