trigger AccountContactTrigger on AccountContact__c (before insert, after update, after delete) {

    if (Recursive.runOnce()) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                AccountContactTriggerHandler.onBeforeInsert(Trigger.new);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isUpdate) {
                AccountContactTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}