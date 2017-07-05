<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PRM_Partner_Opp_Revenue_Share_Rate</fullName>
        <field>Revenue_Sharing_Rate2__c</field>
        <formula>Product2.PRM_Revenue_Sharing_Rate_del__c</formula>
        <name>Partner Opp Revenue Share Rate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PSA_Oppty_Product_Set_IsServices_Flag</fullName>
        <field>pse__IsServicesProductLine__c</field>
        <literalValue>1</literalValue>
        <name>PSA Oppty Product Set IsServices Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>PSA Opportunity Product Set IsServicesProductLine Flag</fullName>
        <actions>
            <name>PSA_Oppty_Product_Set_IsServices_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Product2.pse__IsServicesProduct__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>This workflow will look at the product that has been added to the opportunity product line item. If the product is a services product it will check the check box on the opportunity product line item.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Partner Opportunity Line Item</fullName>
        <actions>
            <name>PRM_Partner_Opp_Revenue_Share_Rate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>OpportunityLineItem.CreatedDate</field>
            <operation>equals</operation>
            <value>TODAY</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
