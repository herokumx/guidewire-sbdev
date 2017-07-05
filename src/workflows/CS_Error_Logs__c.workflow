<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Service Contract Failures</fullName>
        <active>false</active>
        <criteriaItems>
            <field>CS_Error_Logs__c.CS_Object_Name__c</field>
            <operation>equals</operation>
            <value>ServiceContract</value>
        </criteriaItems>
        <description>*********Email Notification when Service Contract Fails*********</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
