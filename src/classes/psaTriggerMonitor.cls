/****************************************************************************************
Name            : psaTriggerMonitor
Author          : CLD Partners 
                  From recipe: 
                  http://blog.internetcreations.com/2012/07/the-spouse-situation-and-avoiding-recursive-triggers-in-salesforce/
Created Date    : February 4, 2015
Description     : Used to prevent trigger recursion
******************************************************************************************/

public class psaTriggerMonitor 
{
    public static set<string> ExecutedTriggers = new set<string>();
}