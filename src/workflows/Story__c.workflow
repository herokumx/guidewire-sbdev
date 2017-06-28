<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Alert_to_Business_Requestor_on_Story_status_change</fullName>
        <description>Send Alert to Business Requestor on Story Status change</description>
        <protected>false</protected>
        <recipients>
            <field>Business_Requestor__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Alert_on_Story_Update_html</template>
    </alerts>
    <alerts>
        <fullName>Send_Alert_to_Story_Owner_and_Business_Requestor_on_Story_Creation</fullName>
        <description>Send Alert to Story Owner and Business Requestor on Story Creation</description>
        <protected>false</protected>
        <recipients>
            <field>Business_Requestor__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Story_Owner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Alert_on_Story_Creation_html</template>
    </alerts>
    <rules>
        <fullName>Alert on Story Creation</fullName>
        <actions>
            <name>Send_Alert_to_Story_Owner_and_Business_Requestor_on_Story_Creation</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Story__c.CreatedDate</field>
            <operation>greaterThan</operation>
            <value>1/1/2014</value>
        </criteriaItems>
        <criteriaItems>
            <field>Story__c.Story_Status__c</field>
            <operation>notEqual</operation>
            <value>Completed</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Send alert on Story update</fullName>
        <actions>
            <name>Send_Alert_to_Business_Requestor_on_Story_status_change</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Story_Status__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
