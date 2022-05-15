public with sharing class AccountContactTriggerHandler {

    public static void onBeforeInsert(List<AccountContact__c> contacts) {
        Set<Id> contactsIds = new Set<Id>();

        for (AccountContact__c accountContact : contacts) {
            contactsIds.add(accountContact.Contact__c);
        }

        Set<Id> existedPrimaryAccountContacts = getContactsIds(contactsIds);

        for (AccountContact__c accountContact : contacts) {
            accountContact.isPrimary__c = !existedPrimaryAccountContacts.contains(accountContact.Contact__c);
        }
    }

    public static void onAfterUpdate(Map<Id, AccountContact__c> oldRecords, Map<Id, AccountContact__c> newRecords) {
        List<UpdatedAccountContact> updatedAccountContacts = new List<AccountContactTriggerHandler.UpdatedAccountContact>();
        Set<Id> contactIds = new Set<Id>();
        for (AccountContact__c oldAccountContact : oldRecords.values()) {
            if (isUpdated(newRecords.get(oldAccountContact.Id), oldAccountContact)) {
                updatedAccountContacts.add(new UpdatedAccountContact(newRecords.get(oldAccountContact.Id)));
                contactIds.add(newRecords.get(oldAccountContact.Id).Contact__c);
            }
        }

        if (updatedAccountContacts.isEmpty())
            return;

        Map<Id, List<AccountContact__c>> accountContactsByContactIds = getAccountContactsByContactIds(contactIds);
        List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
        for (UpdatedAccountContact updatedAccountContact : updatedAccountContacts) {
            if (accountContactsByContactIds.get(updatedAccountContact.contactId).size() > 1) {
                for (AccountContact__c accountContact : accountContactsByContactIds.get(updatedAccountContact.contactId)) {
                    if (updatedAccountContact.accountContactId != accountContact.Id) {

                        //TODO: case when we update another record AccountContact.isPrimary = true
                        if (updatedAccountContact.isPrimaryValue) {
                            accountContact.isPrimary__c = false;
                            accountContactsForUpdate.add(accountContact);
                        }
                        //TODO: case when we uncheck primary AC record and check is primary the most of new record related with the same contact
                        else {
                            accountContact.isPrimary__c = true;
                            accountContactsForUpdate.add(accountContact);
                            break;
                        }
                    }
                }
            }
        }

        if (!accountContactsForUpdate.isEmpty()) {
            update accountContactsForUpdate;
        }
    }

    private static Boolean isUpdated(AccountContact__c newRecord, AccountContact__c oldRecord) {
        return newRecord.isPrimary__c != oldRecord.isPrimary__c
                && newRecord.Contact__c != null
                && newRecord.Account__c != null;
    }

    private static Set<Id> getContactsIds(Set<Id> contactsIds) {
        Set<Id> ids = new Set<Id>();
        for (AccountContact__c accountContact : getAccountContactsByContactIdsAndPrimary(contactsIds)) {
            ids.add(accountContact.Contact__c);
        }

        return ids;
    }

    private static List<AccountContact__c> getAccountContactsByContactIdsAndPrimary(Set<Id> contactsIds) {
        return [
                SELECT Id
                        , Contact__c
                        , Account__c
                        , isPrimary__c
                FROM AccountContact__c
                WHERE Contact__c IN :contactsIds
                AND isPrimary__c = TRUE
                ORDER BY CreatedDate
        ];
    }

    private static Map<Id, List<AccountContact__c>> getAccountContactsByContactIds(Set<Id> contactsIds) {
        Map<Id, List<AccountContact__c>> result = new Map<Id, List<AccountContact__c>>();

        List<AccountContact__c> accountContacts = [
                SELECT Id
                        , Contact__c
                        , Account__c
                        , isPrimary__c
                FROM AccountContact__c
                WHERE Contact__c IN :contactsIds
                ORDER BY CreatedDate DESC
        ];

        if (accountContacts.isEmpty())
            return result;

        for (AccountContact__c accountContact : accountContacts) {
            if (result.containsKey(accountContact.Contact__c)) {
                result.get(accountContact.Contact__c).add(accountContact);
            } else {
                result.put(accountContact.Contact__c, new List<AccountContact__c>{
                        accountContact
                });
            }
        }

        return result;
    }

    public class UpdatedAccountContact {
        Boolean isPrimaryValue;
        Id contactId;
        Id accountContactId;

        public UpdatedAccountContact(AccountContact__c accountContact) {
            this.contactId = accountContact.Contact__c;
            this.accountContactId = accountContact.Id;
            this.isPrimaryValue = accountContact.isPrimary__c;
        }
    }
}