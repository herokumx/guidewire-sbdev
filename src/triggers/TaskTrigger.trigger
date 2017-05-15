/**********
Trigger: Task Trigger
Description: Task trigger to manage all operations related to Task.
a. handle task creation from MH sheets and email to assigned person.

Created: 09/30/2015
Created By: Rohit Koul*/

trigger TaskTrigger on Task (after insert)  { 
    
	// Scope for additional DML operations.

	// Call on after insert.
    if(Trigger.isAfter && Trigger.isInsert)
    {
       TaskTriggerUtil.sendEmailNotificationToTaskOwner(Trigger.new);
	}
        
}