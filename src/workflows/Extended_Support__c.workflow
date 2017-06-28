<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>X18_Month_Extended_Support_Notice</fullName>
        <ccEmails>AMER_SalesOps_CRM@guidewire.com, ssherry@guidewire.com, smccolloch@guidewire.com</ccEmails>
        <description>18 Month Extended Support Notice</description>
        <protected>false</protected>
        <recipients>
            <field>Primary_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>CRM_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>smccolloch@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Extended_Support/X18_Month_Extended_Support_Notice</template>
    </alerts>
    <alerts>
        <fullName>XX180_Day_Notice_Email</fullName>
        <ccEmails>AMER_SalesOps_CRM@guidewire.com, ssherry@guidewire.com, smccolloch@guidewire.com</ccEmails>
        <description>180 Day Notice Email</description>
        <protected>false</protected>
        <recipients>
            <field>Primary_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>CRM_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>smccolloch@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Extended_Support/XX180DayNoticeEmail</template>
    </alerts>
    <alerts>
        <fullName>XX90_Day_Notification</fullName>
        <ccEmails>AMER_SalesOps_CRM@guidewire.com, ssherry@guidewire.com, smccolloch@guidewire.com</ccEmails>
        <description>90 Day Notification (25+ months)</description>
        <protected>false</protected>
        <recipients>
            <field>Primary_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>CRM_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>smccolloch@guidewire.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Extended_Support/XX90DayNoticeEmail</template>
    </alerts>
    <fieldUpdates>
        <fullName>ES_Begin_Charging_Extended_Support</fullName>
        <description>Field update used to populate Begin Charging Extended Support with value of Extended Support Begins.</description>
        <field>Begin_Charging_Extended_Support__c</field>
        <formula>Extended_Support_Begins__c</formula>
        <name>ES: Begin Charging Extended Support</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Clear_out_180_Day</fullName>
        <field>X180_Day_Initial_Notification_Due__c</field>
        <name>Extended Support: Clear out 180 Day</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Clear_out_18_Month</fullName>
        <field>X18_Month_Initial_Notification__c</field>
        <name>Extended Support: Clear out 18 Month</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Clear_out_Begin_Date</fullName>
        <field>Begin_Charging_Extended_Support__c</field>
        <name>Extended Support: Clear out Begin Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Populate_180_Day</fullName>
        <description>180 Day Notification should default to 180 Days before the date of Begin Charging Extended Support</description>
        <field>X180_Day_Initial_Notification_Due__c</field>
        <formula>Begin_Charging_Extended_Support__c - 180</formula>
        <name>Extended Support: Populate 180 Day</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Populate_18_months_Dat</fullName>
        <description>Populates 18 Months Initial Notification 18 months (547 days) before the date of Extended Support Begins date.</description>
        <field>X18_Month_Initial_Notification__c</field>
        <formula>Begin_Charging_Extended_Support__c - 547</formula>
        <name>Extended Support: Populate 18 month Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Populate_90_Day</fullName>
        <description>90 Day Notification should default to 90 Days before the date of Begin Charging Extended Support</description>
        <field>X90_Day_Notification_of_Increased_fees__c</field>
        <formula>Date_Extended_Support_Increases_to_60__c  - 90</formula>
        <name>Extended Support: Populate 90 Day</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Populate_CRM_Email</fullName>
        <description>Field update that populates CRM email field.  Used for Workflow Email Alert.</description>
        <field>CRM_Email__c</field>
        <formula>Account__r.Customer_Relationship_Mgr__r.Email</formula>
        <name>Extended Support: Populate CRM Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Extended_Support_Set_Ver_Field</fullName>
        <description>Used to shorten Extended Support Begins formula.  Needed in order to make it less than 5000 when compiled.</description>
        <field>Ver__c</field>
        <formula>CASE( Version__c, 
&apos;PolicyCenter 7&apos;,&apos;PC7&apos;,
&apos;PolicyCenter 8&apos;,&apos;PC8&apos;,
&apos;PolicyCenter 4&apos;,&apos;PC4&apos;,
&apos;PolicyCenter 3&apos;,&apos;PC3&apos;,
&apos;ClaimCenter 4&apos;,&apos;CC4&apos;,
&apos;ClaimCenter 5&apos;,&apos;CC5&apos;,
&apos;ClaimCenter 6&apos;,&apos;CC6&apos;,
&apos;ClaimCenter 7&apos;,&apos;CC7&apos;,
&apos;ClaimCenter 8&apos;,&apos;CC8&apos;,
&apos;BillingCenter 2&apos;,&apos;BC2&apos;,
&apos;BillingCenter 3&apos;,&apos;BC3&apos;,
&apos;BillingCenter 7&apos;,&apos;BC7&apos;,
&apos;BillingCenter 8&apos;,&apos;BC8&apos;,
null
)</formula>
        <name>Extended Support: Set Ver Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>18 Month Extended Support Notice</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Extended_Support__c.X18_Month_Initial_Notification__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Extended_Support__c.X18_Month_N__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>WF Rule used to send time dependent email alert relating to Extended Support.  This rule sends email on 18 Month Initial Notification Date.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>X18_Month_Extended_Support_Notice</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>XX18MonthEmailSent</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Extended_Support__c.X18_Month_Initial_Notification__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>180 Day Notification</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Extended_Support__c.X180_Day_Initial_Notification_Due__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Extended_Support__c.X180_Day_Email__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>WF Rule used to send time dependent email alert relating to Extended Support.  This rule sends on 180 Day date.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>XX180_Day_Notice_Email</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>X180_DaySent</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Extended_Support__c.X180_Day_Initial_Notification_Due__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>90 Day Notification %2825%2B months%29</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Extended_Support__c.X90_Day_Notification_of_Increased_fees__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Extended_Support__c.X90_Day_Email__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>WF Rule used to send time dependent email alert relating to Extended Support.  This rule sends email on 90 Day Notification Date.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>XX90_Day_Notification</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>XX18MonthEmail_Sent_task</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Extended_Support__c.X90_Day_Notification_of_Increased_fees__c</offsetFromField>
            <timeLength>-1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>ES%3A Populate Begin Dates</fullName>
        <actions>
            <name>Extended_Support_Populate_180_Day</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Extended_Support_Populate_18_months_Dat</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Extended_Support_Populate_90_Day</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires when Begin Charging Extended Support is populated.</description>
        <formula>ISBLANK( PRIORVALUE( Begin_Charging_Extended_Support__c )) || ISCHANGED( Begin_Charging_Extended_Support__c ) || NOT(ISNULL(Begin_Charging_Extended_Support__c))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>ES%3A Populate Dates</fullName>
        <actions>
            <name>ES_Begin_Charging_Extended_Support</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Extended_Support_Populate_180_Day</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Extended_Support_Populate_18_months_Dat</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Extended_Support_Populate_90_Day</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Fires when Extended Support Begins is changed.</description>
        <formula>(ISBLANK(PRIORVALUE(  Extended_Support_Begins__c  ))) || ISCHANGED( Extended_Support_Begins__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Extended Support%3A Always Fire</fullName>
        <actions>
            <name>Extended_Support_Populate_CRM_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Rule that always fires.  Used to populate CRM Email address from Account.</description>
        <formula>TRUE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Extended Support%3A Populate Ver Changed</fullName>
        <actions>
            <name>Extended_Support_Set_Ver_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Used to populate ver field.  Needed to shorten Extended Support Begins formula field.</description>
        <formula>NOT(ISBLANK( Version_RUH__c )) || ISCHANGED( Version_RUH__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>X180_DaySent</fullName>
        <assignedTo>sschleppenbach@guidewire.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>The 180 Day Notice Email Notification has been sent to the Primary Contact of this Extended Support Record.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>180 Day Notice Email Sent</subject>
    </tasks>
    <tasks>
        <fullName>XX18MonthEmailSent</fullName>
        <assignedTo>sschleppenbach@guidewire.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>The 18 Month Extended Support Email Notification has been sent to the Primary Contact of this Extended Support Record.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>18 Month Extended Support Notice Sent</subject>
    </tasks>
    <tasks>
        <fullName>XX18MonthEmail_Sent_task</fullName>
        <assignedTo>sschleppenbach@guidewire.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>The 90 Day Email Notification has been sent to the Primary Contact of this Extended Support Record.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>90 Day Notification Sent</subject>
    </tasks>
</Workflow>
