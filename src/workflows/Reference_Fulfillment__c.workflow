<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Reference_Fulfillment_Customer_Feedback</fullName>
        <description>Reference Fulfillment - Customer Feedback</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Reference_Fulfillment_Customer_Feedback</template>
    </alerts>
    <alerts>
        <fullName>Reference_Fulfillment_Prospect_Feedback</fullName>
        <description>Reference Fulfillment - Prospect Feedback</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Reference_Request_Prospect_Feedback</template>
    </alerts>
    <alerts>
        <fullName>Send_an_Email_to_Guidewire_Person_Requesting</fullName>
        <description>Send an Email to Guidewire Person Requesting</description>
        <protected>false</protected>
        <recipients>
            <field>Get_GW_Person__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_to_Guidewire_Person_Requesting</template>
    </alerts>
    <alerts>
        <fullName>Send_an_Email_to_Person_responsible_for_fulfiling_request</fullName>
        <description>Send an Email to Person responsible for fulfiling request</description>
        <protected>false</protected>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <field>Person_Responsible_for_Fulfiling_Request__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_to_Person_responsible_for_fulfiling_request</template>
    </alerts>
    <fieldUpdates>
        <fullName>Reference_Fulfillment_update_status</fullName>
        <field>Status__c</field>
        <literalValue>Confirmed</literalValue>
        <name>Reference Fulfillment - update status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_GW_person</fullName>
        <field>Get_GW_Person__c</field>
        <formula>Reference_Requests__r.CreatedBy.Email</formula>
        <name>Update GW person</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_Field_To_Completed</fullName>
        <field>Status__c</field>
        <literalValue>Completed</literalValue>
        <name>Update Status Field To Completed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Get the GW Person</fullName>
        <actions>
            <name>Update_GW_person</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISBLANK( Reference_Requests__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Reference Fulfillment - Customer Feedback</fullName>
        <active>true</active>
        <formula>NOT( ISBLANK( Date_Reference_is_Scheduled_for__c )) &amp;&amp;  ISBLANK( Reference_Fulfillment_Feedback__c)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Customer_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Customer_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Customer_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>4</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Customer_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Reference Fulfillment - update status</fullName>
        <actions>
            <name>Reference_Fulfillment_update_status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT( ISBLANK(Date_Reference_is_Scheduled_for__c) ) &amp;&amp;  Date_Reference_is_Scheduled_for__c  &gt;   TODAY()</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Reference Fulfillment- Prospect Feedback</fullName>
        <active>true</active>
        <formula>NOT( ISBLANK(Date_Reference_is_Scheduled_for__c ))&amp;&amp; ISBLANK( Reference_Request_Feed_back__c )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Prospect_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Prospect_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Prospect_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Reference_Fulfillment_Prospect_Feedback</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Reference_Fulfillment__c.Date_Reference_is_Scheduled_for__c</offsetFromField>
            <timeLength>4</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Send an Email to Guidewire Person Requesting</fullName>
        <actions>
            <name>Send_an_Email_to_Guidewire_Person_Requesting</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISBLANK( Reference_Request_Feed_back__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Send an Email to Person responsible for fulfiling request</fullName>
        <actions>
            <name>Send_an_Email_to_Person_responsible_for_fulfiling_request</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISBLANK( Reference_Fulfillment_Feedback__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
