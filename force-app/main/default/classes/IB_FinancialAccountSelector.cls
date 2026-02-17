public with sharing class IB_FinancialAccountSelector {

    /**
     * Fetch Financial Account details by Id
     * @param faId Financial Account Id
     * @return Financial Account record with key fields including RecordType
     */
    public static FinServ__FinancialAccount__c getFinancialAccountById(Id faId) {
        return [
            SELECT Id,
                   Name,
                   FinServ__FinancialAccountNumber__c,
                   RecordTypeId,
                   RecordType.DeveloperName,
                   RecordType.Name
            FROM FinServ__FinancialAccount__c
            WHERE (Id = :faId AND RecordType.Name = 'Loan Account')
            WITH USER_MODE
            LIMIT 1
        ];
    }

    public static FinServ__FinancialAccount__c getCreditCardById(Id cardId) {
        return [
            SELECT Id, Name, RecordType.Name, IB_MaskedCardNumber__c, IB_FromDate__c, IB_ToDate__c, FinServ__PrimaryOwner__r.Phone
            FROM FinServ__FinancialAccount__c
            WHERE (Id = :cardId AND RecordType.Name = 'Credit Card')
            WITH USER_MODE
            LIMIT 1
        ];
    }

    public static FinServ__Card__c getCardById(Id cardId) {
        return [
            SELECT Id, Name, RecordType.Name
            FROM FinServ__Card__c
            WHERE (Id = :cardId AND RecordType.Name = 'Debit Card')
            WITH USER_MODE
            LIMIT 1
        ];
    }
}
