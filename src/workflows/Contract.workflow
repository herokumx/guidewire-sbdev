<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Activate_Contract</fullName>
        <field>Status</field>
        <literalValue>Activated</literalValue>
        <name>Activate Contract</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Renewal_Quoted_Checkbox</fullName>
        <field>SBQQ__RenewalQuoted__c</field>
        <literalValue>1</literalValue>
        <name>Check Renewal Quoted Checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Preserve_Bundle_Structure_Upon_Renewals</fullName>
        <field>SBQQ__PreserveBundleStructureUponRenewals__c</field>
        <literalValue>1</literalValue>
        <name>Preserve Bundle Structure Upon Renewals</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Renewal_Opportunity_Record_Type_ID</fullName>
        <field>SBQQ__RenewalOpportunityRecordTypeId__c</field>
        <formula>&quot;012800000003oCJ&quot;</formula>
        <name>Renewal Opportunity Record Type ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Renewal_Opportunity_Stage_Lead</fullName>
        <field>SBQQ__RenewalOpportunityStage__c</field>
        <formula>&quot;Lead&quot;</formula>
        <name>Renewal Opportunity Stage Lead</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Renewal_Pricebook_ID_Standard_Price_Book</fullName>
        <field>SBQQ__RenewalPricebookId__c</field>
        <formula>&quot;01s3000000007kA&quot;</formula>
        <name>Renewal Pricebook ID Standard Price Book</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Renewal_Status_Changed_Date_Update</fullName>
        <field>Renewal_Status_Changed_Date__c</field>
        <formula>TODAY()</formula>
        <name>Renewal Status Changed Date Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Renewal_Term_12_months</fullName>
        <field>SBQQ__RenewalTerm__c</field>
        <formula>12</formula>
        <name>Renewal Term 12 Months</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Invoice_Date_to_Start_Date</fullName>
        <field>Invoice_Date__c</field>
        <formula>StartDate</formula>
        <name>Set Invoice Date to Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Setting_Up_Renewal_Term</fullName>
        <field>SBQQ__RenewalTerm__c</field>
        <name>Setting Up Renewal Term</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Contract_Renewal_Forecast</fullName>
        <field>SBQQ__RenewalForecast__c</field>
        <literalValue>1</literalValue>
        <name>Update Contract Renewal Forecast</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Contract_Renewal_Quoted</fullName>
        <field>SBQQ__RenewalQuoted__c</field>
        <literalValue>1</literalValue>
        <name>Update Contract Renewal Quoted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Contract_Status</fullName>
        <field>Status</field>
        <literalValue>Activated</literalValue>
        <name>Update Contract Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Description</fullName>
        <field>PBO_Description__c</field>
        <formula>&apos;Test&apos;</formula>
        <name>Update Description</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Activate Contract-v2</fullName>
        <actions>
            <name>Update_Contract_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Timed base WFR to activate the contract</description>
        <formula>Id &lt;&gt; NULL</formula>
        <triggerType>onCreateOnly</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Contract_Renewal_Forecast</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Update_Contract_Renewal_Quoted</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Contract.Contract_Activate_Trigger_Time__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Renewal Status Changed Date - Update</fullName>
        <actions>
            <name>Renewal_Status_Changed_Date_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(Renewal_Status__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Contract Invoice Date to Start Date</fullName>
        <actions>
            <name>Set_Invoice_Date_to_Start_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>1=1</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
