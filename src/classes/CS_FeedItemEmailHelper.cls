/*
*****************************************************************************************************************************
Class Name - CS_FeedItemEmailHelper
Class Type -  Helper Class
Test Class-
Purpose- Feed Item Helper for email notification on Public and Private Feed on Case Record

*****************************************************************************************************************************

Name            Email              Date             Notes 
Alice jones                                         Initial Creation
Mani G                           08/30/2016        Fixed code for Defect DE181
Mani G                           08/31/2016        Fixed code for Defect DE482
Mani G                           09/01/2016        Added Customer Case COntact Role to Email Ignore list
Mani G                           09/08/2016        Bug Fix for DE614
Mani G                           09/20/2016        Bug Fix for DE884
*****************************************************************************************************************************
*/
public without  sharing class CS_FeedItemEmailHelper {
    public Set < String > noDuplicates = new Set < String > ();

    private String emailTemplateType;
    private static string replyToAddress='noreply@salesforce.com';
    private OrgWideEmailAddress CommunityEmailAddress;

    public CS_FeedItemEmailHelper() {

    }

    public void SendCaseFeedEmail(List < FeedItem > newTrigger) {
        system.debug('Entered Case Feed Comment');
        Set < id > parentCaseIds = new Set < id > ();
        Set < id > CommentedUsers = new Set < id > (); // To set the reply-to Address

        List < FeedItem > isValidFeed = new List < FeedItem > ();

        for (FeedItem CC: newTrigger) {
            if (String.valueOf(CC.ParentId.getSObjectType()) == 'Case') //Only if comment is public, send out emails 
            {
                isValidFeed.add(CC);
                parentCaseIds.add(CC.ParentId);
                CommentedUsers.add(CC.CreatedById);
                if(cc.Visibility == 'InternalUsers') {

                    emailTemplateType ='InternalUsers';
                }
                else {

                    emailTemplateType ='AllUsers';   
                }

            }
        }

        if (isValidFeed.size() > 0) {
            for (FeedItem CC: isValidFeed) {
                Case currentCase = new Case();
                //String replytoAddress;
                List < Id > toMemberIds = new List < Id > ();
                //List < String > ccAddresses = new List < String > ();
                //List < String > bccAddresses = new List < String > ();
                String bodyText;
                
                currentCase = [sELECT Id, ownerid,CS_Recent_Private_Comment__c,
                                          CS_Recent_Private_Comment_Postedby__c,
                                          CS_Recent_Private_Comment_Posteddate__c,
                                          CS_Recent_Public_Comment_Postedby__c,
                                          CS_Recent_Public_Comment_Posteddate__c,
                                          CS_Recent_Public_Case_Comment__c,CS_Asset_Name__c,
                                          Description, CaseNumber,Asset.name,Owner.name,
                                          Subject,CS_Urgency__c,Environment_Affected__c,Severity__c,Status,
                                          Asset.CS_Organization__c,Contact.name,Contact.email,contact.phone,CS_Case_Url__c, 
                                          CS_Associated_Jira_URL__c,IsEscalated, CS_Case_Thread__c
                                FROM Case
                                WHERE Id =: CC.ParentId limit 1];
                // Adding Case Owner to Email Recipients DE884            
              
                if(string.valueOf(currentCase.OwnerId).startsWith('005')) {             
                        System.debug('++++Case Owner is ++++' +currentCase.OwnerId );
                        toMemberIds.add(currentCase.Ownerid);
                }



                List < CaseTeamMember > caseTeamMembers = new List < CaseTeamMember > ([SELECT Id, Member.Id, Member.Email, TeamRole.Name
                    FROM CaseTeamMember
                    WHERE ParentId =: CC.ParentId
                    AND TeamRole.Name
                    NOT IN('Customer Case Contact','Customer Support', 'Customer Support View Only', 'Partner')
                ]);
                system.debug('CTM===' + caseTeamMembers);
             
                noDuplicates.add(currentCase.Contact.Email);
                system.debug('noDuplicates ='+noDuplicates);
                for (CaseTeamMember member: caseTeamMembers) {
                    system.debug('member email==' + member.member.email +' Team Role==' + member.TeamRole.Name + 'Dup Check==' + noDuplicates);
                    if(member.Member.Email != null && isNewAddress(member.Member.Email) ){

/*
                        if(member.TeamRole.Name == 'Customer Case Contact') {
                            System.debug('Adding  CCC to Member Id' +member.Member.Email);
                            toMemberIds.add(member.Member.Id);
                        }
                        */
                        if (member.TeamRole.Name == 'GW Watcher') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Follow the Sun') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Leads') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Collaborator') {
                            toMemberIds.add(member.Member.Id);
                        }
                    }
                }

                system.debug('CTM toMemberIds=' +toMemberIds);
                
                List < EntitySubscription > followers = new List < EntitySubscription > ([SELECT Id, SubscriberId, Subscriber.Email
                                                                                            FROM EntitySubscription
                                                                                            WHERE ParentId =: CC.ParentId
                                                                                            AND SubscriberId NOT IN 
                                                                                               (SELECT Id FROM User WHERE Profile.Name IN ('GW Customer Community','GW Partner Community', 'GW Services'))
                                                                                            LIMIT 1000]);
                for (EntitySubscription follower: followers) {
                    if (follower.Subscriber.Email != null && isNewAddress(follower.Subscriber.Email)) {
                        toMemberIds.add(follower.SubscriberId);
                    }
                }
                
                

                        
                
                
                system.debug('toMemberIds=' +toMemberIds);
                if (toMemberIds != null ) {
                    SendCommentEmail(toMemberIds,replyToAddress, currentCase, CC.Body, emailTemplateType);
                }
            }
        }
    }
    
    // Method for Case Comments changes
    
    public void SendCaseCommentEmail(List < CaseComment > newTrigger) {
        system.debug('Entered Case Feed Comment');
        Set < id > parentCaseIds = new Set < id > ();
        Set < id > CommentedUsers = new Set < id > (); // To set the reply-to Address

        List < CaseComment > isValidFeed = new List < CaseComment > ();

        for (CaseComment CC: newTrigger) {
            if (String.valueOf(CC.ParentId.getSObjectType()) == 'Case') //Only if comment is public, send out emails 
            {
                isValidFeed.add(CC);
                parentCaseIds.add(CC.ParentId);
                CommentedUsers.add(CC.CreatedById);
               
                if(cc.isPublished == false) {

                    emailTemplateType ='InternalUsers';
                }
                else {

                    emailTemplateType ='AllUsers';   
                }  

            }
        }

        if (isValidFeed.size() > 0) {
            for (CaseComment CC: isValidFeed) {
                Case currentCase = new Case();
                //String replytoAddress;
                List < Id > toMemberIds = new List < Id > ();
                //List < String > ccAddresses = new List < String > ();
                //List < String > bccAddresses = new List < String > ();
                String bodyText;
                
                currentCase = [sELECT Id, ownerid,CS_Recent_Private_Comment__c,
                                          CS_Recent_Private_Comment_Postedby__c,
                                          CS_Recent_Private_Comment_Posteddate__c,
                                          CS_Recent_Public_Comment_Postedby__c,
                                          CS_Recent_Public_Comment_Posteddate__c,
                                          CS_Recent_Public_Case_Comment__c,
                                          Description, CaseNumber,Asset.name,Owner.name,CS_Asset_Name__c,
                                          Subject,CS_Urgency__c,Environment_Affected__c,Severity__c,Status,
                                          Asset.CS_Organization__c,Contact.name,Contact.email,contact.phone,CS_Case_Url__c, 
                                          CS_Associated_Jira_URL__c,IsEscalated, CS_Case_Thread__c 
                                FROM Case
                                WHERE Id =: CC.ParentId limit 1];

                if(string.valueOf(currentCase.OwnerId).startsWith('005')) {             
                        System.debug('++++Case Owner is ++++' +currentCase.OwnerId );
                        toMemberIds.add(currentCase.Ownerid);
                }
                
                List < CaseTeamMember > caseTeamMembers = new List < CaseTeamMember > ([SELECT Id, Member.Id, Member.Email, TeamRole.Name
                    FROM CaseTeamMember
                    WHERE ParentId =: CC.ParentId
                    AND TeamRole.Name
                    NOT IN('Customer Case Contact','Customer Support', 'Customer Support View Only', 'Partner')
                ]);
                system.debug('CTM===' + caseTeamMembers);
             
                noDuplicates.add(currentCase.Contact.Email);
                system.debug('noDuplicates ='+noDuplicates);
                for (CaseTeamMember member: caseTeamMembers) {
                    system.debug('member email==' + member.member.email +' Team Role==' + member.TeamRole.Name + 'Dup Check==' + noDuplicates);
                    if(member.Member.Email != null && isNewAddress(member.Member.Email) ){

                      /*
                        if(member.TeamRole.Name == 'Customer Case Contact') {
                            System.debug('Adding  CCC to Member Id' +member.Member.Email);
                            toMemberIds.add(member.Member.Id);
                        }
                        */
                        if (member.TeamRole.Name == 'GW Watcher') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Follow the Sun') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Leads') {
                            toMemberIds.add(member.Member.Id);
                        }
                        if (member.TeamRole.Name == 'Collaborator') {
                            toMemberIds.add(member.Member.Id);
                        }
                    }
                }

                system.debug('CTM toMemberIds=' +toMemberIds);
                
                List < EntitySubscription > followers = new List < EntitySubscription > ([SELECT Id, SubscriberId, Subscriber.Email
                                                                                            FROM EntitySubscription
                                                                                            WHERE ParentId =: CC.ParentId
                                                                                            AND SubscriberId NOT IN 
                                                                                               (SELECT Id FROM User WHERE Profile.Name IN ('GW Customer Community','GW Partner Community', 'GW Services'))
                                                                                            LIMIT 1000]);
                for (EntitySubscription follower: followers) {
                    if (follower.Subscriber.Email != null && isNewAddress(follower.Subscriber.Email)) {
                        toMemberIds.add(follower.SubscriberId);
                    }
                }
                
                system.debug('toMemberIds=' +toMemberIds);
                if (toMemberIds != null ) {
                    SendCommentEmail(toMemberIds,replyToAddress, currentCase, CC.CommentBody, emailTemplateType);
                }
            }
        }
    }
    
    public Boolean isNewAddress(String inAddress) {
        Boolean bool = false;
        Integer initialCount = noDuplicates.size();
        noDuplicates.add(inAddress);
        if(noDuplicates.size()>initialCount) {
            bool = true;
        } else {
            bool = false;
        }
        return bool;
    }
    
    public String stripHTMLTags(String inString) {
        if(inString!=null && inString.trim().length()!=0){
            inString = inString.replace('</p>','\n').replace('<p>','');
            inString = inString.replace('<b>','').replace('</b>','');
            inString = inString.replace('<i>','').replace('</i>','');
            inString = inString.replace('<u>','').replace('</u>','');
            inString = inString.replace('<s>','').replace('</s>','');
            inString = inString.replace('</li>','\n').replace('<li>','');
            inString = inString.replace('<ol>','').replace('</ol>','');
            inString = inString.replace('<ul>','').replace('</ul>','');
        }
        return inString;
    }

    private void SendCommentEmail(List < Id > toMemberIds,                                   
                                  String replyTo, 
                                  Case CurrentCase,                            
                                  String CommentBody, 
                                  String emailTemplateId) {

        system.debug('inside email call===' +toMemberIds);    
        //Defect DE482 Changed From id to Organization Wide Address
        OrgWideEmailAddress LstOrgAddress= [SELECT id, Address FROM OrgWideEmailAddress WHERE DisplayName ='Guidewire Community'];
        for(Id memberId : toMemberIds) {
              
            String Subject;
            String TXTEmailBody;
            system.debug('000::'+emailTemplateType);
            if(emailTemplateType =='AllUsers'){
                //Defect DE482 Changed Subject line 
                Subject=CurrentCase.subject+' [Case:'+ CurrentCase.CaseNumber + '] - '+ CurrentCase.CS_Case_Thread__c;                
                TXTEmailBody='<b>A Public Comment Posted on Case '+ CurrentCase.CaseNumber  +':</b><br>'
                +'<br>\nCase Number: '+CurrentCase.CaseNumber
                +'<br>\nAsset Group: '+ CurrentCase.asset.CS_Organization__c
                +'<br>\nCustomer Contact Name: '+CurrentCase.Contact.name
                +'<br>\nCustomer Contact Email: '+CurrentCase.Contact.email
                +'<br>\nSeverity: '+ CurrentCase.Severity__c
                +'<br>\nStatus: '+ CurrentCase.Status
                +'<br>\nUrgency: '+ CurrentCase.cs_Urgency__c
                +'<br>\nAsset: '+ CurrentCase.CS_Asset_Name__c
                +'<br>\nCase Owner: '+ CurrentCase.Owner.name
                +'<br>\nEnvironment Affected: '+ CurrentCase.Environment_Affected__c
                +'<br>\nCommented By: '+CurrentCase.CS_Recent_public_Comment_Postedby__c
                +'<br>\nCommented Date: '+CurrentCase.CS_Recent_Public_Comment_Posteddate__c.format()
                +'<br>\nCase Link: '+CurrentCase.CS_Case_Url__c
                +'<br><br>\nComment Posted:'
                +'<br>\n********************************************************************************'
                + '<br>\n' + CurrentCase.CS_Recent_Public_Case_Comment__c
                +'<br>\n**************** System generated email , Please do not reply ***************************';
            }

            else {
                // Fixed the code for Defect #DE181
                //Defect DE482  Changed Subject line 
                Subject=CurrentCase.subject+' [Case:'+ CurrentCase.CaseNumber + '] - '+ CurrentCase.CS_Case_Thread__c;       
                TXTEmailBody='<b>Private Comment Posted on Case '+ CurrentCase.CaseNumber  +':</b><br>'
                +'<br>\nCase Number: '+CurrentCase.CaseNumber
                +'<br>\nAsset Group: '+ CurrentCase.asset.CS_Organization__c
                +'<br>\nCustomer Contact Name: '+CurrentCase.Contact.name
                +'<br>\nCustomer Contact Email: '+CurrentCase.Contact.email
                +'<br>\nSeverity: '+ CurrentCase.Severity__c
                +'<br>\nStatus: '+ CurrentCase.Status
                +'<br>\nUrgency: '+ CurrentCase.cs_Urgency__c
                +'<br>\nAsset: '+ CurrentCase.CS_Asset_Name__c
                +'<br>\nCase Owner: '+ CurrentCase.Owner.name
                +'<br>\nEnvironment Affected: '+ CurrentCase.Environment_Affected__c                
                +'<br>\nCommented By: '+CurrentCase.CS_Recent_Private_Comment_Postedby__c
                +'<br>\nCommented Date: '+CurrentCase.CS_Recent_Private_Comment_Posteddate__c.format()
                +'<br>\nCase Link: '+CurrentCase.CS_Case_Url__c
                +'<br><br>\nComment Posted:'
                +'<br>\n********************************************************************************'
                +'<br>\nComments: '+ CurrentCase.CS_Recent_Private_Comment__c
                +'<br>\n**************** System generated email , Please do not reply ***************************';
            }
           
            // Send Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(memberId);            
            mail.setSubject(Subject);
            //mail.setPlainTextBody(TXTEmailBody);
            mail.setHtmlBody(TXTEmailBody);
            mail.setReplyTo(replyTo);
            mail.setUseSignature(false);
            mail.saveAsActivity = false;
            mail.setCharset('UTF-8');
            //Defect DE482 Changed From id to Organization Wide Address
            if(LstOrgAddress!=null){
                mail.setOrgWideEmailAddressId(LstOrgAddress.id);
            }
            system.debug('TXTEmailBody=='+TXTEmailBody);
            system.debug('mail::'+mail);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
            });
        }            

    }

    public boolean isContactID(id IdInQuestion) {
        return (IdInQuestion.getSObjectType()== Contact.sObjectType); 
    }

}