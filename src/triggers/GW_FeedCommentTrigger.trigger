/*
*****************************************************************************************************************************
Class Name - GW_FeedCommentTrigger
Trig -  Handler
Test Class-
Purpose- 


*****************************************************************************************************************************

Name        Email              Date             Notes 
Mani G                        08/04/2016       Initial Creation

*****************************************************************************************************************************
*/
trigger GW_FeedCommentTrigger on FeedComment (before insert) {
     for(FeedComment fc : trigger.new)
       if((fc.CommentType== 'TextComment' || fc.CommentType== 'ContentComment') && (fc.ParentId.getSObjectType() == Case.SObjectType))
                fc.addError('Comments are not allowed on Case feed. Please create a new Post');
 }