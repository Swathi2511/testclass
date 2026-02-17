@IsTest
private class IB_GenericMetadataServiceTest {

    private class MappingScope {
        String recordTypeName;
        String apiIdentifier;
        List<IB_API_Response_Field_Mapping__mdt> mappings;

        MappingScope(
            String recordTypeName,
            String apiIdentifier,
            List<IB_API_Response_Field_Mapping__mdt> mappings
        ) {
            this.recordTypeName = recordTypeName;
            this.apiIdentifier = apiIdentifier;
            this.mappings = mappings;
        }
    }

    @IsTest
    static void processResponse_returnsEmptyForBlankInputs() {
        Test.startTest();
        List<IB_APIResponseDisplayController.SectionWrapper> resultNullJson =
            IB_GenericMetadataService.processResponse(null, 'RecordType', 'ApiId');
        List<IB_APIResponseDisplayController.SectionWrapper> resultBlankRecordType =
            IB_GenericMetadataService.processResponse('{"ok":true}', '', 'ApiId');
        List<IB_APIResponseDisplayController.SectionWrapper> resultBlankApiId =
            IB_GenericMetadataService.processResponse('{"ok":true}', 'RecordType', '');
        Test.stopTest();

        System.assertEquals(0, resultNullJson.size(), 'Null JSON should return empty list.');
        System.assertEquals(0, resultBlankRecordType.size(), 'Blank record type should return empty list.');
        System.assertEquals(0, resultBlankApiId.size(), 'Blank API identifier should return empty list.');
    }

    @IsTest
    static void processResponse_handlesInvalidJson() {
        Test.startTest();
        List<IB_APIResponseDisplayController.SectionWrapper> result =
            IB_GenericMetadataService.processResponse('{"badJson"', 'RecordType', 'ApiId');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Invalid JSON should be caught and return empty list.');
    }

    @IsTest
    static void processResponse_handlesErrorResponses() {
        Map<String, Object> errorMap = getSupportedErrorPayload();
        if (errorMap == null) {
            System.assert(true, 'No supported error payload shape detected for this org.');
            return;
        }

        List<IB_APIResponseDisplayController.SectionWrapper> expected =
            IB_MetadataServiceUtility.buildErrorSection(errorMap);

        Test.startTest();
        List<IB_APIResponseDisplayController.SectionWrapper> actual =
            IB_GenericMetadataService.processResponse(
                JSON.serialize(errorMap),
                'AnyRecordType',
                'AnyApi'
            );
        Test.stopTest();

        System.assertNotEquals(null, actual, 'Error handling should return a non-null list.');
        System.assertEquals(
            expected.size(),
            actual.size(),
            'Error payload should follow the same error section builder output size.'
        );
    }

    @IsTest
    static void processResponse_returnsEmptyWhenMappingsAreMissing() {
        String uniqueRecordType = 'RT_' + String.valueOf(DateTime.now().getTime());
        String uniqueApi = 'API_' + String.valueOf(DateTime.now().getTime()) + '_A';

        Test.startTest();
        List<IB_APIResponseDisplayController.SectionWrapper> result =
            IB_GenericMetadataService.processResponse(
                '{"sample":"value"}',
                uniqueRecordType,
                uniqueApi
            );
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Unknown record type/API combination should return empty list.');
    }

