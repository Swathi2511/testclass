@IsTest
private with sharing class IB_FinancialAccountSelectorTest {

    private static void assertExpectedException(Exception thrown, String methodName) {
        System.assertNotEquals(null, thrown, methodName + ' should throw when no matching record is found.');
        System.assert(
            thrown instanceof QueryException || thrown instanceof System.NoAccessException,
            methodName + ' should throw QueryException or NoAccessException, but got: ' + thrown.getTypeName()
        );
    }

    @IsTest
    static void getFinancialAccountById_noMatchingLoanAccount_throwsException() {
        Exception thrown;

        Test.startTest();
        try {
            IB_FinancialAccountSelector.getFinancialAccountById(UserInfo.getUserId());
        } catch (Exception e) {
            thrown = e;
        }
        Test.stopTest();

        assertExpectedException(thrown, 'getFinancialAccountById');
    }

    @IsTest
    static void getCreditCardById_noMatchingCreditCard_throwsException() {
        Exception thrown;

        Test.startTest();
        try {
            IB_FinancialAccountSelector.getCreditCardById(UserInfo.getUserId());
        } catch (Exception e) {
            thrown = e;
        }
        Test.stopTest();

        assertExpectedException(thrown, 'getCreditCardById');
    }

    @IsTest
    static void getCardById_noMatchingDebitCard_throwsException() {
        Exception thrown;

        Test.startTest();
        try {
            IB_FinancialAccountSelector.getCardById(UserInfo.getUserId());
        } catch (Exception e) {
            thrown = e;
        }
        Test.stopTest();

        assertExpectedException(thrown, 'getCardById');
    }
}
