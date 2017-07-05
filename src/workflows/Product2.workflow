<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Product_SKU_Approved_Email</fullName>
        <description>Product/SKU Approved Email</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Product_SKU_Approved</template>
    </alerts>
    <alerts>
        <fullName>Product_SKU_Recalled_Email</fullName>
        <description>Product/SKU Recalled Email</description>
        <protected>false</protected>
        <recipients>
            <recipient>Product_Master</recipient>
            <type>group</type>
        </recipients>
        <recipients>
            <field>First_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Product_SKU_Recalled</template>
    </alerts>
    <alerts>
        <fullName>Product_SKU_Rejection_Email</fullName>
        <description>Product/SKU Rejection Email</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Product_SKU_Rejected</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approval_Status_to_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approval Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_to_Pending</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Approval</literalValue>
        <name>Approval Status to Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_to_Recalled</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Recalled</literalValue>
        <name>Approval Status to Recalled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_to_Rejected</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Approval Status to Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Product_Integration_Flag_Integrated</fullName>
        <field>Product_Integration_Status__c</field>
        <literalValue>Integrated</literalValue>
        <name>Set Product Integration Flag Integrated</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Product_Integration_Flag_to_Eligible</fullName>
        <field>Product_Integration_Status__c</field>
        <literalValue>Eligible for Product setup</literalValue>
        <name>Set Product Integration Flag to Eligible</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Product_Integration_Flag_to_InEligib</fullName>
        <field>Product_Integration_Status__c</field>
        <literalValue>Ineligible</literalValue>
        <name>Set Product Integration Flag InEligible</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Standard_Active_field_to_False</fullName>
        <field>IsActive</field>
        <literalValue>0</literalValue>
        <name>Set Standard Active field to False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Standard_Active_field_to_True</fullName>
        <field>IsActive</field>
        <literalValue>1</literalValue>
        <name>Set Standard Active field to True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Active</fullName>
        <field>Status__c</field>
        <literalValue>Active</literalValue>
        <name>Set Status to Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Draft</fullName>
        <field>Status__c</field>
        <literalValue>Draft</literalValue>
        <name>Set Status to Draft</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_In_Active</fullName>
        <field>Status__c</field>
        <literalValue>Inactive in Intacct</literalValue>
        <name>Set Status to In Active</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_First_Approver_to_Ayan</fullName>
        <field>First_Approver__c</field>
        <lookupValue>asarkar@guidewire.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Update First Approver to Ayan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_First_Approver_to_Brian</fullName>
        <field>First_Approver__c</field>
        <lookupValue>bvannoni@guidewire.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Update First Approver to Brian</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_First_Approver_to_Eugene</fullName>
        <field>First_Approver__c</field>
        <lookupValue>elee@guidewire.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Update First Approver to Eugene</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Product_Description_for_Product</fullName>
        <field>Description</field>
        <formula>Name</formula>
        <name>Update Product Description for Product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Product_Name_for_SKU</fullName>
        <field>Name</field>
        <formula>SKU_Name__c</formula>
        <name>Update Product Name for SKU</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Product Description for Product</fullName>
        <actions>
            <name>Update_Product_Description_for_Product</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.RecordTypeId</field>
            <operation>equals</operation>
            <value>Standard Products</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Product Name for SKU</fullName>
        <actions>
            <name>Update_Product_Name_for_SKU</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product2.RecordTypeId</field>
            <operation>equals</operation>
            <value>Sku</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
