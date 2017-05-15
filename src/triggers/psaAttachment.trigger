trigger psaAttachment on Attachment (before insert, before update, before delete, after insert, after update) {
	psaTriggerHandlerFactory.createHandler(Attachment.sObjectType);

}