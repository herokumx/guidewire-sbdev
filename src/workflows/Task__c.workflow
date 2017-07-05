<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_alert_to_task_creator_on_status_change</fullName>
        <description>Send alert to task creator on status change</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Alert_on_Task_Status_update_html</template>
    </alerts>
    <alerts>
        <fullName>Send_alert_to_task_owner_on_task_creation</fullName>
        <description>Send alert to task owner on task creation</description>
        <protected>false</protected>
        <recipients>
            <field>Task_Owner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Alert_on_Task_Creation_html</template>
    </alerts>
    <rules>
        <fullName>Notify task creator on status change</fullName>
        <actions>
            <name>Send_alert_to_task_creator_on_status_change</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task__c.Task_Status__c</field>
            <operation>equals</operation>
            <value>Dev Complete,Ready for Review,Complete</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify task owner of new task created</fullName>
        <actions>
            <name>Send_alert_to_task_owner_on_task_creation</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task__c.Task_Status__c</field>
            <operation>notEqual</operation>
            <value>Complete</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
