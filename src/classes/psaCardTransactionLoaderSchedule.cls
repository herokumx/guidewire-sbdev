/*********************************************************************************************** x
Name            : psaCardTransactionLoaderSchedule
Author          : CLD
Created Date    : Oct 2015
Revision History:

Usage           : Scheduler for card transaction loader
                :
NOTE TO SCHEDULE A NON ON DEMAND FORECAST REPORT ITEM PROCESS RUN A SCRIPT LIKE THIS IN THE SYSTEM CONSOLE:

String seconds   = '0'; //Execute at Zero Seconds
String minutes   = '0'; //Execute at top of every hour (:00 minute)
String hours     = '1'; //Execute at 1:00am
String month     = '*'; //Execute every month
String dayOfWeek = '?'; //Execute on every day of week
String year      = '*'; //Execute every year
String sch = seconds + ' ' + minutes + ' ' + hours + ' * ' + month + ' ' + dayOfWeek + year;
psaCardTransactionLoaderSchedule rfs = new psaCardTransactionLoaderSchedule();
system.schedule('PSA-Card-Transaction-Loader at 01:00', sch, rfs);

***********************************************************************************************/
global class psaCardTransactionLoaderSchedule  implements Schedulable
{
    public static final Integer BATCH_SIZE = 500; // todo...maybe able to increase this!

    // default constructor
    public psaCardTransactionLoaderSchedule()
    {
    }

    global void execute(SchedulableContext sc)
    {
        psaCardTransactionLoaderBatch batchClass = new psaCardTransactionLoaderBatch();
        Id batchID = database.executebatch(batchClass, BATCH_SIZE);
    }
}

/*
//// ensure scheduled date is in future....otherwise set it to run in 30 seconds....
Datetime sysTime = System.now().addSeconds( 30 ) ;
String cronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
Id schedId = system.schedule('PSA-Card-Transaction-Loader  ' +sysTime, cronExpression, new psaCardTransactionLoaderSchedule() );



*/