<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Community_Access_Request_Email_Alert</fullName>
        <description>Community Access Request - Production</description>
        <protected>false</protected>
        <recipients>
            <field>Customer_Support_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Community_Access_Request_Template</template>
    </alerts>
    <alerts>
        <fullName>Community_Access_Request_Implementation_Customer</fullName>
        <description>Community Access Request - Implementation Customer</description>
        <protected>false</protected>
        <recipients>
            <field>Customer_Support_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Community_Access_Request_Template</template>
    </alerts>
    <alerts>
        <fullName>Community_Access_Request_Implementation_Not_Customer</fullName>
        <description>Community Access Request - Implementation Not Customer</description>
        <protected>false</protected>
        <recipients>
            <field>Implementation_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Community_Access_Request_Template</template>
    </alerts>
    <alerts>
        <fullName>Community_Access_Request_Partner</fullName>
        <description>Community Access Request - Partner</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Community_Access_Request_Template</template>
    </alerts>
    <rules>
        <fullName>Email Notification - Community Access Request</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Community_Access_Request__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
