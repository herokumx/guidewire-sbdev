<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Customer_Story_Feedback_created</fullName>
        <ccEmails>customerstories@guidewire.com</ccEmails>
        <description>Customer Story - Feedback created</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>Customer_Story_Templates/SFDC_Customer_Story_Feedback</template>
    </alerts>
    <rules>
        <fullName>Customer Story - new Feedback created</fullName>
        <actions>
            <name>Customer_Story_Feedback_created</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Feedback__c.Note_Details__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>When a new Feedback record is created, send an email to ʺSalesEnablement@guidewire.comʺ and ʺproductmarketing@Guidewire.comʺ.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
