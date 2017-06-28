<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ACP_Composite_Key_Update</fullName>
        <field>CS_ACP_Unique_Key__c</field>
        <formula>CS_Contact__c+CS_Asset__c</formula>
        <name>ACP Composite Key Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>ACP Dupe Check</fullName>
        <actions>
            <name>ACP_Composite_Key_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>**** ACP Dupe Check *****</description>
        <formula>OR(  ISNEW(), ISCLONE(), ISCHANGED(CS_Contact__c), ISCHANGED(CS_Asset__c)   )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