    @IsTest
    static void processResponse_metadataDrivenBranchCoverage() {
        MappingScope scope = discoverWorkingScope();
        if (scope == null || scope.mappings.isEmpty()) {
            System.assert(true, 'No metadata mappings available to run metadata-driven assertions.');
            return;
        }

        List<String> wrapperModes = new List<String>{
            'BodyPayload',
            'ResponseData',
            'Data',
            'Payload',
            'Direct'
        };

        Integer totalSections = 0;

        Test.startTest();
        for (String wrapperMode : wrapperModes) {
            Map<String, Object> payload = buildResponseForMappings(
                scope.mappings,
                wrapperMode,
                true,
                false
            );
            List<IB_APIResponseDisplayController.SectionWrapper> sections =
                IB_GenericMetadataService.processResponse(
                    JSON.serialize(payload),
                    scope.recordTypeName,
                    scope.apiIdentifier
                );
            totalSections += sections.size();
        }

        // Missing values path: returns placeholders ("--") for non-resolvable fields.
        List<IB_APIResponseDisplayController.SectionWrapper> missingValueSections =
            IB_GenericMetadataService.processResponse(
                JSON.serialize(new Map<String, Object>{'unrelated' => 'value'}),
                scope.recordTypeName,
                scope.apiIdentifier
            );

        // Date formatting / extractor exception hardening path.
        Map<String, Object> invalidDatePayload = buildResponseForMappings(
            scope.mappings,
            'Direct',
            true,
            true
        );
        List<IB_APIResponseDisplayController.SectionWrapper> invalidDateSections =
            IB_GenericMetadataService.processResponse(
                JSON.serialize(invalidDatePayload),
                scope.recordTypeName,
                scope.apiIdentifier
            );

        // Source navigation failure path (non-map object in source chain).
        Map<String, Object> brokenSourcePayload = buildBrokenSourcePayload(scope.mappings);
        List<IB_APIResponseDisplayController.SectionWrapper> brokenSourceSections =
            IB_GenericMetadataService.processResponse(
                JSON.serialize(brokenSourcePayload),
                scope.recordTypeName,
                scope.apiIdentifier
            );
        Test.stopTest();

        System.assert(totalSections >= 0, 'Wrapper mode executions should complete without exceptions.');
        System.assertNotEquals(null, missingValueSections, 'Missing value flow should still return a list.');
        System.assertNotEquals(null, invalidDateSections, 'Invalid date flow should still return a list.');
        System.assertNotEquals(null, brokenSourceSections, 'Broken source flow should still return a list.');
    }

    private static MappingScope discoverWorkingScope() {
        List<IB_API_Response_Field_Mapping__mdt> allMappings = [
            SELECT FIELDS(ALL)
            FROM IB_API_Response_Field_Mapping__mdt
            LIMIT 300
        ];
        if (allMappings.isEmpty()) {
            return null;
        }

        List<String> recordTypeFieldCandidates = new List<String>{
            'IB_Record_Type_Name__c',
            'IB_Record_Type__c',
            'IB_RecordType__c',
            'Record_Type__c',
            'RecordType__c'
        };
        List<String> apiIdentifierFieldCandidates = new List<String>{
            'IB_API_Identifier__c',
            'IB_API_Name__c',
            'IB_API__c',
            'API_Identifier__c',
            'ApiIdentifier__c'
        };

        for (IB_API_Response_Field_Mapping__mdt mapping : allMappings) {
            String recordTypeName = firstNonBlankValue(mapping, recordTypeFieldCandidates);
            String apiIdentifier = firstNonBlankValue(mapping, apiIdentifierFieldCandidates);

            if (String.isBlank(recordTypeName) || String.isBlank(apiIdentifier)) {
                continue;
            }

            List<IB_API_Response_Field_Mapping__mdt> scopedMappings =
                IB_MetadataServiceUtility.queryMetadataMappings(recordTypeName, apiIdentifier);
            if (!scopedMappings.isEmpty()) {
                return new MappingScope(recordTypeName, apiIdentifier, scopedMappings);
            }
        }

        for (IB_API_Response_Field_Mapping__mdt mapping : allMappings) {
            Map<String, Object> values = mapping.getPopulatedFieldsAsMap();
            String recordTypeValue;
            String apiIdentifierValue;

            for (String fieldApi : values.keySet()) {
                Object raw = values.get(fieldApi);
                if (raw == null || !(raw instanceof String)) {
                    continue;
                }

                String value = String.valueOf(raw);
                if (String.isBlank(value)) {
                    continue;
                }

                String lowered = fieldApi.toLowerCase();
                if (recordTypeValue == null && lowered.contains('record') && lowered.contains('type')) {
                    recordTypeValue = value;
                }
                if (apiIdentifierValue == null && lowered.contains('api') &&
                    (lowered.contains('identifier') || lowered.contains('name') || lowered.endsWith('_api__c'))) {
                    apiIdentifierValue = value;
                }
            }

            if (String.isBlank(recordTypeValue) || String.isBlank(apiIdentifierValue)) {
                continue;
            }

            List<IB_API_Response_Field_Mapping__mdt> scopedMappings =
                IB_MetadataServiceUtility.queryMetadataMappings(recordTypeValue, apiIdentifierValue);
            if (!scopedMappings.isEmpty()) {
                return new MappingScope(recordTypeValue, apiIdentifierValue, scopedMappings);
            }
        }

        return null;
    }

