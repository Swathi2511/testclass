@IsTest(SeeAllData=true)
private class IB_APIResponseDisplayControllerTest {

    private class StaticHttpResponseMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;

        StaticHttpResponseMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static String getValidRecordId() {
        return (String) UserInfo.getUserId();
    }

    private static void insertIntegrationLog(String recordIdValue) {
        try {
            insert new Integration_Message_Log__c(
                Message_Id__c = recordIdValue,
                Callout_Date__c = Datetime.now()
            );
        } catch (Exception e) {
            // Some orgs may have extra required fields / validation rules.
            System.debug('Integration_Message_Log__c setup failed: ' + e.getMessage());
        }
    }

    private static Boolean hasIntegrationLog(String recordIdValue) {
        return [
            SELECT COUNT()
            FROM Integration_Message_Log__c
            WHERE Message_Id__c = :recordIdValue
        ] > 0;
    }

    @IsTest
    static void testWrapperConstructors() {
        IB_APIResponseDisplayController.SectionWrapper section = new IB_APIResponseDisplayController.SectionWrapper();
        System.assertNotEquals(null, section.rows, 'SectionWrapper should initialize rows.');
        System.assertEquals(0, section.rows.size(), 'SectionWrapper rows should start empty.');

        IB_APIResponseDisplayController.RowWrapper row = new IB_APIResponseDisplayController.RowWrapper();
        System.assertNotEquals(null, row.fields, 'RowWrapper should initialize fields.');
        System.assertEquals(0, row.fields.size(), 'RowWrapper fields should start empty.');

        IB_APIResponseDisplayController.FieldWrapper fieldValue =
            new IB_APIResponseDisplayController.FieldWrapper('Label', 'Value', 'String', 1);
        System.assertEquals('Label', fieldValue.fieldLabel);
        System.assertEquals('Value', fieldValue.fieldValue);
        System.assertEquals('String', fieldValue.dataType);
        System.assertEquals(1, fieldValue.columnPosition);

        IB_APIResponseDisplayController.ResponseWrapper response = new IB_APIResponseDisplayController.ResponseWrapper();
        System.assertNotEquals(null, response.sections, 'ResponseWrapper should initialize sections.');
        System.assertEquals(0, response.sections.size(), 'ResponseWrapper sections should start empty.');
    }

    @IsTest
    static void testGetStructuredAPIResponse_ErrorPayload() {
        String payload = '{"isError":true,"errorMessage":"Upstream error"}';

        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                payload,
                'AnyRecordType',
                'AnyApiIdentifier'
            );

        System.assertEquals(true, response.isError);
        System.assertEquals('Upstream error', response.errorMessage);
        System.assertNotEquals(null, response.sections);
        System.assertEquals(0, response.sections.size());
        System.assertEquals(null, response.calloutDateTime);
    }

    @IsTest
    static void testGetStructuredAPIResponse_InvalidJson_Caught() {
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                '{"isError":',
                'AnyRecordType',
                'AnyApiIdentifier'
            );

        System.assertEquals(true, response.isError, 'Invalid JSON should be handled as error.');
        System.assert(response.errorMessage != null && response.errorMessage.startsWith('Error processing response:'));
        System.assertNotEquals(null, response.sections);
        System.assertEquals(0, response.sections.size());
        System.assertEquals(null, response.calloutDateTime);
    }

    @IsTest
    static void testGetStructuredAPIResponse_Success_CreditCardPath() {
        String payload = '{"isError":false,"data":{}}';

        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                payload,
                'AnyRecordType',
                IB_GlobalConstants.API_IDENTIFIER_CREDIT_CARD
            );

        System.assertEquals(false, response.isError, 'Expected success for non-error payload.');
        System.assertNotEquals(null, response.sections);
        System.assertEquals(null, response.calloutDateTime);
    }

    @IsTest
    static void testGetStructuredAPIResponse_Success_GenericPath() {
        String payload = '{"isError":false,"data":{}}';

        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                payload,
                'AnyRecordType',
                'NON_CREDIT_CARD_IDENTIFIER'
            );

        System.assertEquals(false, response.isError, 'Expected success for non-error payload.');
        System.assertNotEquals(null, response.sections);
        System.assertEquals(null, response.calloutDateTime);
    }

    @IsTest
    static void testFetchAndDisplayAPIData_ErrorPayload() {
        String recordIdValue = getValidRecordId();
        insertIntegrationLog(recordIdValue);

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError":true,"errorMessage":"Callout failed"}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordIdValue,
                'AnyRecordType',
                'AnyApiIdentifier'
            );
        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assertEquals('Callout failed', response.errorMessage);
        System.assertNotEquals(null, response.sections);
        System.assertEquals(0, response.sections.size());

        if (hasIntegrationLog(recordIdValue)) {
            System.assertNotEquals(
                null,
                response.calloutDateTime,
                'When callout log exists, formatted callout date/time should be returned.'
            );
        }
    }

    @IsTest
    static void testFetchAndDisplayAPIData_Success_CreditCardPath() {
        String recordIdValue = getValidRecordId();
        insertIntegrationLog(recordIdValue);

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError":false,"data":{}}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordIdValue,
                'AnyRecordType',
                IB_GlobalConstants.API_IDENTIFIER_CREDIT_CARD
            );
        Test.stopTest();

        System.assertEquals(false, response.isError, 'Expected success for non-error payload.');
        System.assertNotEquals(null, response.sections);
    }

    @IsTest
    static void testFetchAndDisplayAPIData_Success_GenericPath() {
        String recordIdValue = getValidRecordId();
        insertIntegrationLog(recordIdValue);

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError":false,"data":{}}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordIdValue,
                'AnyRecordType',
                'NON_CREDIT_CARD_IDENTIFIER'
            );
        Test.stopTest();

        System.assertEquals(false, response.isError, 'Expected success for non-error payload.');
        System.assertNotEquals(null, response.sections);
    }

    @IsTest
    static void testFetchAndDisplayAPIData_InvalidRecordId_Caught() {
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                'invalid-id',
                'AnyRecordType',
                'AnyApiIdentifier'
            );

        System.assertEquals(true, response.isError, 'Invalid record Id should be handled as error.');
        System.assert(response.errorMessage != null && response.errorMessage.startsWith('Error processing response:'));
        System.assertNotEquals(null, response.sections);
        System.assertEquals(0, response.sections.size());
    }
}
