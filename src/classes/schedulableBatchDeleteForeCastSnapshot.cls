global class schedulableBatchDeleteForeCastSnapshot implements Schedulable {
global void execute(SchedulableContext scMain) {
BatchDeleteForeCastSnapshot batch = new BatchDeleteForeCastSnapshot();
ID idBatch = Database.executeBatch(batch, 200);
}
}