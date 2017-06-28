<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Product_Documentation_Name</fullName>
        <description>Update Product Documentation Name</description>
        <field>Name</field>
        <formula>Product_Version__c+&apos; &apos;+TEXT(CS_Type__c)</formula>
        <name>Update Product Documentation Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Modify Documentation Name</fullName>
        <actions>
            <name>Update_Product_Documentation_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Modify Documentation Name to make it unique</description>
        <formula>AND(CS_Release_Version__c != NULL,TEXT(CS_Type__c) != NULL)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
