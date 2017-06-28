<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_alert_on_Issues_to_notify_Dev_Owner</fullName>
        <description>Email alert on Issues to notify Dev Owner</description>
        <protected>false</protected>
        <recipients>
            <field>Dev_Owner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Issue_alert_for_Dev_Owner_on_Issues_html</template>
    </alerts>
    <alerts>
        <fullName>Email_alert_on_Issues_to_notify_Issue_Owner</fullName>
        <description>Email alert on Issues to notify Issue Owner</description>
        <protected>false</protected>
        <recipients>
            <field>Issue_Owner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Issue_alert_for_Issue_Owner_on_Issues_html</template>
    </alerts>
    <rules>
        <fullName>Notify Dev owner on issue update</fullName>
        <actions>
            <name>Email_alert_on_Issues_to_notify_Dev_Owner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Issue__c.Issue_Status__c</field>
            <operation>equals</operation>
            <value>New,QA In Progress,QA Complete,ReOpened</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Notify Issue owner on issue update</fullName>
        <actions>
            <name>Email_alert_on_Issues_to_notify_Issue_Owner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Issue__c.Issue_Status__c</field>
            <operation>equals</operation>
            <value>Planned,In Progress,Dev Complete,Ready for QA,Complete,Blocked,Enhancement</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
