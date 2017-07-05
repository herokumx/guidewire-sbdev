<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Case_Assignment_Notification</fullName>
        <description>Case Assignment Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Assignment</template>
    </alerts>
    <alerts>
        <fullName>Case_Auto_Response_email_to_Creator</fullName>
        <description>Case Auto Response email to Creator</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>ps-help@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>PS_Help/Case_Creation_Template</template>
    </alerts>
    <alerts>
        <fullName>Case_Auto_Response_email_to_Creator_Guidewire_Live</fullName>
        <description>Case Auto Response email to Creator - Guidewire Live</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>live-support@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>PS_Help/Guidewire_Live_Case_Creation_Template</template>
    </alerts>
    <alerts>
        <fullName>Case_Closure_Request_from_Customer</fullName>
        <description>Case Closure Request from Customer</description>
        <protected>false</protected>
        <recipients>
            <recipient>Collaborator</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Follow the Sun</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>GW Watcher</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Leads</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Closure_Request</template>
    </alerts>
    <alerts>
        <fullName>Case_Expiration_Alert_Email</fullName>
        <description>Case Expiration Alert Email</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Milestone_Expiration_Alert1</template>
    </alerts>
    <alerts>
        <fullName>Case_Owner_changes_from_Default_Queue</fullName>
        <description>Case Owner changes from Default Queue</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>PS_Help/Case_Owner_changes_from_Default_Queue</template>
    </alerts>
    <alerts>
        <fullName>Case_Reopen_Email_to_Case_Owner</fullName>
        <description>Case Reopen Email to Case Owner</description>
        <protected>false</protected>
        <recipients>
            <recipient>Collaborator</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Follow the Sun</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>GW Watcher</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Leads</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_ReOpen</template>
    </alerts>
    <alerts>
        <fullName>Case_SLA_Breach_Notification</fullName>
        <description>Case SLA Breach Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>Follow the Sun</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>GW Watcher</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Leads</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_SLA_Breach_Notification</template>
    </alerts>
    <alerts>
        <fullName>Case_Update_Notification</fullName>
        <description>Case Update Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>Collaborator</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Follow the Sun</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>GW Watcher</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <recipient>Leads</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Update</template>
    </alerts>
    <alerts>
        <fullName>Email_Notification_to_Customer_on_Public_Post</fullName>
        <description>Email Notification to Customer on Public Post</description>
        <protected>false</protected>
        <recipients>
            <recipient>Customer Case Contact</recipient>
            <type>caseTeam</type>
        </recipients>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_10__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_1__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_3__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_4__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_5__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_6__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_7__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_8__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>CS_Carbon_Copy_Email_9__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>guidewirecommunity@c-77ju934pvcnbm2yc406xs2baa.3-fhieam.na29.case.salesforce.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/New_Public_Case_Comment</template>
    </alerts>
    <alerts>
        <fullName>Guidewire_Live_Case_Escalation_Alert</fullName>
        <description>Guidewire Live Case Escalation Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>Guidewire_Live_Cases</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PS_Help/Case_Escalation_Alert1</template>
    </alerts>
    <alerts>
        <fullName>High_Severity2_Case_Alert_Hosted</fullName>
        <ccEmails>gps-escalation@guidewire.com,</ccEmails>
        <ccEmails>cloudservices_sev2@guidewire.pagerduty.com</ccEmails>
        <description>High Severity 2 Case Alert Hosted</description>
        <protected>false</protected>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/High_Severity_Cases</template>
    </alerts>
    <alerts>
        <fullName>High_Severity_Case_Alert</fullName>
        <ccEmails>customersupport@guidewire.com,solutionenablement@guidewire.com, consultingenablement@guidewire.com,</ccEmails>
        <ccEmails>6505761413@txt.att.net</ccEmails>
        <description>High Severity Case Alert</description>
        <protected>false</protected>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/High_Severity_Cases</template>
    </alerts>
    <alerts>
        <fullName>High_Severity_Case_Alert_Hosted</fullName>
        <ccEmails>cloudoperations-escalation@guidewire.com,</ccEmails>
        <ccEmails>gps-escalation@guidewire.com,</ccEmails>
        <ccEmails>cloudservices_sev1@guidewire.pagerduty.com</ccEmails>
        <description>High Severity Case Alert Hosted</description>
        <protected>false</protected>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/High_Severity_Cases</template>
    </alerts>
    <alerts>
        <fullName>Send_the_survey</fullName>
        <description>Send the survey for Support</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Close_Customer_Survey_Email</template>
    </alerts>
    <alerts>
        <fullName>Send_the_survey_enablement</fullName>
        <description>Send the survey for enablement</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>guidewirecommunity@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Case_Management/Case_Close_Customer_Survey_Email_enablement</template>
    </alerts>
    <fieldUpdates>
        <fullName>CS_Milestone_1_Update</fullName>
        <field>CS_Milestone_1__c</field>
        <literalValue>1</literalValue>
        <name>Milestone 1 Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Milestone_2_Update</fullName>
        <field>CS_Milestone_2__c</field>
        <literalValue>1</literalValue>
        <name>Milestone 2 Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Milestone_3_Update</fullName>
        <field>CS_Milestone_3__c</field>
        <literalValue>1</literalValue>
        <name>Milestone 3 Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Milestone_4_Update</fullName>
        <field>CS_Milestone_4__c</field>
        <literalValue>1</literalValue>
        <name>Milestone 4 Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Case_Copy_Account_Name_for_Search</fullName>
        <field>Account_Name_For_Search__c</field>
        <name>Case: Copy Account Name for Search</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Case_Customer_Public_Comment_Blank</fullName>
        <field>CS_Recent_Public_Case_Comment__c</field>
        <name>Case Customer Public Comment Blank</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Case_Owner_changes_from_Default_Queue</fullName>
        <field>Status</field>
        <literalValue>Assigned</literalValue>
        <name>Case Owner changes from Default Queue</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Associated_Jira</fullName>
        <description>Update Associated Jira URL based on Associated Jira Ids</description>
        <field>CS_Associated_Jira_URL__c</field>
        <formula>IF(OR( ISNULL(CS_Associated_Jira__c),ISBlANK(CS_Associated_Jira__c) )=true , &apos;&apos;, &quot;https://jira.guidewire.com/login.jsp?os_destination=%2Fsecure%2FIssueNavigator.jspa%3Freset%3Dtrue%26jqlQuery%3Dkey%2Bin%2B%2528&quot;+CS_Associated_Jira__c+&quot;%2529&quot;)</formula>
        <name>Update Associated Jira</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Associated Jira URL</fullName>
        <actions>
            <name>Update_Associated_Jira</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Associated Jira URL based on Associated Hira Ids</description>
        <formula>IF(RecordType.Name=&apos;Customer Support&apos;, true, false)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Assignment Notification</fullName>
        <actions>
            <name>Case_Assignment_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>**** Service Cloud Notify the user when a new case has been assigned to them.*****</description>
        <formula>AND(ISCHANGED(OwnerId), NOT(LEFT(OwnerId,3)=&quot;00G&quot;), RecordType.Name = &apos;Customer Support&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Auto Response email to Creator</fullName>
        <actions>
            <name>Case_Auto_Response_email_to_Creator</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND (2 OR 3)</booleanFilter>
        <criteriaItems>
            <field>Case.OwnerId</field>
            <operation>equals</operation>
            <value>Enablement Queue - PSA</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Other</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Sales Enablement</value>
        </criteriaItems>
        <description>This workflow notifies the case submitter/creator with an automated email.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Case Auto Response email to Creator - Guidewire Live</fullName>
        <actions>
            <name>Case_Auto_Response_email_to_Creator_Guidewire_Live</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Guidewire Live</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.OwnerId</field>
            <operation>equals</operation>
            <value>Guidewire Live - Cases</value>
        </criteriaItems>
        <description>This workflow notifies the case submitter/creator with an automated email for Guidewire Live.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Case Close Task Creation</fullName>
        <actions>
            <name>Pending_KB_Article_Creation</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Closed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.CS_KB_Article_Required__c</field>
            <operation>equals</operation>
            <value>Yes</value>
        </criteriaItems>
        <description>*** Service Cloud Create Tasks when case is closed****</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Case Closure Request</fullName>
        <actions>
            <name>Case_Closure_Request_from_Customer</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Closed by customer</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Customer Support</value>
        </criteriaItems>
        <description>*** Service Cloud Notification Case Close Request is received from Customer , Send email to Case Owner***</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Case High Severity 1 Notification Hosted</fullName>
        <actions>
            <name>High_Severity_Case_Alert_Hosted</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>**** Service Cloud Notification to be sent when a High severity case has been created for hosted product ****</description>
        <formula>AND  (  RecordType.DeveloperName =&quot;CS_Customer_Support&quot;,   Asset.Parent.Is_Hosted__c = True,  ISPICKVAL(Severity__c, &quot;1–Critical&quot;), ISPICKVAL( Case_Type__c , &quot;Defect&quot;)    )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Case High Severity 2 Notification Hosted</fullName>
        <actions>
            <name>High_Severity2_Case_Alert_Hosted</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>**** Service Cloud Notification to be sent when a High severity case has been created for hosted product ****</description>
        <formula>AND  (  RecordType.DeveloperName =&quot;CS_Customer_Support&quot;,   Asset.Parent.Is_Hosted__c = True,  ISPICKVAL(Severity__c, &quot;2–Major&quot;), ISPICKVAL( Case_Type__c , &quot;Defect&quot;)   )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Case High Severity Notification</fullName>
        <actions>
            <name>High_Severity_Case_Alert</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <booleanFilter>3 AND (1 OR 2)</booleanFilter>
        <criteriaItems>
            <field>Case.Severity__c</field>
            <operation>equals</operation>
            <value>1-Blocker</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Severity__c</field>
            <operation>equals</operation>
            <value>2-Critical</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Customer Support</value>
        </criteriaItems>
        <description>**** Service Cloud Notification to be sent when a High severity case has been created****</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Case Owner changes from Default Queue to User</fullName>
        <actions>
            <name>Case_Owner_changes_from_Default_Queue</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(ISCHANGED(OwnerId),LEFT(PRIORVALUE(OwnerId), 3)=&quot;00G&quot;,  RecordType.Name !=&quot;Customer Support&quot; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Reopen Email Notification</fullName>
        <actions>
            <name>Case_Reopen_Email_to_Case_Owner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>**** Service Cloud  Email Sent when case  is ReOpened by Customer****</description>
        <formula>AND( 
OR ( 
$User.ProfileId=$Setup.CS_Profile_Id__c.CS_Customer_Profile__c, 
$User.CS_Profile_Name__c =&quot;GW Services&quot;, 
$User.CS_Profile_Name__c =&quot;GW Services - PSA&quot;, $User.CS_Profile_Name__c = &quot;GW Standard - PSA&quot; 
), 
OR( 
TEXT(PRIORVALUE(Status)) = &quot;Closed&quot;, 
TEXT(PRIORVALUE(Status)) = &quot;Closed by customer&quot; 
), 
Text(Status)=&apos;Updated by customer&apos;, 
RecordType.Name=&apos;Customer Support&apos; 
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Update Notification</fullName>
        <actions>
            <name>Case_Update_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>**** Service Cloud Send case update notification to Internal Case Team Members****</description>
        <formula>AND( ISCHANGED(LastModifiedDate),  NOT($Setup.CS_ByPass__c.CS_Disable_WF_Rules__c), AND( NOT(ISCHANGED(CS_Recent_Public_Case_Comment__c)), NOT(ISCHANGED(CS_Recent_Private_Comment__c)) ), AND( $User.ProfileId!=$Setup.CS_Profile_Id__c.CS_Customer_Profile__c, $User.ProfileId!=$Setup.CS_Profile_Id__c.CS_Partner_Profile__c ), RecordType.Name = &apos;Customer Support&apos; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Copu Account Name for Search Results</fullName>
        <actions>
            <name>Case_Copy_Account_Name_for_Search</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>ISCHANGED( AccountId  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Email Notification to Customer on Public Case Comment</fullName>
        <actions>
            <name>Email_Notification_to_Customer_on_Public_Post</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>*** Service Cloud Send Email Notification on Public Case Comment to Customer***</description>
        <formula>AND(  NOT($Setup.CS_ByPass__c.CS_Batch_Context__c),  ISCHANGED(CS_Recent_Public_Case_Comment__c), RecordType.Name=&apos;Customer Support&apos;, CS_Recent_Public_Case_Comment_Source__c  = &apos;Case Comment&apos; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Guidewire Live Case Escalation</fullName>
        <actions>
            <name>Guidewire_Live_Case_Escalation_Alert</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>AND (IsEscalated, RecordType.DeveloperName =&apos;Guidewire_Live&apos;,  ISCHANGED(IsEscalated) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Send Survey to Users on Case closure</fullName>
        <actions>
            <name>Send_the_survey</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>**** Service Cloud Notification Send Survey to Users on Case closure*****
**** Not Required as Emails Are sent via Process Flow *****</description>
        <formula>AND(IsClosed,ISChanged(Status))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Pending_KB_Article_Creation</fullName>
        <assignedToType>owner</assignedToType>
        <description>Please Submit your KB Article for the case  you have closed within next 7 days</description>
        <dueDateOffset>7</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Case.ClosedDate</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Pending KB Article  Creation</subject>
    </tasks>
</Workflow>
