<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PSA_Contact_Set_Mailing_Country</fullName>
        <field>MailingCountry</field>
        <formula>PSA_Home_Country__r.Name</formula>
        <name>PSA Contact Set Mailing Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PSA_Contact_Set_Mailing_State</fullName>
        <field>MailingState</field>
        <formula>PSA_Home_State__r.Name</formula>
        <name>PSA Contact Set Mailing State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PSA_Update_Resource_Start_Date</fullName>
        <description>PSA - Update resource start date to hire date + 90 days</description>
        <field>pse__Start_Date__c</field>
        <formula>PSA_Hire_Date__c + 90</formula>
        <name>PSA Update Resource Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Print_As_Firstname_Lastname</fullName>
        <field>Print_As__c</field>
        <formula>FirstName + &quot; &quot; + LastName</formula>
        <name>Print As = Firstname + Lastname</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>PSA Contact Set Mailing Country</fullName>
        <actions>
            <name>PSA_Contact_Set_Mailing_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>If the value of Home Country (lookup to the country object) changes, then this workflow rule will fire and copy the text value of the lookup value to the Contact Mailing Country</description>
        <formula>AND( ISCHANGED( PSA_Home_Country__c ), NOT( ISBLANK( PSA_Home_Country__c ) ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>PSA Contact Set Mailing State</fullName>
        <actions>
            <name>PSA_Contact_Set_Mailing_State</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>If the value of Home State (lookup to the state object) changes, then this workflow rule will fire and copy the text values of the lookup value to the Contact Mailing State</description>
        <formula>AND( NOT( ISBLANK(PSA_Home_Country__c ) ), OR( PSA_Home_Country__r.pw_cc__IsoCode_3__c = &apos;USA&apos;, PSA_Home_Country__r.pw_cc__IsoCode_3__c = &apos;CAN&apos;),    AND(ISCHANGED( PSA_Home_State__c ),NOT( ISBLANK(PSA_Home_State__c))) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC-Contact-Default populate blank Print As field on Create</fullName>
        <actions>
            <name>Print_As_Firstname_Lastname</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Print_As__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
