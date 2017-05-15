/**************************************************************************************
// Name          : psaContact Trigger
// Date          : March 12, 2015
// Description   : psaContact Trigger
// Author        : CLD Partners
// Revisions     : 2015-02-06  Schwartz  Initial version
***************************************************************************************/
trigger psaContact on Contact (before insert, after insert, before update, after update) {
	psaTriggerHandlerFactory.createHandler(Contact.sObjectType);
}