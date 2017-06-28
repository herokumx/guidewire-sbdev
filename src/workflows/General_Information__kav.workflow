<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Article_rejected</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <description>Article rejected</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Article_created_Need_approval</template>
    </alerts>
    <fieldUpdates>
        <fullName>Article_Approved</fullName>
        <description>Article approved</description>
        <field>ValidationStatus</field>
        <literalValue>Approved</literalValue>
        <name>Article Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Article_rejected</fullName>
        <description>Article rejected</description>
        <field>ValidationStatus</field>
        <literalValue>Author Review</literalValue>
        <name>Article - Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Validation_Status</fullName>
        <description>Update Validation status of the</description>
        <field>ValidationStatus</field>
        <literalValue>Administrator Review</literalValue>
        <name>Update Validation Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
