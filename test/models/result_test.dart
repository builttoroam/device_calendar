import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.isSuccess', () {
    // isSuccess is `data != null && errors.isEmpty`, with one extra carve-out:
    // if data is a String, it must also be non-empty. Any other type (bool,
    // List, custom object) only needs to be non-null.
    test('IsSuccess_DataNullNoErrors_False', () {
      final result = Result<bool>();
      expect(result.isSuccess, isFalse);
    });

    test('IsSuccess_DataSetNoErrors_True', () {
      final result = Result<bool>()..data = true;
      expect(result.isSuccess, isTrue);
    });

    test('IsSuccess_DataSetWithErrors_False', () {
      final result = Result<bool>()
        ..data = true
        ..errors.add(const ResultError(1, 'error'));
      expect(result.isSuccess, isFalse);
    });

    test('IsSuccess_StringDataEmpty_False', () {
      final result = Result<String>()..data = '';
      expect(result.isSuccess, isFalse);
    });

    test('IsSuccess_StringDataNonEmpty_True', () {
      final result = Result<String>()..data = 'x';
      expect(result.isSuccess, isTrue);
    });

    test('IsSuccess_NonStringEmptyCollectionData_True', () {
      // Only String gets the extra "non-empty" check -- an empty list still
      // counts as success as long as data isn't null.
      final result = Result<List<int>>()..data = <int>[];
      expect(result.isSuccess, isTrue);
    });
  });

  group('Result.hasErrors', () {
    test('HasErrors_ReflectsErrorsList', () {
      final result = Result<bool>();
      expect(result.hasErrors, isFalse);
      result.errors.add(const ResultError(1, 'error'));
      expect(result.hasErrors, isTrue);
    });
  });

  group('ResultError', () {
    test('ResultError_FieldsSetCorrectly', () {
      const error = ResultError(400, 'bad request');
      expect(error.errorCode, 400);
      expect(error.errorMessage, 'bad request');
    });
  });
}
