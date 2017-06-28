<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>CS_Email_Alert_Prior_to_Asset_Deactivation</fullName>
        <description>Email Alert Prior to Asset Deactivation</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Asset/CS_Prospect_Asset_Deactivation_Email_Alert</template>
    </alerts>
    <fieldUpdates>
        <fullName>CS_Deactivate_Prospect_Asset</fullName>
        <description>***** Deactivate Prospect Asset*******</description>
        <field>CS_Is_Active__c</field>
        <literalValue>0</literalValue>
        <name>Deactivate Prospect Asset</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Prospect Asset Deactivation</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Asset.Status</field>
            <operation>equals</operation>
            <value>Prospect</value>
        </criteriaItems>
        <criteriaItems>
            <field>Asset.CS_Is_Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Asset.CS_Prospect_Evaluation_End_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>***** Prospect Asset deactivation ********</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>CS_Email_Alert_Prior_to_Asset_Deactivation</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Asset.CS_Prospect_Evaluation_End_Date__c</offsetFromField>
            <timeLength>-3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>CS_Deactivate_Prospect_Asset</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Asset.CS_Prospect_Evaluation_End_Date__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Update Asset parent</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Asset.CS_Account_Name__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
