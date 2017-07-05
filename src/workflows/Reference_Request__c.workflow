<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_an_Email_to_John_Leonidas_APACAccountManagers_based_on_No_longer_needed</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>apacaccountmanagers@guidewire.com</ccEmails>
        <description>Send an Email to John Leonidas &amp; APACAccountManagers based on No longer needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_based_on_No_Longer_Needed</template>
    </alerts>
    <alerts>
        <fullName>Send_an_Email_to_John_Leonidas_CRM_AMER1</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>CRM_AMER@guidewire.com</ccEmails>
        <description>Send an Email to John Leonidas &amp; CRM_AMER1</description>
        <protected>false</protected>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_to_JOHN_CRM_AMER</template>
    </alerts>
    <alerts>
        <fullName>Send_an_Email_to_John_Leonidas_CRM_AMER_based_on_No_longer_needed</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>CRM_AMER@guidewire.com</ccEmails>
        <description>Send an Email to John Leonidas &amp; CRM_AMER based on No longer needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_based_on_No_Longer_Needed</template>
    </alerts>
    <alerts>
        <fullName>Send_an_Email_to_John_Leonidas_Samirah_Rizman_based_on_No_longer_needed</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>srizwan@guidewire.com</ccEmails>
        <description>Send an Email to John Leonidas &amp; Samirah Rizman based on No longer needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_based_on_No_Longer_Needed</template>
    </alerts>
    <alerts>
        <fullName>send_an_Email_to_John_Leonidas_APACAccountManagers</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>apacaccountmanagers@guidewire.com</ccEmails>
        <description>send an Email to John Leonidas &amp; APACAccountManagers</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_to_JOHN_CRM_AMER</template>
    </alerts>
    <alerts>
        <fullName>send_an_Email_to_John_Leonidas_Samirah_Rizman</fullName>
        <ccEmails>dmakam@guidewire.com</ccEmails>
        <ccEmails>srizwan@guidewire.com</ccEmails>
        <description>send an Email to John Leonidas &amp; Samirah Rizman</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>jleonidas@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Send_an_Email_to_JOHN_CRM_AMER</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_CRM_Email_Field</fullName>
        <field>CRM_email_Field__c</field>
        <formula>Account_Requesting__r.Customer_Relationship_Mgr__r.Email</formula>
        <name>Update CRM Email Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Get the CRM field</fullName>
        <actions>
            <name>Update_CRM_Email_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISBLANK( Account_Requesting__c ))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Send Email based on No longer needed and APAC</fullName>
        <actions>
            <name>Send_an_Email_to_John_Leonidas_APACAccountManagers_based_on_No_longer_needed</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>AND(No_Longer_Needed__c = TRUE,ISPICKVAL( Region_Requested_to_Fulfill_Reference__c,&quot;APAC&quot;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Send Email based on No longer needed and EMEA</fullName>
        <actions>
            <name>Send_an_Email_to_John_Leonidas_Samirah_Rizman_based_on_No_longer_needed</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>AND(No_Longer_Needed__c = TRUE,ISPICKVAL( Region_Requested_to_Fulfill_Reference__c,&quot;EMEA&quot;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Send Email to John Leonidas %26 APAC based on Reference Request Region %3D APAC</fullName>
        <actions>
            <name>send_an_Email_to_John_Leonidas_APACAccountManagers</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Reference_Request__c.Region_Requested_to_Fulfill_Reference__c</field>
            <operation>equals</operation>
            <value>APAC</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Send Email to John Leonidas %26 EMEA based on Reference Request Region %3D EMEA</fullName>
        <actions>
            <name>send_an_Email_to_John_Leonidas_Samirah_Rizman</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Reference_Request__c.Region_Requested_to_Fulfill_Reference__c</field>
            <operation>equals</operation>
            <value>EMEA</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Send an Email based on No longer needed and AMER%2FLatAM</fullName>
        <actions>
            <name>Send_an_Email_to_John_Leonidas_CRM_AMER_based_on_No_longer_needed</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <booleanFilter>(1 OR 2) AND 3</booleanFilter>
        <criteriaItems>
            <field>Reference_Request__c.Region_Requested_to_Fulfill_Reference__c</field>
            <operation>equals</operation>
            <value>AMER</value>
        </criteriaItems>
        <criteriaItems>
            <field>Reference_Request__c.Region_Requested_to_Fulfill_Reference__c</field>
            <operation>equals</operation>
            <value>LatAM</value>
        </criteriaItems>
        <criteriaItems>
            <field>Reference_Request__c.No_Longer_Needed__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Send an Email to John Leonidas %26 CRM_AMER based on Reference Request Region Equals to AMER%2FLatAm</fullName>
        <actions>
            <name>Send_an_Email_to_John_Leonidas_CRM_AMER1</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR(ISPICKVAL(Region_Requested_to_Fulfill_Reference__c, &quot;AMER&quot;),ISPICKVAL(Region_Requested_to_Fulfill_Reference__c,&quot;LatAM&quot;))</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
