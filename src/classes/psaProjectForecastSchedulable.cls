/****************************************************************************************
Name            : psaProjectForecastSchedulable
Author          : CLD
Created Date    : April 29, 2015
Description     : Contains methods for letting the Project Forecast calculation be run 
				: by the system scheduler.
                : 
                
NOTE: TO SCHEDULE THE PROCESS RUN A SCRIPT LIKE THIS IN THE SYSTEM CONSOLE:

String seconds = '0'; //Execute at Zero Seconds
String minutes = '0'; //Execute at top of the hour (:00 minute)
String hours = '1,13'; // Execute at 1:00am and 1:00pm
String month = '*'; //Execute every month
String dayOfWeek = '?'; //Execute on every day of weeek
String year = '*'; //Execute every year
String sch = seconds + ' ' + minutes + ' ' + hours + ' * ' + month + ' ' + dayOfWeek + year;
psaProjectForecastSchedulable pfs = new psaProjectForecastSchedulable();
system.schedule('PSA Project Forecast Calc at 01:00 & 13:00', sch, pfs);
******************************************************************************************/
global class psaProjectForecastSchedulable implements Schedulable
{
    global void execute(SchedulableContext sc) 
    {
        integer BATCH_SIZE = 20; 
        
        psaProjectForecastBatch projectForecastBatch = new psaProjectForecastBatch();
        System.debug('**** psaProjectForecastSchedulable: starting batch exection *****************');

        Id batchId = database.executeBatch(projectForecastBatch, BATCH_SIZE);    
        
        System.debug('**** psaProjectForecastSchedulable: Batch executed batchId: ' +batchId); 
    }
}