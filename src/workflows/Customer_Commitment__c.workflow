<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Report_Neg_Value_Consulting_Field_Update</fullName>
        <field>Value_Consulting__c</field>
        <literalValue>0</literalValue>
        <name>Report_Neg_Value Consulting Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Sales_Event__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Report_Value_Consulting_Field_Update</fullName>
        <field>Value_Consulting__c</field>
        <literalValue>1</literalValue>
        <name>Report_Value Consulting Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Sales_Event__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Report_Value Consulting Workflow</fullName>
        <actions>
            <name>Report_Value_Consulting_Field_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When within Customer Commitment, Coverage area is chosen as &apos;Value Consulting&apos;, update Sales Event.Value Consulting = true.</description>
        <formula>INCLUDES( Coverage_Area__c,&quot;Value Consulting&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Report_Value Consulting_Negative Workflow</fullName>
        <actions>
            <name>Report_Neg_Value_Consulting_Field_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>When within Customer Commitment, Coverage area is no longer as &apos;Value Consulting&apos;, update Sales Event.Value Consulting = False.</description>
        <formula>NOT INCLUDES( Coverage_Area__c,&quot;Value Consulting&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
