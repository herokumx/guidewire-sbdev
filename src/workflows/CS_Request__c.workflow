<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>CS_Dev_Request_Fields_Update</fullName>
        <description>Dev Request Fields Update</description>
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
            <field>Case_Owner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Dev_Assignee__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/CS_Dev_Request_Fields_Update</template>
    </alerts>
    <alerts>
        <fullName>CS_Dev_request_notification_to_PgM_email_Alias</fullName>
        <description>Dev request notification to PgM email Alias</description>
        <protected>false</protected>
        <recipients>
            <field>CS_Email_Alias__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Enablement/CS_Dev_Request</template>
    </alerts>
    <fieldUpdates>
        <fullName>CS_Update_Case_Owner_s_Email</fullName>
        <field>Case_Owner_Email__c</field>
        <formula>CS_Case__r.Owner:User.Email</formula>
        <name>Update Case Owner&apos;s Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Update_Next_Dev_Response_Date</fullName>
        <description>Clear the Next Dev Response Date field.</description>
        <field>CS_Next_Dev_Response__c</field>
        <name>Update Next Dev Response Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Update_PGM_email_Alias</fullName>
        <description>Update PGM email alias based on the PGM owner choosen</description>
        <field>CS_Email_Alias__c</field>
        <formula>CASE( TEXT(Pgm_Request_Owner__c) , 
             &apos;ClaimCenter PgM&apos;, &apos;cc-escalation-mgr@guidewire.com&apos;,
             &apos;BillingCenter PgM&apos;, &apos;bc-escalation-mgr@guidewire.com&apos;, 
             &apos;Platform PgM&apos;, &apos;pl-escalation-mgr@guidewire.com&apos;,
             &apos;PolicyCenter PgM&apos;, &apos;pc-escalation-mgr@guidewire.com&apos;,
             &apos;DataManagement PgM&apos;, &apos;dm-escalation-mgr@guidewire.com&apos;,
             &apos;Digital Portals PgM&apos;, &apos;mp-escalation-mgr@guidewire.com&apos;,
             &apos;EDC&apos;, &apos;apex-escalation-mgr@guidewire.com&apos;,
             &apos;TDC&apos;, &apos;tdc-escalation-mgr@guidewire.com&apos;,
             &apos;escalation-mgr-tst@guidewire.com&apos;)</formula>
        <name>Update PGM email Alias</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>CS_Dev Request Fields Update</fullName>
        <actions>
            <name>CS_Dev_Request_Fields_Update</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>US2743 -  Notify on  Dev Request fields change.</description>
        <formula>AND( RecordType.DeveloperName=&apos;Dev_Request&apos;, NOT(ISNEW()), OR( ISCHANGED(CS_Request_Owner__c),ISCHANGED( Pgm_Request_Owner__c ),ISCHANGED( CS_Request_Status__c ),ISCHANGED( CS_Information_Request__c ),ISCHANGED( CS_Case__c ),ISCHANGED( CS_Escalation_Note__c ),ISCHANGED( CS_Fix_by_Version__c ),ISCHANGED( CS_Customer_Commitment__c ),ISCHANGED( CS_Dev_Jira__c ),ISCHANGED( CS_Associated_Jira__c ),ISCHANGED( CS_Request_Type__c ), ISCHANGED( CS_Request_Reason__c ),ISCHANGED( CS_Next_Dev_Response__c ),ISCHANGED( Dev_Assignee__c ),ISCHANGED( CS_Dev_Current_Status__c),ISCHANGED( Dev_Assignee_Group__c)) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CS_Send email to PgM email Alias</fullName>
        <actions>
            <name>CS_Dev_request_notification_to_PgM_email_Alias</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>CS_Request__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Dev Request</value>
        </criteriaItems>
        <criteriaItems>
            <field>CS_Request__c.CS_Submitted_First_Time__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Every time a dev request is submitted, an email is sent to PgM email alias</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS_Update Case Owner%27s Email</fullName>
        <actions>
            <name>CS_Update_Case_Owner_s_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>CS_Request__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Dev Request</value>
        </criteriaItems>
        <description>US2743 - Notify on Dev Request fields change.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CS_Update Next Dev Response Date</fullName>
        <actions>
            <name>CS_Update_Next_Dev_Response_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>US2763 - Clear next Dev Response field.</description>
        <formula>AND( RecordType.DeveloperName = &apos;Dev_Request&apos;, ISCHANGED(CS_Request_Status__c),  ISPICKVAL(CS_Request_Status__c, &apos;Answered&apos;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CS_Update Pgm Email Alias</fullName>
        <actions>
            <name>CS_Update_PGM_email_Alias</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update Pgm email alias based on the pgm owner chosen on request</description>
        <formula>NOT( ISNULL(TEXT(Pgm_Request_Owner__c) ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
