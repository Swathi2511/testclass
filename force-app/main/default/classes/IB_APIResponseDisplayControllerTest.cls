@IsTest
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

    /* ----------------------------------------------------------
       Helper: Create Integration Log for calloutDateTime
    ---------------------------------------------------------- */
    private static void createLog(String recordId) {
        try {
            insert new Integration_Message_Log__c(
                Message_Id__c = recordId,
                Callout_Date__c = System.now()
            );
        } catch (Exception e) {
            System.debug('Unable to create Integration_Message_Log__c in test: ' + e.getMessage());
        }
    }

    /* ----------------------------------------------------------
       TEST: fetchAndDisplayAPIData -> Generic Success
    ---------------------------------------------------------- */
    @IsTest
    static void testFetch_GenericSuccess() {

        String recordId = UserInfo.getUserId();
        createLog(recordId);

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError": true, "errorMessage": "Failure"}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordId,
                'AnyType',
                'SOME_API'
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(true, response.isError);
    }

    /* ----------------------------------------------------------
       TEST: fetchAndDisplayAPIData -> Credit Card Branch
    ---------------------------------------------------------- */
    @IsTest
    static void testFetch_CreditCardBranch() {

        String recordId = UserInfo.getUserId();
        createLog(recordId);

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError": false, "data": {}}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordId,
                'AnyType',
                IB_GlobalConstants.API_IDENTIFIER_CREDIT_CARD
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    /* ----------------------------------------------------------
       TEST: fetchAndDisplayAPIData -> Error JSON branch
    ---------------------------------------------------------- */
    @IsTest
    static void testFetch_ErrorJSON() {

        // Directly call structured method with error JSON
        String errorJson =
            '{"isError": true, "errorMessage": "Failure"}';

        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                errorJson,
                'Type',
                'SOME_API'
            );
        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assertEquals('Failure', response.errorMessage);
    }

    /* ----------------------------------------------------------
       TEST: getStructuredAPIResponse -> Generic Success
    ---------------------------------------------------------- */
    @IsTest
    static void testStructured_GenericSuccess() {

        String json =
            '{"success": true, "data": {}}';

        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                json,
                'Type',
                'SOME_API'
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    /* ----------------------------------------------------------
       TEST: getStructuredAPIResponse -> Credit Card Success
    ---------------------------------------------------------- */
    @IsTest
    static void testStructured_CreditSuccess() {

        String json =
            '{"success": true}';

        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                json,
                'Type',
                IB_GlobalConstants.API_IDENTIFIER_CREDIT_CARD
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    /* ----------------------------------------------------------
       TEST: getStructuredAPIResponse -> Exception Catch
    ---------------------------------------------------------- */
    @IsTest
    static void testStructured_ExceptionCatch() {

        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                'INVALID_JSON',
                'Type',
                'SOME_API'
            );
        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assert(response.errorMessage.contains('Error processing response'));
    }

    /* ----------------------------------------------------------
       TEST: fetchAndDisplayAPIData -> Exception Catch
    ---------------------------------------------------------- */
    @IsTest
    static void testFetch_ExceptionCatch() {

        // Pass invalid Id format to force exception
        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                'INVALID_ID',
                'Type',
                'SOME_API'
            );
        Test.stopTest();

        System.assertEquals(true, response.isError);
    }

    /* ----------------------------------------------------------
       TEST: getCalloutDateTime -> No logs
    ---------------------------------------------------------- */
    @IsTest
    static void testFetch_NoLogs() {

        String recordId = UserInfo.getUserId();

        Test.startTest();
        Test.setMock(
            HttpCalloutMock.class,
            new StaticHttpResponseMock(200, '{"isError": false, "data": {}}')
        );
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.fetchAndDisplayAPIData(
                recordId,
                'Type',
                'SOME_API'
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @IsTest
    static void testWrapperConstructors() {

        // Cover SectionWrapper constructor
        IB_APIResponseDisplayController.SectionWrapper section =
            new IB_APIResponseDisplayController.SectionWrapper();

        System.assertNotEquals(null, section.rows);

        // Cover RowWrapper constructor
        IB_APIResponseDisplayController.RowWrapper row =
            new IB_APIResponseDisplayController.RowWrapper();

        System.assertNotEquals(null, row.fields);

        // Cover FieldWrapper constructor
        IB_APIResponseDisplayController.FieldWrapper field =
            new IB_APIResponseDisplayController.FieldWrapper(
                'Label',
                'Value',
                'String',
                1
            );

        System.assertEquals('Label', field.fieldLabel);
        System.assertEquals('Value', field.fieldValue);
        System.assertEquals('String', field.dataType);
        System.assertEquals(1, field.columnPosition);
    }

    @IsTest
    static void testStructured_GenericFullSuccess() {

        String json = '{"success": true}';

        Test.startTest();
        IB_APIResponseDisplayController.ResponseWrapper response =
            IB_APIResponseDisplayController.getStructuredAPIResponse(
                json,
                'TestType',
                'ANY_API'
            );
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assertEquals(null, response.calloutDateTime);
    }
}
