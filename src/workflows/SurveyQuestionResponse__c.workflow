<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Survey_Force_update_responses</fullName>
        <field>Responses__c</field>
        <formula>Response__c</formula>
        <name>Survey Force update responses</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>SurveyForce</fullName>
        <actions>
            <name>Survey_Force_update_responses</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() &amp;&amp; ( Response__c =&apos;Very Satisfied&apos; || Response__c =&apos;Satisfied&apos; || Response__c =&apos;Neutral&apos; || Response__c =&apos;Unsatisfied&apos; || Response__c =&apos;Very Unsatisfied&apos; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
