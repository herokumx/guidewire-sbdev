<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Modify_Release_Name</fullName>
        <description>Update release name on create of release data</description>
        <field>Name</field>
        <formula>CS_Product__r.Name+IF(ISPICKVAL(CS_Major_Release_version__c,&apos;&apos;),&apos;&apos;,&apos; &apos;)+TEXT(CS_Major_Release_version__c)+IF( ISPICKVAL(CS_Minor_Release_Version__c,&apos;&apos;),&apos;&apos;,&apos;.&apos;)+TEXT(CS_Minor_Release_Version__c)+ IF( ISPICKVAL(CS_Maintenance_Release_Version__c,&apos;&apos;),&apos;&apos;,&apos;.&apos;)+TEXT(CS_Maintenance_Release_Version__c)+ IF(CS_Additional_Version_Code__c == &apos;&apos; || CONTAINS(CS_Additional_Version_Code__c,&apos;-&apos;),&apos;&apos;,&apos; &apos;) +CS_Additional_Version_Code__c+IF(ISPICKVAL(CS_Patch_Version__c,&apos;&apos;),&apos;&apos;,&apos; &apos;)+TEXT(CS_Patch_Version__c)</formula>
        <name>Modify Release Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Publish_Status</fullName>
        <description>Update Publish Status via WF Rule</description>
        <field>CS_IsActive__c</field>
        <literalValue>1</literalValue>
        <name>Update Publish Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Auto Publish Release</fullName>
        <active>true</active>
        <description>Auto Publish Release Record via Time based Trigger</description>
        <formula>NOT(ISNULL(CS_Publish_Date__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Publish_Status</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>CS_Release__c.CS_Publish_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Modify Release Name</fullName>
        <actions>
            <name>Modify_Release_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update release name on insert of release records</description>
        <formula>OR(ISNEW(), ISCHANGED(CS_Major_Release_version__c ),  ISCHANGED( CS_Minor_Release_Version__c ) , ISCHANGED( CS_Patch_Version__c ) , ISCHANGED( CS_Release_Type__c ), ISCHANGED( CS_Product_Version__c)    )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
