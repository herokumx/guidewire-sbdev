/**************************************************************************************
// Name          : psaTriggerHandlerException
// Date          : February 4, 2015
// Description   : Exception class for the trigger handler code
//                 Based on the recipe from:
//                 http://developer.force.com/cookbook/recipe/trigger-pattern-for-tidy-streamlined-bulkified-triggers
// Author        : CLD Partners
// Revisions     : 2015-02-04   Schwartz  Initial version
***************************************************************************************/
public class psaTriggerHandlerException extends Exception
{
    public psaTriggerHandlerException(String errorMessage, Boolean t)
    {
        setMessage(errorMessage);
    }
}