<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PRM_Lead_Source_Partner_Referral</fullName>
        <field>LeadSource</field>
        <literalValue>Partner Referral</literalValue>
        <name>Lead Source - Partner Referral</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PRM_Partner_Lead_Source</fullName>
        <description>Updates the lead source of a lead created by a partner in the partner community to “Partner Community”</description>
        <field>LeadSource</field>
        <literalValue>Partner Community</literalValue>
        <name>Partner Lead Source</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>LEAD%3A Mark Email Notification Sent for GWL</fullName>
        <actions>
            <name>Lead_Notification_Sent_to_Lead_Queue</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.LeadSource</field>
            <operation>equals</operation>
            <value>Guidewire-Live-Web</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>PRM New Business Referred</fullName>
        <actions>
            <name>PRM_Lead_Source_Partner_Referral</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.RecordTypeId</field>
            <operation>equals</operation>
            <value>Partner Referral Lead</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.PRM_Sales_Lead_Generated__c</field>
            <operation>equals</operation>
            <value>Yes</value>
        </criteriaItems>
        <description>Updates the lead source of a PRM referral from Partner Community to Partner Referral if the lead &apos;Sales Lead Generated&apos; field = Yes</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Partner Community Leads</fullName>
        <actions>
            <name>PRM_Partner_Lead_Source</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>equals</operation>
            <value>Partner Community User,Partner Community Manager</value>
        </criteriaItems>
        <description>Every time a lead is created in the partner community, update the lead source to &quot;Partner Community&quot;</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <tasks>
        <fullName>Lead_Notification_Sent_to_Lead_Queue</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Lead Notification Sent to Lead Queue Gor Guidewire Live Lead</subject>
    </tasks>
</Workflow>
