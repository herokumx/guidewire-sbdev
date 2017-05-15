global class ScheduledSalesEventStatusUpdaterB implements Schedulable  
 {  
    global void execute(SchedulableContext SC) {
      //call out to other class here, but just do work in this execute method
       ScheduledSalesEventStatusUpdater.execute();
      
   }
 }