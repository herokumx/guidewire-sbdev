<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>CS_Update_TA_Validation_Stat</fullName>
        <description>Update Validation status to Administrator review</description>
        <field>ValidationStatus</field>
        <literalValue>Administrator Review</literalValue>
        <name>Update Technical Article Validation Stat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Update_TA_rejection_Status</fullName>
        <description>Update TA rejection Status</description>
        <field>ValidationStatus</field>
        <literalValue>Rejected</literalValue>
        <name>Update TA rejection Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Updated_TA_Validation_Status</fullName>
        <description>Update TA validation status</description>
        <field>ValidationStatus</field>
        <literalValue>Approved</literalValue>
        <name>Updated TA Validation Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