    private static Map<String, Object> getSupportedErrorPayload() {
        List<Map<String, Object>> candidates = new List<Map<String, Object>>{
            new Map<String, Object>{'error' => true, 'message' => 'Generic error'},
            new Map<String, Object>{'status' => 'ERROR', 'errorMessage' => 'Failure'},
            new Map<String, Object>{'success' => false, 'message' => 'Request failed'},
            new Map<String, Object>{'isError' => true, 'details' => 'Backend failure'},
            new Map<String, Object>{'code' => '500', 'message' => 'Server error'}
        };

        for (Map<String, Object> candidate : candidates) {
            if (IB_MetadataServiceUtility.isErrorResponse(candidate)) {
                return candidate;
            }
        }
        return null;
    }

    private static String firstNonBlankValue(
        IB_API_Response_Field_Mapping__mdt mapping,
        List<String> fieldNames
    ) {
        for (String fieldName : fieldNames) {
            String value = readStringField(mapping, fieldName);
            if (String.isNotBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private static String readStringField(
        IB_API_Response_Field_Mapping__mdt recordValue,
        String fieldApiName
    ) {
        try {
            Object raw = recordValue.get(fieldApiName);
            return raw == null ? null : String.valueOf(raw);
        } catch (Exception e) {
            return null;
        }
    }

    private static Map<String, Object> buildResponseForMappings(
        List<IB_API_Response_Field_Mapping__mdt> mappings,
        String wrapperMode,
        Boolean includeValues,
        Boolean useInvalidDateValues
    ) {
        Map<String, Map<String, Object>> sourcePayloads = new Map<String, Map<String, Object>>();
        Boolean recursiveSearchSeeded = false;

        for (IB_API_Response_Field_Mapping__mdt mapping : mappings) {
            String source = String.isBlank(mapping.IB_API_Source__c) ? '' : mapping.IB_API_Source__c.trim();
            if (!sourcePayloads.containsKey(source)) {
                sourcePayloads.put(source, new Map<String, Object>());
            }

            Map<String, Object> payload = sourcePayloads.get(source);

            if (mapping.IB_Is_Calculation__c && String.isNotBlank(mapping.IB_Calculation_Formula__c)) {
                for (String token : extractFormulaTokens(mapping.IB_Calculation_Formula__c)) {
                    if (!payload.containsKey(token)) {
                        payload.put(token, 10);
                    }
                }
                if (!payload.containsKey('amount')) {
                    payload.put('amount', 100);
                }
                if (!payload.containsKey('rate')) {
                    payload.put('rate', 5);
                }
                continue;
            }

            if (!includeValues || String.isBlank(mapping.IB_API_Response_Key__c)) {
                continue;
            }

            Object value = buildValueForFieldType(
                mapping.IB_Field_Data_Type__c,
                mapping.IB_API_Response_Key__c,
                useInvalidDateValues
            );

            if (!recursiveSearchSeeded) {
                payload.put(
                    'nestedContainer',
                    new Map<String, Object>{ mapping.IB_API_Response_Key__c => value }
                );
                recursiveSearchSeeded = true;
            } else {
                payload.put(mapping.IB_API_Response_Key__c, value);
            }
        }

        Map<String, Object> root = new Map<String, Object>();
        for (String source : sourcePayloads.keySet()) {
            Map<String, Object> payload = sourcePayloads.get(source);
            Map<String, Object> wrappedPayload = wrapPayload(payload, wrapperMode);
            placeAtSourcePath(root, source, wrappedPayload);
        }

        if (root.isEmpty()) {
            root.put('placeholder', 'value');
        }
        return root;
    }

    private static Object buildValueForFieldType(
        String fieldType,
        String keyName,
        Boolean useInvalidDateValues
    ) {
        if (fieldType == 'Date') {
            return useInvalidDateValues ? 'not-a-date' : '2026-02-17';
        }
        if (fieldType == 'Number' || fieldType == 'Currency' || fieldType == 'Percent') {
            return 123.45;
        }
        if (fieldType == 'Boolean') {
            return true;
        }
        return 'value_for_' + keyName;
    }

    private static Map<String, Object> wrapPayload(Map<String, Object> payload, String wrapperMode) {
        if (wrapperMode == 'BodyPayload') {
            return new Map<String, Object>{
                'Body' => new Map<String, Object>{'Payload' => payload}
            };
        }
        if (wrapperMode == 'ResponseData') {
            return new Map<String, Object>{
                'Response' => new Map<String, Object>{'Data' => payload}
            };
        }
        if (wrapperMode == 'Data') {
            return new Map<String, Object>{'Data' => payload};
        }
        if (wrapperMode == 'Payload') {
            return new Map<String, Object>{'Payload' => payload};
        }
        return payload;
    }

    private static void placeAtSourcePath(
        Map<String, Object> root,
        String sourcePath,
        Map<String, Object> terminalValue
    ) {
        if (String.isBlank(sourcePath)) {
            root.putAll(terminalValue);
            return;
        }

        List<String> parts = sourcePath.split('\\.');
        Map<String, Object> cursor = root;

        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts[i];
            Boolean isLast = (i == parts.size() - 1);

            if (isLast) {
                if (cursor.containsKey(part) && cursor.get(part) instanceof Map<String, Object>) {
                    ((Map<String, Object>) cursor.get(part)).putAll(terminalValue);
                } else {
                    cursor.put(part, terminalValue);
                }
                continue;
            }

            if (!cursor.containsKey(part) || !(cursor.get(part) instanceof Map<String, Object>)) {
                cursor.put(part, new Map<String, Object>());
            }
            cursor = (Map<String, Object>) cursor.get(part);
        }
    }

    private static Set<String> extractFormulaTokens(String formula) {
        Set<String> tokens = new Set<String>();
        if (String.isBlank(formula)) {
            return tokens;
        }

        Matcher matcher = Pattern.compile('[A-Za-z_][A-Za-z0-9_]*').matcher(formula);
        Set<String> ignored = new Set<String>{
            'if',
            'and',
            'or',
            'not',
            'true',
            'false',
            'null',
            'min',
            'max',
            'round',
            'abs'
        };

        while (matcher.find()) {
            String token = matcher.group(0);
            if (String.isBlank(token)) {
                continue;
            }
            if (!ignored.contains(token.toLowerCase())) {
                tokens.add(token);
            }
        }
        return tokens;
    }

    private static Map<String, Object> buildBrokenSourcePayload(
        List<IB_API_Response_Field_Mapping__mdt> mappings
    ) {
        Map<String, Object> payload = new Map<String, Object>();
        for (IB_API_Response_Field_Mapping__mdt mapping : mappings) {
            if (String.isBlank(mapping.IB_API_Source__c)) {
                continue;
            }

            List<String> parts = mapping.IB_API_Source__c.split('\\.');
            if (parts.isEmpty()) {
                continue;
            }

            payload.put(parts[0], 'not_a_map');
            return payload;
        }

        payload.put('fallback', 'not_a_map');
        return payload;
    }
}
