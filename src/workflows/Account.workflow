<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Approve_Prospect_Partner_Vendor_Customer_Email_Alert</fullName>
        <description>Approve Prospect/Partner/Vendor/Customer Email Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>dmakam@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>rkoul@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Approve_Prospect_Partner_Vendor_Customer</template>
    </alerts>
    <alerts>
        <fullName>Email_Alert_to_record_submitter_Approved</fullName>
        <description>Email Alert to record submitter - Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Approval_Submitter__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/TRAC_Approval_Request_Approved</template>
    </alerts>
    <alerts>
        <fullName>Email_Alert_to_record_submitter_Rejected</fullName>
        <description>Email Alert to record submitter - Rejected</description>
        <protected>false</protected>
        <recipients>
            <field>Approval_Submitter__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/TRAC_Approval_Request_Rejected</template>
    </alerts>
    <alerts>
        <fullName>test_mail</fullName>
        <description>test mail</description>
        <protected>false</protected>
        <recipients>
            <recipient>rkoul@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Approve_Prospect_Partner_Vendor_Customer</template>
    </alerts>
    <fieldUpdates>
        <fullName>Acct_Update_Type_Cust_Acquisition</fullName>
        <description>Update Type to &quot;Customer - Acquisition&quot; when parameters met</description>
        <field>Type</field>
        <literalValue>Customer - Acquisition</literalValue>
        <name>Acct - Update Type Cust Acquisition</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approval Status = Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Pending_Approval</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Approval</literalValue>
        <name>Approval Status = Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Recalled</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Recalled</literalValue>
        <name>Approval Status = Recalled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Rejected</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Approval Status = Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>If_Alliance_Partner_Account_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Partner</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>If Alliance- Partner Account Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Remove_Integation_Pending</fullName>
        <description>When an approval request is rejected, the Integration status field is cleared</description>
        <field>Integration_Status__c</field>
        <name>Remove Integation Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Partner_Status_to_Suspect</fullName>
        <field>Partner_Status__c</field>
        <literalValue>Suspect</literalValue>
        <name>Set Partner Status to Suspect</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_type_to_Alliance</fullName>
        <field>Type</field>
        <literalValue>Alliance</literalValue>
        <name>Set type to Alliance</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_ACCT_Update_LOC_to_Site</fullName>
        <field>Name</field>
        <formula>Name + &quot; -loc&quot;</formula>
        <name>TRAC - ACCT - Update -LOC to Site</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Account_Update_Integration_Stat</fullName>
        <description>Updates integration status to Pending</description>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>TRAC- Account - Update Integration Stat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Account_Update_RecordType</fullName>
        <description>Update record type on account when manual request submitted and is approved</description>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Account - Update RecordType</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Account_Update_Type</fullName>
        <description>Update Type to &quot;Customer - Direct&quot; when parameters met</description>
        <field>Type</field>
        <literalValue>Customer-Direct</literalValue>
        <name>TRAC - Account - Update Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Approval_Resub</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Resubmit Required</literalValue>
        <name>TRAC - Acct Approval Resub</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Integration_Resub</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Resubmit Required</literalValue>
        <name>TRAC - Acct - Integration Resub</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Rec_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Acct - Update Rec Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Rec_Type_Cust</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Acct - Update Rec Type Cust</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Rec_Type_Customer</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Acct - Update Rec Type Customer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Type_Cust_Indirect</fullName>
        <field>Type</field>
        <literalValue>Customer-Indirect</literalValue>
        <name>TRAC - Acct - Update Type Cust Indirect</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Type_Other</fullName>
        <field>Type</field>
        <literalValue>Customer-Other</literalValue>
        <name>TRAC - Acct - Update Type Other</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Acct_Update_Type_Parent</fullName>
        <field>Type</field>
        <literalValue>Customer-Parent</literalValue>
        <name>TRAC - Acct - Update Type Parent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_Alliance_Partner_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Partner</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Update Alliance Partner Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_Alliance_Type</fullName>
        <field>Type</field>
        <literalValue>Potential Partner</literalValue>
        <name>TRAC - Update Alliance Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_PartnerConn_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Partner</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Update PartnerConn Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_PartnerConn_Type</fullName>
        <field>Type</field>
        <literalValue>PartnerConnect - Consulting</literalValue>
        <name>TRAC - Update PartnerConn Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_Partner_Child_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Partner</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>TRAC - Update Partner Child Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TRAC_Update_Partner_Child_Type</fullName>
        <field>Type</field>
        <literalValue>PartnerConnect - Solution</literalValue>
        <name>TRAC - Update Partner Child Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Account_Resub_Status_update</fullName>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>Trac - Account - Resub Status update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Account_Update_Channel</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Trac - Account - Update Channel</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Account_update_channel_type</fullName>
        <field>Type</field>
        <literalValue>Customer-Channel</literalValue>
        <name>Trac - Account - update channel type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Acct_Approval_Pending</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Approval</literalValue>
        <name>Trac - Acct - Approval Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Acct_Resub_Update</fullName>
        <field>Integration_Status__c</field>
        <literalValue>Pending Integration</literalValue>
        <name>Trac - Acct - Resub Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Update_Partner_Type</fullName>
        <description>Updates Account Type field to Technology Partner</description>
        <field>Type</field>
        <literalValue>Partner - Other</literalValue>
        <name>Trac - Update Partner Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Trac_Update_Tech_Partner_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Partner</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Trac - Update Tech Partner Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Account_Name_Internal</fullName>
        <field>Account_Name_Internal__c</field>
        <formula>Name</formula>
        <name>Update Account Name(Internal)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Approval_Submitter_field</fullName>
        <field>Approval_Submitter__c</field>
        <formula>$User.Email</formula>
        <name>Update Approval Submitter field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_City</fullName>
        <field>BillingCity</field>
        <formula>Billing_City__c</formula>
        <name>Update Billing City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_Country</fullName>
        <field>BillingCountry</field>
        <formula>pw_cc__BillingCountryLookup__r.Name</formula>
        <name>Update Billing Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_State</fullName>
        <field>BillingState</field>
        <formula>pw_cc__BillingStateLookup__r.Name</formula>
        <name>Update Billing State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_Street</fullName>
        <field>BillingStreet</field>
        <formula>Billing_Street__c</formula>
        <name>Update Billing Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Billing_Zip_Postal_Code</fullName>
        <field>BillingPostalCode</field>
        <formula>Billing_Zip_Postal_Code__c</formula>
        <name>Update Billing Zip/Postal Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account -Customer Acquisition Update</fullName>
        <actions>
            <name>Acct_Update_Type_Cust_Acquisition</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer - Acquisition</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>Update Record type to Customer - Acquisition and Type to Customer-Acquisition if conditions are met</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Account Name%28Internal%29 update on Account creation</fullName>
        <actions>
            <name>Update_Account_Name_Internal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Account_Name_Internal__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Account%3A If Alliance- Partner Account Record Type</fullName>
        <actions>
            <name>If_Alliance_Partner_Account_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Partner_Status_to_Suspect</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_type_to_Alliance</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND (2 or 3)</booleanFilter>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>Partner Account</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Prospective_Partner_Type__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Alliance_Type__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>If the Account&apos;s prospective partner type is filled in, set record type and Type values - used after lead conversion</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>GW Standard Billing Address change</fullName>
        <actions>
            <name>Update_Billing_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Billing_Zip_Postal_Code</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>ISCHANGED(Billing_City__c) || ISCHANGED(pw_cc__BillingCountryLookup__c) || ISCHANGED(pw_cc__BillingStateLookup__c)|| ISCHANGED(Billing_Street__c) || ISCHANGED(Billing_Zip_Postal_Code__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Alliance Update</fullName>
        <actions>
            <name>TRAC_Update_Alliance_Partner_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Update_Alliance_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>Potential Partner</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Append -loc to Sites</fullName>
        <actions>
            <name>TRAC_ACCT_Update_LOC_to_Site</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Adds a suffix of -LOC to new Site Records</description>
        <formula>RecordType.DeveloperName = &quot;Site&quot; &amp;&amp; (NOT(CONTAINS(Name,&quot; -loc&quot;)))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Customer Channel Update</fullName>
        <actions>
            <name>Trac_Account_Update_Channel</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Trac_Account_update_channel_type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer - Channel</value>
        </criteriaItems>
        <description>Updates the record type to customer and the type to customer-channel</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Customer Other</fullName>
        <actions>
            <name>TRAC_Acct_Update_Rec_Type_Cust</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Acct_Update_Type_Other</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer - Other</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Integration Resub</fullName>
        <actions>
            <name>TRAC_Acct_Approval_Resub</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Acct_Integration_Resub</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT( ISBLANK(Participant_id__c)) &amp;&amp; (NOT(ISPICKVAL(PRIORVALUE(Approval_Status__c), &quot;Pending Approval&quot; ))&amp;&amp; NOT(ISPICKVAL(PRIORVALUE(Approval_Status__c), &quot;Resubmit Required&quot; ))  )&amp;&amp;   
(     
ISCHANGED(Name) ||  
ISCHANGED(BillingCity)||  
ISCHANGED(BillingStreet)||   
ISCHANGED(BillingCountry) ||   
ISCHANGED(BillingState)||  
ISCHANGED(BillingPostalCode) ||  
ISCHANGED(CurrencyIsoCode) ||
ISCHANGED(Invoice_Delivery_Method__c) || 
ISCHANGED(Payment_Term__c) ||  
ISCHANGED(Record_Status__c)  
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Integration Status Update</fullName>
        <actions>
            <name>TRAC_Account_Update_Integration_Stat</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates integration status to Pending when the record is approved and has an Intacct ID</description>
        <formula>!ISNULL(Participant_id__c) &amp;&amp;  ( ( ( ISPICKVAL(Approval_Status__c, &quot;Approved&quot;) &amp;&amp;  TEXT(Integration_Status__c) = &quot;&quot; ) ) || ( ISPICKVAL(PRIORVALUE(Approval_Status__c),&quot;Pending Approval&quot;)&amp;&amp; NOT(ISPICKVAL(Approval_Status__c,&quot;Rejected&quot;)) ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - New Cust Indirect</fullName>
        <actions>
            <name>TRAC_Acct_Update_Rec_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Acct_Update_Type_Cust_Indirect</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer – Indirect</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - New Customer Parent</fullName>
        <actions>
            <name>TRAC_Acct_Update_Rec_Type_Customer</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Acct_Update_Type_Parent</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer – Parent</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Partner Child Acct</fullName>
        <actions>
            <name>TRAC_Update_Partner_Child_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Update_Partner_Child_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>PartnerConnect - Solution</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - PartnerConnect</fullName>
        <actions>
            <name>TRAC_Update_PartnerConn_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Update_PartnerConn_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>PartnerConnect - Consulting</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account - Tech Partner</fullName>
        <actions>
            <name>Trac_Update_Partner_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Trac_Update_Tech_Partner_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>Partner - Other</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>TRAC - Account -Customer Direct Update</fullName>
        <actions>
            <name>TRAC_Account_Update_RecordType</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>TRAC_Account_Update_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Requested_Approval__c</field>
            <operation>equals</operation>
            <value>New Customer - Direct</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>Update Record type to Customer and Type to Customer-Direct if parameters met</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
