<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>CS_Update_Contact_record_type_to_Support</fullName>
        <description>This field update will update contact record type to Support when a Ship To ACR is created.</description>
        <field>RecordTypeId</field>
        <lookupValue>Support</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update Contact record type to Support</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <targetObject>Contact__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACR_Int_Pending_Stat_Update</fullName>
        <description>If an ACR record is updated, this flips the status to Pending</description>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>TRAC - ACR - Int Pending Stat Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACR_Ready_to_Integrate_Status</fullName>
        <description>Change the integration status to &quot;Ready to Integrate&quot;</description>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>TRAC - ACR - Ready to Integrate Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACR_Update_Account_Contact_Name</fullName>
        <field>Name</field>
        <formula>Participant_Account__r.Participant_id__c + &quot; - &quot; + (LEFT(Participant_Account__r.Name, (LEN(Participant_Account__r.Name)- (LEN(Participant_Account__r.Participant_id__c + &quot; - &quot; + Participant_Account__r.Name + &quot; - &quot; + Contact__r.FirstName + Contact__r.LastName)-80)))) + &quot; - &quot; + Contact__r.FirstName + Contact__r.LastName</formula>
        <name>TRAC-ACR-Update Account Contact Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACR_Update_Contact_Name</fullName>
        <field>Contact_Name__c</field>
        <formula>Contact_Key__c +&quot; - &quot;+ Participant_Account__r.Name +&quot; - &quot;+ TEXT(Contact_Type__c)</formula>
        <name>TRAC - ACR - Update Contact Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACR_Update_Int_Stats_Pending</fullName>
        <description>Updates integration status to pending when Intacct ID is inserted</description>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>TRAC - ACR - Update Int Stats Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_ACR_Set_Concat_Name</fullName>
        <description>Sets the concatenated name value in the field</description>
        <field>Contact_Name__c</field>
        <formula>(Contact_Key__c) + &quot; - &quot; +(Account__r.Name) + &quot; - &quot; + TEXT(Contact_Type__c)</formula>
        <name>Trac - ACR - Set Concat Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>TRAC - ACR - Int Status Change</fullName>
        <actions>
            <name>TRAC_ACR_Int_Pending_Stat_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires when an already integrated ACR record has a Intacct dependent data change</description>
        <formula>ISPICKVAL(Integration_Status__c,&quot;Integrated&quot;) &amp;&amp; ISCHANGED(Contact_Name__c) ||  ISCHANGED(Contact__c) ||  ISCHANGED(Account__c) ||  ISCHANGED(RecordStatus__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Integration Pending</fullName>
        <actions>
            <name>TRAC_ACR_Update_Int_Stats_Pending</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account_Contact__c.Contact_Key__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Integration Ready</fullName>
        <actions>
            <name>TRAC_ACR_Ready_to_Integrate_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>Contact_Key__c = &quot;&quot; &amp;&amp; Contact_Name__c != &quot;&quot; &amp;&amp; Contact__c != &quot;&quot; &amp;&amp; Account__c != &quot;&quot; &amp;&amp; Text(CurrencyIsoCode) != &quot;&quot;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Record Status change Int Status</fullName>
        <actions>
            <name>TRAC_ACR_Int_Pending_Stat_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When Record status is changed from Active to Inactive, a workflow fires to update integration status</description>
        <formula>ISCHANGED(RecordStatus__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Update Account Contact Name</fullName>
        <actions>
            <name>TRAC_ACR_Update_Account_Contact_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the Account Contact name with the Account Name and Contact First and Last Names.  APEX is responsible for updating the Participant ID in this string.</description>
        <formula>NOT(ISBLANK( Account__r.Name ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Update Concat %22Contact Name%22</fullName>
        <actions>
            <name>TRAC_ACR_Update_Contact_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the ACR &quot;Contact Name&quot; field with the concatenated value</description>
        <formula>NOT(ISBLANK( Account__r.Name ))</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - ACR - Update Int Status when Rec Status Changes</fullName>
        <actions>
            <name>TRAC_ACR_Int_Pending_Stat_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account_Contact__c.RecordStatus__c</field>
            <operation>equals</operation>
            <value>Active,Inactive</value>
        </criteriaItems>
        <description>Updates the record status to pending integration when the record status is set at record create</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Contact record type to Support</fullName>
        <actions>
            <name>CS_Update_Contact_record_type_to_Support</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account_Contact__c.Contact_Type__c</field>
            <operation>equals</operation>
            <value>Ship To</value>
        </criteriaItems>
        <description>This workflow rule will update contact record type to Support when a ACR is created or updated of type Ship To</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
