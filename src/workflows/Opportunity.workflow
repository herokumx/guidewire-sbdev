<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Corp_Ops_on_Closed_Won_Opportunities</fullName>
        <description>Notify Corp Ops on Closed-Won Opportunities</description>
        <protected>false</protected>
        <recipients>
            <recipient>Corp_Ops</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Notify_Corp_Ops_on_Closed_Won_Opportunities</template>
    </alerts>
    <alerts>
        <fullName>Notify_DataManagement_Team</fullName>
        <ccEmails>dm-availability@guidewire.com</ccEmails>
        <description>Notify DataManagement Team</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Notification_Approvals_DataManagement</template>
    </alerts>
    <alerts>
        <fullName>Notify_Data_management_activity</fullName>
        <ccEmails>dm-availability@guidewire.com</ccEmails>
        <description>Notify Data management activity</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Product_Activity</template>
    </alerts>
    <alerts>
        <fullName>Notify_Insurancesuite_activity</fullName>
        <ccEmails>suite-availability@guidewire.com</ccEmails>
        <description>Notify Insurancesuite activity</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Product_Activity</template>
    </alerts>
    <alerts>
        <fullName>Notify_Insurancesuite_product_team</fullName>
        <ccEmails>suite-availability@guidewire.com</ccEmails>
        <description>Notify Insurancesuite product team</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Notification_Approvals_InsuranceSuite</template>
    </alerts>
    <alerts>
        <fullName>Notify_Live_activity</fullName>
        <ccEmails>live-availability@guidewire.com</ccEmails>
        <description>Notify Live activity</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Product_Activity_Live</template>
    </alerts>
    <alerts>
        <fullName>Notify_Live_team</fullName>
        <ccEmails>live-availability@guidewire.com</ccEmails>
        <description>Notify Live team</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Notification_Approvals_Live</template>
    </alerts>
    <alerts>
        <fullName>Notify_Mobile_Portals_team</fullName>
        <ccEmails>mp-availability@guidewire.com</ccEmails>
        <description>Notify Mobile &amp; Portals team</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Notification_Approvals_MobilePortal</template>
    </alerts>
    <alerts>
        <fullName>Notify_Mobile_portals_activity</fullName>
        <ccEmails>mp-availability@guidewire.com</ccEmails>
        <description>Notify Mobile portals activity</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Product_Activity</template>
    </alerts>
    <alerts>
        <fullName>Notify_RFI_Change</fullName>
        <description>Notify RFI Change</description>
        <protected>false</protected>
        <recipients>
            <recipient>RFI_Change</recipient>
            <type>group</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Services_Director__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Notify_RFI_EOI_Change</template>
    </alerts>
    <alerts>
        <fullName>Notify_RFP_Change</fullName>
        <description>Notify RFP Change</description>
        <protected>false</protected>
        <recipients>
            <recipient>RFP_Change</recipient>
            <type>group</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Services_Director__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Notify_RFP_Tender_Change</template>
    </alerts>
    <alerts>
        <fullName>Notify_Standards_based_activity</fullName>
        <ccEmails>sbt-availability@guidewire.com</ccEmails>
        <description>Notify Standards based activity</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Product_Activity</template>
    </alerts>
    <alerts>
        <fullName>Notify_standards_based_templates_team</fullName>
        <ccEmails>sbt-availability@guidewire.com</ccEmails>
        <description>Notify standards based templates team</description>
        <protected>false</protected>
        <recipients>
            <field>Region_Sales_Executive__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PAM_Notification_and_Approvals/PAM_Notification_Approvals_Standardbased</template>
    </alerts>
    <alerts>
        <fullName>PRM_GW_Factors_Notification</fullName>
        <description>PRM GW Factors Notification</description>
        <protected>false</protected>
        <recipients>
            <field>PRM_Partner_Account_Exec_s_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>PRM_Partner_Community/Partner_Community_Opportunity_Notification_to_Partner</template>
    </alerts>
    <alerts>
        <fullName>PRM_Partner_Factors_Notification</fullName>
        <description>PRM Partner Factors Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>dmakam@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>PRM_Partner_Community/Partner_Community_Opportunity_Notification</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_to_Brad_on_Ship_To_update</fullName>
        <description>Send Email to Brad on Ship To update</description>
        <protected>false</protected>
        <recipients>
            <recipient>bbaldwin@guidewire.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Ship_To_update_on_Opportunity</template>
    </alerts>
    <fieldUpdates>
        <fullName>BillingCenter_1</fullName>
        <field>BillingCenter__c</field>
        <formula>1</formula>
        <name>BillingCenter=1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_RT_to_Customer</fullName>
        <description>Changes Account RT to Customer.</description>
        <field>RecordTypeId</field>
        <lookupValue>Customer</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Change RT to Customer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Contracted_Checkbox</fullName>
        <field>SBQQ__Contracted__c</field>
        <literalValue>1</literalValue>
        <name>Check Contracted Checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>ClaimCenter_1</fullName>
        <field>ClaimCenter__c</field>
        <formula>1</formula>
        <name>ClaimCenter=1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>DataHub_1</fullName>
        <field>DataHub__c</field>
        <formula>1</formula>
        <name>DataHub=1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>GuidewireLive_0</fullName>
        <field>GuidewireLive__c</field>
        <formula>0</formula>
        <name>GuidewireLive = 0</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>GuidewireLive_1</fullName>
        <field>GuidewireLive__c</field>
        <formula>1</formula>
        <name>GuidewireLive = 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Infocenter_1</fullName>
        <field>InfoCenter__c</field>
        <formula>1</formula>
        <name>Infocenter=1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Type_Renewal</fullName>
        <field>Opportunity_Type__c</field>
        <literalValue>Renewal Type</literalValue>
        <name>Opportunity Type - Renewal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PolicyCenter_1</fullName>
        <field>PolicyCenter__c</field>
        <formula>1</formula>
        <name>PolicyCenter=1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Premium_In_Scope</fullName>
        <field>Premium_In_Scope__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.Premium_In_Scope__c</formula>
        <name>Premium In Scope</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Premium_In_Scope2</fullName>
        <field>Premium_In_Scope__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.Premium_In_Scope__c</formula>
        <name>Premium In Scope</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Region_AMER</fullName>
        <description>Set region to AMER</description>
        <field>Region__c</field>
        <literalValue>AMER</literalValue>
        <name>Region - AMER</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Region_APAC</fullName>
        <description>Set region to APAC</description>
        <field>Region__c</field>
        <literalValue>APAC</literalValue>
        <name>Region - APAC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Region_EMEA</fullName>
        <description>Set region to EMEA.</description>
        <field>Region__c</field>
        <literalValue>EMEA</literalValue>
        <name>Region - EMEA</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sales_Executive_AMER</fullName>
        <field>Region_Sales_Executive__c</field>
        <formula>&quot;amer-product-availability-copy-list@guidewire.com&quot;</formula>
        <name>Sales Executive - AMER</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sales_Executive_APAC</fullName>
        <field>Region_Sales_Executive__c</field>
        <formula>&quot;apac-product-availability-copy-list@guidewire.com&quot;</formula>
        <name>Sales Executive - APAC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sales_Executive_EMEA</fullName>
        <field>Region_Sales_Executive__c</field>
        <formula>&quot;emea-product-availability-copy-list@guidewire.com&quot;</formula>
        <name>Sales Executive - EMEA</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Acct_Type_to_Active_Opp</fullName>
        <field>Type</field>
        <literalValue>Prospect - Active Opportunity</literalValue>
        <name>Set Acct Type to Active Opp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Acct_Type_to_Customer</fullName>
        <field>Type</field>
        <literalValue>Customer-Direct</literalValue>
        <name>Set Acct Type to Customer</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Acct_Type_to_Prospect</fullName>
        <field>Type</field>
        <literalValue>Prospect</literalValue>
        <name>Set Acct Type to Prospect</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Premium_In_Scope</fullName>
        <field>Premium_In_Scope__c</field>
        <formula>pse__Parent_Opportunity__r.Premium_In_Scope__c</formula>
        <name>Set Premium In-Scope</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Standard_Price_Book_automatically</fullName>
        <field>SBQQ__QuotePricebookId__c</field>
        <formula>&quot;01s3000000007kA&quot;</formula>
        <name>Set Standard Price Book automatically</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Term_Sequance</fullName>
        <field>CPQ_Term_Sequence__c</field>
        <formula>3</formula>
        <name>Term Sequance</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Term_Sequence</fullName>
        <field>CPQ_Term_Sequence__c</field>
        <formula>IF(pse__Parent_Opportunity__r.CPQ_Term_Sequence__c = 1, 3, pse__Parent_Opportunity__r.CPQ_Term_Sequence__c + 1)</formula>
        <name>Term Sequence</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Term_Sequence2</fullName>
        <field>CPQ_Term_Sequence__c</field>
        <formula>4</formula>
        <name>Term Sequance</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Closed_Date</fullName>
        <field>CloseDate</field>
        <formula>TODAY()</formula>
        <name>Update Closed Date on Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_DM_Requested_Date</fullName>
        <field>Requested_Date_DM__c</field>
        <formula>TODAY()</formula>
        <name>Update DM Requested Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_GW_Live_Count</fullName>
        <field>GuidewireLive__c</field>
        <formula>1</formula>
        <name>Update GW Live Count</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_InsuranceSuite_Requested_Date</fullName>
        <field>Requested_Date_InsuranceSuite__c</field>
        <formula>TODAY()</formula>
        <name>Update InsuranceSuite Requested Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Live_Requested_Date</fullName>
        <field>Requested_Date_Live__c</field>
        <formula>TODAY()</formula>
        <name>Update Live Requested Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_M_P_Requested_Date</fullName>
        <field>Requested_Date_MP__c</field>
        <formula>TODAY()</formula>
        <name>Update M&amp;P Requested Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_RFI_Approval_SC</fullName>
        <field>RFI_Approval_SC__c</field>
        <literalValue>Requested</literalValue>
        <name>Update RFI Approval - SC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_RFI_Approval_SD</fullName>
        <field>RFI_Approval_SD__c</field>
        <literalValue>Requested</literalValue>
        <name>Update RFI Approval - SD</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_RFP_Approval_SC</fullName>
        <field>RFP_Approval_SC__c</field>
        <literalValue>Requested</literalValue>
        <name>Update RFP Approval - SC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_RFP_Approval_SD</fullName>
        <field>RFP_Approval_SD__c</field>
        <literalValue>Requested</literalValue>
        <name>Update RFP Approval - SD</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_SBT_Requested_Date</fullName>
        <field>Requested_Date_SBP__c</field>
        <formula>TODAY()</formula>
        <name>Update SBT Requested Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Year_3_Ramp_Up</fullName>
        <field>CPQ_Year_3_Ramp_Up__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.CPQ_Year_3_Ramp_Up__c</formula>
        <name>Year 3 Ramp-Up</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Year_4_Ramp_Up</fullName>
        <field>CPQ_Year_4_Ramp_Up__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.CPQ_Year_4_Ramp_Up__c</formula>
        <name>Year 4 Ramp-Up</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Year_4_Ramp_Up2</fullName>
        <field>CPQ_Year_4_Ramp_Up__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.CPQ_Year_4_Ramp_Up__c</formula>
        <name>Year 4 Ramp-Up</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Year_5_Ramp_Up</fullName>
        <field>CPQ_Year_5_Ramp_Up__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.CPQ_Year_5_Ramp_Up__c</formula>
        <name>Year 5 Ramp-Up</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Year_5_Ramp_Up2</fullName>
        <field>CPQ_Year_5_Ramp_Up__c</field>
        <formula>Contract.SBQQ__RenewalOpportunity__r.pse__Parent_Opportunity__r.CPQ_Year_5_Ramp_Up__c</formula>
        <name>Year 5 Ramp-Up</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Check Contracted Checkbox on Closed Won Opportunity</fullName>
        <actions>
            <name>Check_Contracted_Checkbox</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.IsWon</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>CPQ - When an opportunity is closed won, the contracted checkbox is checked. This converts any eligible products to assets and creates a contract.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Fields Auto-populated %28Opportunity Sequence 4%29</fullName>
        <actions>
            <name>Opportunity_Type_Renewal</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Premium_In_Scope2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Term_Sequence2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Year_4_Ramp_Up2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Year_5_Ramp_Up2</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Type</field>
            <operation>equals</operation>
            <value>Renewal Opportunity</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If BillingCenter%2C 1</fullName>
        <actions>
            <name>BillingCenter_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Type__c</field>
            <operation>includes</operation>
            <value>BillingCenter</value>
        </criteriaItems>
        <description>Update field so roll up on account include this product when the opportunity is won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If ClaimCenter%2C 1</fullName>
        <actions>
            <name>ClaimCenter_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Type__c</field>
            <operation>includes</operation>
            <value>ClaimCenter</value>
        </criteriaItems>
        <description>Update field so roll up on account include this product when the opportunity is won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If DataHub%2C 1</fullName>
        <actions>
            <name>DataHub_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Type__c</field>
            <operation>includes</operation>
            <value>DataHub</value>
        </criteriaItems>
        <description>Update field so roll up on account include this product when the opportunity is won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If GuidewireLive Closed%2C 1</fullName>
        <actions>
            <name>GuidewireLive_0</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Guidewire Live Opportunity</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.IsClosed</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If GuidewireLive open%2C 1</fullName>
        <actions>
            <name>GuidewireLive_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Guidewire Live Opportunity</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.IsClosed</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Eval the rule when the record is created or subsiquenty met</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If InfoCenter%2C 1</fullName>
        <actions>
            <name>Infocenter_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Type__c</field>
            <operation>includes</operation>
            <value>InfoCenter</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>If PolicyCenter%2C 1</fullName>
        <actions>
            <name>PolicyCenter_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Type__c</field>
            <operation>includes</operation>
            <value>PolicyCenter</value>
        </criteriaItems>
        <description>Update field so roll up on account include this product when the opportunity is won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Notify Data management activity</fullName>
        <actions>
            <name>Notify_Data_management_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Data_Management_Approved__c), Data_Management_Approved__c = true), AND( ISCHANGED(Data_Management_Approved_PMM__c),Data_Management_Approved_PMM__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Data management activity notes</fullName>
        <actions>
            <name>Notify_Data_management_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Data_Management_Approval_Comments__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify DataManagement Team</fullName>
        <actions>
            <name>Notify_DataManagement_Team</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_DM_Requested_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Request_Data_Management_Approval__c), Request_Data_Management_Approval__c = true), AND(  ISNEW(),Request_Data_Management_Approval__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Insurancesuite activity</fullName>
        <actions>
            <name>Notify_Insurancesuite_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(InsuranceSuite_Approved__c), InsuranceSuite_Approved__c ==true), AND( ISCHANGED(Insurance_Suite_Approved_PMM__c),Insurance_Suite_Approved_PMM__c =true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Insurancesuite activity notes</fullName>
        <actions>
            <name>Notify_Insurancesuite_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( InsuranceSuite_Approval_Comments__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Insurancesuite product team</fullName>
        <actions>
            <name>Notify_Insurancesuite_product_team</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_InsuranceSuite_Requested_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED( Request_Insurance_Suite_Approval__c ), Request_Insurance_Suite_Approval__c = true ), AND( ISNEW(), Request_Insurance_Suite_Approval__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Live activity</fullName>
        <actions>
            <name>Notify_Live_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Live_Approved__c), Live_Approved__c = true), AND( ISCHANGED(Live_Approved_PPM__c),Live_Approved_PPM__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Live activity notes</fullName>
        <actions>
            <name>Notify_Live_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Live_Approval_comments__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Live team</fullName>
        <actions>
            <name>Notify_Live_team</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Live_Requested_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Request_Live_Approval__c), Request_Live_Approval__c = true), AND(  ISNEW(), Request_Live_Approval__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Mobile and Portals Team</fullName>
        <actions>
            <name>Notify_Mobile_Portals_team</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_M_P_Requested_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( AND(ISCHANGED( Request_Mobile_Portals_Approval__c ), Request_Mobile_Portals_Approval__c = true), AND( ISNEW(), Request_Mobile_Portals_Approval__c = true ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Mobile portals activity</fullName>
        <actions>
            <name>Notify_Mobile_portals_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Mobile_Portals_Approved__c), Mobile_Portals_Approved__c ==true), AND( ISCHANGED(Mobile_Portals_Approved_PMM__c),Mobile_Portals_Approved_PMM__c =true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Mobile portals activity notes</fullName>
        <actions>
            <name>Notify_Mobile_portals_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Mobile_and_Portal_Approval_Comments__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify RFI Change</fullName>
        <actions>
            <name>Notify_RFI_Change</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_RFI_Approval_SC</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_RFI_Approval_SD</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISPICKVAL(Region__c,&apos;EMEA&apos;), OR(ISCHANGED(RFI_EOI_Received__c), AND(ISNEW(),NOT(ISNULL(RFI_EOI_Received__c))),ISCHANGED(RFI_EOI_Due__c),AND(ISNEW(),NOT(ISNULL(RFI_EOI_Due__c)))))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify RFP Change</fullName>
        <actions>
            <name>Notify_RFP_Change</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_RFP_Approval_SC</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_RFP_Approval_SD</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISPICKVAL(Region__c,&apos;EMEA&apos;),OR(ISCHANGED( RFP_Tender_Received__c ), AND(ISNEW(),NOT(ISNULL(RFP_Tender_Received__c))),ISCHANGED( RFP_Tender_Due__c ),AND(ISNEW(),NOT(ISNULL(RFP_Tender_Due__c)))))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Standard based Templates team</fullName>
        <actions>
            <name>Notify_standards_based_templates_team</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_SBT_Requested_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Request_Standards_based_Approval__c), Request_Standards_based_Approval__c = true), AND( ISNEW(), Request_Standards_based_Approval__c = true ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Standards based activity</fullName>
        <actions>
            <name>Notify_Standards_based_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>OR( AND( ISCHANGED(Standards_based_Templates_Approved__c), Standards_based_Templates_Approved__c = true), AND( ISCHANGED(Standards_based_Templates_Approved_PMM__c),Standards_based_Templates_Approved_PMM__c = true))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Standards based activity notes</fullName>
        <actions>
            <name>Notify_Standards_based_activity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Standards_based_Approval_Comments__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>PRM GW Factors Notification</fullName>
        <actions>
            <name>PRM_GW_Factors_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(PRM_GW_Revenue_Sharing_Frequency__c) || ISCHANGED(PRM_GW_Revenue_Sharing_Rate__c) || ISCHANGED(PRM_GW_Integration_Existence_Factor__c) || ISCHANGED(PRM_GW_Contribution_Factor__c) || ISCHANGED(PRM_Influence_Factor_Rate__c) || ISCHANGED(PRM_Guidewire_Revenue_Share__c) || ISCHANGED(Product_Type__c) || ISCHANGED(Add_On_Modules__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>PRM Partner Factors Notification</fullName>
        <actions>
            <name>PRM_Partner_Factors_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Triggers when any of the partner factors change.</description>
        <formula>ISCHANGED(PRM_Revenue_Sharing_Frequency__c) || ISCHANGED(PRM_Revenue_Sharing_Rate__c) || ISCHANGED(PRM_Integration_Existence_Factor__c) || ISCHANGED(PRM_Partner_Contribution_Factor__c) || ISCHANGED(PRM_Partner_Influence_Factor__c) || ISCHANGED(PRM_Partner_Revenue_Share__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Populate Renewal Opportunity Fields</fullName>
        <actions>
            <name>Set_Premium_In_Scope</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Term_Sequence</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>NOT(ISNULL( pse__Parent_Opportunity__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Region - AMER</fullName>
        <actions>
            <name>Region_AMER</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sales_Executive_AMER</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>User.UserRoleId</field>
            <operation>startsWith</operation>
            <value>North American,The Americas,NA</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>rohearn@guidewire.com,smccolloch@guidewire.com,thuber@guidewire.com</value>
        </criteriaItems>
        <description>Rule that fires when Role of Created By is AMER sales.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Region - APAC</fullName>
        <actions>
            <name>Region_APAC</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sales_Executive_APAC</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>User.UserRoleId</field>
            <operation>startsWith</operation>
            <value>International-AP,AP,ANZ,Japan</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>space@guidewire.com</value>
        </criteriaItems>
        <description>Rule that fires when Role of Created By is APAC sales.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Region - EMEA</fullName>
        <actions>
            <name>Region_EMEA</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sales_Executive_EMEA</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>User.UserRoleId</field>
            <operation>startsWith</operation>
            <value>International-EMEA,EMEA,N Europe,DACH,S Europe,UKI,FrIt</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>yherzog@guidewire.com,amahmood@guidewire.com,ebreton@guidewire.com</value>
        </criteriaItems>
        <description>Rule that fires when Role of Created By is EMEA sales.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Standard Price Book automatically</fullName>
        <actions>
            <name>Set_Standard_Price_Book_automatically</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Ship To change on Opportunity</fullName>
        <actions>
            <name>Send_Email_to_Brad_on_Ship_To_update</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>Send email to Brad when Ship to is changed on Opportunity</description>
        <formula>ISCHANGED(Ship_To__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Account from Active to Customer</fullName>
        <actions>
            <name>Change_RT_to_Customer</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Acct_Type_to_Customer</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.IsWon</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Type</field>
            <operation>equals</operation>
            <value>Prospect,Prospect - Active Opportunity</value>
        </criteriaItems>
        <description>when an Opportunity is won and Account is in Active, move to Customer</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Account from Active to Prospect</fullName>
        <actions>
            <name>Set_Acct_Type_to_Prospect</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.IsWon</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.IsClosed</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Type</field>
            <operation>equals</operation>
            <value>Prospect - Active Opportunity</value>
        </criteriaItems>
        <description>when an Opportunity is lost and Account is in Active, move back to Prospect</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Account from Prospect to Active</fullName>
        <actions>
            <name>Set_Acct_Type_to_Active_Opp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Qualified</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Type</field>
            <operation>equals</operation>
            <value>Prospect</value>
        </criteriaItems>
        <description>When an open Opportunity Stage =  Qualified and Account is in Prospect, move to Active</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Closed date for Closed-Won Opportunities</fullName>
        <actions>
            <name>Notify_Corp_Ops_on_Closed_Won_Opportunities</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Closed_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( OR(CloseDate &lt;= TODAY(),CloseDate &gt; TODAY()), ISPICKVAL( StageName , &apos;Closed - Won&apos;), ISCHANGED(StageName) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Closed date for Lost Opportunities</fullName>
        <actions>
            <name>Update_Closed_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( OR(CloseDate  &lt;  TODAY(), CloseDate  &gt;  TODAY()), OR(ISPICKVAL(StageName,&apos;No Intent to Buy&apos;), ISPICKVAL(StageName,&apos;Project Cancelled&apos;), ISPICKVAL(StageName,&apos;Opportunity Died&apos;), ISPICKVAL(StageName,&apos;Guidewire Excluded&apos;), ISPICKVAL(StageName,&apos;Dead/Dry&apos;)), ISCHANGED(StageName))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
